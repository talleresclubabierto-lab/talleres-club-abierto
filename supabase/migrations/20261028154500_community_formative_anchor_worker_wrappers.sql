-- Service-only wrappers let the anchor worker access the private schema without exposing it through PostgREST.
create unique index if not exists comunidad_formativa_anclajes_lote_uidx
  on comunidad_formativa.anclajes(lote_id);

create or replace function public.community_formative_anchor_prepared_batch()
returns jsonb
language sql
security definer
set search_path = pg_catalog
as $$
  select jsonb_build_object(
    'id',l.id,'referencia',l.referencia,'raiz_merkle_sha256',l.raiz_sha256,
    'cantidad',l.cantidad,'preparado_en',l.preparado_en
  )
  from comunidad_formativa.lotes_merkle l
  where l.estado='preparado'
  order by l.preparado_en asc
  limit 1
$$;

create or replace function public.community_formative_anchor_pending_batches()
returns jsonb
language sql
security definer
set search_path = pg_catalog
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',l.id,'referencia',l.referencia,'raiz_merkle_sha256',l.raiz_sha256,
    'cantidad',l.cantidad,'transaccion_hash',l.transaccion_hash,'estado',l.estado
  )), '[]'::jsonb)
  from comunidad_formativa.lotes_merkle l
  where l.estado='enviado'
$$;

create or replace function public.community_formative_anchor_claim(p_id uuid)
returns boolean
language sql
security definer
set search_path = pg_catalog
as $$
  with claimed as (
    update comunidad_formativa.lotes_merkle
       set estado='enviado'
     where id=p_id and estado='preparado'
     returning 1
  )
  select exists(select 1 from claimed)
$$;

create or replace function public.community_formative_anchor_record_tx(
  p_id uuid,p_tx_hash text,p_red text,p_chain_id bigint,p_contrato text
)
returns boolean
language sql
security definer
set search_path = pg_catalog
as $$
  with updated as (
    update comunidad_formativa.lotes_merkle
       set transaccion_hash=p_tx_hash,red=p_red,chain_id=p_chain_id,contrato=p_contrato
     where id=p_id and estado='enviado' and transaccion_hash is null
     returning 1
  )
  select exists(select 1 from updated)
$$;

create or replace function public.community_formative_anchor_confirm(
  p_id uuid,p_tx_hash text,p_red text,p_chain_id bigint,p_contrato text,p_bloque bigint
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare v_ref text;
begin
  update comunidad_formativa.lotes_merkle
     set estado='confirmado',bloque=p_bloque
   where id=p_id and estado='enviado' and transaccion_hash=p_tx_hash
  returning referencia into v_ref;
  if v_ref is null then return false; end if;
  insert into comunidad_formativa.anclajes
    (lote_id,red,chain_id,contrato,transaccion_hash,bloque,confirmado_en)
  values (p_id,p_red,p_chain_id,p_contrato,p_tx_hash,p_bloque,clock_timestamp())
  on conflict (lote_id) do update set
    red=excluded.red,chain_id=excluded.chain_id,contrato=excluded.contrato,
    transaccion_hash=excluded.transaccion_hash,bloque=excluded.bloque,confirmado_en=excluded.confirmado_en;
  return true;
end;
$$;

revoke all on function public.community_formative_anchor_prepared_batch() from public,anon,authenticated;
revoke all on function public.community_formative_anchor_pending_batches() from public,anon,authenticated;
revoke all on function public.community_formative_anchor_claim(uuid) from public,anon,authenticated;
revoke all on function public.community_formative_anchor_record_tx(uuid,text,text,bigint,text) from public,anon,authenticated;
revoke all on function public.community_formative_anchor_confirm(uuid,text,text,bigint,text,bigint) from public,anon,authenticated;
grant execute on function public.community_formative_anchor_prepared_batch() to service_role;
grant execute on function public.community_formative_anchor_pending_batches() to service_role;
grant execute on function public.community_formative_anchor_claim(uuid) to service_role;
grant execute on function public.community_formative_anchor_record_tx(uuid,text,text,bigint,text) to service_role;
grant execute on function public.community_formative_anchor_confirm(uuid,text,text,bigint,text,bigint) to service_role;
