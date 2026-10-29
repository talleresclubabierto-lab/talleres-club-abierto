// Run with: node --experimental-strip-types --test scripts/test-scouting-api.mjs
import test from 'node:test';
import assert from 'node:assert/strict';
import { makeHandler } from '../supabase/functions/scouting-api/index.ts';

const origin = 'https://talleresclubabierto.com';
const token = 'synthetic-session-token-for-handler-tests-only-0001';
const envValues = { SUPABASE_URL: 'https://synthetic.supabase.co', SUPABASE_SERVICE_ROLE_KEY: 'synthetic-service-role-key' };
const env = name => envValues[name];
const request = (body = { action: 'bootstrap' }, extra = {}) => new Request('https://local.example/scouting-api', {
  method: 'POST', headers: { origin, 'content-type': 'application/json', 'x-club-session': token, ...(extra.headers ?? {}) },
  body: JSON.stringify(body), ...Object.fromEntries(Object.entries(extra).filter(([key]) => key !== 'headers')),
});

test('RPC receives the existing club session and only the documented parameters', async () => {
  let called;
  const handler = makeHandler(env, async (url, init) => {
    called = { url, init };
    return Response.json({ ok: true, actor: { numero_socio: 1, role: 'socio' } });
  });
  const response = await handler(request({ action: 'bootstrap', payload: {} }));
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('access-control-allow-origin'), origin);
  assert.match(response.headers.get('cache-control'), /no-store/);
  assert.equal(called.url, 'https://synthetic.supabase.co/rest/v1/rpc/scouting_api');
  assert.deepEqual(JSON.parse(called.init.body), { p_token: token, p_action: 'bootstrap', p_payload: {} });
  assert.equal(called.init.headers.Authorization, 'Bearer synthetic-service-role-key');
  assert.equal((await response.json()).ok, true);
});

test('missing sessions, foreign origins and unsupported actions never reach the RPC', async () => {
  let calls = 0;
  const handler = makeHandler(env, async () => { calls++; return Response.json({ ok: true }); });
  const missing = await handler(request(undefined, { headers: { 'x-club-session': '' } }));
  assert.equal(missing.status, 401);
  const foreign = await handler(request(undefined, { headers: { origin: 'https://untrusted.example' } }));
  assert.equal(foreign.status, 403);
  assert.equal(foreign.headers.get('access-control-allow-origin'), null);
  const action = await handler(request({ action: 'admin_import_from_arbitrary_url' }));
  assert.equal(action.status, 422);
  assert.equal(calls, 0);
});

test('preflight and method restrictions work independently of credentials', async () => {
  const handler = makeHandler(() => undefined, async () => { throw new Error('must not call'); });
  const preflight = await handler(new Request('https://local.example', { method: 'OPTIONS', headers: { origin } }));
  assert.equal(preflight.status, 204);
  assert.match(preflight.headers.get('access-control-allow-headers'), /x-club-session/);
  const get = await handler(new Request('https://local.example', { headers: { origin } }));
  assert.equal(get.status, 405);
});

test('body bounds, malformed JSON and non-object payloads fail before service access', async () => {
  let calls = 0;
  const handler = makeHandler(env, async () => { calls++; return Response.json({ ok: true }); });
  const oversize = await handler(request({ action: 'create', payload: { reason: 'x'.repeat(33 * 1024) } }));
  assert.equal(oversize.status, 413);
  const malformed = await handler(new Request('https://local.example', {
    method: 'POST', headers: { origin, 'content-type': 'application/json', 'x-club-session': token }, body: '{',
  }));
  assert.equal(malformed.status, 400);
  const array = await handler(request({ action: 'create', payload: [] }));
  assert.equal(array.status, 422);
  assert.equal(calls, 0);
});

test('expected authorization/conflict/quota errors retain status and safe message', async () => {
  for (const status of [401, 403, 404, 409, 422, 429]) {
    const handler = makeHandler(env, async () => Response.json({ code: `PT${status}`, message: 'Mensaje controlado' }, { status }));
    const response = await handler(request({ action: 'detail', payload: { id: 'invalid' } }));
    assert.equal(response.status, status);
    assert.deepEqual(Object.keys(await response.clone().json()).sort(), ['error', 'ok']);
    assert.equal((await response.json()).error.message, 'Mensaje controlado');
  }
});

test('unexpected backend details and failed fetch never disclose values', async () => {
  const privateValue = 'private-player-name-and-server-secret';
  for (const fetcher of [
    async () => Response.json({ code: '23505', message: privateValue, detail: privateValue }, { status: 500 }),
    async () => { throw new Error(privateValue); },
    async () => new Response(privateValue, { status: 200 }),
  ]) {
    const response = await makeHandler(env, fetcher)(request());
    assert.equal(response.status, 503);
    assert.equal((await response.text()).includes(privateValue), false);
  }
});

test('modern service secrets are never sent as JWT bearer tokens', async () => {
  let headers;
  const handler = makeHandler(name => ({
    SUPABASE_URL: 'https://synthetic.supabase.co',
    SUPABASE_SECRET_KEYS: JSON.stringify({ default: 'sb_secret_synthetic_only' }),
  })[name], async (_, init) => { headers = init.headers; return Response.json({ ok: true }); });
  const response = await handler(request());
  assert.equal(response.status, 200);
  assert.equal(headers.apikey, 'sb_secret_synthetic_only');
  assert.equal(headers.Authorization, undefined);
  assert.equal((await response.text()).includes('sb_secret_'), false);
});
