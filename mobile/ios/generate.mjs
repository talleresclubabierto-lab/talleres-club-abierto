import { existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const directory = dirname(fileURLToPath(import.meta.url));
const cli = resolve(directory, 'node_modules/@capacitor/cli/bin/capacitor');
const args = existsSync(resolve(directory, 'ios/App/App.xcodeproj'))
  ? ['sync', 'ios']
  : ['add', 'ios', '--packagemanager', 'SPM'];
const result = spawnSync(process.execPath, [cli, ...args], {
  cwd: directory, stdio: 'inherit', env: { ...process.env, CI: 'true' }
});
if (result.error) throw result.error;
if (result.status !== 0) throw new Error(`Capacitor ${args.join(' ')} failed (${result.status})`);
await import('./configure-native.mjs');

