-- Hash the sport/season classification as a separate append-only event after its private row is created.
create or replace function comunidad_formativa.registrar_evento_criptografico_clasificacion()
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
begin
  select c.codigo into v_codigo
    from comunidad_formativa.casos c
   where c.id=new.caso_id;
  if v_codigo is null then raise exception 'community case not found for classification'; end if;

  perform pg_advisory_xact_lock(hashtextextended(v_codigo, 0));
  select e.evento_hash into v_prev_hash
    from comunidad_formativa.eventos_criptograficos e
   where e.codigo=v_codigo order by e.id desc limit 1;

  v_actor_ref_hash := encode(digest(convert_to('system:classification', 'UTF8'), 'sha256'), 'hex');
  v_contenido_hash := encode(digest(convert_to(to_jsonb(new)::text, 'UTF8'), 'sha256'), 'hex');
  v_event_hash := encode(digest(convert_to(concat_ws('|',
    v_codigo, 'clasificacion_registrada', 'sistema', v_actor_ref_hash,
    v_contenido_hash, coalesce(v_prev_hash, ''),
    to_char(v_created at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
  ), 'UTF8'), 'sha256'), 'hex');

  insert into comunidad_formativa.eventos_criptograficos
    (codigo,tipo,actor_rol,actor_ref,contenido_hash,prev_hash,evento_hash,creado_en)
  values
    (v_codigo,'clasificacion_registrada','sistema',v_actor_ref_hash,v_contenido_hash,v_prev_hash,v_event_hash,v_created)
  returning id into v_event_id;

  insert into comunidad_formativa.lotes_merkle
    (referencia,primer_evento_id,ultimo_evento_id,cantidad,raiz_sha256,algoritmo,estado)
  values
    ('CF:' || v_codigo || ':' || v_event_id::text,v_event_id,v_event_id,1,
     public.merkle_root_sha256_sorted_pairs_v1(array[v_event_hash]),
     'sha256_sorted_pairs_v1','preparado');
  return new;
end;
$$;

drop trigger if exists casos_clasificacion_crypto_append on comunidad_formativa.casos_clasificacion;
create trigger casos_clasificacion_crypto_append
after insert on comunidad_formativa.casos_clasificacion
for each row execute function comunidad_formativa.registrar_evento_criptografico_clasificacion();
