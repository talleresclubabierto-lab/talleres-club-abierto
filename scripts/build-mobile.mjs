import { cp, mkdir, rm, readFile, writeFile } from 'node:fs/promises';

await rm('www', { recursive: true, force: true });
await mkdir('www', { recursive: true });
for (const file of ['index.html','manifest.webmanifest','service-worker.js','icon.svg']) {
  await cp(file, 'www/' + file);
}
let html = await readFile('www/index.html', 'utf8');
const css = await readFile('src/estructura-institucional.css', 'utf8');
const js = await readFile('src/estructura-institucional.js', 'utf8');
html = html.replace('</head>', `<style data-v12="estructura-institucional">${css}</style>\n</head>`);
html = html.replace('</body>', `<script data-v12="estructura-institucional">${js}</script>\n</body>`);
await writeFile('www/index.html', html, 'utf8');
console.log('Mobile v1.2: estructura institucional integrada.');