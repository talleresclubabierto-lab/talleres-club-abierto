-- Scouting colaborativo. Apply through Supabase apply_migration after review.
-- No remote catalogue retrieval, scheduler or blockchain activation is included.
-- Dependency contracts were inspected on 2026-10-29; no existing table is modified.

create schema scouting;
revoke all on schema scouting from public, anon, authenticated, service_role;
alter default privileges in schema scouting revoke all on tables from public, anon, authenticated, service_role;
alter default privileges in schema scouting revoke all on sequences from public, anon, authenticated, service_role;
alter default privileges in schema scouting revoke execute on functions from public, anon, authenticated, service_role;

create table scouting.provinces (
  name text primary key
);
insert into scouting.provinces(name) values
 ('Buenos Aires'),('Catamarca'),('Chaco'),('Chubut'),('Ciudad Autónoma de Buenos Aires'),
 ('Córdoba'),('Corrientes'),('Entre Ríos'),('Formosa'),('Jujuy'),('La Pampa'),('La Rioja'),
 ('Mendoza'),('Misiones'),('Neuquén'),('Río Negro'),('Salta'),('San Juan'),('San Luis'),
 ('Santa Cruz'),('Santa Fe'),('Santiago del Estero'),('Tierra del Fuego, Antártida e Islas del Atlántico Sur'),('Tucumán');

create table scouting.competitions (
  id text primary key check (id ~ '^[a-z0-9-]{2,60}$'),
  name text not null check (char_length(name) between 2 and 160),
  season text not null default '2026',
  sort_order integer not null default 50,
  active boolean not null default true
);
-- Navigation labels, not a claim of complete provider coverage. Local competitions
-- and player categories remain independent from national first-team competitions.
insert into scouting.competitions(id,name,sort_order) values
 ('primera-division','Primera División — Liga Profesional de Fútbol',10),
 ('primera-nacional','Primera Nacional',20),
 ('federal-a','Torneo Federal A',30),
 ('primera-b','Primera B',31),
 ('primera-c','Primera C',40),
 ('regional-amateur','Torneo Regional Federal Amateur',41),
 ('promocional-amateur','Torneo Promocional Amateur',50),
 ('liga-local','Liga local o regional',60);

create table scouting.catalogue_runs (
  id uuid primary key default gen_random_uuid(),
  source text not null,
  status text not null check(status in ('staging','validated','published','failed')),
  authorization_reference text,
  created_at timestamptz not null default now(),
  published_at timestamptz,
  metadata jsonb not null default '{}'::jsonb
);
create table scouting.clubs (
  id uuid primary key default gen_random_uuid(),
  source_key text not null unique,
  name text not null check(char_length(name) between 2 and 160),
  province text not null references scouting.provinces(name),
  city text not null check(char_length(city) between 2 and 100),
  league text,
  source text not null check(source in ('official_reference','licensed_transfermarkt','verified_manual')),
  source_urls jsonb not null default '[]'::jsonb,
  checked_at timestamptz not null,
  catalogue_run_id uuid references scouting.catalogue_runs(id),
  active boolean not null default true
);
create index scouting_clubs_province_name_idx on scouting.clubs(province, lower(name), id) where active;
create unique index scouting_clubs_identity_idx on scouting.clubs(province, lower(city), lower(name));
create table scouting.club_competitions (
  club_id uuid not null references scouting.clubs(id),
  competition_id text not null references scouting.competitions(id),
  season text not null,
  division text,
  reference_scope text not null default 'primer_equipo_masculino',
  source_urls jsonb not null default '[]'::jsonb,
  checked_at timestamptz not null,
  primary key(club_id, competition_id, season)
);
create index scouting_club_competitions_filter_idx on scouting.club_competitions(competition_id, season, club_id);
create table scouting.players (
  id uuid primary key default gen_random_uuid(),
  source_key text not null unique,
  club_id uuid not null references scouting.clubs(id),
  first_name text not null check(char_length(first_name) between 2 and 100),
  last_name text not null check(char_length(last_name) between 2 and 100),
  category text not null check(char_length(category) between 2 and 100),
  position text,
  transfermarkt_url text,
  source text not null check(source in ('official_reference','licensed_transfermarkt','verified_manual')),
  checked_at timestamptz not null,
  catalogue_run_id uuid references scouting.catalogue_runs(id),
  active boolean not null default true
);
create index scouting_players_club_category_idx on scouting.players(club_id, category, lower(last_name), id) where active;

create table scouting.recommendations (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  owner_numero_socio bigint not null references public.socios(numero_socio),
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  status text not null default 'recibida' check(status in ('recibida','en_revision','informacion_solicitada','en_seguimiento','cerrada')),
  snapshot jsonb not null check(jsonb_typeof(snapshot)='object'),
  private_nonce text not null check(private_nonce ~ '^[a-f0-9]{64}$'),
  commitment_hash text not null check(commitment_hash ~ '^[a-f0-9]{64}$')
);
create index scouting_recommendations_owner_created_idx on scouting.recommendations(owner_numero_socio, created_at desc, id desc);
create index scouting_recommendations_status_created_idx on scouting.recommendations(status, created_at desc, id desc);

create table scouting.events (
  id uuid primary key default gen_random_uuid(),
  recommendation_id uuid not null references scouting.recommendations(id),
  sequence_no integer not null check(sequence_no>0),
  actor_numero_socio bigint not null references public.socios(numero_socio),
  actor_role text not null check(actor_role in ('socio','admin')),
  event_type text not null check(event_type in ('created','information_added','status_updated','club_validated')),
  status text not null check(status in ('recibida','en_revision','informacion_solicitada','en_seguimiento','cerrada')),
  member_message text not null,
  created_at timestamptz not null default clock_timestamp(),
  private_nonce text not null check(private_nonce ~ '^[a-f0-9]{64}$'),
  prev_hash text,
  event_hash text not null check(event_hash ~ '^[a-f0-9]{64}$'),
  audit_event_id bigint not null unique references public.auditoria_administrativa(id),
  unique(recommendation_id, sequence_no)
);
create index scouting_events_rec_idx on scouting.events(recommendation_id, sequence_no);
create table scouting.requests (
  actor_numero_socio bigint not null references public.socios(numero_socio),
  request_id uuid not null,
  action text not null,
  request_hash text not null,
  recommendation_id uuid not null references scouting.recommendations(id),
  created_at timestamptz not null default clock_timestamp(),
  primary key(actor_numero_socio, request_id)
);
create table scouting.club_validations (
  recommendation_id uuid primary key references scouting.recommendations(id),
  club_id uuid not null references scouting.clubs(id),
  actor_numero_socio bigint not null references public.socios(numero_socio),
  reason text not null,
  created_at timestamptz not null default clock_timestamp()
);

do $$
declare r record;
begin
  for r in select tablename from pg_tables where schemaname='scouting' loop
    execute format('alter table scouting.%I enable row level security',r.tablename);
    execute format('alter table scouting.%I force row level security',r.tablename);
    execute format('revoke all on scouting.%I from public, anon, authenticated, service_role',r.tablename);
  end loop;
end;
$$;

create function scouting.prevent_history_change() returns trigger
language plpgsql security invoker set search_path=pg_catalog as $$
begin
  raise exception using errcode='42501', message='El historial de scouting es inmutable';
end;
$$;
create trigger scouting_events_immutable before update or delete on scouting.events
  for each row execute function scouting.prevent_history_change();
create trigger scouting_requests_immutable before update or delete on scouting.requests
  for each row execute function scouting.prevent_history_change();
create trigger scouting_club_validations_immutable before update or delete on scouting.club_validations
  for each row execute function scouting.prevent_history_change();
create function scouting.protect_recommendation() returns trigger
language plpgsql security invoker set search_path=pg_catalog as $$
begin
  if tg_op='DELETE' then
    raise exception using errcode='42501', message='Las recomendaciones se conservan en el historial';
  end if;
  if new.id is distinct from old.id or new.code is distinct from old.code
     or new.owner_numero_socio is distinct from old.owner_numero_socio
     or new.created_at is distinct from old.created_at or new.snapshot is distinct from old.snapshot
     or new.private_nonce is distinct from old.private_nonce
     or new.commitment_hash is distinct from old.commitment_hash then
    raise exception using errcode='42501', message='Los datos originales de la recomendación son inmutables';
  end if;
  return new;
end;
$$;
create trigger scouting_recommendation_snapshot_immutable before update or delete on scouting.recommendations
  for each row execute function scouting.protect_recommendation();

create function scouting.text_value(p_value jsonb,p_min integer,p_max integer,p_label text,p_optional boolean default false)
returns text language plpgsql immutable security invoker set search_path=pg_catalog as $$
declare v text;
begin
  if p_value is null or p_value='null'::jsonb then
    if p_optional then return null; end if;
    raise exception using errcode='PT422', message='Completá el campo '||p_label;
  end if;
  if jsonb_typeof(p_value)<>'string' then
    raise exception using errcode='PT422', message='El campo '||p_label||' debe ser texto';
  end if;
  v:=btrim(p_value #>> '{}');
  if v='' and p_optional then return null; end if;
  if char_length(v)<p_min or char_length(v)>p_max or v ~ '[\x00-\x08\x0B\x0C\x0E-\x1F]' then
    raise exception using errcode='PT422', message='Revisá la longitud o el formato de '||p_label;
  end if;
  return v;
end;
$$;

create function scouting.url_value(p_value jsonb,p_kind text)
returns text language plpgsql immutable security invoker set search_path=pg_catalog as $$
declare v text;
begin
  v:=scouting.text_value(p_value,1,2048,'enlace',true);
  if v is null then return null; end if;
  if v ~ '[[:space:]\\]' then raise exception using errcode='PT422',message='El enlace no es válido'; end if;
  if p_kind='transfermarkt' then
    if v !~ '^https://(www\.)?transfermarkt\.(com|com\.ar|es|de|co\.uk|it|fr|pt|nl)/[a-zA-Z0-9_/%.-]+/(profil/spieler|startseite/verein|kader/verein)/[0-9]+(/[^?#]*)?(\?[^#]*)?(#.*)?$' then
      raise exception using errcode='PT422',message='Usá un enlace HTTPS al perfil de Transfermarkt del jugador o del club';
    end if;
  elsif p_kind='video' then
    if v !~ '^https://((www\.|m\.)?youtube\.com|youtu\.be|(www\.|player\.)?vimeo\.com)/[^[:space:]\\]+$' then
      raise exception using errcode='PT422',message='Usá un enlace HTTPS de YouTube o Vimeo';
    end if;
  else raise exception using errcode='PT422',message='Tipo de enlace inválido';
  end if;
  return v;
end;
$$;

create function scouting.recommendation_json(p_id uuid,p_admin boolean default false,p_actor bigint default null)
returns jsonb language sql stable security invoker set search_path=pg_catalog as $$
  select r.snapshot || jsonb_build_object(
    'id',r.id,'code',r.code,'created_at',r.created_at,'updated_at',r.updated_at,
    'status',r.status,'commitment_hash',r.commitment_hash,
    'author',jsonb_build_object('name',(select s.nombre from public.socios s where s.numero_socio=r.owner_numero_socio)),
    'can_add_info',coalesce(p_actor=r.owner_numero_socio and r.status<>'cerrada',false),'can_manage',p_admin,
    'club_validated',exists(select 1 from scouting.club_validations cv where cv.recommendation_id=r.id),
    'audit_event_id',(select e.audit_event_id from scouting.events e where e.recommendation_id=r.id order by e.sequence_no limit 1)
  )
  from scouting.recommendations r where r.id=p_id;
$$;

create function scouting.append_event(p_recommendation_id uuid,p_actor bigint,p_role text,p_type text,p_status text,p_message text)
returns uuid language plpgsql security invoker set search_path=pg_catalog as $$
declare
  v_rec scouting.recommendations%rowtype;
  v_id uuid:=gen_random_uuid();
  v_nonce text:=encode(extensions.gen_random_bytes(32),'hex');
  v_previous text;
  v_sequence integer;
  v_created timestamptz:=clock_timestamp();
  v_hash text;
  v_audit bigint;
  v_context text:=current_setting('app.actor_socio',true);
begin
  select * into strict v_rec from scouting.recommendations where id=p_recommendation_id for update;
  select event_hash,sequence_no+1 into v_previous,v_sequence from scouting.events
    where recommendation_id=p_recommendation_id order by sequence_no desc limit 1;
  v_sequence:=coalesce(v_sequence,1);
  v_hash:=encode(extensions.digest(convert_to(jsonb_build_object(
    'schema','scouting-event-v1','id',v_id,'recommendation_id',p_recommendation_id,
    'sequence',v_sequence,'actor',p_actor,'role',p_role,'type',p_type,'status',p_status,
    'message',p_message,'created_at',to_char(v_created at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'original_commitment',v_rec.commitment_hash,'previous',v_previous,'nonce',v_nonce
  )::text,'UTF8'),'sha256'),'hex');

  -- The shared audit function normally resolves actor names. Its context is
  -- suppressed only for this call: the identity, nonce and content remain private.
  perform set_config('app.actor_socio','',true);
  v_audit:=public.registrar_auditoria_interna(
    'SCOUTING_'||upper(p_type),'scouting_commitment',v_id::text,null,
    jsonb_build_object('schema','scouting-event-v1','commitment_sha256',v_hash),
    null,jsonb_build_object('modulo','scouting','version',1),'scouting_api'
  );
  perform set_config('app.actor_socio',coalesce(v_context,''),true);

  insert into scouting.events(id,recommendation_id,sequence_no,actor_numero_socio,actor_role,event_type,status,
    member_message,created_at,private_nonce,prev_hash,event_hash,audit_event_id)
  values(v_id,p_recommendation_id,v_sequence,p_actor,p_role,p_type,p_status,p_message,
    v_created,v_nonce,v_previous,v_hash,v_audit);
  return v_id;
exception when others then
  perform set_config('app.actor_socio',coalesce(v_context,''),true);
  raise;
end;
$$;

create function scouting.proof_json(p_recommendation_id uuid)
returns jsonb language plpgsql stable security invoker set search_path=pg_catalog as $$
declare
  v_event scouting.events%rowtype;
  v_lot public.lotes_merkle_auditoria%rowtype;
  v_audit_hash text;
  v_hashes text[];
  v_index integer;
  v_path jsonb;
  v_valid boolean:=false;
  v_status text:='registrada';
begin
  select * into v_event from scouting.events where recommendation_id=p_recommendation_id order by sequence_no limit 1;
  if not found then return null; end if;
  select event_hash into v_audit_hash from public.auditoria_administrativa where id=v_event.audit_event_id;
  select * into v_lot from public.lotes_merkle_auditoria
    where v_event.audit_event_id between primer_evento_id and ultimo_evento_id
    order by (estado='anclado') desc,preparado_en desc limit 1;
  if found then
    select array_agg(a.event_hash order by a.id),count(*) filter(where a.id<v_event.audit_event_id)::integer
      into v_hashes,v_index from public.auditoria_administrativa a
      where a.id between v_lot.primer_evento_id and v_lot.ultimo_evento_id;
    v_path:=public.merkle_proof_sha256_sorted_pairs_v1(v_hashes,v_index);
    v_valid:=public.verificar_prueba_merkle_sha256_sorted_pairs_v1(v_audit_hash,v_path,v_lot.raiz_merkle_sha256);
    v_status:='preparada';
    if v_lot.estado='enviado' then v_status:='enviada'; end if;
    if v_lot.estado='anclado' and v_lot.transaccion_hash ~ '^0x[0-9a-fA-F]{64}$'
       and v_lot.bloque_numero is not null and v_lot.anclado_en is not null and v_valid then v_status:='anclada'; end if;
  end if;
  return jsonb_build_object('status',v_status,'commitment_hash',v_event.event_hash,
    'audit_event_id',v_event.audit_event_id,'audit_event_hash',v_audit_hash,
    'lot_id',v_lot.id,'merkle_root',v_lot.raiz_merkle_sha256,'merkle_path',v_path,'merkle_valid',v_valid,
    'transaction_hash',v_lot.transaccion_hash,'block_number',v_lot.bloque_numero,
    'chain_id',v_lot.chain_id,'anchor_state',v_lot.estado);
end;
$$;

-- Single narrowly granted RPC. The legacy club session is validated server-side
-- for every action; neither frontend role flags nor user-editable metadata authorize.
create function public.scouting_api(p_token text,p_action text,p_payload jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path=pg_catalog as $$
declare
  v_actor bigint;
  v_admin boolean;
  v_role text;
  v_action text:=coalesce(p_action,'');
  v_payload jsonb:=coalesce(p_payload,'{}'::jsonb);
  v_id uuid;
  v_request uuid;
  v_request_hash text;
  v_previous_request scouting.requests%rowtype;
  v_rec scouting.recommendations%rowtype;
  v_club scouting.clubs%rowtype;
  v_player scouting.players%rowtype;
  v_comp scouting.competitions%rowtype;
  v_club_id uuid;
  v_player_id uuid;
  v_club_json jsonb;
  v_player_json jsonb;
  v_snapshot jsonb;
  v_nonce text;
  v_hash text;
  v_code text;
  v_category text;
  v_position text;
  v_sector text;
  v_reason text;
  v_observation text;
  v_video text;
  v_tm text;
  v_message text;
  v_status text;
  v_query text;
  v_province text;
  v_competition text;
  v_items jsonb;
  v_events jsonb;
  v_next text;
  v_offset integer:=0;
  v_positions constant text[]:=array['Arquero','Lateral','Defensor Central','Volante central','Volante por derecha','Volante por Izquierda','Volante Mixto','Delantero de Area','Delantero Extremo'];
  v_categories constant text[]:=array['Primera','Reserva','Proyección/Tercera','4ª división','5ª división','6ª división','7ª división','8ª división','9ª división','10ª división','11ª división','Sub-21','Sub-20','Sub-19','Sub-17','Sub-16','Sub-15','Sub-14','Sub-13','Sub-12','Infantil','Otra'];
begin
  if p_token is null or char_length(p_token) not between 32 and 512 then
    raise exception using errcode='PT401',message='Ingresá nuevamente con tu número de socio';
  end if;
  begin
    v_actor:=public.validar_sesion_segura_interno(p_token);
  exception when others then
    raise exception using errcode='PT401',message='La sesión venció o no está habilitada';
  end;
  if v_actor is null or not exists(select 1 from public.socios where numero_socio=v_actor and habilitado) then
    raise exception using errcode='PT401',message='La sesión venció o no está habilitada';
  end if;
  select exists(select 1 from public.administradores where numero_socio=v_actor and habilitado) into v_admin;
  v_role:=case when v_admin then 'admin' else 'socio' end;
  if jsonb_typeof(v_payload)<>'object' or octet_length(v_payload::text)>32768 then
    raise exception using errcode='PT422',message='Los datos del formulario no son válidos o son demasiado extensos';
  end if;
  if v_action not in ('bootstrap','clubs','players','create','feed','mine','detail','add_info','admin_list','admin_update','admin_validate_club') then
    raise exception using errcode='PT422',message='La operación solicitada no está disponible';
  end if;
  if v_action in ('admin_list','admin_update','admin_validate_club') and not v_admin then
    raise exception using errcode='PT403',message='Esta operación requiere un administrador habilitado';
  end if;
  if nullif(v_payload->>'internal_note','') is not null then
    raise exception using errcode='PT422',message='Las devoluciones de scouting son visibles para todos los socios. Usá el campo mensaje';
  end if;

  if v_action='bootstrap' then
    return jsonb_build_object('ok',true,'actor',jsonb_build_object('numero_socio',v_actor,'role',v_role),
      'provinces',(select jsonb_agg(name order by name) from scouting.provinces),
      'competitions',(select jsonb_agg(jsonb_build_object('id',id,'name',name,'season',season) order by sort_order,name) from scouting.competitions where active),
      'positions',to_jsonb(v_positions),'categories',to_jsonb(v_categories),
      'catalogue',jsonb_build_object('club_count',(select count(*) from scouting.clubs where active),
        'player_count',(select count(*) from scouting.players where active),
        'provider_status','pending_authorization','coverage','partial_official_references',
        'last_verified_at',(select max(checked_at) from scouting.clubs where active)));
  end if;

  if v_action in ('clubs','players','feed','mine','admin_list') then
    if nullif(v_payload->>'cursor','') is not null then
      if v_payload->>'cursor' !~ '^[0-9]{1,6}$' then raise exception using errcode='PT422',message='La página solicitada no es válida'; end if;
      v_offset:=(v_payload->>'cursor')::integer;
      if v_offset>100000 then raise exception using errcode='PT422',message='Refiná la búsqueda para ver más resultados'; end if;
    end if;
    v_query:=scouting.text_value(v_payload->'query',0,100,'búsqueda',true);
    v_province:=scouting.text_value(v_payload->'province',0,100,'provincia',true);
    v_competition:=scouting.text_value(v_payload->'competition_id',0,60,'competencia',true);
    if v_province is not null and not exists(select 1 from scouting.provinces where name=v_province) then
      raise exception using errcode='PT422',message='Seleccioná una provincia válida';
    end if;
  end if;

  if v_action='clubs' then
    with matches as (
      select c.id,c.name,c.province,c.city,c.league,c.checked_at,c.source,c.source_urls,
        co.id as competition_id,co.name as competition_name,cc.division,cc.season,cc.reference_scope,
        coalesce((select jsonb_agg(jsonb_build_object('id',cx.id,'name',cx.name,
          'season',mx.season,'division',mx.division,'reference_scope',mx.reference_scope) order by mx.season desc,cx.sort_order)
          from scouting.club_competitions mx join scouting.competitions cx on cx.id=mx.competition_id
          where mx.club_id=c.id and cx.active),'[]'::jsonb) as competitions
      from scouting.clubs c
      left join lateral (select m.* from scouting.club_competitions m
        where m.club_id=c.id and (v_competition is null or m.competition_id=v_competition)
        order by m.season desc,m.competition_id limit 1) cc on true
      left join scouting.competitions co on co.id=cc.competition_id
      where c.active and (v_province is null or c.province=v_province)
        and (v_competition is null or cc.competition_id=v_competition)
        and (v_query is null or strpos(lower(c.name||' '||c.city),lower(v_query))>0)
      order by lower(c.name),c.id limit 26 offset v_offset
    ) select coalesce(jsonb_agg(to_jsonb(matches)),'[]'::jsonb) into v_items from matches;
  elsif v_action='players' then
    v_club_id:=nullif(v_payload->>'club_id','')::uuid;
    if v_club_id is null or not exists(select 1 from scouting.clubs where id=v_club_id and active) then
      raise exception using errcode='PT422',message='Seleccioná un club del catálogo';
    end if;
    v_category:=scouting.text_value(v_payload->'category',0,100,'categoría',true);
    with matches as (
      select id,first_name,last_name,category,position from scouting.players
      where active and club_id=v_club_id and (v_category is null or category=v_category)
        and (v_query is null or strpos(lower(first_name||' '||last_name),lower(v_query))>0)
      order by lower(last_name),lower(first_name),id limit 26 offset v_offset
    ) select coalesce(jsonb_agg(to_jsonb(matches)),'[]'::jsonb) into v_items from matches;
  elsif v_action in ('feed','mine','admin_list') then
    if v_payload ? 'mine_only' and jsonb_typeof(v_payload->'mine_only')<>'boolean' then
      raise exception using errcode='PT422',message='El filtro de autor no es válido';
    end if;
    v_status:=scouting.text_value(v_payload->'status',0,40,'estado',true);
    if v_status is not null and v_status not in ('recibida','en_revision','informacion_solicitada','en_seguimiento','cerrada') then
      raise exception using errcode='PT422',message='Seleccioná un estado válido';
    end if;
    with matches as (
      select r.id from scouting.recommendations r
      where ((v_action<>'mine' and not coalesce((v_payload->>'mine_only')::boolean,false)) or r.owner_numero_socio=v_actor)
        and (v_status is null or r.status=v_status)
        and (v_query is null or strpos(lower(concat_ws(' ',r.code,r.snapshot#>>'{player,first_name}',r.snapshot#>>'{player,last_name}',r.snapshot#>>'{club,name}')),lower(v_query))>0)
      order by r.created_at desc,r.id desc limit 26 offset v_offset
    ) select coalesce(jsonb_agg(scouting.recommendation_json(id,v_admin,v_actor)),'[]'::jsonb) into v_items from matches;
  end if;
  if v_action in ('clubs','players','feed','mine','admin_list') then
    if jsonb_array_length(v_items)>25 then v_items:=v_items-25;v_next:=(v_offset+25)::text;end if;
    return jsonb_build_object('ok',true,'items',v_items,'next_cursor',v_next);
  end if;

  if v_action='detail' then
    v_id:=nullif(v_payload->>'id','')::uuid;
    select * into v_rec from scouting.recommendations where id=v_id;
    if not found then raise exception using errcode='PT404',message='No se encontró la recomendación';end if;
    select coalesce(jsonb_agg(jsonb_build_object('id',e.id,'type',e.event_type,'status',e.status,
      'actor_role',e.actor_role,'actor_name',s.nombre,'message',e.member_message,'created_at',e.created_at,'event_hash',e.event_hash)
      order by e.sequence_no),'[]'::jsonb)
      into v_events from scouting.events e join public.socios s on s.numero_socio=e.actor_numero_socio where e.recommendation_id=v_id;
    return jsonb_build_object('ok',true,'recommendation',scouting.recommendation_json(v_id,v_admin,v_actor),
      'events',v_events,'proof',scouting.proof_json(v_id));
  end if;

  -- Serialize all writes by actor, then lock the selected record. Duplicate clicks
  -- and retries use the same UUID and fingerprint without adding events or quotas.
  v_request:=nullif(v_payload->>'request_id','')::uuid;
  if v_request is null then raise exception using errcode='PT422',message='Falta la identificación del envío';end if;
  v_request_hash:=encode(extensions.digest(convert_to(jsonb_build_object('action',v_action,'payload',v_payload-'request_id')::text,'UTF8'),'sha256'),'hex');
  perform pg_advisory_xact_lock(hashtextextended('scouting:actor:'||v_actor::text,0));
  select * into v_previous_request from scouting.requests where actor_numero_socio=v_actor and request_id=v_request;
  if found then
    if v_previous_request.action<>v_action or v_previous_request.request_hash<>v_request_hash then
      raise exception using errcode='PT409',message='Ese envío ya se usó con otros datos. Iniciá un nuevo envío';
    end if;
    return jsonb_build_object('ok',true,'recommendation',scouting.recommendation_json(v_previous_request.recommendation_id,v_admin,v_actor),'replayed',true);
  end if;

  if v_action='create' then
    if (select count(*) from scouting.recommendations where owner_numero_socio=v_actor and created_at>clock_timestamp()-interval '24 hours')>=20 then
      raise exception using errcode='PT429',message='Alcanzaste el límite de 20 recomendaciones en 24 horas';
    end if;
    v_club_id:=nullif(v_payload->>'club_id','')::uuid;
    v_competition:=scouting.text_value(v_payload->'competition_id',0,60,'competencia',true);
    v_category:=scouting.text_value(v_payload->'category',2,100,'categoría');
    if lower(v_category)='otra' then raise exception using errcode='PT422',message='Indicá el nombre de la categoría';end if;
    if v_club_id is null then
      if jsonb_typeof(v_payload->'club_manual') is distinct from 'object' then
        raise exception using errcode='PT422',message='Completá los datos de Otro club';
      end if;
      v_province:=scouting.text_value(v_payload#>'{club_manual,province}',2,100,'provincia del club');
      if not exists(select 1 from scouting.provinces where name=v_province) then
        raise exception using errcode='PT422',message='Seleccioná una provincia argentina válida';
      end if;
      if v_competition is not null then
        select * into v_comp from scouting.competitions where id=v_competition and active;
        if not found then raise exception using errcode='PT422',message='Seleccioná una competencia válida';end if;
      end if;
      v_club_json:=jsonb_build_object('id',null,'source','manual',
        'name',scouting.text_value(v_payload#>'{club_manual,name}',2,160,'nombre del club'),
        'province',v_province,'city',scouting.text_value(v_payload#>'{club_manual,city}',2,100,'ciudad del club'),
        'league',scouting.text_value(v_payload#>'{club_manual,league}',2,160,'liga del club'),
        'competition_id',v_comp.id,'competition_name',v_comp.name,'division',null,
        'season',v_comp.season,'reference_scope','declarado_por_socio','provenance','member_submission');
    else
      select * into v_club from scouting.clubs where id=v_club_id and active;
      if not found then raise exception using errcode='PT422',message='El club seleccionado no está disponible';end if;
      if v_competition is not null and not exists(select 1 from scouting.club_competitions where club_id=v_club_id and competition_id=v_competition) then
        raise exception using errcode='PT422',message='La competencia no corresponde al club seleccionado';
      end if;
      select c.* into v_comp from scouting.club_competitions cc join scouting.competitions c on c.id=cc.competition_id
        where cc.club_id=v_club_id and c.active and (v_competition is null or c.id=v_competition)
        order by cc.season desc,c.sort_order limit 1;
      v_club_json:=jsonb_build_object('id',v_club.id,'source','catalogue','name',v_club.name,'province',v_club.province,
        'city',v_club.city,'league',v_club.league,'competition_id',v_comp.id,'competition_name',v_comp.name,
        'division',(select division from scouting.club_competitions where club_id=v_club_id and competition_id=v_comp.id order by season desc limit 1),
        'season',(select season from scouting.club_competitions where club_id=v_club_id and competition_id=v_comp.id order by season desc limit 1),
        'reference_scope',(select reference_scope from scouting.club_competitions where club_id=v_club_id and competition_id=v_comp.id order by season desc limit 1),
        'provenance',v_club.source,'source_urls',v_club.source_urls,'verified_at',v_club.checked_at);
    end if;

    v_player_id:=nullif(v_payload->>'player_id','')::uuid;
    v_position:=scouting.text_value(v_payload#>'{player,position}',2,60,'posición');
    if not(v_position=any(v_positions)) then raise exception using errcode='PT422',message='Seleccioná una posición válida';end if;
    v_sector:=coalesce(scouting.text_value(v_payload#>'{player,sector}',0,30,'sector',true),'no_especificado');
    if v_sector not in ('derecha','izquierda','ambos','no_especificado') then raise exception using errcode='PT422',message='Seleccioná un sector válido';end if;
    if v_position not in ('Lateral','Delantero Extremo') then v_sector:='no_especificado';end if;
    if v_player_id is not null then
      select * into v_player from scouting.players where id=v_player_id and active and club_id=v_club_id;
      if not found then raise exception using errcode='PT422',message='El jugador no corresponde al club seleccionado';end if;
      if v_player.category<>v_category then raise exception using errcode='PT422',message='La categoría no corresponde al jugador seleccionado';end if;
      v_player_json:=jsonb_build_object('id',v_player.id,'first_name',v_player.first_name,'last_name',v_player.last_name,
        'position',v_position,'sector',v_sector,'source','catalogue','verified_at',v_player.checked_at);
    else
      v_player_json:=jsonb_build_object('id',null,'first_name',scouting.text_value(v_payload#>'{player,first_name}',2,100,'nombre del jugador'),
        'last_name',scouting.text_value(v_payload#>'{player,last_name}',2,100,'apellido del jugador'),
        'position',v_position,'sector',v_sector,'source','manual');
    end if;
    v_reason:=scouting.text_value(v_payload->'reason',20,4000,'motivo de la recomendación');
    v_observation:=scouting.text_value(v_payload->'observation',0,2000,'contexto de observación',true);
    v_video:=scouting.url_value(v_payload->'video_url','video');
    v_tm:=scouting.url_value(v_payload->'transfermarkt_url','transfermarkt');
    v_snapshot:=jsonb_build_object('schema_version',1,'category',v_category,'club',v_club_json,'player',v_player_json,
      'reason',v_reason,'observation',v_observation,'video_url',v_video,'transfermarkt_url',v_tm,
      'source',case when v_player_id is null then 'manual' else 'catalogue' end);
    v_id:=gen_random_uuid();v_nonce:=encode(extensions.gen_random_bytes(32),'hex');
    v_hash:=encode(extensions.digest(convert_to(jsonb_build_object('schema','scouting-recommendation-v1','id',v_id,'owner',v_actor,'snapshot',v_snapshot,'nonce',v_nonce)::text,'UTF8'),'sha256'),'hex');
    v_code:='SC-'||upper(substr(replace(v_id::text,'-',''),1,12));
    insert into scouting.recommendations(id,code,owner_numero_socio,snapshot,private_nonce,commitment_hash)
      values(v_id,v_code,v_actor,v_snapshot,v_nonce,v_hash);
    perform scouting.append_event(v_id,v_actor,v_role,'created','recibida','Recomendación recibida');
  else
    v_id:=nullif(v_payload->>'id','')::uuid;
    select * into v_rec from scouting.recommendations where id=v_id and
      ((v_action='add_info' and owner_numero_socio=v_actor) or (v_action in ('admin_update','admin_validate_club') and v_admin)) for update;
    if not found then raise exception using errcode='PT404',message='No se encontró la recomendación';end if;
    v_message:=scouting.text_value(v_payload->'message',2,4000,'mensaje');
    if v_action='admin_validate_club' then
      if v_rec.snapshot#>>'{club,source}' is distinct from 'manual' then
        raise exception using errcode='PT409',message='El club de esta recomendación ya pertenece al catálogo';
      end if;
      if exists(select 1 from scouting.club_validations where recommendation_id=v_id) then
        raise exception using errcode='PT409',message='El club de esta recomendación ya fue validado';
      end if;
      v_club_json:=v_rec.snapshot->'club';
      perform pg_advisory_xact_lock(hashtextextended('scouting:club:'||
        (v_club_json->>'province')||':'||lower(v_club_json->>'city')||':'||lower(v_club_json->>'name'),0));
      select id into v_club_id from scouting.clubs where province=v_club_json->>'province'
        and lower(city)=lower(v_club_json->>'city') and lower(name)=lower(v_club_json->>'name');
      if not found then
        insert into scouting.clubs(source_key,name,province,city,league,source,checked_at)
          values('manual:'||v_id::text,v_club_json->>'name',v_club_json->>'province',v_club_json->>'city',
            v_club_json->>'league','verified_manual',clock_timestamp()) returning id into v_club_id;
        if v_club_json->>'competition_id' is not null then
          insert into scouting.club_competitions(club_id,competition_id,season,reference_scope,checked_at)
            select v_club_id,c.id,c.season,'declarado_por_socio_validado',clock_timestamp() from scouting.competitions c
              where c.id=v_club_json->>'competition_id' and c.active;
        end if;
      end if;
      insert into scouting.club_validations(recommendation_id,club_id,actor_numero_socio,reason)
        values(v_id,v_club_id,v_actor,v_message);
      perform scouting.append_event(v_id,v_actor,v_role,'club_validated',v_rec.status,
        'Club validado e incorporado o vinculado al catálogo. Motivo: '||v_message);
      update scouting.recommendations set updated_at=clock_timestamp() where id=v_id;
    elsif v_action='add_info' then
      if v_rec.status='cerrada' then raise exception using errcode='PT409',message='La recomendación está cerrada';end if;
      perform scouting.append_event(v_id,v_actor,v_role,'information_added',v_rec.status,v_message);
      update scouting.recommendations set updated_at=clock_timestamp() where id=v_id;
    else
      v_status:=scouting.text_value(v_payload->'status',2,40,'estado');
      if v_status not in ('recibida','en_revision','informacion_solicitada','en_seguimiento','cerrada') then
        raise exception using errcode='PT422',message='Seleccioná un estado válido';
      end if;
      -- Reopening is deliberate and auditable; the member-visible message is required.
      perform scouting.append_event(v_id,v_actor,v_role,'status_updated',v_status,v_message);
      update scouting.recommendations set status=v_status,updated_at=clock_timestamp() where id=v_id;
    end if;
  end if;
  insert into scouting.requests(actor_numero_socio,request_id,action,request_hash,recommendation_id)
    values(v_actor,v_request,v_action,v_request_hash,v_id);
  return jsonb_build_object('ok',true,'recommendation',scouting.recommendation_json(v_id,v_admin,v_actor),'replayed',false);
exception
  when invalid_text_representation or numeric_value_out_of_range or check_violation then
    raise exception using errcode='PT422',message='Revisá los datos del formulario';
end;
$$;

revoke all on all functions in schema scouting from public, anon, authenticated, service_role;
revoke all on all tables in schema scouting from public, anon, authenticated, service_role;
revoke all on all sequences in schema scouting from public, anon, authenticated, service_role;
revoke all on function public.scouting_api(text,text,jsonb) from public, anon, authenticated;
grant execute on function public.scouting_api(text,text,jsonb) to service_role;

comment on function public.scouting_api(text,text,jsonb) is
  'Service-only RPC for authenticated club scouting. Validates custom session and server-side roles on every call; records only opaque commitments in shared audit.';
