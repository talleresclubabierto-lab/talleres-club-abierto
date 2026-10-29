# Actualización mensual del scouting argentino

## Ejecución programada

La tarea **Actualización del scouting argentino** se creó y habilitó el
29/10/2026 en las tareas programadas de ChatGPT. Ejecuta el relevamiento, la
validación, la carga y la verificación mediante los conectores de GitHub y
Supabase. La recurrencia es el **día 1 de cada mes, por la mañana en Córdoba**,
con inicio el **1/11/2026**. El horario de referencia es 08:00 en
`America/Argentina/Cordoba`, con una ventana flexible de una hora.

El programador reside en ChatGPT. Este documento conserva el procedimiento;
no configura un segundo cron en Supabase ni un workflow programado de GitHub.
Cambiar este documento no cambia la recurrencia: para eso se actualiza la tarea
existente. No crear una segunda tarea para la misma actualización.

El usuario autorizó recopilar datos, crear planillas, cargarlos y publicarlos.
Los cambios comprobados se ejecutan y se verifican; el resultado de la tarea es
una actualización efectiva o un informe concreto de ausencia de cambios,
cobertura parcial o bloqueo. No requiere una nueva confirmación rutinaria.

| Recurso | Destino |
| --- | --- |
| Repositorio | `talleresclubabierto-lab/talleres-club-abierto`, rama `main` |
| Supabase | Proyecto `sziuyjicqyxnmbgtbopg`, esquema privado `scouting` |
| Aplicación | `https://talleresclubabierto.com/scouting` |
| Servicio | Edge Function `scouting-api` del proyecto |
| Contrato | [scouting-backend.md](scouting-backend.md) |

## Alcance y fuentes

El corte inicial del 29/10/2026 contiene 153 clubes: Primera División (30),
Primera Nacional (36), Federal A (37), Primera B (22) y Primera C (28).
Hay 21 jugadores publicados y 100 referencias conservadas para revisión:
98 pendientes y 2 con afiliaciones contradictorias. Estos números describen
ese corte; no son límites ni cantidades que deban forzarse en futuras cargas.
No equivalen a todos los clubes, ligas, categorías o planteles de Argentina.

Cada ejecución revisa las competencias cubiertas, los jugadores publicados y
las referencias pendientes. Puede ampliar la cobertura a otras competencias,
ligas y categorías argentinas con evidencia suficiente. Debe informar qué
alcance pudo revisar efectivamente, sin convertir una búsqueda parcial en
una declaración de cobertura completa.

Fuentes prioritarias: AFA, LPF, Consejo Federal, clubes y ligas oficiales.
La pertenencia a un torneo y su temporada requieren documentación oficial
del organizador; la afiliación de un jugador necesita corroboración individual
reciente del club o de un registro oficial apropiado.

Los IDs y enlaces Transfermarkt ya observados se conservan como referencias
de identidad. No hay credenciales ni un feed licenciado configurado. Sus
[condiciones de uso, apartado 11.1](https://www.transfermarkt.com/intern/anb)
restringen la copia mediante procesos automatizados. Este procedimiento no
implementa una descarga integral de sus páginas. Una fuente autorizada sólo
se incorpora cuando exista autorización verificable y dentro de su alcance.
No eludir bloqueos, CAPTCHA o límites de acceso.

Una referencia indexada antigua no demuestra una afiliación actual. Conservar
los parámetros de las URLs observadas, incluido `saison_id`; no reconstruir
un enlace supuestamente actual sustituyendo el año. Una fuente inaccesible
no significa que el club o jugador haya desaparecido.

## Recuperación y conciliación

1. Leer las instrucciones vigentes del repositorio, su `main` actual, los
   snapshots publicados y el esquema/RPC real de Supabase.
2. Consultar `catalogue_runs`, `clubs`, `club_competitions`, `competitions` y
   `players`. Conciliar cambios posteriores de administradores antes de
   proponer diferencias. El JSON histórico no sustituye el estado vivo.
3. Registrar commit base, último lote, hash de contenido y una huella estable
   de las filas del catálogo que se van a actualizar. No depender de rutas
   temporales de una conversación anterior.
4. Clasificar cada diferencia: alta, cambio, salida comprobada, nueva evidencia
   sin cambio deportivo, pendiente, conflicto o fuente inaccesible. Conservar
   valor anterior, propuesta, fuente y motivo.

El importador puntual de octubre y sus migraciones son antecedentes de una
carga, no programas recurrentes: contienen una temporada, una clave de lote
y cantidades fijas. No ejecutarlos otra vez ni reconstruir funciones actuales
copiando una definición antigua.

## Reglas por registro

- **Identidad:** conservar UUID y `source_key`. Resolver jugadores por el ID
  de perfil Transfermarkt registrado cuando exista, junto con su evidencia.
  Las claves iniciales pueden contener club/año: un cambio de club o temporada
  no crea otra persona. No unir homónimos por nombre solamente.
- **Clubes:** mantener la localidad deportiva estable y documentar por separado
  una sede administrativa diferente. No usar un estadio prestado como mudanza
  del club. Un campo de liga vacío significa falta de confirmación, y no borra
  una afiliación conocida sin evidencia nueva.
- **Jugadores:** verificar identidad, club y categoría individualmente antes
  de hacerlos seleccionables. Los pendientes y conflictos mantienen su estado
  hasta resolverlo. Las posiciones ambiguas no se fuerzan a una equivalencia.
- **Fechas:** separar consulta, hecho deportivo y fecha/antigüedad de la fuente.
  Renovar `checked_at` sólo cuando se haya comprobado de nuevo el registro.
  Una búsqueda fallida no permite presentar datos viejos como recién verificados.
- **Bajas:** una salida comprobada puede actualizar la pertenencia de un jugador
  o desactivarlo del catálogo actual, conservando evidencia anterior. No retirar
  registros por ausencia en un relevamiento parcial, ni reactivar bajas
  deliberadas. Preservar clubes manuales validados fuera del alcance investigado.
- **Temporadas:** `competitions.season` expresa la temporada vigente de cada
  competencia; `club_competitions` conserva sus relaciones históricas. Cambiar
  ambas partes de la proyección actual dentro de una misma transacción y sólo
  con participantes comprobados. No inferir un cambio deportivo por el año
  del calendario. Verificar que búsquedas y creación de recomendaciones usen
  la temporada vigente y no mezclen relaciones de distintos años.

## Snapshot y planilla

Crear un snapshot nuevo en `scouting/catalogue-argentina-AAAA-MM.json`. Si el
archivo ya existe, usar fecha/hora o una revisión nueva; no sobrescribir el
corte anterior. Conservar metadatos, cobertura, fuentes por registro,
verificaciones individuales, pendientes, conflictos y diferencias antes/después.

Calcular SHA-256 sobre los bytes definitivos del snapshot y guardarlo en los
metadatos del lote y su informe; no incluir un hash autorreferencial dentro
del contenido que se está calculando.

Generar una planilla XLSX fechada con **Cobertura, Clubes, Jugadores, Cambios y
Fuentes**. Distinguir publicados, pendientes y conflictos y enlazar fuentes.
Guardar el archivo con el mecanismo persistente de archivos disponible y
entregar su enlace. Los archivos públicos sólo contienen información deportiva
y de procedencia; no incluir información privada de socios ni credenciales.

## Publicación idempotente

Preparar una operación explícita de actualización basada en el esquema vivo.
Si requiere DDL, usar el mecanismo de migraciones de Supabase y conservar en
GitHub la versión realmente aplicada. No reinstalar el RPC desde migraciones
históricas ni modificar permisos para facilitar una importación.

Cada lote usa una clave nueva, por ejemplo `argentina-review-AAAA-MM-DD-r1`,
y el hash del snapshot. En una transacción:

1. Adquirir un bloqueo común del catálogo para todas las actualizaciones, por
   ejemplo `pg_advisory_xact_lock(hashtextextended('scouting.catalogue.refresh', 0))`.
   Bloquear además las tablas o filas afectadas para conciliar escrituras
   administrativas concurrentes.
2. Comprobar el lote: misma clave y hash ya publicado es una repetición inocua;
   misma clave con contenido distinto es un error. No reciclar la clave de octubre.
3. Revalidar la huella del estado de partida. Si cambió durante la investigación,
   conciliarlo antes de escribir; no sobrescribir silenciosamente trabajo nuevo.
4. Crear el registro de ejecución, aplicar sólo diferencias comprobadas y
   conservar identidades, fuentes anteriores, relaciones históricas y bajas
   deliberadas. No modificar recomendaciones ni eventos.
5. Comprobar recuentos derivados, unicidad, afiliaciones actuales y cobertura.
   Guardar resultado, evidencia y diferencias; publicar el lote sólo después
   de esas comprobaciones. Un error revierte la transacción completa.

`scouting.players` no tiene columna `source_urls`: la evidencia individual
completa se guarda en los metadatos del lote y en el snapshot versionado.
La procedencia de datos corroborados oficialmente es `official_reference`;
un enlace Transfermarkt no convierte la procedencia en `licensed_transfermarkt`.

Si no hay novedades deportivas, registrar la revisión real y sus límites sin
inventar cambios ni actualizar fechas de registros que no se comprobaron.
Una ejecución parcial puede publicar cambios independientes confirmados,
siempre que su cobertura y sus pendientes queden explícitos.

Conservar snapshot y operación en una rama/PR del repositorio. Usar el commit
esperado para evitar sobrescrituras concurrentes, completar las verificaciones
pertinentes y publicar los cambios autorizados. Supabase y GitHub deben referirse
al mismo lote y hash. No hay una transacción distribuida entre ambos servicios:
registrar las etapas alcanzadas y reanudar de forma idempotente si uno falla,
sin borrar lo publicado ni declarar éxito completo antes de conciliar ambos.

## Verificación e informe

Comprobar el resultado real en Supabase y el código publicado: cantidades,
identidades estables, temporada vigente, filtros por provincia/competencia,
selección de jugadores y ausencia de alteraciones de recomendaciones o eventos.
Las pruebas que requieran identidades sintéticas deben ejecutarse dentro de
una transacción con `ROLLBACK`, sin dejar datos de prueba en producción.

La política **PAREDES DE CRISTAL** permanece vigente: todos los socios habilitados
ven todas las recomendaciones y devoluciones. La antigüedad no modifica la
visibilidad ni la prioridad deportiva. La actualización no activa Polygon ni
cambia el circuito de auditoría. Un hash o lote local no confirma anclaje en cadena.

Entregar por ChatGPT un informe con fecha, cobertura revisada, altas, cambios,
salidas comprobadas, pendientes/conflictos, fuentes inaccesibles, totales
publicados, planilla y referencias de lote/PR. Distinguir **publicado**, **sin
cambios verificados**, **parcial** y **fallido**. No enviar correos ni mensajes
a terceros desde esta tarea.

Si aparece una conexión, renovación o aprobación realmente necesaria, informar
la acción y etapa bloqueada, conservar el trabajo preparado y no simular éxito.
