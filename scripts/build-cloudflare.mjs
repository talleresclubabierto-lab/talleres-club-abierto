import { cp, mkdir, rm, readFile, writeFile } from 'node:fs/promises';

const output = 'dist';
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });

for (const file of [
  'index.html',
  'comunidad-formativa.html',
  'comunidad-formativa-vinculo.html',
  'comunidad-formativa-acompanamiento.html',
  'comunidad-formativa-integridad.html',
  'comunidad-formativa-presentaciones.html',
  '_redirects',
  'manifest.webmanifest',
  'service-worker.js',
  'icon.svg',
  'estructura-institucional.js',
  'estructura-institucional.css',
  '_headers'
]) {
  await cp(file, output + '/' + file);
}

await cp('comunidad-formativa', output + '/comunidad-formativa', { recursive: true });
// Publish the canonical institutional assets, never the obsolete root-level overlay.
await cp('src/estructura-institucional.js', output + '/estructura-institucional.js');
await cp('src/estructura-institucional.css', output + '/estructura-institucional.css');

const indexPath = output + '/index.html';
let html = await readFile(indexPath, 'utf8');
const css = await readFile('src/estructura-institucional.css', 'utf8');
const js = await readFile('src/estructura-institucional.js', 'utf8');
// Remove legacy institutional overlay embedded in index; the current module owns this view.
html = html.replace(/<style id="ei-embedded-css">[\s\S]*?<\/style>/g, '').replace(/<script id="ei-embedded-js" defer>[\s\S]*?<\/script>/g, '');
html = html.replace('</head>', '<style data-v12="estructura-institucional">' + css + '</style>\n</head>');
html = html.replace('</body>', '<script data-v12="estructura-institucional">' + js + '</script>\n</body>');
await writeFile(indexPath, html, 'utf8');
console.log('Cloudflare build: Estructura Institucional y Comunidad Formativa integradas.');
