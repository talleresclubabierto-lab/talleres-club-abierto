import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const cors = {
  "Access-Control-Allow-Origin": "https://www.talleresclubabierto.com",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "content-type",
  "Cache-Control": "no-store",
};

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
      // Use the legacy server key below when present.
    }
  }
  const legacy = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  return legacy ? { key: legacy, isSecret: false } : null;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "GET") {
    return Response.json({ error: "method_not_allowed" }, { status: 405, headers: cors });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const server = serverKey();
  if (!supabaseUrl || !server) {
    return Response.json(
      { error: "backend_not_configured", intake_enabled: false },
      { status: 503, headers: cors },
    );
  }

  try {
    const headers = new Headers({
      "Content-Type": "application/json",
      "apikey": server.key,
    });
    if (!server.isSecret) headers.set("Authorization", `Bearer ${server.key}`);

    const response = await fetch(
      `${supabaseUrl}/rest/v1/rpc/community_formative_status`,
      { method: "POST", headers, body: "{}" },
    );
    if (!response.ok) {
      return Response.json(
        { error: "backend_unavailable", intake_enabled: false },
        { status: 503, headers: cors },
      );
    }
    const state = await response.json();
    return Response.json(state, { headers: cors });
  } catch {
    return Response.json(
      { error: "backend_unavailable", intake_enabled: false },
      { status: 503, headers: cors },
    );
  }
});
