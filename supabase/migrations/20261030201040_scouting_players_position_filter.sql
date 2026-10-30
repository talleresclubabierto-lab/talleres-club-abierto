-- Add a server-side position filter to the existing authenticated players
-- action. Pagination and matching totals use the same predicate; squad metadata
-- continues to describe the entire selected club/category.
-- No schema, grants, role/session checks, recommendation or audit changes.
set local lock_timeout='5s';
set local statement_timeout='45s';

do $position_filter_patch$
declare
  v_definition text;
  v_before_metadata jsonb;
  v_after_metadata jsonb;
begin
  select pg_get_functiondef(p.oid),jsonb_build_object('owner',p.proowner,'acl',p.proacl::text,
    'security_definer',p.prosecdef,'config',p.proconfig,'volatility',p.provolatile)
    into v_definition,v_before_metadata from pg_proc p
    where p.oid='public.scouting_api(text,text,jsonb)'::regprocedure;
  if md5(v_definition)<>'debdc4297e4adebaf2a5ed447a91ecec' then
    raise exception 'The scouting RPC changed since review; reconcile before applying the position filter';
  end if;

  if char_length(v_definition)-char_length(replace(v_definition,$old_position_validation$    v_category:=scouting.text_value(v_payload->'category',0,100,'categoría',true);
    with matches as ($old_position_validation$,''))
    <>char_length($old_position_validation$    v_category:=scouting.text_value(v_payload->'category',0,100,'categoría',true);
    with matches as ($old_position_validation$) then
    raise exception 'Position filter fragment mismatch: position_validation';
  end if;
  v_definition:=replace(v_definition,
    $old_position_validation$    v_category:=scouting.text_value(v_payload->'category',0,100,'categoría',true);
    with matches as ($old_position_validation$,
    $new_position_validation$    v_category:=scouting.text_value(v_payload->'category',0,100,'categoría',true);
    v_position:=scouting.text_value(v_payload->'position',0,60,'posición',true);
    if v_position is not null and v_position<>'__unknown__' and not (v_position=any(v_positions)) then
      raise exception using errcode='PT422',message='Seleccioná una posición válida';
    end if;
    with matches as ($new_position_validation$);

  if char_length(v_definition)-char_length(replace(v_definition,$old_matches_before_pagination$      where p.active and p.club_id=v_club_id and scouting.player_has_squad(p.id,v_club_id,v_category)
        and (v_query is null or strpos(lower(first_name||' '||last_name),lower(v_query))>0)$old_matches_before_pagination$,''))
    <>char_length($old_matches_before_pagination$      where p.active and p.club_id=v_club_id and scouting.player_has_squad(p.id,v_club_id,v_category)
        and (v_query is null or strpos(lower(first_name||' '||last_name),lower(v_query))>0)$old_matches_before_pagination$) then
    raise exception 'Position filter fragment mismatch: matches_before_pagination';
  end if;
  v_definition:=replace(v_definition,
    $old_matches_before_pagination$      where p.active and p.club_id=v_club_id and scouting.player_has_squad(p.id,v_club_id,v_category)
        and (v_query is null or strpos(lower(first_name||' '||last_name),lower(v_query))>0)$old_matches_before_pagination$,
    $new_matches_before_pagination$      where p.active and p.club_id=v_club_id and scouting.player_has_squad(p.id,v_club_id,v_category)
        and (v_position is null or case when v_position='__unknown__' then p.position is null else p.position=v_position end)
        and (v_query is null or strpos(lower(first_name||' '||last_name),lower(v_query))>0)$new_matches_before_pagination$);

  if char_length(v_definition)-char_length(replace(v_definition,$old_matching_total_count$          and scouting.player_has_squad(p.id,v_club_id,v_category)
          and (v_query is null or strpos(lower(p.first_name||' '||p.last_name),lower(v_query))>0)),$old_matching_total_count$,''))
    <>char_length($old_matching_total_count$          and scouting.player_has_squad(p.id,v_club_id,v_category)
          and (v_query is null or strpos(lower(p.first_name||' '||p.last_name),lower(v_query))>0)),$old_matching_total_count$) then
    raise exception 'Position filter fragment mismatch: matching_total_count';
  end if;
  v_definition:=replace(v_definition,
    $old_matching_total_count$          and scouting.player_has_squad(p.id,v_club_id,v_category)
          and (v_query is null or strpos(lower(p.first_name||' '||p.last_name),lower(v_query))>0)),$old_matching_total_count$,
    $new_matching_total_count$          and scouting.player_has_squad(p.id,v_club_id,v_category)
          and (v_position is null or case when v_position='__unknown__' then p.position is null else p.position=v_position end)
          and (v_query is null or strpos(lower(p.first_name||' '||p.last_name),lower(v_query))>0)),$new_matching_total_count$);

  if md5(v_definition)<>'f194c6d6710ed861f55c76b7f6a63bbf' then
    raise exception 'Unexpected proposed scouting RPC definition';
  end if;
  execute v_definition;
  if md5(pg_get_functiondef('public.scouting_api(text,text,jsonb)'::regprocedure))<>'f194c6d6710ed861f55c76b7f6a63bbf' then
    raise exception 'The applied scouting RPC does not match the reviewed position filter';
  end if;
  select jsonb_build_object('owner',p.proowner,'acl',p.proacl::text,
    'security_definer',p.prosecdef,'config',p.proconfig,'volatility',p.provolatile) into v_after_metadata
    from pg_proc p where p.oid='public.scouting_api(text,text,jsonb)'::regprocedure;
  if v_before_metadata is distinct from v_after_metadata then
    raise exception 'Position filter unexpectedly changed function privileges or execution settings';
  end if;
end;
$position_filter_patch$;
