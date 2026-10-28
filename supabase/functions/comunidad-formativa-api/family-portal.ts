const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

type PortalDeps = {
  json: (body: unknown, status?: number, origin?: string) => Response;
  rpc: (name: string, body: Record<string, unknown>) => Promise<any>;
  hmac: (keyBytes: Uint8Array, value: string) => Promise<string>;
  base64Bytes: (value: string) => Uint8Array | null;
  decryptJson: (ciphertextB64: string, nonceB64: string, keyBytes: Uint8Array, context: string) => Promise<any>;
  encryptJson: (value: unknown, keyBytes: Uint8Array, context: string) => Promise<{nonce: string; ciphertext: string}>;
  cleanText: (value: unknown, max: number) => string | null;
  validUuid: (value: unknown) => value is string;
  applicationCode: () => string;
};
export function createFamilyPortal(deps: PortalDeps) {
 const {json,rpc,hmac,base64Bytes,decryptJson,encryptJson,cleanText,validUuid,applicationCode}=deps;
function randomSessionToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

async function verifyOtp(payload: unknown, origin?: string) {
  const lookupKey = base64Bytes(Deno.env.get("CF_LOOKUP_HMAC_KEY_V1") ?? "");
  const encryptionKey = base64Bytes(Deno.env.get("CF_DATA_ENCRYPTION_KEY_V1") ?? "");
  if (!lookupKey || !encryptionKey) return json({ error: "otp_temporarily_unavailable" }, 503, origin);
  if (!payload || typeof payload !== "object") return json({ error: "invalid_request" }, 400, origin);
  const input = payload as Record<string, unknown>;
  const email = typeof input.email === "string" ? input.email.trim().toLowerCase() : "";
  if (typeof input.challenge_id !== "string" ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(input.challenge_id) ||
      typeof input.code !== "string" || !/^\d{6}$/.test(input.code) ||
      !EMAIL_RE.test(email) || email.length > 254) {
    return json({ error: "invalid_code" }, 400, origin);
  }
  try {
    const valid = await rpc("community_formative_verify_email_otp", {
      p_id: input.challenge_id,
      p_codigo_hmac: await hmac(lookupKey, `otp:v1:${input.code}`),
    });
    if (valid !== true) return json({ error: "invalid_or_expired_code" }, 400, origin);

    const emailHmac = await hmac(lookupKey, `email:v1:${email}`);
    const approved = await rpc("community_formative_list_approved_access_requests", {
      p_email_hmac: emailHmac,
    });
    const candidates = Array.isArray(approved) ? approved : [];
    let matchingRequest: string | null = null;
    for (const candidate of candidates.slice(0, 100)) {
      if (!candidate || typeof candidate.id !== "string" ||
          typeof candidate.datos_cifrados_b64 !== "string" ||
          typeof candidate.nonce_b64 !== "string") continue;
      try {
        const data = await decryptJson(
          candidate.datos_cifrados_b64,
          candidate.nonce_b64,
          encryptionKey,
          "cf-access-request:v1",
        );
        if (typeof data?.email === "string" && data.email.trim().toLowerCase() === email) {
          matchingRequest = candidate.id;
          break;
        }
      } catch {
        // An encrypted record with a different key version is ignored safely.
      }
    }

    if (!matchingRequest) {
      return json({ ok: true, email_verified: true, access_enabled: false }, 200, origin);
    }

    const sessionToken = randomSessionToken();
    const tokenHmac = await hmac(lookupKey, `family-session:v1:${sessionToken}`);
    const expiresAt = new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString();
    const session = await rpc("community_formative_create_family_session", {
      p_challenge_id: input.challenge_id,
      p_email_hmac: emailHmac,
      p_request_id: matchingRequest,
      p_token_hmac: tokenHmac,
      p_expires_at: expiresAt,
    });
    if (!session?.ok) {
      return json({ ok: true, email_verified: true, access_enabled: false }, 200, origin);
    }
    return json({
      ok: true,
      email_verified: true,
      access_enabled: true,
      session_token: sessionToken,
      session_expires_at: session.expires_at,
    }, 200, origin);
  } catch {
    return json({ error: "otp_temporarily_unavailable" }, 503, origin);
  }
}
async function familySession(req: Request): Promise<{ token: string; tokenHmac: string; lookupKey: Uint8Array } | null> {
  const token = req.headers.get("x-club-session")?.trim() ?? "";
  const lookupKey = base64Bytes(Deno.env.get("CF_LOOKUP_HMAC_KEY_V1") ?? "");
  if (!token || token.length < 40 || token.length > 100 || !lookupKey) return null;
  return { token, tokenHmac: await hmac(lookupKey, `family-session:v1:${token}`), lookupKey };
}

async function familyProfile(req: Request, origin?: string) {
  const session = await familySession(req);
  if (!session) return json({ error: "family_session_required" }, 401, origin);
  const encryptionKey = base64Bytes(Deno.env.get("CF_DATA_ENCRYPTION_KEY_V1") ?? "");
  if (!encryptionKey) return json({ error: "backend_unavailable" }, 503, origin);
  try {
    const result = await rpc("community_formative_get_family_session", { p_token_hmac: session.tokenHmac });
    if (!result?.request_id || !result.datos_cifrados_b64 || !result.nonce_b64) {
      return json({ error: "family_session_expired" }, 401, origin);
    }
    const data = await decryptJson(result.datos_cifrados_b64, result.nonce_b64, encryptionKey, "cf-access-request:v1");
    return json({
      ok: true,
      profile: {
        player: {
          name: data?.player?.name ?? "",
          birth_date: data?.player?.birth_date ?? "",
          category: data?.player?.category ?? "",
        },
        adult: {
          name: data?.adult?.name ?? "",
          relationship: data?.adult?.relationship ?? "",
          phone: data?.adult?.phone ?? "",
          email: typeof data?.email === "string" ? data.email : "",
        },
        link_status: "validado",
      },
    }, 200, origin);
  } catch {
    return json({ error: "family_profile_unavailable" }, 503, origin);
  }
}

async function familyCases(req: Request, origin?: string) {
  const session = await familySession(req);
  if (!session) return json({ error: "family_session_required" }, 401, origin);
  try {
    const result = await rpc("community_formative_list_family_cases", { p_token_hmac: session.tokenHmac });
    return json({ ok: true, cases: Array.isArray(result) ? result : [] }, 200, origin);
  } catch {
    return json({ error: "family_cases_unavailable" }, 503, origin);
  }
}

async function familyCaseSubmit(req: Request, payload: unknown, origin?: string) {
  const session = await familySession(req);
  const encryptionKey = base64Bytes(Deno.env.get("CF_DATA_ENCRYPTION_KEY_V1") ?? "");
  if (!session) return json({ error: "family_session_required" }, 401, origin);
  if (!encryptionKey || !payload || typeof payload !== "object") {
    return json({ error: "invalid_request" }, 400, origin);
  }
  const input = payload as Record<string, unknown>;
  const categories = new Set([
    "consulta","posible_ventaja_indebida","posible_intervencion_irregular",
    "posible_conflicto_intereses","criterio_deportivo","maltrato_discriminacion",
    "posible_represalia","salud_proteccion","educacion_acompanamiento",
    "entrenamiento","alimentacion","transporte","infraestructura",
    "otra_situacion","sugerencia",
  ]);
  const category = input.category;
  const reservation = input.reservation;
  const narrative = cleanText(input.narrative, 10000);
  const mentionedPeople = typeof input.mentioned_people === "string"
    ? input.mentioned_people.normalize("NFC").trim().replace(/\s+/g," ").slice(0,2000)
    : "";
  const approxDate = typeof input.approx_date === "string" ? input.approx_date : "";
  const season = typeof input.season === "string" ? input.season : "2026";
  const communicationType = input.communication_type ?? "acompanamiento";
  const classification = {
    province: cleanText(input.province, 100),
    locality: cleanText(input.locality, 120),
    venue: cleanText(input.venue, 160),
    sport: cleanText(input.sport, 100),
    competition: cleanText(input.competition, 100),
    sport_category: cleanText(input.sport_category, 100),
    division: cleanText(input.division, 100),
  };
  if (typeof category !== "string" || !categories.has(category) ||
      typeof reservation !== "string" ||
      !["identificada","reservada_frente_a_area_deportiva","confidencial_integridad"].includes(reservation) ||
      !/^\d{4}$/.test(season) ||
      !["acompanamiento","integridad"].includes(String(communicationType)) ||
      !narrative || (approxDate && !/^\d{4}-\d{2}-\d{2}$/.test(approxDate))) {
    return json({ error: "invalid_case_payload" }, 400, origin);
  }

  const report = await encryptJson({
    narrative,
    mentioned_people: mentionedPeople,
  }, encryptionKey, "cf-case-report:v1");
  const dateData = approxDate
    ? await encryptJson({ date: approxDate }, encryptionKey, "cf-case-date:v1")
    : { ciphertext: null, nonce: null };
  const action = await encryptJson({
    action: "presentacion_recibida",
    category,
    recorded_at: new Date().toISOString(),
  }, encryptionKey, "cf-case-action:v1");

  try {
    const result = await rpc("community_formative_create_family_case_v2", {
      p_token_hmac: session.tokenHmac,
      p_codigo: applicationCode(),
      p_categoria: category,
      p_modalidad_reserva: reservation,
      p_relato_cifrado: report.ciphertext,
      p_nonce: report.nonce,
      p_version_clave: 1,
      p_fecha_cifrada: dateData.ciphertext,
      p_fecha_nonce: dateData.nonce,
      p_fecha_version_clave: dateData.ciphertext ? 1 : null,
      p_actuacion_cifrada: action.ciphertext,
      p_actuacion_nonce: action.nonce,
      p_temporada: season,
      p_tipo_comunicacion: communicationType,
      p_provincia: classification.province,
      p_localidad: classification.locality,
      p_sede: classification.venue,
      p_deporte: classification.sport,
      p_competencia: classification.competition,
      p_categoria_deportiva: classification.sport_category,
      p_division: classification.division,
      p_opcion_catalogo_id: null,
    });
    if (!result?.ok) throw new Error("case_submit_failed");
    return json({ ok: true, code: result.codigo, status: result.estado }, 200, origin);
  } catch {
    return json({ error: "case_submit_unavailable" }, 503, origin);
  }
}
async function adminListCases(req: Request, origin?: string) {
  const token=req.headers.get("x-club-session")?.trim()??"";
  if(!token)return json({error:"admin_session_required"},401,origin);
  try{
    const rows=await rpc("community_formative_list_admin_case_rows",{p_token:token});
    return json({ok:true,cases:Array.isArray(rows)?rows:[]},200,origin);
  }catch{return json({error:"admin_not_authorized"},403,origin);}
}

async function adminReadCase(req: Request,payload: unknown,origin?: string) {
  const token=req.headers.get("x-club-session")?.trim()??"";
  const input=payload as Record<string,unknown>;
  const id=input?.case_id;
  const reason=cleanText(input?.reason,500);
  if(!token)return json({error:"admin_session_required"},401,origin);
  if(!validUuid(id)||!reason||input?.confirm!==true)return json({error:"case_review_confirmation_required"},400,origin);
  const key=base64Bytes(Deno.env.get("CF_DATA_ENCRYPTION_KEY_V1")??"");
  if(!key)return json({error:"backend_unavailable"},503,origin);
  try{
    const audit=await encryptJson({reason},key,"cf-case-audit:v1");
    const result=await rpc("community_formative_read_admin_case",{
      p_token:token,p_case_id:id,p_motivo_cifrado:audit.ciphertext,p_nonce:audit.nonce,p_version_clave:1,p_confirmada:true,
    });
    const report=await decryptJson(result.relato_cifrado_b64,result.nonce_b64,key,"cf-case-report:v1");
    let approxDate=null;
    if(result.fecha_cifrada_b64&&result.fecha_nonce_b64){
      try{const d=await decryptJson(result.fecha_cifrada_b64,result.fecha_nonce_b64,key,"cf-case-date:v1");approxDate=d?.date??null;}catch{}
    }
    return json({ok:true,case:{
      id:result.id,code:result.codigo,category:result.categoria,status:result.estado,created_at:result.creada_en,
      narrative:report?.narrative??"",mentioned_people:report?.mentioned_people??"",approx_date:approxDate,
    }},200,origin);
  }catch{return json({error:"admin_case_unavailable"},403,origin);}
}

async function adminUpdateCase(req: Request,payload: unknown,origin?: string) {
  const token=req.headers.get("x-club-session")?.trim()??"";
  const input=payload as Record<string,unknown>;
  const id=input?.case_id;
  const state=input?.status;
  const reason=cleanText(input?.reason,500);
  const allowed=new Set(["recibida","en_evaluacion","informacion_solicitada","en_investigacion","resuelta","archivada","reabierta"]);
  if(!token)return json({error:"admin_session_required"},401,origin);
  if(!validUuid(id)||typeof state!=="string"||!allowed.has(state)||!reason||input?.confirm!==true)
    return json({error:"case_action_confirmation_required"},400,origin);
  const key=base64Bytes(Deno.env.get("CF_DATA_ENCRYPTION_KEY_V1")??"");
  if(!key)return json({error:"backend_unavailable"},503,origin);
  try{
    const detail=await encryptJson({reason,status:state,recorded_at:new Date().toISOString()},key,"cf-case-action:v1");
    const result=await rpc("community_formative_admin_update_case",{
      p_token:token,p_case_id:id,p_estado:state,p_detalle_cifrado:detail.ciphertext,p_nonce:detail.nonce,p_version_clave:1,p_confirmada:true,
    });
    return json({ok:true,code:result.codigo,status:result.estado},200,origin);
  }catch{return json({error:"admin_case_update_unavailable"},403,origin);}
}
 return {verifyOtp,familyProfile,familyCases,familyCaseSubmit,adminListCases,adminReadCase,adminUpdateCase};
}

