-- Community Formative: append-only crypto event -> Merkle lot. No PII or report text is copied to these records.
alter table comunidad_formativa.lotes_merkle
  add column if not exists transaccion_hash text,
  add column if not exists red text,
  add column if not exists chain_id bigint,
  add column if not exists contrato text,
  add column if not exists bloque bigint;

create or replace function comunidad_formativa.registrar_evento_criptografico_actuacion()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  v_codigo text;
  v_actor_ref_hash text;
  v_contenido_hash text;
  v_prev_hash text;
  v_event_hash text;
  v_event_id bigint;
  v_created timestamptz := clock_timestamp();
  v_ref text;
begin
  select c.codigo into v_codigo
    from comunidad_formativa.casos c
   where c.id = new.caso_id;
  if v_codigo is null then
    raise exception 'community case not found for crypto event';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_codigo, 0));

  select e.evento_hash into v_prev_hash
    from comunidad_formativa.eventos_criptograficos e
   where e.codigo = v_codigo
   order by e.id desc
   limit 1;

  v_actor_ref_hash := encode(digest(convert_to(new.actor_ref, 'UTF8'), 'sha256'), 'hex');
  v_contenido_hash := encode(digest(new.detalle_cifrado || new.nonce || convert_to(new.version_clave::text, 'UTF8'), 'sha256'), 'hex');
  v_event_hash := encode(digest(convert_to(concat_ws('|',
    v_codigo, new.tipo, new.actor_rol, v_actor_ref_hash, v_contenido_hash,
    coalesce(v_prev_hash, ''), to_char(v_created at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
  ), 'UTF8'), 'sha256'), 'hex');

  insert into comunidad_formativa.eventos_criptograficos
    (codigo, tipo, actor_rol, actor_ref, contenido_hash, prev_hash, evento_hash, creado_en)
  values
    (v_codigo, new.tipo, new.actor_rol, v_actor_ref_hash, v_contenido_hash, v_prev_hash, v_event_hash, v_created)
  returning id into v_event_id;

  v_ref := 'CF:' || v_codigo || ':' || v_event_id::text;
  insert into comunidad_formativa.lotes_merkle
    (referencia, primer_evento_id, ultimo_evento_id, cantidad, raiz_sha256, algoritmo, estado)
  values
    (v_ref, v_event_id, v_event_id, 1, public.merkle_root_sha256_sorted_pairs_v1(array[v_event_hash]), 'sha256_sorted_pairs_v1', 'preparado');

  return new;
end;
$$;

drop trigger if exists actuaciones_crypto_append on comunidad_formativa.actuaciones;
create trigger actuaciones_crypto_append
after insert on comunidad_formativa.actuaciones
for each row execute function comunidad_formativa.registrar_evento_criptografico_actuacion();

create or replace function comunidad_formativa.estado_criptografico_caso(p_codigo text)
returns text
language plpgsql
stable
security definer
set search_path = pg_catalog
as $$
declare v text;
begin
  if exists (
    select 1 from comunidad_formativa.lotes_merkle l
    join comunidad_formativa.anclajes a on a.lote_id = l.id
    where l.referencia like 'CF:' || p_codigo || ':%'
  ) then
    return 'Hash y lote Merkle verificados en blockchain';
  end if;
  if exists (select 1 from comunidad_formativa.lotes_merkle l where l.referencia like 'CF:' || p_codigo || ':%' and l.estado='preparado') then
    return 'Hash y lote Merkle preparados; blockchain pendiente de activación institucional';
  end if;
  if exists (select 1 from comunidad_formativa.eventos_criptograficos e where e.codigo=p_codigo) then
    return 'Hash registrado';
  end if;
  return 'Pendiente de registro criptográfico';
end;
$$;
revoke all on function comunidad_formativa.estado_criptografico_caso(text) from public, anon, authenticated;
grant execute on function comunidad_formativa.estado_criptografico_caso(text) to service_role;

create or replace function public.community_formative_case_crypto_status(p_code text)
returns text
language sql
security definer
set search_path = pg_catalog
as $$
  select comunidad_formativa.estado_criptografico_caso(p_code)
$$;
revoke all on function public.community_formative_case_crypto_status(text) from public, anon, authenticated;
grant execute on function public.community_formative_case_crypto_status(text) to service_role;

create or replace function public.community_formative_list_member_cases(p_token text)
returns table(codigo text, periodo text, categoria_general text, estado text, registro_criptografico text)
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare v_actor bigint;
begin
  v_actor := public.validar_sesion_segura_interno(coalesce(p_token,''));
  if v_actor is null or not exists(select 1 from public.socios s where s.numero_socio=v_actor and s.habilitado) then
    raise exception 'active member session required' using errcode='42501';
  end if;
  return query
  select c.codigo,
         to_char(date_trunc('month',c.creada_en),'YYYY-MM')::text,
         case
           when c.categoria in ('maltrato_discriminacion','posible_represalia','salud_proteccion') then 'Convivencia y protección'
           when c.categoria in ('posible_ventaja_indebida','posible_intervencion_irregular','posible_conflicto_intereses','criterio_deportivo') then 'Integridad deportiva'
           when c.categoria in ('transporte','entrenamiento','alimentacion','infraestructura','educacion_acompanamiento') then 'Acompañamiento formativo'
           else 'Consulta o sugerencia'
         end,
         case c.estado when 'en_evaluacion' then 'En evaluación'
              when 'informacion_solicitada' then 'Información solicitada'
              when 'en_investigacion' then 'En investigación'
              when 'resuelta' then 'Resuelta' when 'archivada' then 'Archivada'
              when 'reabierta' then 'Reabierta' else 'Recibida' end,
         comunidad_formativa.estado_criptografico_caso(c.codigo)
    from comunidad_formativa.casos c
   order by c.creada_en desc;
end;
$$;
revoke all on function public.community_formative_list_member_cases(text) from public, anon, authenticated;
grant execute on function public.community_formative_list_member_cases(text) to service_role;

create or replace function public.community_formative_list_family_cases(p_token_hmac text)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog'
as $$
declare
  v_request_id uuid;
  v_cases jsonb;
begin
  select se.solicitud_id into v_request_id
    from comunidad_formativa.sesiones se
    join comunidad_formativa.solicitudes_acceso s on s.id = se.solicitud_id
   where se.token_hmac = p_token_hmac
     and se.cuenta_id is null
     and se.revocada_en is null
     and se.vence_en > clock_timestamp()
     and s.estado = 'aprobada'
     and s.estado_vinculo = 'validado';
  if v_request_id is null then
    raise exception 'family session required' using errcode = '42501';
  end if;
  update comunidad_formativa.sesiones set ultimo_uso_en = clock_timestamp() where token_hmac = p_token_hmac;
  select coalesce(jsonb_agg(jsonb_build_object(
    'codigo', c.codigo,
    'categoria', c.categoria,
    'estado', c.estado,
    'creada_en', c.creada_en,
    'registro_criptografico', comunidad_formativa.estado_criptografico_caso(c.codigo)
  ) order by c.creada_en desc), '[]'::jsonb)
    into v_cases
    from comunidad_formativa.casos c
   where c.solicitud_presentante_id = v_request_id;
  return v_cases;
end;
$$;
revoke all on function public.community_formative_list_family_cases(text) from public, anon, authenticated;
grant execute on function public.community_formative_list_family_cases(text) to service_role;
