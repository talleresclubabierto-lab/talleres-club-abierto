import { cp, mkdir, rm } from 'node:fs/promises';

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
