-- Bind each crypto event to the encrypted report and approximate date, never to plaintext identity or narrative.
create or replace function comunidad_formativa.registrar_evento_criptografico_actuacion()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  v_codigo text;
  v_categoria text;
  v_report bytea;
  v_report_nonce bytea;
  v_date bytea;
  v_date_nonce bytea;
  v_actor_ref_hash text;
  v_contenido_hash text;
  v_prev_hash text;
  v_event_hash text;
  v_event_id bigint;
  v_created timestamptz := clock_timestamp();
  v_ref text;
begin
  select c.codigo,c.categoria,c.relato_cifrado,c.nonce,c.fecha_aproximada_cifrada,c.fecha_aproximada_nonce
    into v_codigo,v_categoria,v_report,v_report_nonce,v_date,v_date_nonce
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
  v_contenido_hash := encode(digest(
    coalesce(v_report, '\x'::bytea) ||
    coalesce(v_report_nonce, '\x'::bytea) ||
    coalesce(v_date, '\x'::bytea) ||
    coalesce(v_date_nonce, '\x'::bytea) ||
    new.detalle_cifrado || new.nonce ||
    convert_to(v_categoria, 'UTF8') ||
    convert_to(new.version_clave::text, 'UTF8'),
    'sha256'
  ), 'hex');
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
