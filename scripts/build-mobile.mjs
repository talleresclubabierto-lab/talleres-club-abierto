import { cp, mkdir, rm, readFile, writeFile } from 'node:fs/promises';

// Match the production web build, including Estructura Institucional assets.
await rm('www', { recursive: true, force: true });
await mkdir('www', { recursive: true });
for (const file of ['index.html', 'manifest.webmanifest', 'service-worker.js', 'icon.svg']) {
  await cp(file, 'www/' + file);
}
const htmlPath = 'www/index.html';
let html = await readFile(htmlPath, 'utf8');
const css = await readFile('src/estructura-institucional.css', 'utf8');
const js = await readFile('src/estructura-institucional.js', 'utf8');
if (!html.includes('</head>') || !html.includes('</body>')) throw new Error('Invalid web HTML');
html = html.replace('</head>', '<style data-v12="estructura-institucional">' + css + '</style>\\n</head>');
html = html.replace('</body>', '<script data-v12="estructura-institucional">' + js + '</script>\\n</body>');
await writeFile(htmlPath, html, 'utf8');
console.log('Android web bundle matches the production Cloudflare build.');
