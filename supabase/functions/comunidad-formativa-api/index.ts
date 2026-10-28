import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createFamilyPortal } from "./family-portal.ts";

const ALLOWED_ORIGINS = new Set([
  "https://www.talleresclubabierto.com",
  "https://talleresclubabierto.com",
]);
function corsHeaders(origin?: string) {
  return {
    ...(origin && ALLOWED_ORIGINS.has(origin) ? { "Access-Control-Allow-Origin": origin } : {}),
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "content-type, x-club-session",
  "Cache-Control": "no-store",
  "Vary": "Origin",
  };
}
const MAX_BODY_BYTES = 20000;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function json(body: unknown, status = 200, origin?: string): Response {
  return Response.json(body, { status, headers: corsHeaders(origin) });
}

function serverKey(): { key: string; isSecret: boolean } | null {
  const raw = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (raw) {
    try {
      const keys = JSON.parse(raw);
      const key = keys.default ?? Object.values(keys)[0];
      if (typeof key === "string" && key.length > 0) {
        return { key, isSecret: key.startsWith("sb_secret_") };
      }
    } catch {
      // Fall back to the legacy server key when present.
    }
  }
  const legacy = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  return legacy ? { key: legacy, isSecret: false } : null;
}

function base64Bytes(value: string): Uint8Array | null {
  try {
    const binary = atob(value);
    const result = Uint8Array.from(binary, (ch) => ch.charCodeAt(0));
    return result.length === 32 ? result : null;
  } catch {
    return null;
  }
}

function hex(bytes: Uint8Array): string {
  return Array.from(bytes, (value) => value.toString(16).padStart(2, "0")).join("");
}

async function hmac(keyBytes: Uint8Array, value: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    keyBytes,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(value));
  return hex(new Uint8Array(signature));
}

async function encryptEmail(email: string, keyBytes: Uint8Array) {
  const nonce = crypto.getRandomValues(new Uint8Array(12));
  const key = await crypto.subtle.importKey("raw", keyBytes, "AES-GCM", false, ["encrypt"]);
  const ciphertext = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv: nonce, additionalData: new TextEncoder().encode("cf-email-otp:v1") },
    key,
    new TextEncoder().encode(email),
  );
  return { nonce: `\\x${hex(nonce)}`, ciphertext: `\\x${hex(new Uint8Array(ciphertext))}` };
}

async function encryptJson(value: unknown, keyBytes: Uint8Array, context: string) {
  const nonce = crypto.getRandomValues(new Uint8Array(12));
  const key = await crypto.subtle.importKey("raw", keyBytes, "AES-GCM", false, ["encrypt"]);
  const ciphertext = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv: nonce, additionalData: new TextEncoder().encode(context) },
    key,
    new TextEncoder().encode(JSON.stringify(value)),
  );
  return { nonce: `\\x${hex(nonce)}`, ciphertext: `\\x${hex(new Uint8Array(ciphertext))}` };
}

function decodeBase64(value: string): Uint8Array {
  return Uint8Array.from(atob(value), (char) => char.charCodeAt(0));
}

async function decryptJson(ciphertextB64: string, nonceB64: string, keyBytes: Uint8Array, context: string) {
  const key = await crypto.subtle.importKey("raw", keyBytes, "AES-GCM", false, ["decrypt"]);
  const clear = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: decodeBase64(nonceB64), additionalData: new TextEncoder().encode(context) },
    key,
    decodeBase64(ciphertextB64),
  );
  return JSON.parse(new TextDecoder().decode(clear));
}

function randomCode(): string {
  const value = crypto.getRandomValues(new Uint32Array(1))[0] % 1_000_000;
  return value.toString().padStart(6, "0");
}

function emailReady() {
  return Boolean(
    Deno.env.get("RESEND_API_KEY") &&
      Deno.env.get("CF_EMAIL_FROM") &&
      base64Bytes(Deno.env.get("CF_DATA_ENCRYPTION_KEY_V1") ?? "") &&
      base64Bytes(Deno.env.get("CF_LOOKUP_HMAC_KEY_V1") ?? ""),
  );
}

async function rpc(name: string, body: Record<string, unknown>) {
  const url = Deno.env.get("SUPABASE_URL");
  const server = serverKey();
  if (!url || !server) throw new Error("backend_unavailable");

  const headers = new Headers({
    "Content-Type": "application/json",
    "apikey": server.key,
  });
  if (!server.isSecret) headers.set("Authorization", `Bearer ${server.key}`);
  const response = await fetch(`${url}/rest/v1/rpc/${name}`, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
  if (!response.ok) throw new Error("backend_unavailable");
  return response.json();
}

async function requestOtp(req: Request, payload: unknown) {
  const origin = req.headers.get("origin") ?? undefined;
  if (!emailReady()) return json({ error: "otp_temporarily_unavailable" }, 503, origin);
  if (!payload || typeof payload !== "object") return json({ error: "invalid_request" }, 400, origin);
  const emailValue = (payload as Record<string, unknown>).email;
  if (typeof emailValue !== "string" || emailValue.length > 254) {
    return json({ error: "invalid_request" }, 400, origin);
  }
  const email = emailValue.trim().toLowerCase();
  if (!EMAIL_RE.test(email)) return json({ error: "invalid_request" }, 400, origin);

  const encryptionKey = base64Bytes(Deno.env.get("CF_DATA_ENCRYPTION_KEY_V1") ?? "");
  const lookupKey = base64Bytes(Deno.env.get("CF_LOOKUP_HMAC_KEY_V1") ?? "");
  const resendKey = Deno.env.get("RESEND_API_KEY");
  const sender = Deno.env.get("CF_EMAIL_FROM");
  if (!encryptionKey || !lookupKey || !resendKey || !sender) {
    return json({ error: "otp_temporarily_unavailable" }, 503, origin);
  }

  const forwarded = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
  const emailHmac = await hmac(lookupKey, `email:v1:${email}`);
  const ipHmac = await hmac(lookupKey, `ip:v1:${forwarded}`);
  const code = randomCode();
  const encrypted = await encryptEmail(email, encryptionKey);

  try {
    const id = await rpc("community_formative_issue_email_otp", {
      p_email_hmac: emailHmac,
      p_code_hmac: await hmac(lookupKey, `otp:v1:${code}`),
      p_email_cifrado: encrypted.ciphertext,
      p_nonce: encrypted.nonce,
      p_version_clave: 1,
      p_ip_hmac: ipHmac,
    });
    if (typeof id !== "string") {
      return json({ ok: true, message: "Si el envío es posible, recibirás un código en el correo indicado." }, 200, origin);
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);
    let sent = false;
    try {
      const response = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${resendKey}`,
          "Content-Type": "application/json",
        },
        signal: controller.signal,
        body: JSON.stringify({
          from: sender,
          to: [email],
          subject: "Código de acceso | Comunidad Formativa",
          text: `Tu código de verificación es ${code}. Vence en 5 minutos. Si no solicitaste este código, ignora este correo. Si el vínculo ya fue aprobado, este código permite abrir tu sesión. Si todavía no fue aprobado, solo verifica el correo y no habilita el acceso.`,
        }),
      });
      sent = response.ok;
    } finally {
      clearTimeout(timeout);
    }
    if (!sent) {
      await rpc("community_formative_revoke_email_otp", { p_id: id });
      return json({ error: "otp_temporarily_unavailable" }, 503, origin);
    }
    return json({ ok: true, challenge_id: id, message: "Si el envío es posible, recibirás un código en el correo indicado." }, 200, origin);
  } catch {
    return json({ error: "otp_temporarily_unavailable" }, 503, origin);
  }
}

function cleanText(value: unknown, max: number): string | null {
  if (typeof value !== "string") return null;
  const clean = value.normalize("NFC").trim().replace(/\s+/g, " ");
  if (clean.length < 2 || clean.length > max || /[\u0000-\u001f\u007f]/.test(clean)) return null;
  return clean;
}

function validUuid(value: unknown): value is string {
  return typeof value === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function validDni(value: unknown): value is string {
  return typeof value === "string" && /^\d{7,8}$/.test(value);
}

function applicationCode(): string {
  // Keep generated codes inside the SQL constraint [A-Z2-7].
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ234567";
  const random = crypto.getRandomValues(new Uint8Array(8));
  const suffix = Array.from(random, (n) => alphabet[n % alphabet.length]).join("");
  return `CF-${new Date().getUTCFullYear()}-${suffix}`;
}

async function submitAccessRequest(payload: unknown, origin?: string) {
  const input = payload as Record<string, unknown>;
  if (!emailReady() || !input || !validUuid(input.challenge_id)) {
    return json({ error: "invalid_request" }, 400, origin);
  }
  const email = typeof input.email === "string" ? input.email.trim().toLowerCase() : "";
  const adultName = cleanText(input.adult_name, 120);
  const playerName = cleanText(input.player_name, 120);
  const adultDni = input.adult_dni;
  const playerDni = input.player_dni;
  const relationship = input.relationship;
  const phone = typeof input.phone === "string" ? input.phone.trim().replace(/[\s().-]/g, "") : "";
  const birthDate = typeof input.birth_date === "string" ? input.birth_date : "";
  const category = typeof input.category === "string" && input.category.trim()
    ? cleanText(input.category, 40)
    : null;
  const birthTime = Date.parse(`${birthDate}T00:00:00Z`);
  const ageMs = Date.now() - birthTime;
  const relationshipValues = new Set(["madre", "padre", "tutor"]);
  if (!EMAIL_RE.test(email) || email.length > 254 || !adultName || !playerName ||
      !validDni(adultDni) || !validDni(playerDni) ||
      typeof relationship !== "string" || !relationshipValues.has(relationship) ||
      !/^\+?\d{8,15}$/.test(phone) ||
      !/^\d{4}-\d{2}-\d{2}$/.test(birthDate) || !Number.isFinite(birthTime) ||
      (typeof input.category === "string" && input.category.trim() && !category) ||
      birthTime > Date.now() || ageMs > 24 * 365.25 * 24 * 60 * 60 * 1000 ||
      input.consent !== true) {
    return json({ error: "invalid_application" }, 400, origin);
  }

  const encryptionKey = base64Bytes(Deno.env.get("CF_DATA_ENCRYPTION_KEY_V1") ?? "");
  const lookupKey = base64Bytes(Deno.env.get("CF_LOOKUP_HMAC_KEY_V1") ?? "");
  if (!encryptionKey || !lookupKey) return json({ error: "intake_temporarily_unavailable" }, 503, origin);

  const normalizedAdultDni = adultDni;
  const normalizedPlayerDni = playerDni;
  const emailHmac = await hmac(lookupKey, `email:v1:${email}`);
  const identifierHmac = await hmac(lookupKey, `player-dni:v1:${normalizedPlayerDni}`);
  const encrypted = await encryptJson({
    adult: { name: adultName, dni: normalizedAdultDni, relationship, phone },
    player: { name: playerName, dni: normalizedPlayerDni, birth_date: birthDate, category },
    email,
  }, encryptionKey, "cf-access-request:v1");

  try {
    const result = await rpc("community_formative_submit_access_request", {
      p_otp_id: input.challenge_id,
      p_email_hmac: emailHmac,
      p_datos_cifrados: encrypted.ciphertext,
      p_nonce: encrypted.nonce,
      p_version_clave: 1,
      p_identificador_hmac: identifierHmac,
      p_codigo: applicationCode(),
      p_consentimiento_version: "comunidad-formativa-alta-v1",
    });
    if (!result?.ok) {
      if (result?.reason === "request_exists") return json({ error: "request_exists" }, 409, origin);
      return json({ error: "verification_required" }, 403, origin);
    }
    return json({ ok: true, code: result.codigo, status: "pendiente" }, 200, origin);
  } catch {
    return json({ error: "intake_temporarily_unavailable" }, 503, origin);
  }
}

async function adminList(req: Request, origin?: string) {
  const token = req.headers.get("x-club-session")?.trim() ?? "";
  if (!token) return json({ error: "admin_session_required" }, 401, origin);
  try {
    const result = await rpc("community_formative_list_access_requests", { p_token: token });
    return json(result, 200, origin);
  } catch {
    return json({ error: "admin_not_authorized" }, 403, origin);
  }
}

async function adminRead(req: Request, payload: unknown, origin?: string) {
  const token = req.headers.get("x-club-session")?.trim() ?? "";
  const input = payload as Record<string, unknown>;
  const requestId = input?.request_id;
  const reason = cleanText(input?.reason, 500);
  if (!token) return json({ error: "admin_session_required" }, 401, origin);
  if (!validUuid(requestId) || !reason || input?.confirm !== true) {
    return json({ error: "identity_access_confirmation_required" }, 400, origin);
  }
  const keyBytes = base64Bytes(Deno.env.get("CF_DATA_ENCRYPTION_KEY_V1") ?? "");
  if (!keyBytes) return json({ error: "backend_unavailable" }, 503, origin);
  try {
    const audit = await encryptJson({ reason }, keyBytes, "cf-access-audit:v1");
    const result = await rpc("community_formative_read_access_request", {
      p_token: token, p_solicitud_id: requestId,
      p_motivo_cifrado: audit.ciphertext, p_nonce: audit.nonce,
      p_version_clave: 1, p_confirmada: true,
    });
    const data = await decryptJson(result.datos_cifrados_b64, result.nonce_b64, keyBytes, "cf-access-request:v1");
    return json({ ok: true, request: { id: result.id, code: result.codigo, status: result.estado, data } }, 200, origin);
  } catch {
    return json({ error: "admin_request_unavailable" }, 403, origin);
  }
}

async function adminReview(req: Request, payload: unknown, origin?: string) {
  const token = req.headers.get("x-club-session")?.trim() ?? "";
  const input = payload as Record<string, unknown>;
  const requestId = input?.request_id;
  const decision = input?.decision;
  const reason = cleanText(input?.reason, 500);
  if (!token) return json({ error: "admin_session_required" }, 401, origin);
  if (!validUuid(requestId) || !["aprobar", "rechazar"].includes(String(decision)) || !reason || input?.confirm !== true) {
    return json({ error: "review_confirmation_required" }, 400, origin);
  }
  const keyBytes = base64Bytes(Deno.env.get("CF_DATA_ENCRYPTION_KEY_V1") ?? "");
  if (!keyBytes) return json({ error: "backend_unavailable" }, 503, origin);
  try {
    const audit = await encryptJson({ reason }, keyBytes, "cf-access-audit:v1");
    const result = await rpc("community_formative_review_access_request", {
      p_token: token, p_solicitud_id: requestId, p_decision: decision,
      p_motivo_cifrado: audit.ciphertext, p_nonce: audit.nonce,
      p_version_clave: 1, p_confirmada: true,
    });
    return json(result, 200, origin);
  } catch {
    return json({ error: "admin_review_unavailable" }, 403, origin);
  }
}

const familyPortal=createFamilyPortal({json,rpc,hmac,base64Bytes,decryptJson,encryptJson,cleanText,validUuid,applicationCode});

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("origin") ?? undefined;
  if (origin && !ALLOWED_ORIGINS.has(origin)) {
    return new Response(null, { status: 403, headers: corsHeaders() });
  }
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders(origin) });

  if (req.method === "GET") {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    if (!supabaseUrl || !serverKey()) {
      return json({ error: "backend_not_configured", intake_enabled: false }, 503, origin);
    }
    try {
      const state = await rpc("community_formative_status", {});
      if (!state || typeof state !== "object") throw new Error("invalid_status");
      return json({
        phase: state.phase === "foundation_created" ? state.phase : "foundation_created",
        module: "comunidad_formativa",
        intake_enabled: emailReady(),
        case_submission_enabled: true,
        blockchain_anchor_enabled: false,
        otp_email_ready: emailReady(),
      }, 200, origin);
    } catch {
      return json({ error: "backend_unavailable", intake_enabled: false }, 503, origin);
    }
  }

  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405, origin);
  const contentType = req.headers.get("content-type")?.split(";")[0].trim().toLowerCase();
  if (contentType !== "application/json") return json({ error: "unsupported_media_type" }, 415, origin);
  let payload: unknown;
  try {
    const text = await req.text();
    if (new TextEncoder().encode(text).length > MAX_BODY_BYTES) return json({ error: "invalid_request" }, 413, origin);
    payload = JSON.parse(text);
  } catch {
    return json({ error: "invalid_request" }, 400, origin);
  }
  const actionName = payload && typeof payload === "object"
    ? (payload as Record<string, unknown>).action
    : null;
  if (actionName === "otp_request") return requestOtp(req, payload);
  if (actionName === "otp_verify") return familyPortal.verifyOtp(payload, origin);
  if (actionName === "family_profile") return familyPortal.familyProfile(req, origin);
  if (actionName === "family_cases_list") return familyPortal.familyCases(req, origin);
  if (actionName === "member_cases_list") return familyPortal.memberCases(req, origin);
  if (actionName === "family_case_submit") return familyPortal.familyCaseSubmit(req, payload, origin);
  if (actionName === "intake_submit") return submitAccessRequest(payload, origin);
  if (actionName === "admin_list_access_requests") return adminList(req, origin);
  if (actionName === "admin_list_cases") return familyPortal.adminListCases(req, origin);
  if (actionName === "admin_read_case") return familyPortal.adminReadCase(req, payload, origin);
  if (actionName === "admin_update_case") return familyPortal.adminUpdateCase(req, payload, origin);
  if (actionName === "admin_read_access_request") return adminRead(req, payload, origin);
  if (actionName === "admin_review_access_request") return adminReview(req, payload, origin);
  return json({ error: "unsupported_action" }, 400, origin);
});
