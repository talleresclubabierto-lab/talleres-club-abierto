# Actualización mensual del scouting de seis países

## Ejecución programada

La automatización existente tiene ID
**(tarea existente de actualización mensual)**. Está **PAUSADA**:
`is_enabled=false`, estado observado en la actualización del 19/11/2026 a
las 21:24. La ampliación de su prompt a los seis países debe conservar ese
estado. Actualizar el procedimiento o el alcance no reactiva la tarea.

La recurrencia guardada se conserva: **día 1 de cada mes a las 08:00**, zona
`America/Argentina/Cordoba`. Mientras `is_enabled=false`, ese horario no
produce ejecuciones. No presentar la actualización mensual como activa.

El programador reside en ChatGPT. Este documento conserva el procedimiento;
no configura un segundo cron en Supabase ni un workflow programado de GitHub.
Cambiar este documento no cambia la recurrencia: para eso se actualiza la tarea
existente. No crear una segunda tarea para la misma actualización.

El alcance es exclusivamente **Scouting**; no modifica Comunidad Formativa ni
otros módulos. El usuario autorizó recopilar datos, crear planillas, cargarlos y publicarlos.
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

| País del club | Código | Etiqueta territorial |
| --- | --- | --- |
| Argentina | `AR` | Provincia |
| Brasil | `BR` | Estado |
| Chile | `CL` | Región |
| Colombia | `CO` | Departamento |
| Ecuador | `EC` | Provincia |
| Uruguay | `UY` | Departamento |

Cada ejecución debe registrar qué competencias, clubes y categorías pudo
revisar en cada país, incluyendo los pendientes y las fuentes inaccesibles.
Puede ampliar una cobertura documentada, sin asumir que el catálogo contiene
todos los clubes de esos países o todos los que existen en Transfermarkt.
El país describe al club y su competencia, no la nacionalidad del jugador.

Argentina conserva su catálogo y antecedentes. El corte inicial del 29/10/2026
contenía 153 clubes y una muestra de 21 jugadores; no representa la cobertura
actual ni un objetivo fijo para una carga posterior.

La ampliación del 30/10/2026 se conserva en
`scouting/catalogue-squads-2026-10-30.json.gz`: incluye las nóminas de los primeros
equipos de los 153 clubes y las reservas que se pudieron consultar. Este corte
supera la muestra inicial de 21 jugadores. **Cada ejecución mensual debe revisar
los planteles por club y categoría, no limitarse a la lista de clubes ni a esa
muestra inicial.** Conciliar siempre la cobertura y las exclusiones del corte
con la base viva; una nómina parcial permanece identificada como parcial.

La ampliación de fuentes del 19/11/2026 se conserva en
`scouting/catalogue-south-america-2026-11-19.json.xz`, junto con su índice
`.sources.json.gz`, cobertura `.coverage.json` y validación `.validation.json`.
Estos archivos documentan fuentes observadas; por sí solos no prueban que todos
sus registros hayan sido importados. Los lotes y recuentos de la base deben
conciliarse por separado, incluyendo exclusiones y conflictos.

Priorizar organizadores, federaciones, clubes y ligas oficiales para comprobar
competencias, temporadas, movimientos y contradicciones. Una **fila observada
de un plantel público de Transfermarkt**, con nombre, ID de perfil, club,
categoría y fuente trazables, es evidencia para esa referencia del catálogo.
**No se exige un segundo artículo oficial ni abrir un perfil adicional por
cada jugador** cuando la fila ya aporta la identidad y el contexto necesarios.
Si falta un dato o hay contradicción, se revisa ese caso; no se completa por
deducción. Fechas de nacimiento y valores de mercado mantienen sus requisitos
específicos de evidencia.

El modo del catálogo es `reviewed_public_squads`. El indicador del feed
licenciado sigue siendo `provider_status='pending_authorization'`; una revisión
pública no activa ni acredita ese servicio. Conservar IDs y URLs observados y
usar sólo acceso público disponible mediante las herramientas permitidas.
Ante WAF, CAPTCHA, acceso denegado, `bot_blocked` o límites explícitos, registrar
el bloqueo y continuar con fuentes accesibles. No eludirlo cambiando hosts,
proxies, identidad del cliente o credenciales. Un error transitorio de lectura
puede tener un reintento limitado de la misma URL; un bloqueo de acceso no.

Una referencia indexada antigua no demuestra una afiliación actual. Conservar
los parámetros de las URLs observadas, incluido `saison_id`; no reconstruir
un enlace supuestamente actual sustituyendo el año. El valor numérico de
`saison_id` puede diferir del rótulo de temporada mostrado: conservar ambos sin
reinterpretarlos. Una fuente inaccesible o una edición histórica no demuestra
que el club o jugador haya desaparecido ni acredita su afiliación actual.

## Recuperación y conciliación

1. Leer las instrucciones vigentes del repositorio, su `main` actual, los
   snapshots publicados y el esquema/RPC real de Supabase.
2. Consultar `catalogue_runs`, `clubs`, `club_competitions`, `competitions`,
   `players`, `player_squads` y `squad_reviews`, distinguiendo cada país y el
   estado global de las identidades. Conciliar cambios posteriores de administradores antes de
   proponer diferencias. El JSON histórico no sustituye el estado vivo.
3. Registrar commit base, último lote, hash de contenido y una huella estable
   de las filas del catálogo que se van a actualizar. No depender de rutas
   temporales de una conversación anterior.
4. Clasificar cada diferencia: alta, cambio, salida comprobada, nueva evidencia
   sin cambio deportivo, pendiente, conflicto o fuente inaccesible. Conservar
   valor anterior, propuesta, fuente y motivo.
5. Consultar `scouting.catalogue_country_fingerprints(country_code)` para el
   país del siguiente lote. No reutilizar huellas tomadas antes de publicar otro
   lote de ese país. Una plantilla de fuentes todavía no es un documento listo
   para importar: necesita las huellas actuales y una clave final de lote.

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

- **Identidad:** conservar UUID y `source_key` globalmente, entre países y
  temporadas. Resolver clubes por su `transfermarkt_id` y jugadores por el ID
  de perfil Transfermarkt registrado cuando exista, junto con su evidencia.
  Las claves iniciales pueden contener club/año: un cambio de club o temporada
  no crea otra persona. No unir homónimos por nombre solamente.
- **Clubes y geografía:** comprobar que club, región y competencias correspondan
  al mismo país. Mantener valores territoriales estables como
  `Brasil — São Paulo`; `São Paulo` es sólo su etiqueta visible. No deducir una
  región a partir de la ciudad, del nombre del club o de un campeonato estadual.
  Si la fuente no confirma región o ciudad, guardar `null` y conservar la ruta
  de búsqueda por competencia. Si se incorpora geografía, guardar sus
  `geography_source_urls` explícitas. Mantener la localidad deportiva estable y documentar por separado
  una sede administrativa diferente. No usar un estadio prestado como mudanza
  del club. Un campo de liga vacío significa falta de confirmación, y no borra
  una afiliación conocida sin evidencia nueva. Un club que participa en un
  torneo estadual y otro nacional conserva un UUID y varias membresías de
  competencia; no se duplica el club ni su plantel por cada torneo.
- **Jugadores:** comprobar la identidad y el contexto de club/categoría de cada fila antes
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
- **Nombre deportivo único:** un monónimo observado conserva el nombre exacto
  como `first_name`, `last_name=''` y `name_kind='sporting_mononym'`. El importador
  también acepta `last_name=null` de la fuente y lo normaliza a vacío. Si se
  incluye `full_name`, debe coincidir con ese nombre. No inventar un apellido
  ni sustituirlo por un nombre legal no observado. Los otros nombres usan
  `name_kind='display_name_parts'`; las recomendaciones manuales siguen
  requiriendo nombre y apellido. El nombre no sustituye al ID de identidad.
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
  Los importadores de lotes no trasladan jugadores entre clubes o países:
  registran `affiliation_requires_reconciliation` cuando el ID ya pertenece
  a otro club. Resolver ese conflicto mediante una corrección explícita,
  respaldada por evidencia actual y pruebas de conservación del historial.
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
   perfil. Los normalizadores procesan HTML previamente recuperado; no descargan
   páginas ni eluden restricciones. Para el corte sudamericano están versionados
   `scripts/discover-scouting-south-america.py`,
   `scripts/parse-scouting-south-america-rosters.py` y
   `scripts/build-scouting-country-import-templates.py`, todos con
   `--directory` obligatorio. Argentina conserva además el antecedente
   `scripts/parse-scouting-rosters.py`. Verificar sus entradas y configuración
   antes de reutilizarlos: las versiones del corte de noviembre contienen una
   fecha, temporadas y un alcance concretos; no son descubridores universales
   ni deben ejecutarse cada mes sobre las mismas fuentes viejas. Si el extractor
   omite nombres, no completarlos por deducción. Registrar los pendientes.
3. Guardar el número de filas observadas, incorporadas y excluidas por plantel,
   su fuente, fecha, temporada y condición de cobertura. `complete` significa
   todas las filas de la tabla consultada; no garantiza la exhaustividad del
   plantel real. Una consulta inaccesible se registra como `unavailable` y no
   equivale a una baja de jugadores. Una fuente consultada que publica cero
   filas se distingue de una fuente no consultada; tampoco demuestra que el
   club carezca de jugadores. Una nómina de una temporada histórica no se
   presenta como actual aunque su URL siga accesible.
4. Resolver globalmente los ID de perfil antes de importar. Un ID en Primera
   y Reserva del mismo club mantiene una sola persona y dos membresías. El mismo
   ID observado en dos clubes requiere conciliación y no puede resolverse por el
   orden de carga. **Detectar y excluir las identidades ambiguas de todos los
   lotes antes de dividir el corte por país o tamaño.** El importador de un lote
   no puede detectar una contradicción que sólo aparece en otro archivo todavía
   no cargado. Conservar esas filas y sus fuentes en el registro de conflictos,
   y marcar como parcial el plantel afectado. Preservar las bajas deliberadas y
   las modificaciones más nuevas.
5. Usar el importador privado versionado en la migración vigente. Una corrección
   de categoría que retire una membresía debe ser explícita y demostrar ausencia
   de la nómina completa de origen y presencia en la categoría destino. No aplicar
   bajas masivas por ausencia en una consulta parcial. Verificar las huellas del
   estado vivo inmediatamente antes de aplicar el corte.
6. Comprobar el selector real del RPC en los países y competencias afectados:
   Primera y Reserva cuando haya fuentes, un plantel de más de 25 jugadores,
   posición y paginación, cobertura parcial y fuentes inaccesibles. Incluir un
   club sin ubicación y uno con varias competencias cuando existan en el lote.
   Conservar todos los aportes y sus constancias anteriores.

## Snapshot y planilla

Crear un corte nuevo y fechado dentro de `scouting/`, con un manifiesto que
declare sus rutas exactas. Puede reunir la evidencia de varios países, pero
los documentos de importación se separan por país y lote. Si una ruta ya existe,
usar fecha/hora o revisión nueva; no sobrescribir un corte anterior. Conservar
metadatos, cobertura por país/competencia/categoría, fuentes por registro,
pendientes, conflictos y diferencias antes/después.

Distinguir tres archivos: **evidencia de fuentes**, **plantilla de importación**
y **documento final del lote**. Las plantillas generadas por
`build-scouting-country-import-templates.py` contienen marcadores
`REQUIRES_CURRENT_COUNTRY_FINGERPRINT`; no pueden publicarse como lotes ejecutados.
Su manifiesto intermedio usa `status='review_templates_require_current_fingerprints'`.
Sustituir las huellas sólo después de consultar el estado vivo del país, fijar
la clave del lote y congelar entonces los bytes definitivos.

Calcular SHA-256 y tamaño UTF-8 por separado para la evidencia, cada plantilla
y cada documento final. El `content_sha256` pasado al importador identifica el
JSON final de ese lote; el hash del conjunto de fuentes se conserva como una
referencia separada en el manifiesto. No sustituir uno por otro ni incluir un
hash autorreferencial dentro del contenido que se está calculando.

Los JSON grandes pueden conservarse comprimidos sin pérdida mediante gzip con
`mtime=0`. El corte de planteles del 30/10 se distribuye en
`scouting/catalogue-squads-2026-10-30.json.gz` (evidencia, esquema 3) y
`scouting/catalogue-squads-2026-10-30.import.json.gz` (documento del importador,
esquema 2). Descomprimir antes de validar o importar y comprobar que los bytes
recuperados coincidan exactamente con los originales. Los hashes y tamaños del
JSON registrados en `.validation.json` se mantienen: corresponden al contenido
descomprimido, no al contenedor gzip. No volver a serializar, normalizar espacios
ni alterar saltos de línea antes de comprobar esa integridad. Un hash adicional
del archivo comprimido, si se registra, debe identificarse por separado. Aplicar
la misma regla al corte de noviembre y a cada nueva versión: guardar en el
manifiesto ruta, bytes y SHA-256 del original y del gzip, además del commit base,
país, tipo y clave de lote. Registrar el hash del HTML observado cuando esté
disponible, junto con su URL y fecha, para rastrear la extracción.

Dividir la importación en lotes de aproximadamente **20–40 clubes o planteles**,
ajustando la cantidad para que cada JSON final se mantenga, en general, por
debajo de **unos 500 KB sin comprimir**. El límite del importador es 20 MB y
1000 clubes o planteles; es un límite técnico, no el tamaño recomendado.
No dividir un club y sus competencias, ni las filas de un mismo plantel, entre
varios documentos. Cada lote conserva sus propios conteos, clave y hash.
Detectar conflictos globales antes de esta partición; una plantilla por país
no habilita a importar ciegamente todos sus registros.

Generar una planilla XLSX fechada con **Cobertura, Clubes, Jugadores, Cambios y
Fuentes**. Incluir país y competencia, distinguir personas únicas de membresías
de plantel, y separar observados, publicados, pendientes y conflictos. Enlazar fuentes.
Guardar el archivo con el mecanismo persistente de archivos disponible y
entregar su enlace. Los archivos públicos sólo contienen información deportiva
y de procedencia; no incluir información privada de socios ni credenciales.

## Publicación idempotente

Preparar una operación explícita de actualización basada en el esquema vivo.
Si requiere DDL, usar el mecanismo de migraciones de Supabase y conservar en
GitHub la versión realmente aplicada. No reinstalar el RPC desde migraciones
históricas ni modificar permisos para facilitar una importación.

La migración de octubre
`20261030193757_scouting_reviewed_squads_and_category_memberships.sql` es el
antecedente de las membresías por categoría. La ampliación por país agrega el
importador de clubes y actualiza el de planteles. Consultar las **definiciones
vigentes** y la versión de migración realmente aplicada; no reinstalarlas desde
un archivo histórico ni confundir disponibilidad del importador con publicación
de datos. Completar esa versión en el manifiesto de cierre.

| Función privada | Documento y uso |
| --- | --- |
| `scouting.catalogue_country_fingerprints(text)` | Huellas y recuentos actuales del país. No publica datos. |
| `scouting.import_club_batch(jsonb,text)` | `metadata` con `schema_version=1`, `kind='reviewed_clubs'`, `country_code`, `country`, `batch_key`; `clubs` y, si hacen falta, `competitions` nuevas. Verifica `expected_clubs_sha256`, `expected_competitions_sha256` y `expected_club_competitions_sha256`. |
| `scouting.import_roster_batch(jsonb,text)` | `metadata` con `schema_version=2`, `country_code`, `country`, `fingerprint_scope='country'`, `batch_key`; `squads`. Verifica `expected_players_sha256` y `expected_clubs_sha256` del país. |

Usar el alcance `country` para los lotes mensuales nuevos, también los de
Argentina. La compatibilidad con documentos históricos argentinos no convierte
una huella global antigua en una huella actual por país. Reutilizar los IDs
vigentes de competencias; una competencia nueva exige fuente, nombre, país y
temporada comprobados. Cambiar el nombre o la temporada de una competencia ya
existente requiere conciliación explícita, no un alta duplicada.

Estos importadores no están expuestos al socio ni habilitados para
`public`, `anon`, `authenticated` o `service_role`. Ejecutarlos por el mecanismo
administrativo de base de datos autorizado, sin conceder privilegios al cliente
ni agregar un bypass al RPC. Conservan el bloqueo común
`scouting.catalogue.refresh` y bloqueos de tablas para serializar las cargas.

Procedimiento por **un lote de un país**:

1. Publicar primero los lotes de clubes/competencias del país y después sus
   planteles. Usar claves únicas que distingan país, tipo, fecha, revisión y
   número de lote; por ejemplo, `br-clubs-2026-12-01-r1-b001`. No reciclar claves
   de cortes anteriores ni utilizar la misma clave para fragmentos distintos.
2. Consultar si esa clave ya existe. Un lote publicado con la misma clave,
   hash **y documento completo** devuelve el resultado sin repetir cambios.
   Cualquier diferencia o estado incompleto exige conciliación. Para recuperar
   una respuesta incierta, reutilizar exactamente el documento original, sin
   reemplazar sus huellas por otras nuevas.
3. Si es un lote nuevo, obtener las huellas vivas del país, completar la plantilla,
   congelar el documento final y registrar sus bytes/hash. Preparar evidencia de
   las filas afectadas antes y después. El importador vuelve a comparar las
   huellas bajo sus bloqueos; si cambiaron, detener esa carga y conciliar el
   trabajo nuevo antes de generar otra revisión.
4. Ensayar el documento final en un único `BEGIN` / `ROLLBACK`, con
   `SET LOCAL lock_timeout='5s'` y `SET LOCAL statement_timeout='120s'`.
   Comprobar las diferencias, respuestas del RPC e idempotencia dentro del ensayo,
   y verificar que el rollback conserve el catálogo y los historiales reales.
   No dejar identidades sintéticas en producción.
5. Tras un ensayo satisfactorio, verificar de nuevo la integridad y ejecutar
   el mismo lote en una transacción de publicación con esos límites locales.
   Un error revierte todo el lote; no declarar publicados otros lotes del país
   que todavía no se ejecutaron. Verificar `catalogue_runs.status`, el resultado
   y los recuentos reales después del commit.
6. **Obtener nuevas huellas después de cada lote publicado**, antes de completar
   el siguiente. Los lotes siguientes no pueden conservar la huella previa al
   primer lote. Si sólo hubo un ensayo revertido y el estado sigue idéntico, el
   documento ensayado puede publicarse sin cambiar sus bytes.

El importador de clubes guarda `before_clubs`/`after_clubs` y
`before_club_competitions`/`after_club_competitions` de las identidades observadas.
Los lotes de planteles con alcance por país guardan `before_players`/`after_players`
de las identidades observadas en ese lote; **la huella sí compara el catálogo
completo del país**. Controlar también las membresías y revisiones afectadas,
incluyendo altas, exclusiones y correcciones explícitas. No duplicar todo el
catálogo nacional en cada snapshot de auditoría del lote ni reescribir
recomendaciones, eventos, autores o pruebas anteriores.

`scouting.players` no tiene columna `source_urls`: la evidencia individual
completa se guarda en los metadatos del lote y en el snapshot versionado.
La procedencia de datos corroborados oficialmente es `official_reference`;
las fuentes públicas revisadas pueden usar `verified_manual` con su evidencia.
Un enlace Transfermarkt no convierte la procedencia en `licensed_transfermarkt`.
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

La primera opción son los lotes pequeños descritos arriba. Si aun así el
documento de **un lote** supera el tamaño práctico de una llamada, usar una
fila de transporte en `scouting.catalogue_runs`, separada del lote de importación.
Este transporte privado no cambia clubes ni planteles y no declara publicado
el catálogo. Un fragmento de transporte no es un lote de importación independiente.

1. Descomprimir, si corresponde, y validar el documento final del lote. Fijar el SHA-256 y los
   bytes UTF-8 del JSON original, la cantidad de fragmentos esperada y un
   `transport_key` propio, distinto del `metadata.batch_key` del documento.
2. Crear o reanudar sólo la fila correspondiente a ese transporte, con
   `source='reviewed_squad_transport'` y `status='staging'`. Guardar los fragmentos
   de texto en `metadata.document_parts`, identificados por índices numéricos.
   Conservar país, tipo de importación y el manifiesto de cantidad, bytes y hash.
   El nombre histórico del origen de transporte no elige el importador:
   el documento completo determina si corresponde a clubes o planteles.
   Repetir un fragmento idéntico
   es inocuo; una clave o un índice con contenido diferente exige conciliación.
3. Recuperar únicamente esa fila mediante su ID, origen, estado y `transport_key`.
   Verificar índices únicos y contiguos y ensamblar los valores en orden numérico,
   no lexicográfico: `jsonb_each_text(metadata->'document_parts')` y
   `string_agg(value, '' order by key::integer)`. Comprobar cantidad de fragmentos,
   `octet_length` y SHA-256 de los bytes UTF-8 antes de convertir el texto a JSONB.
   Un fragmento faltante o cualquier diferencia impide la importación.
4. Ensayar primero el documento completo dentro de un único `BEGIN` / `ROLLBACK`,
   con `SET LOCAL lock_timeout='5s'` y `SET LOCAL statement_timeout='120s'`.
   Si el ensayo detecta un plan inadecuado durante una carga desde una tabla
   pequeña, documentar el caso y limitar cualquier ajuste de planificación a esa
   transacción; no forzar opciones globales ni cambiarlas en el RPC.
   Invocar `import_club_batch` o `import_roster_batch` según el documento,
   comprobar identidades, membresías, exclusiones,
   huellas, historiales y respuestas del RPC. Comprobar también la repetición
   idempotente dentro del ensayo y verificar que el `ROLLBACK` no deje sus cambios.
5. Tras el ensayo satisfactorio, ensamblar y validar otra vez e importar el
   documento completo en una única transacción de publicación con los mismos
   límites locales. No importar cada fragmento por separado. El importador vuelve
   a validar las huellas y publica su propio lote atómicamente. Si la respuesta
   es incierta, consultar el lote por `batch_key`, hash y contenido antes de
   reintentar; la repetición idéntica recupera el resultado sin duplicar jugadores.
6. Si la carga modifica sustancialmente el volumen de las tablas, actualizar
   sus estadísticas con `ANALYZE`: clubes/competencias/membresías de competencia
   para una carga de clubes; `scouting.players`, `scouting.player_squads` y
   `scouting.squad_reviews` para planteles. Después del
   commit, verificar el lote y sus recuentos. Limpiar
   únicamente la fila staging del transporte propio, identificada con las mismas
   condiciones, y sólo si no la referencia ningún registro del catálogo. Conservar
   el lote publicado, el documento y sus evidencias. Si el proceso se interrumpe,
   dejar el staging identificable para reanudarlo; no borrar otros transportes ni
   lotes para resolver una colisión.

## Verificación e informe

Comprobar el resultado real en Supabase y el código publicado: cantidades,
identidades estables, temporada vigente, filtros por país/región/competencia,
selección de jugadores y ausencia de alteraciones de recomendaciones o eventos.
Las pruebas que requieran identidades sintéticas deben ejecutarse dentro de
una transacción con `ROLLBACK`, sin dejar datos de prueba en producción.

Verificar los puntos afectados por el corte:

- `bootstrap`, `clubs` y `players` reciben el `country_code` correcto; sus
  regiones, competencias y recuentos pertenecen a ese país. Omitir el país
  conserva Argentina para los clientes anteriores.
- Un club sin ubicación puede encontrarse por competencia. En países nuevos,
  el formulario comienza por esa ruta y mantiene la región opcional; no rellenar
  datos geográficos para evitar un resultado vacío.
- Un club con varias competencias conserva la elegida en el listado, plantel
  y recomendación. `total_count` corresponde al filtro/paginación, mientras que
  `squad.player_count` describe el plantel del club y categoría.
- Un monónimo del catálogo mantiene su UUID y nombre exacto, incluido
  **Recomendar también**. Un apellido vacío manual sigue rechazándose.
- Los nuevos snapshots identifican el país del club. Los anteriores no se
  reescriben; la interfaz conserva el fallback Argentina cuando falta ese dato.
- Feed, tablero, ranking e historial siguen siendo globales. Cambiar el país
  del formulario no oculta aportes de otros países ni cambia permisos.

Si se modificó el contrato o las funciones, ejecutar además sus regresiones de
autorización, idempotencia, aislamiento del catálogo por país, membresías y
conservación de historiales. La actualización ordinaria de datos no requiere
reinstalar funciones ni ampliar sus permisos.

La política **PAREDES DE CRISTAL** permanece vigente: todos los socios habilitados
ven todas las recomendaciones y devoluciones. La antigüedad no modifica la
visibilidad ni la prioridad deportiva. La actualización no activa Polygon ni
cambia el circuito de auditoría. Un hash o lote local no confirma anclaje en cadena.
No reescribir las fichas históricas, los autores ni los estados durante la carga.
El tablero agrupa repeticiones por UUID estable de catálogo o vínculo manual
explícito desde **Recomendar también**. Un cambio de club no debe crear otra
identidad de jugador; los homónimos manuales independientes no se fusionan.

Entregar por ChatGPT un informe con fecha, **cobertura y resultado por país**,
altas, cambios,
salidas comprobadas, pendientes/conflictos, fuentes inaccesibles, totales
observados y publicados, planilla y referencias de lote/PR. Separar clubes,
planteles, membresías de plantel y personas únicas; no sumar varias apariciones
de la misma persona como jugadores distintos. Distinguir **publicado**, **sin
cambios verificados**, **parcial** y **fallido**. No enviar correos ni mensajes
a terceros desde esta tarea.

Si aparece una conexión, renovación o aprobación realmente necesaria, informar
la acción y etapa bloqueada, conservar el trabajo preparado y no simular éxito.

## Manifiesto vigente: ampliación del 19/11/2026

Los 44 lotes se aplicaron y verificaron en la base. Las cantidades siguientes
son resultados de este corte, no objetivos fijos para el mes siguiente.
La actualización mensual requiere una consulta nueva y una conciliación del
estado vivo; no debe repetir estos documentos como una revisión nueva.

| Recurso del corte | Referencia |
| --- | --- |
| Evidencia de fuentes | `scouting/catalogue-south-america-2026-11-19.json.xz` |
| Índice de fuentes | `scouting/catalogue-south-america-2026-11-19.sources.json.gz` |
| Cobertura observada | `scouting/catalogue-south-america-2026-11-19.coverage.json` |
| Validación de archivos, bytes y hashes | `scouting/catalogue-south-america-2026-11-19.validation.json` |
| Migración realmente aplicada | `supabase/migrations/20261119220235_scouting_south_america_countries.sql` |
| Documentos exactos de los 44 lotes | `scouting/catalogue-south-america-2026-11-19.imports.json.gz` |
| Recibos, hashes y resultados por lote | `scouting/catalogue-south-america-2026-11-19.import-manifest.json` |
| Verificación del catálogo mediante la API | `scouting/catalogue-south-america-2026-11-19.api-validation.json` |
| Integridad y comprobaciones de esta versión | `scouting/catalogue-south-america-2026-11-19.release-validation.json` |
| Versión de recursos web | `20261119-south-america`; despliegue asociado al PR de este cambio |

| País | Lotes nuevos | Clubes activos | Jugadores activos | Revisiones nuevas de plantel |
| --- | ---: | ---: | ---: | ---: |
| Argentina | 0 | 153 | 5.627 | 0 |
| Brasil | 23 | 275 | 6.634 | 310 |
| Chile | 5 | 46 | 1.276 | 53 |
| Colombia | 4 | 36 | 1.146 | 59 |
| Ecuador | 6 | 51 | 1.216 | 62 |
| Uruguay | 6 | 50 | 1.492 | 75 |
| **Total** | **44** | **611** | **17.391** | **559** |

La carga agregó 458 clubes, 11.764 personas y 11.765 membresías de plantel.
Las 49 identidades con afiliación contradictoria se excluyeron antes de crear
los lotes y mantienen sus fuentes para revisión. El cruce con los 5.627
jugadores argentinos no encontró duplicados. No hubo omisiones ni conflictos
adicionales en la importación; las huellas de Argentina, recomendaciones y
eventos anteriores quedaron idénticas a las iniciales.

La prueba real recorrió las 27 páginas de clubes por país y las 62 páginas de
las 47 competencias con cobertura, además de 30 conjuntos de planteles por
país, categoría y estado de fuente. Verificó el filtro de posición más allá
de la primera página y un monónimo brasileño. Usó una sesión sintética y
finalizó con ROLLBACK, sin dejar aportes ni identidades de prueba.

El archivo de hechos se distribuye en XZ para mantener el transporte por debajo
del límite del conector. Su contenido JSON es exactamente el mismo que el
revisado. El paquete `.imports.json.gz` conserva `document_utf8` con los bytes
UTF-8 exactos de cada documento aplicado: comprobar su SHA-256 antes de parsearlo.

Automatización: **pausada**, ID (tarea existente de actualización mensual),
`is_enabled=false`, estado observado antes de la ampliación. Se amplía su
procedimiento a los seis países y se conserva la recurrencia existente del
día 1 a las 08:00 de `America/Argentina/Cordoba`, sin crear un segundo cron.
