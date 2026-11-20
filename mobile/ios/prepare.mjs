import { cp, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const directory = dirname(fileURLToPath(import.meta.url));
const root = resolve(directory, '../..');
for (const script of ['scripts/build-mobile.mjs', 'scripts/test-mobile-build.mjs']) {
  const result = spawnSync(process.execPath, [script], { cwd: root, stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${script} failed (${result.status})`);
}
const target = resolve(directory, 'www');
await rm(target, { recursive: true, force: true });
await cp(resolve(root, 'www'), target, { recursive: true });
const git = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' });
const manifest = JSON.parse(await readFile(resolve(directory, 'package.json'), 'utf8'));
await writeFile(resolve(directory, 'source-build.json'), JSON.stringify({
  app: 'Talleres Club Abierto',
  platform: 'ios',
  appVersion: '1.9',
  sourceCommit: git.status === 0 ? git.stdout.trim() : 'local-working-copy',
  capacitor: manifest.dependencies['@capacitor/core'],
  distribution: 'unsigned-development-only'
}, null, 2) + '\n');
console.log('iOS: contenido web actual preparado; sin alterar los archivos fuente.');

