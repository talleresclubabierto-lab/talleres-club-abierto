import { cp, mkdir, rm } from 'node:fs/promises';

await rm('www', { recursive: true, force: true });
await mkdir('www', { recursive: true });
for (const file of ['index.html','scouting.html','manifest.webmanifest','service-worker.js','icon.svg']) {
  await cp(file, 'www/' + file);
}
await mkdir('www/scouting', { recursive: true });
for (const file of ['scouting.css','scouting.js']) {
  await cp('scouting/' + file, 'www/scouting/' + file);
}
await mkdir('www/assets', { recursive: true });
await cp('assets/club-abierto-logo.webp', 'www/assets/club-abierto-logo.webp');

