-- Puentes PostgREST para la Edge Function de OTP.
-- La lógica y los datos permanecen en el esquema privado comunidad_formativa.
-- Solo service_role puede ejecutar estos wrappers.

create or replace function public.community_formative_issue_email_otp(
  p_email_hmac text,
  p_code_hmac text,
  p_email_cifrado bytea,
  p_nonce bytea,
  p_version_clave smallint,
  p_ip_hmac text
)
returns uuid
language sql
security definer
set search_path = pg_catalog
as $$
  select comunidad_formativa.emitir_desafio_email_otp(
    p_email_hmac, p_code_hmac, p_email_cifrado, p_nonce, p_version_clave, p_ip_hmac
  );
$$;

create or replace function public.community_formative_verify_email_otp(
  p_id uuid,
  p_codigo_hmac text
)
returns boolean
language sql
security definer
set search_path = pg_catalog
as $$
  select comunidad_formativa.verificar_desafio_email_otp(p_id, p_codigo_hmac);
$$;

create or replace function public.community_formative_revoke_email_otp(p_id uuid)
returns void
language sql
security definer
set search_path = pg_catalog
as $$
  select comunidad_formativa.invalidar_desafio_email_otp(p_id);
$$;

revoke all on function public.community_formative_issue_email_otp(text,text,bytea,bytea,smallint,text)
  from public, anon, authenticated;
revoke all on function public.community_formative_verify_email_otp(uuid,text)
  from public, anon, authenticated;
revoke all on function public.community_formative_revoke_email_otp(uuid)
  from public, anon, authenticated;
grant execute on function public.community_formative_issue_email_otp(text,text,bytea,bytea,smallint,text)
  to service_role;
grant execute on function public.community_formative_verify_email_otp(uuid,text)
  to service_role;
grant execute on function public.community_formative_revoke_email_otp(uuid)
  to service_role;
