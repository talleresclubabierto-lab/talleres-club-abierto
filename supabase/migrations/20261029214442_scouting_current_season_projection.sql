-- Current-season projection for scouting catalogue refreshes.
-- Source: SELECT pg_get_functiondef('public.scouting_api(text,text,jsonb)'::regprocedure)
-- from project sziuyjicqyxnmbgtbopg, observed 2026-10-29.
-- Live definition MD5: f05e866bef275a69b71fd89a53d10a03
-- Proposed definition MD5: 972089e8df055deb7d23884704c38d22
-- Apply through the normal migration workflow in a transaction.
-- No table data, sessions, audit/blockchain logic or grants are changed.
set local lock_timeout = '5s';
set local statement_timeout = '30s';

do $season_migration$
declare
  v_oid oid := 'public.scouting_api(text,text,jsonb)'::regprocedure;
  v_before text := pg_get_functiondef(v_oid);
  v_before_attributes jsonb;
  v_after_attributes jsonb;
  v_target text := $current_season_definition$
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
      select id,first_name,last_name,category,position,transfermarkt_url,checked_at from scouting.players
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
$function$
$current_season_definition$;
begin
  -- Trim only the leading newline introduced by the dollar-quoted wrapper.
  v_target := ltrim(v_target, chr(10));
  if md5(v_before) = '972089e8df055deb7d23884704c38d22' then
    raise notice 'Current-season scouting projection is already installed';
    return;
  end if;
  if md5(v_before) <> 'f05e866bef275a69b71fd89a53d10a03' then
    raise exception 'scouting_api changed since review; retrieve its live definition and rebase this isolated patch';
  end if;
  if md5(v_target) <> '972089e8df055deb7d23884704c38d22' then
    raise exception 'Proposed scouting definition differs from the reviewed patch';
  end if;
  select jsonb_build_object('oid',p.oid,'owner',p.proowner,'acl',p.proacl,
    'security_definer',p.prosecdef,'config',p.proconfig,'volatility',p.provolatile,
    'parallel',p.proparallel,'leakproof',p.proleakproof)
    into v_before_attributes from pg_proc p where p.oid=v_oid;
  execute v_target;
  select jsonb_build_object('oid',p.oid,'owner',p.proowner,'acl',p.proacl,
    'security_definer',p.prosecdef,'config',p.proconfig,'volatility',p.provolatile,
    'parallel',p.proparallel,'leakproof',p.proleakproof)
    into v_after_attributes from pg_proc p where p.oid=v_oid;
  if v_after_attributes is distinct from v_before_attributes then
    raise exception 'Function identity, execution settings or privileges changed unexpectedly';
  end if;
  if md5(pg_get_functiondef(v_oid)) <> '972089e8df055deb7d23884704c38d22' then
    raise exception 'Installed scouting definition does not match the reviewed patch';
  end if;
end;
$season_migration$;
