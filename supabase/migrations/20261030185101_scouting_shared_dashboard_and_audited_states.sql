-- Shared scouting dashboard; prepared from live functions on 2026-10-30.
-- Apply in one transaction. No historical snapshot/event or session policy is rewritten.
set local lock_timeout='5s';
set local statement_timeout='60s';

do $baseline$
begin
  if md5(pg_get_functiondef('public.scouting_api(text,text,jsonb)'::regprocedure))<>'972089e8df055deb7d23884704c38d22'
    or md5(pg_get_functiondef('scouting.recommendation_json(uuid,boolean,bigint)'::regprocedure))<>'2df554744055a60d2dd993b35ddb3299'
    or md5(pg_get_functiondef('scouting.append_event(uuid,bigint,text,text,text,text)'::regprocedure))<>'a3644cb3889bd6a7522c8657e0595b82'
    or md5(pg_get_functiondef('scouting.protect_recommendation()'::regprocedure))<>'b00e02fe4dcaa3762d05e196c9ca8d94' then
    raise exception 'Scouting functions changed since review; rebase the dashboard patch on the current definitions';
  end if;
end;
$baseline$;

alter table scouting.recommendations drop constraint recommendations_status_check;
alter table scouting.recommendations add constraint recommendations_status_check check(status in ('recibida','en_revision','informacion_solicitada','en_seguimiento','contactado','visitado','convocado_a_prueba','prueba_realizada','no_avanza','cerrada'));
alter table scouting.events drop constraint events_status_check;
alter table scouting.events add constraint events_status_check check(status in ('recibida','en_revision','informacion_solicitada','en_seguimiento','contactado','visitado','convocado_a_prueba','prueba_realizada','no_avanza','cerrada'));
alter table scouting.events
  add column previous_status text,
  add column hash_version smallint not null default 1,
  add constraint events_previous_status_check check(previous_status is null or previous_status in ('recibida','en_revision','informacion_solicitada','en_seguimiento','contactado','visitado','convocado_a_prueba','prueba_realizada','no_avanza','cerrada')),
  add constraint events_hash_version_check check(hash_version in (1,2)),
  add constraint events_previous_status_v2_check check(hash_version=1 or
    (event_type='created' and previous_status is null) or
    (event_type<>'created' and previous_status is not null));

alter table scouting.players
  add column birth_date date,
  add column birth_date_source_url text,
  add column birth_date_verified_at timestamptz,
  add column market_value_amount numeric(18,2),
  add column market_value_currency text,
  add column market_value_source_url text,
  add column market_value_as_of date,
  add column market_value_verified_at timestamptz,
  add column market_value_verified boolean not null default false,
  add constraint players_birth_date_check check(birth_date is null or
    (birth_date>=date '1900-01-01' and birth_date<=(current_timestamp at time zone 'America/Argentina/Cordoba')::date)),
  add constraint players_birth_date_evidence_check check(birth_date is null or
    (birth_date_source_url is not null and birth_date_verified_at is not null)),
  add constraint players_birth_date_source_check check(birth_date_source_url is null or
    (char_length(birth_date_source_url)<=2048 and birth_date_source_url ~ '^https://' and birth_date_source_url !~ '[[:space:]\\]')),
  add constraint players_market_value_amount_check check(market_value_amount is null or market_value_amount>=0),
  add constraint players_market_value_currency_check check(market_value_currency is null or market_value_currency ~ '^[A-Z]{3}$'),
  add constraint players_market_value_source_url_check check(market_value_source_url is null or (
    char_length(market_value_source_url)<=2048 and market_value_source_url !~ '[[:space:]\\]'
    and market_value_source_url ~ '^https://(www\.)?transfermarkt\.(com|com\.ar|es|de|co\.uk|it|fr|pt|nl)/[a-zA-Z0-9_/%.-]+/profil/spieler/[0-9]+(/[^?#]*)?(\?[^#]*)?(#.*)?$')),
  add constraint players_market_value_verified_check check(not market_value_verified or (
    market_value_amount is not null and market_value_currency is not null and market_value_source_url is not null
    and market_value_as_of is not null and market_value_verified_at is not null
    and market_value_as_of<=(current_timestamp at time zone 'America/Argentina/Cordoba')::date));

-- The dashboard reads every recommendation, not one 25-row page. This partial
-- index restricts historical milestone aggregation to the five relevant statuses.
create index scouting_events_dashboard_milestones_idx on scouting.events(status,recommendation_id)
  where event_type='status_updated' and status in ('contactado','visitado','convocado_a_prueba','prueba_realizada','no_avanza');

-- Only server-written immutable snapshots feed this identity function. Independent
-- manual submissions retain separate identities; an explicit reference is a member
-- declaration, not catalogue verification or a name-based match.
create function scouting.player_identity_key(p_snapshot jsonb,p_recommendation_id uuid)
returns text language sql immutable security invoker set search_path=pg_catalog as $identity$
  select case when p_snapshot#>>'{player,source}'='catalogue'
    and p_snapshot#>>'{player,id}' ~ '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$'
    then 'catalogue:'||lower(p_snapshot#>>'{player,id}')
    when p_snapshot#>>'{player,reference_id}' ~ '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$'
    then 'reference:'||lower(p_snapshot#>>'{player,reference_id}')
    else 'reference:'||p_recommendation_id::text end;
$identity$;

create function scouting.player_age(p_birth_date date,p_on_date date)
returns integer language sql immutable security invoker set search_path=pg_catalog as $age$
  select case when p_birth_date is not null and p_on_date is not null
    and extract(year from age(p_on_date,p_birth_date)) between 1 and 100
    then extract(year from age(p_on_date,p_birth_date))::integer end;
$age$;

create function scouting.player_market_value(p_player scouting.players)
returns jsonb language sql immutable security invoker set search_path=pg_catalog as $market$
  select case when p_player.market_value_verified
    and p_player.market_value_amount is not null and p_player.market_value_currency is not null
    and p_player.market_value_source_url is not null and p_player.market_value_as_of is not null
    and p_player.market_value_verified_at is not null then
    jsonb_build_object('amount',p_player.market_value_amount,'currency',p_player.market_value_currency,
      'source','Transfermarkt','source_url',p_player.market_value_source_url,
      'as_of',p_player.market_value_as_of,'verified_at',p_player.market_value_verified_at,'verification','verified')
    else null end;
$market$;

create function scouting.dashboard_json()
returns jsonb language sql stable security invoker set search_path=pg_catalog as $dashboard$
  with milestones as (
    select e.recommendation_id,
      bool_or(e.status='contactado') as contacted,
      bool_or(e.status='visitado') as visited,
      bool_or(e.status='convocado_a_prueba') as invited_to_trial,
      bool_or(e.status='prueba_realizada') as trial_completed,
      bool_or(e.status='no_avanza') as not_advanced
    from scouting.events e
    where e.event_type='status_updated' and e.status in ('contactado','visitado','convocado_a_prueba','prueba_realizada','no_avanza')
    group by e.recommendation_id
  ), player_references as (
    select r.id,r.status,r.snapshot,r.owner_numero_socio,r.created_at,
      scouting.player_identity_key(r.snapshot,r.id) as identity_key,
      scouting.player_identity_key(r.snapshot,r.id) like 'catalogue:%' as identified,
      coalesce(m.contacted,false) as contacted,
      coalesce(m.visited,false) as visited,
      coalesce(m.invited_to_trial,false) as invited_to_trial,
      coalesce(m.trial_completed,false) as trial_completed,
      coalesce(m.not_advanced,false) as not_advanced
    from scouting.recommendations r left join milestones m on m.recommendation_id=r.id
  ), ranked as (
    select identity_key,count(*) as recommendation_count,
      count(distinct owner_numero_socio) as unique_recommenders_count,max(created_at) as latest_at
    from player_references group by identity_key having count(*)>=2
    order by count(*) desc,max(created_at) desc,identity_key limit 10
  )
  select jsonb_build_object(
    'total_recommendations',count(*),
    'identified_players',count(distinct identity_key) filter(where identified),
    'unverified_player_references',count(distinct identity_key) filter(where not identified),
    'manual_recommendations',count(*) filter(where not identified),
    'total_player_references',count(distinct identity_key),
    'contacted',count(distinct identity_key) filter(where contacted),
    'visited',count(distinct identity_key) filter(where visited),
    'invited_to_trial',count(distinct identity_key) filter(where invited_to_trial),
    'trial_completed',count(distinct identity_key) filter(where trial_completed),
    'not_advanced',count(distinct identity_key) filter(where not_advanced),
    'milestone_recommendations',jsonb_build_object(
      'contacted',count(*) filter(where contacted),
      'visited',count(*) filter(where visited),
      'invited_to_trial',count(*) filter(where invited_to_trial),
      'trial_completed',count(*) filter(where trial_completed),
      'not_advanced',count(*) filter(where not_advanced)),
    'counts_by_status',(select jsonb_object_agg(s.status,(select count(*) from player_references rr where rr.status=s.status))
      from unnest(array['recibida','en_revision','informacion_solicitada','en_seguimiento','contactado','visitado','convocado_a_prueba','prueba_realizada','no_avanza','cerrada']) as s(status)),
    'counts_by_status_unit','recommendations',
    'most_recommended_players',(select coalesce(jsonb_agg(jsonb_build_object(
        'identity_type',case when latest.identified then 'catalogue' else 'member_reference' end,
        'player_id',case when latest.identified then latest.snapshot#>>'{player,id}' end,
        'reference_recommendation_id',latest.id,
        'identity_verification',case when latest.identified then 'catalogue' else 'member_declared' end,
        'recommendation_count',g.recommendation_count,'unique_recommenders_count',g.unique_recommenders_count,
        'player',jsonb_build_object('age_at_recommendation',null,'age_source',null,'age_source_url',null,'age_verified_at',null,'market_value',null)
          ||coalesce(latest.snapshot->'player','{}'::jsonb)
          ||jsonb_build_object('reference_id',case when not latest.identified then split_part(g.identity_key,':',2) end,
            'identity_verification',case when latest.identified then 'catalogue' else 'member_declared' end),
        'club',latest.snapshot->'club',
        'latest_recommendation',jsonb_build_object('id',latest.id,'created_at',latest.created_at,'status',latest.status))
        order by g.recommendation_count desc,g.latest_at desc,g.identity_key),'[]'::jsonb)
      from ranked g cross join lateral (
        select rr.* from player_references rr where rr.identity_key=g.identity_key
        order by rr.created_at desc,rr.id desc limit 1
      ) latest),
    'as_of',statement_timestamp(),'scope','all_recommendations',
    'milestone_unit','player_references','player_count_basis','catalogue_identity_or_explicit_member_reference'
  ) from player_references;
$dashboard$;
revoke all on function scouting.player_identity_key(jsonb,uuid),scouting.player_age(date,date),scouting.player_market_value(scouting.players),scouting.dashboard_json()
  from public,anon,authenticated,service_role;

CREATE FUNCTION scouting.event_proof_json(p_event_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
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
  select * into v_event from scouting.events where id=p_event_id;
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
$function$
;
revoke all on function scouting.event_proof_json(uuid) from public,anon,authenticated,service_role;

CREATE OR REPLACE FUNCTION scouting.append_event(p_recommendation_id uuid, p_actor bigint, p_role text, p_type text, p_status text, p_message text)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
declare
  v_rec scouting.recommendations%rowtype;
  v_id uuid:=gen_random_uuid();
  v_nonce text:=encode(extensions.gen_random_bytes(32),'hex');
  v_previous text;
  v_previous_status text;
  v_sequence integer;
  v_created timestamptz:=clock_timestamp();
  v_hash text;
  v_audit bigint;
  v_context text:=current_setting('app.actor_socio',true);
begin
  select * into strict v_rec from scouting.recommendations where id=p_recommendation_id for update;
  v_previous_status:=case when p_type='created' then null else v_rec.status end;
  select event_hash,sequence_no+1 into v_previous,v_sequence from scouting.events
    where recommendation_id=p_recommendation_id order by sequence_no desc limit 1;
  v_sequence:=coalesce(v_sequence,1);
  v_hash:=encode(extensions.digest(convert_to(jsonb_build_object(
    'schema','scouting-event-v2','id',v_id,'recommendation_id',p_recommendation_id,
    'sequence',v_sequence,'actor',p_actor,'role',p_role,'type',p_type,'previous_status',v_previous_status,'status',p_status,
    'message',p_message,'created_at',to_char(v_created at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'original_commitment',v_rec.commitment_hash,'previous',v_previous,'nonce',v_nonce
  )::text,'UTF8'),'sha256'),'hex');

  -- The shared audit function normally resolves actor names. Its context is
  -- suppressed only for this call: the identity, nonce and content remain private.
  perform set_config('app.actor_socio','',true);
  v_audit:=public.registrar_auditoria_interna(
    'SCOUTING_'||upper(p_type),'scouting_commitment',v_id::text,null,
    jsonb_build_object('schema','scouting-event-v2','commitment_sha256',v_hash),
    null,jsonb_build_object('modulo','scouting','version',2),'scouting_api'
  );
  perform set_config('app.actor_socio',coalesce(v_context,''),true);

  insert into scouting.events(id,recommendation_id,sequence_no,actor_numero_socio,actor_role,event_type,status,
    member_message,created_at,private_nonce,prev_hash,event_hash,audit_event_id,previous_status,hash_version)
  values(v_id,p_recommendation_id,v_sequence,p_actor,p_role,p_type,p_status,p_message,
    v_created,v_nonce,v_previous,v_hash,v_audit,v_previous_status,2);
  return v_id;
exception when others then
  perform set_config('app.actor_socio',coalesce(v_context,''),true);
  raise;
end;
$function$
;

CREATE OR REPLACE FUNCTION scouting.recommendation_json(p_id uuid, p_admin boolean DEFAULT false, p_actor bigint DEFAULT NULL::bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  select r.snapshot || jsonb_build_object(
    'id',r.id,'code',r.code,'created_at',r.created_at,'updated_at',r.updated_at,
    'status',r.status,'commitment_hash',r.commitment_hash,
    'author',jsonb_build_object('numero_socio',r.owner_numero_socio,'name',(select s.nombre from public.socios s where s.numero_socio=r.owner_numero_socio)),
    'player',jsonb_build_object('age_at_recommendation',null,'age_source',null,'age_source_url',null,'age_verified_at',null,'market_value',null)
      ||coalesce(r.snapshot->'player','{}'::jsonb)
      ||jsonb_build_object('reference_id',case when scouting.player_identity_key(r.snapshot,r.id) like 'reference:%'
          then split_part(scouting.player_identity_key(r.snapshot,r.id),':',2) end,
        'identity_verification',case when scouting.player_identity_key(r.snapshot,r.id) like 'catalogue:%' then 'catalogue' else 'member_declared' end),
    'can_add_info',coalesce(p_actor=r.owner_numero_socio and r.status<>'cerrada',false),'can_manage',p_admin,
    'club_validated',exists(select 1 from scouting.club_validations cv where cv.recommendation_id=r.id),
    'audit_event_id',(select e.audit_event_id from scouting.events e where e.recommendation_id=r.id order by e.sequence_no limit 1)
  )
  from scouting.recommendations r where r.id=p_id;
$function$
;

CREATE OR REPLACE FUNCTION public.scouting_api(p_token text, p_action text, p_payload jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
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
  v_filter_player_id uuid;
  v_filter_reference_id uuid;
  v_filter_identity_key text;
  v_reference_recommendation_id uuid;
  v_reference_rec scouting.recommendations%rowtype;
  v_reference_identity_key text;
  v_member_reference_id uuid;
  v_age integer;
  v_age_input jsonb;
  v_age_source text;
  v_today date := (clock_timestamp() at time zone 'America/Argentina/Cordoba')::date;
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
  if v_action not in ('bootstrap','dashboard','event_proof','clubs','players','create','feed','mine','detail','add_info','admin_list','admin_update','admin_validate_club') then
    raise exception using errcode='PT422',message='La operación solicitada no está disponible';
  end if;
  if v_action in ('admin_list','admin_update','admin_validate_club') and not v_admin then
    raise exception using errcode='PT403',message='Esta operación requiere un administrador habilitado';
  end if;
  if nullif(v_payload->>'internal_note','') is not null then
    raise exception using errcode='PT422',message='Las devoluciones de scouting son visibles para todos los socios. Usá el campo mensaje';
  end if;

  if v_action='dashboard' then
    return jsonb_build_object('ok',true,'dashboard',scouting.dashboard_json());
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
          where mx.club_id=c.id and cx.active and mx.season=cx.season),'[]'::jsonb) as competitions
      from scouting.clubs c
      left join lateral (select m.* from scouting.club_competitions m
        join scouting.competitions current_comp on current_comp.id=m.competition_id
        where m.club_id=c.id and current_comp.active and m.season=current_comp.season
          and (v_competition is null or m.competition_id=v_competition)
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
      select p.id,p.first_name,p.last_name,p.category,p.position,p.transfermarkt_url,p.checked_at,
        scouting.player_age(p.birth_date,v_today) as age_at_recommendation,
        scouting.player_age(p.birth_date,v_today) as age_current,v_today as age_as_of,
        case when scouting.player_age(p.birth_date,v_today) is not null then 'catalogue_birth_date' end as age_source,
        case when scouting.player_age(p.birth_date,v_today) is not null then p.birth_date_source_url end as age_source_url,
        case when scouting.player_age(p.birth_date,v_today) is not null then p.birth_date_verified_at end as age_verified_at,
        scouting.player_market_value(p) as market_value
      from scouting.players p
      where p.active and p.club_id=v_club_id and (v_category is null or category=v_category)
        and (v_query is null or strpos(lower(first_name||' '||last_name),lower(v_query))>0)
      order by lower(last_name),lower(first_name),id limit 26 offset v_offset
    ) select coalesce(jsonb_agg(to_jsonb(matches)),'[]'::jsonb) into v_items from matches;
  elsif v_action in ('feed','mine','admin_list') then
    if v_payload ? 'mine_only' and jsonb_typeof(v_payload->'mine_only')<>'boolean' then
      raise exception using errcode='PT422',message='El filtro de autor no es válido';
    end if;
    v_filter_player_id:=nullif(v_payload->>'player_id','')::uuid;
    v_filter_reference_id:=nullif(v_payload->>'reference_recommendation_id','')::uuid;
    if v_filter_reference_id is not null then
      select scouting.player_identity_key(r.snapshot,r.id) into v_filter_identity_key
        from scouting.recommendations r where r.id=v_filter_reference_id;
      if not found then raise exception using errcode='PT404',message='No se encontró la recomendación de referencia';end if;
    end if;
    v_status:=scouting.text_value(v_payload->'status',0,40,'estado',true);
    if v_status is not null and v_status not in ('recibida','en_revision','informacion_solicitada','en_seguimiento','contactado','visitado','convocado_a_prueba','prueba_realizada','no_avanza','cerrada') then
      raise exception using errcode='PT422',message='Seleccioná un estado válido';
    end if;
    with matches as (
      select r.id from scouting.recommendations r
      where ((v_action<>'mine' and not coalesce((v_payload->>'mine_only')::boolean,false)) or r.owner_numero_socio=v_actor)
        and (v_status is null or r.status=v_status)
        and (v_filter_player_id is null or (r.snapshot#>>'{player,source}'='catalogue'
          and lower(r.snapshot#>>'{player,id}')=v_filter_player_id::text))
        and (v_filter_identity_key is null or scouting.player_identity_key(r.snapshot,r.id)=v_filter_identity_key)
        and (v_query is null or strpos(lower(concat_ws(' ',r.code,r.snapshot#>>'{player,first_name}',r.snapshot#>>'{player,last_name}',r.snapshot#>>'{club,name}')),lower(v_query))>0)
      order by r.created_at desc,r.id desc limit 26 offset v_offset
    ) select coalesce(jsonb_agg(scouting.recommendation_json(id,v_admin,v_actor)),'[]'::jsonb) into v_items from matches;
  end if;
  if v_action in ('clubs','players','feed','mine','admin_list') then
    if jsonb_array_length(v_items)>25 then v_items:=v_items-25;v_next:=(v_offset+25)::text;end if;
    return jsonb_build_object('ok',true,'items',v_items,'next_cursor',v_next);
  end if;

  if v_action='event_proof' then
    v_id:=nullif(v_payload->>'event_id','')::uuid;
    if v_id is null or not exists(select 1 from scouting.events where id=v_id) then
      raise exception using errcode='PT404',message='No se encontró la actuación';
    end if;
    return jsonb_build_object('ok',true,'event_id',v_id,'proof',scouting.event_proof_json(v_id));
  end if;

  if v_action='detail' then
    v_id:=nullif(v_payload->>'id','')::uuid;
    select * into v_rec from scouting.recommendations where id=v_id;
    if not found then raise exception using errcode='PT404',message='No se encontró la recomendación';end if;
    with history as (
      select e.*,lag(e.status) over(order by e.sequence_no) as preceding_status
      from scouting.events e where e.recommendation_id=v_id
    )
    select coalesce(jsonb_agg(jsonb_build_object('id',e.id,'type',e.event_type,'status',e.status,
      'actor_role',e.actor_role,'actor_name',s.nombre,'actor_numero_socio',e.actor_numero_socio,
      'actor',jsonb_build_object('numero_socio',e.actor_numero_socio,'name',s.nombre,'role',e.actor_role),
      'previous_status',case when e.hash_version=2 then e.previous_status when e.event_type='created' then null else e.preceding_status end,
      'new_status',e.status,'hash_version',e.hash_version,
      'previous_status_source',case when e.hash_version=2 then 'recorded' else 'event_sequence' end,
      'audit_event_id',e.audit_event_id,'commitment_hash',e.event_hash,
      'message',e.member_message,'created_at',e.created_at,'event_hash',e.event_hash)
      order by e.sequence_no),'[]'::jsonb)
      into v_events from history e join public.socios s on s.numero_socio=e.actor_numero_socio;
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
    -- UI-flow contract only: authorization still comes from the validated member session.
    -- Replays above remain valid and never create a second record.
    if v_payload->>'panel_context' is distinct from 'socio' then
      raise exception using errcode='PT403',message='Para recomendar, abrí Scouting desde tu panel Socio Activo';
    end if;
    if nullif(v_payload->'market_value','null'::jsonb) is not null
      or nullif(v_payload#>'{player,market_value}','null'::jsonb) is not null then
      raise exception using errcode='PT422',message='El valor de mercado sólo se obtiene de una referencia verificada del catálogo';
    end if;
    if nullif(v_payload#>'{player,reference_id}','null'::jsonb) is not null then
      raise exception using errcode='PT422',message='La identidad compartida se elige desde una recomendación existente';
    end if;
    v_reference_recommendation_id:=nullif(v_payload->>'reference_recommendation_id','')::uuid;
    if v_reference_recommendation_id is not null then
      select * into v_reference_rec from scouting.recommendations where id=v_reference_recommendation_id;
      if not found then raise exception using errcode='PT404',message='No se encontró la recomendación de referencia';end if;
      v_reference_identity_key:=scouting.player_identity_key(v_reference_rec.snapshot,v_reference_rec.id);
      if v_reference_identity_key like 'reference:%' then
        v_member_reference_id:=split_part(v_reference_identity_key,':',2)::uuid;
      end if;
    end if;
    if nullif(v_payload#>'{player,age_at_recommendation}','null'::jsonb) is not null
      and nullif(v_payload->'age_at_recommendation','null'::jsonb) is not null
      and v_payload#>'{player,age_at_recommendation}' is distinct from v_payload->'age_at_recommendation' then
      raise exception using errcode='PT422',message='La edad informada no coincide entre los campos del formulario';
    end if;
    v_age_input:=coalesce(nullif(v_payload#>'{player,age_at_recommendation}','null'::jsonb),
      nullif(v_payload->'age_at_recommendation','null'::jsonb));
    if v_age_input is not null then
      if jsonb_typeof(v_age_input)<>'number' or v_age_input#>>'{}' !~ '^[0-9]{1,3}$' then
        raise exception using errcode='PT422',message='La edad debe ser un número entero de años';
      end if;
      v_age:=(v_age_input#>>'{}')::integer;
      if v_age not between 1 and 100 then
        raise exception using errcode='PT422',message='La edad debe estar entre 1 y 100 años';
      end if;
      v_age_source:='member_reported';
    end if;
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
      select c.* into v_comp from scouting.club_competitions cc join scouting.competitions c on c.id=cc.competition_id
        where cc.club_id=v_club_id and c.active and cc.season=c.season
          and (v_competition is null or c.id=v_competition)
        order by cc.season desc,c.sort_order limit 1;
      if v_competition is not null and not found then
        raise exception using errcode='PT422',message='La competencia no corresponde al club en su temporada vigente';
      end if;
      v_club_json:=jsonb_build_object('id',v_club.id,'source','catalogue','name',v_club.name,'province',v_club.province,
        'city',v_club.city,'league',v_club.league,'competition_id',v_comp.id,'competition_name',v_comp.name,
        'division',(select division from scouting.club_competitions where club_id=v_club_id and competition_id=v_comp.id and season=v_comp.season),
        'season',v_comp.season,
        'reference_scope',(select reference_scope from scouting.club_competitions where club_id=v_club_id and competition_id=v_comp.id and season=v_comp.season),
        'provenance',v_club.source,'source_urls',v_club.source_urls,'verified_at',v_club.checked_at);
    end if;

    v_id:=gen_random_uuid();
    v_player_id:=nullif(v_payload->>'player_id','')::uuid;
    if v_reference_recommendation_id is not null then
      if v_reference_identity_key like 'catalogue:%' then
        if v_player_id is not null and v_player_id<>split_part(v_reference_identity_key,':',2)::uuid then
          raise exception using errcode='PT422',message='El jugador seleccionado no coincide con la recomendación de referencia';
        end if;
        v_player_id:=split_part(v_reference_identity_key,':',2)::uuid;
      elsif v_player_id is not null then
        raise exception using errcode='PT422',message='Para elegir otro jugador, iniciá una recomendación nueva sin referencia';
      end if;
    end if;
    v_position:=scouting.text_value(v_payload#>'{player,position}',2,60,'posición');
    if not(v_position=any(v_positions)) then raise exception using errcode='PT422',message='Seleccioná una posición válida';end if;
    v_sector:=coalesce(scouting.text_value(v_payload#>'{player,sector}',0,30,'sector',true),'no_especificado');
    if v_sector not in ('derecha','izquierda','ambos','no_especificado') then raise exception using errcode='PT422',message='Seleccioná un sector válido';end if;
    if v_position not in ('Lateral','Delantero Extremo') then v_sector:='no_especificado';end if;
    if v_player_id is not null then
      select * into v_player from scouting.players where id=v_player_id and active and club_id=v_club_id;
      if not found then raise exception using errcode='PT422',message='El jugador no corresponde al club seleccionado';end if;
      if v_player.category<>v_category then raise exception using errcode='PT422',message='La categoría no corresponde al jugador seleccionado';end if;
      if scouting.player_age(v_player.birth_date,v_today) is not null then
        v_age:=scouting.player_age(v_player.birth_date,v_today);
        v_age_source:='catalogue_birth_date';
      end if;
      v_player_json:=jsonb_build_object('id',v_player.id,'first_name',v_player.first_name,'last_name',v_player.last_name,
        'position',v_position,'sector',v_sector,'source','catalogue','verified_at',v_player.checked_at,
        'age_at_recommendation',v_age,'age_source',v_age_source,
        'age_source_url',case when v_age_source='catalogue_birth_date' then v_player.birth_date_source_url end,
        'age_verified_at',case when v_age_source='catalogue_birth_date' then v_player.birth_date_verified_at end,
        'market_value',scouting.player_market_value(v_player));
    else
      v_player_json:=jsonb_build_object('id',null,
        'first_name',case when v_reference_recommendation_id is not null then v_reference_rec.snapshot#>>'{player,first_name}'
          else scouting.text_value(v_payload#>'{player,first_name}',2,100,'nombre del jugador') end,
        'last_name',case when v_reference_recommendation_id is not null then v_reference_rec.snapshot#>>'{player,last_name}'
          else scouting.text_value(v_payload#>'{player,last_name}',2,100,'apellido del jugador') end,
        'position',v_position,'sector',v_sector,'source','manual',
        'reference_id',coalesce(v_member_reference_id,v_id),'identity_verification','member_declared',
        'age_at_recommendation',v_age,'age_source',v_age_source,'age_source_url',null,'age_verified_at',null,'market_value',null);
    end if;
    v_reason:=scouting.text_value(v_payload->'reason',20,4000,'motivo de la recomendación');
    v_observation:=scouting.text_value(v_payload->'observation',0,2000,'contexto de observación',true);
    v_video:=scouting.url_value(v_payload->'video_url','video');
    v_tm:=scouting.url_value(v_payload->'transfermarkt_url','transfermarkt');
    v_snapshot:=jsonb_build_object('schema_version',1,'reference_recommendation_id',v_reference_recommendation_id,'category',v_category,'club',v_club_json,'player',v_player_json,
      'reason',v_reason,'observation',v_observation,'video_url',v_video,'transfermarkt_url',v_tm,
      'source',case when v_player_id is null then 'manual' else 'catalogue' end);
    v_nonce:=encode(extensions.gen_random_bytes(32),'hex');
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
        if v_club_json->>'competition_id' is not null
          and nullif(btrim(v_club_json->>'season'),'') is not null then
          insert into scouting.club_competitions(club_id,competition_id,season,reference_scope,checked_at)
            select v_club_id,c.id,v_club_json->>'season','declarado_por_socio_validado',clock_timestamp() from scouting.competitions c
              where c.id=v_club_json->>'competition_id';
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
      if v_status not in ('recibida','en_revision','informacion_solicitada','en_seguimiento','contactado','visitado','convocado_a_prueba','prueba_realizada','no_avanza','cerrada') then
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
$function$
;

do $verify$
begin
  if md5(pg_get_functiondef('public.scouting_api(text,text,jsonb)'::regprocedure))<>'8a135faf5ebfd96e1ac61c5e260a7536'
    or md5(pg_get_functiondef('scouting.recommendation_json(uuid,boolean,bigint)'::regprocedure))<>'487985855163bcb7d5079012839d95c7' then
    raise exception 'Installed dashboard functions differ from the reviewed definitions';
  end if;
  if not exists(select 1 from pg_proc where oid='public.scouting_api(text,text,jsonb)'::regprocedure
      and prosecdef and proconfig=array['search_path=pg_catalog'])
    or has_function_privilege('anon','public.scouting_api(text,text,jsonb)','EXECUTE')
    or has_function_privilege('authenticated','public.scouting_api(text,text,jsonb)','EXECUTE')
    or not has_function_privilege('service_role','public.scouting_api(text,text,jsonb)','EXECUTE') then
    raise exception 'Scouting RPC authorization settings changed unexpectedly';
  end if;
  if md5(pg_get_functiondef('scouting.append_event(uuid,bigint,text,text,text,text)'::regprocedure))<>'cd41be30ef05ad5e2ca0eed6550e8665'
    or md5(pg_get_functiondef('scouting.protect_recommendation()'::regprocedure))<>'b00e02fe4dcaa3762d05e196c9ca8d94'
    or md5(pg_get_functiondef('scouting.proof_json(uuid)'::regprocedure))<>'06c781243738524fab7acf7735c68398' then
    raise exception 'Audit version, historical snapshot or original proof functions differ from the reviewed change';
  end if;
  if exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='scouting' and c.relkind='r' and (not c.relrowsecurity or not c.relforcerowsecurity)) then
    raise exception 'Scouting RLS configuration changed unexpectedly';
  end if;
end;
$verify$;
