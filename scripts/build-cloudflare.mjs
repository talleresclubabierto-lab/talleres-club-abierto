import { cp, mkdir, rm, readFile, writeFile } from 'node:fs/promises';

const output = 'dist';
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });

for (const file of [
  'index.html',
  'scouting.html',
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
await mkdir(output + '/scouting', { recursive: true });
for (const file of ['scouting.css', 'scouting.js']) {
  await cp('scouting/' + file, output + '/scouting/' + file);
}
await mkdir(output + '/assets', { recursive: true });
await cp('assets/club-abierto-logo.webp', output + '/assets/club-abierto-logo.webp');
// Publish the canonical institutional assets, never the obsolete root-level overlay.
await cp('src/estructura-institucional.js', output + '/estructura-institucional.js');
await cp('src/estructura-institucional.css', output + '/estructura-institucional.css');

const indexPath = output + '/index.html';
let html = await readFile(indexPath, 'utf8');
const css = await readFile('src/estructura-institucional.css', 'utf8');
const js = await readFile('src/estructura-institucional.js', 'utf8');
// Remove legacy institutional overlay embedded in index; the current module owns this view.
html = html.replace(/<style id="ei-embedded-css">[\s\S]*?<\/style>/g, '').replace(/<script id="ei-embedded-js" defer>[\s\S]*?<\/script>/g, '');
// Avoid CSS @import waterfall for Google Fonts; the stylesheet can load in parallel.
const fontImport = "@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap');";
if (!html.includes(fontImport)) throw new Error('Expected font import missing; review build before publishing');
html = html.replace(fontImport, '');
html = html.replace('</head>', '<link rel="preconnect" href="https://fonts.googleapis.com">\n<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&amp;family=JetBrains+Mono:wght@500;700&amp;display=swap">\n</head>');
html = html.replace('</head>', '<style data-v12="estructura-institucional">' + css + '</style>\n</head>');
html = html.replace('</body>', '<script data-v12="estructura-institucional">' + js + '</script>\n</body>');
await writeFile(indexPath, html, 'utf8');
console.log('Cloudflare build: Estructura Institucional, Comunidad Formativa y Scouting integrados.');

