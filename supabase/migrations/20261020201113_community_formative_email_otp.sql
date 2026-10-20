-- OTP de correo aislado para Comunidad Formativa. No crea cuentas ni valida pertenencia.
-- El correo queda cifrado en aplicación y esta tabla no es accesible por clientes.

create table comunidad_formativa.desafios_email_otp (
  id uuid primary key default gen_random_uuid(),
  email_cifrado bytea not null check (octet_length(email_cifrado) between 17 and 512),
  nonce bytea not null check (octet_length(nonce) = 12),
  version_clave smallint not null check (version_clave = 1),
  email_hmac text not null check (email_hmac ~ '^[0-9a-f]{64}$'),
  codigo_hmac text not null check (codigo_hmac ~ '^[0-9a-f]{64}$'),
  ip_hmac text not null check (ip_hmac ~ '^[0-9a-f]{64}$'),
  intentos smallint not null default 0 check (intentos between 0 and 5),
  creado_en timestamptz not null default now(),
  vence_en timestamptz not null default (now() + interval '5 minutes'),
  verificado_en timestamptz,
  invalidado_en timestamptz,
  check (vence_en <= creado_en + interval '5 minutes')
);

create index desafios_email_otp_email_creado_idx
  on comunidad_formativa.desafios_email_otp (email_hmac, creado_en desc);
create index desafios_email_otp_ip_creado_idx
  on comunidad_formativa.desafios_email_otp (ip_hmac, creado_en desc);

alter table comunidad_formativa.desafios_email_otp enable row level security;
alter table comunidad_formativa.desafios_email_otp force row level security;
revoke all on comunidad_formativa.desafios_email_otp from public, anon, authenticated;
grant all on comunidad_formativa.desafios_email_otp to service_role;

create or replace function comunidad_formativa.emitir_desafio_email_otp(
  p_email_hmac text,
  p_codigo_hmac text,
  p_email_cifrado bytea,
  p_nonce bytea,
  p_version_clave smallint,
  p_ip_hmac text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  v_id uuid;
  v_now timestamptz := clock_timestamp();
begin
  if p_email_hmac !~ '^[0-9a-f]{64}$'
     or p_codigo_hmac !~ '^[0-9a-f]{64}$'
     or p_ip_hmac !~ '^[0-9a-f]{64}$'
     or octet_length(p_nonce) <> 12
     or octet_length(p_email_cifrado) < 17
     or octet_length(p_email_cifrado) > 512
     or p_version_clave <> 1 then
    raise exception 'invalid otp challenge payload' using errcode = '22023';
  end if;

  -- Serializa por destino y origen para que el límite sea correcto bajo concurrencia.
  perform pg_advisory_xact_lock(hashtextextended(p_email_hmac, 74021));
  perform pg_advisory_xact_lock(hashtextextended(p_ip_hmac, 74022));

  if exists (
    select 1 from comunidad_formativa.desafios_email_otp d
    where d.email_hmac = p_email_hmac
      and d.creado_en > v_now - interval '60 seconds'
  ) or (
    select count(*) from comunidad_formativa.desafios_email_otp d
    where d.email_hmac = p_email_hmac
      and d.creado_en > v_now - interval '1 hour'
  ) >= 3 or (
    select count(*) from comunidad_formativa.desafios_email_otp d
    where d.ip_hmac = p_ip_hmac
      and d.creado_en > v_now - interval '1 hour'
  ) >= 15 then
    return null;
  end if;

  insert into comunidad_formativa.desafios_email_otp (
    email_cifrado, nonce, version_clave, email_hmac, codigo_hmac, ip_hmac,
    creado_en, vence_en
  ) values (
    p_email_cifrado, p_nonce, p_version_clave, p_email_hmac, p_codigo_hmac,
    p_ip_hmac, v_now, v_now + interval '5 minutes'
  ) returning id into v_id;
  return v_id;
end;
$$;

create or replace function comunidad_formativa.verificar_desafio_email_otp(
  p_id uuid,
  p_codigo_hmac text
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  v_row comunidad_formativa.desafios_email_otp%rowtype;
  v_now timestamptz := clock_timestamp();
begin
  if p_codigo_hmac !~ '^[0-9a-f]{64}$' then
    return false;
  end if;
  select * into v_row
    from comunidad_formativa.desafios_email_otp d
    where d.id = p_id
    for update;
  if not found or v_row.vence_en <= v_now or v_row.verificado_en is not null
     or v_row.invalidado_en is not null or v_row.intentos >= 5 then
    return false;
  end if;

  if v_row.codigo_hmac = p_codigo_hmac then
    update comunidad_formativa.desafios_email_otp
       set verificado_en = v_now, intentos = intentos + 1
     where id = p_id;
    return true;
  end if;

  update comunidad_formativa.desafios_email_otp
     set intentos = intentos + 1,
         invalidado_en = case when intentos + 1 >= 5 then v_now else invalidado_en end
   where id = p_id;
  return false;
end;
$$;

create or replace function comunidad_formativa.invalidar_desafio_email_otp(p_id uuid)
returns void
language sql
security definer
set search_path = pg_catalog
as $$
  update comunidad_formativa.desafios_email_otp
     set invalidado_en = clock_timestamp()
   where id = p_id and verificado_en is null and invalidado_en is null
$$;

revoke all on function comunidad_formativa.emitir_desafio_email_otp(text,text,bytea,bytea,smallint,text)
  from public, anon, authenticated;
revoke all on function comunidad_formativa.verificar_desafio_email_otp(uuid,text)
  from public, anon, authenticated;
revoke all on function comunidad_formativa.invalidar_desafio_email_otp(uuid)
  from public, anon, authenticated;
grant execute on function comunidad_formativa.emitir_desafio_email_otp(text,text,bytea,bytea,smallint,text)
  to service_role;
grant execute on function comunidad_formativa.verificar_desafio_email_otp(uuid,text)
  to service_role;
grant execute on function comunidad_formativa.invalidar_desafio_email_otp(uuid)
  to service_role;

comment on table comunidad_formativa.desafios_email_otp is
  'Desafíos OTP de corta duración; verifica únicamente control del correo y no habilita acceso ni valida pertenencia formativa.';
