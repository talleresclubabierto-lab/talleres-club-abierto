import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const directory = dirname(fileURLToPath(import.meta.url));
const expectedRoot = resolve(directory, 'www');
const actualRoot = resolve(directory, process.argv[2] || 'ios/App/App/public');
function files(root, relative = '') {
  return readdirSync(join(root, relative), { withFileTypes: true }).flatMap(entry => {
    const path = join(relative, entry.name);
    return entry.isDirectory() ? files(root, path) : [path];
  }).sort();
}
const digest = path => createHash('sha256').update(readFileSync(path)).digest('hex');
const expected = files(expectedRoot);
for (const file of expected) {
  assert.equal(digest(join(actualRoot, file)), digest(join(expectedRoot, file)), `iOS differs from web: ${file}`);
}
// Capacitor may add its runtime files, but every source file must remain intact.
console.log(`PASS iOS native bundle: ${expected.length} files identical to the current mobile web bundle.`);

