-- Run only after 20261029202902_scouting_colaborativo_paredes_de_cristal.sql exists, as a database test operator.
-- Synthetic fixtures are created inside this transaction. No existing member,
-- administrator or session is queried or used as an identity. ALWAYS ROLLBACK.
begin;
set local statement_timeout='40s';
set local lock_timeout='5s';

do $test$
declare
  v_owner bigint:=880000000000000+(floor(random()*1000000000))::bigint;
  v_other bigint:=v_owner+1;
  v_admin bigint:=v_owner+2;
  v_token_owner text:=encode(extensions.gen_random_bytes(32),'hex');
  v_token_other text:=encode(extensions.gen_random_bytes(32),'hex');
  v_token_admin text:=encode(extensions.gen_random_bytes(32),'hex');
  v_payload jsonb;
  v_result jsonb;
  v_detail jsonb;
  v_replayed jsonb;
  v_id uuid;
  v_request uuid:=gen_random_uuid();
  v_admin_request uuid:=gen_random_uuid();
  v_initial_snapshot jsonb;
  v_count integer;
  v_audit_count integer;
  v_hash text;
  v_nonce text;
  v_row record;
  v_lot uuid;
  v_proof jsonb;
  v_catalogue_id uuid;
  v_player_id uuid;
  v_batch_id uuid;
begin
  -- Fail on even an improbable ID collision; do not reuse or overwrite any identity.
  insert into public.socios(numero_socio,nombre,fecha_alta,habilitado)
  values(v_owner,'SCOUTING SYNTHETIC OWNER',current_date,true),
        (v_other,'SCOUTING SYNTHETIC OTHER',current_date,true),
        (v_admin,'SCOUTING SYNTHETIC ADMIN',current_date,true);
  insert into public.administradores(numero_socio,habilitado,es_principal)
    values(v_admin,true,false);
  perform public.crear_sesion_segura_interno(v_owner,v_token_owner,5,'scouting_test','{}'::jsonb);
  perform public.crear_sesion_segura_interno(v_other,v_token_other,5,'scouting_test','{}'::jsonb);
  perform public.crear_sesion_segura_interno(v_admin,v_token_admin,5,'scouting_test','{}'::jsonb);

  v_result:=public.scouting_api(v_token_owner,'bootstrap','{}'::jsonb);
  if v_result#>>'{actor,role}' is distinct from 'socio' or (v_result#>>'{actor,numero_socio}')::bigint<>v_owner
    then raise exception 'bootstrap owner assertion failed'; end if;
  if jsonb_array_length(v_result->'provinces')<>24 or jsonb_array_length(v_result->'positions')<>9
    then raise exception 'catalogue selectors assertion failed'; end if;
  if v_result#>>'{catalogue,provider_status}' is distinct from 'pending_authorization'
    then raise exception 'provider status must remain honest'; end if;
  v_result:=public.scouting_api(v_token_admin,'bootstrap','{}'::jsonb);
  if v_result#>>'{actor,role}' is distinct from 'admin' then raise exception 'admin role assertion failed';end if;

  begin
    perform public.scouting_api(repeat('x',64),'bootstrap','{}'::jsonb);
    raise exception 'invalid session was accepted';
  exception when sqlstate 'PT401' then null; end;
  begin
    perform public.scouting_api(v_token_owner,'admin_list','{}'::jsonb);
    raise exception 'non-admin accessed admin list';
  exception when sqlstate 'PT403' then null; end;
  begin
    perform public.scouting_api(v_token_owner,'detail','{"id":"not-a-uuid"}'::jsonb);
    raise exception 'malformed UUID was accepted';
  exception when sqlstate 'PT422' then null; end;

  v_payload:=jsonb_build_object('request_id',v_request,'club_id',null,
    'club_manual',jsonb_build_object('province','Córdoba','city','Localidad de prueba',
      'name','SCOUTING TEST CLUB '||v_owner::text,'league','Liga de prueba'),
    'competition_id','liga-local','category','Sub-17','player_id',null,
    'player',jsonb_build_object('first_name','TEST_PLAYER_NAME','last_name','TEST_PLAYER_LASTNAME','position','Lateral','sector','derecha'),
    'reason','TEST_PRIVATE_REASON: referencia deportiva ficticia usada únicamente en pruebas',
    'observation','TEST_PRIVATE_OBSERVATION','video_url','https://www.youtube.com/watch?v=synthetic',
    'transfermarkt_url','https://www.transfermarkt.com/synthetic/profil/spieler/123');
  -- Ensure actor context is suppressed, and restored, while the shared audit runs.
  perform set_config('app.actor_socio',v_owner::text,true);
  v_result:=public.scouting_api(v_token_owner,'create',v_payload);
  v_id:=(v_result#>>'{recommendation,id}')::uuid;
  if current_setting('app.actor_socio',true)<>v_owner::text then raise exception 'audit context not restored'; end if;
  if v_result#>>'{recommendation,status}' is distinct from 'recibida' then raise exception 'create status incorrect';end if;
  select snapshot into v_initial_snapshot from scouting.recommendations where id=v_id;
  select count(*) into v_count from scouting.events where recommendation_id=v_id;
  if v_count<>1 then raise exception 'create must have exactly one event';end if;

  v_replayed:=public.scouting_api(v_token_owner,'create',v_payload);
  if v_replayed#>>'{recommendation,id}'<>v_id::text or v_replayed->>'replayed'<>'true'
    then raise exception 'idempotent create failed';end if;
  if (select count(*) from scouting.events where recommendation_id=v_id)<>1 then raise exception 'replay added event';end if;
  begin
    perform public.scouting_api(v_token_owner,'create',v_payload||'{"reason":"Un contenido diferente que no debe ser aceptado"}'::jsonb);
    raise exception 'request UUID reused with altered payload';
  exception when sqlstate 'PT409' then null;end;

  v_detail:=public.scouting_api(v_token_other,'detail',jsonb_build_object('id',v_id));
  if v_detail#>>'{recommendation,id}' is distinct from v_id::text
    or v_detail#>>'{recommendation,author,name}' is distinct from 'SCOUTING SYNTHETIC OWNER'
    or (v_detail#>>'{recommendation,can_add_info}')::boolean is distinct from false
    then raise exception 'shared member detail/author/ownership flags failed';end if;
  begin
    perform public.scouting_api(v_token_other,'add_info',jsonb_build_object('id',v_id,'request_id',gen_random_uuid(),'message','No es mi aporte'));
    raise exception 'another member changed private recommendation';
  exception when sqlstate 'PT404' then null;end;
  v_result:=public.scouting_api(v_token_other,'mine','{}'::jsonb);
  if jsonb_array_length(v_result->'items')<>0 then raise exception 'mine leaked other member rows';end if;
  v_result:=public.scouting_api(v_token_other,'feed',jsonb_build_object('query','TEST_PLAYER_NAME'));
  if not exists(select 1 from jsonb_array_elements(v_result->'items') x where x->>'id'=v_id::text)
    then raise exception 'shared feed omitted another member recommendation';end if;
  v_result:=public.scouting_api(v_token_other,'feed','{"mine_only":true}'::jsonb);
  if jsonb_array_length(v_result->'items')<>0 then raise exception 'mine_only filter returned another author';end if;

  perform public.scouting_api(v_token_owner,'add_info',jsonb_build_object('id',v_id,'request_id',gen_random_uuid(),'message','Una observación adicional ficticia'));
  v_result:=public.scouting_api(v_token_admin,'admin_update',jsonb_build_object(
    'id',v_id,'request_id',v_admin_request,'status','en_revision','message','TEST_ADMIN_PUBLIC_FEEDBACK: El aporte está en revisión'));
  if v_result#>>'{recommendation,status}'<>'en_revision' then raise exception 'admin update failed';end if;
  v_detail:=public.scouting_api(v_token_other,'detail',jsonb_build_object('id',v_id));
  if v_detail::text not like '%TEST_ADMIN_PUBLIC_FEEDBACK%' or v_detail::text not like '%SCOUTING SYNTHETIC ADMIN%'
    then raise exception 'administrative feedback or author not visible to members';end if;
  if v_detail::text like '%internal_note%' or v_detail::text like '%owner_numero_socio%'
    or v_detail::text like '%private_nonce%' or v_detail::text like '%token_hash%'
    or v_detail::text like '%datos_extra%' or v_detail::text like '%"dni"%'
    then raise exception 'member response exposed private technical or identity fields';end if;
  if exists(select 1 from jsonb_array_elements(v_detail->'events') x where x ? 'actor_numero_socio')
    then raise exception 'events leaked actor identity';end if;
  v_detail:=public.scouting_api(v_token_admin,'detail',jsonb_build_object('id',v_id));
  if v_detail::text like '%internal_note%' then raise exception 'private-note concept remains in detail';end if;
  begin
    perform public.scouting_api(v_token_admin,'admin_update',jsonb_build_object('id',v_id,'request_id',gen_random_uuid(),
      'status','en_revision','message','Devolución pública','internal_note','No se permite contenido oculto'));
    raise exception 'hidden note was accepted';
  exception when sqlstate 'PT422' then null;end;

  -- Append-only protection and preservation of the original club/player/category.
  begin
    update scouting.events set member_message='changed' where recommendation_id=v_id;
    raise exception 'append-only event was editable';
  exception when insufficient_privilege then null;end;
  begin
    update scouting.recommendations set snapshot=snapshot||'{"category":"Primera"}'::jsonb where id=v_id;
    raise exception 'original snapshot was editable';
  exception when insufficient_privilege then null;end;
  if (select snapshot from scouting.recommendations where id=v_id) is distinct from v_initial_snapshot
    then raise exception 'original snapshot changed';end if;

  -- General audit contains commitments only, and the number of private/public
  -- events matches for this recommendation. The isolated test identities can
  -- create unrelated fixture audit rows; only scouting events are inspected here.
  select count(*) into v_audit_count from scouting.events e join public.auditoria_administrativa a on a.id=e.audit_event_id
    where e.recommendation_id=v_id;
  if v_audit_count<>(select count(*) from scouting.events where recommendation_id=v_id) then raise exception 'audit coupling failed';end if;
  if exists(select 1 from scouting.events e join public.auditoria_administrativa a on a.id=e.audit_event_id
    where e.recommendation_id=v_id and (a.actor_numero_socio is not null or a.actor_nombre is not null or a.actor_rol is not null
      or to_jsonb(a)::text like '%TEST_PLAYER%' or to_jsonb(a)::text like '%TEST_PRIVATE%'
      or to_jsonb(a)::text like '%TEST_ADMIN_PUBLIC%' or to_jsonb(a)::text like '%SCOUTING SYNTHETIC%'))
    then raise exception 'shared audit exposed identity or private content';end if;
  for v_row in select * from scouting.events where recommendation_id=v_id order by sequence_no loop
    v_hash:=encode(extensions.digest(convert_to(jsonb_build_object(
      'schema','scouting-event-v1','id',v_row.id,'recommendation_id',v_row.recommendation_id,
      'sequence',v_row.sequence_no,'actor',v_row.actor_numero_socio,'role',v_row.actor_role,
      'type',v_row.event_type,'status',v_row.status,'message',v_row.member_message,
      'created_at',to_char(v_row.created_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),'original_commitment',(select commitment_hash from scouting.recommendations where id=v_id),
      'previous',v_row.prev_hash,'nonce',v_row.private_nonce)::text,'UTF8'),'sha256'),'hex');
    if v_hash<>v_row.event_hash then raise exception 'event commitment cannot be recomputed';end if;
  end loop;

  -- Reuse the real Merkle functions, but this preparatory batch is rolled back.
  select public.preparar_lote_merkle_auditoria('SCOUTING-TEST-'||v_id::text,'extraordinario',
    min(e.audit_event_id),max(e.audit_event_id),null,'scouting_test','{}'::jsonb)
    into v_lot from scouting.events e where recommendation_id=v_id;
  v_proof:=scouting.proof_json(v_id);
  if v_proof->>'status' is distinct from 'preparada' or (v_proof->>'merkle_valid')::boolean is distinct from true
    then raise exception 'Merkle proof verification failed';end if;
  if v_proof->>'transaction_hash' is not null then raise exception 'unconfirmed test proof claimed a transaction';end if;

  -- Validating a manual club adds/reuses an entry and preserves the original snapshot.
  v_result:=public.scouting_api(v_token_admin,'admin_validate_club',jsonb_build_object('id',v_id,'request_id',gen_random_uuid(),'message','Referencia de prueba validada por administrador'));
  select club_id into v_catalogue_id from scouting.club_validations where recommendation_id=v_id;
  if v_catalogue_id is null then raise exception 'club validation did not link catalogue';end if;
  if (select snapshot from scouting.recommendations where id=v_id) is distinct from v_initial_snapshot
    then raise exception 'club validation overwrote historical snapshot';end if;
  begin
    perform public.scouting_api(v_token_owner,'admin_validate_club',jsonb_build_object('id',v_id,'request_id',gen_random_uuid(),'message','No autorizado'));
    raise exception 'non-admin validated a club';
  exception when sqlstate 'PT403' then null;end;

  -- A closed recommendation rejects further member additions; reopening requires an admin action.
  perform public.scouting_api(v_token_admin,'admin_update',jsonb_build_object('id',v_id,'request_id',gen_random_uuid(),'status','cerrada','message','Cierre de prueba con motivo'));
  begin
    perform public.scouting_api(v_token_owner,'add_info',jsonb_build_object('id',v_id,'request_id',gen_random_uuid(),'message','No debería guardarse'));
    raise exception 'closed recommendation accepted member update';
  exception when sqlstate 'PT409' then null;end;

  -- URLs cannot become SSRF input or arbitrary clickable schemes.
  begin
    perform public.scouting_api(v_token_owner,'create',v_payload||jsonb_build_object('request_id',gen_random_uuid(),'video_url','javascript:alert(1)'));
    raise exception 'javascript URL accepted';
  exception when sqlstate 'PT422' then null;end;
  begin
    perform public.scouting_api(v_token_owner,'create',v_payload||jsonb_build_object('request_id',gen_random_uuid(),'transfermarkt_url','https://transfermarkt.com.attacker.example/player/profil/spieler/123'));
    raise exception 'lookalike Transfermarkt host accepted';
  exception when sqlstate 'PT422' then null;end;

  -- No actor role can be forged through user-editable metadata.
  update public.socios set datos_extra=jsonb_build_object('role','admin','is_admin',true) where numero_socio=v_owner;
  v_result:=public.scouting_api(v_token_owner,'bootstrap','{}'::jsonb);
  if v_result#>>'{actor,role}'<>'socio' then raise exception 'user metadata escalated role';end if;
  update public.administradores set habilitado=false where numero_socio=v_admin;
  begin
    perform public.scouting_api(v_token_admin,'admin_list','{}'::jsonb);
    raise exception 'disabled administrator retained access';
  exception when sqlstate 'PT403' then null;end;
  update public.socios set habilitado=false where numero_socio=v_owner;
  begin
    perform public.scouting_api(v_token_owner,'mine','{}'::jsonb);
    raise exception 'disabled member retained access';
  exception when sqlstate 'PT401' then null;end;

  if has_function_privilege('anon','public.scouting_api(text,text,jsonb)','EXECUTE')
    or has_function_privilege('authenticated','public.scouting_api(text,text,jsonb)','EXECUTE')
    then raise exception 'public role can call restricted RPC';end if;
  if not has_function_privilege('service_role','public.scouting_api(text,text,jsonb)','EXECUTE')
    then raise exception 'service role cannot call RPC';end if;
  if exists(select 1 from pg_tables where schemaname='scouting' and not rowsecurity)
    then raise exception 'RLS missing on scouting table';end if;
  raise notice 'Scouting backend contract: synthetic fixture tests passed; transaction will roll back';
end;
$test$;

rollback;
