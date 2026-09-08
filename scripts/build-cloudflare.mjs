import { cp, mkdir, rm, readFile, writeFile } from 'node:fs/promises';

const output = 'dist';
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });

for (const file of [
  'index.html',
  'manifest.webmanifest',
  'service-worker.js',
  'icon.svg',
  '_headers'
]) {
  await cp(file, output + '/' + file);
}

const indexPath = output + '/index.html';
let html = await readFile(indexPath, 'utf8');
const css = await readFile('src/estructura-institucional.css', 'utf8');
const js = await readFile('src/estructura-institucional.js', 'utf8');
html = html.replace('</head>', '<style data-v12="estructura-institucional">' + css + '</style>\n</head>');
html = html.replace('</body>', '<script data-v12="estructura-institucional">' + js + '</script>\n</body>');
await writeFile(indexPath, html, 'utf8');
console.log('Cloudflare build: Estructura Institucional integrada.');
