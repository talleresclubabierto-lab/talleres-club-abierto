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

La ampliación del 30/10/2026 se conserva en
`scouting/catalogue-squads-2026-10-30.json.gz`: incluye las nóminas de los primeros
equipos de los 153 clubes y las reservas que se pudieron consultar. Este corte
supera la muestra inicial de 21 jugadores. **Cada ejecución mensual debe revisar
los planteles por club y categoría, no limitarse a la lista de clubes ni a esa
muestra inicial.** Conciliar siempre la cobertura y las exclusiones del corte
con la base viva; una nómina parcial permanece identificada como parcial.

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

Conciliar también los cortes de enriquecimiento posteriores al snapshot completo.
`scouting/catalogue-player-details-2026-10-30.json` es un delta de datos de 21
jugadores: 21 fechas de nacimiento, 20 referencias de valor y dos correcciones
de club verificadas. No reemplaza el catálogo completo de octubre ni sus referencias
pendientes. Los metadatos del lote guardan las filas antes y después. El estado
resultante requiere aplicar el corte completo y sus deltas publicados, además de
conciliar las modificaciones administrativas posteriores.

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
  Una fila de un plantel actual de Transfermarkt que muestra el nombre y enlaza
  al perfil por su ID es evidencia de esa referencia de pertenencia y categoría;
  no necesita un segundo artículo oficial por cada jugador para incorporarse.
  Conservar URL, fecha de consulta, rótulo de temporada y alcance de la extracción.
  Una noticia oficial específica que contradiga una nómina general requiere
  conciliación, como los casos de Vigo y Barticciotto documentados abajo.
  No derivar nombres de un slug ni crear identidades distintas para una persona
  que figure en Primera y Reserva: usar `player_squads` con el mismo UUID.
- **Edad:** conservar `birth_date`, `birth_date_source_url` y
  `birth_date_verified_at` sólo con evidencia individual. El servicio calcula la
  edad del catálogo con el calendario de Argentina y congela la edad al crear
  cada recomendación; no actualiza edades históricas ni expone la fecha completa
  de nacimiento en el listado de socios.
- **Valor de mercado:** guardar importe, moneda, URL exacta de perfil Transfermarkt,
  fecha propia de la valoración (`market_value_as_of`) y fecha de comprobación
  (`market_value_verified_at`). Marcar `market_value_verified=true` únicamente con
  evidencia suficiente. Una referencia sin valor conserva `null`, nunca cero.
  La fecha de consulta no sustituye a la fecha del valor. No aceptar estimaciones
  de socios como si fueran Transfermarkt; si la fuente no permite comprobar el
  dato, informar la falta y conservar el antecedente con su fecha.
- **Fechas:** separar consulta, hecho deportivo y fecha/antigüedad de la fuente.
  Renovar `checked_at` sólo cuando se haya comprobado de nuevo el registro.
  Una búsqueda fallida no permite presentar datos viejos como recién verificados.
- **Bajas:** una salida comprobada puede actualizar la pertenencia de un jugador
  o desactivarlo del catálogo actual, conservando evidencia anterior. No retirar
  registros por ausencia en un relevamiento parcial, ni reactivar bajas
  deliberadas. Preservar clubes manuales validados fuera del alcance investigado.
  Una noticia oficial específica de salida puede corregir una nómina general
  desactualizada; conservar ambas evidencias y el motivo. En el delta del 30/10,
  Alex Vigo pasó a Independiente Rivadavia y Bruno Barticciotto a Huracán. Este
  último préstamo fue informado hasta el 31/12/2026: revisar su continuidad con
  nueva evidencia, sin programar un retorno ni una extensión por inferencia.
- **Temporadas:** `competitions.season` expresa la temporada vigente de cada
  competencia; `club_competitions` conserva sus relaciones históricas. Cambiar
  ambas partes de la proyección actual dentro de una misma transacción y sólo
  con participantes comprobados. No inferir un cambio deportivo por el año
  del calendario. Verificar que búsquedas y creación de recomendaciones usen
  la temporada vigente y no mezclen relaciones de distintos años.
  Conservar por separado `source_season`, el rótulo realmente observado en la
  fuente. Una página actual sin rótulo explícito conserva ese campo nulo y su
  limitación; no inventar el año ni modificar automáticamente `saison_id`.

## Revisión de planteles

1. Recorrer los clubes de las competencias cubiertas y sus categorías Primera
   y Reserva. Seguir sólo enlaces públicos observados, conservando la asociación
   explícita entre el club y su segundo equipo. No confundir juveniles, fútbol
   femenino, competidores o movimientos de transferencias con el plantel elegido.
2. Recuperar las filas de la tabla de jugadores con sus nombres y enlaces de
   perfil. El normalizador local `scripts/parse-scouting-rosters.py` procesa HTML
   previamente recuperado; no descarga páginas ni elude restricciones. Si el
   extractor omite nombres, no completarlos por deducción. Registrar los pendientes.
3. Guardar el número de filas observadas, incorporadas y excluidas por plantel,
   su fuente, fecha, temporada y condición de cobertura. `complete` significa
   todas las filas de la tabla consultada; no garantiza la exhaustividad del
   plantel real. Una consulta inaccesible se registra como `unavailable` y no
   equivale a una baja de jugadores.
4. Resolver globalmente los ID de perfil antes de importar. Un ID en Primera
   y Reserva del mismo club mantiene una sola persona y dos membresías. El mismo
   ID observado en dos clubes requiere conciliación y no puede resolverse por el
   orden de carga. Preservar las bajas deliberadas y las modificaciones más nuevas.
5. Usar el importador privado versionado en la migración vigente. Una corrección
   de categoría que retire una membresía debe ser explícita y demostrar ausencia
   de la nómina completa de origen y presencia en la categoría destino. No aplicar
   bajas masivas por ausencia en una consulta parcial. Verificar las huellas del
   estado vivo inmediatamente antes de aplicar el corte.
6. Comprobar el selector real del RPC: al menos un club por competencia, Primera
   y Reserva, un plantel de más de 25 jugadores, búsquedas, cobertura parcial y
   fuentes inaccesibles. Conservar todos los aportes y sus constancias anteriores.

## Snapshot y planilla

Crear un snapshot nuevo en `scouting/catalogue-argentina-AAAA-MM.json`. Si el
archivo ya existe, usar fecha/hora o una revisión nueva; no sobrescribir el
corte anterior. Conservar metadatos, cobertura, fuentes por registro,
verificaciones individuales, pendientes, conflictos y diferencias antes/después.

Calcular SHA-256 sobre los bytes definitivos del snapshot y guardarlo en los
metadatos del lote y su informe; no incluir un hash autorreferencial dentro
del contenido que se está calculando.

Los JSON grandes pueden conservarse comprimidos sin pérdida mediante gzip con
`mtime=0`. El corte de planteles del 30/10 se distribuye en
`scouting/catalogue-squads-2026-10-30.json.gz` (evidencia, esquema 3) y
`scouting/catalogue-squads-2026-10-30.import.json.gz` (documento del importador,
esquema 2). Descomprimir antes de validar o importar y comprobar que los bytes
recuperados coincidan exactamente con los originales. Los hashes y tamaños del
JSON registrados en `.validation.json` se mantienen: corresponden al contenido
descomprimido, no al contenedor gzip. No volver a serializar, normalizar espacios
ni alterar saltos de línea antes de comprobar esa integridad. Un hash adicional
del archivo comprimido, si se registra, debe identificarse por separado.

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

La migración aplicada
`20261030193757_scouting_reviewed_squads_and_category_memberships.sql` incorpora
`scouting.import_roster_batch(jsonb,text)` y las membresías por categoría. Consultar
su definición vigente antes de cada ejecución; no volver a aplicar la migración
ni confundir la disponibilidad del importador con un lote de datos publicado.

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
Los campos individuales de nacimiento y valor conservan además sus columnas de
procedencia; la evidencia extensa y los conflictos se guardan en el snapshot/lote.

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

### Transporte de documentos grandes

Cuando el documento completo supera el tamaño práctico de una llamada, usar una
fila de transporte en `scouting.catalogue_runs`, separada del lote de importación.
Este transporte privado no cambia los planteles ni declara publicado el catálogo.

1. Descomprimir y validar el documento `.import.json.gz`. Fijar el SHA-256 y los
   bytes UTF-8 del JSON original, la cantidad de fragmentos esperada y un
   `transport_key` propio, distinto del `metadata.batch_key` del documento.
2. Crear o reanudar sólo la fila correspondiente a ese transporte, con
   `source='reviewed_squad_transport'` y `status='staging'`. Guardar los fragmentos
   de texto en `metadata.document_parts`, identificados por índices numéricos.
   Conservar el manifiesto de cantidad, bytes y hash. Repetir un fragmento idéntico
   es inocuo; una clave o un índice con contenido diferente exige conciliación.
3. Recuperar únicamente esa fila mediante su ID, origen, estado y `transport_key`.
   Verificar índices únicos y contiguos y ensamblar los valores en orden numérico,
   no lexicográfico: `jsonb_each_text(metadata->'document_parts')` y
   `string_agg(value, '' order by key::integer)`. Comprobar cantidad de fragmentos,
   `octet_length` y SHA-256 de los bytes UTF-8 antes de convertir el texto a JSONB.
   Un fragmento faltante o cualquier diferencia impide la importación.
4. Ensayar primero el documento completo dentro de un único `BEGIN` / `ROLLBACK`,
   con `SET LOCAL lock_timeout='5s'` y `SET LOCAL statement_timeout='120s'`.
   En una carga masiva desde un catálogo pequeño, usar también
   `SET LOCAL enable_seqscan=off` y `SET LOCAL jit=off` dentro de esa transacción:
   evita conservar un plan de búsqueda secuencial calculado para pocas filas
   mientras crece la tabla. No cambiar estas opciones globalmente ni en el RPC.
   Invocar el importador privado, comprobar identidades, membresías, exclusiones,
   huellas, historiales y respuestas del RPC. Comprobar también la repetición
   idempotente dentro del ensayo y verificar que el `ROLLBACK` no deje sus cambios.
5. Tras el ensayo satisfactorio, ensamblar y validar otra vez e importar el
   documento completo en una única transacción de publicación con los mismos
   límites locales. No importar cada fragmento por separado. El importador vuelve
   a validar las huellas y publica su propio lote atómicamente. Si la respuesta
   es incierta, consultar el lote por `batch_key`, hash y contenido antes de
   reintentar; la repetición idéntica recupera el resultado sin duplicar jugadores.
6. Antes de terminar la transacción de carga, ejecutar `ANALYZE` sobre
   `scouting.players`, `scouting.player_squads` y `scouting.squad_reviews` para
   actualizar las estadísticas que usarán las consultas normales. Después del
   commit, verificar el lote y sus recuentos. Limpiar
   únicamente la fila staging del transporte propio, identificada con las mismas
   condiciones, y sólo si no la referencia ningún registro del catálogo. Conservar
   el lote publicado, el documento y sus evidencias. Si el proceso se interrumpe,
   dejar el staging identificable para reanudarlo; no borrar otros transportes ni
   lotes para resolver una colisión.

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
No reescribir las fichas históricas, los autores ni los estados durante la carga.
El tablero agrupa repeticiones por UUID estable de catálogo o vínculo manual
explícito desde **Recomendar también**. Un cambio de club no debe crear otra
identidad de jugador; los homónimos manuales independientes no se fusionan.

Entregar por ChatGPT un informe con fecha, cobertura revisada, altas, cambios,
salidas comprobadas, pendientes/conflictos, fuentes inaccesibles, totales
publicados, planilla y referencias de lote/PR. Distinguir **publicado**, **sin
cambios verificados**, **parcial** y **fallido**. No enviar correos ni mensajes
a terceros desde esta tarea.

Si aparece una conexión, renovación o aprobación realmente necesaria, informar
la acción y etapa bloqueada, conservar el trabajo preparado y no simular éxito.
