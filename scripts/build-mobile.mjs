import { cp, rm } from 'node:fs/promises';
import { basename } from 'node:path';
import './build-cloudflare.mjs';

// Package the same transformed pages and assets as the web, including access routes.
// Hosting directives have no effect in Capacitor's local static server.
const hostingFiles = new Set(['_headers', '_redirects']);
await rm('www', { recursive: true, force: true });
await cp('dist', 'www', {
  recursive: true,
  filter: source => !hostingFiles.has(basename(source))
});
console.log('Mobile build: same pages, panel order and assets as the web.');
