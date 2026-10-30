-- Synthetic integration regression. Run after the scouting dashboard migration.
-- No real member/session is read or reused. No worker or chain transaction is sent.
-- ALWAYS retain the outer ROLLBACK. To combine with a migration dry run, use one
-- external transaction and omit only this file's BEGIN / ROLLBACK.
begin;
set local statement_timeout='90s';
set local lock_timeout='5s';

do $dashboard_test$
declare
  v_owner bigint:=881000000000000+(floor(random()*1000000000))::bigint;
  v_other bigint:=v_owner+1;
  v_admin bigint:=v_owner+2;
  v_token text:=encode(extensions.gen_random_bytes(32),'hex');
  v_token_other text:=encode(extensions.gen_random_bytes(32),'hex');
  v_token_admin text:=encode(extensions.gen_random_bytes(32),'hex');
  v_suffix text:=left(replace(gen_random_uuid()::text,'-',''),12);
  v_marker text;
  v_club uuid:=gen_random_uuid();
  v_player uuid:=gen_random_uuid();
  v_homonym uuid:=gen_random_uuid();
  v_comp text;
  v_today date:=(clock_timestamp() at time zone 'America/Argentina/Cordoba')::date;
  v_payload jsonb;
  v_request jsonb;
  v_replay_request jsonb;
  v_result jsonb;
  v_detail jsonb;
  v_before jsonb;
  v_dashboard jsonb;
  v_admin_dashboard jsonb;
  v_snapshot jsonb;
  v_initial_snapshot jsonb;
  v_rank jsonb;
  v_ids uuid[]:=array[]::uuid[];
  v_status text;
  v_bad_age jsonb;
  v_i integer;
  v_before_event_count integer;
  v_contact_event uuid;
  v_contact_audit bigint;
  v_rec_legacy uuid:=gen_random_uuid();
  v_linked_manual uuid;
  v_linked_request jsonb;
  v_legacy_event uuid:=gen_random_uuid();
  v_legacy_nonce text:=encode(extensions.gen_random_bytes(32),'hex');
  v_nonce text;
  v_hash text;
  v_hash_document jsonb;
  v_original_hash text;
  v_created timestamptz;
  v_audit bigint;
  v_context text;
  v_event record;
  v_lot uuid;
  v_proof jsonb;
  v_assertions integer:=0;
begin
  v_marker:='SCOUTING DASHBOARD '||v_suffix;
  v_comp:='qa-dashboard-'||v_suffix;
  insert into public.socios(numero_socio,nombre,fecha_alta,habilitado) values
    (v_owner,'SCOUTING DASHBOARD SYNTHETIC OWNER',current_date,true),
    (v_other,'SCOUTING DASHBOARD SYNTHETIC OTHER',current_date,true),
    (v_admin,'SCOUTING DASHBOARD SYNTHETIC ADMIN',current_date,true);
  insert into public.administradores(numero_socio,habilitado,es_principal) values(v_admin,true,false);
  perform public.crear_sesion_segura_interno(v_owner,v_token,5,'scouting_dashboard_test','{}'::jsonb);
  perform public.crear_sesion_segura_interno(v_other,v_token_other,5,'scouting_dashboard_test','{}'::jsonb);
  perform public.crear_sesion_segura_interno(v_admin,v_token_admin,5,'scouting_dashboard_test','{}'::jsonb);
  insert into scouting.competitions(id,name,season,sort_order) values(v_comp,'QA dashboard competition','2026',999);
  insert into scouting.clubs(id,source_key,name,province,city,league,source,source_urls,checked_at)
    values(v_club,'qa-dashboard:'||v_suffix,v_marker||' CLUB','Córdoba','Localidad sintética','Liga sintética',
      'verified_manual','[]'::jsonb,clock_timestamp());
  insert into scouting.club_competitions(club_id,competition_id,season,division,reference_scope,checked_at)
    values(v_club,v_comp,'2026','QA division','primer_equipo_masculino',clock_timestamp());
  insert into scouting.players(id,source_key,club_id,first_name,last_name,category,position,source,checked_at,
    birth_date,birth_date_source_url,birth_date_verified_at,
    market_value_amount,market_value_currency,market_value_source_url,market_value_as_of,market_value_verified_at,market_value_verified)
    values(v_player,'qa-dashboard:player:'||v_suffix,v_club,v_marker,'Homónimo','Primera','Lateral','verified_manual',clock_timestamp(),
      (v_today-interval '20 years')::date,'https://www.transfermarkt.com/synthetic/profil/spieler/99900001',clock_timestamp(),
      100000,'EUR','https://www.transfermarkt.com/synthetic/profil/spieler/99900001',v_today-1,clock_timestamp(),true),
    (v_homonym,'qa-dashboard:homonym:'||v_suffix,v_club,v_marker,'Homónimo','Primera','Lateral','verified_manual',clock_timestamp(),
      null,null,null,123000,'EUR','https://www.transfermarkt.com/synthetic/profil/spieler/99900002',v_today-1,null,false);

  v_before:=public.scouting_api(v_token,'dashboard','{}'::jsonb)->'dashboard';
  if v_before->>'scope'<>'all_recommendations' or v_before->>'milestone_unit'<>'player_references'
    or v_before->>'counts_by_status_unit'<>'recommendations' then
    raise exception 'dashboard metric units are not explicit';
  end if;
  begin
    perform public.scouting_api(repeat('x',64),'dashboard','{}'::jsonb);
    raise exception 'dashboard accepted an invalid session';
  exception when sqlstate 'PT401' then null;end;
  v_assertions:=v_assertions+1;

  v_payload:=jsonb_build_object('panel_context','socio','club_id',v_club,'competition_id',v_comp,
    'category','Primera','player_id',null,
    'player',jsonb_build_object('first_name',v_marker,'last_name','Homónimo','position','Lateral',
      'sector','derecha','age_at_recommendation',17),
    'reason','QA_PRIVATE_REASON: observación deportiva sintética del tablero compartido',
    'observation','QA_PRIVATE_OBSERVATION','video_url',null,'transfermarkt_url',null);

  -- 1. Member context is required; an administrator remains an eligible member
  -- when deliberately entering through Socio Activo.
  begin
    perform public.scouting_api(v_token,'create',(v_payload-'panel_context')||jsonb_build_object('request_id',gen_random_uuid()));
    raise exception 'create without member panel context was accepted';
  exception when sqlstate 'PT403' then null;end;
  begin
    perform public.scouting_api(v_token_admin,'create',v_payload||jsonb_build_object('request_id',gen_random_uuid(),'panel_context','admin'));
    raise exception 'create in admin panel context was accepted';
  exception when sqlstate 'PT403' then null;end;
  v_assertions:=v_assertions+1;

  -- 2. No user-written market valuation can become verified. Age is optional,
  -- numeric integer years, and member-reported unless corroborated by catalogue DOB.
  begin
    perform public.scouting_api(v_token,'create',v_payload||jsonb_build_object('request_id',gen_random_uuid(),
      'market_value',jsonb_build_object('amount',999999999,'verification','verified')));
    raise exception 'member-supplied verified market value was accepted';
  exception when sqlstate 'PT422' then null;end;
  foreach v_bad_age in array array['0'::jsonb,'101'::jsonb,'-1'::jsonb,'17.5'::jsonb,'"17"'::jsonb] loop
    begin
      perform public.scouting_api(v_token,'create',jsonb_set(v_payload,'{player,age_at_recommendation}',v_bad_age)||
        jsonb_build_object('request_id',gen_random_uuid()));
      raise exception 'invalid manual age was accepted';
    exception when sqlstate 'PT422' then null;end;
  end loop;
  if scouting.player_age(date '2000-10-31',date '2026-10-30')<>25
    or scouting.player_age(date '2000-10-31',date '2026-10-31')<>26
    or scouting.player_age(null,v_today) is not null then
    raise exception 'complete-birthday or missing-age calculation failed';
  end if;
  v_assertions:=v_assertions+1;

  -- 3. Two members recommend the same verified player. A catalogue homonym and
  -- two manual homonyms remain separate references. Then 27 more records ensure
  -- statistics cannot be derived from one 25-row page.
  for v_i in 1..32 loop
    v_request:=v_payload||jsonb_build_object('request_id',gen_random_uuid(),
      'player_id',case when v_i in (1,2) then v_player when v_i=3 then v_homonym else null end);
    if v_i=1 then v_replay_request:=v_request;end if;
    v_result:=public.scouting_api(case when mod(v_i,2)=0 then v_token_other else v_token end,'create',v_request);
    v_ids:=array_append(v_ids,(v_result#>>'{recommendation,id}')::uuid);
  end loop;
  v_result:=public.scouting_api(v_token_admin,'create',v_payload||jsonb_build_object('request_id',gen_random_uuid()));
  v_ids:=array_append(v_ids,(v_result#>>'{recommendation,id}')::uuid);
  select snapshot into v_initial_snapshot from scouting.recommendations where id=v_ids[1];
  if v_initial_snapshot#>>'{player,age_at_recommendation}'<>'20'
    or v_initial_snapshot#>>'{player,age_source}'<>'catalogue_birth_date'
    or (v_initial_snapshot#>>'{player,market_value,amount}')::numeric<>100000
    or v_initial_snapshot#>>'{player,market_value,verification}'<>'verified' then
    raise exception 'catalogue age/value snapshot failed';
  end if;
  v_detail:=public.scouting_api(v_token_other,'detail',jsonb_build_object('id',v_ids[3]));
  if v_detail#>>'{recommendation,player,age_source}'<>'member_reported'
    or v_detail#>>'{recommendation,player,age_at_recommendation}'<>'17'
    or v_detail#>'{recommendation,player,market_value}' is distinct from 'null'::jsonb then
    raise exception 'unverified market value leaked or manual age was incorrectly verified';
  end if;
  v_assertions:=v_assertions+1;

  -- 4. The original creation request is idempotent, including the new age/context.
  v_result:=public.scouting_api(v_token,'create',v_replay_request);
  if v_result->>'replayed'<>'true' or v_result#>>'{recommendation,id}'<>v_ids[1]::text
    or (select count(*) from scouting.events where recommendation_id=v_ids[1])<>1 then
    raise exception 'create replay duplicated a recommendation or event';
  end if;
  v_assertions:=v_assertions+1;

  -- 5. Only an authenticated administrator changes a status, with a public reason.
  begin
    perform public.scouting_api(v_token,'admin_update',jsonb_build_object('id',v_ids[1],
      'request_id',gen_random_uuid(),'status','contactado','message','Cambio no autorizado'));
    raise exception 'member changed a tracking status';
  exception when sqlstate 'PT403' then null;end;
  begin
    perform public.scouting_api(v_token_admin,'admin_update',jsonb_build_object('id',v_ids[1],
      'request_id',gen_random_uuid(),'status','contactado','message',''));
    raise exception 'administrator changed a tracking status without a reason';
  exception when sqlstate 'PT422' then null;end;
  v_assertions:=v_assertions+1;

  -- 6. Five exact milestones: no inferred stages, no duplicate counts after retries,
  -- and accumulated achievements remain visible after moving to a later status.
  foreach v_status in array array['contactado','visitado','convocado_a_prueba','prueba_realizada','cerrada'] loop
    v_request:=jsonb_build_object('id',v_ids[1],'request_id',gen_random_uuid(),'status',v_status,
      'message','QA_ADMIN_PUBLIC_REASON: avance registrado '||v_status);
    if v_status='contactado' then v_replay_request:=v_request;end if;
    perform public.scouting_api(v_token_admin,'admin_update',v_request);
  end loop;
  select id,audit_event_id into v_contact_event,v_contact_audit from scouting.events
    where recommendation_id=v_ids[1] and event_type='status_updated' and status='contactado';
  select count(*) into v_before_event_count from scouting.events where recommendation_id=v_ids[1];
  v_result:=public.scouting_api(v_token_admin,'admin_update',v_replay_request);
  if v_result->>'replayed'<>'true' or (select count(*) from scouting.events where recommendation_id=v_ids[1])<>v_before_event_count then
    raise exception 'status update replay appended another event';
  end if;
  foreach v_status in array array['contactado','contactado','no_avanza'] loop
    perform public.scouting_api(v_token_admin,'admin_update',jsonb_build_object('id',v_ids[2],
      'request_id',gen_random_uuid(),'status',v_status,'message','Segundo aporte del mismo jugador: '||v_status));
  end loop;
  perform public.scouting_api(v_token_admin,'admin_update',jsonb_build_object('id',v_ids[3],
    'request_id',gen_random_uuid(),'status','prueba_realizada','message','Salto explícito a prueba, sin inventar visitas o contactos'));
  foreach v_status in array array['contactado','visitado','cerrada'] loop
    perform public.scouting_api(v_token_admin,'admin_update',jsonb_build_object('id',v_ids[4],
      'request_id',gen_random_uuid(),'status',v_status,'message','Primer homónimo manual: '||v_status));
  end loop;
  foreach v_status in array array['contactado','no_avanza'] loop
    perform public.scouting_api(v_token_admin,'admin_update',jsonb_build_object('id',v_ids[5],
      'request_id',gen_random_uuid(),'status',v_status,'message','Segundo homónimo manual: '||v_status));
  end loop;
  v_assertions:=v_assertions+1;

  -- 7. A genuine version-1 fixture proves backward-compatible hashing and null
  -- age/market fields without altering an immutable legacy snapshot.
  v_snapshot:=jsonb_build_object('schema_version',1,'category','Primera',
    'club',jsonb_build_object('id',v_club,'name',v_marker||' CLUB','province','Córdoba','city','Localidad sintética','source','catalogue'),
    'player',jsonb_build_object('id',v_homonym,'first_name',v_marker,'last_name','Homónimo','position','Lateral','sector','derecha','source','catalogue'),
    'reason','QA_PRIVATE_LEGACY_REASON: fixture histórico anterior al tablero','source','manual');
  v_original_hash:=encode(extensions.digest(convert_to(jsonb_build_object('schema','scouting-recommendation-v1',
    'id',v_rec_legacy,'owner',v_owner,'snapshot',v_snapshot,'nonce',v_legacy_nonce)::text,'UTF8'),'sha256'),'hex');
  insert into scouting.recommendations(id,code,owner_numero_socio,snapshot,private_nonce,commitment_hash)
    values(v_rec_legacy,'QA-'||v_suffix,v_owner,v_snapshot,v_legacy_nonce,v_original_hash);
  v_nonce:=encode(extensions.gen_random_bytes(32),'hex');v_created:=clock_timestamp();
  v_hash:=encode(extensions.digest(convert_to(jsonb_build_object('schema','scouting-event-v1','id',v_legacy_event,
    'recommendation_id',v_rec_legacy,'sequence',1,'actor',v_owner,'role','socio','type','created','status','recibida',
    'message','QA legacy creation','created_at',to_char(v_created at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'original_commitment',v_original_hash,'previous',null,'nonce',v_nonce)::text,'UTF8'),'sha256'),'hex');
  v_context:=current_setting('app.actor_socio',true);perform set_config('app.actor_socio','',true);
  v_audit:=public.registrar_auditoria_interna('SCOUTING_CREATED','scouting_commitment',v_legacy_event::text,null,
    jsonb_build_object('schema','scouting-event-v1','commitment_sha256',v_hash),null,
    jsonb_build_object('modulo','scouting','version',1),'scouting_api');
  perform set_config('app.actor_socio',coalesce(v_context,''),true);
  insert into scouting.events(id,recommendation_id,sequence_no,actor_numero_socio,actor_role,event_type,status,
    member_message,created_at,private_nonce,prev_hash,event_hash,audit_event_id,hash_version)
    values(v_legacy_event,v_rec_legacy,1,v_owner,'socio','created','recibida','QA legacy creation',v_created,v_nonce,null,v_hash,v_audit,1);
  perform public.scouting_api(v_token_admin,'admin_update',jsonb_build_object('id',v_rec_legacy,
    'request_id',gen_random_uuid(),'status','contactado','message','Primera actuación versión2 sobre una ficha versión1'));
  v_ids:=array_append(v_ids,v_rec_legacy);
  v_detail:=public.scouting_api(v_token_other,'detail',jsonb_build_object('id',v_rec_legacy));
  if v_detail#>'{recommendation,player,age_at_recommendation}' is distinct from 'null'::jsonb
    or v_detail#>'{recommendation,player,market_value}' is distinct from 'null'::jsonb
    or (select snapshot from scouting.recommendations where id=v_rec_legacy) is distinct from v_snapshot then
    raise exception 'legacy unknown age/value was invented or legacy snapshot changed';
  end if;
  v_assertions:=v_assertions+1;

  -- Explicitly recommending an existing manual reference joins only that person.
  -- The server preserves their name and root reference, while age/category are
  -- evidence for the new contribution, not copied historical facts.
  begin
    perform public.scouting_api(v_token,'create',jsonb_set(v_payload,'{player,reference_id}',to_jsonb(v_ids[4]))
      ||jsonb_build_object('request_id',gen_random_uuid()));
    raise exception 'client invented a shared player reference';
  exception when sqlstate 'PT422' then null;end;
  begin
    perform public.scouting_api(v_token,'create',v_payload||jsonb_build_object('request_id',gen_random_uuid(),
      'reference_recommendation_id',gen_random_uuid()));
    raise exception 'unknown recommendation reference was accepted';
  exception when sqlstate 'PT404' then null;end;
  begin
    perform public.scouting_api(v_token,'create',v_payload||jsonb_build_object('request_id',gen_random_uuid(),
      'reference_recommendation_id',v_ids[1],'player_id',v_homonym));
    raise exception 'reference was changed to a different catalogue identity';
  exception when sqlstate 'PT422' then null;end;
  v_linked_request:=v_payload||jsonb_build_object('request_id',gen_random_uuid(),
    'reference_recommendation_id',v_ids[4],'category','Reserva',
    'player',jsonb_build_object('first_name','A changed name must be ignored','last_name','Different',
      'position','Delantero Extremo','sector','ambos','age_at_recommendation',null),
    'reason','Nuevo aporte independiente sobre la persona seleccionada en una ficha existente');
  v_result:=public.scouting_api(v_token,'create',v_linked_request);
  v_linked_manual:=(v_result#>>'{recommendation,id}')::uuid;
  v_ids:=array_append(v_ids,v_linked_manual);
  if v_result#>>'{recommendation,player,reference_id}'<>v_ids[4]::text
    or v_result#>>'{recommendation,player,identity_verification}'<>'member_declared'
    or v_result#>>'{recommendation,player,first_name}'<>v_marker
    or v_result#>>'{recommendation,player,last_name}'<>'Homónimo'
    or v_result#>>'{recommendation,player,position}'<>'Delantero Extremo'
    or v_result#>>'{recommendation,category}'<>'Reserva'
    or v_result#>'{recommendation,player,age_at_recommendation}' is distinct from 'null'::jsonb
    or v_result#>'{recommendation,player,market_value}' is distinct from 'null'::jsonb
    or (select snapshot#>>'{player,age_at_recommendation}' from scouting.recommendations where id=v_ids[4])<>'17' then
    raise exception 'explicit manual reference changed identity, copied historical age or lost contribution context';
  end if;
  v_result:=public.scouting_api(v_token,'create',v_linked_request);
  if v_result->>'replayed'<>'true' or v_result#>>'{recommendation,id}'<>v_linked_manual::text then
    raise exception 'explicit manual reference replay failed';
  end if;
  perform public.scouting_api(v_token_admin,'admin_update',jsonb_build_object('id',v_linked_manual,
    'request_id',gen_random_uuid(),'status','contactado','message','Contacto de otro aporte de la misma persona referenciada'));
  if scouting.player_identity_key('{"player":{"source":"manual"}}'::jsonb,v_ids[4])
      <>scouting.player_identity_key((select snapshot from scouting.recommendations where id=v_linked_manual),v_linked_manual) then
    raise exception 'legacy manual fallback and explicitly linked reference diverge';
  end if;
  v_assertions:=v_assertions+1;

  -- 8. Global deduplication and historical counters exceed pagination boundaries.
  v_dashboard:=public.scouting_api(v_token,'dashboard','{}'::jsonb)->'dashboard';
  v_admin_dashboard:=public.scouting_api(v_token_admin,'dashboard','{}'::jsonb)->'dashboard';
  if v_dashboard-'as_of' is distinct from v_admin_dashboard-'as_of' then
    raise exception 'member and administrator dashboards differ';
  end if;
  if (v_dashboard->>'total_recommendations')::integer<>(v_before->>'total_recommendations')::integer+35
    or (v_dashboard->>'identified_players')::integer<>(v_before->>'identified_players')::integer+2
    or (v_dashboard->>'unverified_player_references')::integer<>(v_before->>'unverified_player_references')::integer+30
    or (v_dashboard->>'manual_recommendations')::integer<>(v_before->>'manual_recommendations')::integer+31
    or (v_dashboard->>'total_player_references')::integer<>(v_before->>'total_player_references')::integer+32
    or (v_dashboard->>'contacted')::integer<>(v_before->>'contacted')::integer+4
    or (v_dashboard->>'visited')::integer<>(v_before->>'visited')::integer+2
    or (v_dashboard->>'invited_to_trial')::integer<>(v_before->>'invited_to_trial')::integer+1
    or (v_dashboard->>'trial_completed')::integer<>(v_before->>'trial_completed')::integer+2
    or (v_dashboard->>'not_advanced')::integer<>(v_before->>'not_advanced')::integer+2
    or (v_dashboard#>>'{milestone_recommendations,contacted}')::integer<>(v_before#>>'{milestone_recommendations,contacted}')::integer+6 then
    raise exception 'global deduplication, exact milestone or accumulated status counts failed: %',v_dashboard;
  end if;
  v_assertions:=v_assertions+1;

  -- 9. Ranking counts recommendations and distinct authors, not events or names.
  select x into v_rank from jsonb_array_elements(v_dashboard->'most_recommended_players') x where x->>'player_id'=v_player::text;
  if v_rank is null or v_rank->>'recommendation_count'<>'2' or v_rank->>'unique_recommenders_count'<>'2'
    or v_rank#>>'{latest_recommendation,id}'<>v_ids[2]::text
    or v_rank#>>'{latest_recommendation,status}'<>'no_avanza' then
    raise exception 'verified-player ranking or latest-recommendation attribution failed';
  end if;
  select x into v_rank from jsonb_array_elements(v_dashboard->'most_recommended_players') x where x->>'player_id'=v_homonym::text;
  if v_rank is null or v_rank->>'recommendation_count'<>'2' or v_rank->>'unique_recommenders_count'<>'1'
    or v_rank#>>'{latest_recommendation,id}'<>v_rec_legacy::text
    or v_rank#>'{player,age_at_recommendation}' is distinct from 'null'::jsonb
    or v_rank#>'{player,market_value}' is distinct from 'null'::jsonb then
    raise exception 'catalogue homonyms merged or legacy ranking fields lost their null defaults';
  end if;
  if exists(select 1 from jsonb_array_elements(v_dashboard->'most_recommended_players') x
    where (x->>'recommendation_count')::integer<2)
    or jsonb_array_length(v_dashboard->'most_recommended_players')>10 then
    raise exception 'ranking merged homonyms or contains singletons';
  end if;
  select x into v_rank from jsonb_array_elements(v_dashboard->'most_recommended_players') x
    where x#>>'{player,reference_id}'=v_ids[4]::text;
  if v_rank is null or v_rank->>'identity_type'<>'member_reference'
    or v_rank->>'identity_verification'<>'member_declared' or v_rank->>'player_id' is not null
    or v_rank->>'recommendation_count'<>'2' or v_rank->>'unique_recommenders_count'<>'2'
    or v_rank#>>'{latest_recommendation,id}'<>v_linked_manual::text then
    raise exception 'manual reference ranking merged homonyms or claimed catalogue verification';
  end if;
  v_result:=public.scouting_api(v_token_other,'feed',jsonb_build_object('reference_recommendation_id',v_ids[4]));
  if jsonb_array_length(v_result->'items')<>2 then raise exception 'manual reference feed filter failed';end if;
  v_result:=public.scouting_api(v_token_other,'feed',jsonb_build_object('reference_recommendation_id',v_linked_manual));
  if jsonb_array_length(v_result->'items')<>2 then raise exception 'linked manual reference did not resolve the same group';end if;
  v_result:=public.scouting_api(v_token_other,'feed',jsonb_build_object('reference_recommendation_id',v_ids[1]));
  if jsonb_array_length(v_result->'items')<>2 then raise exception 'catalogue reference feed filter failed';end if;
  v_result:=public.scouting_api(v_token_other,'feed',jsonb_build_object('player_id',v_player,'query',v_marker));
  if jsonb_array_length(v_result->'items')<>2 then raise exception 'exact ranking player filter failed';end if;
  v_result:=public.scouting_api(v_token_other,'feed',jsonb_build_object('player_id',v_player,'mine_only',true));
  if jsonb_array_length(v_result->'items')<>1 then raise exception 'exact player filter broke mine_only';end if;
  v_assertions:=v_assertions+1;

  -- 10. One shared paginated feed, visible owner membership number and dated fields.
  v_result:=public.scouting_api(v_token_other,'feed',jsonb_build_object('query',v_marker));
  if jsonb_array_length(v_result->'items')<>25 or v_result->>'next_cursor' is null then
    raise exception 'shared feed did not paginate 35 fixtures';
  end if;
  v_result:=public.scouting_api(v_token_other,'feed',jsonb_build_object('query',v_marker,'cursor',v_result->>'next_cursor'));
  if jsonb_array_length(v_result->'items')<>10 or v_result->>'next_cursor' is not null then
    raise exception 'shared feed second page count failed';
  end if;
  v_detail:=public.scouting_api(v_token_other,'detail',jsonb_build_object('id',v_ids[1]));
  if v_detail#>>'{recommendation,author,numero_socio}'<>v_owner::text
    or v_detail#>>'{recommendation,author,name}'<>'SCOUTING DASHBOARD SYNTHETIC OWNER'
    or v_detail#>>'{recommendation,created_at}' is null
    or v_detail#>>'{recommendation,club,province}'<>'Córdoba'
    or v_detail#>>'{recommendation,club,competition_name}'<>'QA dashboard competition' then
    raise exception 'shared row fields or author identity missing';
  end if;
  v_assertions:=v_assertions+1;

  -- 11. Every change identifies its actual administrator, previous/new status and
  -- public reason; private nonces and unrelated personal fields never appear.
  if not exists(select 1 from jsonb_array_elements(v_detail->'events') x where x->>'id'=v_contact_event::text
    and x#>>'{actor,numero_socio}'=v_admin::text and x#>>'{actor,name}'='SCOUTING DASHBOARD SYNTHETIC ADMIN'
    and x#>>'{actor,role}'='admin' and x->>'previous_status'='recibida' and x->>'new_status'='contactado'
    and x->>'message' like 'QA_ADMIN_PUBLIC_REASON:%' and x->>'hash_version'='2') then
    raise exception 'status-change actor or before/after not visible to another member';
  end if;
  if v_detail::text like '%private_nonce%' or v_detail::text like '%token_hash%'
    or v_detail::text like '%"dni"%' or v_detail::text like '%"email"%' or v_detail::text like '%"birth_date"%' then
    raise exception 'detail exposed unrelated private information';
  end if;
  v_assertions:=v_assertions+1;

  -- 12. Catalogue changes cannot rewrite historic recommendation evidence.
  update scouting.players set birth_date=(v_today-interval '21 years')::date,
    market_value_amount=250000,market_value_as_of=v_today,market_value_verified_at=clock_timestamp()
    where id=v_player;
  v_result:=public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_club,'query',v_marker));
  if not exists(select 1 from jsonb_array_elements(v_result->'items') x where x->>'id'=v_player::text
    and x->>'age_current'='21' and (x#>>'{market_value,amount}')::numeric=250000) then
    raise exception 'current catalogue enrichment was not exposed by lookup';
  end if;
  v_detail:=public.scouting_api(v_token_other,'detail',jsonb_build_object('id',v_ids[1]));
  if v_detail#>>'{recommendation,player,age_at_recommendation}'<>'20'
    or (v_detail#>>'{recommendation,player,market_value,amount}')::numeric<>100000
    or (select snapshot from scouting.recommendations where id=v_ids[1]) is distinct from v_initial_snapshot then
    raise exception 'historic age/value snapshot drifted with the catalogue';
  end if;
  v_assertions:=v_assertions+1;

  -- 13. Recompute both immutable event hash formats; v2 explicitly commits before/
  -- after plus actor. Check chain continuity and coupling to the shared audit.
  for v_event in select e.*,r.commitment_hash as original_commitment,
      lag(e.event_hash) over(partition by e.recommendation_id order by e.sequence_no) as expected_previous,
      lag(e.status) over(partition by e.recommendation_id order by e.sequence_no) as expected_previous_status
    from scouting.events e join scouting.recommendations r on r.id=e.recommendation_id
    where e.recommendation_id=any(v_ids) order by e.recommendation_id,e.sequence_no loop
    v_hash_document:=jsonb_build_object('schema','scouting-event-v'||v_event.hash_version,
      'id',v_event.id,'recommendation_id',v_event.recommendation_id,'sequence',v_event.sequence_no,
      'actor',v_event.actor_numero_socio,'role',v_event.actor_role,'type',v_event.event_type,'status',v_event.status,
      'message',v_event.member_message,'created_at',to_char(v_event.created_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
      'original_commitment',v_event.original_commitment,'previous',v_event.prev_hash,'nonce',v_event.private_nonce);
    if v_event.hash_version=2 then
      v_hash_document:=v_hash_document||jsonb_build_object('previous_status',v_event.previous_status);
      if (v_event.event_type='created' and v_event.previous_status is not null)
        or (v_event.event_type<>'created' and v_event.previous_status is distinct from v_event.expected_previous_status) then
        raise exception 'version2 previous status does not match the actual prior event';
      end if;
    end if;
    v_hash:=encode(extensions.digest(convert_to(v_hash_document::text,'UTF8'),'sha256'),'hex');
    if v_hash<>v_event.event_hash or v_event.prev_hash is distinct from v_event.expected_previous then
      raise exception 'version% event hash or previous-hash link cannot be recomputed',v_event.hash_version;
    end if;
  end loop;
  if (select count(*) from scouting.events where recommendation_id=any(v_ids))
    <> (select count(*) from scouting.events e join public.auditoria_administrativa a on a.id=e.audit_event_id where e.recommendation_id=any(v_ids)) then
    raise exception 'an event lacks its coupled shared-audit commitment';
  end if;
  if exists(select 1 from scouting.events e join public.auditoria_administrativa a on a.id=e.audit_event_id
    where e.recommendation_id=any(v_ids) and (a.actor_numero_socio is not null or a.actor_nombre is not null or a.actor_rol is not null
      or to_jsonb(a)::text like '%QA_PRIVATE_%' or to_jsonb(a)::text like '%SCOUTING DASHBOARD SYNTHETIC%'
      or to_jsonb(a)::text like '%QA_ADMIN_PUBLIC_REASON%')) then
    raise exception 'shared blockchain audit exposed event content or member identity';
  end if;
  v_assertions:=v_assertions+1;

  -- 14. The selected status-change proof is its own commitment, never the initial
  -- recommendation proof. Preparing a local Merkle lot does not imply anchoring.
  select public.preparar_lote_merkle_auditoria('SCOUTING-DASHBOARD-QA-'||v_suffix,'extraordinario',
    min(e.audit_event_id),max(e.audit_event_id),null,'scouting_dashboard_test','{}'::jsonb)
    into v_lot from scouting.events e where e.recommendation_id=any(v_ids);
  v_result:=public.scouting_api(v_token_other,'event_proof',jsonb_build_object('event_id',v_contact_event));
  v_proof:=v_result->'proof';
  if v_result->>'event_id'<>v_contact_event::text
    or v_proof->>'status'<>'preparada' or (v_proof->>'merkle_valid')::boolean is distinct from true
    or v_proof->>'audit_event_id'<>v_contact_audit::text
    or v_proof->>'lot_id'<>v_lot::text
    or v_proof->>'commitment_hash'<>(select event_hash from scouting.events where id=v_contact_event)
    or v_proof->>'commitment_hash'=scouting.proof_json(v_ids[1])->>'commitment_hash'
    or v_proof->>'transaction_hash' is not null then
    raise exception 'per-actuation proof selected the wrong event or claimed an unconfirmed anchor';
  end if;
  begin
    perform public.scouting_api(v_token,'event_proof',jsonb_build_object('event_id',gen_random_uuid()));
    raise exception 'unknown event proof was accepted';
  exception when sqlstate 'PT404' then null;end;
  begin
    perform public.scouting_api(repeat('x',64),'event_proof',jsonb_build_object('event_id',v_contact_event));
    raise exception 'event proof accepted an unauthenticated request';
  exception when sqlstate 'PT401' then null;end;
  v_assertions:=v_assertions+1;

  -- 15. Private helpers remain inaccessible to clients; original snapshots and
  -- chronology remain immutable, and no existing authorization grant is broadened.
  if has_function_privilege('anon','scouting.dashboard_json()','EXECUTE')
    or has_function_privilege('authenticated','scouting.dashboard_json()','EXECUTE')
    or has_function_privilege('service_role','scouting.dashboard_json()','EXECUTE')
    or has_function_privilege('anon','scouting.event_proof_json(uuid)','EXECUTE')
    or has_function_privilege('authenticated','scouting.event_proof_json(uuid)','EXECUTE')
    or has_function_privilege('service_role','scouting.event_proof_json(uuid)','EXECUTE')
    or has_function_privilege('anon','scouting.player_identity_key(jsonb,uuid)','EXECUTE')
    or has_function_privilege('authenticated','scouting.player_identity_key(jsonb,uuid)','EXECUTE')
    or has_function_privilege('service_role','scouting.player_identity_key(jsonb,uuid)','EXECUTE')
    or has_function_privilege('anon','public.scouting_api(text,text,jsonb)','EXECUTE')
    or has_function_privilege('authenticated','public.scouting_api(text,text,jsonb)','EXECUTE')
    or not has_function_privilege('service_role','public.scouting_api(text,text,jsonb)','EXECUTE') then
    raise exception 'dashboard or event-proof privileges are broader than the existing contract';
  end if;
  begin
    update scouting.events set previous_status='cerrada' where id=v_contact_event;
    raise exception 'event chronology became mutable';
  exception when insufficient_privilege then null;end;
  if (select hash_version from scouting.events where id=v_legacy_event)<>1
    or (select snapshot from scouting.recommendations where id=v_rec_legacy) is distinct from v_snapshot then
    raise exception 'legacy evidence was rewritten';
  end if;
  v_assertions:=v_assertions+1;
  raise notice 'Scouting dashboard regression passed: % grouped checks, 35 synthetic recommendations; all rolled back',v_assertions;
end;
$dashboard_test$;

rollback;
