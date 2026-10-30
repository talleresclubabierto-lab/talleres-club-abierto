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

test('shared dashboard forwards one authenticated RPC and preserves global counts beyond one page', async () => {
  let calls = 0;
  let sent;
  const expected = { ok: true, dashboard: {
    total_recommendations: 37, identified_players: 2, unverified_player_references: 33,
    total_player_references: 35, contacted: 4, visited: 2, invited_to_trial: 1,
    trial_completed: 1, not_advanced: 1, milestone_unit: 'player_references',
    scope: 'all_recommendations',
  } };
  const handler = makeHandler(env, async (_url, init) => {
    calls++; sent = JSON.parse(init.body);
    return Response.json(expected);
  });
  const response = await handler(request({ action: 'dashboard', payload: {} }));
  assert.equal(response.status, 200);
  assert.equal(calls, 1);
  assert.deepEqual(sent, { p_token: token, p_action: 'dashboard', p_payload: {} });
  assert.deepEqual(await response.json(), expected);
  assert.match(response.headers.get('cache-control'), /no-store/);
});

test('member panel context and optional age reach the authoritative RPC unchanged', async () => {
  let sent;
  const payload = { panel_context: 'socio', request_id: '00000000-0000-4000-8000-000000000001',
    reference_recommendation_id: '00000000-0000-4000-8000-000000000002',
    player: { first_name: 'Synthetic', last_name: 'Player', age_at_recommendation: 17 } };
  const handler = makeHandler(env, async (_url, init) => {
    sent = JSON.parse(init.body);
    return Response.json({ code: 'PT422', message: 'Faltan los otros datos de la ficha' }, { status: 422 });
  });
  const response = await handler(request({ action: 'create', payload }));
  assert.equal(response.status, 422);
  assert.deepEqual(sent, { p_token: token, p_action: 'create', p_payload: payload });
  assert.equal((await response.json()).error.message, 'Faltan los otros datos de la ficha');
});

test('a selected event proof keeps its own event identity and unconfirmed status', async () => {
  let sent;
  const eventId = '00000000-0000-4000-8000-000000000003';
  const expected = { ok: true, event_id: eventId, proof: {
    status: 'preparada', commitment_hash: 'a'.repeat(64), audit_event_id: 42,
    transaction_hash: null, merkle_valid: true,
  } };
  const handler = makeHandler(env, async (_url, init) => {
    sent = JSON.parse(init.body);
    return Response.json(expected);
  });
  const response = await handler(request({ action: 'event_proof', payload: { event_id: eventId } }));
  assert.equal(response.status, 200);
  assert.deepEqual(sent, { p_token: token, p_action: 'event_proof', p_payload: { event_id: eventId } });
  assert.deepEqual(await response.json(), expected);
  assert.match(response.headers.get('cache-control'), /no-store/);
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
