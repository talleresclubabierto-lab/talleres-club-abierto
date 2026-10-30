-- Synthetic integration regression for players.position. Execute only after
-- installing the proposed patch in the same rollback rehearsal or deployment.
-- Never read/reuse a real member session. ALWAYS retain the final ROLLBACK.
begin;
set local statement_timeout='60s';
set local lock_timeout='5s';

do $position_filter_test$
declare
  v_suffix text:=left(replace(gen_random_uuid()::text,'-',''),12);
  v_member bigint:=886000000000000+(floor(random()*1000000000))::bigint;
  v_token text:=encode(extensions.gen_random_bytes(32),'hex');
  v_expired_token text:=encode(extensions.gen_random_bytes(32),'hex');
  v_expired_session bigint;
  v_comp text;
  v_club uuid:=gen_random_uuid();
  v_other_club uuid:=gen_random_uuid();
  v_player uuid;
  v_club_for_player uuid;
  v_position text;
  v_n integer;
  v_page integer;
  v_expected integer;
  v_cursor text;
  v_response jsonb;
  v_all_response jsonb;
  v_first jsonb;
  v_next jsonb;
  v_extra jsonb;
  v_bad jsonb;
  v_payload jsonb;
  v_all_ids uuid[]:=array[]::uuid[];
  v_lateral_ids uuid[]:=array[]::uuid[];
  v_unknown_ids uuid[]:=array[]::uuid[];
  v_foreign_ids uuid[]:=array[]::uuid[];
  v_received uuid[];
  v_pages uuid[]:=array[]::uuid[];
  v_events_before bigint;
  v_recommendations_before bigint;
begin
  if md5(pg_get_functiondef('public.scouting_api(text,text,jsonb)'::regprocedure))<>'f194c6d6710ed861f55c76b7f6a63bbf' then
    raise exception 'Install the reviewed position-filter RPC before this regression';
  end if;
  v_comp:='qa-position-'||v_suffix;
  insert into public.socios(numero_socio,nombre,fecha_alta,habilitado)
    values(v_member,'SCOUTING POSITION FILTER SYNTHETIC MEMBER',current_date,true);
  perform public.crear_sesion_segura_interno(v_member,v_token,5,'scouting_position_filter_test','{}'::jsonb);
  v_expired_session:=public.crear_sesion_segura_interno(v_member,v_expired_token,5,'scouting_position_filter_expired_test','{}'::jsonb);
  -- Backdate only this synthetic session, preserving vence_en > creada_en.
  update public.sesiones_seguras set creada_en=now()-interval '2 minutes',vence_en=now()-interval '1 minute'
    where id=v_expired_session and numero_socio=v_member;

  insert into scouting.competitions(id,name,season)
    values(v_comp,'Synthetic position-filter competition','2026');
  insert into scouting.clubs(id,source_key,name,province,city,source,checked_at) values
    (v_club,'qa-position-'||v_suffix,'Synthetic position-filter club','Córdoba','Localidad sintética','verified_manual',clock_timestamp()),
    (v_other_club,'qa-position-other-'||v_suffix,'Synthetic foreign position-filter club','Córdoba','Localidad sintética','verified_manual',clock_timestamp());
  insert into scouting.club_competitions(club_id,competition_id,season,checked_at) values
    (v_club,v_comp,'2026',clock_timestamp()),(v_other_club,v_comp,'2026',clock_timestamp());

  -- The first unfiltered page mixes all three groups. The 31 Lateral players
  -- necessarily reach beyond that page. Total synthetic players: exactly 60.
  for v_n in 1..60 loop
    v_player:=gen_random_uuid();
    v_club_for_player:=case when v_n between 55 and 57 then v_other_club else v_club end;
    v_position:=case when v_n>54 or v_n%2=0 or v_n in (1,3,5,7) then 'Lateral' when v_n%4=1 then 'Arquero' else null end;
    insert into scouting.players(id,source_key,club_id,first_name,last_name,category,position,source,checked_at,active)
      values(v_player,'qa-position-'||v_suffix||':player:'||v_n::text,v_club_for_player,'Jugador','Mixto '||lpad(v_n::text,3,'0'),
        'Primera',v_position,'verified_manual',clock_timestamp(),v_n<=57);
    insert into scouting.player_squads(player_id,club_id,category,season,source,checked_at)
      values(v_player,v_club_for_player,'Primera','2026','verified_manual',clock_timestamp());
    if v_n<=54 then
      v_all_ids:=array_append(v_all_ids,v_player);
      if v_position='Lateral' then v_lateral_ids:=array_append(v_lateral_ids,v_player);end if;
      if v_position is null then v_unknown_ids:=array_append(v_unknown_ids,v_player);end if;
    elsif v_n<=57 then
      v_foreign_ids:=array_append(v_foreign_ids,v_player);
    end if;
  end loop;
  -- Two of the same people also belong to Reserva; no duplicate player UUIDs.
  insert into scouting.player_squads(player_id,club_id,category,season,source,checked_at)
    select p,v_club,'Reserva','2026','verified_manual',clock_timestamp()
    from unnest(v_lateral_ids[1:2])p;
  insert into scouting.squad_reviews(club_id,category,season,source_season,source,source_url,checked_at,completeness,expected_count,imported_count)
    values(v_club,'Primera','2026','2026','verified_manual','https://www.transfermarkt.com/synthetic/kader/verein/99999971',clock_timestamp(),'complete',54,54),
      (v_club,'Reserva','2026','2026','verified_manual','https://www.transfermarkt.com/synthetic-reserve/kader/verein/99999972',clock_timestamp(),'complete',2,2);
  select count(*) into v_events_before from scouting.events;
  select count(*) into v_recommendations_before from scouting.recommendations;
  v_payload:=jsonb_build_object('club_id',v_club,'category','Primera');
  v_all_response:=public.scouting_api(v_token,'players',v_payload);

  -- Omitted, JSON null, empty and whitespace filters all preserve old behavior.
  for v_extra in select x from jsonb_array_elements('[{}, {"position":null}, {"position":""}, {"position":"   "}]'::jsonb)x loop
    v_response:=public.scouting_api(v_token,'players',v_payload||v_extra);
    if (v_response->>'total_count')::integer<>54 or jsonb_array_length(v_response->'items')<>25
      or v_response->>'next_cursor'<>'25' or v_response->'items'<>v_all_response->'items'
      or v_response->'squad'<>v_all_response->'squad' then
      raise exception 'All-position filter changed legacy behavior: %',v_extra;
    end if;
  end loop;

  -- Full unfiltered pagination contains exactly the 54 active primary players.
  v_cursor:=null;
  for v_page in 1..3 loop
    v_response:=public.scouting_api(v_token,'players',v_payload||jsonb_build_object('cursor',v_cursor));
    select coalesce(array_agg((p->>'id')::uuid order by ord),array[]::uuid[]) into v_received
      from jsonb_array_elements(v_response->'items') with ordinality x(p,ord);
    v_pages:=v_pages||v_received;
    if (v_response->>'total_count')::integer<>54 then raise exception 'All-position total changed between pages';end if;
    v_cursor:=v_response->>'next_cursor';
  end loop;
  if v_pages<>v_all_ids or v_cursor is not null then raise exception 'Unfiltered pagination lost/duplicated/included ineligible players';end if;

  v_first:=public.scouting_api(v_token,'players',v_payload||jsonb_build_object('position','Lateral'));
  v_next:=public.scouting_api(v_token,'players',v_payload||jsonb_build_object('position','Lateral','cursor',v_first->>'next_cursor'));
  select array_agg((p->>'id')::uuid order by ord) into v_received from jsonb_array_elements(v_first->'items') with ordinality x(p,ord);
  if v_received<>v_lateral_ids[1:25] or (v_first->>'total_count')::integer<>31 or v_first->>'next_cursor'<>'25' then
    raise exception 'Position filter was not applied before first-page pagination';end if;
  select array_agg((p->>'id')::uuid order by ord) into v_received from jsonb_array_elements(v_next->'items') with ordinality x(p,ord);
  if v_received<>v_lateral_ids[26:31] or (v_next->>'total_count')::integer<>31 or v_next->>'next_cursor' is not null then
    raise exception 'Position filter lost players beyond the first page';end if;
  if v_first->'squad'<>v_all_response->'squad' or v_next->'squad'<>v_all_response->'squad'
    or (v_first#>>'{squad,player_count}')::integer<>54 or v_first#>>'{squad,status}'<>'verified' then
    raise exception 'Position filter changed complete squad coverage metadata';end if;

  v_first:=public.scouting_api(v_token,'players',v_payload||jsonb_build_object('position','__unknown__'));
  select array_agg((p->>'id')::uuid order by ord) into v_received from jsonb_array_elements(v_first->'items') with ordinality x(p,ord);
  if v_received<>v_unknown_ids or (v_first->>'total_count')::integer<>11 or v_first->>'next_cursor' is not null
    or exists(select 1 from jsonb_array_elements(v_first->'items')p where p->>'position' is not null) then
    raise exception 'Unknown filter did not select only NULL positions';end if;
  if v_first->'squad'<>v_all_response->'squad' then raise exception 'Unknown-position filter changed squad coverage';end if;

  -- Name query remains supported and intersects the complete position group.
  v_response:=public.scouting_api(v_token,'players',v_payload||jsonb_build_object('position','Lateral','query','Mixto 01'));
  if (v_response->>'total_count')::integer<>5 or jsonb_array_length(v_response->'items')<>5 then
    raise exception 'Name query and position were not combined with AND';end if;
  v_response:=public.scouting_api(v_token,'players',v_payload||jsonb_build_object('position','Lateral','query','Mixto 054'));
  if (v_response->>'total_count')::integer<>1 or v_response#>>'{items,0,id}'<>v_lateral_ids[31]::text then
    raise exception 'Name+position query was restricted to the first unfiltered page';end if;
  v_response:=public.scouting_api(v_token,'players',v_payload||jsonb_build_object('position','Arquero','query','Mixto 054'));
  if (v_response->>'total_count')::integer<>0 or jsonb_array_length(v_response->'items')<>0 or v_response->'squad'<>v_all_response->'squad' then
    raise exception 'Name+position no-match changed squad counts';end if;

  -- Same UUIDs, different category: only the two Reserva memberships qualify.
  v_response:=public.scouting_api(v_token,'players',v_payload||jsonb_build_object('category','Reserva','position','Lateral'));
  select array_agg((p->>'id')::uuid order by ord) into v_received from jsonb_array_elements(v_response->'items') with ordinality x(p,ord);
  if v_received<>v_lateral_ids[1:2] or (v_response->>'total_count')::integer<>2 or (v_response#>>'{squad,player_count}')::integer<>2 then
    raise exception 'Position filter crossed category membership boundaries';end if;
  v_response:=public.scouting_api(v_token,'players',v_payload||jsonb_build_object('club_id',v_other_club,'position','Lateral'));
  select array_agg((p->>'id')::uuid order by ord) into v_received from jsonb_array_elements(v_response->'items') with ordinality x(p,ord);
  if v_received<>v_foreign_ids or (v_response->>'total_count')::integer<>3 then
    raise exception 'Position filter crossed club boundaries';end if;

  -- Every current bootstrap position is accepted, including empty groups.
  v_response:=public.scouting_api(v_token,'bootstrap','{}'::jsonb);
  for v_position in select jsonb_array_elements_text(v_response->'positions') loop
    v_response:=public.scouting_api(v_token,'players',v_payload||jsonb_build_object('position',v_position));
    v_expected:=case v_position when 'Lateral' then 31 when 'Arquero' then 12 else 0 end;
    if (v_response->>'total_count')::integer<>v_expected then raise exception 'Bootstrap position filter disagrees: %',v_position;end if;
  end loop;
  for v_bad in select x from jsonb_array_elements('["Delantero", "__UNKNOWN__", "Todos", "%", 1, true, ["Lateral"], {}]'::jsonb)x loop
    begin
      perform public.scouting_api(v_token,'players',v_payload||jsonb_build_object('position',v_bad));
      raise exception 'Invalid position accepted: %',v_bad;
    exception when sqlstate 'PT422' then null;end;
  end loop;
  begin
    perform public.scouting_api(v_expired_token,'players',v_payload||jsonb_build_object('position','Lateral'));
    raise exception 'Expired session accessed filtered players';
  exception when sqlstate 'PT401' then null;end;
  begin
    perform public.scouting_api(repeat('x',64),'players',v_payload||jsonb_build_object('position','__unknown__'));
    raise exception 'Invalid session accessed filtered players';
  exception when sqlstate 'PT401' then null;end;
  if (select count(*) from scouting.events)<>v_events_before
    or (select count(*) from scouting.recommendations)<>v_recommendations_before then
    raise exception 'Reading filtered players changed scouting recommendations or events';end if;
  raise notice 'Position-filter regression passed: complete-roster filtering, pagination, NULL, legacy all/query, coverage, club/category and session boundaries';
end;
$position_filter_test$;

rollback;
