// Exercise the real panel integration without sessions, network or production writes.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const html = readFileSync(process.argv[2] || 'index.html', 'utf8');
const functionsStart = html.indexOf('function ocultarTodo(){');
const functionsEnd = html.indexOf('function mostrarSeccionSocio(', functionsStart);
assert(functionsStart > 0 && functionsEnd > functionsStart, 'Scouting navigation integration missing');
const source = html.slice(functionsStart, functionsEnd);
assert(source.includes('function irAScoutingColaborativo()'), 'Scouting opener missing');

const definitions = html.match(/var defs=(\{[\s\S]*?\n\});\nfunction label\(b\)/);
assert(definitions, 'Panel categories missing');
const categories = vm.runInNewContext('(' + definitions[1] + ')');
for (const [panel, button] of [['socioDashboard', 'btnScoutingSocio'], ['adminDashboard', 'btnScoutingAdmin']]) {
  const others = categories[panel].filter(group => group[0] === 'Otros accesos');
  assert.equal(others.length, 1, `${panel}: expected one Otros accesos category`);
  assert(others[0][3].includes('Scouting colaborativo'), `${panel}: scouting must be under Otros accesos`);
  const start = html.indexOf(`<div id="${panel}"`);
  const end = html.indexOf('\n</div>', start);
  assert(start > 0 && end > start);
  const panelHtml = html.slice(start, end);
  assert(panelHtml.includes(`id="${button}"`), `${panel}: entry missing from the panel`);
  assert(panelHtml.includes('onclick="irAScoutingColaborativo()"'), `${panel}: entry is not wired`);
  assert.equal((html.match(new RegExp(`id="${button}"`, 'g')) || []).length, 1, 'Duplicate scouting entry');
}

const origin = 'https://talleresclubabierto.com';
const token = 'synthetic-session-only-for-navigation-tests';
const nodes = new Map(['loginScreen', 'socioDashboard', 'adminDashboard', 'secScoutingColaborativo'].map(id => [id, { id, style: {} }]));
const frames = [];
const listeners = new Map();
let alerts = 0;
let returns = 0;
let currentToken = token;
const host = {
  children: [],
  get firstChild() { return this.children[0] || null; },
  replaceChildren() {
    for (const child of this.children) child.isConnected = false;
    this.children = [];
  },
  appendChild(child) { child.isConnected = true; this.children.push(child); },
};
nodes.set('scoutingFrameHost', host);
const context = {
  ROL_ACTIVO: '', ID_SOCIO_ACTIVO: 0,
  obtenerTokenSesionClub: () => currentToken,
  alert: () => { alerts++; },
  document: {
    getElementById(id) { return id === 'scoutingFrame' ? host.children.find(x => x.id === id) || null : nodes.get(id) || null; },
    querySelectorAll(selector) {
      assert.equal(selector, '.dashboard,.sub-view');
      return ['socioDashboard', 'adminDashboard', 'secScoutingColaborativo'].map(id => nodes.get(id));
    },
    createElement(tag) {
      assert.equal(tag, 'iframe');
      const callbacks = new Map();
      const frame = {
        style: {}, attributes: {}, callbacks, posts: [], isConnected: false,
        addEventListener(event, callback) { callbacks.set(event, callback); },
        setAttribute(name, value) { this.attributes[name] = value; },
      };
      frame.contentWindow = { postMessage(data, target) { frame.posts.push({ data, target }); } };
      frames.push(frame);
      return frame;
    },
  },
  window: {
    location: { origin },
    addEventListener(event, callback) { assert(!listeners.has(event), 'Duplicate global listener'); listeners.set(event, callback); },
  },
  regresarAlPanelInterno() { returns++; context.ocultarTodo(); nodes.get(context.ROL_ACTIVO === 'socio' ? 'socioDashboard' : 'adminDashboard').style.display = 'flex'; },
};
vm.createContext(context);
vm.runInContext(source, context);
assert.equal(frames.length, 0, 'Scouting must not load during login/bootstrap');
context.irAScoutingColaborativo();
assert.equal(alerts, 1);
assert.equal(frames.length, 0, 'An unauthenticated visitor opened scouting');

for (const role of ['socio', 'admin']) {
  context.ROL_ACTIVO = role;
  context.ID_SOCIO_ACTIVO = 1;
  currentToken = '';
  context.irAScoutingColaborativo();
  assert.equal(host.children.length, 0, 'Missing session opened an iframe');
  currentToken = token;
  for (let i = 0; i < 25; i++) {
    context.irAScoutingColaborativo();
    assert.equal(host.children.length, 1, 'Repeated entry accumulated live frames');
    const frame = host.children[0];
    assert.equal(nodes.get('secScoutingColaborativo').style.display, 'flex');
    const url = new URL(frame.src, origin);
    assert.equal(url.pathname, '/scouting.html');
    assert.equal(url.searchParams.get('panel_context'), role);
    assert(!frame.src.includes(token), 'Session token leaked into iframe URL');
    frame.callbacks.get('load')();
    assert.equal(frame.posts.length, 1);
    assert.equal(frame.posts[0].target, origin);
    assert.equal(frame.posts[0].data.panel_context, role);
    assert.equal(frame.posts[0].data.type, 'club-abierto:scouting-context');
    const before = returns;
    const onMessage = listeners.get('message');
    onMessage({ origin: 'https://foreign.example', source: frame.contentWindow, data: { type: 'club-scouting-back' } });
    onMessage({ origin, source: {}, data: { type: 'club-scouting-back' } });
    assert.equal(returns, before, 'Untrusted message navigated the parent');
    onMessage({ origin, source: frame.contentWindow, data: { type: 'club-scouting-back' } });
    assert.equal(returns, before + 1);
    assert.equal(host.children.length, 0, 'Leaving scouting retained its iframe');
    assert.equal(frame.isConnected, false);
    frame.callbacks.get('load')();
    assert.equal(frame.posts.length, 1, 'A detached frame still received panel context');
    onMessage({ origin, source: frame.contentWindow, data: { type: 'club-scouting-back' } });
    assert.equal(returns, before + 1, 'A stale iframe navigated the panel');
  }
}
console.log('Scouting navigation passed: both Otros accesos entries, lazy load, role context, no token in URL, trusted messages, 50 open/back cycles and frame cleanup.');
