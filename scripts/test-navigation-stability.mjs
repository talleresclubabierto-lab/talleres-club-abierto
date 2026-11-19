// Regression for the production institutional module's observer feedback loop.
// This small DOM harness implements the mutation delivery used by the module;
// no network, database writes, browser, or third-party test package is needed.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

const sourcePath = process.argv[2] || 'src/estructura-institucional.js';
const source = readFileSync(sourcePath, 'utf8');

function createDOM() {
  const observers = [];
  const listeners = new Map();
  function isWithin(node, ancestor) {
    for (let current = node; current; current = current.parentElement) {
      if (current === ancestor) return true;
    }
    return false;
  }
  function changed(target) {
    for (const observer of observers) {
      if (observer.target && (target === observer.target ||
          (observer.options.subtree && isWithin(target, observer.target)))) {
        observer.records.push({ type: 'childList', target });
      }
    }
  }
  function matches(element, selector) {
    if (selector.startsWith('.')) return element.classList.contains(selector.slice(1));
    if (selector.startsWith('#')) return element.id === selector.slice(1);
    return element.tagName === selector.toUpperCase();
  }
  function selectorMatches(element, selector) {
    const parts = selector.trim().split(/\s+/);
    if (!matches(element, parts.pop())) return false;
    let parent = element.parentElement;
    while (parts.length) {
      const part = parts.pop();
      while (parent && !matches(parent, part)) parent = parent.parentElement;
      if (!parent) return false;
      parent = parent.parentElement;
    }
    return true;
  }
  class Element {
    constructor(tagName) {
      this.tagName = tagName.toUpperCase();
      this.children = [];
      this.parentElement = null;
      this.id = '';
      this.style = {};
      this.disabled = false;
      this._text = '';
      this._classes = new Set();
      this.classList = {
        contains: name => this._classes.has(name),
        add: (...names) => names.forEach(name => this._classes.add(name)),
        remove: (...names) => names.forEach(name => this._classes.delete(name))
      };
      this.events = new Map();
    }
    set className(value) { this._classes = new Set(value.split(/\s+/).filter(Boolean)); }
    get className() { return [...this._classes].join(' '); }
    set textContent(value) {
      this.children.forEach(child => { child.parentElement = null; });
      this.children = [];
      this._text = value;
      changed(this);
    }
    get textContent() { return this._text + this.children.map(child => child.textContent).join(''); }
    set innerHTML(value) { this.textContent = value.replace(/<[^>]*>/g, ''); }
    appendChild(child) {
      if (child.parentElement) child.remove();
      child.parentElement = this;
      this.children.push(child);
      changed(this);
      return child;
    }
    get nextElementSibling() {
      if (!this.parentElement) return null;
      const siblings = this.parentElement.children;
      return siblings[siblings.indexOf(this) + 1] || null;
    }
    insertBefore(child, reference) {
      if (reference == null) return this.appendChild(child);
      assert.equal(reference.parentElement, this, 'insertBefore reference must belong to the parent');
      if (child === reference) return child;
      if (child.parentElement) child.remove();
      child.parentElement = this;
      this.children.splice(this.children.indexOf(reference), 0, child);
      changed(this);
      return child;
    }
    replaceChildren(...children) {
      this.children.forEach(child => { child.parentElement = null; });
      this.children = [];
      this._text = '';
      changed(this);
      children.forEach(child => this.appendChild(child));
    }
    remove() {
      if (!this.parentElement) return;
      const parent = this.parentElement;
      parent.children = parent.children.filter(child => child !== this);
      this.parentElement = null;
      changed(parent);
    }
    querySelectorAll(selector) {
      const result = [];
      const visit = element => element.children.forEach(child => {
        if (selectorMatches(child, selector)) result.push(child);
        visit(child);
      });
      visit(this);
      return result;
    }
    querySelector(selector) { return this.querySelectorAll(selector)[0] || null; }
    addEventListener(name, handler) { this.events.set(name, handler); }
  }
  const body = new Element('body');
  const document = {
    body,
    createElement: tagName => new Element(tagName),
    getElementById: id => body.querySelector('#' + id),
    addEventListener: (name, listener) => listeners.set(name, listener)
  };
  class MutationObserver {
    constructor(callback) { this.callback = callback; this.records = []; observers.push(this); }
    observe(target, options) { this.target = target; this.options = options; }
  }
  function flush() {
    let rounds = 0;
    while (observers.some(observer => observer.records.length)) {
      assert(++rounds <= 20, 'MutationObserver does not settle: repeated DOM writes freeze navigation');
      for (const observer of observers) {
        if (!observer.records.length) continue;
        const records = observer.records.splice(0);
        observer.callback(records, observer);
      }
    }
    return rounds;
  }
  function add(parent, tagName, className, text = '') {
    const child = document.createElement(tagName);
    child.className = className;
    child.textContent = text;
    parent.appendChild(child);
    return child;
  }
  const panels = ['socioDashboard', 'adminDashboard'].map(id => {
    const dashboard = add(body, 'section', 'dashboard');
    dashboard.id = id;
    const panel = add(dashboard, 'section', 'ca-category-view');
    const head = add(panel, 'div', 'ca-category-head');
    const heading = add(head, 'h2', '');
    const grid = add(panel, 'div', 'action-grid');
    return { dashboard, panel, heading, grid };
  });
  const window = {};
  runInNewContext(source, { window, document, MutationObserver }, { filename: sourcePath });
  listeners.get('DOMContentLoaded')();
  function openCategory(fixture, title, buttons = []) {
    fixture.grid.replaceChildren(...buttons);
    fixture.heading.textContent = title;
    fixture.panel.classList.add('ca-open');
    return flush();
  }
  return { document, panels, flush, openCategory, add };
}

const dom = createDOM();
for (const fixture of dom.panels) {
  // Existing original button must be reused without losing its click handler.
  const original = dom.document.createElement('button');
  original.textContent = '⌘ Estructura institucional Áreas, autoridades y fuentes';
  original.id = fixture.dashboard.id + '-existing-institution';
  original.style.display = 'none';
  original.disabled = true;
  const existingHandler = () => {};
  original.addEventListener('click', existingHandler);
  dom.openCategory(fixture, 'Transparencia y auditoría', [original]);
  assert.equal(fixture.grid.querySelectorAll('button').length, 1);
  assert.equal(fixture.grid.querySelector('button'), original);
  assert.equal(original.events.get('click'), existingHandler);

  const labels = fixture.dashboard.id === 'socioDashboard'
    ? ['Concursos y Licitaciones', 'Paredes de Cristal', 'Historial de Cambios']
    : ['Gobernanza Institucional', 'Paredes de Cristal', 'Historial de Cambios', 'Concursos y Licitaciones'];
  const prefix = labels.map(text => {
    const button = dom.document.createElement('button');
    button.textContent = text;
    return button;
  });
  const blockchain = dom.document.createElement('button');
  blockchain.textContent = '⬡ Integración Blockchain Estado, lotes y trazabilidad criptográfica';

  // The approved title and order work for originals at either end of the grid.
  for (const buttons of [[original, ...prefix, blockchain], [...prefix, blockchain, original]]) {
    assert(dom.openCategory(fixture, 'Transparencia y Auditoría', buttons) <= 2);
    assert.deepEqual(fixture.grid.children, [...prefix, original, blockchain]);
    assert.equal(original.events.get('click'), existingHandler, 'Moving a button must retain its handler');
    assert.equal(original.style.display, 'none', 'Moving a button must not bypass role visibility');
    assert.equal(original.disabled, true, 'Moving a button must not change permission-related state');
    assert.equal(original.id, fixture.dashboard.id + '-existing-institution');
  }

  // Missing original: insert precisely one entry immediately before Blockchain.
  assert(dom.openCategory(fixture, 'Transparencia y Auditoría', [...prefix, blockchain]) <= 2);
  assert.equal(fixture.grid.querySelectorAll('.ei-entry').length, 1);
  const injected = fixture.grid.querySelector('.ei-entry');
  assert.equal(typeof injected.events.get('click'), 'function');
  assert.deepEqual(fixture.grid.children, [...prefix, injected, blockchain]);

  // An unrelated mutation must not cause a redundant move and observer feedback.
  const probe = dom.add(fixture.dashboard, 'span', '', 'Unrelated status update');
  assert.equal(dom.flush(), 1, 'An already ordered menu must require no additional DOM writes');
  probe.remove();
  assert.equal(dom.flush(), 1);

  // Stable identity must work even if the UI wording changes later.
  injected.textContent = 'Organización del club';
  dom.flush();
  assert.deepEqual(fixture.grid.children, [...prefix, injected, blockchain]);

  // Recover already-duplicated entries and retain the router's original.
  const duplicate = dom.document.createElement('button');
  duplicate.className = 'ei-entry';
  duplicate.textContent = 'Estructura institucional';
  dom.openCategory(fixture, 'Transparencia y auditoría', [original, ...prefix, blockchain, injected, duplicate]);
  assert.deepEqual(fixture.grid.children, [...prefix, original, blockchain]);
  dom.openCategory(fixture, 'TRANSPARENCIA Y AUDITORÍA', [injected, duplicate, ...prefix, blockchain, original]);
  assert.deepEqual(fixture.grid.children, [...prefix, original, blockchain]);

  // Repeated navigation must never grow the menu or leave entries in other sections.
  for (let i = 0; i < 25; i++) {
    dom.openCategory(fixture, 'Mi Perfil');
    assert.equal(fixture.dashboard.querySelectorAll('.ei-entry').length, 0);
    dom.openCategory(fixture, 'Transparencia y Auditoría', [...prefix, blockchain]);
    const entry = fixture.grid.querySelector('.ei-entry');
    assert(entry, 'Institutional entry must return on every visit');
    assert.deepEqual(fixture.grid.children, [...prefix, entry, blockchain]);
    assert.equal(fixture.grid.querySelectorAll('.ei-entry').length, 1);
  }
}
console.log('Navigation stability passed: both roles, approved order before Blockchain, title case, preserved handlers and permissions, duplicates, label changes, 50 category round trips.');
