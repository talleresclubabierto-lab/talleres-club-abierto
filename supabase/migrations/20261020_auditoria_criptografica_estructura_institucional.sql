-- Auditoria institucional conectada a cadena SHA-256 y lotes Merkle.
-- Desplegada en Supabase el 20-10-2026.
create or replace function public.trg_auditar_estructura_institucional()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
declare v_old jsonb; v_new jsonb; v_id text; v_accion text;
begin
 if tg_op = 'INSERT' then
   v_old := null; v_new := to_jsonb(new); v_id := new.id::text; v_accion := 'ESTRUCTURA_INSTITUCIONAL_ALTA';
 elsif tg_op = 'UPDATE' then
   if to_jsonb(old) = to_jsonb(new) then return new; end if;
   v_old := to_jsonb(old); v_new := to_jsonb(new); v_id := new.id::text; v_accion := 'ESTRUCTURA_INSTITUCIONAL_MODIFICACION';
 else
   v_old := to_jsonb(old); v_new := null; v_id := old.id::text; v_accion := 'ESTRUCTURA_INSTITUCIONAL_BAJA';
 end if;
 perform public.registrar_auditoria_interna(v_accion,tg_table_name,v_id,v_old,v_new,null,
   jsonb_build_object('modulo','estructura_institucional','operacion',tg_op,'tabla',tg_table_name,'blockchain','lote_merkle_auditoria'),
   'trigger_estructura_institucional');
 return case when tg_op = 'DELETE' then old else new end;
end; $$;
revoke all on function public.trg_auditar_estructura_institucional() from public, anon, authenticated;
drop trigger if exists trg_auditar_estructura_asambleistas on public.estructura_asambleistas;
create trigger trg_auditar_estructura_asambleistas after insert or update or delete on public.estructura_asambleistas for each row execute function public.trg_auditar_estructura_institucional();
drop trigger if exists trg_auditar_estructura_personas on public.estructura_personas;
create trigger trg_auditar_estructura_personas after insert or update or delete on public.estructura_personas for each row execute function public.trg_auditar_estructura_institucional();
