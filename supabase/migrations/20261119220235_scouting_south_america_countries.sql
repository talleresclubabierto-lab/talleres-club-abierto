-- Scouting multi-country catalogue, stable identities and country-scoped imports.
set local statement_timeout='120s';
set local lock_timeout='5s';
do $country_guard$
declare v_fingerprint text;
begin
  if md5(pg_get_functiondef('public.scouting_api(text,text,jsonb)'::regprocedure))<>'f194c6d6710ed861f55c76b7f6a63bbf'
    or md5(pg_get_functiondef('scouting.import_roster_batch(jsonb,text)'::regprocedure))<>'85c686312d06a6fa0d495fde7c995612' then
    raise exception 'Scouting API/importer changed since review; reconcile before applying';
  end if;
  select encode(extensions.digest(convert_to(jsonb_build_object(
    'provinces',(select jsonb_agg(to_jsonb(p) order by p.name) from scouting.provinces p),
    'competitions',(select jsonb_agg(to_jsonb(c) order by c.id) from scouting.competitions c))::text,'UTF8'),'sha256'),'hex') into v_fingerprint;
  if v_fingerprint<>'3a6ff43af446ea6d9790be56de66183ea9de7dc9f2117eb2f60c03b531467b67' then
    raise exception 'Existing country regions/competitions changed since review';
  end if;
end;
$country_guard$;


-- Scouting only. Existing province keys, competition IDs and person UUIDs stay stable.
alter table scouting.provinces add column country_code text not null default 'AR';
alter table scouting.provinces add constraint scouting_provinces_country_check
  check(country_code in ('AR','BR','CL','CO','EC','UY'));
update scouting.provinces set country_code=case
  when name like 'Brasil — %' then 'BR' when name like 'Chile — %' then 'CL'
  when name like 'Colombia — %' then 'CO' when name like 'Ecuador — %' then 'EC'
  when name like 'Uruguay — %' then 'UY' else 'AR' end;
alter table scouting.provinces add constraint scouting_provinces_name_country_key unique(name,country_code);

alter table scouting.competitions add column country_code text not null default 'AR';
alter table scouting.competitions add constraint scouting_competitions_country_check
  check(country_code in ('AR','BR','CL','CO','EC','UY'));
update scouting.competitions set country_code=case
  when id like 'brasil-%' then 'BR' when id like 'chile-%' then 'CL'
  when id like 'colombia-%' then 'CO' when id like 'ecuador-%' then 'EC'
  when id like 'uruguay-%' then 'UY' else 'AR' end;

alter table scouting.clubs add column country_code text not null default 'AR';
alter table scouting.clubs add constraint scouting_clubs_country_check
  check(country_code in ('AR','BR','CL','CO','EC','UY'));
update scouting.clubs c set country_code=p.country_code from scouting.provinces p where p.name=c.province;
alter table scouting.clubs drop constraint clubs_province_fkey;
alter table scouting.clubs add constraint scouting_clubs_country_region_fkey
  foreign key(province,country_code) references scouting.provinces(name,country_code);
alter table scouting.clubs alter column province drop not null;
alter table scouting.clubs alter column city drop not null;
alter table scouting.clubs add column transfermarkt_id text;
alter table scouting.clubs add constraint scouting_clubs_transfermarkt_id_check
  check(transfermarkt_id ~ '^[1-9][0-9]{0,11}$');
-- Live inventory verified one unique club TMID in source_urls for every existing club.
do $club_identity_guard$
begin
  if exists(select 1 from scouting.clubs c where
    (select count(distinct substring(u.value from '/verein/([0-9]+)'))
      from jsonb_array_elements_text(c.source_urls)u(value) where u.value ~ '/verein/[0-9]+')<>1) then
    raise exception 'Existing club Transfermarkt identity changed since review';
  end if;
end;
$club_identity_guard$;
update scouting.clubs c set transfermarkt_id=(
  select min(substring(u.value from '/verein/([0-9]+)'))
  from jsonb_array_elements_text(c.source_urls)u(value) where u.value ~ '/verein/[0-9]+');
alter table scouting.clubs add constraint scouting_clubs_transfermarkt_id_key unique(transfermarkt_id);
create index scouting_clubs_country_region_idx on scouting.clubs(country_code,province);
create index scouting_clubs_region_country_fk_idx on scouting.clubs(province,country_code);

-- A sporting mononym is an evidenced catalogue display name, not a missing manual surname.
alter table scouting.players add column name_kind text not null default 'display_name_parts';
alter table scouting.players drop constraint players_last_name_check;
alter table scouting.players add constraint scouting_players_name_kind_check check(
  (name_kind='display_name_parts' and char_length(last_name) between 2 and 100)
  or (name_kind='sporting_mononym' and last_name=''));


create function scouting.country_code_value(p_value jsonb)
returns text language plpgsql immutable set search_path=pg_catalog as $function$
declare v text;
begin
  v:=upper(coalesce(scouting.text_value(p_value,0,2,'país',true),'AR'));
  if v not in ('AR','BR','CL','CO','EC','UY') then
    raise exception using errcode='PT422',message='Seleccioná un país válido';
  end if;
  return v;
end;
$function$;
create function scouting.country_name(p_code text)
returns text language sql immutable strict set search_path=pg_catalog as $function$
  select case p_code when 'AR' then 'Argentina' when 'BR' then 'Brasil' when 'CL' then 'Chile'
    when 'CO' then 'Colombia' when 'EC' then 'Ecuador' when 'UY' then 'Uruguay' end;
$function$;
create function scouting.region_name(p_value text)
returns text language sql immutable strict set search_path=pg_catalog as $function$
  select regexp_replace(p_value,'^(Brasil|Chile|Colombia|Ecuador|Uruguay) — ','');
$function$;

create function scouting.enforce_competition_country()
returns trigger language plpgsql set search_path=pg_catalog as $function$
begin
  if (select country_code from scouting.clubs where id=new.club_id)
    is distinct from (select country_code from scouting.competitions where id=new.competition_id) then
    raise exception using errcode='23514',message='Club and competition must belong to the same country';
  end if;
  return new;
end;
$function$;
create trigger scouting_club_competition_country
  before insert or update of club_id,competition_id on scouting.club_competitions
  for each row execute function scouting.enforce_competition_country();

create function scouting.catalogue_country_fingerprints(p_country_code text)
returns jsonb language plpgsql stable set search_path=pg_catalog as $function$
declare v_country text:=scouting.country_code_value(to_jsonb(p_country_code));
begin
  return jsonb_build_object('country_code',v_country,'fingerprint_scope','country',
    'club_count',(select count(*) from scouting.clubs where country_code=v_country),
    'player_count',(select count(*) from scouting.players p join scouting.clubs c on c.id=p.club_id where c.country_code=v_country),
    'expected_clubs_sha256',(select encode(extensions.digest(convert_to(coalesce(jsonb_agg(to_jsonb(c) order by c.id),'[]'::jsonb)::text,'UTF8'),'sha256'),'hex') from scouting.clubs c where c.country_code=v_country),
    'expected_players_sha256',(select encode(extensions.digest(convert_to(coalesce(jsonb_agg(to_jsonb(p) order by p.id),'[]'::jsonb)::text,'UTF8'),'sha256'),'hex') from scouting.players p join scouting.clubs c on c.id=p.club_id where c.country_code=v_country),
    'expected_competitions_sha256',(select encode(extensions.digest(convert_to(coalesce(jsonb_agg(to_jsonb(c) order by c.id),'[]'::jsonb)::text,'UTF8'),'sha256'),'hex') from scouting.competitions c where c.country_code=v_country),
    'expected_club_competitions_sha256',(select encode(extensions.digest(convert_to(coalesce(jsonb_agg(to_jsonb(m) order by m.club_id,m.competition_id,m.season),'[]'::jsonb)::text,'UTF8'),'sha256'),'hex') from scouting.club_competitions m join scouting.clubs c on c.id=m.club_id where c.country_code=v_country));
end;
$function$;

revoke all on function scouting.country_code_value(jsonb) from public,anon,authenticated,service_role;
revoke all on function scouting.country_name(text) from public,anon,authenticated,service_role;
revoke all on function scouting.region_name(text) from public,anon,authenticated,service_role;
revoke all on function scouting.enforce_competition_country() from public,anon,authenticated,service_role;
revoke all on function scouting.catalogue_country_fingerprints(text) from public,anon,authenticated,service_role;


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
  v_country text;
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

  if v_action in ('bootstrap','clubs','players','create') then
    v_country:=scouting.country_code_value(v_payload->'country_code');
  end if;

  if v_action='dashboard' then
    return jsonb_build_object('ok',true,'dashboard',scouting.dashboard_json());
  end if;

  if v_action='bootstrap' then
    return jsonb_build_object('ok',true,'actor',jsonb_build_object('numero_socio',v_actor,'role',v_role),
      'country_code',v_country,
      'countries',(select jsonb_agg(jsonb_build_object('code',x.code,'name',scouting.country_name(x.code),'region_label',x.region_label) order by x.ord)
        from (values ('AR','Provincia',1),('BR','Estado',2),('CL','Región',3),('CO','Departamento',4),('EC','Provincia',5),('UY','Departamento',6))x(code,region_label,ord)),
      'provinces',(select coalesce(jsonb_agg(name order by name),'[]'::jsonb) from scouting.provinces where country_code=v_country),
      'regions',(select coalesce(jsonb_agg(jsonb_build_object('value',p.name,'label',scouting.region_name(p.name),
        'country_code',p.country_code,'club_count',(select count(*) from scouting.clubs c where c.active and c.country_code=v_country and c.province=p.name)) order by p.name),'[]'::jsonb)
        from scouting.provinces p where p.country_code=v_country),
      'competitions',(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'season',season,'country_code',country_code) order by sort_order,name),'[]'::jsonb)
        from scouting.competitions where active and country_code=v_country),
      'positions',to_jsonb(v_positions),'categories',to_jsonb(v_categories),
      'catalogue',jsonb_build_object('country_code',v_country,'club_count',(select count(*) from scouting.clubs where active and country_code=v_country),
        'player_count',(select count(*) from scouting.players p join scouting.clubs c on c.id=p.club_id where p.active and c.active and c.country_code=v_country),
        'provider_status','pending_authorization','catalogue_mode','reviewed_public_squads','coverage','partial_catalogue_with_squad_coverage',
        'last_verified_at',(select max(checked_at) from scouting.clubs where active and country_code=v_country)));
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
    if v_province is not null and not exists(select 1 from scouting.provinces where name=v_province
      and (v_action not in ('clubs','players') or country_code=v_country)) then
      raise exception using errcode='PT422',message='Seleccioná una región válida del país';
    end if;
    if v_action in ('clubs','players') and v_competition is not null
      and not exists(select 1 from scouting.competitions where id=v_competition and active and country_code=v_country) then
      raise exception using errcode='PT422',message='Seleccioná una competencia del país';
    end if;
  end if;

  if v_action='clubs' then
    with matches as (
      select c.id,c.name,c.province,c.city,c.league,c.checked_at,c.source,c.source_urls,
        c.country_code,scouting.country_name(c.country_code) as country_name,scouting.region_name(c.province) as region_name,
        co.id as competition_id,co.name as competition_name,cc.division,cc.season,cc.reference_scope,
        coalesce((select jsonb_agg(jsonb_build_object('id',cx.id,'name',cx.name,
          'season',mx.season,'division',mx.division,'reference_scope',mx.reference_scope,'country_code',cx.country_code) order by mx.season desc,cx.sort_order)
          from scouting.club_competitions mx join scouting.competitions cx on cx.id=mx.competition_id
          where mx.club_id=c.id and cx.active and cx.country_code=c.country_code and mx.season=cx.season),'[]'::jsonb) as competitions
      from scouting.clubs c
      left join lateral (select m.* from scouting.club_competitions m
        join scouting.competitions current_comp on current_comp.id=m.competition_id
        where m.club_id=c.id and current_comp.active and current_comp.country_code=c.country_code and m.season=current_comp.season
          and (v_competition is null or m.competition_id=v_competition)
        order by m.season desc,m.competition_id limit 1) cc on true
      left join scouting.competitions co on co.id=cc.competition_id
      where c.active and c.country_code=v_country and (v_province is null or c.province=v_province)
        and (v_competition is null or cc.competition_id=v_competition)
        and (v_query is null or strpos(lower(concat_ws(' ',c.name,c.city)),lower(v_query))>0)
      order by lower(c.name),c.id limit 26 offset v_offset
    ) select coalesce(jsonb_agg(to_jsonb(matches)),'[]'::jsonb) into v_items from matches;
  elsif v_action='players' then
    v_club_id:=nullif(v_payload->>'club_id','')::uuid;
    if v_club_id is null or not exists(select 1 from scouting.clubs where id=v_club_id and active and country_code=v_country) then
      raise exception using errcode='PT422',message='Seleccioná un club del catálogo del país';
    end if;
    if v_competition is not null and not exists(select 1 from scouting.club_competitions m
      join scouting.competitions c on c.id=m.competition_id where m.club_id=v_club_id
      and c.id=v_competition and c.active and c.country_code=v_country and m.season=c.season) then
      raise exception using errcode='PT422',message='La competencia no corresponde al club en su temporada vigente';
    end if;
    v_category:=scouting.text_value(v_payload->'category',0,100,'categoría',true);
    v_position:=scouting.text_value(v_payload->'position',0,60,'posición',true);
    if v_position is not null and v_position<>'__unknown__' and not (v_position=any(v_positions)) then
      raise exception using errcode='PT422',message='Seleccioná una posición válida';
    end if;
    with matches as (
      select p.id,p.first_name,p.last_name,p.name_kind,btrim(p.first_name||' '||p.last_name) as display_name,coalesce(v_category,chosen.category,p.category) as category,p.position,p.transfermarkt_url,p.checked_at,
        scouting.player_age(p.birth_date,v_today) as age_at_recommendation,
        scouting.player_age(p.birth_date,v_today) as age_current,v_today as age_as_of,
        case when scouting.player_age(p.birth_date,v_today) is not null then 'catalogue_birth_date' end as age_source,
        case when scouting.player_age(p.birth_date,v_today) is not null then p.birth_date_source_url end as age_source_url,
        case when scouting.player_age(p.birth_date,v_today) is not null then p.birth_date_verified_at end as age_verified_at,
        scouting.player_market_value(p) as market_value
      from scouting.players p
      left join lateral (select m.category from scouting.player_squads m where m.player_id=p.id and m.club_id=v_club_id and m.active
        and scouting.player_has_squad(p.id,v_club_id,m.category)
        and (v_category is null or m.category=v_category) order by case m.category when 'Primera' then 0 when 'Reserva' then 1 else 2 end,m.category limit 1) chosen on true
      where p.active and p.club_id=v_club_id and scouting.player_has_squad(p.id,v_club_id,v_category)
        and (v_position is null or case when v_position='__unknown__' then p.position is null else p.position=v_position end)
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
    if v_action='players' then
      return jsonb_build_object('ok',true,'items',v_items,'next_cursor',v_next,
        'total_count',(select count(*) from scouting.players p where p.active and p.club_id=v_club_id
          and scouting.player_has_squad(p.id,v_club_id,v_category)
          and (v_position is null or case when v_position='__unknown__' then p.position is null else p.position=v_position end)
          and (v_query is null or strpos(lower(p.first_name||' '||p.last_name),lower(v_query))>0)),
        'squad',scouting.squad_json(v_club_id,v_category));
    end if;
    if v_action='clubs' then
      return jsonb_build_object('ok',true,'items',v_items,'next_cursor',v_next,'country_code',v_country,
        'total_count',(select count(*) from scouting.clubs c where c.active and c.country_code=v_country
          and (v_province is null or c.province=v_province)
          and (v_query is null or strpos(lower(concat_ws(' ',c.name,c.city)),lower(v_query))>0)
          and (v_competition is null or exists(select 1 from scouting.club_competitions m
            join scouting.competitions co on co.id=m.competition_id where m.club_id=c.id and co.active
              and co.country_code=v_country and m.season=co.season and m.competition_id=v_competition))));
    end if;
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
      if v_payload#>'{club_manual,country_code}' is not null
        and scouting.country_code_value(v_payload#>'{club_manual,country_code}')<>v_country then
        raise exception using errcode='PT422',message='El país del club no coincide con el seleccionado';
      end if;
      if not exists(select 1 from scouting.provinces where name=v_province and country_code=v_country) then
        raise exception using errcode='PT422',message='Seleccioná una región válida del país';
      end if;
      if v_competition is not null then
        select * into v_comp from scouting.competitions where id=v_competition and active and country_code=v_country;
        if not found then raise exception using errcode='PT422',message='Seleccioná una competencia válida';end if;
      end if;
      v_club_json:=jsonb_build_object('id',null,'source','manual','country_code',v_country,
        'country_name',scouting.country_name(v_country),'region_name',scouting.region_name(v_province),
        'name',scouting.text_value(v_payload#>'{club_manual,name}',2,160,'nombre del club'),
        'province',v_province,'city',scouting.text_value(v_payload#>'{club_manual,city}',2,100,'ciudad del club'),
        'league',scouting.text_value(v_payload#>'{club_manual,league}',2,160,'liga del club'),
        'competition_id',v_comp.id,'competition_name',v_comp.name,'division',null,
        'season',v_comp.season,'reference_scope','declarado_por_socio','provenance','member_submission');
    else
      select * into v_club from scouting.clubs where id=v_club_id and active and country_code=v_country;
      if not found then raise exception using errcode='PT422',message='El club seleccionado no está disponible';end if;
      select c.* into v_comp from scouting.club_competitions cc join scouting.competitions c on c.id=cc.competition_id
        where cc.club_id=v_club_id and c.active and c.country_code=v_country and cc.season=c.season
          and (v_competition is null or c.id=v_competition)
        order by cc.season desc,c.sort_order limit 1;
      if v_competition is not null and not found then
        raise exception using errcode='PT422',message='La competencia no corresponde al club en su temporada vigente';
      end if;
      v_club_json:=jsonb_build_object('id',v_club.id,'source','catalogue','name',v_club.name,'province',v_club.province,
        'country_code',v_club.country_code,'country_name',scouting.country_name(v_club.country_code),'region_name',scouting.region_name(v_club.province),
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
      select * into v_player from scouting.players where id=v_player_id and active and club_id=v_club_id
        and scouting.player_has_squad(id,v_club_id,null);
      if not found then raise exception using errcode='PT422',message='El jugador no corresponde al club seleccionado';end if;
      if not scouting.player_has_squad(v_player.id,v_club_id,v_category) then raise exception using errcode='PT422',message='La categoría no corresponde al jugador seleccionado';end if;
      if scouting.player_age(v_player.birth_date,v_today) is not null then
        v_age:=scouting.player_age(v_player.birth_date,v_today);
        v_age_source:='catalogue_birth_date';
      end if;
      v_player_json:=jsonb_build_object('id',v_player.id,'first_name',v_player.first_name,'last_name',v_player.last_name,'name_kind',v_player.name_kind,
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
      v_country:=scouting.country_code_value(to_jsonb(coalesce(v_club_json->>'country_code',
        (select country_code from scouting.provinces where name=v_club_json->>'province'),'AR')));
      perform pg_advisory_xact_lock(hashtextextended('scouting:club:'||v_country||':'||
        (v_club_json->>'province')||':'||lower(v_club_json->>'city')||':'||lower(v_club_json->>'name'),0));
      select id into v_club_id from scouting.clubs where country_code=v_country and province=v_club_json->>'province'
        and lower(city)=lower(v_club_json->>'city') and lower(name)=lower(v_club_json->>'name');
      if not found then
        insert into scouting.clubs(source_key,country_code,name,province,city,league,source,checked_at)
          values('manual:'||v_id::text,v_country,v_club_json->>'name',v_club_json->>'province',v_club_json->>'city',
            v_club_json->>'league','verified_manual',clock_timestamp()) returning id into v_club_id;
        if v_club_json->>'competition_id' is not null
          and nullif(btrim(v_club_json->>'season'),'') is not null then
          insert into scouting.club_competitions(club_id,competition_id,season,reference_scope,checked_at)
            select v_club_id,c.id,v_club_json->>'season','declarado_por_socio_validado',clock_timestamp() from scouting.competitions c
              where c.id=v_club_json->>'competition_id' and c.country_code=v_country;
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
$function$;


CREATE OR REPLACE FUNCTION scouting.import_roster_batch(p_document jsonb, p_content_sha256 text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
declare
  v_country text;
  v_scope text:=coalesce(p_document#>>'{metadata,fingerprint_scope}','global');
  v_country_fingerprints jsonb;
  v_observed_tm_ids text[];
  v_name_kind text;
  v_last_name text;
  v_key text:=p_document#>>'{metadata,batch_key}';
  v_existing_run scouting.catalogue_runs%rowtype;
  v_run uuid;
  v_squad jsonb;
  v_retirement jsonb;
  v_target_squad jsonb;
  v_replacement_squad jsonb;
  v_row jsonb;
  v_club scouting.clubs%rowtype;
  v_player scouting.players%rowtype;
  v_membership scouting.player_squads%rowtype;
  v_review scouting.squad_reviews%rowtype;
  v_player_id uuid;
  v_tm_id text;
  v_category text;
  v_checked timestamptz;
  v_source text;
  v_source_url text;
  v_expected integer;
  v_imported integer;
  v_squad_skipped integer;
  v_conflicts jsonb:='[]'::jsonb;
  v_retired_memberships jsonb:='[]'::jsonb;
  v_ambiguous text[];
  v_before jsonb;
  v_after jsonb;
  v_fingerprint text;
  v_player_count_before integer;
  v_memberships_before integer;
  v_inserted integer:=0;
  v_refreshed integer:=0;
  v_skipped integer:=0;
  v_squad_count integer:=0;
  v_result jsonb;
  v_birth date;
  v_birth_source text;
  v_position text;
begin
  v_country:=scouting.country_code_value(p_document#>'{metadata,country_code}');
  if jsonb_typeof(p_document) is distinct from 'object' or jsonb_typeof(p_document->'squads') is distinct from 'array'
    or p_document#>>'{metadata,country}' is distinct from scouting.country_name(v_country)
    or v_scope not in ('global','country') or (v_country<>'AR' and v_scope<>'country')
    or p_document#>>'{metadata,schema_version}' is distinct from '2'
    or v_key is null or v_key !~ '^[a-z0-9][a-z0-9-]{4,120}$'
    or p_content_sha256 is null or p_content_sha256 !~ '^[a-f0-9]{64}$'
    or jsonb_array_length(p_document->'squads') not between 1 and 1000
    or octet_length(p_document::text)>20000000 then
    raise exception 'Invalid reviewed roster document';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('scouting.catalogue.refresh',0));
  lock table scouting.clubs in share mode;
  lock table scouting.players,scouting.player_squads,scouting.squad_reviews,scouting.catalogue_runs in share row exclusive mode;
  select * into v_existing_run from scouting.catalogue_runs where metadata->>'batch_key'=v_key;
  if found then
    if v_existing_run.status='published' and v_existing_run.metadata->>'content_sha256'=p_content_sha256
      and v_existing_run.metadata->'document'=p_document then
      return v_existing_run.metadata->'result'||jsonb_build_object('replayed',true,'run_id',v_existing_run.id);
    end if;
    raise exception 'Batch key already exists with different content or incomplete status';
  end if;
  select coalesce(array_agg(distinct p->>'transfermarkt_id'),array[]::text[]) into v_observed_tm_ids
    from jsonb_array_elements(p_document->'squads')s cross join lateral jsonb_array_elements(coalesce(s->'players','[]'::jsonb))p;
  if v_scope='country' then
    v_country_fingerprints:=scouting.catalogue_country_fingerprints(v_country);
    select coalesce(jsonb_agg(to_jsonb(p) order by p.id),'[]'::jsonb) into v_before from scouting.players p
      join scouting.clubs c on c.id=p.club_id where c.country_code=v_country
        and substring(p.transfermarkt_url from '/profil/spieler/([0-9]+)')=any(v_observed_tm_ids);
    v_fingerprint:=v_country_fingerprints->>'expected_players_sha256';
  else
    select coalesce(jsonb_agg(to_jsonb(p) order by p.id),'[]'::jsonb) into v_before from scouting.players p;
    v_fingerprint:=encode(extensions.digest(convert_to(v_before::text,'UTF8'),'sha256'),'hex');
  end if;
  if p_document#>>'{metadata,expected_players_sha256}' is distinct from v_fingerprint then
    raise exception 'Players changed since review: reconcile the live catalogue before importing';
  end if;
  if v_scope='country' then
    v_fingerprint:=v_country_fingerprints->>'expected_clubs_sha256';
  else
    select encode(extensions.digest(convert_to(coalesce(jsonb_agg(to_jsonb(c) order by c.id),'[]'::jsonb)::text,'UTF8'),'sha256'),'hex')
      into v_fingerprint from scouting.clubs c;
  end if;
  if p_document#>>'{metadata,expected_clubs_sha256}' is distinct from v_fingerprint then
    raise exception 'Clubs changed since review: reconcile the live catalogue before importing';
  end if;
  select count(*) into v_player_count_before from scouting.players;
  select count(*) into v_memberships_before from scouting.player_squads;
  if exists(select 1 from jsonb_array_elements(p_document->'squads') s
    group by s->>'club_source_key',s->>'category' having count(*)>1) then
    raise exception 'Duplicate club/category in reviewed document';
  end if;
  select coalesce(array_agg(tm_id),array[]::text[]) into v_ambiguous from (
    select p->>'transfermarkt_id' as tm_id from jsonb_array_elements(p_document->'squads') s
      cross join lateral jsonb_array_elements(coalesce(s->'players','[]'::jsonb)) p
      group by p->>'transfermarkt_id' having count(distinct s->>'club_source_key')>1
  ) conflicts;
  insert into scouting.catalogue_runs(source,status,authorization_reference,metadata)
    values('reviewed_public_squads','staging','User authorized scouting country catalogue expansion and publication',
      jsonb_build_object('batch_key',v_key,'country_code',v_country,'fingerprint_scope',v_scope,
        'player_snapshot_scope',case when v_scope='country' then 'observed_identities' else 'global' end,
        'content_sha256',p_content_sha256,'document',p_document,'before_players',v_before))
    returning id into v_run;

  for v_squad in select s from jsonb_array_elements(p_document->'squads') s
    order by case s->>'category' when 'Primera' then 0 else 1 end,s->>'club_source_key',s->>'category' loop
    v_category:=v_squad->>'category';
    v_source:=v_squad->>'source';
    v_source_url:=v_squad->>'source_url';
    v_checked:=(v_squad->>'checked_at')::timestamptz;
    v_expected:=nullif(v_squad->>'expected_count','')::integer;
    if v_category is null or char_length(v_category) not between 2 and 100
      or v_source is null or v_source not in ('official_reference','verified_manual')
      or v_source_url is null or char_length(v_source_url)>2048 or v_source_url !~ '^https://' or v_source_url ~ '[[:space:]\\]'
      or v_checked is null or v_checked>clock_timestamp()+interval '5 minutes'
      or v_squad->>'completeness' is null or v_squad->>'completeness' not in ('complete','partial','unavailable')
      or jsonb_typeof(v_squad->'players') is distinct from 'array'
      or jsonb_array_length(v_squad->'players')>1000
      or (v_expected is not null and v_expected not between 0 and 1000) then
      raise exception 'Invalid squad metadata for % / %',v_squad->>'club_source_key',v_category;
    end if;
    if v_squad->>'completeness'='complete' and (v_expected is null or v_expected<1 or v_expected<>jsonb_array_length(v_squad->'players')) then
      raise exception 'Complete squad expected_count must equal the observed roster rows';
    end if;
    if v_squad->>'completeness'='unavailable' and jsonb_array_length(v_squad->'players')<>0 then
      raise exception 'An unavailable source cannot introduce player observations';
    end if;
    select * into v_club from scouting.clubs where source_key=v_squad->>'club_source_key' and active;
    if not found then raise exception 'Unknown or inactive club %',v_squad->>'club_source_key';end if;
    if v_club.country_code<>v_country then raise exception 'Squad club country does not match batch country';end if;
    if nullif(v_squad->>'season','') is null or not exists(
      select 1 from scouting.club_competitions cc join scouting.competitions co on co.id=cc.competition_id
      where cc.club_id=v_club.id and co.active and cc.season=co.season and cc.season=v_squad->>'season') then
      raise exception 'Squad season does not match a verified current club competition';
    end if;
    select * into v_review from scouting.squad_reviews where club_id=v_club.id and category=v_category;
    if found and v_review.checked_at>v_checked then raise exception 'A newer squad review already exists';end if;
    if exists(select 1 from jsonb_array_elements(v_squad->'players') p group by p->>'transfermarkt_id' having count(*)>1) then
      raise exception 'Duplicate player identity in squad % / %',v_club.source_key,v_category;
    end if;
    v_imported:=0;v_squad_skipped:=0;
    for v_row in select p from jsonb_array_elements(v_squad->'players') p loop
      v_tm_id:=v_row->>'transfermarkt_id';
      v_position:=nullif(v_row->>'position','');
      v_name_kind:=coalesce(v_row->>'name_kind','display_name_parts');
      v_last_name:=coalesce(v_row->>'last_name','');
      v_birth:=nullif(v_row->>'birth_date','')::date;
      v_birth_source:=coalesce(nullif(v_row->>'birth_date_source_url',''),v_source_url);
      if v_tm_id is null or v_tm_id !~ '^[1-9][0-9]{0,11}$'
        or v_row->>'transfermarkt_url' is null
        or v_row->>'transfermarkt_url' !~ '^https://(www\.)?transfermarkt\.(com|com\.ar|es|de|co\.uk|it|fr|pt|nl)/[a-zA-Z0-9_/%.-]+/profil/spieler/[0-9]+(/[^?#]*)?(\?[^#]*)?(#.*)?$'
        or substring(v_row->>'transfermarkt_url' from '/profil/spieler/([0-9]+)')<>v_tm_id
        or char_length(coalesce(v_row->>'first_name','')) not between 2 and 100
        or not ((v_name_kind='display_name_parts' and char_length(v_last_name) between 2 and 100)
          or (v_name_kind='sporting_mononym' and v_last_name=''
            and (v_row->>'full_name' is null or v_row->>'full_name'=v_row->>'first_name')))
        or (v_position is not null and v_position<>all(array['Arquero','Lateral','Defensor Central','Volante central','Volante por derecha','Volante por Izquierda','Volante Mixto','Delantero de Area','Delantero Extremo'])) then
        raise exception 'Invalid player identity, name or position in % / %: %',v_club.source_key,v_category,v_tm_id;
      end if;
      if v_tm_id=any(v_ambiguous) then
        v_conflicts:=v_conflicts||jsonb_build_array(jsonb_build_object('transfermarkt_id',v_tm_id,'club_source_key',v_club.source_key,
          'category',v_category,'reason','same_player_observed_for_multiple_clubs'));
        v_squad_skipped:=v_squad_skipped+1;continue;
      end if;
      select * into v_player from scouting.players where substring(transfermarkt_url from '/profil/spieler/([0-9]+)')=v_tm_id;
      if found then
        v_player_id:=v_player.id;
        select * into v_membership from scouting.player_squads m where m.player_id=v_player.id and m.club_id=v_club.id
          and m.category=v_category;
        if not v_player.active or v_player.club_id<>v_club.id
          or (v_membership.player_id is not null and (not v_membership.active or v_membership.checked_at>v_checked)) then
          v_conflicts:=v_conflicts||jsonb_build_array(jsonb_build_object('transfermarkt_id',v_tm_id,'club_source_key',v_club.source_key,
            'category',v_category,'existing_player_id',v_player.id,'existing_club_id',v_player.club_id,
            'reason',case when not v_player.active then 'preserve_deliberate_inactive_player' when v_player.club_id<>v_club.id then 'affiliation_requires_reconciliation'
              when v_membership.active=false then 'preserve_deliberate_inactive_membership' else 'preserve_newer_membership_review' end));
          v_squad_skipped:=v_squad_skipped+1;continue;
        end if;
        if v_birth is not null and v_player.birth_date is not null and v_birth<>v_player.birth_date then
          v_conflicts:=v_conflicts||jsonb_build_array(jsonb_build_object('transfermarkt_id',v_tm_id,'field','birth_date',
            'reason','preserve_conflicting_verified_birth_date','previous',v_player.birth_date,'observed',v_birth));
        end if;
        -- Keep verified names, previous DOB/value evidence, stable source_key and
        -- UUID. A squad observation does not re-date a previous market value.
        update scouting.players set checked_at=greatest(checked_at,v_checked),catalogue_run_id=v_run,
          category=case when v_category='Primera' then 'Primera' else category end,
          position=coalesce(position,v_position),
          birth_date=coalesce(birth_date,v_birth),
          birth_date_source_url=case when birth_date is null and v_birth is not null then v_birth_source else birth_date_source_url end,
          birth_date_verified_at=case when birth_date is null and v_birth is not null then v_checked else birth_date_verified_at end
          where id=v_player_id;
        v_refreshed:=v_refreshed+1;
      else
        if exists(select 1 from scouting.players where source_key='tm-player-'||v_tm_id) then
          raise exception 'Stable source_key already belongs to another identity';
        end if;
        insert into scouting.players(source_key,club_id,first_name,last_name,name_kind,category,position,transfermarkt_url,source,checked_at,catalogue_run_id,
          birth_date,birth_date_source_url,birth_date_verified_at)
        values('tm-player-'||v_tm_id,v_club.id,v_row->>'first_name',v_last_name,v_name_kind,v_category,v_position,
          v_row->>'transfermarkt_url',v_source,v_checked,v_run,v_birth,
          case when v_birth is not null then v_birth_source end,case when v_birth is not null then v_checked end)
        returning id into v_player_id;
        v_inserted:=v_inserted+1;
      end if;
      insert into scouting.player_squads(player_id,club_id,category,season,source,source_url,checked_at,catalogue_run_id)
        values(v_player_id,v_club.id,v_category,v_squad->>'season',v_source,v_source_url,v_checked,v_run)
        on conflict(player_id,club_id,category) do update set season=excluded.season,source=excluded.source,
          source_url=excluded.source_url,checked_at=excluded.checked_at,catalogue_run_id=excluded.catalogue_run_id;
      -- Deliberately inactive memberships are not reactivated by an import.
      if exists(select 1 from scouting.player_squads where player_id=v_player_id and club_id=v_club.id and category=v_category and active) then
        v_imported:=v_imported+1;
      else
        v_squad_skipped:=v_squad_skipped+1;
        v_conflicts:=v_conflicts||jsonb_build_array(jsonb_build_object('transfermarkt_id',v_tm_id,'club_source_key',v_club.source_key,
          'category',v_category,'reason','preserve_deliberate_inactive_membership'));
      end if;
    end loop;
    insert into scouting.squad_reviews(club_id,category,season,source_season,source,source_url,checked_at,completeness,expected_count,imported_count,catalogue_run_id,notes)
      values(v_club.id,v_category,v_squad->>'season',nullif(v_squad->>'source_season',''),v_source,v_source_url,v_checked,
        case when v_squad_skipped>0 then 'partial' else v_squad->>'completeness' end,
        v_expected,v_imported,v_run,v_squad->>'notes')
      on conflict(club_id,category) do update set season=excluded.season,source_season=excluded.source_season,source=excluded.source,
        source_url=excluded.source_url,checked_at=excluded.checked_at,completeness=excluded.completeness,
        expected_count=excluded.expected_count,imported_count=excluded.imported_count,catalogue_run_id=excluded.catalogue_run_id,notes=excluded.notes;
    v_skipped:=v_skipped+v_squad_skipped;v_squad_count:=v_squad_count+1;
  end loop;
  -- Explicit reviewed category corrections only. Merely missing from a roster
  -- never retires a player or a membership. These corrections require two full
  -- retrieved squads: absent from the old category and present in the new one.
  if p_document ? 'membership_retirements' and jsonb_typeof(p_document->'membership_retirements')<>'array' then
    raise exception 'Invalid explicit membership retirement list';
  end if;
  for v_retirement in select r from jsonb_array_elements(coalesce(p_document->'membership_retirements','[]'::jsonb))r loop
    v_tm_id:=v_retirement->>'transfermarkt_id';
    v_category:=v_retirement->>'category';
    v_checked:=(v_retirement->>'checked_at')::timestamptz;
    if v_tm_id is null or v_tm_id !~ '^[1-9][0-9]{0,11}$'
      or v_category is null or v_category=v_retirement->>'replacement_category'
      or v_checked is null or v_checked>clock_timestamp()+interval '5 minutes'
      or char_length(coalesce(v_retirement->>'reason','')) not between 20 and 1000
      or jsonb_typeof(v_retirement->'source_urls') is distinct from 'array' then
      raise exception 'Invalid explicit category correction';
    end if;
    select s into v_target_squad from jsonb_array_elements(p_document->'squads')s
      where s->>'club_source_key'=v_retirement->>'club_source_key' and s->>'category'=v_category;
    select s into v_replacement_squad from jsonb_array_elements(p_document->'squads')s
      where s->>'club_source_key'=v_retirement->>'club_source_key' and s->>'category'=v_retirement->>'replacement_category';
    if v_target_squad is null or v_replacement_squad is null
      or v_target_squad->>'completeness'<>'complete' or v_replacement_squad->>'completeness'<>'complete'
      or v_target_squad->>'season'<>v_replacement_squad->>'season'
      or v_checked<(v_target_squad->>'checked_at')::timestamptz or v_checked<(v_replacement_squad->>'checked_at')::timestamptz
      or exists(select 1 from jsonb_array_elements(v_target_squad->'players')p where p->>'transfermarkt_id'=v_tm_id)
      or not exists(select 1 from jsonb_array_elements(v_replacement_squad->'players')p where p->>'transfermarkt_id'=v_tm_id)
      or not (v_retirement->'source_urls' @> jsonb_build_array(v_target_squad->>'source_url',v_replacement_squad->>'source_url')) then
      raise exception 'Category correction requires both fresh complete source rosters and explicit player evidence';
    end if;
    select * into v_club from scouting.clubs where source_key=v_retirement->>'club_source_key' and active;
    if v_club.id is null or v_club.country_code<>v_country then raise exception 'Category correction club country does not match batch country';end if;
    select * into v_player from scouting.players where substring(transfermarkt_url from '/profil/spieler/([0-9]+)')=v_tm_id;
    select * into v_membership from scouting.player_squads where player_id=v_player.id and club_id=v_club.id and category=v_category;
    if v_player.id is null or not v_player.active or v_player.club_id<>v_club.id or v_membership.player_id is null
      or v_membership.checked_at>v_checked
      or not scouting.player_has_squad(v_player.id,v_club.id,v_retirement->>'replacement_category')
      or not exists(select 1 from scouting.squad_reviews r where r.club_id=v_club.id and r.category=v_category
        and r.catalogue_run_id=v_run and r.completeness='complete')
      or not exists(select 1 from scouting.squad_reviews r where r.club_id=v_club.id and r.category=v_retirement->>'replacement_category'
        and r.catalogue_run_id=v_run and r.completeness='complete') then
      raise exception 'Category correction cannot override conflicting, inactive or newer reviewed state';
    end if;
    if v_membership.active then
      update scouting.player_squads set active=false,checked_at=v_checked,catalogue_run_id=v_run,
        source=v_target_squad->>'source',source_url=v_target_squad->>'source_url'
        where player_id=v_player.id and club_id=v_club.id and category=v_category;
      update scouting.players set category=v_retirement->>'replacement_category',checked_at=greatest(checked_at,v_checked),catalogue_run_id=v_run
        where id=v_player.id and category=v_category;
      v_retired_memberships:=v_retired_memberships||jsonb_build_array(jsonb_build_object('player_id',v_player.id,
        'before',to_jsonb(v_membership),'after',(select to_jsonb(m) from scouting.player_squads m
          where m.player_id=v_player.id and m.club_id=v_club.id and m.category=v_category),'evidence',v_retirement));
    end if;
  end loop;
  if v_scope='country' then
    select coalesce(jsonb_agg(to_jsonb(p) order by p.id),'[]'::jsonb) into v_after from scouting.players p
      join scouting.clubs c on c.id=p.club_id where c.country_code=v_country
        and substring(p.transfermarkt_url from '/profil/spieler/([0-9]+)')=any(v_observed_tm_ids);
  else
    select coalesce(jsonb_agg(to_jsonb(p) order by p.id),'[]'::jsonb) into v_after from scouting.players p;
  end if;
  v_result:=jsonb_build_object('run_id',v_run,'batch_key',v_key,'content_sha256',p_content_sha256,
    'squads_reviewed',v_squad_count,'players_inserted',v_inserted,'player_observations_refreshed',v_refreshed,
    'observations_skipped',v_skipped,'players_before',v_player_count_before,'players_after',(select count(*) from scouting.players),
    'country_code',v_country,'fingerprint_scope',v_scope,'snapshot_players_before',jsonb_array_length(v_before),'snapshot_players_after',jsonb_array_length(v_after),
    'memberships_before',v_memberships_before,'memberships_after',(select count(*) from scouting.player_squads),
    'conflicts',v_conflicts,'membership_retirements',jsonb_array_length(v_retired_memberships),'replayed',false);
  update scouting.catalogue_runs set status='published',published_at=clock_timestamp(),
    metadata=metadata||jsonb_build_object('after_players',v_after,'membership_changes',v_retired_memberships,'result',v_result) where id=v_run;
  return v_result;
end;
$function$;


-- Reviewed source data only. Not callable from the member API or service role.
create function scouting.import_club_batch(p_document jsonb,p_content_sha256 text)
returns jsonb language plpgsql set search_path=pg_catalog as $function$
declare
  v_country text:=scouting.country_code_value(p_document#>'{metadata,country_code}');
  v_key text:=p_document#>>'{metadata,batch_key}';
  v_fingerprints jsonb;
  v_existing_run scouting.catalogue_runs%rowtype;
  v_run uuid;
  v_row jsonb;
  v_link jsonb;
  v_comp_row jsonb;
  v_comp scouting.competitions%rowtype;
  v_club scouting.clubs%rowtype;
  v_membership scouting.club_competitions%rowtype;
  v_club_id uuid;
  v_tm_id text;
  v_name text;
  v_province text;
  v_city text;
  v_checked timestamptz;
  v_comp_checked timestamptz;
  v_source text;
  v_urls jsonb;
  v_before jsonb;
  v_after jsonb;
  v_before_links jsonb;
  v_after_links jsonb;
  v_inserted integer:=0;
  v_refreshed integer:=0;
  v_links integer:=0;
  v_new_competitions integer:=0;
  v_result jsonb;
begin
  if jsonb_typeof(p_document) is distinct from 'object'
    or jsonb_typeof(p_document->'clubs') is distinct from 'array'
    or p_document#>>'{metadata,schema_version}' is distinct from '1'
    or p_document#>>'{metadata,kind}' is distinct from 'reviewed_clubs'
    or p_document#>>'{metadata,country}' is distinct from scouting.country_name(v_country)
    or v_key is null or v_key !~ '^[a-z0-9][a-z0-9-]{4,120}$'
    or p_content_sha256 is null or p_content_sha256 !~ '^[a-f0-9]{64}$'
    or jsonb_array_length(p_document->'clubs') not between 1 and 1000
    or octet_length(p_document::text)>20000000
    or (p_document ? 'competitions' and jsonb_typeof(p_document->'competitions') is distinct from 'array') then
    raise exception 'Invalid reviewed club document';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('scouting.catalogue.refresh',0));
  lock table scouting.clubs,scouting.competitions,scouting.club_competitions,scouting.catalogue_runs in share row exclusive mode;
  select * into v_existing_run from scouting.catalogue_runs where metadata->>'batch_key'=v_key;
  if found then
    if v_existing_run.status='published' and v_existing_run.metadata->>'content_sha256'=p_content_sha256
      and v_existing_run.metadata->'document'=p_document then
      return v_existing_run.metadata->'result'||jsonb_build_object('replayed',true,'run_id',v_existing_run.id);
    end if;
    raise exception 'Batch key already exists with different content or incomplete status';
  end if;
  v_fingerprints:=scouting.catalogue_country_fingerprints(v_country);
  if p_document#>>'{metadata,expected_clubs_sha256}' is distinct from v_fingerprints->>'expected_clubs_sha256'
    or p_document#>>'{metadata,expected_competitions_sha256}' is distinct from v_fingerprints->>'expected_competitions_sha256'
    or p_document#>>'{metadata,expected_club_competitions_sha256}' is distinct from v_fingerprints->>'expected_club_competitions_sha256' then
    raise exception 'Country catalogue changed since review: reconcile before importing clubs';
  end if;
  if exists(select 1 from jsonb_array_elements(p_document->'clubs')c group by c->>'transfermarkt_id' having count(*)>1)
    or exists(select 1 from jsonb_array_elements(p_document->'clubs')c group by c->>'source_key' having count(*)>1)
    or exists(select 1 from jsonb_array_elements(coalesce(p_document->'competitions','[]'::jsonb))c group by c->>'id' having count(*)>1) then
    raise exception 'Duplicate identity in reviewed club document';
  end if;
  select coalesce(jsonb_agg(to_jsonb(c) order by c.id),'[]'::jsonb) into v_before from scouting.clubs c
    where c.transfermarkt_id in (select x->>'transfermarkt_id' from jsonb_array_elements(p_document->'clubs')x);
  select coalesce(jsonb_agg(to_jsonb(m) order by m.club_id,m.competition_id,m.season),'[]'::jsonb) into v_before_links
    from scouting.club_competitions m join scouting.clubs c on c.id=m.club_id
    where c.transfermarkt_id in (select x->>'transfermarkt_id' from jsonb_array_elements(p_document->'clubs')x);
  insert into scouting.catalogue_runs(source,status,authorization_reference,metadata)
    values('reviewed_public_clubs','staging','User authorized scouting country catalogue expansion and publication',
      jsonb_build_object('batch_key',v_key,'country_code',v_country,'fingerprint_scope','country',
        'club_snapshot_scope','observed_identities','content_sha256',p_content_sha256,'document',p_document,
        'before_clubs',v_before,'before_club_competitions',v_before_links)) returning id into v_run;

  for v_comp_row in select x from jsonb_array_elements(coalesce(p_document->'competitions','[]'::jsonb))x loop
    if v_comp_row->>'id' is null or v_comp_row->>'id' !~ '^[a-z0-9-]{2,60}$'
      or char_length(coalesce(v_comp_row->>'name','')) not between 2 and 160
      or char_length(coalesce(v_comp_row->>'season','')) not between 1 and 50
      or v_comp_row->>'source_url' is null or v_comp_row->>'source_url' !~ '^https://'
      or char_length(v_comp_row->>'source_url')>2048 or v_comp_row->>'source_url' ~ '[[:space:]\\]'
      or (v_comp_row ? 'country_code' and v_comp_row->>'country_code' is distinct from v_country) then
      raise exception 'Invalid reviewed competition';
    end if;
    select * into v_comp from scouting.competitions where id=v_comp_row->>'id';
    if found then
      if v_comp.country_code<>v_country or not v_comp.active or v_comp.season<>v_comp_row->>'season'
        or v_comp.name<>v_comp_row->>'name' then
        raise exception 'Existing competition requires explicit reconciliation';
      end if;
    else
      insert into scouting.competitions(id,name,season,sort_order,country_code)
        values(v_comp_row->>'id',v_comp_row->>'name',v_comp_row->>'season',
          coalesce((v_comp_row->>'sort_order')::integer,150),v_country);
      v_new_competitions:=v_new_competitions+1;
    end if;
  end loop;

  for v_row in select x from jsonb_array_elements(p_document->'clubs')x loop
    v_tm_id:=v_row->>'transfermarkt_id';
    v_name:=scouting.text_value(v_row->'name',2,160,'nombre del club');
    v_province:=scouting.text_value(v_row->'province',0,100,'región del club',true);
    v_city:=scouting.text_value(v_row->'city',2,100,'ciudad del club',true);
    v_checked:=(v_row->>'checked_at')::timestamptz;
    v_source:=v_row->>'source';
    v_urls:=v_row->'source_urls';
    if v_tm_id is null or v_tm_id !~ '^[1-9][0-9]{0,11}$'
      or v_row->>'source_key' is null or char_length(v_row->>'source_key') not between 2 and 160
      or v_source is null or v_source not in ('official_reference','verified_manual')
      or v_checked is null or v_checked>clock_timestamp()+interval '5 minutes'
      or jsonb_typeof(v_urls) is distinct from 'array' or jsonb_array_length(v_urls) not between 1 and 40
      or exists(select 1 from jsonb_array_elements(v_urls)u where jsonb_typeof(u)<>'string'
        or u#>>'{}' !~ '^https://' or char_length(u#>>'{}')>2048 or u#>>'{}' ~ '[[:space:]\\]')
      or not exists(select 1 from jsonb_array_elements_text(v_urls)u(url)
        where u.url ~ '^https://(www\.)?transfermarkt\.(com|com\.ar|es|de|co\.uk|it|fr|pt|nl)/'
          and substring(u.url from '/verein/([0-9]+)')=v_tm_id)
      or (v_row ? 'country_code' and v_row->>'country_code' is distinct from v_country)
      or jsonb_typeof(v_row->'competitions') is distinct from 'array'
      or jsonb_array_length(v_row->'competitions') not between 1 and 40 then
      raise exception 'Invalid reviewed club identity or provenance: %',v_tm_id;
    end if;
    if v_province is not null and not exists(select 1 from scouting.provinces where name=v_province and country_code=v_country) then
      raise exception 'Club region does not belong to the batch country';
    end if;
    if v_province is not null or v_city is not null then
      if jsonb_typeof(v_row->'geography_source_urls') is distinct from 'array'
        or jsonb_array_length(v_row->'geography_source_urls')=0
        or exists(select 1 from jsonb_array_elements(v_row->'geography_source_urls')u
          where jsonb_typeof(u)<>'string' or not (v_urls @> jsonb_build_array(u))) then
        raise exception 'Club geography requires explicit reviewed source evidence';
      end if;
    end if;
    select * into v_club from scouting.clubs where transfermarkt_id=v_tm_id;
    if found then
      if v_club.country_code<>v_country or v_club.source_key<>v_row->>'source_key'
        or not v_club.active or v_club.checked_at>v_checked then
        raise exception 'Existing club identity, country, inactive or newer state requires reconciliation';
      end if;
      if (v_club.province is not null and v_province is not null and v_club.province<>v_province)
        or (v_club.city is not null and v_city is not null and lower(v_club.city)<>lower(v_city)) then
        raise exception 'Existing club geography requires explicit reconciliation';
      end if;
      v_club_id:=v_club.id;
      update scouting.clubs set province=coalesce(province,v_province),city=coalesce(city,v_city),
        league=coalesce(league,scouting.text_value(v_row->'league',0,160,'liga',true)),
        checked_at=v_checked,catalogue_run_id=v_run,
        source_urls=(select coalesce(jsonb_agg(u.value order by u.value),'[]'::jsonb)
          from (select distinct value from jsonb_array_elements_text(v_club.source_urls||v_urls))u)
        where id=v_club_id;
      v_refreshed:=v_refreshed+1;
    else
      if v_row->>'source_key'<>'tm-club-'||v_tm_id
        or exists(select 1 from scouting.clubs where source_key=v_row->>'source_key') then
        raise exception 'New club stable source key does not match its Transfermarkt identity';
      end if;
      insert into scouting.clubs(source_key,transfermarkt_id,country_code,name,province,city,league,source,source_urls,checked_at,catalogue_run_id)
        values(v_row->>'source_key',v_tm_id,v_country,v_name,v_province,v_city,
          scouting.text_value(v_row->'league',0,160,'liga',true),v_source,v_urls,v_checked,v_run) returning id into v_club_id;
      v_inserted:=v_inserted+1;
    end if;
    if exists(select 1 from jsonb_array_elements(v_row->'competitions')m
      group by m->>'competition_id',m->>'season' having count(*)>1) then
      raise exception 'Duplicate club competition membership';
    end if;
    for v_link in select m from jsonb_array_elements(v_row->'competitions')m loop
      v_comp_checked:=(v_link->>'checked_at')::timestamptz;
      select * into v_comp from scouting.competitions where id=v_link->>'competition_id'
        and country_code=v_country and active and season=v_link->>'season';
      if not found or v_comp_checked is null or v_comp_checked>clock_timestamp()+interval '5 minutes'
        or char_length(coalesce(v_link->>'reference_scope','')) not between 2 and 100
        or v_link->>'source_url' is null or v_link->>'source_url' !~ '^https://'
        or char_length(v_link->>'source_url')>2048 or v_link->>'source_url' ~ '[[:space:]\\]' then
        raise exception 'Club competition is not verified for the country and current season';
      end if;
      select * into v_membership from scouting.club_competitions where club_id=v_club_id and competition_id=v_comp.id and season=v_comp.season;
      if found and v_membership.checked_at>v_comp_checked then
        raise exception 'A newer club competition membership already exists';
      end if;
      insert into scouting.club_competitions(club_id,competition_id,season,division,reference_scope,source_urls,checked_at)
        values(v_club_id,v_comp.id,v_comp.season,scouting.text_value(v_link->'division',0,100,'división',true),
          v_link->>'reference_scope',jsonb_build_array(v_link->>'source_url'),v_comp_checked)
        on conflict(club_id,competition_id,season) do update set division=excluded.division,
          reference_scope=excluded.reference_scope,checked_at=excluded.checked_at,
          source_urls=(select coalesce(jsonb_agg(u.value order by u.value),'[]'::jsonb)
            from (select distinct value from jsonb_array_elements_text(scouting.club_competitions.source_urls||excluded.source_urls))u);
      v_links:=v_links+1;
    end loop;
  end loop;
  select coalesce(jsonb_agg(to_jsonb(c) order by c.id),'[]'::jsonb) into v_after from scouting.clubs c
    where c.transfermarkt_id in (select x->>'transfermarkt_id' from jsonb_array_elements(p_document->'clubs')x);
  select coalesce(jsonb_agg(to_jsonb(m) order by m.club_id,m.competition_id,m.season),'[]'::jsonb) into v_after_links
    from scouting.club_competitions m join scouting.clubs c on c.id=m.club_id
    where c.transfermarkt_id in (select x->>'transfermarkt_id' from jsonb_array_elements(p_document->'clubs')x);
  v_result:=jsonb_build_object('run_id',v_run,'batch_key',v_key,'country_code',v_country,'content_sha256',p_content_sha256,
    'clubs_inserted',v_inserted,'clubs_refreshed',v_refreshed,'competitions_inserted',v_new_competitions,
    'club_competitions_observed',v_links,'clubs_after',(select count(*) from scouting.clubs where country_code=v_country),'replayed',false);
  update scouting.catalogue_runs set status='published',published_at=clock_timestamp(),
    metadata=metadata||jsonb_build_object('after_clubs',v_after,'after_club_competitions',v_after_links,'result',v_result) where id=v_run;
  return v_result;
end;
$function$;
revoke all on function scouting.import_club_batch(jsonb,text) from public,anon,authenticated,service_role;



-- Existing RPC/importer privileges must stay closed.
do $country_privileges$
begin
  if has_function_privilege('anon','public.scouting_api(text,text,jsonb)','EXECUTE')
    or has_function_privilege('authenticated','public.scouting_api(text,text,jsonb)','EXECUTE')
    or not has_function_privilege('service_role','public.scouting_api(text,text,jsonb)','EXECUTE')
    or has_function_privilege('service_role','scouting.import_roster_batch(jsonb,text)','EXECUTE') then
    raise exception 'Scouting function privileges changed';
  end if;
end;
$country_privileges$;
