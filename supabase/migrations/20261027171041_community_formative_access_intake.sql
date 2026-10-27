-- Solicitudes de acceso de Comunidad Formativa.
-- Los datos completos (incluidos DNI de adulto y jugador) llegan ya cifrados
-- desde la Edge Function. No se agregan DNI en claro a ninguna tabla.

alter table comunidad_formativa.desafios_email_otp
  add column if not exists solicitud_consumida_en timestamptz;

create unique index if not exists solicitudes_acceso_identificador_activo_uidx
  on comunidad_formativa.solicitudes_acceso (identificador_hmac)
  where identificador_hmac is not null and estado in ('pendiente','en_revision','aprobada');

create table if not exists comunidad_formativa.auditoria_solicitudes_acceso (
  id uuid primary key default gen_random_uuid(),
  solicitud_id uuid not null references comunidad_formativa.solicitudes_acceso(id),
  actor_socio_id bigint not null references public.socios(numero_socio),
  accion text not null check (accion in ('consulta_identidad','aprobacion','rechazo')),
  motivo_cifrado bytea not null,
  nonce bytea not null check (octet_length(nonce) = 12),
  version_clave smallint not null check (version_clave = 1),
  confirmada boolean not null check (confirmada),
  creada_en timestamptz not null default clock_timestamp()
);

alter table comunidad_formativa.auditoria_solicitudes_acceso enable row level security;
alter table comunidad_formativa.auditoria_solicitudes_acceso force row level security;
revoke all on comunidad_formativa.auditoria_solicitudes_acceso from public, anon, authenticated;
grant all on comunidad_formativa.auditoria_solicitudes_acceso to service_role;

drop trigger if exists auditoria_solicitudes_acceso_append_only
  on comunidad_formativa.auditoria_solicitudes_acceso;
create trigger auditoria_solicitudes_acceso_append_only
  before update or delete on comunidad_formativa.auditoria_solicitudes_acceso
  for each row execute function comunidad_formativa.bloquear_mutacion_append_only();

create or replace function public.community_formative_submit_access_request(
  p_otp_id uuid,
  p_email_hmac text,
  p_datos_cifrados bytea,
  p_nonce bytea,
  p_version_clave smallint,
  p_identificador_hmac text,
  p_codigo text,
  p_consentimiento_version text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  v_otp comunidad_formativa.desafios_email_otp%rowtype;
  v_id uuid;
  v_now timestamptz := clock_timestamp();
begin
  if p_otp_id is null
     or p_email_hmac !~ '^[0-9a-f]{64}$'
     or p_identificador_hmac !~ '^[0-9a-f]{64}$'
     or p_codigo !~ '^CF-[0-9]{4}-[A-Z2-7]{8}$'
     or p_version_clave <> 1
     or octet_length(p_nonce) <> 12
     or octet_length(p_datos_cifrados) < 17
     or octet_length(p_datos_cifrados) > 16384
     or p_consentimiento_version <> 'comunidad-formativa-alta-v1' then
    raise exception 'invalid application payload' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_identificador_hmac, 74131));
  select * into v_otp
    from comunidad_formativa.desafios_email_otp d
   where d.id = p_otp_id
   for update;

  if not found or v_otp.email_hmac <> p_email_hmac
     or v_otp.verificado_en is null or v_otp.verificado_en > v_now
     or v_otp.verificado_en < v_now - interval '30 minutes'
     or v_otp.invalidado_en is not null or v_otp.solicitud_consumida_en is not null then
    return jsonb_build_object('ok', false, 'reason', 'verification_required');
  end if;

  if exists (
    select 1 from comunidad_formativa.solicitudes_acceso s
     where s.identificador_hmac = p_identificador_hmac
       and s.estado in ('pendiente','en_revision','aprobada')
  ) then
    return jsonb_build_object('ok', false, 'reason', 'request_exists');
  end if;

  insert into comunidad_formativa.solicitudes_acceso (
    codigo, datos_cifrados, nonce, version_clave, identificador_hmac,
    estado, estado_vinculo, consentimiento_version, consentimiento_en
  ) values (
    p_codigo, p_datos_cifrados, p_nonce, p_version_clave, p_identificador_hmac,
    'pendiente', 'pendiente_validacion', p_consentimiento_version, v_now
  ) returning id into v_id;

  update comunidad_formativa.desafios_email_otp
     set solicitud_consumida_en = v_now
   where id = p_otp_id;

  return jsonb_build_object('ok', true, 'id', v_id, 'codigo', p_codigo, 'estado', 'pendiente');
end;
$$;

create or replace function public.community_formative_list_access_requests(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  v_actor bigint;
  v_rows jsonb;
begin
  v_actor := public.validar_sesion_segura_interno(coalesce(p_token, ''));
  if v_actor is null or not exists (
    select 1 from public.administradores a
     where a.numero_socio = v_actor and a.habilitado and a.es_principal
  ) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', s.id, 'codigo', s.codigo, 'estado', s.estado,
    'estado_vinculo', s.estado_vinculo, 'creada_en', s.creada_en
  ) order by s.creada_en desc), '[]'::jsonb)
    into v_rows
    from (
      select id, codigo, estado, estado_vinculo, creada_en
        from comunidad_formativa.solicitudes_acceso
       where estado in ('pendiente','en_revision')
       order by creada_en desc limit 100
    ) s;
  return jsonb_build_object('ok', true, 'solicitudes', v_rows);
end;
$$;

create or replace function public.community_formative_read_access_request(
  p_token text,
  p_solicitud_id uuid,
  p_motivo_cifrado bytea,
  p_nonce bytea,
  p_version_clave smallint,
  p_confirmada boolean
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  v_actor bigint;
  v_row comunidad_formativa.solicitudes_acceso%rowtype;
begin
  v_actor := public.validar_sesion_segura_interno(coalesce(p_token, ''));
  if v_actor is null or not exists (
    select 1 from public.administradores a
     where a.numero_socio = v_actor and a.habilitado and a.es_principal
  ) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_confirmada is distinct from true or octet_length(p_nonce) <> 12
     or p_version_clave <> 1 or octet_length(p_motivo_cifrado) < 17
     or octet_length(p_motivo_cifrado) > 2048 then
    raise exception 'identity access confirmation required' using errcode = '22023';
  end if;

  select * into v_row from comunidad_formativa.solicitudes_acceso s
   where s.id = p_solicitud_id for update;
  if not found then raise exception 'not found' using errcode = 'P0002'; end if;

  insert into comunidad_formativa.auditoria_solicitudes_acceso (
    solicitud_id, actor_socio_id, accion, motivo_cifrado, nonce, version_clave, confirmada
  ) values (
    v_row.id, v_actor, 'consulta_identidad', p_motivo_cifrado, p_nonce, p_version_clave, true
  );

  return jsonb_build_object(
    'ok', true, 'id', v_row.id, 'codigo', v_row.codigo, 'estado', v_row.estado,
    'datos_cifrados_b64', encode(v_row.datos_cifrados, 'base64'),
    'nonce_b64', encode(v_row.nonce, 'base64'), 'version_clave', v_row.version_clave
  );
end;
$$;

create or replace function public.community_formative_review_access_request(
  p_token text,
  p_solicitud_id uuid,
  p_decision text,
  p_motivo_cifrado bytea,
  p_nonce bytea,
  p_version_clave smallint,
  p_confirmada boolean
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  v_actor bigint;
  v_row comunidad_formativa.solicitudes_acceso%rowtype;
  v_new_estado text;
begin
  v_actor := public.validar_sesion_segura_interno(coalesce(p_token, ''));
  if v_actor is null or not exists (
    select 1 from public.administradores a
     where a.numero_socio = v_actor and a.habilitado and a.es_principal
  ) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_decision not in ('aprobar','rechazar')
     or p_confirmada is distinct from true or octet_length(p_nonce) <> 12
     or p_version_clave <> 1 or octet_length(p_motivo_cifrado) < 17
     or octet_length(p_motivo_cifrado) > 2048 then
    raise exception 'invalid review decision' using errcode = '22023';
  end if;

  select * into v_row from comunidad_formativa.solicitudes_acceso s
   where s.id = p_solicitud_id for update;
  if not found then raise exception 'not found' using errcode = 'P0002'; end if;
  if v_row.estado not in ('pendiente','en_revision') then
    raise exception 'request is no longer reviewable' using errcode = '55000';
  end if;

  v_new_estado := case when p_decision = 'aprobar' then 'aprobada' else 'rechazada' end;
  update comunidad_formativa.solicitudes_acceso
     set estado = v_new_estado,
         estado_vinculo = case when p_decision = 'aprobar' then 'validado' else 'no_validado' end,
         revisada_por = v_actor,
         revisada_en = clock_timestamp()
   where id = p_solicitud_id;

  insert into comunidad_formativa.auditoria_solicitudes_acceso (
    solicitud_id, actor_socio_id, accion, motivo_cifrado, nonce, version_clave, confirmada
  ) values (
    p_solicitud_id, v_actor,
    case when p_decision = 'aprobar' then 'aprobacion' else 'rechazo' end,
    p_motivo_cifrado, p_nonce, p_version_clave, true
  );

  return jsonb_build_object('ok', true, 'id', p_solicitud_id, 'estado', v_new_estado);
end;
$$;

revoke all on function public.community_formative_submit_access_request(uuid,text,bytea,bytea,smallint,text,text,text)
  from public, anon, authenticated;
revoke all on function public.community_formative_list_access_requests(text)
  from public, anon, authenticated;
revoke all on function public.community_formative_read_access_request(text,uuid,bytea,bytea,smallint,boolean)
  from public, anon, authenticated;
revoke all on function public.community_formative_review_access_request(text,uuid,text,bytea,bytea,smallint,boolean)
  from public, anon, authenticated;
grant execute on function public.community_formative_submit_access_request(uuid,text,bytea,bytea,smallint,text,text,text)
  to service_role;
grant execute on function public.community_formative_list_access_requests(text)
  to service_role;
grant execute on function public.community_formative_read_access_request(text,uuid,bytea,bytea,smallint,boolean)
  to service_role;
grant execute on function public.community_formative_review_access_request(text,uuid,text,bytea,bytea,smallint,boolean)
  to service_role;

comment on table comunidad_formativa.auditoria_solicitudes_acceso is
  'Registro append-only y cifrado de consultas de identidad y decisiones sobre solicitudes de acceso formativo.';

create or replace function public.community_formative_status()
returns jsonb
language sql
stable
security definer
set search_path = pg_catalog
as $$
  select jsonb_build_object(
    'module', 'comunidad_formativa',
    'phase', 'initial_intake_open',
    'intake_enabled', true,
    'case_submission_enabled', false,
    'blockchain_anchor_enabled', false
  );
$$;
revoke all on function public.community_formative_status() from public, anon, authenticated;
grant execute on function public.community_formative_status() to service_role;
