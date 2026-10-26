# Asistente de Instagram y Facebook

Asistente para comentarios orgánicos, anuncios pagos de Instagram, mensajes
privados de Instagram y comentarios de Facebook de Talleres Club Abierto.

## Estado actual

- Recibe webhooks firmados por Meta.
- Clasifica comentarios y mensajes privados.
- Genera respuestas con el tono de la propuesta.
- Publica automáticamente solo las categorías seguras habilitadas.
- Separa casos sensibles para atención humana.
- Conserva una auditoría de cada borrador generado.

## Categorías iniciales

| Categoría | Acción inicial |
|---|---|
| Apoyo y colaboración | Respuesta cálida automática |
| Presentación profesional | Orientación automática al Banco de Profesionales |
| Pregunta genuina | Borrador técnico para revisar |
| Confusión sobre identidad | Aclaración institucional |
| Crítica constructiva | Respuesta firme para revisar |
| Chicana rival | Respuesta picante medida para revisar |
| Agresión o spam | Ocultar o ignorar, sin respuesta automática |
| Política, acusaciones, prensa y menores | Atención humana obligatoria |

## Secretos requeridos

La función `instagram-asistente-webhook` necesita estos secretos de Supabase:

- `META_APP_SECRET`
- `META_WEBHOOK_VERIFY_TOKEN`
- `META_INSTAGRAM_ACCESS_TOKEN`
- `META_FACEBOOK_ACCESS_TOKEN`
- `META_PAGE_ACCESS_TOKEN` (para comentarios de la página de Facebook)

## Respuestas automáticas seguras

El modo `respuestas_seguras` puede publicar automáticamente solo estas categorías:

- apoyo;
- colaboración;
- confusión de identidad;
- chicana rival con tono futbolero medido.

Las presentaciones profesionales —por ejemplo, “soy licenciado en logística”,
“trabajo en finanzas” o “tengo experiencia en sistemas”— se tratan como colaboración.
La respuesta aclara que todavía no hay mesas de trabajo y orienta al Banco de
Profesionales para cargar el CV, consultar perfiles por área y solicitar acceso a un
CV específico con autorización de su titular.

Denuncias o acusaciones, prensa, asuntos de menores, agresiones y preguntas genuinas
permanecen bajo revisión humana. El reclamo atómico previo al envío y la clave única del
evento evitan respuestas duplicadas cuando Meta reintenta un webhook.

## Privacidad

Los datos se guardan en el esquema privado `instagram_asistente`, inaccesible para `anon` y `authenticated`. La retención predeterminada es de 90 días y puede reducirse. Los ejemplos históricos se cargan anonimizados, sin nombres de usuario ni fotografías.
