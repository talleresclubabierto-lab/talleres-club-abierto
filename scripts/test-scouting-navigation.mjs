// Exercise the real native-panel loader without sessions, network or writes.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const html = readFileSync(process.argv[2] || 'index.html', 'utf8');
const css = readFileSync('scouting/scouting.css', 'utf8');
const functionsStart = html.indexOf('function ocultarTodo(){');
const functionsEnd = html.indexOf('function mostrarSeccionSocio(', functionsStart);
assert(functionsStart > 0 && functionsEnd > functionsStart, 'Scouting navigation integration missing');
const source = html.slice(functionsStart, functionsEnd);
assert(source.includes('async function irAScoutingColaborativo()'), 'Scouting opener missing');
assert(!source.includes('iframe') && !source.includes('postMessage'), 'Scouting still creates a nested page');
assert(!html.includes('scoutingFrameHost') && !html.includes("id='scoutingFrame'"));
assert(css.includes(':host{display:block;min-width:0;width:100%;background:transparent;overflow:visible;height:auto}'));
assert(css.includes(':host .page-shell{max-width:none;padding:4px 0 36px;margin:0}'));

const definitions = html.match(/var defs=(\{[\s\S]*?\n\});\nfunction label\(b\)/);
assert(definitions, 'Panel categories missing');
const categories = vm.runInNewContext('(' + definitions[1] + ')');
for (const [panel, button] of [['socioDashboard', 'btnScoutingSocio'], ['adminDashboard', 'btnScoutingAdmin']]) {
  const others = categories[panel].filter(group => group[0] === 'Otros accesos');
  assert.equal(others.length, 1, `${panel}: expected one Otros accesos category`);
  assert(others[0][3].includes('Scouting colaborativo'));
  const start = html.indexOf(`<div id="${panel}"`);
  const end = html.indexOf('\n</div>', start);
  const panelHtml = html.slice(start, end);
  assert(panelHtml.includes(`id="${button}"`) && panelHtml.includes('onclick="irAScoutingColaborativo()"'));
  assert.equal((html.match(new RegExp(`id="${button}"`, 'g')) || []).length, 1);
}

class Node {
  constructor(tag = 'div') { this.tagName = tag; this.children = []; this.style = {}; this.attributes = {}; this.listeners = new Map(); this.isConnected = true; }
  get firstChild() { return this.children[0] || null; }
  replaceChildren(...children) { this.children.forEach(child => { child.isConnected = false; }); this.children = children; children.forEach(child => { child.isConnected = true; }); }
  appendChild(child) { this.children.push(child); child.isConnected = true; if (child.tagName === 'script') queueMicrotask(() => { context.window.ClubAbiertoScouting = module; child.onload(); }); }
  attachShadow() { assert(!this.shadowRoot); this.shadowRoot = new Node('shadow-root'); return this.shadowRoot; }
  setAttribute(name, value) { this.attributes[name] = value; }
  addEventListener(type, callback) { this.listeners.set(type, callback); }
  querySelector(selector) { return ['#application', '#detail-dialog'].includes(selector) ? new Node() : null; }
  remove() { this.isConnected = false; }
}
const token = 'synthetic-session-only-for-navigation-tests';
const nodes = new Map(['loginScreen', 'socioDashboard', 'adminDashboard', 'secScoutingColaborativo', 'scoutingNativeHost'].map(id => [id, new Node()]));
const host = nodes.get('scoutingNativeHost');
const head = new Node('head');
const calls = [];
const mounts = [];
let live = 0, disposals = 0, alerts = 0, currentToken = token;
let resources = { content: new Node('component'), css: 'test styles' };
const module = { mount(root, options) { assert.equal(root, host.shadowRoot); assert.equal(live, 0, 'Accumulated live components'); live++; const mount = { options, disposed: false }; mounts.push(mount); return { dispose() { assert(!mount.disposed, 'Double disposal'); mount.disposed = true; live--; disposals++; } }; } };
const context = {
  ROL_ACTIVO: '', ID_SOCIO_ACTIVO: 0,
  obtenerTokenSesionClub: () => currentToken,
  alert: () => { alerts++; },
  AbortController, setTimeout, clearTimeout,
  fetch: async (url, settings) => { calls.push({ url, settings }); return { ok: true, text: async () => url.includes('.css') ? 'test styles' : '<div id="scouting-content"></div>' }; },
  DOMParser: class { parseFromString() { return { getElementById: id => id === 'scouting-content' ? resources.content : null }; } },
  document: {
    head,
    getElementById: id => nodes.get(id) || null,
    querySelectorAll(selector) { assert.equal(selector, '.dashboard,.sub-view'); return ['socioDashboard', 'adminDashboard', 'secScoutingColaborativo'].map(id => nodes.get(id)); },
    createElement(tag) { assert.notEqual(tag, 'iframe'); return new Node(tag); },
    importNode(node) { return new Node(node.tagName); },
  },
  window: { scrollTo() {} },
  regresarAlPanelInterno() { context.ocultarTodo(); nodes.get(context.ROL_ACTIVO === 'socio' ? 'socioDashboard' : 'adminDashboard').style.display = 'flex'; },
};
vm.createContext(context);
vm.runInContext(source, context);
assert.equal(calls.length, 0, 'Scouting assets loaded during login/bootstrap');
await context.irAScoutingColaborativo();
assert.equal(alerts, 1);
assert.equal(calls.length, 0);
for (const role of ['socio', 'admin']) {
  context.ROL_ACTIVO = role; context.ID_SOCIO_ACTIVO = 1;
  currentToken = ''; await context.irAScoutingColaborativo(); assert.equal(live, 0);
  currentToken = token;
  for (let index = 0; index < 25; index++) {
    await context.irAScoutingColaborativo();
    assert.equal(live, 1); assert.equal(nodes.get('secScoutingColaborativo').style.display, 'flex');
    assert.equal(host.shadowRoot.children.length, 2, 'Native component must contain one style and one content subtree');
    assert.equal(mounts.at(-1).options.panelContext, role);
    assert(!JSON.stringify(mounts.at(-1).options).includes(token), 'Session passed to component options');
    mounts.at(-1).options.onBack();
    assert.equal(live, 0); assert.equal(host.shadowRoot.children.length, 0);
  }
}
assert.equal(disposals, 50);
assert.equal(calls.length, 2, 'Repeated entries downloaded the same source repeatedly');
assert.equal(head.children.length, 1, 'Repeated entries accumulated script tags');
assert(calls.every(call => !call.url.includes(token)));
assert(!head.children[0].src.includes(token));

// Closing, changing roles or changing sessions during asset loading must not mount.
for (const change of ['close', 'role', 'session']) {
  context.ROL_ACTIVO = 'socio'; currentToken = token;
  let resolve;
  context.SCOUTING_NATIVE_LOAD = new Promise(done => { resolve = done; });
  const pending = context.irAScoutingColaborativo();
  if (change === 'close') context.ocultarTodo();
  if (change === 'role') context.ROL_ACTIVO = 'admin';
  if (change === 'session') currentToken = 'replacement-session';
  resolve(resources); await pending;
  assert.equal(live, 0, `Late ${change} load mounted a stale component`);
  context.ocultarTodo();
}
context.SCOUTING_NATIVE_LOAD = Promise.resolve(resources);
context.ROL_ACTIVO = 'socio'; currentToken = token;
await context.irAScoutingColaborativo(); assert.equal(live, 1);
await context.irAScoutingColaborativo(); assert.equal(live, 1, 'Double activation accumulated components');
context.ocultarTodo(); assert.equal(live, 0);
console.log('PASS native navigation: both Otros accesos entries, no iframe/message bridge, one document scroll, lazy assets cached, 50 open/back cycles, single component, role/session checks and late-load cancellation.');
