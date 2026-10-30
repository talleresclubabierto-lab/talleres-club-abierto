import assert from 'node:assert/strict';
import { readFileSync, writeFileSync, mkdtempSync, rmSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { execFileSync } from 'node:child_process';
import vm from 'node:vm';

// HTML parsing, rather than a JavaScript-aware regexp, is essential here:
// browsers close a script on a literal end tag even inside a quoted JS string.
const parser = String.raw`
import json, sys
from html.parser import HTMLParser
class Document(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=False)
        self.scripts=[]
        self.current=None
        self.visible=[]
        self.ids=[]
    def handle_starttag(self, tag, attrs):
        attributes=dict(attrs)
        if attributes.get('id'): self.ids.append(attributes['id'])
        if tag == 'script':
            self.current={'attrs':attributes,'code':''}
            self.scripts.append(self.current)
    def handle_endtag(self, tag):
        if tag == 'script': self.current=None
    def handle_data(self, data):
        if self.current is not None: self.current['code'] += data
        else: self.visible.append(data)
d=Document()
d.feed(open(sys.argv[1], encoding='utf8').read())
d.close()
print(json.dumps({'scripts':d.scripts,'visible':' '.join(d.visible),'ids':d.ids}))
`;

function parseHtml(html) {
  const temporary = mkdtempSync(join(tmpdir(), 'club-formative-html-'));
  try {
    const input = join(temporary, 'document.html');
    writeFileSync(input, html);
    return JSON.parse(execFileSync('python3', ['-c', parser, input], {
      encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 4 * 1024 * 1024, timeout: 5000,
    }));
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
}

function validateScripts(html, label) {
  const parsed = parseHtml(html);
  for (const [index, script] of parsed.scripts.entries()) {
    if (script.attrs.src || !script.code.trim()) continue;
    assert.notEqual(script.attrs.type, 'module', 'Add module validation before introducing module scripts');
    new vm.Script(script.code, { filename: `${label}:script-${index + 1}` });
  }
  assert(!parsed.visible.includes('frame.srcdoc=adminDocument'), `${label}: JavaScript leaked into visible HTML`);
  return parsed;
}

function runRoute(code, hash) {
  const frames = [];
  const redirects = [];
  const body = { style: {}, replaceChildren: (...children) => frames.push(...children) };
  const context = vm.createContext({
    window: { location: { hash, replace: url => redirects.push(url) } },
    document: {
      body,
      createElement(tag) { assert.equal(tag, 'iframe'); return { tag, style: {} }; },
    },
  });
  new vm.Script(code).runInContext(context, { timeout: 1000 });
  return { frames, redirects };
}

class TestElement {
  constructor(tag = 'div') {
    this.tagName = tag.toUpperCase();
    this.children = [];
    this.listeners = new Map();
    this.textContent = '';
    this.classList = { add() {}, remove() {} };
  }
  append(...children) { this.children.push(...children); }
  replaceChildren(...children) { this.children = [...children]; }
  addEventListener(type, callback) { this.listeners.set(type, callback); }
  scrollIntoView() {}
  reset() {}
}

async function testAdminCaseReview(code, label) {
  const elements = new Map();
  const listeners = new Map();
  const calls = [];
  const get = id => {
    if (!elements.has(id)) elements.set(id, new TestElement());
    return elements.get(id);
  };
  const session = 'synthetic-test-session-only';
  const context = vm.createContext({
    console,
    Intl,
    Date,
    sessionStorage: { getItem: () => session },
    window: { addEventListener: (name, callback) => listeners.set(name, callback) },
    document: { getElementById: get, createElement: tag => new TestElement(tag) },
    FormData: class {
      get(name) { return name === 'confirm' ? 'on' : 'Motivo sintético de prueba'; }
    },
    async fetch(url, options) {
      const body = JSON.parse(options.body);
      assert.equal(options.headers['X-Club-Session'], session, `${label}: authenticated request header lost`);
      calls.push(body);
      let data;
      if (body.action === 'admin_list_access_requests') data = { solicitudes: [] };
      else if (body.action === 'admin_list_cases') data = { cases: [{
        id: 'synthetic-case', codigo: 'CF-TEST', categoria: 'consulta', estado: 'recibida', creada_en: '2026-10-30T12:00:00Z',
      }] };
      else if (body.action === 'admin_read_case') {
        assert.equal(body.case_id, 'synthetic-case');
        assert.equal(body.confirm, true);
        data = { case: {
          id: 'synthetic-case', code: 'CF-TEST', status: 'recibida', category: 'consulta',
          created_at: '2026-10-30T12:00:00Z', narrative: 'Relato sintético de prueba.', mentioned_people: '',
        } };
      } else throw new Error(`Unexpected action during read-only test: ${body.action}`);
      return { ok: true, json: async () => data };
    },
  });
  new vm.Script(code, { filename: label }).runInContext(context, { timeout: 1000 });
  await new Promise(resolve => setImmediate(resolve));
  const row = get('admin-case-list').children[0];
  const button = row?.children.find(child => child.tagName === 'BUTTON');
  assert(button, `${label}: case review button missing`);
  assert.doesNotThrow(() => button.listeners.get('click')(), `${label}: selecting case must not throw ReferenceError`);
  const form = get('case-read-form');
  await form.listeners.get('submit')({ preventDefault() {}, currentTarget: form });
  assert.equal(get('case-narrative').textContent, 'Relato sintético de prueba.');
  assert(calls.some(call => call.action === 'admin_read_case'), `${label}: case read was not dispatched`);
  assert.doesNotThrow(() => listeners.get('pagehide')(), `${label}: cleanup must not throw ReferenceError`);
}

const file = resolve(process.argv[2] || 'comunidad-formativa.html');
const root = dirname(file);
const home = validateScripts(readFileSync(file, 'utf8'), file);
const route = home.scripts.find(script => script.code.includes('const adminDocument='));
assert(route, 'Embedded admin route missing');
const normal = runRoute(route.code, '');
assert.equal(normal.frames.length, 0, 'Normal home must not mount administrator interface');
assert.equal(normal.redirects.length, 0, 'Normal home must not redirect');
const legacy = runRoute(route.code, '#socios-casos');
assert.deepEqual(legacy.redirects, ['/comunidad-formativa-seguimiento.html']);
assert.equal(legacy.frames.length, 0);
const admin = runRoute(route.code, '#gestion');
assert.equal(admin.frames.length, 1);
assert.equal(admin.frames[0].title, 'Gestión de Comunidad Formativa');
const embedded = validateScripts(admin.frames[0].srcdoc, 'embedded-admin');
assert.equal(embedded.scripts.length, 1);
await testAdminCaseReview(embedded.scripts[0].code, 'embedded-admin');
const standalone = validateScripts(readFileSync(join(root, 'comunidad-formativa-admin.html'), 'utf8'), 'standalone-admin');
assert.equal(standalone.scripts.length, 1);
await testAdminCaseReview(standalone.scripts[0].code, 'standalone-admin');
validateScripts(readFileSync(join(root, 'comunidad-formativa-seguimiento.html'), 'utf8'), 'member-followup');
const builtRoot = join(root, 'dist');
for (const name of ['comunidad-formativa-admin.html', 'comunidad-formativa-seguimiento.html']) {
  assert(existsSync(join(builtRoot, name)), `Published route target missing: ${name}`);
  validateScripts(readFileSync(join(builtRoot, name), 'utf8'), `dist/${name}`);
}
const canonicalForm = readFileSync(join(builtRoot, 'comunidad-formativa/presentaciones/index.html'), 'utf8');
const rootForm = readFileSync(join(builtRoot, 'comunidad-formativa-presentaciones.html'), 'utf8');
assert.equal(rootForm, canonicalForm, 'Root and nested presentation routes must serve the same complete form');
const parsedForm = validateScripts(rootForm, 'dist/presentaciones');
assert(parsedForm.ids.includes('case-form'), 'Published presentation form is missing');
assert(parsedForm.ids.includes('nueva-presentacion'), 'Published presentation deep-link target is missing');
console.log('Formative HTML: outer/embedded scripts parse; home/legacy routes, admin case selection/read/cleanup, and packaged routes/forms pass.');
