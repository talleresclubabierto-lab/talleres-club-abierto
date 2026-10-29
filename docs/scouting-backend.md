# Scouting: backend y verificación

## Alcance implementado

La nueva Edge Function `scouting-api` recibe la sesión existente de Club Abierto.
No cambia `login`, `estado_inicial`, las votaciones ni la configuración de Polygon.
El catálogo se consulta sólo cuando la sección lo solicita.

Todos los socios habilitados pueden leer todas las recomendaciones, su autor,
historial, estado y las devoluciones administrativas. `Mis recomendaciones` es un
filtro del mismo contenido. La antigüedad no determina visibilidad, prioridad,
puntuación ni calidad de scouting. Sólo el autor puede ampliar su recomendación y
sólo administradores habilitados pueden decidir estados o validar clubes.

El catálogo inicial se cargó desde `scouting/catalogue-seed.json`, cuya
procedencia son referencias oficiales verificadas: 11 clubes y ningún jugador importado.
No hay credenciales de Transfermarkt, descargas de sus páginas ni sincronización mensual
habilitada. `bootstrap.catalogue.provider_status` informa `pending_authorization`.
No debe interpretarse el catálogo parcial como cobertura de todas las ligas.

## Archivos y despliegue

- `supabase/migrations/20261029202902_scouting_colaborativo_paredes_de_cristal.sql`: migración de estructura y RPC, aplicada.
- `supabase/migrations/20261029202924_scouting_initial_official_catalogue.sql`: migración del catálogo inicial, aplicada.
- `scouting/catalogue-seed.json`: datos y fuentes verificadas de los 11 clubes iniciales.
- `supabase/functions/scouting-api/index.ts`: Edge Function independiente.
- `supabase/tests/scouting-contract.sql`: prueba de integración, con datos ficticios
  dentro de `BEGIN` / `ROLLBACK`.
- `scripts/test-scouting-api.mjs`: pruebas locales del adaptador HTTP con respuestas
  simuladas del RPC; no usan secretos ni servicios reales.

El CLI Supabase no estaba disponible al preparar este cambio. Las dos migraciones
se aplicaron mediante `apply_migration` y se conservaron con sus versiones reales,
`20261029202902` y `20261029202924`. No se inventaron timestamps de migración.

La prueba de integración SQL se ejecutó satisfactoriamente dentro de `BEGIN` /
`ROLLBACK`. Al finalizar se comprobó que no quedaron recomendaciones de prueba ni
socios sintéticos. Para repetirla, conservar siempre el `ROLLBACK` del script.
Si se compone dentro de otra transacción de ensayo, debe existir un único par externo
de `BEGIN` / `ROLLBACK`.

La Edge Function `scouting-api`, versión 1, quedó en estado `ACTIVE`. Una solicitud
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
| `clubs` | `province?`, `competition_id?`, `query?`, `cursor?` | `items`, `next_cursor` |
| `players` | `club_id`, `category?`, `query?`, `cursor?` | `items`, `next_cursor` |
| `create` | Ver abajo | `recommendation`, `replayed` |
| `feed` | `status?`, `query?`, `mine_only?`, `cursor?` | `items`, `next_cursor` |
| `mine` | `status?`, `cursor?` | `items`, `next_cursor` |
| `detail` | `id` | `recommendation`, `events`, `proof` |
| `add_info` | `id`, `request_id`, `message` | `recommendation`, `replayed` |
| `admin_list` | `status?`, `query?`, `cursor?` | `items`, `next_cursor` |
| `admin_update` | `id`, `request_id`, `status`, `message` | `recommendation`, `replayed` |
| `admin_validate_club` | `id`, `request_id`, `message` | `recommendation`, `replayed` |

Cada página tiene como máximo 25 elementos. `next_cursor` es un valor opaco para el
cliente; debe devolverse tal como se recibió. La implementación inicial utiliza un
offset acotado, por lo que cambios simultáneos del listado pueden mover registros
entre páginas; el cliente puede actualizar la primera página para reconciliarlo.

`clubs.items[].competitions` conserva las competencias y temporadas disponibles.
`reference_scope=primer_equipo_masculino` identifica el alcance de la semilla:
la competencia del primer equipo no es una afirmación sobre el torneo de un juvenil.
La categoría de la recomendación es un campo independiente. El snapshot conserva
la temporada, procedencia, fecha y fuentes de la referencia seleccionada.

`create` recibe:

```json
{
  "request_id": "UUID generado para este envío",
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
    "sector": "derecha"
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
`commitment_hash`. `author.name` muestra el nombre del autor. `can_add_info` aplica
el permiso real de autor y estado abierto; `can_manage` identifica la gestión
administrativa; `club_validated` evita ofrecer una segunda validación del mismo club.
Los eventos muestran tipo, estado, `actor_name`, `actor_role`, mensaje, fecha y hash.
No se exponen DNI, teléfonos, emails, tokens, nonces ni números de socio ajenos.
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

La prueba de detalle calcula el camino Merkle sólo al solicitarla y distingue:

- `registrada`: evento guardado, todavía sin lote.
- `preparada`: lote disponible, sin confirmación de cadena.
- `enviada`: lote marcado como enviado.
- `anclada`: lote existente confirmado con hash de transacción, bloque, fecha y
  prueba Merkle válida. No se afirma una confirmación a partir de un hash local.

Este módulo no activa la integración institucional ni llama al worker Polygon.
La cola y la política de lotes existentes deciden el envío cuando estén habilitadas.
Si falla cualquier parte del registro local/auditoría, se revierte toda la operación.

## Verificación realizada y pendiente

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

## Verificación visual de integración

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
