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
    flush();
  }
  return { document, panels, flush, openCategory, add };
}

const dom = createDOM();
for (const fixture of dom.panels) {
  // Existing original button must be reused without losing its click handler.
  const original = dom.document.createElement('button');
  original.textContent = '⌘ Estructura institucional Áreas, autoridades y fuentes';
  const existingHandler = () => {};
  original.addEventListener('click', existingHandler);
  dom.openCategory(fixture, 'Transparencia y auditoría', [original]);
  assert.equal(fixture.grid.querySelectorAll('button').length, 1);
  assert.equal(fixture.grid.querySelector('button'), original);
  assert.equal(original.events.get('click'), existingHandler);

  // Missing original: insert precisely one entry and reach a stable DOM.
  dom.openCategory(fixture, 'Transparencia y auditoría');
  assert.equal(fixture.grid.querySelectorAll('.ei-entry').length, 1);
  const injected = fixture.grid.querySelector('.ei-entry');
  assert.equal(typeof injected.events.get('click'), 'function');

  // Stable identity must work even if the UI wording changes later.
  injected.textContent = 'Organización del club';
  dom.flush();
  assert.equal(fixture.grid.querySelectorAll('button').length, 1);

  // Recover already-duplicated entries and retain the router's original.
  const duplicate = dom.document.createElement('button');
  duplicate.className = 'ei-entry';
  duplicate.textContent = 'Estructura institucional';
  dom.openCategory(fixture, 'Transparencia y auditoría', [original, injected, duplicate]);
  assert.deepEqual(fixture.grid.querySelectorAll('button'), [original]);
  dom.openCategory(fixture, 'Transparencia y auditoría', [injected, duplicate, original]);
  assert.deepEqual(fixture.grid.querySelectorAll('button'), [original]);

  // Repeated navigation must never grow the menu or leave entries in other sections.
  for (let i = 0; i < 25; i++) {
    dom.openCategory(fixture, 'Mi perfil');
    assert.equal(fixture.dashboard.querySelectorAll('.ei-entry').length, 0);
    dom.openCategory(fixture, 'Transparencia y auditoría');
    assert.equal(fixture.grid.querySelectorAll('button').length, 1);
  }
}
console.log('Navigation stability passed: both roles, existing/missing entries, duplicates, label changes, 50 category round trips.');
