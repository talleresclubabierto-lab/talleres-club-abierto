// Independent API: no login/bootstrap changes and no provider/network imports.
// Deploy with verify_jwt=false because X-Club-Session is validated by the RPC.
type Env = (name: string) => string | undefined;
type Fetcher = typeof fetch;

const MAX_BODY_BYTES = 32 * 1024;
const ACTIONS = new Set([
  "bootstrap", "dashboard", "event_proof", "clubs", "players", "create", "feed", "mine", "detail", "add_info",
  "admin_list", "admin_update", "admin_validate_club",
]);
const DEFAULT_ORIGINS = [
  "https://talleresclubabierto.com", "https://www.talleresclubabierto.com",
  "https://localhost", "http://localhost", "capacitor://localhost",
];

class RequestFailure extends Error {
  status: number;
  code: string;
  constructor(status: number, code: string, message: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

async function readJson(req: Request): Promise<Record<string, unknown>> {
  if (!req.headers.get("content-type")?.toLowerCase().startsWith("application/json")) {
    throw new RequestFailure(415, "unsupported_media_type", "Enviá los datos como JSON");
  }
  const size = Number(req.headers.get("content-length"));
  if (Number.isFinite(size) && size > MAX_BODY_BYTES) {
    throw new RequestFailure(413, "payload_too_large", "El formulario supera el tamaño permitido");
  }
  if (!req.body) throw new RequestFailure(400, "invalid_json", "Faltan los datos del formulario");
  const reader = req.body.getReader();
  const chunks: Uint8Array[] = [];
  let length = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.byteLength;
      if (length > MAX_BODY_BYTES) {
        await reader.cancel();
        throw new RequestFailure(413, "payload_too_large", "El formulario supera el tamaño permitido");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
  let parsed: unknown;
  try { parsed = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes)); }
  catch { throw new RequestFailure(400, "invalid_json", "El formulario no tiene un formato válido"); }
  if (!isRecord(parsed)) throw new RequestFailure(400, "invalid_json", "El formulario no tiene un formato válido");
  return parsed;
}

function serviceKey(env: Env): string | undefined {
  const legacy = env("SUPABASE_SERVICE_ROLE_KEY");
  if (legacy) return legacy;
  try {
    const keys: unknown = JSON.parse(env("SUPABASE_SECRET_KEYS") ?? "{}");
    if (isRecord(keys)) {
      if (typeof keys.default === "string" && keys.default.startsWith("sb_secret_")) return keys.default;
      for (const value of Object.values(keys)) {
        if (typeof value === "string" && value.startsWith("sb_secret_")) return value;
      }
    }
  } catch { /* no values are logged */ }
  return undefined;
}

export function makeHandler(env: Env, fetcher: Fetcher = fetch) {
  const allowedOrigins = new Set(DEFAULT_ORIGINS);
  for (const value of (env("SCOUTING_ALLOWED_ORIGINS") ?? "").split(",")) {
    const origin = value.trim();
    if (/^https?:\/\/[^/\s]+$/.test(origin)) allowedOrigins.add(origin);
  }
  return async function handler(req: Request): Promise<Response> {
    const origin = req.headers.get("origin");
    const corsAllowed = origin !== null && allowedOrigins.has(origin);
    const headers: Record<string, string> = {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store, max-age=0",
      "Vary": "Origin",
      "X-Content-Type-Options": "nosniff",
      "Referrer-Policy": "no-referrer",
    };
    if (corsAllowed) {
      headers["Access-Control-Allow-Origin"] = origin;
      headers["Access-Control-Allow-Methods"] = "POST, OPTIONS";
      headers["Access-Control-Allow-Headers"] = "content-type, apikey, x-club-session, authorization, x-client-info";
      headers["Access-Control-Max-Age"] = "600";
    }
    const reply = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers });
    try {
      if (origin && !corsAllowed) throw new RequestFailure(403, "origin_not_allowed", "El origen de la solicitud no está habilitado");
      if (req.method === "OPTIONS") return new Response(null, { status: 204, headers });
      if (req.method !== "POST") throw new RequestFailure(405, "method_not_allowed", "Usá POST para esta operación");
      const token = req.headers.get("x-club-session")?.trim() ?? "";
      if (token.length < 32 || token.length > 512) {
        throw new RequestFailure(401, "session_required", "Ingresá nuevamente con tu número de socio");
      }
      const body = await readJson(req);
      if (typeof body.action !== "string" || !ACTIONS.has(body.action)) {
        throw new RequestFailure(422, "invalid_action", "La operación solicitada no está disponible");
      }
      if (body.payload !== undefined && !isRecord(body.payload)) {
        throw new RequestFailure(422, "invalid_payload", "Los datos del formulario no son válidos");
      }
      const baseUrl = env("SUPABASE_URL")?.replace(/\/+$/, "");
      const key = serviceKey(env);
      if (!baseUrl || !/^https:\/\/[^/]+$/.test(baseUrl) || !key) {
        throw new RequestFailure(503, "service_unavailable", "Scouting no está disponible en este momento");
      }
      const rpcHeaders: Record<string, string> = { "Content-Type": "application/json", "apikey": key };
      if (!key.startsWith("sb_secret_")) rpcHeaders.Authorization = `Bearer ${key}`;
      let upstream: Response;
      try {
        upstream = await fetcher(`${baseUrl}/rest/v1/rpc/scouting_api`, {
          method: "POST", headers: rpcHeaders,
          body: JSON.stringify({ p_token: token, p_action: body.action, p_payload: body.payload ?? {} }),
          signal: AbortSignal.timeout(15_000),
        });
      } catch {
        throw new RequestFailure(503, "service_unavailable", "No se pudo conectar. Podés reintentar el mismo envío");
      }
      let data: unknown;
      try { data = await upstream.json(); }
      catch { throw new RequestFailure(503, "service_unavailable", "No se pudo completar la operación"); }
      if (!upstream.ok) {
        const dbCode = isRecord(data) && typeof data.code === "string" ? data.code : "";
        const statuses: Record<string, number> = { PT401: 401, PT403: 403, PT404: 404, PT409: 409, PT422: 422, PT429: 429 };
        const codes: Record<string, string> = {
          PT401: "session_expired", PT403: "forbidden", PT404: "not_found",
          PT409: "conflict", PT422: "validation_error", PT429: "rate_limited",
        };
        if (statuses[dbCode] && isRecord(data) && typeof data.message === "string") {
          throw new RequestFailure(statuses[dbCode], codes[dbCode], data.message.slice(0,300));
        }
        // Never pass database details, submitted values or server credentials through.
        throw new RequestFailure(503, "service_unavailable", "No se pudo completar la operación. Podés reintentar el mismo envío");
      }
      if (!isRecord(data) || data.ok !== true) {
        throw new RequestFailure(503, "service_unavailable", "El servicio no confirmó la operación");
      }
      return reply(data);
    } catch (error) {
      if (error instanceof RequestFailure) {
        return reply({ ok: false, error: { code: error.code, message: error.message } }, error.status);
      }
      return reply({ ok: false, error: { code: "service_unavailable", message: "No se pudo completar la operación" } }, 503);
    }
  };
}

if (typeof Deno !== "undefined") {
  Deno.serve(makeHandler((name) => Deno.env.get(name)));
}
