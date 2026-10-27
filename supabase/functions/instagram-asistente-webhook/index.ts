import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const MAX_BODY_BYTES = 256_000;
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type, apikey, x-club-session",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type ParsedEvent = {
  externalId: string;
  kind: "comentario" | "mensaje_privado" | "otro";
  platform: "instagram" | "facebook";
  accountId: string | null;
  actorId: string | null;
  username: string | null;
  text: string;
};

type Draft = {
  category: string;
  action: "responder" | "revisar" | "solo_humano" | "ocultar" | "ignorar" | "escalar";
  tone: string;
  reply: string | null;
  reasons: string[];
};

type AssistantConfig = {
  modo?: string;
  envio_automatico_habilitado?: boolean;
};

function response(body: unknown, status = 200): Response {
  return Response.json(body, {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store", ...CORS_HEADERS },
  });
}

function serverKey(): string | null {
  const raw = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      const value = parsed.default ?? Object.values(parsed)[0];
      if (typeof value === "string" && value) return value;
    } catch {
      // Uses the legacy key below when needed.
    }
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function hex(bytes: ArrayBuffer): string {
  return Array.from(new Uint8Array(bytes), (value) => value.toString(16).padStart(2, "0")).join("");
}

async function validMetaSignature(rawBody: string, signature: string | null): Promise<boolean> {
  const secret = Deno.env.get("META_APP_SECRET");
  if (!secret || !signature?.startsWith("sha256=")) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(rawBody));
  return timingSafeEqual(signature.slice(7).toLowerCase(), hex(digest));
}

async function rpc(name: string, body: Record<string, unknown>): Promise<unknown> {
  const url = Deno.env.get("SUPABASE_URL");
  const key = serverKey();
  if (!url || !key) throw new Error("backend_unavailable");
  const headers = new Headers({ "Content-Type": "application/json", apikey: key });
  if (!key.startsWith("sb_secret_")) headers.set("Authorization", `Bearer ${key}`);
  const result = await fetch(`${url}/rest/v1/rpc/${name}`, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
  if (!result.ok) throw new Error(`rpc_${name}_${result.status}`);
  return result.json();
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" ? value as Record<string, unknown> : {};
}

function stringValue(value: unknown): string | null {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function parseEvents(payload: unknown): ParsedEvent[] {
  const root = asRecord(payload);
  const platform = stringValue(root.object) === "page" ? "facebook" : "instagram";
  const entries = Array.isArray(root.entry) ? root.entry : [];
  const result: ParsedEvent[] = [];

  for (const rawEntry of entries) {
    const entry = asRecord(rawEntry);
    const accountId = stringValue(entry.id);
    const changes = Array.isArray(entry.changes) ? entry.changes : [];
    for (const rawChange of changes) {
      const change = asRecord(rawChange);
      const value = asRecord(change.value);
      const from = asRecord(value.from);
      const text = stringValue(value.text) ?? stringValue(value.message) ?? "";
      const externalId = stringValue(value.id) ?? stringValue(value.comment_id);
      if (!externalId) continue;
      const isComment = stringValue(change.field)?.includes("comment") ||
        stringValue(value.item) === "comment";
      const actorId = stringValue(from.id) ?? stringValue(value.sender_id);
      if (isComment && actorId && actorId === accountId) continue;
      result.push({
        externalId,
        kind: isComment ? "comentario" : "otro",
        platform,
        accountId,
        actorId,
        username: stringValue(from.username) ?? stringValue(from.name),
        text,
      });
    }

    const messaging = Array.isArray(entry.messaging) ? entry.messaging : [];
    for (const rawMessage of messaging) {
      const item = asRecord(rawMessage);
      const sender = asRecord(item.sender);
      const message = asRecord(item.message);
      const externalId = stringValue(message.mid);
      if (!externalId || message.is_echo === true) continue;
      result.push({
        externalId,
        kind: "mensaje_privado",
        platform,
        accountId,
        actorId: stringValue(sender.id),
        username: null,
        text: stringValue(message.text) ?? "",
      });
    }
  }
  return result;
}

function classify(input: string): Draft {
  const text = input.toLocaleLowerCase("es-AR");
  const normalizedText = text.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  const has = (words: string[]) => words.some((word) =>
    normalizedText.includes(word.toLocaleLowerCase("es-AR").normalize("NFD").replace(/[\u0300-\u036f]/g, ""))
  );
  const hasProfessionalContext = has([
    "soy ", "trabajo en", "me dedico a", "tengo experiencia en",
    "mi experiencia es", "mi profesión es", "mi especialidad es",
    "estudié ", "estudio ", "me recibí de", "recibido en", "recibida en",
  ]);
  const hasProfessionalRole = has([
    "licenciado", "licenciada", "contador", "contadora", "abogado", "abogada",
    "ingeniero", "ingeniera", "arquitecto", "arquitecta", "profesional",
    "técnico", "técnica", "logística", "administración", "finanzas",
    "contabilidad", "marketing", "comunicación", "sistemas", "programación",
    "tecnología", "recursos humanos", "infraestructura", "kinesiología",
    "psicología", "nutrición", "medicina", "educación", "asuntos legales",
  ]);
  const isProfessionalIntroduction = !text.includes("?") && hasProfessionalContext && hasProfessionalRole;

  if (has(["menor", "juvenil", "inferiores", "abuso", "acoso"])) {
    return { category: "menores", action: "escalar", tone: "sin_respuesta", reply: null,
      reasons: ["Posible asunto relacionado con menores o protección."] };
  }
  if (has(["denuncia", "delito", "estafa", "robo", "lavado", "corrup", "demanda"])) {
    return { category: "acusacion_sensible", action: "solo_humano", tone: "sin_respuesta", reply: null,
      reasons: ["Contiene una acusación o un asunto legal/financiero sensible."] };
  }
  if (has(["periodista", "prensa", "radio", "entrevista", "diario"])) {
    return { category: "prensa", action: "solo_humano", tone: "institucional", reply: null,
      reasons: ["Contacto o referencia de prensa."] };
  }
  if (isProfessionalIntroduction) {
    return { category: "colaboracion", action: "responder", tone: "calido",
      reply: "¡Excelente! Todavía no conformamos mesas de trabajo, pero ya podés ingresar al Banco de Profesionales de Talleres Club Abierto. Allí podés cargar tu CV, consultar los perfiles cargados en las distintas áreas y solicitar acceso a un CV específico; su titular deberá autorizar la visualización. Ingresá en https://talleresclubabierto.com, accedé al Panel Socio Activo y elegí Comunidad profesional → Banco de profesionales. 💙🤍",
      reasons: ["Informa una profesión, especialidad o experiencia con posible intención de colaborar."] };
  }
  if (has(["quiero ayudar", "quiero aportar", "me sumo", "colaborar", "involucrarme"])) {
    return { category: "colaboracion", action: "responder", tone: "calido",
      reply: "¡Gracias por acercarte! Estamos sumando socios, hinchas y profesionales que quieran construir una propuesta concreta, participativa y transparente. Contanos en qué área tenés experiencia y cómo te gustaría aportar. 💙🤍",
      reasons: ["Expresa intención concreta de colaborar."] };
  }
  if (has(["son del club", "cuenta oficial", "representan al club", "son ustedes"])) {
    return { category: "confusion_identidad", action: "responder", tone: "institucional",
      reply: "Somos socios e hinchas de Talleres impulsando una propuesta concreta e independiente. No somos una cuenta oficial del Club ni representamos a la actual conducción.",
      reasons: ["Puede estar confundiendo la propuesta con una cuenta oficial."] };
  }
  if (has(["felicit", "muy bueno", "excelente", "apoyo", "aguante", "gracias"])) {
    return { category: "apoyo", action: "responder", tone: "calido",
      reply: "¡Muchas gracias por el apoyo! Esta propuesta concreta crece con socios e hinchas que quieren participar, decidir y controlar. 💙🤍",
      reasons: ["Mensaje de apoyo sin riesgo aparente."] };
  }
  if (has(["humo", "chiste", "virgo", "gallina", "mexicano", "fassi", "belgrano", "instituto", "la cola abierta", "jajaja"])) {
    let reply = "Vinieron a reírse y terminaron leyendo toda la propuesta. Algo bien estaremos haciendo. Cuando quieran debatir ideas, acá estamos. 😉";
    if (has(["gallina", "muerta", "muerto"])) {
      reply = "Nos dicen “muertos” mientras siguen pendientes de cada cosa que hace Talleres. Gracias por la atención; nosotros seguimos construyendo. 😉";
    } else if (has(["virgo", "la cola abierta"])) {
      reply = "Para hablar de historia primero hay que tener memoria. La chicana es gratis; construir una propuesta concreta lleva trabajo. 😉";
    } else if (has(["mexicano", "fassi", "kiko"])) {
      reply = "El meme dura segundos; las ideas quedan. Cuando quieran debatir la propuesta sin confundir al Club con una conducción, acá estamos. 😉";
    }
    return { category: "chicana_rival", action: "responder", tone: "picante_medido", reply,
      reasons: ["Chicana futbolera reconocida; respuesta automática limitada a ironía sin ataques personales."] };
  }
  if (has(["hijo de puta", "mugre", "matar", "amenaza"])) {
    return { category: "agresion", action: "ocultar", tone: "sin_respuesta", reply: null,
      reasons: ["Agresión grave o posible amenaza."] };
  }
  const mentionsPublicSupport = has([
    "gobierno", "estado", "provincia", "nacion", "municipalidad", "municipio",
  ]);
  const mentionsStadiumLand = has([
    "terreno", "hectarea", "cesion", "donacion", "comodato", "habilitacion",
    "infraestructura", "nuevo estadio",
  ]);
  if (mentionsPublicSupport && mentionsStadiumLand) {
    return { category: "pregunta_genuina", action: "revisar", tone: "institucional",
      reply: "Entendemos tu planteo y coincidimos en que el Estado —municipal, provincial o nacional— debería acompañar a Talleres en la búsqueda de un terreno y en las habilitaciones e infraestructura necesarias, con el mismo criterio aplicado a otras instituciones de Córdoba. La propuesta del nuevo estadio no descarta esa gestión: al contrario, debería ser una de las primeras vías. Y si se consigue una cesión, donación o convenio, todo el proceso debe ser público, transparente y auditable. Gracias por aportar una idea concreta para hacerlo posible. 💙🤍",
      reasons: ["Aporte de un hincha sobre gestión estatal de terreno, habilitaciones o infraestructura."] };
  }
  if (text.includes("?")) {
    return { category: "pregunta_genuina", action: "revisar", tone: "tecnico",
      reply: "Buena pregunta. La propuesta busca que las decisiones relevantes tengan información clara, responsables identificados y mecanismos de participación y auditoría. Si nos precisás el punto, te respondemos con el detalle correspondiente.",
      reasons: ["Pregunta que necesita una respuesta contextual."] };
  }
  return { category: "otra", action: "revisar", tone: "institucional", reply: null,
    reasons: ["No coincide con una categoría segura para respuesta automática."] };
}

async function assistantConfig(): Promise<AssistantConfig> {
  const value = await rpc("instagram_asistente_obtener_configuracion", {});
  return asRecord(Array.isArray(value) ? value[0] : value) as AssistantConfig;
}

async function claimAutomaticSend(draftId: unknown): Promise<boolean> {
  const value = await rpc("instagram_asistente_preparar_envio", { p_borrador_id: draftId });
  return value === true;
}

async function markSend(draftId: unknown, status: "enviado" | "fallido", detail: Record<string, unknown>): Promise<void> {
  await rpc("instagram_asistente_marcar_envio", {
    p_borrador_id: draftId,
    p_estado: status,
    p_detalle: detail,
  });
}

async function sendInstagramReply(event: ParsedEvent, message: string): Promise<Record<string, unknown>> {
  const instagramToken = Deno.env.get("META_INSTAGRAM_ACCESS_TOKEN");
  const facebookToken = event.platform === "facebook"
    ? Deno.env.get("META_PAGE_ACCESS_TOKEN") ?? Deno.env.get("META_FACEBOOK_ACCESS_TOKEN")
    : Deno.env.get("META_FACEBOOK_ACCESS_TOKEN");
  const endpoint = event.kind === "comentario"
    ? event.platform === "facebook"
      ? `https://graph.facebook.com/v26.0/${encodeURIComponent(event.externalId)}/comments`
      : `https://graph.instagram.com/v26.0/${encodeURIComponent(event.externalId)}/replies`
    : "https://graph.instagram.com/v26.0/me/messages";
  const body = event.kind === "comentario"
    ? { message }
    : { recipient: { id: event.actorId }, message: { text: message } };
  if (event.kind === "mensaje_privado" && !event.actorId) throw new Error("instagram_recipient_missing");
  const primaryToken = event.platform === "facebook" ? facebookToken : instagramToken;
  if (!primaryToken) throw new Error(`${event.platform}_access_token_missing`);

  let result = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${primaryToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  let payload = asRecord(await result.json().catch(() => ({})));
  if (!result.ok && event.platform === "instagram" && event.kind === "comentario" && facebookToken) {
    result = await fetch(`https://graph.facebook.com/v26.0/${encodeURIComponent(event.externalId)}/replies`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${facebookToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    payload = asRecord(await result.json().catch(() => ({})));
  }
  if (!result.ok) {
    const code = asRecord(payload.error).code;
    throw new Error(`${event.platform}_send_${result.status}_${String(code ?? "unknown")}`);
  }
  return payload;
}

async function processEvent(event: ParsedEvent, payload: unknown): Promise<"enviado" | "revision" | "omitido" | "fallido"> {
  const eventId = await rpc("instagram_asistente_guardar_evento", {
    p_id_externo: event.externalId,
    p_tipo: event.kind,
    p_cuenta_externa: event.accountId,
    p_actor_id: event.actorId,
    p_actor_usuario: event.username,
    p_contenido: event.text,
    p_payload: payload,
  });
  const draft = classify(event.text);
  const draftId = await rpc("instagram_asistente_guardar_borrador", {
    p_evento_id: eventId,
    p_categoria: draft.category,
    p_accion_sugerida: draft.action,
    p_tono: draft.tone,
    p_respuesta: draft.reply,
    p_razones: draft.reasons,
  });
  const config = await assistantConfig();
  if (config.modo !== "respuestas_seguras" || !config.envio_automatico_habilitado ||
      draft.action !== "responder" || !draft.reply) return "revision";
  if (!await claimAutomaticSend(draftId)) return "omitido";
  try {
    const sent = await sendInstagramReply(event, draft.reply);
    await markSend(draftId, "enviado", { id_meta: sent.id ?? sent.message_id ?? null });
    return "enviado";
  } catch (error) {
    await markSend(draftId, "fallido", {
      error: error instanceof Error ? error.message : "instagram_send_unknown",
    });
    return "fallido";
  }
}

async function handleWebhook(req: Request): Promise<Response> {
  const length = Number(req.headers.get("content-length") ?? "0");
  if (length > MAX_BODY_BYTES) return response({ error: "payload_too_large" }, 413);
  const raw = await req.text();
  if (new TextEncoder().encode(raw).length > MAX_BODY_BYTES) {
    return response({ error: "payload_too_large" }, 413);
  }
  if (!await validMetaSignature(raw, req.headers.get("x-hub-signature-256"))) {
    return response({ error: "invalid_signature" }, 401);
  }

  let payload: unknown;
  try {
    payload = JSON.parse(raw);
  } catch {
    return response({ error: "invalid_json" }, 400);
  }

  for (const event of parseEvents(payload)) {
    await processEvent(event, payload);
  }
  return response({ received: true });
}

async function requireClubAdmin(req: Request): Promise<number> {
  const session = req.headers.get("x-club-session");
  const url = Deno.env.get("SUPABASE_URL");
  const key = serverKey();
  if (!session || !url || !key) throw new Error("sesion_requerida");
  const headers = new Headers({ "Content-Type": "application/json", apikey: key, "X-Club-Session": session });
  if (!key.startsWith("sb_secret_")) headers.set("Authorization", `Bearer ${key}`);
  const result = await fetch(`${url}/functions/v1/club-abierto-api`, {
    method: "POST",
    headers,
    body: JSON.stringify({ accion: "validar_sesion" }),
  });
  const data = asRecord(await result.json().catch(() => ({})));
  const reviewer = Number(data.numero_socio);
  if (!result.ok || data.ok !== true || data.sesion_valida !== true || data.es_administrador !== true ||
      !Number.isInteger(reviewer) || reviewer < 1) throw new Error("administrador_requerido");
  return reviewer;
}

async function handleAdmin(req: Request): Promise<Response> {
  let reviewer: number;
  try {
    reviewer = await requireClubAdmin(req);
  } catch (error) {
    return response({ ok: false, error: error instanceof Error ? error.message : "administrador_requerido" }, 401);
  }
  const body = asRecord(await req.json().catch(() => ({})));
  const action = stringValue(body.accion);
  if (action === "listar_revision") {
    const state = stringValue(body.estado) ?? "pendiente";
    const rows = await rpc("instagram_asistente_listar_revision", { p_estado: state, p_limite: 150 });
    return response({ ok: true, items: Array.isArray(rows) ? rows : [] });
  }
  const draftId = stringValue(body.borrador_id);
  if (!draftId) return response({ ok: false, error: "borrador_requerido" }, 400);
  if (action === "descartar_revision") {
    const done = await rpc("instagram_asistente_resolver_revision", {
      p_borrador_id: draftId, p_estado: "rechazado", p_revisor: reviewer,
      p_detalle: { motivo: stringValue(body.motivo) ?? "Descartado desde el panel administrador" },
    });
    return response({ ok: done === true });
  }
  if (action === "publicar_revision") {
    const message = stringValue(body.respuesta);
    if (!message) return response({ ok: false, error: "respuesta_requerida" }, 400);
    const prepared = asRecord(await rpc("instagram_asistente_preparar_revision_humana", {
      p_borrador_id: draftId, p_respuesta: message, p_revisor: reviewer,
    }));
    const platform = stringValue(prepared.plataforma) === "page" ? "facebook" : "instagram";
    const event: ParsedEvent = {
      externalId: stringValue(prepared.id_externo) ?? "",
      kind: stringValue(prepared.tipo) === "mensaje_privado" ? "mensaje_privado" : "comentario",
      platform,
      accountId: stringValue(prepared.cuenta_externa),
      actorId: stringValue(prepared.actor_id),
      username: null,
      text: "",
    };
    if (!event.externalId) return response({ ok: false, error: "evento_incompleto" }, 409);
    try {
      const sent = await sendInstagramReply(event, message);
      await rpc("instagram_asistente_resolver_revision", {
        p_borrador_id: draftId, p_estado: "enviado", p_revisor: reviewer,
        p_detalle: { id_meta: sent.id ?? sent.message_id ?? null, origen: "panel_administrador" },
      });
      return response({ ok: true, estado: "enviado" });
    } catch (error) {
      await rpc("instagram_asistente_resolver_revision", {
        p_borrador_id: draftId, p_estado: "fallido", p_revisor: reviewer,
        p_detalle: { error: error instanceof Error ? error.message : "envio_desconocido" },
      });
      return response({ ok: false, error: "No se pudo publicar en Meta. Quedó marcado para reintentar." }, 502);
    }
  }
  return response({ ok: false, error: "accion_invalida" }, 400);
}

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS_HEADERS });
  if (req.method === "GET") {
    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token");
    const challenge = url.searchParams.get("hub.challenge");
    if (mode === "subscribe" && token && challenge &&
        timingSafeEqual(token, Deno.env.get("META_WEBHOOK_VERIFY_TOKEN") ?? "")) {
      return new Response(challenge, { status: 200, headers: { "Content-Type": "text/plain" } });
    }
    return response({ error: "verification_failed" }, 403);
  }
  if (req.method === "POST" && url.searchParams.get("modo") === "admin") return handleAdmin(req);
  if (req.method === "POST") return handleWebhook(req);
  return response({ error: "method_not_allowed" }, 405);
});
