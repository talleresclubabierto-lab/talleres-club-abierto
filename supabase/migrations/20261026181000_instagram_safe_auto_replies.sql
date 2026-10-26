-- Envíos automáticos limitados a categorías autorizadas por Talleres Club Abierto.
-- Denuncias, prensa, menores, agresiones y preguntas continúan bajo revisión humana.

create or replace function public.instagram_asistente_obtener_configuracion()
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'modo', modo,
    'envio_automatico_habilitado', envio_automatico_habilitado
  )
  from instagram_asistente.configuracion
  where id = 1;
$$;

create or replace function public.instagram_asistente_preparar_envio(p_borrador_id uuid)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_actualizado integer;
begin
  update instagram_asistente.borradores b
     set estado = 'aprobado', revisado_en = now()
    from instagram_asistente.configuracion c
   where b.id = p_borrador_id
     and b.estado = 'pendiente'
     and b.accion_sugerida = 'responder'
     and b.categoria in ('apoyo', 'colaboracion', 'confusion_identidad', 'chicana_rival')
     and c.id = 1
     and c.modo = 'respuestas_seguras'
     and c.envio_automatico_habilitado;
  get diagnostics v_actualizado = row_count;
  return v_actualizado = 1;
end;
$$;

create or replace function public.instagram_asistente_marcar_envio(
  p_borrador_id uuid,
  p_estado text,
  p_detalle jsonb default '{}'::jsonb
) returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_actualizado integer;
begin
  if p_estado not in ('enviado', 'fallido') then
    raise exception 'estado_invalido';
  end if;

  update instagram_asistente.borradores
     set estado = p_estado,
         enviado_en = case when p_estado = 'enviado' then now() else enviado_en end
   where id = p_borrador_id
     and estado = 'aprobado';
  get diagnostics v_actualizado = row_count;

  if v_actualizado = 1 then
    insert into instagram_asistente.auditoria (evento, entidad, entidad_id, actor, detalle)
    values ('respuesta_' || p_estado, 'borrador', p_borrador_id::text, 'asistente', coalesce(p_detalle, '{}'::jsonb));
  end if;
  return v_actualizado = 1;
end;
$$;

create or replace function public.instagram_asistente_guardar_borrador(
  p_evento_id uuid,
  p_categoria text,
  p_accion_sugerida text,
  p_tono text,
  p_respuesta text,
  p_razones text[]
) returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_id uuid;
begin
  insert into instagram_asistente.borradores (
    evento_id, categoria, accion_sugerida, tono, respuesta, razones
  ) values (
    p_evento_id, p_categoria, p_accion_sugerida, p_tono,
    nullif(left(coalesce(p_respuesta, ''), 2200), ''), coalesce(p_razones, '{}')
  )
  on conflict (evento_id) do update set
    categoria = excluded.categoria,
    accion_sugerida = excluded.accion_sugerida,
    tono = excluded.tono,
    respuesta = excluded.respuesta,
    razones = excluded.razones
  returning id into v_id;

  update instagram_asistente.eventos set procesado_en = now() where id = p_evento_id;
  insert into instagram_asistente.auditoria (evento, entidad, entidad_id, actor)
  values ('borrador_generado', 'borrador', v_id::text, 'asistente');
  return v_id;
end;
$$;

revoke all on function public.instagram_asistente_obtener_configuracion() from public, anon, authenticated;
revoke all on function public.instagram_asistente_preparar_envio(uuid) from public, anon, authenticated;
revoke all on function public.instagram_asistente_marcar_envio(uuid,text,jsonb) from public, anon, authenticated;
grant execute on function public.instagram_asistente_obtener_configuracion() to service_role;
grant execute on function public.instagram_asistente_preparar_envio(uuid) to service_role;
grant execute on function public.instagram_asistente_marcar_envio(uuid,text,jsonb) to service_role;

insert into instagram_asistente.ejemplos_estilo
  (categoria, entrada_anonimizada, respuesta_aprobada, tono)
select * from (values
  ('chicana_rival', 'Se burla llamando gallina o muerto.',
   'Nos dicen “muertos” mientras siguen pendientes de cada cosa que hace Talleres. Gracias por la atención; nosotros seguimos construyendo. 😉',
   'picante_medido'),
  ('chicana_rival', 'Usa “virgo” o una alusión vulgar a la historia deportiva.',
   'Para hablar de historia primero hay que tener memoria. La chicana es gratis; construir una propuesta concreta lleva trabajo. 😉',
   'picante_medido'),
  ('chicana_rival', 'Hace una burla sobre México, Fassi o un meme mexicano.',
   'El meme dura segundos; las ideas quedan. Cuando quieran debatir la propuesta sin confundir al Club con una conducción, acá estamos. 😉',
   'picante_medido')
) as nuevos(categoria, entrada_anonimizada, respuesta_aprobada, tono)
where not exists (
  select 1 from instagram_asistente.ejemplos_estilo e
  where e.categoria = nuevos.categoria
    and e.respuesta_aprobada = nuevos.respuesta_aprobada
);

