-- Synthetic-only contract and importer regression. ALWAYS run with final ROLLBACK.
-- No real member, administrator, session or recommendation is used as an identity.
begin;
set local statement_timeout='120s';
set local lock_timeout='5s';
do $countries_test$
declare
  v_suffix text:=left(replace(gen_random_uuid()::text,'-',''),12);
  v_key text;
  v_owner bigint:=886000000000000+(floor(random()*1000000000))::bigint;
  v_other bigint:=v_owner+1;
  v_admin bigint:=v_owner+2;
  v_token text:=encode(extensions.gen_random_bytes(32),'hex');
  v_other_token text:=encode(extensions.gen_random_bytes(32),'hex');
  v_admin_token text:=encode(extensions.gen_random_bytes(32),'hex');
  v_expired_token text:=encode(extensions.gen_random_bytes(32),'hex');
  v_expired_session bigint;
  v_tm_base bigint:=91000000000+(floor(random()*1000000))::bigint*100;
  v_country text;
  v_country_no integer:=0;
  v_comp text;
  v_extra_comp text;
  v_region text;
  v_club_rows jsonb;
  v_first_clubs jsonb:='{}'::jsonb;
  v_first_keys jsonb:='{}'::jsonb;
  v_club_id uuid;
  v_br_club uuid;
  v_cl_club uuid;
  v_mononym uuid;
  v_shared uuid;
  v_doc jsonb;
  v_base_club_doc jsonb;
  v_roster_doc jsonb;
  v_bad jsonb;
  v_metadata jsonb;
  v_rows jsonb;
  v_result jsonb;
  v_response jsonb;
  v_response2 jsonb;
  v_bootstrap_ar jsonb;
  v_payload jsonb;
  v_rec uuid;
  v_mononym_rec uuid;
  v_manual_br uuid;
  v_saved_rec jsonb;
  v_initial_history_hash text;
  v_final_history_hash text;
  v_initial_arg_players_hash text;
  v_final_arg_players_hash text;
  v_initial_events integer;
  v_initial_players integer;
  v_initial_recommendations integer;
  v_snapshot_meta jsonb;
  v_invalid jsonb;
  v_expected_regions integer;
  v_checked timestamptz:=clock_timestamp();
begin
  v_key:='qa-sa-'||v_suffix;
  v_extra_comp:='qa-br-state-'||v_suffix;
  select count(*) into v_initial_events from scouting.events;
  select count(*) into v_initial_recommendations from scouting.recommendations;
  select count(*) into v_initial_players from scouting.players;
  select encode(extensions.digest(convert_to(jsonb_build_object(
    'recommendations',(select coalesce(jsonb_agg(to_jsonb(r) order by r.id),'[]'::jsonb) from scouting.recommendations r),
    'events',(select coalesce(jsonb_agg(to_jsonb(e) order by e.id),'[]'::jsonb) from scouting.events e))::text,'UTF8'),'sha256'),'hex') into v_initial_history_hash;
  select encode(extensions.digest(convert_to(coalesce(jsonb_agg(to_jsonb(p) order by p.id),'[]'::jsonb)::text,'UTF8'),'sha256'),'hex')
    into v_initial_arg_players_hash from scouting.players p join scouting.clubs c on c.id=p.club_id where c.country_code='AR';
  insert into public.socios(numero_socio,nombre,fecha_alta,habilitado) values
    (v_owner,'SCOUTING COUNTRIES SYNTHETIC OWNER',current_date,true),
    (v_other,'SCOUTING COUNTRIES SYNTHETIC OTHER',current_date,true),
    (v_admin,'SCOUTING COUNTRIES SYNTHETIC ADMIN',current_date,true);
  insert into public.administradores(numero_socio,habilitado,es_principal) values(v_admin,true,false);
  perform public.crear_sesion_segura_interno(v_owner,v_token,5,'scouting_country_test','{}'::jsonb);
  perform public.crear_sesion_segura_interno(v_other,v_other_token,5,'scouting_country_test','{}'::jsonb);
  perform public.crear_sesion_segura_interno(v_admin,v_admin_token,5,'scouting_country_test','{}'::jsonb);
  v_expired_session:=public.crear_sesion_segura_interno(v_owner,v_expired_token,5,'scouting_country_test','{}'::jsonb);
  update public.sesiones_seguras set creada_en=now()-interval '2 minutes',vence_en=now()-interval '1 minute'
    where id=v_expired_session and numero_socio=v_owner;

  v_bootstrap_ar:=public.scouting_api(v_token,'bootstrap','{}'::jsonb);
  if v_bootstrap_ar->>'country_code'<>'AR' or jsonb_array_length(v_bootstrap_ar->'provinces')<>24
    or jsonb_array_length(v_bootstrap_ar->'countries')<>6 or jsonb_array_length(v_bootstrap_ar->'positions')<>9 then
    raise exception 'Legacy Argentina bootstrap or country/position list changed';
  end if;
  foreach v_country in array array['AR','BR','CL','CO','EC','UY'] loop
    v_response:=public.scouting_api(v_token,'bootstrap',jsonb_build_object('country_code',v_country));
    v_expected_regions:=case v_country when 'AR' then 24 when 'BR' then 27 when 'CL' then 16 when 'CO' then 33 when 'EC' then 24 else 19 end;
    if v_response->>'country_code'<>v_country or jsonb_array_length(v_response->'regions')<>v_expected_regions
      or v_response->'positions'<>v_bootstrap_ar->'positions'
      or exists(select 1 from jsonb_array_elements(v_response->'regions')r where r->>'country_code'<>v_country)
      or exists(select 1 from jsonb_array_elements(v_response->'competitions')c where c->>'country_code'<>v_country)
      or (v_response#>>'{catalogue,club_count}')::integer<>(select count(*) from scouting.clubs where active and country_code=v_country)
      or (v_response#>>'{catalogue,player_count}')::integer<>(select count(*) from scouting.players p join scouting.clubs c on c.id=p.club_id where p.active and c.active and c.country_code=v_country) then
      raise exception 'Bootstrap country isolation/counts failed for %',v_country;
    end if;
  end loop;
  for v_invalid in select x from jsonb_array_elements('["ZZ",1,true,[],{}]'::jsonb)x loop
    begin
      perform public.scouting_api(v_token,'bootstrap',jsonb_build_object('country_code',v_invalid));
      raise exception 'Invalid country accepted';
    exception when sqlstate 'PT422' then null;end;
  end loop;
  for v_invalid in select x from jsonb_array_elements('[null,"","  ","ar"]'::jsonb)x loop
    v_result:=public.scouting_api(v_token,'bootstrap',jsonb_build_object('country_code',v_invalid));
    if v_result->>'country_code'<>'AR' or v_result->'provinces'<>v_bootstrap_ar->'provinces' then raise exception 'Legacy country default failed';end if;
  end loop;
  begin
    perform public.scouting_api(v_expired_token,'bootstrap','{}'::jsonb);
    raise exception 'Expired session accepted';
  exception when sqlstate 'PT401' then null;end;
  begin
    perform public.scouting_api(repeat('x',64),'clubs','{}'::jsonb);
    raise exception 'Invalid session accepted';
  exception when sqlstate 'PT401' then null;end;

  -- 28 Brazilian clubs exercise real pagination; one in every other country
  -- proves that unknown region/city does not leak across catalogue searches.
  foreach v_country in array array['BR','CL','CO','EC','UY','AR'] loop
    v_country_no:=v_country_no+1;
    v_comp:=case v_country when 'BR' then 'brasil-serie-a' when 'CL' then 'chile-primera-division'
      when 'CO' then 'colombia-liga-betplay' when 'EC' then 'ecuador-serie-a' when 'UY' then 'uruguay-primera-division' else 'primera-division' end;
    select jsonb_agg(jsonb_build_object('transfermarkt_id',(v_tm_base+v_country_no*100+n)::text,
      'source_key','tm-club-'||(v_tm_base+v_country_no*100+n)::text,
      'name',v_key||' '||v_country||' '||lpad(n::text,2,'0'),'province',null,'city',null,
      'source','verified_manual','checked_at',v_checked,'source_urls',jsonb_build_array('https://www.transfermarkt.com/synthetic-club/startseite/verein/'||(v_tm_base+v_country_no*100+n)::text),
      'competitions',jsonb_build_array(jsonb_build_object('competition_id',v_comp,'season','2026','division','Primera',
        'reference_scope','primer_equipo_masculino','source_url','https://www.transfermarkt.com/synthetic-competition/startseite/wettbewerb/QA','checked_at',v_checked))
        ||case when v_country='BR' and n=1 then jsonb_build_array(jsonb_build_object('competition_id',v_extra_comp,'season','2026','division','Estadual',
          'reference_scope','primer_equipo_masculino','source_url','https://www.transfermarkt.com/synthetic-state/startseite/wettbewerb/QABR','checked_at',v_checked)) else '[]'::jsonb end) order by n)
      into v_club_rows from generate_series(1,case when v_country='BR' then 28 else 1 end)n;
    v_metadata:=scouting.catalogue_country_fingerprints(v_country)||jsonb_build_object('schema_version',1,'kind','reviewed_clubs',
      'country',scouting.country_name(v_country),'batch_key',v_key||'-clubs-'||lower(v_country));
    v_doc:=jsonb_build_object('metadata',v_metadata,'clubs',v_club_rows,'competitions',case when v_country='BR' then jsonb_build_array(jsonb_build_object(
      'id',v_extra_comp,'name','Brasil · synthetic estadual '||v_suffix,'season','2026','sort_order',199,
      'source_url','https://www.transfermarkt.com/synthetic-state/startseite/wettbewerb/QABR')) else '[]'::jsonb end);
    v_result:=scouting.import_club_batch(v_doc,repeat('a',64));
    if (v_result->>'clubs_inserted')::integer<>(case when v_country='BR' then 28 else 1 end)
      or v_result->>'country_code'<>v_country then raise exception 'Club import country/count incorrect';end if;
    if not (scouting.import_club_batch(v_doc,repeat('a',64))->>'replayed')::boolean then raise exception 'Club replay failed';end if;
    select id into v_club_id from scouting.clubs where source_key=v_club_rows#>>'{0,source_key}';
    v_first_clubs:=v_first_clubs||jsonb_build_object(v_country,v_club_id);
    v_first_keys:=v_first_keys||jsonb_build_object(v_country,v_club_rows#>>'{0,source_key}');
    if v_country='BR' then v_base_club_doc:=v_doc;end if;
  end loop;
  v_br_club:=(v_first_clubs->>'BR')::uuid;
  v_cl_club:=(v_first_clubs->>'CL')::uuid;
  v_response:=public.scouting_api(v_token,'clubs',jsonb_build_object('country_code','BR','query',v_key));
  v_response2:=public.scouting_api(v_token,'clubs',jsonb_build_object('country_code','BR','query',v_key,'cursor','25'));
  if jsonb_array_length(v_response->'items')<>25 or v_response->>'next_cursor'<>'25'
    or (v_response->>'total_count')::integer<>28 or jsonb_array_length(v_response2->'items')<>3
    or v_response2->>'next_cursor' is not null or (v_response2->>'total_count')::integer<>28
    or exists(select 1 from jsonb_array_elements(v_response->'items')a join jsonb_array_elements(v_response2->'items')b on a->>'id'=b->>'id')
    or exists(select 1 from jsonb_array_elements((v_response->'items')||(v_response2->'items'))c where c->>'country_code'<>'BR' or c->>'city' is not null or c->>'province' is not null) then
    raise exception 'Club pagination or unknown geography failed';
  end if;
  v_response:=public.scouting_api(v_token,'clubs',jsonb_build_object('country_code','BR','query',v_key,'competition_id',v_extra_comp));
  if (v_response->>'total_count')::integer<>1 or v_response#>>'{items,0,id}'<>v_br_club::text
    or jsonb_array_length(v_response#>'{items,0,competitions}')<>2 then raise exception 'Multi-competition club duplicated or lost filters';end if;
  v_response:=public.scouting_api(v_token,'clubs',jsonb_build_object('query',v_key));
  if (v_response->>'total_count')::integer<>1 or v_response#>>'{items,0,country_code}'<>'AR' then raise exception 'Legacy clubs request leaked foreign country';end if;
  begin
    perform public.scouting_api(v_token,'clubs',jsonb_build_object('country_code','BR','province','Córdoba'));
    raise exception 'Cross-country region accepted';
  exception when sqlstate 'PT422' then null;end;
  begin
    perform public.scouting_api(v_token,'clubs',jsonb_build_object('country_code','BR','competition_id','primera-division'));
    raise exception 'Cross-country competition accepted';
  exception when sqlstate 'PT422' then null;end;
  begin
    update scouting.clubs set province='Córdoba' where id=v_br_club;
    raise exception 'Club country/region FK missing';
  exception when foreign_key_violation then null;end;
  begin
    insert into scouting.club_competitions(club_id,competition_id,season,checked_at) values(v_br_club,'primera-division','2026',clock_timestamp());
    raise exception 'Cross-country club competition inserted';
  exception when check_violation then null;end;
  v_bad:=jsonb_set(v_base_club_doc,'{metadata,batch_key}',to_jsonb(v_key||'-clubs-stale'));
  begin
    perform scouting.import_club_batch(v_bad,repeat('b',64));
    raise exception 'Stale club fingerprint accepted';
  exception when others then
    if sqlerrm not like 'Country catalogue changed since review:%' then raise;end if;
  end;
  v_bad:=jsonb_set(v_base_club_doc,'{metadata}',scouting.catalogue_country_fingerprints('BR')||jsonb_build_object('schema_version',1,'kind','reviewed_clubs','country','Brasil','batch_key',v_key||'-clubs-cross-id'));
  v_bad:=jsonb_set(v_bad,'{clubs}',jsonb_build_array((v_base_club_doc#>'{clubs,0}')||jsonb_build_object(
    'transfermarkt_id',(select transfermarkt_id from scouting.clubs where id=v_cl_club),
    'source_key',v_first_keys->>'CL','source_urls',jsonb_build_array('https://www.transfermarkt.com/synthetic-club/startseite/verein/'||(select transfermarkt_id from scouting.clubs where id=v_cl_club)))));
  v_bad:=v_bad-'competitions';
  begin
    perform scouting.import_club_batch(v_bad,repeat('c',64));
    raise exception 'Cross-country club identity moved';
  exception when others then
    if sqlerrm not like 'Existing club identity, country, inactive or newer state requires reconciliation%' then raise;end if;
  end;

  -- One person UUID may be in Primera and Reserva. A sporting mononym is an
  -- actual source name with an empty surname, never a fabricated surname.
  select jsonb_agg(jsonb_build_object('transfermarkt_id',(v_tm_base+10000+n)::text,
    'transfermarkt_url','https://www.transfermarkt.com/synthetic-player/profil/spieler/'||(v_tm_base+10000+n)::text,
    'first_name',case when n=1 then 'Monoteste' else 'Jogador' end,
    'last_name',case when n=1 then null else 'Teste '||lpad(n::text,2,'0') end,
    'name_kind',case when n=1 then 'sporting_mononym' else 'display_name_parts' end,
    'position',case when n=1 then 'Arquero' else 'Lateral' end,
    'birth_date',case when n=1 then (current_date-interval '20 years')::date end) order by n)
    into v_rows from generate_series(1,28)n;
  v_metadata:=scouting.catalogue_country_fingerprints('BR')||jsonb_build_object('schema_version',2,'country','Brasil','batch_key',v_key||'-rosters-br');
  v_roster_doc:=jsonb_build_object('metadata',v_metadata,'squads',jsonb_build_array(
    jsonb_build_object('club_source_key',v_first_keys->>'BR','category','Primera','season','2026','source_season','2026',
      'source','verified_manual','source_url','https://www.transfermarkt.com/synthetic-club/kader/verein/'||(v_tm_base+101)::text,
      'checked_at',v_checked,'completeness','complete','expected_count',28,'players',v_rows),
    jsonb_build_object('club_source_key',v_first_keys->>'BR','category','Reserva','season','2026','source_season','2026',
      'source','verified_manual','source_url','https://www.transfermarkt.com/synthetic-reserve/kader/verein/'||(v_tm_base+990)::text,
      'checked_at',v_checked,'completeness','complete','expected_count',2,'players',jsonb_build_array(v_rows->0,v_rows->1))));
  v_result:=scouting.import_roster_batch(v_roster_doc,repeat('d',64));
  if (v_result->>'players_inserted')::integer<>28 or (v_result->>'observations_skipped')::integer<>0
    or (select count(*) from scouting.players)<>v_initial_players+28
    or (select count(*) from scouting.player_squads where club_id=v_br_club)<>30 then raise exception 'Country roster import/identity failed';end if;
  if not (scouting.import_roster_batch(v_roster_doc,repeat('d',64))->>'replayed')::boolean then raise exception 'Roster replay failed';end if;
  select id into v_mononym from scouting.players where source_key='tm-player-'||(v_tm_base+10001)::text;
  select id into v_shared from scouting.players where source_key='tm-player-'||(v_tm_base+10002)::text;
  if (select name_kind from scouting.players where id=v_mononym)<>'sporting_mononym'
    or (select last_name from scouting.players where id=v_mononym)<>'' then raise exception 'Mononym identity not preserved';end if;
  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('country_code','BR','club_id',v_br_club,'competition_id','brasil-serie-a','category','Primera'));
  if (v_response->>'total_count')::integer<>28 or jsonb_array_length(v_response->'items')<>25
    or v_response#>>'{squad,status}'<>'verified' or (v_response#>>'{squad,player_count}')::integer<>28
    or not exists(select 1 from jsonb_array_elements(v_response->'items')p where p->>'id'=v_mononym::text and p->>'display_name'='Monoteste' and p->>'name_kind'='sporting_mononym' and p->>'last_name'='') then
    raise exception 'Country players metadata or mononym display failed';end if;
  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('country_code','BR','club_id',v_br_club,'competition_id',v_extra_comp,'category','Primera','position','Lateral','query','Jogador'));
  v_response2:=public.scouting_api(v_token,'players',jsonb_build_object('country_code','BR','club_id',v_br_club,'competition_id',v_extra_comp,'category','Primera','position','Lateral','query','Jogador','cursor','25'));
  if (v_response->>'total_count')::integer<>27 or jsonb_array_length(v_response->'items')<>25 or v_response->>'next_cursor'<>'25'
    or jsonb_array_length(v_response2->'items')<>2 or v_response2->>'next_cursor' is not null
    or (v_response#>>'{squad,player_count}')::integer<>28
    or exists(select 1 from jsonb_array_elements(v_response->'items')a join jsonb_array_elements(v_response2->'items')b on a->>'id'=b->>'id') then
    raise exception 'Country position/search/full-count pagination regressed';end if;
  v_response:=public.scouting_api(v_token,'players',jsonb_build_object('country_code','BR','club_id',v_br_club,'category','Reserva'));
  if (v_response->>'total_count')::integer<>2 or not exists(select 1 from jsonb_array_elements(v_response->'items')p where p->>'id'=v_mononym::text) then
    raise exception 'Reserve duplicated/lost catalogue identity';end if;
  begin
    perform public.scouting_api(v_token,'players',jsonb_build_object('club_id',v_br_club));
    raise exception 'Foreign club accepted without explicit country';
  exception when sqlstate 'PT422' then null;end;
  begin
    perform public.scouting_api(v_token,'players',jsonb_build_object('country_code','BR','club_id',v_br_club,'competition_id','brasil-serie-b'));
    raise exception 'Players accepted unrelated current competition';
  exception when sqlstate 'PT422' then null;end;
  v_bad:=jsonb_set(v_roster_doc,'{metadata}',scouting.catalogue_country_fingerprints('CL')||jsonb_build_object('schema_version',2,'country','Chile','batch_key',v_key||'-rosters-wrong-country'));
  begin
    perform scouting.import_roster_batch(v_bad,repeat('e',64));
    raise exception 'Roster batch accepted another country club';
  exception when others then
    if sqlerrm not like 'Squad club country does not match batch country%' then raise;end if;
  end;

  -- An abbreviated fresh source must neither remove absent players nor copy the
  -- entire country into run snapshots. Only its one observed identity is saved.
  v_bad:=jsonb_set(v_roster_doc,'{metadata}',scouting.catalogue_country_fingerprints('BR')||jsonb_build_object('schema_version',2,'country','Brasil','batch_key',v_key||'-rosters-partial'));
  v_bad:=jsonb_set(v_bad,'{squads}',jsonb_build_array((v_roster_doc#>'{squads,0}')||jsonb_build_object('checked_at',clock_timestamp(),
    'completeness','partial','expected_count',28,'players',jsonb_build_array(v_rows->0))));
  v_result:=scouting.import_roster_batch(v_bad,repeat('f',64));
  select metadata into v_snapshot_meta from scouting.catalogue_runs where id=(v_result->>'run_id')::uuid;
  if jsonb_array_length(v_snapshot_meta->'before_players')<>1 or jsonb_array_length(v_snapshot_meta->'after_players')<>1
    or (select count(*) from scouting.players where club_id=v_br_club)<>28
    or (select count(*) from scouting.player_squads where club_id=v_br_club and category='Primera' and active)<>28 then
    raise exception 'Partial source removed players or bloated affected-identity snapshots';end if;
  -- Same global TMID in Chile is a reviewable affiliation conflict, never a new
  -- player UUID, automatic transfer, or mutation of an Argentine/Brazilian row.
  v_bad:=jsonb_build_object('metadata',scouting.catalogue_country_fingerprints('CL')||jsonb_build_object('schema_version',2,'country','Chile','batch_key',v_key||'-rosters-conflict'),
    'squads',jsonb_build_array((v_roster_doc#>'{squads,0}')||jsonb_build_object('club_source_key',v_first_keys->>'CL',
      'source_url','https://www.transfermarkt.com/synthetic-chile/kader/verein/'||(v_tm_base+201)::text,
      'checked_at',clock_timestamp(),'expected_count',1,'players',jsonb_build_array(v_rows->1))));
  v_result:=scouting.import_roster_batch(v_bad,repeat('1',64));
  if (v_result->>'observations_skipped')::integer<>1 or v_result#>>'{conflicts,0,reason}'<>'affiliation_requires_reconciliation'
    or (select club_id from scouting.players where id=v_shared)<>v_br_club
    or exists(select 1 from scouting.player_squads where player_id=v_shared and club_id=v_cl_club)
    or (select count(*) from scouting.players)<>v_initial_players+28 then raise exception 'Cross-country source duplicated/moved player';end if;
  if (select count(*) from scouting.events)<>v_initial_events or (select count(*) from scouting.recommendations)<>v_initial_recommendations then
    raise exception 'Catalogue import wrote recommendation events';end if;

  -- Manual recommendations remain possible in all six countries. A missing
  -- country only defaults to Argentina; it cannot reinterpret a foreign region.
  foreach v_country in array array['AR','BR','CL','CO','EC','UY'] loop
    select name into v_region from scouting.provinces where country_code=v_country order by name limit 1;
    select id into v_comp from scouting.competitions where active and country_code=v_country order by sort_order,id limit 1;
    v_payload:=jsonb_build_object('panel_context','socio','country_code',v_country,'request_id',gen_random_uuid(),
      'club_manual',jsonb_build_object('name',v_key||' manual '||v_country,'province',v_region,'city','Localidad sintética','league','Liga sintética'),
      'competition_id',v_comp,'category','Primera','player',jsonb_build_object('first_name','Jugador','last_name','Sintético','position','Lateral'),
      'reason','Synthetic recommendation to verify country-specific manual fields and global transparency.');
    if v_country='BR' then
      begin
        perform public.scouting_api(v_token,'create',v_payload-'country_code');
        raise exception 'Manual foreign region accepted without explicit country';
      exception when sqlstate 'PT422' then null;end;
      begin
        perform public.scouting_api(v_token,'create',jsonb_set(v_payload,'{player,last_name}','""'::jsonb));
        raise exception 'Unverified manual mononym accepted';
      exception when sqlstate 'PT422' then null;end;
      begin
        perform public.scouting_api(v_token,'create',jsonb_set(v_payload,'{competition_id}','"primera-division"'::jsonb));
        raise exception 'Manual cross-country competition accepted';
      exception when sqlstate 'PT422' then null;end;
    end if;
    v_result:=public.scouting_api(v_token,'create',v_payload);
    if v_result#>>'{recommendation,club,country_code}'<>v_country
      or v_result#>>'{recommendation,club,country_name}'<>scouting.country_name(v_country)
      or v_result#>>'{recommendation,club,region_name}'<>scouting.region_name(v_region) then raise exception 'Manual snapshot country missing';end if;
    if v_country='BR' then v_manual_br:=(v_result#>>'{recommendation,id}')::uuid;end if;
  end loop;
  v_payload:=jsonb_build_object('panel_context','socio','country_code','BR','request_id',gen_random_uuid(),
    'club_id',v_br_club,'competition_id','brasil-serie-a','category','Primera','player_id',v_mononym,
    'player',jsonb_build_object('position','Arquero'),
    'reason','Synthetic recommendation of an evidenced sporting mononym with a stable global identity.');
  v_result:=public.scouting_api(v_token,'create',v_payload);
  v_mononym_rec:=(v_result#>>'{recommendation,id}')::uuid;
  select to_jsonb(r) into v_saved_rec from scouting.recommendations r where id=v_mononym_rec;
  if v_result#>>'{recommendation,player,name_kind}'<>'sporting_mononym'
    or v_result#>>'{recommendation,player,last_name}'<>'' then raise exception 'Mononym recommendation snapshot changed source name';end if;
  v_payload:=(v_payload-'player_id')||jsonb_build_object('request_id',gen_random_uuid(),'reference_recommendation_id',v_mononym_rec);
  v_result:=public.scouting_api(v_other_token,'create',v_payload);
  if v_result#>>'{recommendation,player,id}'<>v_mononym::text or v_result#>>'{recommendation,player,last_name}'<>'' then
    raise exception 'Recommend-also lost mononym identity';end if;
  v_result:=public.scouting_api(v_other_token,'feed',jsonb_build_object('query',v_key,'country_code','BR'));
  if jsonb_array_length(v_result->'items')<>8
    or (select count(distinct x#>>'{club,country_code}') from jsonb_array_elements(v_result->'items')x)<>6 then
    raise exception 'Global feed was implicitly filtered by scouting country';end if;
  v_result:=public.scouting_api(v_other_token,'dashboard',jsonb_build_object('country_code','BR'));
  if (v_result#>>'{dashboard,total_recommendations}')::integer<>v_initial_recommendations+8
    or not exists(select 1 from jsonb_array_elements(v_result#>'{dashboard,most_recommended_players}')x
      where x->>'player_id'=v_mononym::text and (x->>'recommendation_count')::integer=2) then raise exception 'Global ranking/dashboard changed';end if;
  v_result:=public.scouting_api(v_admin_token,'admin_validate_club',jsonb_build_object('id',v_manual_br,'request_id',gen_random_uuid(),
    'message','Synthetic reviewed manual Brazilian club validation.'));
  select cv.club_id into v_club_id from scouting.club_validations cv where cv.recommendation_id=v_manual_br;
  if v_club_id is null or (select country_code from scouting.clubs where id=v_club_id)<>'BR'
    or not exists(select 1 from scouting.club_competitions m join scouting.competitions c on c.id=m.competition_id where m.club_id=v_club_id and c.country_code='BR') then
    raise exception 'Validated manual club lost its country';end if;
  begin
    perform public.scouting_api(v_token,'admin_validate_club',jsonb_build_object('id',v_manual_br,'request_id',gen_random_uuid(),'message','Synthetic unauthorized change.'));
    raise exception 'Member obtained administrator mutation';
  exception when sqlstate 'PT403' then null;end;
  if (select to_jsonb(r) from scouting.recommendations r where id=v_mononym_rec)<>v_saved_rec then
    raise exception 'Another recommendation changed the original immutable snapshot';end if;
  select encode(extensions.digest(convert_to(jsonb_build_object(
    'recommendations',(select coalesce(jsonb_agg(to_jsonb(r) order by r.id),'[]'::jsonb) from scouting.recommendations r where owner_numero_socio not in (v_owner,v_other,v_admin)),
    'events',(select coalesce(jsonb_agg(to_jsonb(e) order by e.id),'[]'::jsonb) from scouting.events e where actor_numero_socio not in (v_owner,v_other,v_admin)))::text,'UTF8'),'sha256'),'hex') into v_final_history_hash;
  select encode(extensions.digest(convert_to(coalesce(jsonb_agg(to_jsonb(p) order by p.id),'[]'::jsonb)::text,'UTF8'),'sha256'),'hex')
    into v_final_arg_players_hash from scouting.players p join scouting.clubs c on c.id=p.club_id where c.country_code='AR';
  if v_initial_history_hash<>v_final_history_hash or v_initial_arg_players_hash<>v_final_arg_players_hash then
    raise exception 'Country work modified historical data or Argentine player rows';end if;
  if public.blockchain_envio_habilitado() then raise exception 'Country expansion enabled blockchain sending';end if;
  if has_function_privilege('anon','public.scouting_api(text,text,jsonb)','EXECUTE')
    or has_function_privilege('service_role','scouting.import_club_batch(jsonb,text)','EXECUTE')
    or has_function_privilege('service_role','scouting.import_roster_batch(jsonb,text)','EXECUTE')
    or has_table_privilege('authenticated','scouting.clubs','SELECT') then raise exception 'Country migration widened private access';end if;
  raise notice 'Scouting country regression passed: six countries, legacy AR, filtered pagination, multi-competition clubs, mononyms, shared identities, manual validation, global feed, provenance/replay/fingerprints, unchanged history and inactive blockchain';
end;
$countries_test$;
rollback;
