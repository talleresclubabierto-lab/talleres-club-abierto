# OTP de correo — Comunidad Formativa

## Estado

El desafío de correo y las acciones `otp_request` / `otp_verify` están desplegados en `comunidad-formativa-api`. El endpoint sigue cerrado hasta cargar secretos de correo y cifrado. No hay cuentas, formularios de alta ni padrón que queden habilitados al verificar un correo.

La verificación confirma únicamente que la persona controla esa dirección. La pertenencia formativa sigue requiriendo una revisión administrativa independiente. Para menores de 16 años, la futura cuenta principal debe corresponder a madre, padre o tutor.

## Secretos requeridos en Supabase

Configurar en **Project Settings → Edge Functions → Secrets** (o el panel de secretos de Edge Functions):

| Secreto | Contenido |
|---|---|
| `RESEND_API_KEY` | Clave privada del proveedor Resend |
| `CF_EMAIL_FROM` | Remitente validado en Resend, por ejemplo `Comunidad Formativa <acceso@auth.talleresclubabierto.com>` |
| `CF_DATA_ENCRYPTION_KEY_V1` | Clave aleatoria de 32 bytes codificada en Base64 para AES-256-GCM |
| `CF_LOOKUP_HMAC_KEY_V1` | Clave aleatoria independiente de 32 bytes, codificada en Base64, para HMAC-SHA-256 |

Generar cada clave criptográfica por separado con un generador seguro, por ejemplo `openssl rand -base64 32`. No reutilizar claves entre cifrado y HMAC, no subirlas al repositorio y guardarlas en un gestor seguro. Para rotar, mantener la clave anterior disponible hasta migrar los registros compatibles y aumentar la versión de clave en una migración controlada.

El remitente debe pertenecer a un dominio verificado por el proveedor. No enviar las claves por chat, correo ni issues. La Edge Function lee las claves desde secretos; el código, la base y el navegador nunca las reciben.

## Controles del flujo

- OTP numérico de seis dígitos, vence a los cinco minutos y se acepta una sola vez.
- Máximo cinco intentos por desafío; tres envíos por correo por hora, con espera de un minuto, y límite por IP pseudonimizada mediante HMAC.
- Código e identificadores de correo/origen se guardan como HMAC. La dirección se cifra con AES-GCM antes de persistirla.
- El cuerpo del mensaje aclara que el código no habilita una cuenta ni confirma pertenencia.
- Respuestas no enumeran registros; no se escriben email, OTP ni contenido del mensaje en logs.
- RLS está habilitada y forzada. `anon` y `authenticated` carecen de permisos de tabla y ejecución de RPC; solo `service_role` puede operar en el esquema privado.
- El sistema actual de sesiones de socios, sus hashes, lotes y anclajes no interviene.

## Verificación después de configurar secretos

1. Consultar `GET /functions/v1/comunidad-formativa-api` y comprobar `otp_email_ready: true`; las banderas de alta/casos deben seguir en `false` hasta completar el flujo institucional.
2. Enviar `POST` JSON `{ "action": "otp_request", "email": "correo de prueba" }` desde el dominio oficial y confirmar la recepción, expiración y texto del correo.
3. Enviar `{ "action": "otp_verify", "challenge_id": "…", "code": "…" }`; comprobar éxito, un solo uso, expiración, cinco fallos y límites por destino/origen.
4. Consultar la tabla de desafíos solo desde el rol de servicio y confirmar que no contiene correo ni código en claro.
5. Repetir consultas con roles `anon` y `authenticated`; deben fallar.

No usar datos reales de menores para pruebas. El sitio no debe presentar el OTP como acceso a un panel ni permitir alta hasta implementar consentimiento, solicitud cifrada, revisión administrativa, sesión individual, recuperación y protocolo de protección.
