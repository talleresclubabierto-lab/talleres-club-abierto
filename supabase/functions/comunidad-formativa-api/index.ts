import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const ORIGIN = "https://www.talleresclubabierto.com";
const BASE_HEADERS = {
  "Access-Control-Allow-Origin": ORIGIN,
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "content-type",
  "Cache-Control": "no-store",
  "Vary": "Origin",
};
const MAX_BODY_BYTES = 4096;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function json(body: unknown, status = 200): Response {
  return Response.json(body, { status, headers: BASE_HEADERS });
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
  if (!emailReady()) return json({ error: "otp_temporarily_unavailable" }, 503);
  if (!payload || typeof payload !== "object") return json({ error: "invalid_request" }, 400);
  const emailValue = (payload as Record<string, unknown>).email;
  if (typeof emailValue !== "string" || emailValue.length > 254) {
    return json({ error: "invalid_request" }, 400);
  }
  const email = emailValue.trim().toLowerCase();
  if (!EMAIL_RE.test(email)) return json({ error: "invalid_request" }, 400);

  const encryptionKey = base64Bytes(Deno.env.get("CF_DATA_ENCRYPTION_KEY_V1") ?? "");
  const lookupKey = base64Bytes(Deno.env.get("CF_LOOKUP_HMAC_KEY_V1") ?? "");
  const resendKey = Deno.env.get("RESEND_API_KEY");
  const sender = Deno.env.get("CF_EMAIL_FROM");
  if (!encryptionKey || !lookupKey || !resendKey || !sender) {
    return json({ error: "otp_temporarily_unavailable" }, 503);
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
      return json({ ok: true, message: "Si el envío es posible, recibirás un código en el correo indicado." });
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
          text: `Tu código de verificación es ${code}. Vence en 5 minutos. Si no solicitaste este código, ignora este correo. Este código solo verifica el correo y no habilita una cuenta ni confirma pertenencia a divisiones formativas.`,
        }),
      });
      sent = response.ok;
    } finally {
      clearTimeout(timeout);
    }
    if (!sent) {
      await rpc("community_formative_revoke_email_otp", { p_id: id });
      return json({ error: "otp_temporarily_unavailable" }, 503);
    }
    return json({ ok: true, challenge_id: id, message: "Si el envío es posible, recibirás un código en el correo indicado." });
  } catch {
    return json({ error: "otp_temporarily_unavailable" }, 503);
  }
}

async function verifyOtp(payload: unknown) {
  const lookupKey = base64Bytes(Deno.env.get("CF_LOOKUP_HMAC_KEY_V1") ?? "");
  if (!lookupKey) return json({ error: "otp_temporarily_unavailable" }, 503);
  if (!payload || typeof payload !== "object") return json({ error: "invalid_request" }, 400);
  const input = payload as Record<string, unknown>;
  if (typeof input.challenge_id !== "string" ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(input.challenge_id) ||
      typeof input.code !== "string" || !/^\d{6}$/.test(input.code)) {
    return json({ error: "invalid_code" }, 400);
  }
  try {
    const valid = await rpc("community_formative_verify_email_otp", {
      p_id: input.challenge_id,
      p_codigo_hmac: await hmac(lookupKey, `otp:v1:${input.code}`),
    });
    return valid === true
      ? json({ ok: true, email_verified: true, access_enabled: false })
      : json({ error: "invalid_or_expired_code" }, 400);
  } catch {
    return json({ error: "otp_temporarily_unavailable" }, 503);
  }
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("origin");
  if (origin && origin !== ORIGIN) return new Response(null, { status: 403, headers: BASE_HEADERS });
  if (req.method === "OPTIONS") return new Response(null, { headers: BASE_HEADERS });

  if (req.method === "GET") {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    if (!supabaseUrl || !serverKey()) {
      return json({ error: "backend_not_configured", intake_enabled: false }, 503);
    }
    try {
      const state = await rpc("community_formative_status", {});
      if (!state || typeof state !== "object") throw new Error("invalid_status");
      return json({
        phase: state.phase === "foundation_created" ? state.phase : "foundation_created",
        module: "comunidad_formativa",
        intake_enabled: false,
        case_submission_enabled: false,
        blockchain_anchor_enabled: false,
        otp_email_ready: emailReady(),
      });
    } catch {
      return json({ error: "backend_unavailable", intake_enabled: false }, 503);
    }
  }

  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const contentType = req.headers.get("content-type")?.split(";")[0].trim().toLowerCase();
  if (contentType !== "application/json") return json({ error: "unsupported_media_type" }, 415);
  let payload: unknown;
  try {
    const text = await req.text();
    if (new TextEncoder().encode(text).length > MAX_BODY_BYTES) return json({ error: "invalid_request" }, 413);
    payload = JSON.parse(text);
  } catch {
    return json({ error: "invalid_request" }, 400);
  }
  const actionName = payload && typeof payload === "object"
    ? (payload as Record<string, unknown>).action
    : null;
  if (actionName === "otp_request") return requestOtp(req, payload);
  if (actionName === "otp_verify") return verifyOtp(payload);
  return json({ error: "unsupported_action" }, 400);
});
