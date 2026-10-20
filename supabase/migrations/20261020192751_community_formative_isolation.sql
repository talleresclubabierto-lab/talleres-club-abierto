-- Comunidad Formativa: esquema privado y aditivo.
-- Aplicada en Supabase productivo como migración 20261020192751.
-- No altera tablas ni funciones existentes de socios, votos, gobernanza,
-- auditoría económica ni blockchain.

create schema if not exists comunidad_formativa;
revoke all on schema comunidad_formativa from public, anon, authenticated;
grant usage on schema comunidad_formativa to service_role;

alter default privileges in schema comunidad_formativa revoke all on tables from public, anon, authenticated;
alter default privileges in schema comunidad_formativa revoke all on sequences from public, anon, authenticated;
alter default privileges in schema comunidad_formativa grant all on tables to service_role;
alter default privileges in schema comunidad_formativa grant usage, select on sequences to service_role;

create table comunidad_formativa.solicitudes_acceso (
  id uuid primary key default gen_random_uuid(),
  codigo text not null unique,
  datos_cifrados bytea not null,
  nonce bytea not null check (octet_length(nonce) = 12),
  version_clave smallint not null,
  identificador_hmac text,
  estado text not null default 'pendiente'
    check (estado in ('pendiente','en_revision','aprobada','rechazada','cancelada')),
  estado_vinculo text not null default 'declarado'
    check (estado_vinculo in ('declarado','pendiente_validacion','validado','no_validado')),
  prueba_storage_path text,
  consentimiento_version text not null,
  consentimiento_en timestamptz not null,
  revisada_por bigint,
  revisada_en timestamptz,
  creada_en timestamptz not null default now()
);

create table comunidad_formativa.jugadores (
  id uuid primary key default gen_random_uuid(),
  datos_cifrados bytea not null,
  nonce bytea not null check (octet_length(nonce) = 12),
  version_clave smallint not null,
  referencia_padron_hmac text unique,
  fuente text not null default 'registro_voluntario'
    check (fuente in ('registro_voluntario','importacion_archivo','api_institucional','carga_administrativa')),
  estado text not null default 'pendiente' check (estado in ('pendiente','activo','inactivo')),
  validado_en timestamptz,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table comunidad_formativa.adultos_responsables (
  id uuid primary key default gen_random_uuid(),
  datos_cifrados bytea not null,
  nonce bytea not null check (octet_length(nonce) = 12),
  version_clave smallint not null,
  referencia_padron_hmac text unique,
  email_hmac text,
  telefono_hmac text,
  fuente text not null default 'registro_voluntario'
    check (fuente in ('registro_voluntario','importacion_archivo','api_institucional','carga_administrativa')),
  estado text not null default 'pendiente' check (estado in ('pendiente','activo','inactivo')),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  check (email_hmac is not null or telefono_hmac is not null)
);

create table comunidad_formativa.vinculos (
  id uuid primary key default gen_random_uuid(),
  jugador_id uuid not null references comunidad_formativa.jugadores(id),
  adulto_id uuid not null references comunidad_formativa.adultos_responsables(id),
  vinculo_cifrado bytea not null,
  nonce bytea not null check (octet_length(nonce) = 12),
  version_clave smallint not null,
  estado text not null default 'pendiente' check (estado in ('pendiente','validado','revocado')),
  metodo_validacion text not null default 'declaracion'
    check (metodo_validacion in ('declaracion','revision_documental','padron_importado','api_institucional')),
  validado_por bigint,
  validado_en timestamptz,
  desde timestamptz not null default now(),
  hasta timestamptz,
  creado_en timestamptz not null default now()
);
create unique index comunidad_formativa_vinculo_abierto_unico
  on comunidad_formativa.vinculos(jugador_id, adulto_id) where hasta is null;

create table comunidad_formativa.cuentas (
  id uuid primary key default gen_random_uuid(),
  adulto_id uuid references comunidad_formativa.adultos_responsables(id),
  jugador_id uuid references comunidad_formativa.jugadores(id),
  tipo text not null check (tipo in ('adulto_responsable','jugador_mayor_16')),
  identificador_hmac text not null unique,
  estado text not null default 'pendiente' check (estado in ('pendiente','activa','suspendida','revocada')),
  creada_en timestamptz not null default now(),
  actualizada_en timestamptz not null default now(),
  check ((tipo = 'adulto_responsable' and adulto_id is not null and jugador_id is null)
      or (tipo = 'jugador_mayor_16' and jugador_id is not null and adulto_id is null))
);

create table comunidad_formativa.codigos_otp (
  id uuid primary key default gen_random_uuid(),
  cuenta_id uuid not null references comunidad_formativa.cuentas(id),
  codigo_hmac text not null,
  destino_hmac text not null,
  canal text not null check (canal in ('email','sms')),
  vence_en timestamptz not null,
  intentos smallint not null default 0 check (intentos between 0 and 8),
  consumido_en timestamptz,
  creado_en timestamptz not null default now()
);

create table comunidad_formativa.codigos_activacion (
  id uuid primary key default gen_random_uuid(),
  adulto_id uuid references comunidad_formativa.adultos_responsables(id),
  jugador_id uuid references comunidad_formativa.jugadores(id),
  codigo_hmac text not null unique,
  vence_en timestamptz not null,
  usado_en timestamptz,
  revocado_en timestamptz,
  emitido_por bigint not null,
  creado_en timestamptz not null default now(),
  check (adulto_id is not null or jugador_id is not null),
  check (usado_en is null or revocado_en is null)
);

create table comunidad_formativa.sesiones (
  id uuid primary key default gen_random_uuid(),
  cuenta_id uuid not null references comunidad_formativa.cuentas(id),
  token_hmac text not null unique,
  creada_en timestamptz not null default now(),
  vence_en timestamptz not null,
  ultimo_uso_en timestamptz,
  revocada_en timestamptz
);

create table comunidad_formativa.roles_administrativos (
  id uuid primary key default gen_random_uuid(),
  socio_id bigint not null,
  rol text not null check (rol in (
    'administrador_general','responsable_integridad_formativa','principal_integridad_formativa'
  )),
  habilitado boolean not null default true,
  asignado_por bigint,
  asignado_en timestamptz not null default now(),
  unique(socio_id, rol)
);

create table comunidad_formativa.casos (
  id uuid primary key default gen_random_uuid(),
  codigo text not null unique,
  jugador_id uuid references comunidad_formativa.jugadores(id),
  cuenta_presentante_id uuid references comunidad_formativa.cuentas(id),
  categoria text not null check (categoria in (
    'posible_ventaja_indebida','posible_intervencion_irregular','posible_conflicto_intereses',
    'criterio_deportivo','maltrato_discriminacion','posible_represalia','salud_proteccion',
    'educacion_acompanamiento','entrenamiento','alimentacion','transporte',
    'infraestructura','otra_situacion','sugerencia'
  )),
  modalidad_reserva text not null check (modalidad_reserva in (
    'identificada','reservada_frente_a_area_deportiva','confidencial_integridad'
  )),
  relato_cifrado bytea not null,
  nonce bytea not null check (octet_length(nonce) = 12),
  version_clave smallint not null,
  fecha_aproximada_cifrada bytea,
  fecha_aproximada_nonce bytea check (
    fecha_aproximada_nonce is null or octet_length(fecha_aproximada_nonce) = 12
  ),
  fecha_aproximada_version_clave smallint,
  estado text not null default 'recibida' check (estado in (
    'recibida','en_evaluacion','informacion_solicitada','en_investigacion',
    'resuelta','archivada','reabierta'
  )),
  responsable_ref bigint,
  creada_en timestamptz not null default now(),
  actualizada_en timestamptz not null default now(),
  check (
    (fecha_aproximada_cifrada is null and fecha_aproximada_nonce is null
      and fecha_aproximada_version_clave is null)
    or (fecha_aproximada_cifrada is not null and fecha_aproximada_nonce is not null
      and fecha_aproximada_version_clave is not null)
  )
);

create table comunidad_formativa.archivos (
  id uuid primary key default gen_random_uuid(),
  caso_id uuid not null references comunidad_formativa.casos(id),
  storage_path text not null unique,
  sha256 text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  metadatos_cifrados bytea not null,
  nonce bytea not null check (octet_length(nonce) = 12),
  version_clave smallint not null,
  creado_en timestamptz not null default now()
);

create table comunidad_formativa.actuaciones (
  id uuid primary key default gen_random_uuid(),
  caso_id uuid not null references comunidad_formativa.casos(id),
  tipo text not null check (tipo in (
    'presentacion','cambio_estado','solicitud_informacion','respuesta',
    'documentacion_institucional','medida_adoptada','derivacion_protocolo',
    'resolucion','archivo','reapertura','correccion'
  )),
  detalle_cifrado bytea not null,
  nonce bytea not null check (octet_length(nonce) = 12),
  version_clave smallint not null,
  actor_ref text not null,
  actor_rol text not null,
  creada_en timestamptz not null default now()
);

create table comunidad_formativa.accesos_identidad (
  id uuid primary key default gen_random_uuid(),
  caso_id uuid not null references comunidad_formativa.casos(id),
  actor_socio_id bigint not null,
  motivo_cifrado bytea not null,
  nonce bytea not null check (octet_length(nonce) = 12),
  version_clave smallint not null,
  confirmada boolean not null check (confirmada),
  consultada_en timestamptz not null default now()
);

create table comunidad_formativa.proyeccion_socios (
  id uuid primary key default gen_random_uuid(),
  caso_id uuid not null unique references comunidad_formativa.casos(id),
  codigo text not null unique,
  fecha_general date not null check (
    date_trunc('month', fecha_general::timestamp)::date = fecha_general
  ),
  categoria_general text not null,
  estado_publico text not null,
  hash_evento text not null check (hash_evento ~ '^[0-9a-f]{64}$'),
  publicar_despues_de timestamptz not null,
  publicar boolean not null default false,
  actualizada_en timestamptz not null default now()
);

create table comunidad_formativa.eventos_criptograficos (
  id bigint generated always as identity primary key,
  codigo text not null,
  tipo text not null,
  actor_rol text not null,
  actor_ref text not null,
  contenido_hash text not null check (contenido_hash ~ '^[0-9a-f]{64}$'),
  prev_hash text check (prev_hash is null or prev_hash ~ '^[0-9a-f]{64}$'),
  evento_hash text not null unique check (evento_hash ~ '^[0-9a-f]{64}$'),
  creado_en timestamptz not null default now()
);

create table comunidad_formativa.lotes_merkle (
  id uuid primary key default gen_random_uuid(),
  referencia text not null unique,
  primer_evento_id bigint not null references comunidad_formativa.eventos_criptograficos(id),
  ultimo_evento_id bigint not null references comunidad_formativa.eventos_criptograficos(id),
  cantidad integer not null check (cantidad > 0),
  raiz_sha256 text not null check (raiz_sha256 ~ '^[0-9a-f]{64}$'),
  algoritmo text not null default 'sha256_sorted_pairs_v1',
  estado text not null default 'preparado' check (estado in ('preparado','enviado','confirmado','error')),
  preparado_en timestamptz not null default now()
);

create table comunidad_formativa.anclajes (
  id uuid primary key default gen_random_uuid(),
  lote_id uuid not null unique references comunidad_formativa.lotes_merkle(id),
  red text not null,
  chain_id bigint not null,
  contrato text not null,
  transaccion_hash text not null,
  bloque bigint not null,
  confirmado_en timestamptz not null default now()
);

create table comunidad_formativa.importaciones (
  id uuid primary key default gen_random_uuid(),
  origen text not null check (origen in ('archivo','api_institucional')),
  referencia text not null unique,
  estado text not null default 'preparada' check (estado in (
    'preparada','validando','validada','aplicada','fallida'
  )),
  total_registros integer not null default 0 check (total_registros >= 0),
  creada_por bigint not null,
  creada_en timestamptz not null default now()
);

create table comunidad_formativa.importacion_items (
  id uuid primary key default gen_random_uuid(),
  importacion_id uuid not null references comunidad_formativa.importaciones(id),
  clave_registro_hmac text not null,
  fila_cifrada bytea not null,
  nonce bytea not null check (octet_length(nonce) = 12),
  version_clave smallint not null,
  estado text not null default 'pendiente' check (estado in ('pendiente','valida','error','aplicada')),
  error_cifrado bytea,
  unique(importacion_id, clave_registro_hmac)
);

-- Bucket privado; el cliente no recibe políticas de acceso directo.
insert into storage.buckets (id, name, public)
values ('comunidad-formativa-privada', 'comunidad-formativa-privada', false)
on conflict (id) do nothing;

-- Cerrado por defecto. Solo Edge Functions autorizadas con secreto servidor acceden.
do $$
declare t record;
begin
  for t in select tablename from pg_tables where schemaname = 'comunidad_formativa'
  loop
    execute format('alter table comunidad_formativa.%I enable row level security', t.tablename);
    execute format('alter table comunidad_formativa.%I force row level security', t.tablename);
    execute format('revoke all on comunidad_formativa.%I from public, anon, authenticated', t.tablename);
    execute format('grant all on comunidad_formativa.%I to service_role', t.tablename);
  end loop;
end $$;
revoke all on all sequences in schema comunidad_formativa from public, anon, authenticated;
grant usage, select on all sequences in schema comunidad_formativa to service_role;

create or replace function comunidad_formativa.bloquear_mutacion_append_only()
returns trigger language plpgsql as $$
begin
  raise exception 'Registro inmutable: agregue una nueva actuación';
end;
$$;
revoke all on function comunidad_formativa.bloquear_mutacion_append_only() from public, anon, authenticated;
create trigger eventos_criptograficos_append_only
  before update or delete on comunidad_formativa.eventos_criptograficos
  for each row execute function comunidad_formativa.bloquear_mutacion_append_only();
create trigger actuaciones_append_only
  before update or delete on comunidad_formativa.actuaciones
  for each row execute function comunidad_formativa.bloquear_mutacion_append_only();
create trigger accesos_identidad_append_only
  before update or delete on comunidad_formativa.accesos_identidad
  for each row execute function comunidad_formativa.bloquear_mutacion_append_only();
create trigger casos_no_delete
  before delete on comunidad_formativa.casos
  for each row execute function comunidad_formativa.bloquear_mutacion_append_only();

-- Sin seeds: no se cargan datos reales ni demostrativos en producción.

