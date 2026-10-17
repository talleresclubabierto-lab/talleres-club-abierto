# Modulos: Concursos y licitaciones / Banco de profesionales

Estado: especificacion tecnica inicial. Rama aislada; no desplegar sin pruebas.

## Arquitectura
- Conservar autenticacion actual via Edge Function club-abierto-api y sesiones_seguras.
- No habilitar lectura/escritura directa para anon ni authenticated en tablas nuevas.
- RLS habilitado y permisos revocados a anon/authenticated; API valida sesion, rol y propiedad antes de cada operacion.
- Documentos privados en Storage, enlaces temporales tras autorizacion.
- Integrar eventos a auditoria_administrativa y lotes Merkle existentes, sin activar Polygon.

## Concursos
Entidades propuestas: ca_rubros, ca_licitaciones, ca_requisitos, ca_proveedores, ca_proveedores_vinculos, ca_ofertas, ca_ofertas_documentos, ca_evaluaciones, ca_adjudicaciones, ca_contratos, ca_contratos_pagos, ca_contratos_cumplimiento.
Campos: expediente unico; servicio/rubro; modalidad; presupuesto/moneda; plazos; criterios versionados; estado; responsable; CUIT y razon social; fecha constitucion e inicio de actividad; titulares y vinculaciones declaradas; oferta economica; adjudicacion fundada; contrato y cumplimiento.
Flujo: borrador -> publicada -> recepcion cerrada -> evaluacion -> adjudicada/desierta/cancelada. No mostrar ofertas competidoras durante recepcion. Versionar pliegos y adjuntos; no sobrescribir originales.
Socio: filtrar por rubro, fecha, montos, estado, proveedor; comparar ofertas tras cierre y revisar justificaciones, contratos y ejecucion conforme politica de publicacion.
Administrador: publicar, recibir ofertas, evaluar, adjudicar, registrar contratos y pagos. Conflictos de interes declarados y verificables.

## Profesionales
Entidades propuestas: ca_profesiones, ca_profesionales, ca_profesionales_especialidades, ca_profesionales_documentos, ca_cv_solicitudes, ca_convocatorias, ca_postulaciones.
Perfil publico a socios solo con consentimiento: nombre visible, disciplina, especialidad, experiencia resumida y disponibilidad.
CV completo privado por defecto. Solicitud de acceso: solicitante, titular, documento/version, finalidad, estado, autorizacion explicita, expiracion y revocacion. Autorizacion especifica por solicitante y documento; no acceso publico a URL persistente.
Titular: crear/editar perfil, adjuntar CV PDF validado, consentir visibilidad, autorizar/rechazar/revocar solicitudes.
Admin: validar titulaciones, gestionar convocatorias, consultar perfiles; acceso al CV completo solo con autorizacion del titular (salvo otra base legal definida y documentada).
Filtrar por disciplina, especialidad, experiencia, disponibilidad, modalidad y area de interes.

## Validaciones y seguridad
- CUIT: formato y digito verificador; corroboracion externa pendiente.
- Documentos: MIME real, limites, antivirus/escaneo, nombres opacos, hashes y versionado.
- Evitar exponer datos personales sensibles, domicilios y contactos en directorio.
- Fechas UTC en base; interfaz America/Argentina/Cordoba formato 24 h.
- Paginacion y filtros en servidor; indices segun consultas reales.
- Auditoria append-only: actor, accion, entidad, fecha, hash de documento, version y motivo.
- Politicas de retencion, exportacion, rectificacion y revocacion conforme normativa aplicable.

## Plan de entrega
1. Revisar esquema y contrato de sesion de API actual.
2. Crear migracion reversible con RLS y sin grants publicos.
3. Crear endpoints y pruebas de autorizacion para ambos roles.
4. Incorporar UI responsive en paneles administrador y socio.
5. Pruebas de integracion, privacidad, auditoria y regresion Android.
6. Revisar PR antes de merge a main y despliegue.

## Criterios de aceptacion
- Socio no puede modificar concursos ni leer CV sin permiso.
- Admin no puede adjudicar sin expediente, ofertas y justificacion (salvo contratacion directa fundada).
- Ofertas confidenciales hasta cierre; historial de cambios preservado.
- Titular puede revocar acceso futuro al CV.
- No se altera voto, padron, auditoria economica ni estado blockchain.
