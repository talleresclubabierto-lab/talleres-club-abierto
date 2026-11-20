// Run after mobile:prepare. Check the deliverables that Capacitor actually packages.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { basename, join } from 'node:path';

const webRoot = process.argv[2] || 'dist';
const mobileRoot = process.argv[3] || 'www';
const hostingFiles = new Set(['_headers', '_redirects']);
assert(existsSync(webRoot) && existsSync(mobileRoot), 'Run npm run mobile:prepare first');

function files(root, relative = '') {
  return readdirSync(join(root, relative), { withFileTypes: true }).flatMap(entry => {
    const path = join(relative, entry.name);
    return entry.isDirectory() ? files(root, path) : [path];
  }).sort();
}
function digest(path) {
  return createHash('sha256').update(readFileSync(path)).digest('hex');
}

const expectedFiles = files(webRoot).filter(file => !hostingFiles.has(basename(file)));
assert.deepEqual(files(mobileRoot), expectedFiles, 'Android assets differ from the web bundle');
for (const file of expectedFiles) {
  assert.equal(digest(join(mobileRoot, file)), digest(join(webRoot, file)), `${file}: Android content differs from web`);
}
for (const file of hostingFiles) {
  assert(!existsSync(join(mobileRoot, file)), `${file} is a hosting directive, not an app asset`);
}

// The old mobile builder omitted these destinations and used the untransformed index.
const index = readFileSync(join(mobileRoot, 'index.html'), 'utf8');
for (const route of ['acceso-socios.html', 'acceso-administrador.html']) {
  assert(index.includes(`href="./${route}"`), `Home access link missing: ${route}`);
  assert(existsSync(join(mobileRoot, route)), `Home access destination missing: ${route}`);
  assert.equal(digest(join(mobileRoot, route)), digest(join(mobileRoot, 'index.html')), `${route}: access route uses an old panel layout`);
}
for (const asset of [
  'comunidad-formativa.html',
  'comunidad-formativa-admin.html',
  'comunidad-formativa-seguimiento.html',
  'comunidad-formativa/vinculo/index.html',
  'comunidad-formativa/acompanamiento/index.html',
  'comunidad-formativa/integridad/index.html',
  'comunidad-formativa/presentaciones/index.html',
  'scouting.html',
  'scouting/scouting.js',
  'scouting/scouting.css',
  'estructura-institucional.js',
  'estructura-institucional.css',
  'assets/club-abierto-background.webp'
]) {
  assert(existsSync(join(mobileRoot, asset)), `Panel dependency missing in Android: ${asset}`);
}
assert(index.includes('<script data-v12="estructura-institucional">'), 'Android is missing the current institutional module');
assert(!index.includes('id="ei-embedded-js"'), 'Android still embeds the obsolete institutional module');
assert.equal(digest(join(mobileRoot, 'estructura-institucional.js')), digest('src/estructura-institucional.js'));
assert.equal(digest(join(mobileRoot, 'estructura-institucional.css')), digest('src/estructura-institucional.css'));
console.log(`PASS mobile bundle: ${expectedFiles.length} web-identical files, access destinations, community/scouting dependencies and current institutional module.`);


// Release guards: the Android package must contain the six-country Scouting UI,
// the agreed four ordered categories per panel and the exact web background asset.
const scouting = readFileSync(join(mobileRoot, 'scouting/scouting.js'), 'utf8');
for (const [code, name] of Object.entries({
  AR: 'Argentina', BR: 'Brasil', CL: 'Chile',
  CO: 'Colombia', EC: 'Ecuador', UY: 'Uruguay'
})) {
  assert(scouting.includes(code + ": { name: '" + name + "'"),
    'Scouting country missing in Android: ' + name);
}
assert(scouting.includes("'club-competition'") && scouting.includes("'club-country'"),
  'Scouting competition or country selector missing');

const defsStart = index.lastIndexOf('var defs={');
const defsEnd = index.indexOf('function label(b)', defsStart);
assert(defsStart >= 0 && defsEnd > defsStart, 'Panel categories not found');
const definitions = index.slice(defsStart, defsEnd);
const socioStart = definitions.indexOf('socioDashboard:[');
const adminStart = definitions.indexOf('adminDashboard:[');
assert(socioStart >= 0 && adminStart > socioStart, 'Missing socio/admin panel category definitions');
for (const [panel, block] of [
  ['Socio Activo', definitions.slice(socioStart, adminStart)],
  ['Administrador', definitions.slice(adminStart)]
]) {
  const categoryLines = block.split('\n').filter(line => /^\s*\['[^']+','[^']+','[^']+',\[/.test(line));
  assert.equal(categoryLines.length, 4, panel + ': expected exactly four categories');
  for (const expected of ['Participación y Votaciones', 'Transparencia y Auditoría', 'Comunidad y Colaboración']) {
    assert(categoryLines.some(line => line.includes("['" + expected + "'")),
      panel + ': missing ' + expected);
  }
}
assert(index.includes('var(--app-background-club-abierto)'), 'Shared background not applied in index');
assert(index.includes('club-abierto-background.webp'), 'Shared background asset not referenced');
assert.equal(
  digest(join(mobileRoot, 'assets/club-abierto-background.webp')),
  digest(join(webRoot, 'assets/club-abierto-background.webp')),
  'Android background asset does not match web');
console.log('PASS release guards: 6 Scouting countries, 4 categories per panel, identical background asset.');
