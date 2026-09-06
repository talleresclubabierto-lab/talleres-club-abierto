# Despliegue de producción en Cloudflare Pages

## Origen

- Repositorio: `talleresclubabierto-lab/talleres-club-abierto`
- Rama: `main`
- Framework preset: None
- Build command: vacío
- Output directory: `/`

## Secuencia segura

1. Crear un proyecto de Pages conectado al repositorio.
2. Desplegar en el subdominio temporal `pages.dev`.
3. Verificar pantalla pública sin datos, login, votos, auditoría, gobernanza y PWA.
4. Mantener GitHub Pages activo durante toda la prueba.
5. Registrar y conectar `talleresclubabierto.com`.
6. Verificar HTTPS y DNS.
7. Recién entonces establecer Cloudflare como acceso principal.
8. Conservar GitHub como repositorio y respaldo; desactivar Pages antiguo sólo con aprobación expresa.

Los archivos `_headers` y `_redirects` aplican controles de seguridad y navegación exclusivamente en Cloudflare Pages.
