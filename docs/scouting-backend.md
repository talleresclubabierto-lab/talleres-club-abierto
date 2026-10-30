# Scouting: backend y verificación

## Paneles y seguimiento compartido — 30/10/2026

El acceso **Scouting colaborativo** está en **Otros accesos** de Socio Activo y
Administrador. Ambos abren el mismo módulo con tablero, ranking, listado, detalle
e historial compartidos. Scouting se monta directamente en la sección del panel,
con su barra institucional y el desplazamiento del documento. No usa iframe ni un
segundo encabezado. El componente utiliza Shadow DOM para aislar sus estilos y
se desmonta al volver: cancela solicitudes, temporizadores y escuchas, y descarta
respuestas tardías. Los recursos se cargan al abrirlo y se reutilizan; no se cargan
el catálogo ni el tablero durante el ingreso general a la plataforma. La ruta
independiente `/scouting` conserva el mismo componente y contrato de sesión.

El proceso se inicia en **Socio Activo**. Sólo ese contexto muestra el formulario
y las acciones **Recomendar jugador** y **Recomendar también**. Un administrador
que quiera aportar puede entrar desde su panel de socio. El contexto administrador
muestra las mismas recomendaciones y agrega los controles de gestión. El parámetro
`panel_context` expresa este recorrido de interfaz: no es una credencial ni sustituye
la validación de la sesión y del rol administrativo en el servidor.

### Tablero global y repetición de recomendaciones

`dashboard` calcula totales sobre todas las recomendaciones, independientemente de
la página o los filtros del listado. Presenta jugadores/referencias recomendados,
contactados, visitados, convocados a prueba, con prueba realizada y que no avanzan.
Los hitos son **acumulados** y requieren una actuación explícita: pasar directamente
a `prueba_realizada` no inventa un contacto o una visita anteriores. Un jugador
puede haber alcanzado varios hitos y aparecer en más de un contador.

La identidad se resuelve por el UUID estable del jugador del catálogo o por una
referencia manual vinculada explícitamente. Los ingresos manuales independientes
se mantienen separados; nunca se unen homónimos por nombre. El tablero distingue
jugadores identificados en catálogo, referencias declaradas por socios y total de
recomendaciones recibidas. Cada aporte conserva su autor, snapshot e historial;
el módulo no inventa un estado único para todas las recomendaciones de una persona.

**Jugadores más recomendados** muestra hasta diez identidades con dos o más aportes,
ordenadas por cantidad y, en empates, por fecha del último aporte e identidad estable.
Cada fila informa recomendaciones totales y socios distintos. El club mostrado es
el del último aporte, no una afirmación de afiliación vigente. El enlace abre el
grupo exacto de recomendaciones, sin depender de una búsqueda por nombre.

**Recomendar también** inicia un aporte propio desde una recomendación visible.
`reference_recommendation_id` permite que el servidor derive la identidad y los
nombres de la ficha original. Para un jugador del catálogo vuelve a validar club,
categoría y disponibilidad actuales. Para un jugador manual conserva un vínculo
de identidad declarado por socios; no lo convierte en una identidad verificada.
Club, categoría, posición, motivo y edad manual corresponden al nuevo aporte.
El servidor rechaza un `player.reference_id` arbitrario enviado por el cliente.

### Datos y estados visibles

Debajo del tablero, cada aporte muestra fecha, nombre y **N.º de socio** del autor,
jugador, equipo, competencia o liga, provincia, categoría, edad al recomendar,
posición y valor de mercado. Si falta una referencia de valor verificada muestra
**Sin valor informado**. El mercado conserva moneda, fuente Transfermarkt, fecha
de valoración y fecha de comprobación; un precio escrito por un socio se rechaza.

La edad del catálogo se calcula desde una fecha de nacimiento comprobada con el
calendario de Argentina y se congela al recomendar. La fecha de nacimiento no se
devuelve en la API. La edad manual es opcional, entre 1 y 100 años enteros, y se
identifica como declarada por el socio. Los snapshots históricos no se reescriben
cuando cambia la edad, el mercado o la afiliación en el catálogo.

Los estados disponibles incluyen `contactado`, `visitado`, `convocado_a_prueba`,
`prueba_realizada` y `no_avanza`, además de los estados previos `recibida`,
`en_revision`, `informacion_solicitada`, `en_seguimiento` y `cerrada`. Sólo un
administrador habilitado puede cambiarlos, dejando un motivo público. El historial
identifica al responsable por nombre, número de socio y rol, y conserva fecha,
estado anterior, estado nuevo y constancia criptográfica de cada actuación.

## Alcance implementado

La Edge Function `scouting-api` recibe la sesión existente de Club Abierto.
No cambia `login`, `estado_inicial`, las votaciones ni la configuración de Polygon.
El catálogo se consulta sólo cuando la sección lo solicita.

Todos los socios habilitados pueden leer todas las recomendaciones, su autor,
historial, estado y las devoluciones administrativas. `Mis recomendaciones` es un
filtro del mismo contenido. La antigüedad no determina visibilidad, prioridad,
puntuación ni calidad de scouting. Sólo el autor puede ampliar su recomendación y
sólo administradores habilitados pueden decidir estados o validar clubes.

El catálogo inicial se cargó desde `scouting/catalogue-seed.json`, cuya
procedencia son referencias oficiales verificadas: 11 clubes y ningún jugador importado.
No hay credenciales ni un feed licenciado de Transfermarkt.
`bootstrap.catalogue.provider_status` informa `pending_authorization` para ese proveedor.
La actualización mensual del catálogo con fuentes oficiales se ejecuta desde la
tarea programada documentada en [scouting-monthly-refresh.md](scouting-monthly-refresh.md).
No debe interpretarse el catálogo parcial como cobertura de todas las ligas.

## Archivos y despliegue

- `supabase/migrations/20261029202902_scouting_colaborativo_paredes_de_cristal.sql`: migración de estructura y RPC, aplicada.
- `supabase/migrations/20261029202924_scouting_initial_official_catalogue.sql`: migración del catálogo inicial, aplicada.
- `supabase/migrations/20261029214442_scouting_current_season_projection.sql`: proyección de temporada vigente y conservación de validaciones históricas, aplicada.
- `supabase/migrations/20261030193757_scouting_reviewed_squads_and_category_memberships.sql`: membresías por categoría, revisión de planteles e importador privado, aplicada. La aplicación del esquema no acredita por sí sola la publicación de un lote de datos.
- `scouting/catalogue-seed.json`: datos y fuentes verificadas de los 11 clubes iniciales.
- `supabase/functions/scouting-api/index.ts`: Edge Function independiente.
- `supabase/tests/scouting-contract.sql`: prueba de integración, con datos ficticios
  dentro de `BEGIN` / `ROLLBACK`.
- `supabase/tests/scouting-current-season.sql`: regresión de temporada, afiliaciones
  futuras/históricas y validación tardía de clubes manuales, con `ROLLBACK`.
- `scripts/test-scouting-api.mjs`: pruebas locales del adaptador HTTP con respuestas
  simuladas del RPC; no usan secretos ni servicios reales.

El CLI Supabase no estaba disponible al preparar la implementación inicial. Las dos migraciones
se aplicaron mediante `apply_migration` y se conservaron con sus versiones reales,
`20261029202902` y `20261029202924`. No se inventaron timestamps de migración.

La prueba de integración SQL se ejecutó satisfactoriamente dentro de `BEGIN` /
`ROLLBACK`. Al finalizar se comprobó que no quedaron recomendaciones de prueba ni
socios sintéticos. Para repetirla, conservar siempre el `ROLLBACK` del script.
Si se compone dentro de otra transacción de ensayo, debe existir un único par externo
de `BEGIN` / `ROLLBACK`.

En la verificación inicial del 29/10, la Edge Function `scouting-api`, versión 1,
quedó en estado `ACTIVE`. Una solicitud
HTTP real con token inválido llegó al RPC y devolvió `401 session_expired`, con los
encabezados CORS esperados. Esa comprobación confirma el rechazo de sesiones inválidas;
la autorización y las operaciones válidas se comprobaron en la prueba SQL transaccional.

La Edge Function utiliza `verify_jwt=false` porque la autenticación de esta aplicación
es `X-Club-Session`, no un JWT de Supabase Auth. Eso no otorga acceso público: cada
acción llama al RPC que valida la sesión segura existente y comprueba al socio.

Variables del servidor:

- `SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` provistos por Supabase; también se
  admiten claves modernas de `SUPABASE_SECRET_KEYS`.
- `SCOUTING_ALLOWED_ORIGINS` es opcional para agregar orígenes concretos de pruebas,
  separados por comas. Nunca usar `*`.

Los orígenes de producción y Capacitor están declarados en el archivo. Las claves
de servidor no se incorporan a HTML, JavaScript público, documentación ni logs.

## Contrato HTTP

```text
POST /functions/v1/scouting-api
Content-Type: application/json
X-Club-Session: <sesión vigente>

{"action":"...","payload":{...}}
```

Éxito: `{ "ok": true, ... }`.

Error: `{ "ok": false, "error": { "code": "...", "message": "..." } }`,
con HTTP 401, 403, 404, 409, 413, 415, 422, 429 o 503 según corresponda.
Los errores internos no devuelven mensajes SQL, valores del formulario ni secretos.
Las respuestas usan `Cache-Control: no-store`.

| Acción | Carga útil | Respuesta |
| --- | --- | --- |
| `bootstrap` | `{}` | `actor`, `provinces`, `competitions`, `positions`, `categories`, `catalogue` |
| `dashboard` | `{}` | `dashboard` global, con hitos y `most_recommended_players` |
| `clubs` | `province?`, `competition_id?`, `query?`, `cursor?` | `items`, `next_cursor` |
| `players` | `club_id`, `category?`, `query?`, `cursor?` | `items`, `next_cursor`, `total_count`, `squad` |
| `create` | Ver abajo | `recommendation`, `replayed` |
| `feed` | `status?`, `query?`, `mine_only?`, `player_id?`, `reference_recommendation_id?`, `cursor?` | `items`, `next_cursor` |
| `mine` | `status?`, `cursor?` | `items`, `next_cursor` |
| `detail` | `id` | `recommendation`, `events`, `proof` |
| `event_proof` | `event_id` | `event_id`, `proof` de esa actuación |
| `add_info` | `id`, `request_id`, `message` | `recommendation`, `replayed` |
| `admin_list` | `status?`, `query?`, `cursor?` | `items`, `next_cursor` |
| `admin_update` | `id`, `request_id`, `status`, `message` | `recommendation`, `replayed` |
| `admin_validate_club` | `id`, `request_id`, `message` | `recommendation`, `replayed` |

Cada página tiene como máximo 25 elementos. `next_cursor` es un valor opaco para el
cliente; debe devolverse tal como se recibió. La implementación inicial utiliza un
offset acotado, por lo que cambios simultáneos del listado pueden mover registros
entre páginas; el cliente puede actualizar la primera página para reconciliarlo.

### Planteles y selección de categoría

Al seleccionar un club, el formulario elige **Primera** y consulta su plantel
automáticamente. El socio puede cambiar a **Reserva** u otra categoría. El selector
informa cuántos jugadores muestra y el total correspondiente al filtro; una
búsqueda sin coincidencias no se presenta como un plantel vacío. Mantiene la
entrada manual de jugadores y la opción **Otro club**.

`players.squad` incluye `category`, `player_count`, `expected_count`, `status`,
`checked_at`, `source_url`, `source_season`, `competition_season` y
`available_categories`. Cada categoría disponible informa su propia cobertura.
`competition_season` es la temporada de la competencia del catálogo;
`source_season` conserva el rótulo observado en Transfermarkt, que puede ser
diferente o desconocido. `season` es un alias de este último. La fecha de consulta
no se convierte en fecha de valoración ni en temporada de la fuente.

Los estados de cobertura son `verified` (todas las filas de jugadores de la tabla
consultada se incorporaron), `partial`, `not_loaded` y `unavailable`. Una tabla
completa en la fuente no garantiza la integridad del plantel real de la institución.
Los planteles vacíos, las fuentes inaccesibles y las extracciones parciales quedan
identificados, sin inferir que el club carece de jugadores.

`scouting.player_squads` relaciona a una misma persona con Primera y Reserva,
conservando su UUID. La identidad de Transfermarkt tiene un índice único por ID
de perfil; no se deduplica por nombre. `scouting.squad_reviews` conserva el alcance
de cada revisión. Ambas tablas son privadas, con RLS forzada y sin permisos para
`anon`, `authenticated` ni acceso directo de `service_role`. El RPC valida la
sesión de Club Abierto y devuelve únicamente el contrato documentado.

El importador privado `scouting.import_roster_batch(jsonb,text)` recibe un corte
revisado completo. Valida la huella previa de clubes y jugadores, conserva una
clave y un hash por lote, admite una repetición idéntica sin duplicar datos y
rechaza una clave reutilizada con otro contenido. Serializa las actualizaciones
del catálogo y comprueba identidades repetidas entre clubes antes de importar.
Los conflictos quedan registrados; no se decide una afiliación por el orden de
carga ni se reactivan bajas deliberadas. Las ausencias en una fuente parcial no
eliminan jugadores, membresías ni recomendaciones.

La nómina revisada y sus fuentes se conservan en
`scouting/catalogue-squads-2026-10-30.json.gz`. Su procedencia es `verified_manual`:
consulta de páginas públicas y normalización de hechos deportivos, sin credenciales
ni feed licenciado de Transfermarkt. Los valores de la tabla del plantel que no
incluyen fecha de valoración individual no se publican como valores verificados;
se conservan las referencias individuales comprobadas en el corte anterior.

El corte contiene **5.627 jugadores distintos y 5.651 relaciones de plantel**:
4.266 de Primera y 1.385 de Reserva. Los jugadores que figuran en ambas categorías
se cuentan una vez como personas. Se revisaron 264 fuentes: 153 de Primera y 111
de Reserva. Las reservas de 107 clubes contienen jugadores; tres páginas no
publicaron filas y una no se pudo consultar.

El lote `argentina-squads-2026-10-30` se confirmó en la base el 30/10/2026 a las
19:48:31 UTC, con id `4f07dbfd-271e-4364-a130-0345e90bae35`. La consulta posterior
confirmó esos recuentos, las 264 revisiones y la conservación de las 21 identidades
previas y los 20 valores de mercado verificados, sin cambios en sus datos protegidos.
El ensayo completo y la repetición idempotente pasaron antes de la confirmación.
El RPC real devolvió Aldosivi Primera 30 (páginas de 25 y 5) y Reserva 32, también
después del commit. Las sesiones sintéticas de comprobación se eliminaron mediante
`ROLLBACK`. El manifiesto `.validation.json` conserva los resultados. El envío a
Polygon seguía deshabilitado.

En la carga inicial desde 21 jugadores, el planificador escogía búsquedas
secuenciales por identidad. El ensayo completo excedió el tiempo de la llamada y
se comprobó que no había persistido cambios. Con `SET LOCAL enable_seqscan=off`
y `SET LOCAL jit=off`, el ensayo pasó en 13,1 segundos y la importación confirmada
en 13,9 segundos, incluyendo el transporte de la herramienta. Se actualizaron las
estadísticas de jugadores, membresías y revisiones mediante `ANALYZE`; las opciones
locales no modifican el planificador de la aplicación ni su configuración global.

| Competencia del primer equipo | Clubes | Jugadores de Primera | Reservas con jugadores | Jugadores de Reserva |
| --- | ---: | ---: | ---: | ---: |
| Primera División / Liga Profesional | 30 | 892 | 30 | 875 |
| Primera Nacional | 36 | 1.010 | 33 | 341 |
| Federal A | 37 | 1.114 | 30 | 120 |
| Primera B | 22 | 637 | 13 | 46 |
| Primera C | 28 | 613 | 1 | 3 |

Estos recuentos describen las filas comprobadas en las fuentes, no todas las ligas
argentinas ni la exhaustividad deportiva de las nóminas. Defensores de Belgrano
(Primera) conserva 8 de las 24 filas del plantel; los otros 16 nombres quedaron
pendientes tras un bloqueo de la fuente. All Boys (Reserva) registra una consulta
inaccesible. Las reservas de Centro Español, Lugano y Puerto Nuevo no publicaron
jugadores en las tablas consultadas. No se infirieron nombres ni bajas a partir
de esos límites.

`scouting/catalogue-squads-2026-10-30.import.json.gz` conserva exactamente el documento
reducido que recibe el importador (esquema 2), incluidas las huellas del estado
anterior. El snapshot de evidencia usa esquema 3. El archivo `.validation.json`
registra los hashes de ambos; son contenidos distintos con finalidades distintas.
Los dos archivos usan gzip sin pérdida, con `mtime=0`. Al descomprimir se recuperan
exactamente los bytes de los JSON originales, incluidos espacios y saltos de línea.
Los SHA-256 y tamaños originales de `.validation.json` siguen correspondiendo al
contenido descomprimido; no se sustituyen por el hash ni el tamaño del contenedor
gzip. La compresión no cambia el documento de importación ni la identidad del lote.
Una ejecución mensual prepara una nueva clave y nuevas huellas: no modifica ni
vuelve a utilizar este corte histórico como si fuera una consulta nueva.

Para transportar un documento grande, se pueden almacenar fragmentos de su texto
original en `catalogue_runs.metadata.document_parts`, con índices numéricos y un
registro `status='staging'`, `source='reviewed_squad_transport'`. Su `transport_key`
es distinto de `batch_key`: transportar fragmentos no publica ni importa jugadores.
Antes de convertir el texto a JSONB, se ensambla en orden numérico y se comprueban
cantidad de fragmentos, bytes UTF-8 y SHA-256 del documento original. La importación
privada se ejecuta una sola vez sobre el documento completo dentro de una transacción,
después de un ensayo con `ROLLBACK`. El lote publicado conserva su propia fila y
sus evidencias. Sólo se elimina el registro de transporte propio, aún en staging y
sin referencias, una vez verificado el resultado. El procedimiento de reanudación,
ensayo y limpieza está en [scouting-monthly-refresh.md](scouting-monthly-refresh.md#transporte-de-documentos-grandes).

Las correcciones de categoría son explícitas y requieren evidencia de una nómina
completa de origen y de la pertenencia a la categoría destino. Conservan la persona,
su UUID y sus datos históricos. Ninguna importación modifica recomendaciones,
eventos de auditoría, compromisos criptográficos ni lotes pendientes de Polygon.

`clubs.items[].competitions` muestra las relaciones de competencias activas cuya
temporada coincide con `competitions.season`. Las relaciones de temporadas
anteriores se conservan en la base y en los snapshots históricos, y no se ofrecen
como afiliaciones actuales al crear una recomendación.
`reference_scope=primer_equipo_masculino` identifica el alcance de la semilla:
la competencia del primer equipo no es una afirmación sobre el torneo de un juvenil.
La categoría de la recomendación es un campo independiente. El snapshot conserva
la temporada, procedencia, fecha y fuentes de la referencia seleccionada.

`create` recibe:

```json
{
  "request_id": "UUID generado para este envío",
  "panel_context": "socio",
  "reference_recommendation_id": null,
  "club_id": null,
  "club_manual": {
    "province": "Córdoba",
    "city": "Ciudad declarada",
    "name": "Club declarado",
    "league": "Liga declarada"
  },
  "competition_id": "liga-local",
  "category": "Sub-17",
  "player_id": null,
  "player": {
    "first_name": "Nombre",
    "last_name": "Apellido",
    "position": "Lateral",
    "sector": "derecha",
    "age_at_recommendation": 17
  },
  "reason": "Descripción deportiva de al menos veinte caracteres",
  "observation": "Contexto opcional de observación",
  "video_url": null,
  "transfermarkt_url": null
}
```

Si se selecciona `club_id`, se usan sus datos del catálogo; el cliente no puede
reemplazarlos mediante `club_manual`. Si se selecciona `player_id`, el servidor
verifica que pertenezca al club y a la categoría, y toma su nombre de la base.
Ningún dato del formulario elige al socio propietario ni sus permisos.

La respuesta de recomendación contiene `id`, `code`, fechas, `status`, `category`,
`club`, `player`, `reason`, `observation`, enlaces, `source`, `audit_event_id` y
`commitment_hash`. `author.name` y `author.numero_socio` identifican al autor. `can_add_info` aplica
el permiso real de autor y estado abierto; `can_manage` identifica la gestión
administrativa; `club_validated` evita ofrecer una segunda validación del mismo club.
Los eventos muestran tipo, `previous_status`, `new_status`, `actor_name`,
`actor_numero_socio`, `actor_role`, mensaje, fecha, `hash_version`, hash y referencia
a la auditoría. Los números de socio se muestran por la premisa de transparencia;
no se exponen DNI, teléfonos, emails, tokens ni nonces.
No existen notas internas: todos los mensajes y decisiones son visibles para todos
los socios habilitados. Un envío con `internal_note` no vacío es rechazado.

## Seguridad y consistencia

- `public.scouting_api(text,text,jsonb)` es el único RPC concedido a `service_role`.
  Se revoca su ejecución a `PUBLIC`, `anon` y `authenticated`.
- Las tablas están en el esquema privado `scouting`, con RLS forzado y sin grants
  a esos roles ni a `service_role`. Las funciones auxiliares no son APIs públicas.
- El wrapper es `SECURITY DEFINER` de forma deliberada: permite exponer operaciones
  acotadas sin conceder acceso directo a las tablas. Usa `search_path=pg_catalog`
  y nombres calificados, valida siempre `validar_sesion_segura_interno`, y revisa
  `socios.habilitado` y `administradores.habilitado`. Los metadatos editables del
  usuario no conceden privilegios.
- El UUID de `request_id` debe conservarse durante los reintentos del mismo envío.
  Mismo actor + UUID + contenido retorna el registro existente; un contenido distinto
  devuelve 409. Un bloqueo por actor serializa la comprobación y evita duplicados
  causados por solicitudes simultáneas. Cambios de estado además bloquean la fila.
- Hay un máximo de 20 recomendaciones nuevas por socio en 24 horas; los reintentos
  idempotentes no consumen cupo. Cuerpo HTTP: 32 KiB.
- Motivo: 20–4000 caracteres; observación: hasta 2000; mensajes: hasta
  4000; nombre y apellido: 2–100 cada uno; club: 2–160; ciudad: 2–100; liga: 2–160;
  categoría: 2–100. `Otra` requiere escribir el nombre de la categoría.
- Enlaces opcionales HTTPS de perfiles Transfermarkt y de YouTube/Vimeo pasan por
  validación de dominio y ruta. No se descargan, previsualizan ni ejecutan en servidor.
- Las recomendaciones originales, actuaciones y solicitudes idempotentes son
  inmutables. El estado actual es una proyección actualizada en la misma transacción
  que su evento. Una recomendación cerrada no recibe ampliaciones del socio; un
  administrador puede reabrirla dejando el motivo correspondiente.
- `admin_validate_club` exige motivo, crea o vincula un club por identidad normalizada
  con bloqueo contra carreras, registra la decisión y conserva el snapshot anterior.
  No publica automáticamente datos de un club ingresado por un socio.
  Si crea una relación de competencia, conserva la temporada declarada en ese
  snapshot; una aprobación posterior no la convierte en una afiliación de la
  temporada vigente. Si no hay temporada informada, no inventa una relación.

## Auditoría y blockchain

Cada escritura crea un evento privado con actor, contenido, hash anterior y un nonce
aleatorio privado. El compromiso se registra en `public.registrar_auditoria_interna`
dentro de la misma transacción, utilizando sus lotes Merkle generales existentes.

Esa función normalmente resuelve el nombre del actor. El helper de scouting limpia
temporalmente `app.actor_socio`, pasa `actor_hint=NULL` y restaura el contexto tanto
al salir como ante errores. La auditoría general recibe sólo el UUID opaco del evento,
el tipo de operación y su compromiso: no recibe nombres, números de socio, fichas,
mensajes ni el nonce. La identidad auténtica se conserva en el esquema protegido
y el nombre se muestra a los socios en el historial de la sección. El nonce nunca
se expone. Esta separación evita publicar en blockchain los datos de la ficha.

`recommendation.commitment_hash` compromete la ficha original; `proof.commitment_hash`
es el compromiso del primer evento que contiene el hash de esa ficha. Las actuaciones
posteriores tienen sus propios hashes y referencias a la auditoría general.

Las actuaciones nuevas usan `scouting-event-v2`: el hash compromete también el
estado anterior registrado junto al estado nuevo, actor y rol. `hash_version=1`
conserva los eventos previos sin recalcularlos; para esos eventos el estado anterior
se puede reconstruir de la secuencia para mostrarlo, con
`previous_status_source=event_sequence`, sin afirmar que formaba parte de su hash.
`event_proof` calcula la constancia de la actuación solicitada, con la misma
distinción de estados del registro inicial. Se consulta al abrirla, no una vez por
fila de todo el listado.
La atribución proviene de la sesión autenticada y la auditoría del sistema;
no se presenta como una firma digital personal emitida por el administrador.

La prueba de detalle calcula el camino Merkle sólo al solicitarla y distingue:

- `registrada`: evento guardado, todavía sin lote.
- `preparada`: lote disponible, sin confirmación de cadena.
- `enviada`: lote marcado como enviado.
- `anclada`: lote existente confirmado con hash de transacción, bloque, fecha y
  prueba Merkle válida. No se afirma una confirmación a partir de un hash local.

Este módulo no activa la integración institucional ni llama al worker Polygon.
La cola y la política de lotes existentes deciden el envío cuando estén habilitadas.
Si falla cualquier parte del registro local/auditoría, se revierte toda la operación.

La consulta del 30/10/2026 encontró Polygon de producción configurada (chain 137),
pero la integración general con estado `estructurada_no_activada`. Por lo tanto,
registrar una recomendación o actuación no demuestra un anclaje nuevo. El módulo
informa la constancia real de cada evento; no cambia la configuración institucional,
no ejecuta envíos de fondos y no presenta lotes preparados como confirmados.

### Acumulación de lotes con Polygon inactiva

Las recomendaciones y todas sus actuaciones ingresan en la misma auditoría general
dentro de la transacción de escritura. Esa cola persiste aunque la integración esté
en `estructurada_no_activada` o `desactivada`. La preparación de lotes no depende de
la habilitación del envío a la cadena.

La política vigente revisada es de **500 movimientos o 24 horas** desde el último
lote preparado. El trigger evalúa el umbral por cantidad y el cron institucional
`club-abierto-evaluar-anclaje-auditoria`, activo con frecuencia horaria, evalúa el
vencimiento temporal. Con poco movimiento, el lote se prepara en la primera
evaluación horaria que encuentre cumplido el plazo. No se crea un segundo cron ni
un lote por recomendación. Un evento todavía en espera de cierre muestra
`registrada`; una vez incluido en un lote muestra `preparada`, con su ID, raíz y
prueba individual. Ningún estado pendiente se presenta como confirmación en cadena.

Los preparadores ordinario, extraordinario y de rango toman al inicio el mismo
bloqueo transaccional de la cadena de auditoría, antes de leer o construir el lote.
Así, la evaluación horaria y las escrituras de los socios utilizan el mismo orden
de bloqueo y no compiten para preparar simultáneamente un mismo tramo.

Al activar institucionalmente la integración, el procedimiento existente prepara
el remanente histórico hasta el máximo de auditoría que capturó, incluyendo un
último lote de tamaño inferior al umbral. Los lotes ya preparados conservan sus
fechas, rangos y raíces y siguen siendo elegibles para el worker: no se excluyen por
ser anteriores a la activación ni por tener `chain_id` todavía vacío. El worker
procesa los pendientes por antigüedad. La activación no altera las fechas de los
hechos originales.

El cron de conciliación observado invoca `reconcile`, que comprueba transacciones
ya enviadas y devuelve `broadcast:false`; no dispara nuevos envíos ni encadena
`anchor`. La habilitación e invocación del proceso de envío corresponden a la etapa
de activación institucional. Esta entrega garantiza preparación y conservación,
sin presentar la conciliación como un envío automático de la cola.

La cobertura se comprueba por cada `scouting.events.audit_event_id`, buscando su
auditoría y al menos un rango de lote que lo incluya, además de recomputar la raíz
Merkle. Comparar solamente el máximo ID cubierto podría ocultar un hueco. El registro
administrativo de la propia creación de un lote queda para el tramo siguiente;
esto no deja fuera los eventos de scouting incluidos en el lote que se acaba de
cerrar.

El envío conserva sus mecanismos operativos existentes. Un lote que fallara después
de ser reservado como `enviado` y antes de guardar un hash de transacción requiere
la revisión señalada por la conciliación (`missing_transaction_hash_manual_review`).
La conservación en lotes preparados y su elegibilidad no equivalen a garantizar una
confirmación futura sin errores de red o de envío.

La migración aplicada `20261030190632_audit_batch_preparation_shared_lock.sql`
incorpora esos tres bloqueos tempranos y comprueba las definiciones y permisos
antes y después. `supabase/tests/scouting-batching.sql` pasó junto con el contrato
de scouting dentro de una transacción revertida: ocho actuaciones de una ficha,
una segunda ficha, cierre real por cantidad, remanente extraordinario y rama
temporal con reloj controlado. Para esta última se deriva un clon en `pg_temp`
desde la función viva, cambiando sólo el encabezado y el reloj de comparación;
no se modifican funciones públicas ni fechas históricas para simular el tiempo.
Cada actuación terminó cubierta por un solo lote del ensayo, con raíz y prueba
Merkle verificadas. Los reintentos no agregaron eventos ni lotes. Después del
despliegue se confirmó la política original 500/24, envío deshabilitado, permisos
conservados, ningún hueco previo al último rango cubierto y ningún socio sintético
persistido. No se ejecutó una prueba de carga concurrente con socios reales.

## Verificación inicial — 29/10/2026

Ejecutado localmente:

```text
node --experimental-strip-types scripts/test-scouting-api.mjs
```

Siete pruebas del handler aprobadas: contrato de RPC, CORS, sesión ausente,
métodos/preflight, límites/JSON, errores de autorización/conflicto/cupo, aislamiento
de errores inesperados y claves secretas modernas. Son pruebas de adaptador HTTP;
no equivalen a una prueba de integración con la base ni a medición de carga.

El SQL de integración se ejecutó satisfactoriamente y se revirtió: identidades propias,
lectura compartida y escritura sólo del autor, permisos administrativos, UUID malformado,
idempotencia, devolución administrativa visible y rechazo de notas ocultas,
snapshot y eventos inmutables, hashes recomputables, auditoría sin identidad,
prueba Merkle, validación de club manual, restricciones de cierre, URLs y roles vigentes.
La comprobación posterior informó 0 recomendaciones, 0 socios sintéticos restantes,
11 clubes y 0 jugadores. Todas las tablas nuevas tienen RLS activado y forzado.

La revisión de seguridad no agregó advertencias de nivel WARN. Se observaron diez
avisos INFO por RLS habilitado sin políticas, correspondientes a las diez tablas del
esquema privado. Es deliberado: no tienen acceso directo concedido a clientes y el
único RPC autorizado valida sesión y rol antes de operar. La documentación oficial
explica el comportamiento de [RLS y las políticas de acceso](https://supabase.com/docs/guides/database/postgres/row-level-security).

También aprobaron las cuatro comprobaciones de regresión del ingreso y las
compilaciones/generaciones web y móvil. La comparación byte a byte confirmó que el
código de ingreso existente no fue alterado. Esto no equivale a publicar una nueva
versión Android ni a comprobar todos los flujos desde un dispositivo físico.

En este punto de verificación, la revisión visual del frontend y la publicación del
código en GitHub seguían a cargo del integrador. No se realizaron pruebas de
concurrencia real ni un benchmark de catálogo masivo; los bloqueos e índices no
reemplazan esa medición. Estas comprobaciones tampoco confirman un envío nuevo a
Polygon: no se activó la integración ni se creó una transacción de anclaje desde scouting.

## Verificación visual inicial — 29/10/2026

El recorrido se verificó en navegador con el HTML, CSS y JavaScript finales y
respuestas simuladas aisladas del despliegue: listado compartido, detalle de otro
socio y devolución visible, filtro de aportes propios, búsqueda provincial con
cambio de competencia, orden alternativo por competencia, carga y envío de club
manual, ampliación del aporte propio y cambio administrativo de estado con motivo
público. La vista a 375 px conserva controles legibles y no presenta desplazamiento
horizontal. Los datos ficticios de esta prueba no se enviaron a producción.

El servicio real y el SQL se verificaron por separado según las comprobaciones
anteriores. Esta revisión no equivale a usar una cuenta real de socio en el flujo
completo del navegador.

## Ampliación manual del catálogo argentino — 29/10/2026

La migración `20261029205239_scouting_argentina_catalogue_manual_2026_10.sql`
publica el corte documentado en `scouting/catalogue-argentina-2026-10.json`.
Se incorporaron 142 clubes y se enriquecieron los 11 existentes, conservando sus
UUID y claves: 153 clubes activos en total, todos con ID y enlace observado de
Transfermarkt. La distribución del primer equipo masculino en 2026 es Primera
División 30, Primera Nacional 36, Federal A 37, Primera B 22 y Primera C 28.

La membresía y la ubicación se contrastaron con AFA, clubes y organismos públicos.
La localidad corresponde a la sede deportiva estable; las sedes administrativas
divergentes y precisiones geográficas quedan documentadas por registro. Las URLs
históricas de Transfermarkt se preservan como referencias de identidad, sin
atribuirles una confirmación de la temporada actual ni cambiar sus parámetros.
Esta carga no es un feed licenciado ni una descarga integral de Transfermarkt.

Se recopilaron 121 referencias de jugadores. Sólo 21 jugadores de Talleres,
corroborados con fuentes oficiales recientes del club, se publicaron en
`scouting.players`. Las 98 referencias pendientes y los 2 conflictos de club se
conservan en la planilla y en `catalogue_runs.metadata.player_references`; no son
seleccionables como jugadores actuales. Las posiciones ambiguas quedan vacías
para que el socio elija la posición que observó. No se declara plantel completo.

El lote conserva sus fuentes, estados de revisión y SHA-256 del JSON. Repetir la
misma clave y contenido no duplica registros; una clave ya publicada con otro
hash se rechaza. Las correcciones posteriores requieren un nuevo corte revisado.
Esta carga fue manual. El procedimiento recurrente posterior está documentado en
[scouting-monthly-refresh.md](scouting-monthly-refresh.md); su programador es la tarea
de ChatGPT, sin un segundo cron en Supabase.
No se borran clubes, recomendaciones ni eventos, ni se reactivan bajas existentes.

El selector de jugadores agrega `transfermarkt_url` y `checked_at` al contrato
existente. El frontend muestra el enlace observado del club y puede completar el
perfil del jugador; preserva cualquier enlace escrito manualmente. La fecha se
refiere a la revisión de la ficha individual. La lectura compartida, los roles y
las reglas de auditoría siguen siendo los mismos.

## Actualización mensual y temporadas — 29/10/2026

La tarea **Actualización del scouting argentino** quedó habilitada en ChatGPT
para el día 1 de cada mes por la mañana, en horario de Córdoba, con inicio el
1/11/2026. El procedimiento completo, las fuentes, la conciliación, los snapshots,
las planillas y la recuperación ante fallos están en
[scouting-monthly-refresh.md](scouting-monthly-refresh.md).

La migración `20261029214442_scouting_current_season_projection.sql` ajusta la
proyección de competencias y la creación de recomendaciones a la temporada
vigente configurada de cada competencia. Las relaciones anteriores y futuras
se conservan, pero no se ofrecen como afiliaciones actuales. Una recomendación
antigua mantiene su snapshot, incluso cuando se repite su envío idempotente.
La validación tardía de un club manual conserva la temporada declarada.

La definición se recuperó del RPC vivo y el cambio se ensayó junto con 15 grupos
de regresión de temporada y el contrato completo de scouting, dentro de una única
transacción revertida. Después de aplicar la migración se verificaron la definición
esperada, los permisos, el modo de ejecución y las huellas completas del catálogo:
153 clubes, 21 jugadores y todas sus relaciones permanecieron iguales. No quedaron
socios ni recomendaciones de prueba. El cambio no modifica el circuito de auditoría
ni confirma una nueva transacción blockchain.

## Despliegue y regresión del tablero — 30/10/2026

Se aplicaron mediante migraciones nativas de Supabase, conservadas con sus versiones
reales:

- `20261030185101_scouting_shared_dashboard_and_audited_states.sql`: tablero,
  referencias de jugador, nuevos estados, autoría visible, metadatos y eventos v2.
- `20261030185115_scouting_verified_player_details_2026_10_30.sql`: enriquecimiento
  de 21 jugadores, 21 fechas de nacimiento comprobadas y 20 valores de mercado.

El segundo lote usa el snapshot
`scouting/catalogue-player-details-2026-10-30.json`, con SHA-256
`23d77f77bb21429e55a4c4bb7dd638c71ea192d372558b91b3009ffb2ef70257`.
Corrige además las afiliaciones de Alex Vigo a Independiente Rivadavia y Bruno
Barticciotto a Huracán, con anuncios específicos de Talleres y perfiles contrastados.
Conserva sus UUID, claves y evidencia anterior. Jeremías Florentín no tiene valor
informado en la referencia revisada; se conserva `null`. Las fechas de los valores
son las propias de cada valoración, no la fecha de esta carga.

La Edge Function se desplegó como **versión 4, ACTIVE**, con `verify_jwt=false` y
la misma validación de sesión propia. Se partió de la versión viva 3; el adaptador
sólo agregó `dashboard` y `event_proof` a su lista de acciones.

Antes de publicar se ensayaron, dentro de una única transacción revertida, ambas
migraciones, la repetición idempotente del lote y las tres suites SQL. Cada suite
se aisló con un savepoint. `supabase/tests/scouting-dashboard.sql` cubre 35 aportes
sintéticos, conteos más allá de 25 filas, duplicados de catálogo y referencias
manuales explícitas, homónimos independientes, estados y motivos, autores, roles,
valores verificados, edad, snapshots inmutables, compatibilidad de hashes v1/v2
y pruebas Merkle de la actuación correcta. También pasaron el contrato previo
y las regresiones de temporada vigente e historial de afiliaciones.

La comprobación posterior al despliegue confirmó 153 clubes, 21 jugadores activos,
21 fechas de nacimiento y 20 valores verificados, además del hash de lote esperado,
las dos afiliaciones corregidas y los permisos del RPC. Había cero recomendaciones
reales en ese corte y no quedaron recomendaciones, eventos ni socios sintéticos.
La revisión de seguridad no agregó hallazgos respecto de su línea base; los avisos
preexistentes de otras funciones permanecieron fuera del cambio.

Las pruebas locales de navegación, frontend y adaptador HTTP pasaron, junto con la
compilación web y las regresiones de navegación general y Comunidad Formativa:

```text
node scripts/build-cloudflare.mjs
node scripts/test-navigation-stability.mjs
node scripts/test-formative-html.mjs
node scripts/test-scouting-navigation.mjs
node scripts/test-scouting-frontend.mjs
node --experimental-strip-types --test scripts/test-scouting-api.mjs
```

La prueba de navegación realiza 50 recorridos de apertura/retorno y verifica la
eliminación del iframe, el contexto por rol y los mensajes de origen válido. La
suite del frontend usa el código real con un DOM y respuestas simuladas; cubre
repetición de mensajes, paginación, referencias manuales, sesiones, constancias
bajo demanda y cancelación de solicitudes. No equivale a una comprobación visual
del recorrido autenticado en un navegador real. El acceso al fixture local fue
bloqueado por la política del navegador; no se intentó eludirla ni se publicaron
las pantallas con datos ficticios. Las pruebas tampoco confirman una transacción
nueva en Polygon.
