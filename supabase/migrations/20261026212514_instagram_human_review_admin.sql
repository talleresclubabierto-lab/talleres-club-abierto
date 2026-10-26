-- Bandeja privada para que administradores revisen respuestas del asistente.
-- Estas funciones sólo son ejecutables con service_role; la Edge Function
-- valida primero la sesión administrativa de Club Abierto.

create or replace function public.instagram_asistente_listar_revision(
  p_estado text default 'pendiente',
  p_limite integer default 100
) returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select coalesce(jsonb_agg(to_jsonb(x) order by x.creado_en desc), '[]'::jsonb)
  from (
    select
      b.id,
      b.categoria,
      b.accion_sugerida,
      b.tono,
      b.respuesta,
      b.razones,
      b.estado,
      b.creado_en,
      b.revisado_por,
      b.revisado_en,
      b.enviado_en,
      e.id_externo,
      e.tipo,
      e.cuenta_externa,
      e.actor_usuario,
      e.contenido,
      case
        when e.payload #>> '{entry,0,changes,0,value,media,permalink}' is not null
          then e.payload #>> '{entry,0,changes,0,value,media,permalink}'
        else null
      end as enlace_origen,
      coalesce(e.payload->>'object', 'instagram') as plataforma
    from instagram_asistente.borradores b
    join instagram_asistente.eventos e on e.id = b.evento_id
    where (p_estado is null or b.estado = p_estado)
    limit greatest(1, least(coalesce(p_limite, 100), 250))
  ) x;
$$;

create or replace function public.instagram_asistente_preparar_revision_humana(
  p_borrador_id uuid,
  p_respuesta text,
  p_revisor bigint
) returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_resultado jsonb;
begin
  if length(trim(coalesce(p_respuesta, ''))) < 2 then
    raise exception 'respuesta_vacia';
  end if;

  update instagram_asistente.borradores b
     set respuesta = left(trim(p_respuesta), 2200),
         estado = case when b.respuesta is distinct from left(trim(p_respuesta), 2200)
                       then 'editado' else 'aprobado' end,
         revisado_por = p_revisor,
         revisado_en = now()
    from instagram_asistente.eventos e
   where b.id = p_borrador_id
     and b.estado in ('pendiente', 'fallido')
     and e.id = b.evento_id
  returning jsonb_build_object(
    'borrador_id', b.id,
    'respuesta', b.respuesta,
    'estado', b.estado,
    'id_externo', e.id_externo,
    'tipo', e.tipo,
    'plataforma', coalesce(e.payload->>'object', 'instagram'),
    'actor_id', e.actor_id,
    'cuenta_externa', e.cuenta_externa
  ) into v_resultado;

  if v_resultado is null then raise exception 'borrador_no_disponible'; end if;

  insert into instagram_asistente.auditoria(evento, entidad, entidad_id, actor, detalle)
  values ('respuesta_aprobada_humana', 'borrador', p_borrador_id::text,
          'socio:' || p_revisor::text,
          jsonb_build_object('estado', v_resultado->>'estado'));
  return v_resultado;
end;
$$;

create or replace function public.instagram_asistente_resolver_revision(
  p_borrador_id uuid,
  p_estado text,
  p_revisor bigint,
  p_detalle jsonb default '{}'::jsonb
) returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare v_actualizado integer;
begin
  if p_estado not in ('rechazado', 'enviado', 'fallido') then
    raise exception 'estado_invalido';
  end if;

  update instagram_asistente.borradores
     set estado = p_estado,
         revisado_por = coalesce(revisado_por, p_revisor),
         revisado_en = coalesce(revisado_en, now()),
         enviado_en = case when p_estado = 'enviado' then now() else enviado_en end
   where id = p_borrador_id
     and estado in ('pendiente', 'aprobado', 'editado', 'fallido');
  get diagnostics v_actualizado = row_count;

  if v_actualizado = 1 then
    insert into instagram_asistente.auditoria(evento, entidad, entidad_id, actor, detalle)
    values ('revision_humana_' || p_estado, 'borrador', p_borrador_id::text,
            'socio:' || p_revisor::text, coalesce(p_detalle, '{}'::jsonb));
  end if;
  return v_actualizado = 1;
end;
$$;

revoke all on function public.instagram_asistente_listar_revision(text,integer) from public, anon, authenticated;
revoke all on function public.instagram_asistente_preparar_revision_humana(uuid,text,bigint) from public, anon, authenticated;
revoke all on function public.instagram_asistente_resolver_revision(uuid,text,bigint,jsonb) from public, anon, authenticated;
grant execute on function public.instagram_asistente_listar_revision(text,integer) to service_role;
grant execute on function public.instagram_asistente_preparar_revision_humana(uuid,text,bigint) to service_role;
grant execute on function public.instagram_asistente_resolver_revision(uuid,text,bigint,jsonb) to service_role;
