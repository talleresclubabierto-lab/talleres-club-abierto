-- Integration regression for the current-season projection.
-- Run after the shared-dashboard migration, as a database test operator.
-- All identities, clubs and competitions are synthetic. No real session is read.
-- ALWAYS execute the entire BEGIN / ROLLBACK block. No external worker is invoked.
begin;
set local statement_timeout = '45s';
set local lock_timeout = '5s';

do $season_test$
declare
  v_owner bigint := 880000000000000 + (floor(random()*1000000000))::bigint;
  v_token text := encode(extensions.gen_random_bytes(32),'hex');
  v_admin bigint := v_owner+1;
  v_admin_token text := encode(extensions.gen_random_bytes(32),'hex');
  v_suffix text := replace(gen_random_uuid()::text,'-','');
  v_comp_a text;
  v_comp_b text;
  v_comp_legacy text;
  v_comp_inactive text;
  v_marker text;
  v_moving uuid := gen_random_uuid();
  v_same uuid := gen_random_uuid();
  v_legacy uuid := gen_random_uuid();
  v_historical uuid := gen_random_uuid();
  v_unclassified uuid := gen_random_uuid();
  v_payload jsonb;
  v_2026_payload jsonb;
  v_2026_recommendation uuid;
  v_2026_snapshot jsonb;
  v_manual_2026_id uuid;
  v_manual_2026_snapshot jsonb;
  v_validated_club uuid;
  v_before_history jsonb;
  v_after_history jsonb;
  v_result jsonb;
  v_item jsonb;
  v_before_recommendations integer;
  v_before_events integer;
  v_before_requests integer;
  v_def_md5 text;
  v_check_count integer := 0;
begin
  v_def_md5 := md5(pg_get_functiondef('public.scouting_api(text,text,jsonb)'::regprocedure));
  if v_def_md5 <> '8a135faf5ebfd96e1ac61c5e260a7536' then
    raise exception 'Install the reviewed dashboard patch, which preserves the current-season projection, before running this regression';
  end if;
  v_comp_a := 'qa-season-a-' || left(v_suffix,12);
  v_comp_b := 'qa-season-b-' || left(v_suffix,12);
  v_comp_legacy := 'qa-season-legacy-' || left(v_suffix,12);
  v_comp_inactive := 'qa-season-inactive-' || left(v_suffix,12);
  v_marker := 'SCOUTING SEASON ' || v_suffix;

  -- Fail on any identity collision instead of reusing an existing member.
  insert into public.socios(numero_socio,nombre,fecha_alta,habilitado)
    values(v_owner,'SCOUTING SEASON SYNTHETIC MEMBER',current_date,true);
  insert into public.socios(numero_socio,nombre,fecha_alta,habilitado)
    values(v_admin,'SCOUTING SEASON SYNTHETIC ADMIN',current_date,true);
  insert into public.administradores(numero_socio,habilitado,es_principal) values(v_admin,true,false);
  perform public.crear_sesion_segura_interno(v_owner,v_token,5,'scouting_season_test','{}'::jsonb);
  perform public.crear_sesion_segura_interno(v_admin,v_admin_token,5,'scouting_season_test','{}'::jsonb);
  insert into scouting.competitions(id,name,season,sort_order,active) values
    (v_comp_a,'Season fixture A','2026',901,true),
    (v_comp_b,'Season fixture B','2026',902,true),
    (v_comp_legacy,'Season fixture independent 2026','2026',903,true),
    (v_comp_inactive,'Season fixture inactive','2027',904,false);
  insert into scouting.clubs(id,source_key,name,province,city,league,source,source_urls,checked_at) values
    (v_moving,'qa:'||v_suffix||':moving',v_marker||' MOVING','Córdoba','Localidad de prueba','Liga de prueba','verified_manual','[]'::jsonb,clock_timestamp()),
    (v_same,'qa:'||v_suffix||':same',v_marker||' SAME','Córdoba','Localidad de prueba','Liga de prueba','verified_manual','[]'::jsonb,clock_timestamp()),
    (v_legacy,'qa:'||v_suffix||':legacy',v_marker||' LEGACY','Córdoba','Localidad de prueba','Liga de prueba','verified_manual','[]'::jsonb,clock_timestamp()),
    (v_historical,'qa:'||v_suffix||':historical',v_marker||' HISTORICAL','Córdoba','Localidad de prueba','Liga de prueba','verified_manual','[]'::jsonb,clock_timestamp()),
    (v_unclassified,'qa:'||v_suffix||':unclassified',v_marker||' UNCLASSIFIED','Córdoba','Localidad de prueba','Liga de prueba','verified_manual','[]'::jsonb,clock_timestamp());
  insert into scouting.club_competitions(club_id,competition_id,season,division,reference_scope,source_urls,checked_at) values
    (v_moving,v_comp_a,'2026','Moving A 2026','primer_equipo_masculino','[]'::jsonb,clock_timestamp()),
    (v_moving,v_comp_b,'2027','Moving B 2027','primer_equipo_masculino','[]'::jsonb,clock_timestamp()),
    (v_moving,v_comp_inactive,'2027','Hidden inactive','inactive_scope','[]'::jsonb,clock_timestamp()),
    (v_same,v_comp_a,'2026','Same division 2026','scope_2026','[]'::jsonb,clock_timestamp()),
    (v_same,v_comp_a,'2027','Same division 2027','scope_2027','[]'::jsonb,clock_timestamp()),
    (v_legacy,v_comp_legacy,'2026','Independent 2026','primer_equipo_masculino','[]'::jsonb,clock_timestamp()),
    (v_historical,v_comp_a,'2026','Historical only 2026','primer_equipo_masculino','[]'::jsonb,clock_timestamp());

  select jsonb_agg(to_jsonb(cc) order by cc.club_id,cc.competition_id,cc.season)
    into v_before_history from scouting.club_competitions cc
    where club_id in (v_moving,v_same,v_legacy,v_historical,v_unclassified);
  v_payload := jsonb_build_object('panel_context','socio','category','Sub-17','player_id',null,
    'player',jsonb_build_object('first_name','SYNTHETIC','last_name','SEASON TEST','position','Lateral','sector','derecha'),
    'reason','Referencia deportiva ficticia para comprobar la proyección de temporadas',
    'observation',null,'video_url',null,'transfermarkt_url',null);

  -- 1. Bootstrap reflects configured seasons, independent of the calendar year.
  v_result := public.scouting_api(v_token,'bootstrap','{}'::jsonb);
  if not exists(select 1 from jsonb_array_elements(v_result->'competitions') x where x->>'id'=v_comp_a and x->>'season'='2026')
    or exists(select 1 from jsonb_array_elements(v_result->'competitions') x where x->>'id'=v_comp_inactive) then
    raise exception 'bootstrap season/active competition projection failed';
  end if;
  v_check_count := v_check_count+1;

  -- 2. A future affiliation is neither selected nor listed in nested competitions.
  v_result := public.scouting_api(v_token,'clubs',jsonb_build_object('province','Córdoba','query',v_marker||' MOVING'));
  if jsonb_array_length(v_result->'items')<>1 then raise exception 'moving club missing before rollover';end if;
  v_item := v_result#>'{items,0}';
  if v_item->>'competition_id' is distinct from v_comp_a or v_item->>'season' is distinct from '2026'
    or jsonb_array_length(v_item->'competitions')<>1
    or v_item#>>'{competitions,0,id}' is distinct from v_comp_a
    or v_item#>>'{competitions,0,season}' is distinct from '2026' then
    raise exception 'future or inactive relationship leaked before rollover';
  end if;
  v_result := public.scouting_api(v_token,'clubs',jsonb_build_object('competition_id',v_comp_b,'query',v_marker||' MOVING'));
  if jsonb_array_length(v_result->'items')<>0 then raise exception 'future B affiliation was selectable in 2026';end if;
  v_check_count := v_check_count+1;

  -- 3. An explicit future affiliation is rejected, even though its history row exists.
  begin
    perform public.scouting_api(v_token,'create',v_payload||jsonb_build_object(
      'request_id',gen_random_uuid(),'club_id',v_moving,'competition_id',v_comp_b));
    raise exception 'future relationship was accepted by create';
  exception when sqlstate 'PT422' then null;
  end;
  v_check_count := v_check_count+1;

  -- 4. The current 2026 affiliation creates a recommendation; category stays independent.
  v_2026_payload := v_payload||jsonb_build_object(
    'request_id',gen_random_uuid(),'club_id',v_moving,'competition_id',v_comp_a);
  v_result := public.scouting_api(v_token,'create',v_2026_payload);
  v_2026_recommendation := (v_result#>>'{recommendation,id}')::uuid;
  select snapshot into v_2026_snapshot from scouting.recommendations where id=v_2026_recommendation;
  if v_2026_snapshot#>>'{club,competition_id}' is distinct from v_comp_a
    or v_2026_snapshot#>>'{club,season}' is distinct from '2026'
    or v_2026_snapshot->>'category' is distinct from 'Sub-17' then
    raise exception 'valid 2026 recommendation or independent player category failed';
  end if;
  v_check_count := v_check_count+1;

  -- 5. Same competition, two seasons: snapshot must not borrow future division/scope.
  v_result := public.scouting_api(v_token,'create',v_payload||jsonb_build_object(
    'request_id',gen_random_uuid(),'club_id',v_same,'competition_id',v_comp_a));
  if v_result#>>'{recommendation,club,season}' is distinct from '2026'
    or v_result#>>'{recommendation,club,division}' is distinct from 'Same division 2026'
    or v_result#>>'{recommendation,club,reference_scope}' is distinct from 'scope_2026' then
    raise exception 'future division or scope leaked into 2026 snapshot';
  end if;
  v_check_count := v_check_count+1;

  -- A manual recommendation is submitted while A's configured season is still 2026.
  v_result := public.scouting_api(v_token,'create',v_payload||jsonb_build_object(
    'request_id',gen_random_uuid(),'club_id',null,'competition_id',v_comp_a,
    'club_manual',jsonb_build_object('province','Córdoba','city','Localidad de prueba','name',v_marker||' MANUAL OLD','league','Liga de prueba')));
  v_manual_2026_id := (v_result#>>'{recommendation,id}')::uuid;
  select snapshot into v_manual_2026_snapshot from scouting.recommendations where id=v_manual_2026_id;
  if v_manual_2026_snapshot#>>'{club,season}' is distinct from '2026' then
    raise exception 'manual historical fixture did not capture season 2026';
  end if;

  -- Activate 2027 only for these two synthetic competitions, preserving all memberships.
  update scouting.competitions set season='2027' where id in (v_comp_a,v_comp_b);

  -- 6. Moving club leaves A's current projection and appears only in B.
  v_result := public.scouting_api(v_token,'clubs',jsonb_build_object('competition_id',v_comp_a,'query',v_marker||' MOVING'));
  if jsonb_array_length(v_result->'items')<>0 then raise exception '2026 A affiliation remained selectable after rollover';end if;
  v_result := public.scouting_api(v_token,'clubs',jsonb_build_object('competition_id',v_comp_b,'query',v_marker||' MOVING'));
  if jsonb_array_length(v_result->'items')<>1 then raise exception '2027 B affiliation missing after rollover';end if;
  v_item := v_result#>'{items,0}';
  if v_item->>'competition_id' is distinct from v_comp_b or v_item->>'season' is distinct from '2027'
    or v_item->>'division' is distinct from 'Moving B 2027'
    or jsonb_array_length(v_item->'competitions')<>1
    or v_item#>>'{competitions,0,id}' is distinct from v_comp_b
    or v_item#>>'{competitions,0,season}' is distinct from '2027' then
    raise exception 'nested or selected competition disagrees with current season';
  end if;
  v_check_count := v_check_count+1;

  -- 7. Rejected stale/inactive creates leave no recommendation, event or request.
  select count(*) into v_before_recommendations from scouting.recommendations where owner_numero_socio=v_owner;
  select count(*) into v_before_events from scouting.events where actor_numero_socio=v_owner;
  select count(*) into v_before_requests from scouting.requests where actor_numero_socio=v_owner;
  begin
    perform public.scouting_api(v_token,'create',v_payload||jsonb_build_object(
      'request_id',gen_random_uuid(),'club_id',v_moving,'competition_id',v_comp_a));
    raise exception 'expired relationship was accepted by create';
  exception when sqlstate 'PT422' then null;
  end;
  begin
    perform public.scouting_api(v_token,'create',v_payload||jsonb_build_object(
      'request_id',gen_random_uuid(),'club_id',v_moving,'competition_id',v_comp_inactive));
    raise exception 'inactive relationship was accepted by create';
  exception when sqlstate 'PT422' then null;
  end;
  if (select count(*) from scouting.recommendations where owner_numero_socio=v_owner)<>v_before_recommendations
    or (select count(*) from scouting.events where actor_numero_socio=v_owner)<>v_before_events
    or (select count(*) from scouting.requests where actor_numero_socio=v_owner)<>v_before_requests then
    raise exception 'rejected relationship create left persisted side effects';
  end if;
  v_check_count := v_check_count+1;

  -- 8. Idempotent replay of the original 2026 request still returns its historical snapshot.
  v_result := public.scouting_api(v_token,'create',v_2026_payload);
  if v_result->>'replayed' is distinct from 'true'
    or v_result#>>'{recommendation,id}' is distinct from v_2026_recommendation::text
    or v_result#>>'{recommendation,club,season}' is distinct from '2026'
    or (select snapshot from scouting.recommendations where id=v_2026_recommendation) is distinct from v_2026_snapshot then
    raise exception 'historical idempotent replay changed after rollover';
  end if;
  v_check_count := v_check_count+1;

  -- 9. Explicit and automatic choices agree on the active 2027 membership.
  v_result := public.scouting_api(v_token,'create',v_payload||jsonb_build_object(
    'request_id',gen_random_uuid(),'club_id',v_moving,'competition_id',v_comp_b));
  if v_result#>>'{recommendation,club,competition_id}' is distinct from v_comp_b
    or v_result#>>'{recommendation,club,season}' is distinct from '2027'
    or v_result#>>'{recommendation,club,division}' is distinct from 'Moving B 2027' then
    raise exception 'explicit 2027 recommendation failed';
  end if;
  v_result := public.scouting_api(v_token,'create',v_payload||jsonb_build_object(
    'request_id',gen_random_uuid(),'club_id',v_moving,'competition_id',null));
  if v_result#>>'{recommendation,club,competition_id}' is distinct from v_comp_b
    or v_result#>>'{recommendation,club,season}' is distinct from '2027' then
    raise exception 'automatic 2027 recommendation selected historical membership';
  end if;
  v_check_count := v_check_count+1;

  -- 10. A different competition can remain in 2026; no global MAX/year assumption.
  v_result := public.scouting_api(v_token,'clubs',jsonb_build_object('competition_id',v_comp_legacy,'query',v_marker||' LEGACY'));
  if jsonb_array_length(v_result->'items')<>1 or v_result#>>'{items,0,season}' is distinct from '2026' then
    raise exception 'independent current 2026 competition was hidden';
  end if;
  v_result := public.scouting_api(v_token,'create',v_payload||jsonb_build_object(
    'request_id',gen_random_uuid(),'club_id',v_legacy,'competition_id',v_comp_legacy));
  if v_result#>>'{recommendation,club,season}' is distinct from '2026' then
    raise exception 'independent current 2026 create failed';
  end if;
  v_check_count := v_check_count+1;

  -- 11. Historical-only and unclassified clubs remain available by province,
  -- without inventing a current competition. They can still receive recommendations.
  v_result := public.scouting_api(v_token,'clubs',jsonb_build_object('province','Córdoba','query',v_marker||' HISTORICAL'));
  if jsonb_array_length(v_result->'items')<>1 or v_result#>>'{items,0,competition_id}' is not null
    or jsonb_array_length(v_result#>'{items,0,competitions}')<>0 then
    raise exception 'historical-only club was hidden or incorrectly assigned a current competition';
  end if;
  v_result := public.scouting_api(v_token,'create',v_payload||jsonb_build_object(
    'request_id',gen_random_uuid(),'club_id',v_historical,'competition_id',null));
  if v_result#>>'{recommendation,club,competition_id}' is not null
    or v_result#>>'{recommendation,club,season}' is not null then
    raise exception 'implicit create borrowed an expired membership';
  end if;
  v_result := public.scouting_api(v_token,'create',v_payload||jsonb_build_object(
    'request_id',gen_random_uuid(),'club_id',v_unclassified,'competition_id',null));
  if v_result#>>'{recommendation,club,competition_id}' is not null then
    raise exception 'unclassified catalogue club compatibility failed';
  end if;
  v_check_count := v_check_count+1;

  -- 12. Otro club retains its existing declared-competition behavior.
  v_result := public.scouting_api(v_token,'create',v_payload||jsonb_build_object(
    'request_id',gen_random_uuid(),'club_id',null,'competition_id',v_comp_legacy,
    'club_manual',jsonb_build_object('province','Córdoba','city','Localidad de prueba','name',v_marker||' MANUAL','league','Liga de prueba')));
  if v_result#>>'{recommendation,club,source}' is distinct from 'manual'
    or v_result#>>'{recommendation,club,season}' is distinct from '2026' then
    raise exception 'manual club compatibility failed';
  end if;
  v_check_count := v_check_count+1;

  -- 13. Active 2027 snapshot attributes switch together for the same competition.
  v_result := public.scouting_api(v_token,'create',v_payload||jsonb_build_object(
    'request_id',gen_random_uuid(),'club_id',v_same,'competition_id',v_comp_a));
  if v_result#>>'{recommendation,club,season}' is distinct from '2027'
    or v_result#>>'{recommendation,club,division}' is distinct from 'Same division 2027'
    or v_result#>>'{recommendation,club,reference_scope}' is distinct from 'scope_2027' then
    raise exception 'current 2027 snapshot attributes failed';
  end if;
  v_check_count := v_check_count+1;

  -- 14. Validating a manual 2026 recommendation in 2027 preserves its declared season.
  v_result := public.scouting_api(v_admin_token,'admin_validate_club',jsonb_build_object(
    'id',v_manual_2026_id,'request_id',gen_random_uuid(),
    'message','Validación sintética del club según la temporada de la recomendación original'));
  select club_id into v_validated_club from scouting.club_validations where recommendation_id=v_manual_2026_id;
  if v_validated_club is null
    or not exists(select 1 from scouting.club_competitions where club_id=v_validated_club and competition_id=v_comp_a and season='2026')
    or exists(select 1 from scouting.club_competitions where club_id=v_validated_club and season='2027')
    or (select snapshot from scouting.recommendations where id=v_manual_2026_id) is distinct from v_manual_2026_snapshot then
    raise exception 'historical manual club validation invented 2027 membership or changed snapshot';
  end if;
  v_result := public.scouting_api(v_token,'clubs',jsonb_build_object('competition_id',v_comp_a,'query',v_marker||' MANUAL OLD'));
  if jsonb_array_length(v_result->'items')<>0 then
    raise exception 'newly validated historical club leaked into current 2027 competition';
  end if;
  v_result := public.scouting_api(v_token,'clubs',jsonb_build_object('province','Córdoba','query',v_marker||' MANUAL OLD'));
  if jsonb_array_length(v_result->'items')<>1 or v_result#>>'{items,0,competition_id}' is not null
    or jsonb_array_length(v_result#>'{items,0,competitions}')<>0 then
    raise exception 'historically validated club is unavailable or has invented current affiliation';
  end if;
  v_check_count := v_check_count+1;

  -- 15. No history row, prior snapshot, function property or permission is rewritten.
  select jsonb_agg(to_jsonb(cc) order by cc.club_id,cc.competition_id,cc.season)
    into v_after_history from scouting.club_competitions cc
    where club_id in (v_moving,v_same,v_legacy,v_historical,v_unclassified);
  if v_before_history is distinct from v_after_history
    or (select snapshot from scouting.recommendations where id=v_2026_recommendation) is distinct from v_2026_snapshot
    or md5(pg_get_functiondef('public.scouting_api(text,text,jsonb)'::regprocedure))<>v_def_md5 then
    raise exception 'season rollover changed historical data or RPC definition';
  end if;
  if not exists(select 1 from pg_proc p where p.oid='public.scouting_api(text,text,jsonb)'::regprocedure
    and p.prosecdef and p.proconfig=array['search_path=pg_catalog'])
    or has_function_privilege('anon','public.scouting_api(text,text,jsonb)','EXECUTE')
    or has_function_privilege('authenticated','public.scouting_api(text,text,jsonb)','EXECUTE')
    or not has_function_privilege('service_role','public.scouting_api(text,text,jsonb)','EXECUTE') then
    raise exception 'RPC execution settings or privileges differ from the current contract';
  end if;
  v_check_count := v_check_count+1;
  raise notice 'Scouting season regression passed: % grouped behavioral checks; all fixtures will roll back',v_check_count;
end;
$season_test$;

rollback;
