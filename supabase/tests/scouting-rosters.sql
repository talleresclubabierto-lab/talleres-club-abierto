-- Real RPC/import regression with synthetic clubs, players and sessions.
-- ALWAYS execute with the final ROLLBACK. No real identity/session is reused.
begin;
set local statement_timeout='120s';
set local lock_timeout='5s';
do $roster_test$
declare
  v_suffix text:=left(replace(gen_random_uuid()::text,'-',''),12);
  v_member bigint:=884000000000000+(floor(random()*1000000000))::bigint;
  v_token text:=encode(extensions.gen_random_bytes(32),'hex');
  v_club uuid:=gen_random_uuid();
  v_other uuid:=gen_random_uuid();
  v_player uuid;
  v_retired_player uuid;
  v_retired_rec uuid;
  v_retired_history jsonb;
  v_correction jsonb;
  v_key text;
  v_comp text;
  v_tm_base bigint:=98000000000+(floor(random()*1000000000))::bigint;
  v_rows jsonb;
  v_reserve_rows jsonb;
  v_document jsonb;
  v_bad jsonb;
  v_metadata jsonb;
  v_result jsonb;
  v_response jsonb;
  v_response2 jsonb;
  v_payload jsonb;
  v_rec uuid;
  v_before_existing jsonb;
  v_before_history jsonb;
  v_before_membership jsonb;
  v_after_history jsonb;
  v_before_events integer;
  v_before_players integer;
  v_before_lots integer;
  v_count integer;
  v_current_fingerprints jsonb;
  v_hash text:=repeat('a',64);
begin
  v_key:='qa-rosters-'||v_suffix;
  v_comp:='qa-rosters-'||v_suffix;
  select coalesce(jsonb_agg(to_jsonb(p) order by p.id),'[]'::jsonb) into v_before_existing from scouting.players p;
  select count(*) into v_before_players from scouting.players;
  select count(*) into v_before_events from scouting.events;
  select count(*) into v_before_lots from public.lotes_merkle_auditoria;
  select jsonb_build_object('recommendations',(select coalesce(jsonb_agg(to_jsonb(r) order by r.id),'[]'::jsonb) from scouting.recommendations r),
    'events',(select coalesce(jsonb_agg(to_jsonb(e) order by e.id),'[]'::jsonb) from scouting.events e)) into v_before_history;
  insert into public.socios(numero_socio,nombre,fecha_alta,habilitado)
    values(v_member,'SCOUTING ROSTERS SYNTHETIC MEMBER',current_date,true);
  perform public.crear_sesion_segura_interno(v_member,v_token,5,'scouting_roster_test','{}'::jsonb);
  insert into scouting.competitions(id,name,season) values(v_comp,'Synthetic roster competition','2026');
  insert into scouting.clubs(id,source_key,name,province,city,source,checked_at) values
    (v_club,v_key,'Synthetic roster club','Córdoba','Localidad sintética','verified_manual',clock_timestamp()),
    (v_other,v_key||'-other','Synthetic empty club','Córdoba','Localidad sintética','verified_manual',clock_timestamp());
  insert into scouting.club_competitions(club_id,competition_id,season,checked_at) values
    (v_club,v_comp,'2026',clock_timestamp()),(v_other,v_comp,'2026',clock_timestamp());
  select jsonb_agg(jsonb_build_object('transfermarkt_id',(v_tm_base+n)::text,
    'transfermarkt_url','https://www.transfermarkt.com/synthetic-player/profil/spieler/'||(v_tm_base+n)::text,
    'first_name','Jugador','last_name','Sintético '||lpad(n::text,2,'0'),'position','Lateral',
    'birth_date',case when n=1 then (current_date-interval '20 years')::date end) order by n)
    into v_rows from generate_series(1,28)n;
  v_reserve_rows:=jsonb_build_array(v_rows->0,v_rows->1,
    jsonb_build_object('transfermarkt_id',(v_tm_base+29)::text,
      'transfermarkt_url','https://www.transfermarkt.com/synthetic-player/profil/spieler/'||(v_tm_base+29)::text,
      'first_name','Jugador','last_name','Reserva exclusiva','position','Arquero'));
  select jsonb_build_object(
    'expected_players_sha256',encode(extensions.digest(convert_to(coalesce((select jsonb_agg(to_jsonb(p) order by p.id) from scouting.players p),'[]'::jsonb)::text,'UTF8'),'sha256'),'hex'),
    'expected_clubs_sha256',encode(extensions.digest(convert_to(coalesce((select jsonb_agg(to_jsonb(c) order by c.id) from scouting.clubs c),'[]'::jsonb)::text,'UTF8'),'sha256'),'hex')) into v_metadata;
  v_metadata:=v_metadata||jsonb_build_object('schema_version',2,'batch_key',v_key,'country','Argentina','reviewed_at',clock_timestamp());
  v_document:=jsonb_build_object('metadata',v_metadata,'squads',jsonb_build_array(
    jsonb_build_object('club_source_key',v_key,'category','Primera','season','2026','source_season','2026','source','verified_manual',
      'source_url','https://www.transfermarkt.com/synthetic-club/kader/verein/99999991','checked_at',clock_timestamp(),
      'completeness','complete','expected_count',28,'players',v_rows),
    jsonb_build_object('club_source_key',v_key,'category','Reserva','season','2026','source_season','26/27','source','verified_manual',
      'source_url','https://www.transfermarkt.com/synthetic-reserve/kader/verein/99999992','checked_at',clock_timestamp()-interval '1 minute',
      'completeness','complete','expected_count',3,'players',v_reserve_rows)));
  v_result:=scouting.import_roster_batch(v_document,v_hash);
  if (v_result->>'players_inserted')::integer<>29 or (v_result->>'observations_skipped')::integer<>0
    or (select count(*) from scouting.players)<>v_before_players+29
    or (select count(*) from scouting.player_squads where club_id=v_club)<>31 then
    raise exception 'Stable identity failed across Primera / Reserva: %',v_result;
  end if;
  select id into v_player from scouting.players where source_key='tm-player-'||(v_tm_base+1)::text;
  if (select count(*) from scouting.players where id in (select (p->>'id')::uuid from jsonb_array_elements(v_before_existing)p))<>v_before_players
    or (select coalesce(jsonb_agg(to_jsonb(p) order by p.id),'[]'::jsonb) from scouting.players p
      where id in (select (x->>'id')::uuid from jsonb_array_elements(v_before_existing)x))<>v_before_existing then
    raise exception 'Import changed unrelated player identities or verified details';
  end if;
  select jsonb_build_object('recommendations',(select coalesce(jsonb_agg(to_jsonb(r) order by r.id),'[]'::jsonb) from scouting.recommendations r),
    'events',(select coalesce(jsonb_agg(to_jsonb(e) order by e.id),'[]'::jsonb) from scouting.events e)) into v_after_history;
  if v_after_history<>v_before_history then raise exception 'Roster import mutated recommendation history';end if;
  if (scouting.import_roster_batch(v_document,v_hash)->>'replayed')::boolean is not true
    or (select count(*) from scouting.players)<>v_before_players+29 then raise exception 'Import replay duplicated rows';end if;
  begin
    perform scouting.import_roster_batch(v_document||jsonb_build_object('changed',true),v_hash);
    raise exception 'Replay accepted changed content';
  exception when others then
    if sqlerrm='Replay accepted changed content' then raise;end if;
    if sqlerrm not like 'Batch key already exists%' then raise;end if;
  end;

  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_club,'category','Primera'));
  if jsonb_array_length(v_response->'items')<>25 or v_response->>'next_cursor'<>'25'
    or (v_response->>'total_count')::integer<>28 or v_response#>>'{squad,status}'<>'verified'
    or (v_response#>>'{squad,player_count}')::integer<>28 then raise exception 'First-team pagination/coverage wrong: %',v_response;end if;
  v_response2:=public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_club,'category','Primera','cursor','25'));
  if jsonb_array_length(v_response2->'items')<>3 or v_response2->>'next_cursor' is not null
    or (v_response2->>'total_count')::integer<>28 then raise exception 'Final roster page missing';end if;
  if exists(select 1 from jsonb_array_elements(v_response->'items') a join jsonb_array_elements(v_response2->'items') b on a->>'id'=b->>'id') then
    raise exception 'Roster pagination duplicated a player';end if;
  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_club,'category','Reserva'));
  if (v_response->>'total_count')::integer<>3 or v_response#>>'{squad,status}'<>'verified'
    or v_response#>>'{squad,source_season}'<>'26/27' or v_response#>>'{squad,competition_season}'<>'2026'
    or not exists(select 1 from jsonb_array_elements(v_response->'items')p where p->>'id'=v_player::text and p->>'category'='Reserva') then
    raise exception 'Reserve roster lost a shared player identity';end if;
  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_club,'category','Primera','query','not a player'));
  if (v_response->>'total_count')::integer<>0 or (v_response#>>'{squad,player_count}')::integer<>28
    or v_response#>>'{squad,status}'<>'verified' then raise exception 'Search miss confused with missing roster';end if;
  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_other,'category','Primera'));
  if (v_response->>'total_count')::integer<>0 or v_response#>>'{squad,status}'<>'not_loaded' then raise exception 'Missing roster incorrectly reported verified';end if;
  insert into scouting.squad_reviews(club_id,category,season,source,source_url,checked_at,completeness,expected_count,imported_count,notes)
    values(v_other,'Primera','2026','verified_manual','https://www.transfermarkt.com/synthetic-blocked/kader/verein/99999994',
      clock_timestamp(),'unavailable',null,0,'Synthetic failed source attempt');
  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_other,'category','Primera'));
  if v_response#>>'{squad,status}'<>'unavailable' or v_response#>>'{squad,checked_at}' is not null
    or v_response#>>'{squad,last_attempt_at}' is null then raise exception 'Unavailable source falsely presented a verified roster timestamp';end if;
  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_club));
  if (v_response->>'total_count')::integer<>29 then raise exception 'Unfiltered query duplicated multi-category identity';end if;
  begin
    perform public.scouting_api(repeat('x',64),'players',jsonb_build_object('club_id',v_club));
    raise exception 'Players endpoint accepted invalid session';
  exception when sqlstate 'PT401' then null;end;

  v_payload:=jsonb_build_object('panel_context','socio','club_id',v_club,'competition_id',v_comp,'category','Primera',
    'player_id',v_player,'player',jsonb_build_object('position','Lateral'),'reason','Synthetic first-team recommendation for a shared player.');
  v_result:=public.scouting_api(v_token,'create',v_payload||jsonb_build_object('request_id',gen_random_uuid()));
  v_rec:=(v_result#>>'{recommendation,id}')::uuid;
  v_result:=public.scouting_api(v_token,'create',v_payload||jsonb_build_object('request_id',gen_random_uuid(),'category','Reserva'));
  if v_result#>>'{recommendation,player,id}'<>v_player::text or v_result#>>'{recommendation,category}'<>'Reserva' then
    raise exception 'Reserve recommendation did not preserve selected category/identity';end if;
  v_result:=public.scouting_api(v_token,'dashboard','{}'::jsonb);
  if not exists(select 1 from jsonb_array_elements(v_result#>'{dashboard,most_recommended_players}')r
    where r->>'player_id'=v_player::text and (r->>'recommendation_count')::integer=2) then raise exception 'Cross-category ranking split one person';end if;
  begin
    perform public.scouting_api(v_token,'create',v_payload||jsonb_build_object('request_id',gen_random_uuid(),'category','Sub-15'));
    raise exception 'Create accepted absent player category';
  exception when sqlstate 'PT422' then null;end;
  begin
    perform public.scouting_api(v_token,'create',v_payload||jsonb_build_object('request_id',gen_random_uuid(),'club_id',v_other));
    raise exception 'Create accepted foreign club';
  exception when sqlstate 'PT422' then null;end;

  -- A specifically reviewed category correction may retire only the old
  -- membership. Both complete source rosters are required, and the existing
  -- recommendation remains committed to its original category and player UUID.
  select id into v_retired_player from scouting.players where source_key='tm-player-'||(v_tm_base+2)::text;
  v_result:=public.scouting_api(v_token,'create',v_payload||jsonb_build_object('request_id',gen_random_uuid(),'player_id',v_retired_player));
  v_retired_rec:=(v_result#>>'{recommendation,id}')::uuid;
  select to_jsonb(r) into v_retired_history from scouting.recommendations r where id=v_retired_rec;
  select jsonb_build_object(
    'expected_players_sha256',encode(extensions.digest(convert_to((select jsonb_agg(to_jsonb(p) order by p.id) from scouting.players p)::text,'UTF8'),'sha256'),'hex'),
    'expected_clubs_sha256',encode(extensions.digest(convert_to((select jsonb_agg(to_jsonb(c) order by c.id) from scouting.clubs c)::text,'UTF8'),'sha256'),'hex')) into v_current_fingerprints;
  v_correction:=jsonb_set(v_document,'{metadata}',v_metadata||v_current_fingerprints||jsonb_build_object('batch_key',v_key||'-category'));
  v_correction:=jsonb_set(jsonb_set(v_correction,'{squads,0,players}',v_rows-1),'{squads,0,expected_count}','27'::jsonb);
  v_correction:=jsonb_set(jsonb_set(v_correction,'{squads,0,checked_at}',to_jsonb(clock_timestamp())),
    '{squads,1,checked_at}',to_jsonb(clock_timestamp()));
  v_correction:=v_correction||jsonb_build_object('membership_retirements',jsonb_build_array(jsonb_build_object(
    'transfermarkt_id',(v_tm_base+2)::text,'club_source_key',v_key,'category','Primera','replacement_category','Reserva',
    'checked_at',clock_timestamp(),'reason','Verified synthetic projection: absent from full Primera and present in full Reserva.',
    'source_urls',jsonb_build_array(v_document#>>'{squads,0,source_url}',v_document#>>'{squads,1,source_url}'))));
  v_bad:=jsonb_set(jsonb_set(v_correction,'{metadata,batch_key}',to_jsonb(v_key||'-partial-correction')),'{squads,0,completeness}','"partial"'::jsonb);
  begin
    perform scouting.import_roster_batch(v_bad,repeat('e',64));
    raise exception 'Partial squad retired a membership';
  exception when others then
    if sqlerrm='Partial squad retired a membership' then raise;end if;
    if sqlerrm not like 'Category correction requires both fresh complete source rosters%' then raise;end if;
  end;
  v_result:=scouting.import_roster_batch(v_correction,repeat('f',64));
  if (v_result->>'membership_retirements')::integer<>1
    or scouting.player_has_squad(v_retired_player,v_club,'Primera')
    or not scouting.player_has_squad(v_retired_player,v_club,'Reserva')
    or (select category from scouting.players where id=v_retired_player)<>'Reserva'
    or (select count(*) from scouting.players)<>v_before_players+29
    or (select to_jsonb(r) from scouting.recommendations r where id=v_retired_rec)<>v_retired_history then
    raise exception 'Explicit category projection correction changed identity/history or failed to move only membership';end if;

  -- An explicitly retired membership must not resurrect through the legacy row.
  update scouting.player_squads set active=false where player_id=v_player and club_id=v_club and category='Primera';
  if scouting.player_has_squad(v_player,v_club,'Primera') then raise exception 'Inactive membership resurrected from players.category';end if;
  if not scouting.player_has_squad(v_player,v_club,'Reserva') then raise exception 'Independent reserve membership was retired';end if;
  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_club,'category','Primera'));
  if (v_response->>'total_count')::integer<>26 or v_response#>>'{squad,status}'<>'partial' then raise exception 'Coverage stayed complete after membership changed';end if;
  v_result:=public.scouting_api(v_token,'detail',jsonb_build_object('id',v_rec));
  if v_result#>>'{recommendation,player,id}'<>v_player::text or v_result#>>'{recommendation,category}'<>'Primera' then
    raise exception 'Catalogue membership update rewrote historical recommendation';end if;

  -- Concurrent catalogue changes invalidate the reviewed fingerprint.
  v_bad:=jsonb_set(v_document,'{metadata,batch_key}',to_jsonb(v_key||'-stale'));
  begin
    perform scouting.import_roster_batch(v_bad,repeat('b',64));
    raise exception 'Stale import overwrote new catalogue state';
  exception when others then
    if sqlerrm='Stale import overwrote new catalogue state' then raise;end if;
    if sqlerrm not like 'Players changed since review:%' then raise;end if;
  end;
  -- Source conflicts are reviewable, not arbitrary moves based on loop order.
  select jsonb_build_object(
    'expected_players_sha256',encode(extensions.digest(convert_to((select jsonb_agg(to_jsonb(p) order by p.id) from scouting.players p)::text,'UTF8'),'sha256'),'hex'),
    'expected_clubs_sha256',encode(extensions.digest(convert_to((select jsonb_agg(to_jsonb(c) order by c.id) from scouting.clubs c)::text,'UTF8'),'sha256'),'hex')) into v_current_fingerprints;
  v_bad:=jsonb_build_object('metadata',v_metadata||v_current_fingerprints||jsonb_build_object('batch_key',v_key||'-conflict'),
    'squads',jsonb_build_array(jsonb_build_object('club_source_key',v_key||'-other','category','Primera','season','2026',
      'source','verified_manual','source_url','https://www.transfermarkt.com/synthetic-other/kader/verein/99999993',
      'checked_at',clock_timestamp(),'completeness','complete','expected_count',1,'players',jsonb_build_array(v_rows->0))));
  v_result:=scouting.import_roster_batch(v_bad,repeat('c',64));
  if (v_result->>'observations_skipped')::integer<>1 or (select club_id from scouting.players where id=v_player)<>v_club
    or exists(select 1 from scouting.player_squads where player_id=v_player and club_id=v_other) then raise exception 'Conflicting source moved an existing player';end if;
  select to_jsonb(m) into v_before_membership from scouting.player_squads m where player_id=v_player and club_id=v_club and category='Primera';
  v_bad:=jsonb_set(jsonb_set(v_bad,'{metadata,batch_key}',to_jsonb(v_key||'-inactive')),'{squads,0,club_source_key}',to_jsonb(v_key));
  v_result:=scouting.import_roster_batch(v_bad,repeat('d',64));
  if (v_result->>'observations_skipped')::integer<>1
    or (select to_jsonb(m) from scouting.player_squads m where player_id=v_player and club_id=v_club and category='Primera')<>v_before_membership then
    raise exception 'Import modified or reactivated a deliberately inactive membership';end if;
  if has_table_privilege('anon','scouting.player_squads','SELECT') or has_table_privilege('authenticated','scouting.squad_reviews','SELECT')
    or has_function_privilege('service_role','scouting.import_roster_batch(jsonb,text)','EXECUTE')
    or has_function_privilege('anon','public.scouting_api(text,text,jsonb)','EXECUTE') then raise exception 'Private catalogue grants expanded';end if;
  -- A previous season review must not make a new squad look complete merely
  -- because its count coincidentally matches. Unfiltered selections must use a
  -- current membership rather than a stale higher-priority Primera row.
  insert into scouting.club_competitions(club_id,competition_id,season,checked_at)
    values(v_club,v_comp,'2027',clock_timestamp());
  update scouting.competitions set season='2027' where id=v_comp;
  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_club,'category','Reserva'));
  if (v_response->>'total_count')::integer<>0 or v_response#>>'{squad,status}'<>'not_loaded'
    or v_response#>>'{squad,source_url}' is not null then raise exception 'Previous season roster/review leaked into the current projection';end if;
  update scouting.player_squads set season='2027' where club_id=v_club and category='Reserva';
  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_club,'category','Reserva'));
  if (v_response->>'total_count')::integer<>3 or v_response#>>'{squad,status}'<>'partial'
    or v_response#>>'{squad,expected_count}' is not null then raise exception 'Old same-size review falsely verified a new season';end if;
  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_club));
  if (v_response->>'total_count')::integer<>3 or exists(select 1 from jsonb_array_elements(v_response->'items')p where p->>'category'<>'Reserva') then
    raise exception 'Unfiltered roster selected a stale category label';end if;
  if public.blockchain_envio_habilitado() then raise exception 'Roster change enabled blockchain sending';end if;
  if (select count(*) from scouting.events)<>v_before_events+3 then raise exception 'Importer added unexpected recommendation events';end if;
  raise notice 'Scouting roster regression passed: import/replay, stable multi-category identity, full pagination, coverage, source conflict, history and authorization';
end;
$roster_test$;
rollback;
