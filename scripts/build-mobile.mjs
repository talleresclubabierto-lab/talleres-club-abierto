import { cp, mkdir, rm, readFile, writeFile } from 'node:fs/promises';

await rm('www', { recursive: true, force: true });
await mkdir('www', { recursive: true });
for (const file of ['index.html','comunidad-formativa.html','scouting.html','manifest.webmanifest','service-worker.js','icon.svg']) {
  await cp(file, 'www/' + file);
}

await mkdir('www/scouting', { recursive: true });
for (const f of ['scouting.css', 'scouting.js']) await cp('scouting/' + f, 'www/scouting/' + f);
await mkdir('www/assets', { recursive: true });
await cp('assets/club-abierto-logo.webp', 'www/assets/club-abierto-logo.webp');

const indexPath = 'www/index.html';
let html = await readFile(indexPath, 'utf8');
const css = await readFile('src/estructura-institucional.css', 'utf8');
const js = await readFile('src/estructura-institucional.js', 'utf8');
if (!html.includes('data-v12="estructura-institucional"')) {
  html = html.replace('</head>', '<style data-v12="estructura-institucional">' + css + '</style>\n</head>');
  html = html.replace('</body>', '<script data-v12="estructura-institucional">' + js + '</script>\n</body>');
}
await writeFile(indexPath, html, 'utf8');
// The landing screen routes to these two independent access pages. Cloudflare
// generates the same pages from index.html; Capacitor must package them too.
for (const route of ['acceso-socios.html', 'acceso-administrador.html']) {
  await writeFile('www/' + route, html, 'utf8');
}
console.log('Android: tres accesos empaquetados (Socios, Administrador y Comunidad Formativa).');
