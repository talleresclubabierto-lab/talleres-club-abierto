# Optimización segura de rendimiento

## Alcance
Web, Android, panel de socio, administrador y Comunidad Formativa. No modificar autorización, RLS, registros append-only, hash chain, Merkle ni anclajes blockchain como parte de optimizaciones de interfaz.

## Requisitos antes de publicar
1. Registrar SHA de producción y verificar posibilidad de reversión.
2. Medir p50/p95 de navegación, inicio de sesión, consulta y guardado en web y Android, con caché fría y caliente.
3. Inspeccionar consultas SQL con EXPLAIN (ANALYZE, BUFFERS) en entorno de pruebas con datos no sensibles. Agregar índices solo cuando exista evidencia; no aplicar automáticamente todas las advertencias.
4. Optimizar carga de recursos, deduplicación de solicitudes, paginación y caché con aislamiento por sesión y rol; nunca almacenar denuncias ni datos de menores en caché compartida.
5. Verificar flujos: login, biometría, votación única, auditoría, roles, estructura institucional, CV, OTP y denuncias formativas, cierres y estados blockchain.
6. Ejecutar pruebas automatizadas y manuales en escritorio y Android, comparar p50/p95 con línea base y revisar errores 4xx/5xx.
7. Desplegar de forma controlada, comprobar producción y revertir ante fallas de autorización, integridad o rendimiento.

## Estado
Preparación de optimización: rama aislada. Sin cambios en producción. No considerar listo para publicación hasta completar las verificaciones anteriores.
