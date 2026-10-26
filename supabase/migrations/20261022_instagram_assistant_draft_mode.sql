-- Asistente de Instagram para Talleres Club Abierto.
-- Fase inicial: recepción, clasificación y borradores. Nunca publica automáticamente.
-- Esquema privado, aislado de socios, votaciones y módulos institucionales.

create schema if not exists instagram_asistente;
revoke all on schema instagram_asistente from public, anon, authenticated;
grant usage on schema instagram_asistente to service_role;

alter default privileges in schema instagram_asistente revoke all on tables from public, anon, authenticated;
alter default privileges in schema instagram_asistente revoke all on sequences from public, anon, authenticated;
alter default privileges in schema instagram_asistente grant all on tables to service_role;
alter default privileges in schema instagram_asistente grant usage, select on sequences to service_role;

create table instagram_asistente.configuracion (
  id smallint primary key default 1 check (id = 1),
  modo text not null default 'solo_borradores'
    check (modo in ('apagado', 'solo_borradores', 'respuestas_seguras')),
  envio_automatico_habilitado boolean not null default false,
  conservar_eventos_dias smallint not null default 90
    check (conservar_eventos_dias between 7 and 365),
  actualizado_en timestamptz not null default now(),
  check (not envio_automatico_habilitado or modo = 'respuestas_seguras')
);

insert into instagram_asistente.configuracion (id)
values (1)
on conflict (id) do nothing;

create table instagram_asistente.eventos (
  id uuid primary key default gen_random_uuid(),
  id_externo text not null,
  tipo text not null check (tipo in ('comentario', 'mensaje_privado', 'otro')),
  cuenta_externa text,
  actor_id text,
  actor_usuario text,
  contenido text,
  payload jsonb not null,
  recibido_en timestamptz not null default now(),
  procesado_en timestamptz,
  unique (id_externo, tipo)
);

create index instagram_asistente_eventos_pendientes_idx
  on instagram_asistente.eventos (recibido_en)
  where procesado_en is null;

create table instagram_asistente.borradores (
  id uuid primary key default gen_random_uuid(),
  evento_id uuid not null unique references instagram_asistente.eventos(id) on delete cascade,
  categoria text not null check (categoria in (
    'apoyo', 'colaboracion', 'pregunta_genuina', 'confusion_identidad',
    'critica_constructiva', 'chicana_rival', 'agresion', 'spam',
    'politica_institucional', 'acusacion_sensible', 'prensa', 'menores', 'otra'
  )),
  accion_sugerida text not null check (accion_sugerida in (
    'responder', 'revisar', 'solo_humano', 'ocultar', 'ignorar', 'escalar'
  )),
  tono text not null check (tono in (
    'calido', 'institucional', 'tecnico', 'firme', 'picante_medido', 'sin_respuesta'
  )),
  respuesta text,
  razones text[] not null default '{}',
  estado text not null default 'pendiente' check (estado in (
    'pendiente', 'aprobado', 'editado', 'rechazado', 'enviado', 'fallido'
  )),
  creado_en timestamptz not null default now(),
  revisado_por bigint,
  revisado_en timestamptz,
  enviado_en timestamptz,
  check (accion_sugerida <> 'responder' or respuesta is not null)
);

create index instagram_asistente_borradores_revision_idx
  on instagram_asistente.borradores (estado, creado_en desc);

create table instagram_asistente.ejemplos_estilo (
  id bigint generated always as identity primary key,
  categoria text not null,
  entrada_anonimizada text not null,
  respuesta_aprobada text not null,
  tono text not null,
  origen text not null default 'historial_curado'
    check (origen in ('historial_curado', 'respuesta_aprobada', 'manual')),
  activo boolean not null default true,
  creado_en timestamptz not null default now()
);

create table instagram_asistente.auditoria (
  id bigint generated always as identity primary key,
  evento text not null,
  entidad text not null,
  entidad_id text,
  actor text not null,
  detalle jsonb not null default '{}',
  creado_en timestamptz not null default now()
);

insert into instagram_asistente.ejemplos_estilo
  (categoria, entrada_anonimizada, respuesta_aprobada, tono)
values
  ('colaboracion', 'Soy socio y quiero ayudar en administración o logística.',
   '¡Gracias por acercarte! Estamos sumando socios, hinchas y profesionales que quieran construir una propuesta concreta, participativa y transparente. Contanos en qué área tenés experiencia y cómo te gustaría aportar.',
   'calido'),
  ('confusion_identidad', '¿Ustedes son del Club?',
   'Somos socios e hinchas de Talleres impulsando una propuesta concreta e independiente. No somos una cuenta oficial del Club ni representamos a la actual conducción.',
   'institucional'),
  ('pregunta_genuina', '¿Esto también alcanza compras, ventas, contratos y plazos?',
   'Sí. El objetivo es que cada operación relevante tenga información clara, responsables identificados, documentación respaldatoria y mecanismos de auditoría. La implementación puede ser escalonada, pero la transparencia debe alcanzar a todas las áreas.',
   'tecnico'),
  ('critica_constructiva', 'Me parece que todavía están lejos de concretarlo.',
   'Es lógico pedir precisiones. Por eso presentamos una propuesta concreta, con etapas, números ilustrativos y mecanismos auditables. El debate con argumentos ayuda a mejorarla.',
   'firme'),
  ('chicana_rival', 'Se ríe del club y de la propuesta sin aportar argumentos.',
   'La chicana dura segundos; construir una propuesta seria lleva trabajo. Cuando quieras debatir ideas concretas, acá estamos.',
   'picante_medido');

alter table instagram_asistente.configuracion enable row level security;
alter table instagram_asistente.eventos enable row level security;
alter table instagram_asistente.borradores enable row level security;
alter table instagram_asistente.ejemplos_estilo enable row level security;
alter table instagram_asistente.auditoria enable row level security;

create or replace function public.instagram_asistente_guardar_evento(
  p_id_externo text,
  p_tipo text,
  p_cuenta_externa text,
  p_actor_id text,
  p_actor_usuario text,
  p_contenido text,
  p_payload jsonb
) returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_id uuid;
begin
  insert into instagram_asistente.eventos (
    id_externo, tipo, cuenta_externa, actor_id, actor_usuario, contenido, payload
  ) values (
    left(p_id_externo, 255), p_tipo, left(p_cuenta_externa, 255),
    left(p_actor_id, 255), left(p_actor_usuario, 255), left(p_contenido, 8000), p_payload
  )
  on conflict (id_externo, tipo) do update
    set payload = excluded.payload
  returning id into v_id;

  return v_id;
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
    razones = excluded.razones,
    estado = 'pendiente',
    creado_en = now()
  returning id into v_id;

  update instagram_asistente.eventos set procesado_en = now() where id = p_evento_id;
  insert into instagram_asistente.auditoria (evento, entidad, entidad_id, actor)
  values ('borrador_generado', 'borrador', v_id::text, 'asistente');
  return v_id;
end;
$$;

revoke all on function public.instagram_asistente_guardar_evento(text,text,text,text,text,text,jsonb)
  from public, anon, authenticated;
revoke all on function public.instagram_asistente_guardar_borrador(uuid,text,text,text,text,text[])
  from public, anon, authenticated;
grant execute on function public.instagram_asistente_guardar_evento(text,text,text,text,text,text,jsonb)
  to service_role;
grant execute on function public.instagram_asistente_guardar_borrador(uuid,text,text,text,text,text,text[])
  to service_role;

comment on schema instagram_asistente is
  'Datos privados del asistente de Instagram. Sin acceso directo para anon ni authenticated.';
comment on table instagram_asistente.eventos is
  'Eventos recibidos de Meta; retención configurada en 90 días por defecto.';
comment on table instagram_asistente.borradores is
  'Respuestas propuestas para revisión humana. El modo inicial no publica automáticamente.';
