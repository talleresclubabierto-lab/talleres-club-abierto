-- Final read-through of the REAL reviewed Scouting catalogue after all imports.
-- Catalogue, recommendation history and configuration are read only. The only
-- fixture is a new synthetic member/session, reverted by the final ROLLBACK.
-- No importer, schema DDL, club/player mutation or real credential is used.
-- Counts come from the current database; competition IDs describe the reviewed
-- coverage target (42 foreign competitions and the 5 established Argentine ones).
begin isolation level repeatable read;
set local statement_timeout='120s';
set local lock_timeout='5s';
do $real_catalogue_test$
declare
  v_member bigint:=887000000000000+(floor(random()*1000000000))::bigint;
  v_token text:=encode(extensions.gen_random_bytes(32),'hex');
  v_country text;
  v_comp_id text;
  v_target_country text;
  v_comp scouting.competitions%rowtype;
  v_bootstrap jsonb;
  v_response jsonb;
  v_items jsonb;
  v_country_summary jsonb:='[]'::jsonb;
  v_comp_summary jsonb:='[]'::jsonb;
  v_roster_summary jsonb:='[]'::jsonb;
  v_position_summary jsonb;
  v_mononym_summary jsonb;
  v_catalogue_before jsonb:='{}'::jsonb;
  v_catalogue_after jsonb:='{}'::jsonb;
  v_history_before text;
  v_history_after text;
  v_blockchain_before boolean;
  v_blockchain_after boolean;
  v_expected_ids uuid[];
  v_seen_ids uuid[];
  v_page_ids uuid[];
  v_cursor text;
  v_next text;
  v_page_count integer;
  v_club_page_count integer:=0;
  v_comp_page_count integer:=0;
  v_player_page_count integer:=0;
  v_club_count integer;
  v_player_count integer;
  v_full_squad_count integer;
  v_expected_status text;
  v_expected_checked timestamptz;
  v_sample record;
  v_position record;
  v_mononym record;
  v_item jsonb;
  v_expected_competitions constant text[]:=array[
    'primera-division','primera-nacional','federal-a','primera-b','primera-c',
    'chile-primera-division','chile-primera-b','chile-segunda-profesional',
    'ecuador-serie-a','ecuador-serie-b','ecuador-copa-ecuador',
    'uruguay-primera-division','uruguay-segunda-profesional','uruguay-copa-auf-uruguay',
    'colombia-liga-betplay','colombia-torneo-betplay',
    'brasil-serie-a','brasil-serie-b','brasil-serie-c','brasil-serie-d','brasil-copa-do-brasil',
    'brasil-campeonato-paulista','brasil-campeonato-piauiense','brasil-campeonato-acreano',
    'brasil-campeonato-alagoano','brasil-campeonato-amapaense','brasil-campeonato-baiano',
    'brasil-campeonato-cearense','brasil-campeonato-carioca','brasil-campeonato-mineiro',
    'brasil-campeonato-brasiliense','brasil-campeonato-capixaba','brasil-campeonato-goiano',
    'brasil-campeonato-maranhense','brasil-campeonato-mato-grossense','brasil-campeonato-sul-mato-grossense',
    'brasil-campeonato-paraense','brasil-campeonato-paraibano','brasil-campeonato-pernambucano',
    'brasil-campeonato-paranaense','brasil-campeonato-rondoniense','brasil-campeonato-potiguar',
    'brasil-campeonato-roraimense','brasil-campeonato-gaucho','brasil-campeonato-catarinense',
    'brasil-campeonato-sergipano','brasil-campeonato-tocantinense'];
begin
  v_blockchain_before:=public.blockchain_envio_habilitado();
  select encode(extensions.digest(convert_to(jsonb_build_object(
    'recommendations',(select coalesce(jsonb_agg(jsonb_build_object('id',r.id,'snapshot',r.snapshot,'hash',r.commitment_hash,
      'status',r.status,'created_at',r.created_at,'updated_at',r.updated_at) order by r.id),'[]'::jsonb) from scouting.recommendations r),
    'events',(select coalesce(jsonb_agg(jsonb_build_object('id',e.id,'hash',e.event_hash,'status',e.status) order by e.id),'[]'::jsonb) from scouting.events e))::text,'UTF8'),'sha256'),'hex') into v_history_before;
  foreach v_country in array array['AR','BR','CL','CO','EC','UY'] loop
    v_catalogue_before:=v_catalogue_before||jsonb_build_object(v_country,scouting.catalogue_country_fingerprints(v_country));
  end loop;
  insert into public.socios(numero_socio,nombre,fecha_alta,habilitado)
    values(v_member,'SCOUTING REAL CATALOGUE SYNTHETIC READER',current_date,true);
  perform public.crear_sesion_segura_interno(v_member,v_token,10,'scouting_country_catalogue_test','{}'::jsonb);

  -- Full country walks verify every active club, with exact ordering and no
  -- duplicated/missing identity across the real 25-row API pages.
  foreach v_country in array array['AR','BR','CL','CO','EC','UY'] loop
    v_bootstrap:=public.scouting_api(v_token,'bootstrap',jsonb_build_object('country_code',v_country));
    select count(*) into v_club_count from scouting.clubs where active and country_code=v_country;
    select count(*) into v_player_count from scouting.players p join scouting.clubs c on c.id=p.club_id
      where p.active and c.active and c.country_code=v_country;
    if v_club_count=0 or v_player_count=0 then raise exception 'Real country catalogue is not loaded: %',v_country;end if;
    if v_bootstrap->>'country_code' is distinct from v_country or jsonb_array_length(v_bootstrap->'countries') is distinct from 6
      or (v_bootstrap#>>'{catalogue,club_count}')::integer is distinct from v_club_count
      or (v_bootstrap#>>'{catalogue,player_count}')::integer is distinct from v_player_count
      or exists(select 1 from jsonb_array_elements(v_bootstrap->'regions')r where r->>'country_code' is distinct from v_country)
      or exists(select 1 from jsonb_array_elements(v_bootstrap->'competitions')c where c->>'country_code' is distinct from v_country) then
      raise exception 'Real bootstrap country/count mismatch: %',v_country;
    end if;
    if (select coalesce(array_agg(x->>'value' order by x->>'value'),array[]::text[]) from jsonb_array_elements(v_bootstrap->'regions')x)
      is distinct from (select coalesce(array_agg(name order by name),array[]::text[]) from scouting.provinces where country_code=v_country) then
      raise exception 'Real region list lost entries: %',v_country;
    end if;
    select coalesce(array_agg(c.id order by lower(c.name),c.id),array[]::uuid[]) into v_expected_ids
      from scouting.clubs c where c.active and c.country_code=v_country;
    v_seen_ids:=array[]::uuid[];v_cursor:=null;v_page_count:=0;
    loop
      v_response:=public.scouting_api(v_token,'clubs',jsonb_build_object('country_code',v_country,'cursor',v_cursor));
      v_items:=v_response->'items';v_page_count:=v_page_count+1;
      if (v_response->>'total_count')::integer is distinct from v_club_count or jsonb_array_length(v_items)>25
        or exists(select 1 from jsonb_array_elements(v_items)c where c->>'country_code' is distinct from v_country) then
        raise exception 'Real club page country/count mismatch: % page %',v_country,v_page_count;
      end if;
      select coalesce(array_agg((x.item->>'id')::uuid order by x.ord),array[]::uuid[]) into v_page_ids
        from jsonb_array_elements(v_items) with ordinality x(item,ord);
      v_seen_ids:=v_seen_ids||v_page_ids;v_next:=v_response->>'next_cursor';
      if v_next is not null and v_next<>cardinality(v_seen_ids)::text then raise exception 'Club cursor skipped rows: %',v_country;end if;
      if v_page_count>ceil(v_club_count/25.0)::integer+1 then raise exception 'Club pagination did not terminate: %',v_country;end if;
      exit when v_next is null;
      v_cursor:=v_next;
    end loop;
    if v_seen_ids is distinct from v_expected_ids then raise exception 'Real country club walk lost, duplicated or reordered identities: %',v_country;end if;
    v_club_page_count:=v_club_page_count+v_page_count;
    v_country_summary:=v_country_summary||jsonb_build_array(jsonb_build_object('country_code',v_country,
      'clubs',v_club_count,'players',v_player_count,'club_pages',v_page_count,'regions',jsonb_array_length(v_bootstrap->'regions')));
  end loop;
  v_bootstrap:=public.scouting_api(v_token,'bootstrap','{}'::jsonb);
  if v_bootstrap->>'country_code' is distinct from 'AR' then raise exception 'Legacy bootstrap country changed';end if;

  -- All reviewed target competitions must have current clubs. Counters and
  -- pagination are checked against real memberships, not a frozen club total.
  foreach v_comp_id in array v_expected_competitions loop
    v_target_country:=case split_part(v_comp_id,'-',1) when 'brasil' then 'BR' when 'chile' then 'CL'
      when 'colombia' then 'CO' when 'ecuador' then 'EC' when 'uruguay' then 'UY' else 'AR' end;
    select * into v_comp from scouting.competitions where id=v_comp_id and active and country_code=v_target_country;
    if not found then raise exception 'Reviewed competition is missing/inactive/in another country: %',v_comp_id;end if;
    select coalesce(array_agg(c.id order by lower(c.name),c.id),array[]::uuid[]) into v_expected_ids from scouting.clubs c
      where c.active and c.country_code=v_target_country and exists(select 1 from scouting.club_competitions m
        where m.club_id=c.id and m.competition_id=v_comp_id and m.season=v_comp.season);
    v_club_count:=cardinality(v_expected_ids);
    if v_club_count=0 then raise exception 'Reviewed competition has no current imported club: %',v_comp_id;end if;
    v_seen_ids:=array[]::uuid[];v_cursor:=null;v_page_count:=0;
    loop
      v_response:=public.scouting_api(v_token,'clubs',jsonb_build_object('country_code',v_target_country,'competition_id',v_comp_id,'cursor',v_cursor));
      v_items:=v_response->'items';v_page_count:=v_page_count+1;
      if (v_response->>'total_count')::integer is distinct from v_club_count or jsonb_array_length(v_items)>25
        or exists(select 1 from jsonb_array_elements(v_items)c where c->>'country_code' is distinct from v_target_country
          or c->>'competition_id' is distinct from v_comp_id or not exists(select 1 from jsonb_array_elements(c->'competitions')m
            where m->>'id'=v_comp_id and m->>'country_code'=v_target_country and m->>'season'=v_comp.season)) then
        raise exception 'Real competition filter/count mismatch: % page %',v_comp_id,v_page_count;
      end if;
      select coalesce(array_agg((x.item->>'id')::uuid order by x.ord),array[]::uuid[]) into v_page_ids
        from jsonb_array_elements(v_items) with ordinality x(item,ord);
      v_seen_ids:=v_seen_ids||v_page_ids;v_next:=v_response->>'next_cursor';
      if v_next is not null and v_next<>cardinality(v_seen_ids)::text then raise exception 'Competition cursor skipped rows: %',v_comp_id;end if;
      if v_page_count>ceil(v_club_count/25.0)::integer+1 then raise exception 'Competition pagination did not terminate: %',v_comp_id;end if;
      exit when v_next is null;v_cursor:=v_next;
    end loop;
    if v_seen_ids is distinct from v_expected_ids then raise exception 'Real competition walk lost/duplicated memberships: %',v_comp_id;end if;
    v_comp_page_count:=v_comp_page_count+v_page_count;
    v_comp_summary:=v_comp_summary||jsonb_build_array(jsonb_build_object('country_code',v_target_country,'competition_id',v_comp_id,
      'clubs',v_club_count,'pages',v_page_count));
  end loop;

  -- Pick one real club for every observed country/category/source-status cohort,
  -- including absent reviews. Prefer the largest source in each cohort so the
  -- sample exercises full plantels and pagination without fetching all players.
  for v_sample in
    select distinct on(c.country_code,cat.category,coalesce(r.completeness,'absent'))
      c.id as club_id,c.name as club_name,c.source_key,c.country_code,cat.category,
      r.completeness,r.expected_count,r.source_url,r.source_season,r.season as review_season,r.checked_at as review_checked_at
    from scouting.clubs c cross join (values('Primera'),('Reserva'))cat(category)
    left join scouting.squad_reviews r on r.club_id=c.id and r.category=cat.category
      and (r.season is null or exists(select 1 from scouting.club_competitions m join scouting.competitions co on co.id=m.competition_id
        where m.club_id=c.id and co.active and m.season=co.season and m.season=r.season))
    where c.active and c.country_code in ('AR','BR','CL','CO','EC','UY')
    order by c.country_code,cat.category,coalesce(r.completeness,'absent'),r.imported_count desc nulls last,c.source_key
  loop
    select coalesce(array_agg(p.id order by lower(p.last_name),lower(p.first_name),p.id),array[]::uuid[]),max(p.checked_at)
      into v_expected_ids,v_expected_checked from scouting.players p where p.active and p.club_id=v_sample.club_id
        and scouting.player_has_squad(p.id,v_sample.club_id,v_sample.category);
    v_player_count:=cardinality(v_expected_ids);
    v_expected_status:=case when v_sample.completeness='complete' and v_sample.expected_count=v_player_count and v_player_count>0 then 'verified'
      when v_player_count>0 then 'partial' when v_sample.completeness='unavailable' then 'unavailable' else 'not_loaded' end;
    if v_sample.completeness in ('complete','partial') then v_expected_checked:=v_sample.review_checked_at;end if;
    v_seen_ids:=array[]::uuid[];v_cursor:=null;v_page_count:=0;
    loop
      v_response:=public.scouting_api(v_token,'players',jsonb_build_object('country_code',v_sample.country_code,
        'club_id',v_sample.club_id,'category',v_sample.category,'cursor',v_cursor));
      v_items:=v_response->'items';v_page_count:=v_page_count+1;
      if (v_response->>'total_count')::integer is distinct from v_player_count
        or (v_response#>>'{squad,player_count}')::integer is distinct from v_player_count
        or v_response#>>'{squad,status}' is distinct from v_expected_status
        or v_response#>>'{squad,category}' is distinct from v_sample.category
        or v_response#>>'{squad,source_url}' is distinct from v_sample.source_url
        or v_response#>>'{squad,source_season}' is distinct from v_sample.source_season
        or v_response#>>'{squad,competition_season}' is distinct from v_sample.review_season
        or v_response#>>'{squad,last_attempt_status}' is distinct from v_sample.completeness
        or (v_response#>>'{squad,checked_at}')::timestamptz is distinct from v_expected_checked
        or (v_response#>>'{squad,last_attempt_at}')::timestamptz is distinct from v_sample.review_checked_at
        or jsonb_array_length(v_items)>25
        or exists(select 1 from jsonb_array_elements(v_items)p where p->>'category' is distinct from v_sample.category)
        or not exists(select 1 from jsonb_array_elements(v_response#>'{squad,available_categories}')s where s->>'category'='Primera')
        or not exists(select 1 from jsonb_array_elements(v_response#>'{squad,available_categories}')s where s->>'category'='Reserva') then
        raise exception 'Real squad source/coverage metadata mismatch: % / % / %',v_sample.country_code,v_sample.source_key,v_sample.category;
      end if;
      select coalesce(array_agg((x.item->>'id')::uuid order by x.ord),array[]::uuid[]) into v_page_ids
        from jsonb_array_elements(v_items) with ordinality x(item,ord);
      v_seen_ids:=v_seen_ids||v_page_ids;v_next:=v_response->>'next_cursor';
      if v_next is not null and v_next<>cardinality(v_seen_ids)::text then raise exception 'Real player cursor skipped rows';end if;
      if v_page_count>ceil(v_player_count/25.0)::integer+1 then raise exception 'Real player pagination did not terminate';end if;
      exit when v_next is null;v_cursor:=v_next;
    end loop;
    if v_seen_ids is distinct from v_expected_ids then raise exception 'Real plantel walk lost/duplicated player UUIDs: %/%',v_sample.source_key,v_sample.category;end if;
    v_player_page_count:=v_player_page_count+v_page_count;
    v_roster_summary:=v_roster_summary||jsonb_build_array(jsonb_build_object('country_code',v_sample.country_code,'club',v_sample.club_name,
      'category',v_sample.category,'source_status',coalesce(v_sample.completeness,'absent'),'status',v_expected_status,
      'players',v_player_count,'pages',v_page_count,'source_season',v_sample.source_season));
  end loop;
  foreach v_country in array array['AR','BR','CL','CO','EC','UY'] loop
    if not exists(select 1 from jsonb_array_elements(v_roster_summary)s where s->>'country_code'=v_country and s->>'category'='Primera' and (s->>'players')::integer>0)
      or not exists(select 1 from jsonb_array_elements(v_roster_summary)s where s->>'country_code'=v_country and s->>'category'='Reserva' and (s->>'players')::integer>0) then
      raise exception 'No selectable real Primera/Reserva source sample for %',v_country;
    end if;
  end loop;

  -- Choose a real mixed-position plantel with matches both before and AFTER the
  -- first unfiltered page. A client/server filter restricted to 25 rows fails.
  with ranked as (
    select c.id as club_id,c.name as club_name,c.country_code,p.position,
      row_number() over(partition by c.id order by lower(p.last_name),lower(p.first_name),p.id) as unfiltered_rank,
      count(*) over(partition by c.id) as plantel_count
    from scouting.players p join scouting.clubs c on c.id=p.club_id where c.active and p.active
      and scouting.player_has_squad(p.id,c.id,'Primera')
  )
  select club_id,club_name,country_code,position,max(plantel_count)::integer as plantel_count,count(*)::integer as position_count
    into v_position from ranked group by club_id,club_name,country_code,position
    having min(unfiltered_rank)<=25 and max(unfiltered_rank)>25 and count(*)<max(plantel_count)
    order by (position is null),count(*) desc,country_code,club_id limit 1;
  if not found then raise exception 'No real mixed-position plantel crosses the first 25 rows; cannot exercise full-roster filtering';end if;
  select coalesce(array_agg(p.id order by lower(p.last_name),lower(p.first_name),p.id),array[]::uuid[]) into v_expected_ids
    from scouting.players p where p.active and p.club_id=v_position.club_id and scouting.player_has_squad(p.id,v_position.club_id,'Primera')
      and p.position is not distinct from v_position.position;
  v_seen_ids:=array[]::uuid[];v_cursor:=null;v_page_count:=0;
  loop
    v_response:=public.scouting_api(v_token,'players',jsonb_build_object('country_code',v_position.country_code,
      'club_id',v_position.club_id,'category','Primera','position',coalesce(v_position.position,'__unknown__'),'cursor',v_cursor));
    v_items:=v_response->'items';v_page_count:=v_page_count+1;
    if (v_response->>'total_count')::integer is distinct from cardinality(v_expected_ids)
      or (v_response#>>'{squad,player_count}')::integer is distinct from v_position.plantel_count
      or exists(select 1 from jsonb_array_elements(v_items)p where p->>'position' is distinct from v_position.position) then
      raise exception 'Position filter/count was applied to a partial real plantel';
    end if;
    select coalesce(array_agg((x.item->>'id')::uuid order by x.ord),array[]::uuid[]) into v_page_ids
      from jsonb_array_elements(v_items) with ordinality x(item,ord);
    v_seen_ids:=v_seen_ids||v_page_ids;v_next:=v_response->>'next_cursor';
    if v_next is not null and v_next<>cardinality(v_seen_ids)::text then raise exception 'Filtered player cursor skipped rows';end if;
    if v_page_count>ceil(cardinality(v_expected_ids)/25.0)::integer+1 then raise exception 'Filtered player pagination did not terminate';end if;
    exit when v_next is null;v_cursor:=v_next;
  end loop;
  if v_seen_ids is distinct from v_expected_ids then raise exception 'Full-plantel position filter lost real matches beyond row 25';end if;
  v_position_summary:=jsonb_build_object('country_code',v_position.country_code,'club',v_position.club_name,'category','Primera',
    'position',coalesce(v_position.position,'__unknown__'),'plantel_players',v_position.plantel_count,
    'matching_players',cardinality(v_expected_ids),'pages',v_page_count,'included_matches_beyond_unfiltered_row_25',true);

  select p.id,p.first_name,p.last_name,p.transfermarkt_url,c.id as club_id,c.name as club_name,
    case when scouting.player_has_squad(p.id,c.id,'Primera') then 'Primera' else 'Reserva' end as category
    into v_mononym from scouting.players p join scouting.clubs c on c.id=p.club_id
    where c.active and c.country_code='BR' and p.active and p.name_kind='sporting_mononym' and p.last_name=''
      and (scouting.player_has_squad(p.id,c.id,'Primera') or scouting.player_has_squad(p.id,c.id,'Reserva'))
    order by char_length(p.first_name) desc,p.first_name,p.id limit 1;
  if not found then raise exception 'Brazilian catalogue has no selectable sporting mononym';end if;
  v_cursor:=null;v_page_count:=0;v_item:=null;
  loop
    v_response:=public.scouting_api(v_token,'players',jsonb_build_object('country_code','BR','club_id',v_mononym.club_id,
      'category',v_mononym.category,'query',v_mononym.first_name,'cursor',v_cursor));
    select x into v_item from jsonb_array_elements(v_response->'items')x where x->>'id'=v_mononym.id::text;
    v_page_count:=v_page_count+1;v_next:=v_response->>'next_cursor';
    exit when v_item is not null or v_next is null;
    if v_page_count>ceil((v_response->>'total_count')::integer/25.0)::integer+1 then raise exception 'Mononym search did not terminate';end if;
    v_cursor:=v_next;
  end loop;
  if v_item is null or v_item->>'name_kind' is distinct from 'sporting_mononym' or v_item->>'last_name' is distinct from ''
    or v_item->>'display_name' is distinct from v_mononym.first_name then raise exception 'Real mononym was dropped or given a fabricated surname';end if;
  v_mononym_summary:=jsonb_build_object('country_code','BR','club',v_mononym.club_name,'category',v_mononym.category,
    'display_name',v_item->>'display_name','name_kind',v_item->>'name_kind','source_url',v_mononym.transfermarkt_url);

  foreach v_country in array array['AR','BR','CL','CO','EC','UY'] loop
    v_catalogue_after:=v_catalogue_after||jsonb_build_object(v_country,scouting.catalogue_country_fingerprints(v_country));
  end loop;
  select encode(extensions.digest(convert_to(jsonb_build_object(
    'recommendations',(select coalesce(jsonb_agg(jsonb_build_object('id',r.id,'snapshot',r.snapshot,'hash',r.commitment_hash,
      'status',r.status,'created_at',r.created_at,'updated_at',r.updated_at) order by r.id),'[]'::jsonb) from scouting.recommendations r),
    'events',(select coalesce(jsonb_agg(jsonb_build_object('id',e.id,'hash',e.event_hash,'status',e.status) order by e.id),'[]'::jsonb) from scouting.events e))::text,'UTF8'),'sha256'),'hex') into v_history_after;
  v_blockchain_after:=public.blockchain_envio_habilitado();
  if v_catalogue_after is distinct from v_catalogue_before then raise exception 'Read-through altered catalogue state';end if;
  if v_history_after is distinct from v_history_before then raise exception 'Read-through altered recommendation history';end if;
  if v_blockchain_after is distinct from v_blockchain_before then raise exception 'Read-through altered blockchain enablement';end if;
  perform set_config('scouting.country_catalogue_test_result',jsonb_build_object('ok',true,'countries',v_country_summary,
    'competition_targets_tested',cardinality(v_expected_competitions),'competitions',v_comp_summary,
    'club_pages',v_club_page_count,'competition_pages',v_comp_page_count,'sample_player_pages',v_player_page_count,
    'roster_cohorts_tested',jsonb_array_length(v_roster_summary),'roster_samples',v_roster_summary,
    'position_sample',v_position_summary,'mononym_sample',v_mononym_summary,
    'catalogue_unchanged',true,'history_unchanged',true,'blockchain_enabled',v_blockchain_after,
    'session_scope','new_synthetic_reader_rolled_back','as_of',statement_timestamp())::text,true);
end;
$real_catalogue_test$;
select current_setting('scouting.country_catalogue_test_result')::jsonb as scouting_country_catalogue_validation;
rollback;
