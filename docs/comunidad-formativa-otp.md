# Solicitud de acceso — Comunidad Formativa

## Estado

El desafío de correo y las acciones `otp_request` / `otp_verify` están desplegados en `comunidad-formativa-api`. Después de verificar el correo, la persona adulta puede enviar una solicitud de acceso. La solicitud exige DNI del adulto y del jugador, junto con los datos necesarios para revisar el vínculo; no crea acceso hasta la validación administrativa.

La verificación confirma únicamente que la persona controla esa dirección. La pertenencia formativa sigue requiriendo una revisión administrativa independiente. Para menores de 16 años, la futura cuenta principal debe corresponder a madre, padre o tutor. Los DNI se cifran con AES-GCM en el servidor antes de persistirse; solo el administrador principal puede consultar identidad, con motivo obligatorio y registro append-only.

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

1. Consultar `GET /functions/v1/comunidad-formativa-api` y comprobar que las banderas de alta, casos y anclaje sigan en `false`.
2. Desde la tarjeta de verificación de la página, enviar `POST` JSON `{ "action": "otp_request", "email": "correo de prueba" }` y confirmar recepción, expiración y texto del correo.
3. Enviar `{ "action": "otp_verify", "challenge_id": "…", "code": "…" }`; comprobar éxito, un solo uso, expiración, cinco fallos y límites por destino/origen.
4. Enviar `intake_submit` con datos ficticios y ambos DNI sintéticos de 7 u 8 dígitos; comprobar que la solicitud queda pendiente y que el mismo desafío OTP no se puede reutilizar.
5. Abrir `comunidad-formativa-admin.html` desde el panel administrador, consultar la identidad con motivo y confirmación, y comprobar que la decisión queda registrada.
6. Consultar tablas solo desde `service_role` y confirmar que los datos de persona, DNI y motivo no quedan en claro. Repetir intentos de lectura directa con `anon` y `authenticated`; deben fallar.

No usar datos reales de menores para pruebas. La solicitud requiere aceptación expresa del consentimiento y verificación administrativa. La habilitación de sesión individual y el acceso a los módulos de perfil y casos son integraciones posteriores; el OTP de correo no equivale a una cuenta activa.
