import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { webcrypto } from 'node:crypto';

const app = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const html = fs.readFileSync(path.join(app, 'scouting.html'), 'utf8');
const source = fs.readFileSync(path.join(app, 'scouting/scouting.js'), 'utf8');
const tick = () => new Promise(resolve => setTimeout(resolve, 0));
const reply = data => ({ ok: true, status: 200, json: async () => ({ ok: true, ...data }) });
const exported = 'state,channels,timers,initialiseForm,applyPanelContext,canRecommend,canManage,createPayload,verifiedMarketValue,card,loadDashboard,loadList,renderList,activateTab,openDetail,clearSessionState,selectPlayer,renderRanking,renderEvents,renderProof,recommendAlso,clearRecommendationReference,loadPlayers,loadClubs,selectClub,renderSquad,changeCountry,newRecommendation,dispose,api';
assert(source.includes('  boot();\n  return Object.freeze({ dispose });'), 'The test harness must replace only the component boot call.');

const countries = [
  { code: 'AR', name: 'Argentina', region_label: 'Provincia' },
  { code: 'BR', name: 'Brasil', region_label: 'Estado' },
  { code: 'CL', name: 'Chile', region_label: 'Región' },
  { code: 'CO', name: 'Colombia', region_label: 'Departamento' },
  { code: 'EC', name: 'Ecuador', region_label: 'Provincia' },
  { code: 'UY', name: 'Uruguay', region_label: 'Departamento' }
];
const regionNames = { AR: 'Córdoba', BR: 'São Paulo', CL: 'Metropolitana', CO: 'Antioquia', EC: 'Pichincha', UY: 'Montevideo' };
function countryBootstrap(code, overrides = {}) {
  const country = countries.find(entry => entry.code === code);
  const value = code === 'AR' ? regionNames[code] : `${country.name} — ${regionNames[code]}`;
  return {
    country_code: code, countries, actor: { role: 'socio', numero_socio: '123' },
    regions: [{ value, label: regionNames[code], country_code: code, club_count: 1 }], provinces: [value],
    competitions: [{ id: `${code}-national`, name: `Liga ${country.name}`, country_code: code, season: '2026' }],
    catalogue: { club_count: code === 'AR' ? 153 : 40, player_count: code === 'AR' ? 5627 : 1200 },
    categories: ['Primera', 'Reserva'], positions: ['Arquero', 'Defensor Central'], ...overrides
  };
}

function harness(context = 'socio', embedded = true) {
  const elements = new Map();
  class Element {
    constructor(tag = 'div') { this.tagName = tag.toUpperCase(); this.value = ''; this._text = ''; this.children = []; this.listeners = new Map(); this.hidden = false; this.disabled = false; this.checked = false; this.open = false; this.dataset = {}; this.attributes = {}; this.isConnected = true; }
    get textContent() { return this._text + this.children.map(child => child.textContent || '').join(' '); }
    set textContent(value) { this._text = String(value ?? ''); this.children = []; }
    get options() { return this.children; }
    get childElementCount() { return this.children.length; }
    addEventListener(type, callback) { const callbacks = this.listeners.get(type) || []; callbacks.push(callback); this.listeners.set(type, callbacks); }
    removeEventListener(type, callback) { this.listeners.set(type, (this.listeners.get(type) || []).filter(item => item !== callback)); }
    fire(type, extra = {}) { return Promise.all((this.listeners.get(type) || []).map(callback => callback({ target: this, preventDefault() {}, ...extra }))); }
    setAttribute(key, value) { this.attributes[key] = String(value); }
    getAttribute(key) { return this.attributes[key] ?? null; }
    removeAttribute(key) { delete this.attributes[key]; delete this[key]; }
    setCustomValidity(value) { this.validationMessage = value; }
    reportValidity() { return true; }
    append(...children) { for (const child of children) { if (child.parentNode) child.parentNode.children = child.parentNode.children.filter(entry => entry !== child); child.parentNode = this; this.children.push(child); } }
    prepend(...children) { this.children.unshift(...children); }
    replaceChildren(...children) { this._text = ''; for (const child of this.children) child.parentNode = null; this.children = []; this.append(...children); if (this.tagName === 'SELECT') this.value = children[0]?.value || ''; }
    querySelectorAll() { return []; }
    querySelector() { return null; }
    focus() {}
    scrollIntoView() {}
    reset() { for (const match of html.slice(html.indexOf('<form id="recommend-form"'), html.indexOf('</form>')).matchAll(/id="([^"]+)"/g)) { const element = elements.get(match[1]); if (element && ['INPUT', 'SELECT', 'TEXTAREA'].includes(element.tagName)) { element.value = ''; element.checked = false; } } }
    showModal() { this.open = true; }
    close() { this.open = false; void this.fire('close'); }
  }
  for (const match of html.matchAll(/<([a-z][\w-]*)\b([^>]*\bid="([^"]+)"[^>]*)>/g)) {
    assert(!elements.has(match[3]), 'Duplicate HTML ID: ' + match[3]);
    const element = new Element(match[1]); element.hidden = /\bhidden\b/.test(match[2]); elements.set(match[3], element);
  }
  const el = id => { assert(elements.has(id), 'Missing static HTML ID: ' + id); return elements.get(id); };
  const tabs = ['mine', 'recommend'].map(id => { const element = el('tab-' + id); element.dataset.tab = id; return element; });
  const routes = ['province', 'competition'].map(value => { const element = new Element('input'); element.value = value; element.checked = value === 'province'; return element; });
  const querySelector = selector => selector === '[name="search-route"]:checked' ? routes.find(element => element.checked) : null;
  const querySelectorAll = selector => selector === '[data-tab]' ? tabs : selector === '[name="search-route"]' ? routes : [];
  const events = new Map(); const documentEvents = new Map(); const parent = {};
  const window = { location: { origin: 'https://club.example', search: '?panel_context=' + context }, parent, addEventListener(type, callback) { const callbacks = events.get(type) || []; callbacks.push(callback); events.set(type, callbacks); }, removeEventListener(type, callback) { events.set(type, (events.get(type) || []).filter(item => item !== callback)); } };
  const fireWindow = (type, event = {}) => { for (const callback of events.get(type) || []) callback(event); };
  const calls = []; let handler = async () => reply({ items: [], next_cursor: null }); let sessionToken = 'test-session';
  const sandbox = { window, location: { hash: '' }, document: { body: { hasAttribute: () => false }, getElementById: el, createElement: tag => new Element(tag), querySelector, querySelectorAll, addEventListener(type, callback) { const callbacks = documentEvents.get(type) || []; callbacks.push(callback); documentEvents.set(type, callbacks); }, removeEventListener(type, callback) { documentEvents.set(type, (documentEvents.get(type) || []).filter(item => item !== callback)); } }, sessionStorage: { getItem: () => sessionToken }, URL, URLSearchParams, Date, Intl, AbortController, DOMException, setTimeout, clearTimeout, crypto: webcrypto, Option: class extends Element { constructor(text, value) { super('option'); this._text = text; this.value = String(value); } }, fetch: async (_url, options) => { const request = JSON.parse(options.body); calls.push(request); return handler(request, options.signal); } };
  vm.runInNewContext(source.replace('  boot();\n  return Object.freeze({ dispose });', '  globalThis.review={' + exported + '};\n  return Object.freeze({ dispose });'), sandbox, { filename: 'scouting.js' });
  const mountRoot = embedded ? { getElementById: el, querySelector: sandbox.document.querySelector, querySelectorAll: sandbox.document.querySelectorAll } : sandbox.document;
  if (embedded) { sandbox.document.getElementById = () => { throw new Error('Native component escaped its DOM scope'); }; sandbox.document.querySelectorAll = () => { throw new Error('Native component queried the outer panel'); }; }
  window.ClubAbiertoScouting.mount(mountRoot, { panelContext: context });
  const review = sandbox.review;
  review.state.actor = { role: 'socio', numero_socio: '123' }; review.state.activeToken = 'test-session';
  review.state.bootstrap = countryBootstrap('AR', { competitions: [] });
  review.initialiseForm(review.state.bootstrap);
  return { ...review, el, calls, window, parent, fireWindow, listenerCount: () => [...events.values(), ...documentEvents.values(), ...[...elements.values(), ...routes].flatMap(element => [...element.listeners.values()])].reduce((total, callbacks) => total + callbacks.length, 0), setHandler: next => { handler = next; }, setToken: value => { sessionToken = value; }, setRoute: value => { for (const element of routes) element.checked = element.value === value; return routes.find(element => element.checked).fire('change'); } };
}

const recommendation = { id: 'r-1', code: 'SC-001', status: 'contactado', created_at: '2026-10-30T12:00:00Z', player: { first_name: 'Jugador', last_name: 'Demostración', position: 'Arquero', age_at_recommendation: null, market_value: null }, club: { name: 'Club de prueba', province: 'Córdoba', competition_name: 'Liga local' }, author: { numero_socio: '123', name: 'Socio Visible' }, category: 'Primera', can_manage: true, can_add_info: true };
const dashboard = { total_player_references: 137, total_recommendations: 150, identified_players: 120, unverified_player_references: 17, contacted: 34, visited: 20, invited_to_trial: 8, trial_completed: 5, not_advanced: 3, scope: 'all_recommendations', milestone_unit: 'player_references', as_of: '2026-10-30T12:00:00Z', most_recommended_players: [] };

// Context is presentation only: an authenticated administrator must also be in
// the administrative panel to see the administrative controls.
{
  const h = harness(); h.state.list.loaded = true; h.applyPanelContext('socio'); assert(h.canRecommend());
  h.applyPanelContext('admin'); assert(!h.canRecommend()); assert(!h.canManage(recommendation)); assert.equal(h.createPayload(), null);
  h.state.actor.role = 'admin'; assert(h.canManage(recommendation)); h.applyPanelContext('socio'); assert(!h.canManage(recommendation)); assert(h.canRecommend());
  h.fireWindow('message', { origin: 'https://elsewhere.example', source: h.parent, data: { type: 'club-abierto:scouting-context', panel_context: 'admin' } }); assert.equal(h.state.panelContext, 'socio');
  h.fireWindow('message', { origin: h.window.location.origin, source: {}, data: { type: 'club-abierto:scouting-context', panel_context: 'admin' } }); assert.equal(h.state.panelContext, 'socio');
  h.state.list.items = [recommendation]; h.renderList(); const originalCard = h.el('mine-list').children[0];
  let resolveDashboard; let dashboardSignal;
  h.setHandler((_request, signal) => { dashboardSignal = signal; return new Promise(resolve => { resolveDashboard = resolve; }); });
  const pending = h.loadDashboard(); const listenerCount = h.listenerCount();
  for (let index = 0; index < 20; index++) h.fireWindow('message', { origin: h.window.location.origin, source: h.parent, data: { type: 'club-abierto:scouting-context', panel_context: 'socio' } });
  assert.equal(h.calls.length, 1); assert.equal(dashboardSignal.aborted, false); assert.equal(h.el('mine-list').children[0], originalCard); assert.equal(h.listenerCount(), listenerCount);
  resolveDashboard(reply({ dashboard })); await pending; assert.equal(h.el('metric-recomendados').textContent, '137');
  h.setHandler(async () => reply({ dashboard })); for (let index = 0; index < 8; index++) await h.loadDashboard(); assert.equal(h.channels.size, 1);
  let unwantedTimer = false; h.timers.set('pending-search', setTimeout(() => { unwantedTimer = true; }, 10)); h.fireWindow('pagehide');
  await new Promise(resolve => setTimeout(resolve, 20)); assert.equal(h.channels.size, 0); assert.equal(h.timers.size, 0); assert.equal(unwantedTimer, false);
  console.log('PASS context: direct component context, unsolicited messages cannot change roles, no extra requests/listeners; pagehide clears reads and timers.');
}

{ const standalone = harness('admin', false); assert.equal(standalone.state.panelContext, 'admin'); standalone.dispose(); }

// The metrics are authoritative global counts, separate from the current page.
{
  const h = harness(); h.setHandler(async request => request.action === 'dashboard' ? reply({ dashboard }) : reply({ items: [recommendation], next_cursor: 'next' }));
  await h.loadDashboard(); h.el('mine-status').value = 'contactado'; h.el('mine-query').value = 'Jugador'; h.el('mine-only').checked = true;
  await h.loadList(); assert.equal(h.calls.at(-1).action, 'feed'); assert.equal(h.calls.at(-1).payload.mine_only, true); assert.equal(h.el('metric-recomendados').textContent, '137');
  h.el('mine-query').value = 'Another query'; await h.loadList(true); assert.equal(h.calls.at(-1).payload.query, 'Jugador'); assert.equal(h.calls.at(-1).payload.cursor, 'next'); assert.equal(h.state.list.items.length, 1);
  h.setHandler(async () => reply({ dashboard: { ...dashboard, milestone_unit: 'recommendations' } })); await h.loadDashboard(); assert.equal(h.el('metric-recomendados').textContent, '137'); assert.equal(h.el('dashboard-feedback').hidden, false);
  h.state.dashboard.loaded = true; h.el('manual-club-toggle').checked = true;
  h.setHandler(async (_request, signal) => new Promise((_resolve, reject) => signal.addEventListener('abort', () => reject(new DOMException('Aborted', 'AbortError')), { once: true })));
  const pending = h.loadList(true); assert.equal(h.el('mine-more').disabled, true); h.activateTab('recommend'); await pending; h.activateTab('mine'); assert.equal(h.el('mine-more').disabled, false);
  console.log('PASS feed: common filters, stable pagination snapshot, global counts independent of rows, wrong metric units rejected, canceled pagination resumes.');
}

// Missing ages/values remain explicit; member input never supplies a market value.
{
  const h = harness(); const $ = h.el;
  $('manual-club-toggle').checked = true; $('manual-province').value = 'Córdoba'; $('manual-city').value = 'Córdoba'; $('manual-club-name').value = 'Club Ejemplo'; $('manual-league').value = 'Liga local'; $('player-category').value = 'Primera'; $('player-first-name').value = 'Jugador'; $('player-last-name').value = 'Demostración'; $('player-position').value = 'Arquero'; $('recommend-reason').value = 'Un motivo deportivo de más de veinte caracteres.';
  let payload = h.createPayload(); assert.equal(payload.panel_context, 'socio'); assert.equal(payload.player.age_at_recommendation, null); assert.equal('market_value' in payload.player, false);
  $('player-age').value = '23'; assert.equal(h.createPayload().player.age_at_recommendation, 23); $('player-age').value = '23.5'; assert.equal(h.createPayload(), null); $('player-age').value = '101'; assert.equal(h.createPayload(), null);
  const market = { amount: 250000, currency: 'EUR', source: 'Transfermarkt', source_url: 'https://www.transfermarkt.com/example/profil/spieler/123', as_of: '2026-10-29', verified_at: '2026-10-30T12:00:00Z', verification: 'verified' };
  assert(h.verifiedMarketValue(market)); assert.equal(h.verifiedMarketValue({ ...market, verification: 'pending' }), null); assert.equal(h.verifiedMarketValue({ ...market, source_url: 'https://transfermarkt.com.attacker.example/example/profil/spieler/123' }), null);
  const text = h.card(recommendation).textContent; assert.match(text, /Sin edad informada/); assert.match(text, /Sin valor informado/); assert.match(text, /N° 123 · Socio Visible/); assert.match(text, /Liga local/);
  const marketText = h.card({ ...recommendation, player: { ...recommendation.player, age_at_recommendation: 23, market_value: market } }).textContent; assert.match(marketText, /23 años/); assert.match(marketText, /Valor al/); assert.match(marketText, /Verificado el/);
  h.state.selectedClub = { id: 'c' }; h.state.players.set('p', { id: 'p', first_name: 'Jugador', last_name: 'Actual', age_current: 22, age_at_recommendation: 20 }); $('player-choice').value = 'p'; h.selectPlayer(); assert.equal($('player-age').value, '22'); await $('player-first-name').fire('input'); assert.equal($('player-age').value, '');
  $('player-choice').value = 'p'; h.selectPlayer(); $('player-age').value = '23'; await $('player-age').fire('input'); await $('player-first-name').fire('input'); assert.equal($('player-age').value, '23');
  console.log('PASS data: optional ages, exact legacy labels, current catalogue age, manual corrections, verified market provenance, no member-supplied market value.');
}

// Ranking navigation uses a catalogue ID, never a name-based merge of homonyms.
{
  const h = harness(); h.state.dashboard.loaded = true; const rows = Array.from({ length: 12 }, (_, index) => ({ identity_type: 'catalogue', player_id: 'p-' + index, recommendation_count: index + 2, player: { first_name: 'Jugador', last_name: String(index) }, club: { name: 'Club ' + index } }));
  rows.push({ identity_type: 'manual', player_id: 'manual', recommendation_count: 99, player: { first_name: 'Do not merge', last_name: 'homonyms' } }); h.renderRanking(rows);
  assert.equal(h.el('ranking-list').childElementCount, 10); assert(!h.el('ranking-list').textContent.includes('homonyms'));
  await h.el('ranking-list').children[0].children[2].fire('click'); await tick(); assert.equal(h.calls.at(-1).payload.player_id, 'p-11'); assert.equal(h.calls.at(-1).payload.mine_only, false);
  await h.el('player-filter-clear').fire('click'); await tick(); assert.equal(h.calls.at(-1).payload.player_id, null);
  h.renderRanking([]); assert.equal(h.el('ranking-list').hidden, true); assert.match(h.el('ranking-empty').textContent, /dos o más/);
  h.state.referenceRecommendation = { id: 'private-session-reference', firstName: 'Previous', lastName: 'Member' }; h.el('player-first-name').readOnly = true;
  h.clearSessionState(); assert.equal(h.state.referenceRecommendation, null); assert.equal(h.el('reference-notice').hidden, true); assert.equal(h.el('player-first-name').readOnly, false); assert.equal(h.el('ranking-list').childElementCount, 0); assert.equal(h.state.rankedPlayerFilter, null); assert.equal(h.el('metric-recomendados').textContent, '—'); assert.equal(h.el('mine-list').childElementCount, 0);
  console.log('PASS ranking: minimum two, top ten, exact player-ID filtering, honest empty state, and complete session cleanup.');
}

// Manual identities join only when a member explicitly recommends the same reference.
{
  const h = harness(); const $ = h.el;
  const manual = { ...recommendation, id: 'manual-origin', player: { ...recommendation.player, reference_id: 'server-managed-reference', age_at_recommendation: 28 }, club: { name: 'Club de barrio', city: 'Córdoba', province: 'Córdoba', league: 'Liga local', source: 'manual' } };
  h.recommendAlso(manual);
  assert.equal(h.state.referenceRecommendation.id, 'manual-origin'); assert.equal($('player-first-name').readOnly, true); assert.equal($('player-first-name').value, manual.player.first_name); assert.equal($('player-last-name').readOnly, true);
  assert.equal($('player-age').value, ''); assert.equal($('recommend-reason').value, ''); assert.equal($('manual-club-name').value, 'Club de barrio'); assert.equal($('player-lookup').hidden, true);
  $('recommend-reason').value = 'Mi propia observación deportiva para recomendar al mismo jugador.';
  let payload = h.createPayload(); assert.equal(payload.reference_recommendation_id, 'manual-origin'); assert.equal(payload.player_id, null); assert.equal(payload.player.age_at_recommendation, null); assert.equal('reference_id' in payload.player, false);
  $('player-age').value = '29'; $('player-position').value = 'Defensor Central'; await $('player-category').fire('change'); assert.equal(h.state.referenceRecommendation.id, 'manual-origin'); assert.equal($('player-first-name').value, manual.player.first_name); assert.equal($('player-age').value, '29');
  await $('reference-clear').fire('click'); assert.equal(h.state.referenceRecommendation, null); assert.equal($('player-first-name').readOnly, false); assert.equal($('player-first-name').value, '');
  h.recommendAlso(manual); $('player-first-name').value = 'Otra persona'; await $('player-first-name').fire('input'); assert.equal(h.state.referenceRecommendation, null); assert.equal($('player-first-name').readOnly, false);
  const pending = { request_id: 'pending-original' }; h.state.createPending = pending; h.recommendAlso(manual); assert.equal(h.state.createPending, pending); assert.equal(h.state.referenceRecommendation, null); assert.match($('create-feedback').textContent, /envío pendiente/); h.state.createPending = null;
  h.state.activeTab = 'mine'; h.state.dashboard.loaded = true;
  h.renderRanking([{identity_type:'member_reference',identity_verification:'member_declared',player_id:null,reference_recommendation_id:'manual-origin',recommendation_count:2,player:manual.player,club:manual.club}]);
  assert.match($('ranking-list').textContent,/Identidad declarada por socios/); await $('ranking-list').children[0].children[2].fire('click'); await tick(); assert.equal(h.calls.at(-1).payload.reference_recommendation_id, 'manual-origin'); assert.equal(h.calls.at(-1).payload.player_id, null);
  h.applyPanelContext('admin'); h.recommendAlso(manual); assert.equal(h.state.referenceRecommendation, null);
  console.log('PASS explicit references: manual identity is linked by source recommendation, name locks/reset, new age/reason, independent club/category evidence, no client reference ID, pending payload preserved, exact manual ranking filter, no creation from admin context.');
}

// Cryptographic proofs are requested only when opened, with server-supplied status.
{
  const h = harness(); h.state.currentDetailId = 'r-1'; h.el('detail-dialog').open = true;
  const event = { id: 'event-1', type: 'status_changed', previous_status: 'recibida', new_status: 'contactado', status: 'contactado', actor: { name: 'Gestor Visible', numero_socio: '900', role: 'admin' }, created_at: '2026-10-30T12:00:00Z', message: 'Motivo público del cambio' };
  const history = h.renderEvents([event]); assert.equal(h.calls.length, 0); assert.match(history.textContent, /Recibida → Contactado/); assert.match(history.textContent, /N° 900 · Gestor Visible/); assert.match(history.textContent, /Motivo público del cambio/);
  h.setHandler(async request => reply({ event_id: request.payload.event_id, proof: { status: 'registrada', commitment_hash: 'a'.repeat(64) } }));
  const proofContainer = history.children[1].children[0].children[3]; await proofContainer.children[0].fire('click'); assert.equal(h.calls.at(-1).action, 'event_proof'); assert.equal(h.calls.at(-1).payload.event_id, 'event-1'); assert.match(proofContainer.textContent, /todavía no está confirmado/); assert(!proofContainer.textContent.includes('Anclaje confirmado'));
  for (const [status, label] of [['registrada', 'Registrada en auditoría'], ['preparada', 'Preparada para anclaje'], ['enviada', 'Anclaje enviado, pendiente de confirmación'], ['anclada', 'Anclaje confirmado']]) assert(h.renderProof({ status, commitment_hash: 'b'.repeat(64) }, false).textContent.includes(label));
  assert(!h.renderProof({ commitment_hash: 'b'.repeat(64) }, false).textContent.includes('Anclaje confirmado'));
  const pendingHistory = h.renderEvents([{ ...event, id: 'event-2' }]); const pendingContainer = pendingHistory.children[1].children[0].children[3]; let aborted = false;
  h.setHandler(async (_request, signal) => new Promise((_resolve, reject) => signal.addEventListener('abort', () => { aborted = true; reject(new DOMException('Aborted', 'AbortError')); }, { once: true })));
  const pending = pendingContainer.children[0].fire('click'); h.el('detail-dialog').close(); await pending; assert(aborted); assert.equal(pendingContainer.children[2].childElementCount, 0); assert.equal([...h.channels.keys()].filter(key => key.startsWith('event-proof:')).length, 0);
  console.log('PASS history: public author/number/transition/reason, lazy event proofs, accurate registered/prepared/sent/anchored labels, abort and cleanup on dialog close.');
}

// Club selection loads Primera immediately; category data describes real coverage.
{
  const h = harness(); const $ = h.el;
  h.state.activeTab = 'recommend';
  h.state.clubs.set('club-1', { id: 'club-1', name: 'Club de prueba', province: 'Córdoba', competitions: [] });
  $('club-choice').value = 'club-1';
  const squad = { club_id: 'club-1', category: 'Primera', status: 'verified', player_count: 30, expected_count: 30, checked_at: '2026-10-30T12:00:00Z', season: '2026', source_season: '26/27', source_url: 'https://www.transfermarkt.com/example/kader/verein/123', available_categories: [{ category: 'Primera', status: 'verified', player_count: 30 }, { category: 'Reserva', status: 'verified', player_count: 32 }] };
  const players = Array.from({ length: 25 }, (_, index) => ({ id: 'p-' + index, first_name: 'Jugador', last_name: String(index), position: 'Arquero' }));
  h.setHandler(async request => reply({ items: request.payload.cursor ? Array.from({ length: 5 }, (_, index) => ({ id: 'last-' + index, first_name: 'Jugador', last_name: String(index + 25) })) : players, next_cursor: request.payload.cursor ? null : 'next-page', total_count: 30, squad }));
  h.selectClub(); await tick();
  assert.equal($('player-category').value, 'Primera'); assert.equal($('player-lookup').hidden, false);
  assert.equal(h.calls.length, 1); assert.equal(h.calls[0].action, 'players'); assert.equal(h.calls[0].payload.club_id, 'club-1'); assert.equal(h.calls[0].payload.category, 'Primera');
  assert.match($('players-help').textContent, /25 de 30/); assert.equal($('players-more').hidden, false);
  assert.match($('squad-status').textContent, /Plantel de Primera: 30 jugadores publicados en Transfermarkt/); assert.match($('squad-status').textContent, /Temporada de la fuente: 26\/27/); assert.equal($('squad-source').hidden, false);
  assert.match($('player-category').options.find(option => option.value === 'Reserva').textContent, /32/);
  await h.loadPlayers(true); assert.equal(h.state.players.size, 30); assert.match($('players-help').textContent, /30 de 30/); assert.equal($('players-more').hidden, true);
  $('player-position-filter').value = 'Defensor Central';
  h.setHandler(async () => reply({ items: [], next_cursor: null, total_count: 0, squad })); await h.loadPlayers();
  assert.match($('player-choice').textContent, /No hay jugadores con esta posición/); assert.match($('players-help').textContent, /Todas las posiciones/);
  $('player-position-filter').value = ''; $('player-category').value = 'Reserva';
  h.setHandler(async () => reply({ items: [], next_cursor: null, total_count: 0, squad: { ...squad, category: 'Reserva', status: 'not_loaded', player_count: 0, source_url: null } })); await h.loadPlayers();
  assert.match($('squad-status').textContent, /todavía no está cargado en Club Abierto/); assert.match($('squad-status').textContent, /no significa que el plantel no exista en Transfermarkt/); assert.equal($('squad-source').hidden, true);
  h.renderSquad({ ...squad, status: 'partial', player_count: 4 }); assert.match($('squad-status').textContent, /parcialmente cargado: 4/);
  h.renderSquad({ ...squad, status: 'unavailable', player_count: 0 }); assert.match($('squad-status').textContent, /No pudimos consultar su fuente/);
  const emptySource = { ...squad, category: 'Reserva', status: 'not_loaded', player_count: 0, expected_count: 0, last_attempt_status: 'partial' };
  h.setHandler(async () => reply({ items: [], next_cursor: null, total_count: 0, squad: { ...emptySource, available_categories: [emptySource] } })); await h.loadPlayers();
  assert.match($('squad-status').textContent, /La fuente consultada no publica jugadores para este plantel de Reserva/);
  assert.match($('squad-status').textContent, /Consulta del/); assert.equal($('squad-source').hidden, false);
  assert.match($('player-category').options.find(option => option.value === 'Reserva').textContent, /sin nómina publicada/);
  assert.match($('player-choice').textContent, /Fuente sin nómina publicada/); assert(!/completa la carga/.test($('players-help').textContent));
  h.renderSquad({ ...emptySource, expected_count: null }); assert.match($('squad-status').textContent, /todavía no está cargado en Club Abierto/);
  h.renderSquad({ ...emptySource, checked_at: null }); assert.match($('squad-status').textContent, /todavía no está cargado en Club Abierto/);
  h.renderSquad({ ...emptySource, source_url: null }); assert.match($('squad-status').textContent, /todavía no está cargado en Club Abierto/);
  h.renderSquad({ ...emptySource, status: 'unavailable', last_attempt_status: 'unavailable' }); assert.match($('squad-status').textContent, /No pudimos consultar su fuente/);
  h.renderSquad({ ...squad, source_season: null }); assert(!$('squad-status').textContent.includes('Temporada'), 'Do not infer Transfermarkt season from competition season');
  h.dispose();
  console.log('PASS squads: immediate Primera load, separate Reserva counts, complete/partial/unavailable coverage, source/date, 25+5 pagination, missing dataset distinct from search miss and a consulted source publishing zero rows.');
}

// The position selector requests the whole squad filter on the server, with
// independent pagination and without changing a player's recommendation fields.
{
  const h = harness(); const $ = h.el;
  h.state.activeTab = 'recommend';
  h.state.clubs.set('club-positions', { id: 'club-positions', name: 'Club Posiciones', province: 'Córdoba', competitions: [] });
  $('club-choice').value = 'club-positions';
  const roster = Array.from({ length: 60 }, (_, index) => ({ id: 'position-' + index, first_name: 'Jugador', last_name: String(index), position: index < 25 ? 'Arquero' : index < 55 ? 'Defensor Central' : null }));
  const squad = { category: 'Primera', status: 'verified', player_count: 60, expected_count: 60, checked_at: '2026-10-30T12:00:00Z', source_url: 'https://www.transfermarkt.com/example/kader/verein/123' };
  const serverReply = request => {
    const filtered = roster.filter(player => request.payload.position === '__unknown__' ? player.position === null : !request.payload.position || player.position === request.payload.position);
    const offset = Number(request.payload.cursor || 0);
    return reply({ items: filtered.slice(offset, offset + 25), next_cursor: filtered.length > offset + 25 ? String(offset + 25) : null, total_count: filtered.length, squad });
  };
  h.setHandler(async request => serverReply(request));
  h.selectClub(); await tick();
  assert.deepEqual($('player-position-filter').options.map(option => option.value), ['', ...h.state.bootstrap.positions, '__unknown__']);
  assert.equal($('player-position-filter').options[0].textContent, 'Todas las posiciones');
  assert.equal($('player-position-filter').options.at(-1).textContent, 'Sin posición informada');
  assert.equal(h.calls.at(-1).payload.position, null); assert.equal('query' in h.calls.at(-1).payload, false);
  $('player-choice').value = 'position-0'; h.selectPlayer();
  const selected = h.state.selectedPlayer; const originalName = $('player-first-name').value;
  const callsBefore = h.calls.length; $('player-position').value = 'Defensor Central'; await $('player-position').fire('change');
  assert.equal(h.calls.length, callsBefore); assert.equal($('player-position-filter').value, '');
  $('player-position').value = 'Arquero';
  $('player-position-filter').value = 'Defensor Central'; await $('player-position-filter').fire('change');
  assert.equal(h.calls.at(-1).payload.position, 'Defensor Central'); assert.equal(h.calls.at(-1).payload.cursor, null);
  assert.equal(h.state.players.size, 25); assert(h.state.players.has('position-25'), 'Server-filtered results beyond the original first page were lost');
  assert.equal(h.state.selectedPlayer, selected); assert.equal($('player-first-name').value, originalName); assert.equal($('player-position').value, 'Arquero');
  assert.match($('players-help').textContent, /25 de 30 jugadores para esta posición/); assert.equal(h.state.squad.player_count, 60);
  await $('players-more').fire('click'); await tick();
  assert.equal(h.calls.at(-1).payload.position, 'Defensor Central'); assert.equal(h.calls.at(-1).payload.cursor, '25');
  assert.equal(h.state.players.size, 30); assert.equal($('players-more').hidden, true);
  $('player-position-filter').value = '__unknown__'; await $('player-position-filter').fire('change');
  assert.equal(h.calls.at(-1).payload.position, '__unknown__'); assert.equal(h.calls.at(-1).payload.cursor, null);
  assert.equal(h.state.players.size, 5); assert([...h.state.players.values()].every(player => player.position === null));
  assert.equal($('player-position').value, 'Arquero'); assert.equal(h.state.selectedPlayer, selected);
  $('player-position-filter').value = ''; await $('player-position-filter').fire('change');
  assert.equal(h.calls.at(-1).payload.position, null); assert.equal(h.state.players.size, 25); assert.match($('players-help').textContent, /25 de 60/);

  $('player-position-filter').value = 'Defensor Central'; await $('player-position-filter').fire('change');
  $('player-category').value = 'Reserva'; await $('player-category').fire('change'); await tick();
  assert.equal($('player-position-filter').value, ''); assert.equal(h.calls.at(-1).payload.position, null); assert.equal(h.calls.at(-1).payload.category, 'Reserva'); assert.equal(h.calls.at(-1).payload.cursor, null);
  $('player-position-filter').value = '__unknown__'; await $('player-position-filter').fire('change');
  h.state.clubs.set('club-other', { id: 'club-other', name: 'Otro Club', province: 'Córdoba', competitions: [] }); $('club-choice').value = 'club-other'; h.selectClub(); await tick();
  assert.equal($('player-position-filter').value, ''); assert.equal(h.calls.at(-1).payload.club_id, 'club-other'); assert.equal(h.calls.at(-1).payload.position, null); assert.equal(h.calls.at(-1).payload.cursor, null);

  let resolvePrevious, previousSignal;
  h.setHandler((request, signal) => request.payload.position === 'Defensor Central' ? new Promise(resolve => { previousSignal = signal; resolvePrevious = () => resolve(serverReply(request)); }) : Promise.resolve(serverReply(request)));
  $('player-position-filter').value = 'Defensor Central'; const previous = $('player-position-filter').fire('change');
  $('player-position-filter').value = '__unknown__'; await $('player-position-filter').fire('change');
  assert.equal(previousSignal.aborted, true); assert.equal(h.state.players.size, 5);
  resolvePrevious(); await previous;
  assert.equal(h.state.playersQuery.position, '__unknown__'); assert.equal(h.state.players.size, 5); assert([...h.state.players.values()].every(player => player.position === null));
  assert.equal($('players-more').hidden, true); h.dispose();
  assert(!html.includes('id="player-query"') && !html.includes('Buscar en este plantel'));
  assert(html.includes('/scouting/scouting.js?v=20261119-south-america'));
  console.log('PASS position filter: bootstrap options, server-wide results beyond original page, filtered pagination, unknown/all, independent recommendation position and selection, club/category resets, aborted/stale requests discarded.');
}

// Countries scope only the recommendation catalogue. The optional location route
// must not hide a real club whose source has no province/city information.
{
  const h = harness(); const $ = h.el;
  assert.equal($('club-country').value, 'AR');
  assert.deepEqual($('club-country').options.map(option => option.value), countries.map(country => country.code));
  assert.equal($('club-region-label').textContent, 'Provincia');
  assert.deepEqual($('club-filter-flow').children, [$('province-field'), $('competition-field'), $('club-picker-field')]);
  h.setHandler(async request => { assert.equal(request.action, 'bootstrap'); return reply(countryBootstrap(request.payload.country_code)); });
  for (const code of ['BR', 'CL', 'CO', 'EC', 'UY', 'AR']) {
    $('club-country').value = code; await $('club-country').fire('change');
    assert.equal(h.state.countryCode, code); assert.equal(h.state.countryReady, true);
    assert.equal(h.calls.at(-1).payload.country_code, code);
    const country = countries.find(entry => entry.code === code);
    assert.equal($('club-region-label').textContent, country.region_label); assert.equal($('manual-region-label').textContent, country.region_label);
    assert.equal($('club-province').options[1].textContent, regionNames[code]);
    assert.equal($('manual-province').options[1].value, countryBootstrap(code).regions[0].value);
    assert.deepEqual($('club-competition').options.map(option => option.value), ['', `${code}-national`]);
    assert.match($('catalogue-notice').textContent, new RegExp(`Catálogo de ${country.name}:`));
    assert.equal($('country-club-fields').disabled, false);
    if (code !== 'AR') {
      assert.equal($('club-province').required, false, 'A new country must start with optional location');
      assert.equal($('club-competition').required, true);
      assert.deepEqual($('club-filter-flow').children, [$('competition-field'), $('province-field'), $('club-picker-field')]);
    }
  }
  const national = { id: 'BR-national', name: 'Série A', country_code: 'BR', division: 'Primera', season: '2026' };
  const estadual = { id: 'BR-state', name: 'Campeonato Paulista', country_code: 'BR', division: 'Estadual', season: '2026' };
  const club = { id: 'club-br', name: 'Club Brasileño', country_code: 'BR', country_name: 'Brasil', region_name: null, province: null, city: null, competition_id: national.id, competition_name: national.name, competitions: [national, estadual] };
  const player = { id: 'player-br', first_name: 'Jugador', last_name: 'Brasileño', position: 'Defensor Central', age_current: 23 };
  h.setHandler(async request => {
    if (request.action === 'bootstrap') return reply(countryBootstrap('BR', { competitions: [national, estadual] }));
    if (request.action === 'clubs') return reply({ items: [club], next_cursor: null });
    if (request.action === 'players') return reply({ items: request.payload.cursor ? [{ ...player, id: 'player-br-2' }] : [player], next_cursor: request.payload.cursor ? null : 'next-player', total_count: 2, squad: { category: 'Primera', player_count: 2, expected_count: 2, status: 'verified' } });
    throw new Error('Unexpected request: ' + request.action);
  });
  await h.changeCountry('BR'); h.state.activeTab = 'recommend'; await h.setRoute('competition');
  assert.equal($('club-province').required, false); assert.equal($('club-province').value, '');
  assert.equal($('club-province').options[0].textContent, 'Todos los estados');
  $('club-competition').value = estadual.id; await $('club-competition').fire('change'); await tick();
  assert.equal(h.calls.at(-1).action, 'clubs'); assert.equal(h.calls.at(-1).payload.country_code, 'BR'); assert.equal(h.calls.at(-1).payload.province, null); assert.equal(h.calls.at(-1).payload.competition_id, estadual.id);
  $('club-choice').value = club.id; h.selectClub(); await tick();
  assert.equal($('club-competition').value, estadual.id); assert.equal(h.state.selectedClub.competition_id, estadual.id);
  assert.equal(h.calls.at(-1).action, 'players'); assert.equal(h.calls.at(-1).payload.country_code, 'BR'); assert.equal(h.calls.at(-1).payload.competition_id, estadual.id);
  assert.match($('selected-club-description').textContent, /Brasil/); assert.match($('selected-club-description').textContent, /Campeonato Paulista/);
  assert(!$('selected-club-description').textContent.includes('Série A')); assert(!/null|undefined/.test($('selected-club-description').textContent));
  $('player-choice').value = player.id; h.selectPlayer(); $('recommend-reason').value = 'Una observación deportiva completa sobre este jugador.';
  $('player-position-filter').value = 'Defensor Central'; await $('player-position-filter').fire('change');
  await $('players-more').fire('click'); await tick();
  assert.equal(h.calls.at(-1).payload.cursor, 'next-player'); assert.equal(h.calls.at(-1).payload.country_code, 'BR'); assert.equal(h.calls.at(-1).payload.competition_id, estadual.id); assert.equal(h.calls.at(-1).payload.position, 'Defensor Central');
  let payload = h.createPayload(); assert.equal(payload.country_code, 'BR'); assert.equal(payload.competition_id, estadual.id); assert.equal(payload.player_id, player.id);
  assert.equal('nationality' in payload, false); assert.equal('nationality' in payload.player, false);
  await h.setRoute('province'); $('club-province').value = 'Brasil — São Paulo'; await $('club-province').fire('change'); await tick();
  $('club-competition').value = estadual.id; await $('club-competition').fire('change'); await tick();
  $('club-choice').value = club.id; h.selectClub(); await tick();
  assert.equal(h.state.selectedClub.competition_id, estadual.id, 'A province search replaced the explicitly selected estadual');
  $('player-choice').value = player.id; h.selectPlayer();
  $('club-competition').value = national.id; await $('club-competition').fire('change'); await tick();
  assert.equal(h.state.selectedClub.competition_id, national.id); assert.equal(h.state.selectedPlayer.id, player.id); assert.equal($('player-first-name').value, player.first_name);
  assert.equal(h.calls.at(-1).payload.competition_id, national.id);
  h.dispose();
  console.log('PASS country catalogue: all six countries, scoped regions/competitions/counts, country-first flow, clubs without location through competition, explicit estadual retained, country+competition+position pagination, and no player-nationality inference.');
}

// Manual club inputs must belong to the selected country; pending writes keep
// their original immutable payload and cannot be moved to another country.
{
  const h = harness(); const $ = h.el;
  h.setHandler(async request => reply(countryBootstrap(request.payload.country_code)));
  await h.changeCountry('EC'); $('manual-club-toggle').checked = true; await $('manual-club-toggle').fire('change');
  $('manual-province').value = 'Córdoba'; $('manual-city').value = 'Quito'; $('manual-club-name').value = 'Club Local'; $('manual-league').value = 'Liga de Quito';
  $('player-first-name').value = 'Jugador'; $('player-last-name').value = 'Recomendado'; $('player-position').value = 'Arquero'; $('player-category').value = 'Primera'; $('recommend-reason').value = 'Una observación deportiva para este jugador recomendado.';
  assert.equal(h.createPayload(), null); assert.match($('manual-province').validationMessage, /país elegido/);
  $('manual-province').value = 'Ecuador — Pichincha';
  const payload = h.createPayload(); assert.equal(payload.country_code, 'EC'); assert.equal(payload.club_manual.province, 'Ecuador — Pichincha'); assert.equal(payload.club_manual.city, 'Quito'); assert.equal(payload.club_id, null);
  assert.deepEqual($('manual-league-options').children.map(option => option.value), ['Liga Ecuador · 2026']);
  const requests = h.calls.length; h.state.createPending = payload;
  assert.equal(await h.changeCountry('BR'), false); assert.equal(h.calls.length, requests); assert.equal(h.state.countryCode, 'EC'); assert.equal(h.state.createPending, payload);
  h.state.createPending = null; await h.changeCountry('UY');
  for (const id of ['manual-city', 'manual-club-name', 'manual-league', 'player-first-name', 'player-last-name', 'player-position-filter']) assert.equal($(id).value, '', 'Country change retained ' + id);
  assert.equal(h.state.selectedClub, null); assert.equal(h.state.selectedPlayer, null); assert.equal(h.state.playersQuery, null); assert.equal(h.state.playersCursor, null); assert.equal(h.state.clubsCursor, null);
  h.dispose();
  console.log('PASS manual countries: region validation against current country, country-scoped league suggestions, explicit country in creation, pending write preserved, previous manual/player fields and cursors cleared.');
}

// Country changes invalidate all catalogue work, even when an aborted transport
// resolves late. Global recommendations and the current authenticated actor stay put.
{
  const h = harness(); const $ = h.el; const pending = new Map();
  h.state.activeTab = 'recommend'; h.state.list.items = [recommendation];
  h.state.selectedClub = { id: 'old-club', country_code: 'AR' }; h.state.selectedPlayer = { id: 'old-player' };
  $('club-province').value = 'Córdoba'; $('player-category').value = 'Primera'; $('player-lookup').hidden = false;
  $('player-first-name').value = 'Anterior'; $('player-last-name').value = 'Jugador';
  h.setHandler((request, signal) => new Promise(resolve => pending.set(request.action + ':' + request.payload.country_code, { resolve, signal })));
  const oldClubs = h.loadClubs(); const oldPlayers = h.loadPlayers();
  const toBR = h.recommendAlso({ ...recommendation, id: 'foreign-reference', club: { id: 'br-club', country_code: 'BR', country_name: 'Brasil', name: 'Club Brasil', competition_id: 'BR-national' } });
  assert.equal(pending.get('clubs:AR').signal.aborted, true); assert.equal(pending.get('players:AR').signal.aborted, true);
  assert.equal(h.state.selectedClub, null); assert.equal(h.state.selectedPlayer, null); assert.equal($('country-club-fields').disabled, true); assert.equal($('create-submit').disabled, true);
  const toCL = h.changeCountry('CL'); assert.equal(pending.get('bootstrap:BR').signal.aborted, true);
  pending.get('bootstrap:CL').resolve(reply(countryBootstrap('CL', { actor: { role: 'admin', numero_socio: '999' } })));
  assert.equal(await toCL, true); assert.equal(h.state.actor.role, 'socio'); assert.equal(h.state.actor.numero_socio, '123');
  pending.get('bootstrap:BR').resolve(reply(countryBootstrap('BR'))); await toBR;
  pending.get('clubs:AR').resolve(reply({ items: [{ id: 'stale-club', name: 'Club anterior' }], next_cursor: 'stale' }));
  pending.get('players:AR').resolve(reply({ items: [{ id: 'stale-player', first_name: 'Anterior', last_name: 'Jugador' }], next_cursor: 'stale' }));
  await oldClubs; await oldPlayers;
  assert.equal(h.state.countryCode, 'CL'); assert.equal($('club-country').value, 'CL'); assert.equal($('club-region-label').textContent, 'Región');
  assert.equal(h.state.referenceRecommendation, null); assert.equal(h.state.clubs.size, 0); assert.equal(h.state.players.size, 0); assert.equal(h.state.clubsCursor, null); assert.equal(h.state.playersCursor, null);
  assert.equal($('player-first-name').value, ''); assert.equal($('player-last-name').value, ''); assert.equal(h.state.list.items[0], recommendation);
  h.setHandler(async () => reply(countryBootstrap('AR'))); assert.equal(await h.changeCountry('UY'), false);
  assert.equal(h.state.countryReady, false); assert.equal($('country-retry').hidden, false); assert.equal($('country-club-fields').disabled, true); assert.equal(h.createPayload(), null);
  h.setHandler(async request => reply(countryBootstrap(request.payload.country_code))); await $('country-retry').fire('click');
  assert.equal(h.state.countryCode, 'UY'); assert.equal(h.state.countryReady, true); assert.equal($('country-retry').hidden, true);
  h.state.list.loaded = true; h.state.dashboard.loaded = true; h.applyPanelContext('admin');
  const before = h.calls.length; assert.equal(await h.changeCountry('BR'), false); assert.equal(h.calls.length, before); assert.equal(h.createPayload(), null);
  h.applyPanelContext('socio'); let resolveSession, sessionSignal;
  h.setHandler((_request, signal) => { sessionSignal = signal; return new Promise(resolve => { resolveSession = resolve; }); });
  const sessionRead = h.changeCountry('BR'); h.setToken('another-session'); resolveSession(reply(countryBootstrap('BR'))); await sessionRead;
  assert.equal(sessionSignal.aborted, true); assert.equal(h.state.actor, null); assert.equal(h.state.bootstrap, null); assert.equal(h.state.countryCode, 'AR'); assert.equal(h.state.countryReady, false);
  assert.equal($('club-country').value, 'AR'); assert.equal($('manual-province').options.length, 0); assert.equal($('country-feedback').textContent, '');
  h.dispose();
  console.log('PASS country lifecycle: aborts clubs/players/bootstrap, stale cross-country recommend-also cannot repopulate fields, mismatched response blocked/retryable, global rows and actor preserved, role gate and changed-session cleanup.');
}

// A verified catalogue sporting mononym is not a request to invent a surname.
// Editing the identity returns to the ordinary manual name requirements.
{
  const h = harness(); const $ = h.el;
  const club = { id: 'br-mononym-club', name: 'Club del catálogo', country_code: 'BR', country_name: 'Brasil', competition_id: 'BR-national', competition_name: 'Liga Brasil', competitions: [{ id: 'BR-national', name: 'Liga Brasil' }] };
  const mononym = { id: 'verified-mononym', first_name: 'Hulk', last_name: null, name_kind: 'sporting_mononym', position: 'Defensor Central' };
  h.setHandler(async request => request.action === 'bootstrap' ? reply(countryBootstrap(request.payload.country_code)) : request.action === 'clubs' ? reply({ items: [club], next_cursor: null }) : reply({ items: [mononym], next_cursor: null, total_count: 1, squad: { category: 'Primera', player_count: 1, expected_count: 1, status: 'verified' } }));
  await h.changeCountry('BR'); h.state.activeTab = 'recommend'; await h.setRoute('competition'); $('club-competition').value = 'BR-national'; await $('club-competition').fire('change'); await tick();
  $('club-choice').value = club.id; h.selectClub(); await tick();
  assert.match($('player-choice').textContent, /Hulk/); assert(!/null|undefined/.test($('player-choice').textContent));
  $('player-choice').value = mononym.id; h.selectPlayer(); $('recommend-reason').value = 'Una observación deportiva suficiente para este jugador.';
  assert.equal($('player-first-name').value, 'Hulk'); assert.equal($('player-last-name').value, ''); assert.equal($('player-last-name').required, false); assert.equal($('player-last-name').minLength, 0); assert.equal($('last-name-required').hidden, true); assert.equal($('catalogue-name-help').hidden, false);
  let payload = h.createPayload(); assert.equal(payload.player_id, mononym.id); assert.equal(payload.player.first_name, 'Hulk'); assert.equal(payload.player.last_name, ''); assert.equal(payload.country_code, 'BR');
  $('player-first-name').value = 'Otro jugador'; await $('player-first-name').fire('input');
  assert.equal(h.state.selectedPlayer, null); assert.equal($('player-last-name').required, true); assert.equal($('player-last-name').minLength, 2); assert.equal($('catalogue-name-help').hidden, true); assert.equal(h.createPayload(), null);
  $('player-last-name').value = 'Manual'; payload = h.createPayload(); assert.equal(payload.player_id, null); assert.equal(payload.player.last_name, 'Manual');
  $('player-last-name').setCustomValidity('El apellido debe tener al menos 2 caracteres.');
  $('player-last-name').setAttribute('aria-invalid', 'true');
  $('player-choice').value = mononym.id; h.selectPlayer();
  assert.equal($('player-last-name').validationMessage, ''); assert.equal($('player-last-name').getAttribute('aria-invalid'), null);
  await h.changeCountry('AR');
  assert.equal(h.state.selectedPlayer, null); assert.equal($('player-last-name').required, true); assert.equal($('catalogue-name-help').hidden, true);
  h.dispose();
  console.log('PASS sporting mononym: exact catalogue name, nullable surname rendered empty, selected UUID retained, surname optional only while verified identity is linked, manual validation restored on edits/country changes.');
}

// A country selector never turns the shared feed into a country-restricted feed.
// New snapshots identify their club's country; old snapshots retain the AR fallback.
{
  const h = harness(); const $ = h.el; const legacyBefore = JSON.stringify(recommendation);
  const foreign = countries.filter(country => country.code !== 'AR').map(country => ({ ...recommendation, id: 'rec-' + country.code, club: { id: 'club-' + country.code, name: 'Club ' + country.name, country_code: country.code, country_name: country.name, province: null, city: null, competition_id: country.code + '-national', competition_name: 'Liga ' + country.name } }));
  foreign[0] = { ...foreign[0], player: { first_name: 'Hulk', last_name: '', name_kind: 'sporting_mononym', position: 'Defensor Central' } };
  h.setHandler(async request => {
    if (request.action === 'bootstrap') return reply(countryBootstrap(request.payload.country_code));
    if (request.action === 'feed') return reply({ items: [recommendation, ...foreign], next_cursor: null });
    if (request.action === 'dashboard') return reply({ dashboard });
    if (request.action === 'detail') return reply({ recommendation: foreign[0], events: [], proof: { status: 'registrada' } });
    return reply({ items: [], next_cursor: null });
  });
  await h.changeCountry('BR'); await h.loadList(); await h.loadDashboard();
  for (const request of h.calls.filter(request => ['feed', 'dashboard'].includes(request.action))) assert.equal('country_code' in request.payload, false);
  assert.equal($('mine-list').children.length, 6); assert.equal($('metric-recomendados').textContent, '137');
  for (const country of countries) assert.match($('mine-list').textContent, new RegExp(country.name));
  assert.match(h.card(recommendation).textContent, /Argentina/); assert.equal(JSON.stringify(recommendation), legacyBefore);
  await h.openDetail(foreign[0].id); assert.match($('detail-body').textContent, /País del club Brasil/); assert(!/null|undefined/.test($('detail-body').textContent));
  h.renderRanking([{ identity_type: 'catalogue', player_id: 'verified-mononym', recommendation_count: 3, player: foreign[0].player, club: foreign[0].club }]); assert.match($('ranking-list').textContent, /Club Brasil · Brasil/);
  await h.changeCountry('AR'); await h.recommendAlso(foreign[0]);
  assert.equal(h.state.countryCode, 'BR'); assert.equal($('club-country').value, 'BR'); assert.equal(h.state.referenceRecommendation.id, foreign[0].id);
  assert.equal(h.state.selectedClub.country_code, 'BR'); assert.equal($('club-competition').value, 'BR-national'); assert.equal($('club-province').required, false);
  assert.equal($('player-first-name').value, 'Hulk'); assert.equal($('player-last-name').value, ''); assert.equal($('player-last-name').required, false);
  $('recommend-reason').value = 'Mi propia observación deportiva del mismo jugador registrado.';
  const payload = h.createPayload(); assert.equal(payload.reference_recommendation_id, foreign[0].id); assert.equal(payload.country_code, 'BR'); assert.equal(payload.competition_id, 'BR-national'); assert.equal(payload.player_id, null); assert.equal(payload.player.last_name, '');
  await h.setRoute('province'); h.newRecommendation(false);
  assert.equal($('club-country').value, 'BR'); assert.equal($('player-last-name').required, true); assert.equal($('club-province').required, false); assert.equal($('club-competition').required, true);
  await h.recommendAlso(recommendation); assert.equal(h.state.countryCode, 'AR'); assert.equal($('club-country').value, 'AR'); assert.equal($('manual-province').value, 'Córdoba');
  h.dispose();
  console.log('PASS shared countries: global feed/dashboard across all countries, country in cards/detail/ranking, immutable legacy AR fallback, cross-country recommend-also with mononym and location-free club, and same-country reset.');
}

// A disposed native view aborts all work, including mutations outside read channels.
{
  const h = harness(); let resolveRead, resolveMutation; const signals = [];
  h.setHandler((request, signal) => { signals.push(signal); return new Promise(resolve => { if (request.action === 'dashboard') resolveRead = resolve; else resolveMutation = resolve; }); });
  const read = h.loadDashboard();
  const mutation = h.api('add_info', { id: 'r-1', message: 'Test' }).then(() => false, error => error.name === 'AbortError');
  let staleTimer = false; h.timers.set('pending-native', setTimeout(() => { staleTimer = true; }, 10));
  assert(h.listenerCount() > 0); h.dispose(); h.dispose();
  assert(signals.every(signal => signal.aborted)); assert.equal(h.listenerCount(), 0); assert.equal(h.channels.size, 0); assert.equal(h.timers.size, 0);
  assert.equal(h.state.actor, null); assert.equal(h.canRecommend(), false);
  resolveRead(reply({ dashboard })); resolveMutation(reply({ recommendation }));
  await read; assert.equal(await mutation, true);
  await new Promise(resolve => setTimeout(resolve, 20));
  assert.equal(staleTimer, false); assert.equal(h.el('metric-recomendados').textContent, '—');
  const count = h.calls.length; await h.el('dashboard-recommend').fire('click'); h.fireWindow('pageshow', { persisted: true }); assert.equal(h.calls.length, count);
  assert(!source.includes('postMessage') && !source.includes("listen(window, 'message'"));
  console.log('PASS native lifecycle: idempotent disposal, every read/mutation aborted, listeners/timers removed, late results discarded, detached controls and page events inert.');
}

for (const match of source.matchAll(/\$\('([^']+)'\)/g)) assert(html.includes('id="' + match[1] + '"'), 'Missing referenced ID: ' + match[1]);
assert(!html.includes('id="panel-admin"')); assert(!source.includes("api('admin_list'"));
console.log('PASS static structure: one shared feed/dashboard; all literal DOM references exist.');
console.log('All checks passed. These are Node/DOM logic tests; no browser layout or live database verification is claimed.');
