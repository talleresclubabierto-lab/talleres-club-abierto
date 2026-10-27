# Comunidad Formativa — diseño técnico

**Estado:** esquema privado aplicado en Supabase. La recepción de solicitudes de alta y su revisión administrativa se implementan en esta etapa. No hay padrón importado ni datos reales de menores.

## Objetivo y límites

Agregar acompañamiento e integridad de divisiones formativas sin modificar el padrón general, las votaciones, la gobernanza, la auditoría económica, las sesiones actuales de socios, sus hashes, sus lotes o sus anclajes. La incorporación inicial no presupone que exista un padrón institucional.

El sistema actual usa un frontend monolítico en `index.html`, Edge Functions y Supabase. La autenticación de socios se apoya en sesiones propias y `X-Club-Session`; no se usa como identidad de Comunidad Formativa. La configuración Polygon existente permanece en `estructurada_no_activada`. El anclaje de Comunidad Formativa se mantiene en tablas y funciones separadas y no activa envíos.

## Dos etapas, un mismo flujo

### Etapa 1 — sin padrón del club

- La persona adulta solicita el alta, declara su vínculo y confirma su correo con OTP.
- La solicitud exige nombre y DNI del adulto responsable, vínculo, teléfono, nombre y DNI del jugador y fecha de nacimiento. Los DNI se guardan cifrados; sus valores no aparecen en registros públicos ni en la cadena.
- La carga de constancias mediante almacenamiento privado queda como siguiente integración; la solicitud inicial se revisa administrativamente.
- La solicitud queda “pendiente de validación”. La declaración por sí sola no se presenta como pertenencia confirmada.
- Un responsable autorizado revisa la solicitud y deja constancia de la fuente de validación. Solo después se habilita la cuenta.
- La cuenta principal es de la madre, el padre o el tutor. No se abre cuenta individual a menores de 16 años.

### Etapa 2 — padrón institucional

- Se importa una planilla validada o se integra una API en un área de staging cifrada.
- Se comparan registros mediante HMAC de identificadores normalizados; nunca mediante DNI en claro ni hashes simples vulnerables a búsqueda por diccionario.
- La importación se vincula con los mismos UUID internos creados en la primera etapa. Los perfiles, casos y códigos de seguimiento se conservan.
- Duplicados, datos discordantes y vínculos múltiples requieren revisión; una importación no sobrescribe automáticamente información de contacto confirmada.
- Desde los 16 años se puede habilitar una cuenta individual del jugador tras verificación y consentimiento aplicables.

El primer flujo permite confirmar el correo y enviar la solicitud. La bandeja administrativa requiere una sesión vigente del administrador principal; el listado muestra solo código, fecha y estado. Abrir identidad y decidir requieren motivo y confirmación, y quedan asentados en una tabla append-only. No se crean portales distintos según si la persona conoce DNI o número interno.

## Esquema aislado

La migración crea el esquema privado `comunidad_formativa`. Cada tabla tiene RLS habilitada y forzada; se revocan permisos de `public`, `anon` y `authenticated`. Solo `service_role` recibe permisos SQL. El esquema no debe añadirse a los esquemas expuestos de la Data API.

| Tabla | Uso |
|---|---|
| `solicitudes_acceso` | Alta voluntaria, consentimiento y revisión |
| `jugadores`, `adultos_responsables`, `vinculos` | Padrón separado, adultos autorizados y fuente/estado de validación |
| `cuentas`, `codigos_otp`, `codigos_activacion`, `sesiones` | Identidad independiente, OTP y código de activación de un uso, y sesión cuyo token solo se almacena como HMAC |
| `roles_administrativos` | Administrador general, responsable de integridad y principal de integridad |
| `casos`, `archivos`, `actuaciones` | Presentaciones, adjuntos, estados, solicitudes/respuestas, medidas y resoluciones |
| `accesos_identidad`, `auditoria_solicitudes_acceso` | Motivo, usuario y hora de consulta o decisión administrativa |
| `proyeccion_socios` | Campos mínimos preparados para consulta anonimizada; no es una vista directa de la tabla de casos |
| `eventos_criptograficos`, `lotes_merkle`, `anclajes` | Cadena y lotes propios del módulo, separados de las tablas actuales |
| `importaciones`, `importacion_items` | Staging para archivo/API y conciliación segura |

Los datos personales, relatos y fecha aproximada del hecho se guardan como ciphertext AES-GCM, nonce aleatorio y versión de clave. Los DNI y contactos no se guardan en claro en claves de búsqueda: se usa HMAC con secreto fuera de la base. El archivo de importación y la evidencia se alojan en el bucket privado `comunidad-formativa-privada`. No se incluyen datos seed.

## Roles y autorización

- **Administrador general:** padrón, solicitudes y operación; sin acceso automático a identidad reservada ni relatos confidenciales.
- **Responsable de Integridad Formativa:** seguimiento, solicitudes de información, actuaciones, derivaciones y resolución. Trabaja inicialmente sin la identidad cuando la reserva lo solicita.
- **Administrador principal de Integridad:** puede pedir desbloqueo excepcional. La función requiere sesión, rol, motivo, confirmación expresa y registro append-only.
- **Adulto responsable / jugador habilitado:** acceso solo a perfiles vinculados y presentaciones propias, comprobado en servidor.
- **Socio activo:** acceso solo a la proyección anonimizada mediante sesión validada del sistema actual.

Las Edge Functions derivan el actor de la sesión validada en servidor. No confían en IDs de actor enviados por el navegador ni en `user_metadata`. El uso de `service_role` queda exclusivamente en secretos de Edge Functions. El esquema privado, sin grants al cliente y con RLS forzada, funciona como defensa adicional.

## Edge Functions previstas

1. `comunidad-formativa-api`: solicitud, OTP, sesiones, perfiles vinculados, presentaciones, seguimiento y archivos.
2. `comunidad-formativa-admin`: validación de solicitudes, roles, actuaciones, solicitudes de información, estados, protocolos especiales y desbloqueo de identidad.
3. `comunidad-formativa-import`: staging, validación, deduplicación, conciliación y aplicación de archivo/API.
4. `comunidad-formativa-public`: lista y estadísticas con salida allowlist, demoras y supresión de grupos pequeños.
5. `comunidad-formativa-anchor`: preparación/verificación de lotes propios y anclaje solo cuando la integración global esté activada y haya confirmación autorizada.

Cada función tendrá límites de tamaño, validación estricta de MIME y contenido, throttling de OTP, expiración de sesión, logs sin datos sensibles y respuestas genéricas que no permitan enumerar jugadores.

## Presentación, reserva y publicación

Los estados internos son: recibida, en evaluación, información solicitada, en investigación, resuelta, archivada y reabierta. Las actuaciones no se editan ni eliminan; las correcciones se insertan como nuevos eventos.

La proyección para socios usa código anónimo, fecha generalizada, categoría amplia, estado y comprobante criptográfico. No contiene nombre, DNI, números de socio o jugador, categoría deportiva exacta, relato, adjuntos ni personas mencionadas. La publicación se demora y las estadísticas suprimen grupos pequeños (umbral inicial propuesto: menos de cinco). Se usan expresiones de presunción; una presentación no prueba un hecho.

## Hashes y blockchain

Cada evento genera hash en servidor sobre una representación versionada que incluye el hash del ciphertext, código opaco, tipo de actuación y rol. Los archivos tienen SHA-256 propio. Eventos consecutivos forman una cadena; los lotes de Comunidad Formativa tienen raíz Merkle propia. Los eventos y raíces no contienen identificadores personales, DNI, teléfonos, correos, relato ni nombres.

El módulo no inserta filas en `auditoria_administrativa`, `lotes_merkle_auditoria` ni `lotes_merkle_votos`, y no modifica `blockchain-anchor`. La función nueva consultará el estado global vigente y solo podrá enviar si el sistema está activado y un principal autorizado confirma. Mientras tanto, los hashes y pruebas se conservan fuera de cadena. Un hash acredita integridad desde el registro, no que el relato sea verdadero.

## Verificación de esta etapa

- La migración es aditiva: agrega consumo único al desafío OTP, un índice de duplicidad para solicitudes activas y una auditoría privada append-only. No toca tablas del padrón de socios ni funciones de votación, auditoría o anclaje.
- Probar que `anon` y `authenticated` no pueden consultar, insertar, modificar ni borrar tablas/archivos.
- Probar acceso administrativo con sesión vigente, autorización de administrador principal, expiración/revocación y límites OTP.
- Verificar AES-GCM, rotación de claves y búsqueda HMAC; confirmar que ningún log incluye datos en claro.
- Probar append-only, concurrencia de la cadena, raíces Merkle y verificaciones negativas.
- Revisar proyección contra reidentificación y resultados en poblaciones pequeñas.
- Validar carga desde Excel, duplicados, cambios, bajas y compatibilidad con cuentas de etapa 1.
- Realizar pruebas de navegador responsive y de app Android; la app empaqueta assets locales.
- Configurar proveedor de correo/SMS, claves de cifrado/HMAC, retención, protocolos y consentimientos antes de aceptar datos.

La aprobación de una solicitud registra el vínculo validado, pero no reemplaza la etapa posterior de habilitar una sesión individual de Comunidad Formativa. No se deben usar datos reales de menores para la prueba técnica; se debe usar una solicitud ficticia y borrarla por el flujo administrativo de retención cuando corresponda. La implementación debe acompañarse con aviso de privacidad, reglas de retención y revisión jurídica específica bajo Ley 25.326 y Ley 26.061.

