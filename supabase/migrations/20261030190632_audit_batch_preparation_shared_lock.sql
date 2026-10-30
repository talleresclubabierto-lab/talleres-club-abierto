-- Serialize Merkle audit preparation with the existing audit-chain writer.
-- Prepared from live definitions on 2026-10-30. Apply in one transaction.
-- Only one early transaction advisory lock is added to each of three functions.
-- Policy, cron, integration activation, worker, network sends and stored batches are unchanged.
set local lock_timeout='5s';
set local statement_timeout='60s';

do $batching_baseline$
declare
  v_expected record;
  v_function record;
begin
  for v_expected in select * from (values
      ('public.preparar_lote_ordinario_si_corresponde()','71de4c61c1ba184b814e5a325c65a7c2'),
      ('public.preparar_lote_extraordinario_auditoria(text,text)','19d580e3c2778e01483eace0a9b9f138'),
      ('public.preparar_lote_merkle_auditoria(text,text,bigint,bigint,integer,text,jsonb)','12d2be09efbeb33de9dff6fb3782a6ed')
    ) as expected(signature,definition_md5)
  loop
    select p.*,pg_catalog.pg_get_userbyid(p.proowner) as owner_name
      into v_function from pg_catalog.pg_proc p
      where p.oid=pg_catalog.to_regprocedure(v_expected.signature);
    if not found or pg_catalog.md5(pg_catalog.pg_get_functiondef(v_function.oid)) is distinct from v_expected.definition_md5 then
      raise exception 'Unexpected definition for %; stop and review the live version',v_expected.signature;
    end if;
    if v_function.owner_name is distinct from 'postgres'
      or v_function.proacl::text is distinct from '{postgres=X/postgres,service_role=X/postgres}'
      or v_function.proconfig is distinct from array['search_path=public, extensions']
      or v_function.prosecdef is distinct from true
      or v_function.provolatile is distinct from 'v' then
      raise exception 'Owner, grants or execution settings differ for %',v_expected.signature;
    end if;
  end loop;
end;
$batching_baseline$;

CREATE OR REPLACE FUNCTION public.preparar_lote_ordinario_si_corresponde()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  v_policy public.politicas_anclaje_integridad%rowtype;
  v_ultimo_cubierto bigint;
  v_max_evento bigint;
  v_pendientes integer;
  v_ultimo_lote_tiempo timestamptz;
  v_hora_cumplida boolean := false;
  v_cantidad_cumplida boolean := false;
  v_hasta bigint;
  v_desde bigint;
  v_ref text;
  v_id uuid;
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('talleres_digital_auditoria_chain'));
  select * into v_policy from public.obtener_ultima_politica_anclaje_vigente();
  if not found then
    return null;
  end if;

  v_ultimo_cubierto := public.ultimo_evento_cubierto_por_lote_auditoria();
  select coalesce(max(id),0) into v_max_evento from public.auditoria_administrativa;
  if v_max_evento <= v_ultimo_cubierto then
    return null;
  end if;

  select count(*)::integer
  into v_pendientes
  from public.auditoria_administrativa
  where id > v_ultimo_cubierto and id <= v_max_evento;

  v_cantidad_cumplida := v_pendientes >= v_policy.movimientos_por_anclaje;

  select max(preparado_en) into v_ultimo_lote_tiempo
  from public.lotes_merkle_auditoria;

  if v_policy.max_horas_sin_anclaje is not null then
    v_hora_cumplida := coalesce(v_ultimo_lote_tiempo,'-infinity'::timestamptz)
      <= now() - make_interval(hours => v_policy.max_horas_sin_anclaje);
  end if;

  if not (v_cantidad_cumplida or v_hora_cumplida) then
    return null;
  end if;

  select min(id) into v_desde
  from public.auditoria_administrativa
  where id > v_ultimo_cubierto;

  if v_cantidad_cumplida then
    select max(id) into v_hasta
    from (
      select id
      from public.auditoria_administrativa
      where id > v_ultimo_cubierto
      order by id
      limit v_policy.movimientos_por_anclaje
    ) q;
  else
    v_hasta := v_max_evento;
  end if;

  v_ref := format('audit-auto-v%s-%s-%s',v_policy.version,v_desde,v_hasta);

  if exists(select 1 from public.lotes_merkle_auditoria where referencia=v_ref) then
    select id into v_id from public.lotes_merkle_auditoria where referencia=v_ref;
    return v_id;
  end if;

  v_id := public.preparar_lote_merkle_auditoria(
    v_ref,'ordinario',v_desde,v_hasta,v_policy.version,null,
    jsonb_build_object(
      'disparador',case when v_cantidad_cumplida then 'cantidad_movimientos' else 'tiempo_maximo' end,
      'movimientos_objetivo',v_policy.movimientos_por_anclaje,
      'max_horas_sin_anclaje',v_policy.max_horas_sin_anclaje,
      'pendientes_al_evaluar',v_pendientes
    )
  );
  return v_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.preparar_lote_extraordinario_auditoria(p_causa_codigo text, p_descripcion text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  v_policy public.politicas_anclaje_integridad%rowtype;
  v_causa jsonb;
  v_ultimo_cubierto bigint;
  v_max_evento bigint;
  v_desde bigint;
  v_ref text;
  v_id uuid;
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('talleres_digital_auditoria_chain'));
  select * into v_policy from public.obtener_ultima_politica_anclaje_vigente();
  if not found then return null; end if;

  select elem into v_causa
  from jsonb_array_elements(v_policy.causas_extraordinarias) elem
  where elem->>'codigo'=p_causa_codigo
  limit 1;

  if v_causa is null then
    raise exception 'La causa extraordinaria % no existe en la política vigente',p_causa_codigo;
  end if;
  if not coalesce((v_causa->>'habilitada')::boolean,false) then
    raise exception 'La causa extraordinaria % está deshabilitada',p_causa_codigo;
  end if;

  v_ultimo_cubierto := public.ultimo_evento_cubierto_por_lote_auditoria();
  select coalesce(max(id),0) into v_max_evento from public.auditoria_administrativa;
  if v_max_evento <= v_ultimo_cubierto then return null; end if;

  select min(id) into v_desde
  from public.auditoria_administrativa
  where id > v_ultimo_cubierto;

  v_ref := format(
    'audit-extra-v%s-%s-%s-%s',
    v_policy.version,lower(p_causa_codigo),v_desde,v_max_evento
  );

  if exists(select 1 from public.lotes_merkle_auditoria where referencia=v_ref) then
    select id into v_id from public.lotes_merkle_auditoria where referencia=v_ref;
    return v_id;
  end if;

  v_id := public.preparar_lote_merkle_auditoria(
    v_ref,'extraordinario',v_desde,v_max_evento,v_policy.version,p_causa_codigo,
    jsonb_build_object('causa_nombre',v_causa->>'nombre','descripcion',p_descripcion)
  );
  return v_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.preparar_lote_merkle_auditoria(p_referencia text, p_tipo text, p_primer_evento_id bigint, p_ultimo_evento_id bigint, p_politica_version integer DEFAULT NULL::integer, p_causa_extraordinaria text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  v_hashes text[];
  v_cantidad integer;
  v_primero text;
  v_ultimo text;
  v_raiz text;
  v_id uuid;
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('talleres_digital_auditoria_chain'));
  if p_tipo not in ('genesis','ordinario','extraordinario') then
    raise exception 'Tipo de lote inválido';
  end if;
  if p_primer_evento_id is null or p_ultimo_evento_id is null or p_ultimo_evento_id < p_primer_evento_id then
    raise exception 'Rango de auditoría inválido';
  end if;

  select
    array_agg(a.event_hash order by a.id),
    count(*)::integer,
    (array_agg(a.event_hash order by a.id))[1],
    (array_agg(a.event_hash order by a.id desc))[1]
  into v_hashes,v_cantidad,v_primero,v_ultimo
  from public.auditoria_administrativa a
  where a.id between p_primer_evento_id and p_ultimo_evento_id;

  if coalesce(v_cantidad,0)=0 then
    raise exception 'El rango no contiene eventos';
  end if;

  v_raiz := public.merkle_root_sha256_sorted_pairs_v1(v_hashes);

  insert into public.lotes_merkle_auditoria(
    referencia,tipo,politica_version,causa_extraordinaria,
    primer_evento_id,ultimo_evento_id,cantidad_eventos,
    raiz_merkle_sha256,primer_event_hash,ultimo_event_hash,metadata
  )
  values(
    trim(p_referencia),p_tipo,p_politica_version,p_causa_extraordinaria,
    p_primer_evento_id,p_ultimo_evento_id,v_cantidad,
    v_raiz,v_primero,v_ultimo,coalesce(p_metadata,'{}'::jsonb)
  )
  returning id into v_id;

  perform public.registrar_auditoria_interna(
    'LOTE_MERKLE_AUDITORIA_PREPARADO',
    'lotes_merkle_auditoria',
    v_id::text,
    null,
    jsonb_build_object(
      'referencia',trim(p_referencia),
      'tipo',p_tipo,
      'primer_evento_id',p_primer_evento_id,
      'ultimo_evento_id',p_ultimo_evento_id,
      'cantidad_eventos',v_cantidad,
      'raiz_merkle_sha256',v_raiz,
      'algoritmo','sha256_sorted_pairs_v1',
      'politica_version',p_politica_version,
      'causa_extraordinaria',p_causa_extraordinaria
    ),
    null,
    jsonb_build_object('modulo','blockchain','fase','preparacion_merkle'),
    'sistema_blockchain'
  );

  return v_id;
end;
$function$
;

do $batching_verify$
declare
  v_expected record;
  v_function record;
begin
  for v_expected in select * from (values
      ('public.preparar_lote_ordinario_si_corresponde()','b7791464ed57716849063d73b163fb5b'),
      ('public.preparar_lote_extraordinario_auditoria(text,text)','90f57c42e929a58917b56080ad1b18de'),
      ('public.preparar_lote_merkle_auditoria(text,text,bigint,bigint,integer,text,jsonb)','9c772dc53fcc804eb2b0cfcd80e5c29e')
    ) as expected(signature,definition_md5)
  loop
    select p.*,pg_catalog.pg_get_userbyid(p.proowner) as owner_name
      into v_function from pg_catalog.pg_proc p
      where p.oid=pg_catalog.to_regprocedure(v_expected.signature);
    if not found or pg_catalog.md5(pg_catalog.pg_get_functiondef(v_function.oid)) is distinct from v_expected.definition_md5 then
      raise exception 'Unexpected definition for %; stop and review the live version',v_expected.signature;
    end if;
    if v_function.owner_name is distinct from 'postgres'
      or v_function.proacl::text is distinct from '{postgres=X/postgres,service_role=X/postgres}'
      or v_function.proconfig is distinct from array['search_path=public, extensions']
      or v_function.prosecdef is distinct from true
      or v_function.provolatile is distinct from 'v' then
      raise exception 'Owner, grants or execution settings differ for %',v_expected.signature;
    end if;
  end loop;
end;
$batching_verify$;
