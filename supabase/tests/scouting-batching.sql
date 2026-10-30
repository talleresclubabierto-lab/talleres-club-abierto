-- Run as the database test operator after the scouting dashboard and batching-lock migrations.
-- All identities, sessions, the QA policy and lots are transactional synthetic fixtures.
-- No network sender/activation function is invoked. Execute the ENTIRE file: ALWAYS ROLLBACK.
-- PostgreSQL sequences may advance despite rollback; no fixture row or policy persists.
-- The time branch uses an exact pg_temp clone with only its clock input changed;
-- public functions, historical lot timestamps and the real integration state stay untouched.
begin;
set local statement_timeout = '40s';
set local lock_timeout = '5s';

do $test$
declare
  v_owner bigint := 880000000000000 + floor(random()*1000000000)::bigint;
  v_admin bigint := v_owner+1;
  v_owner_token text := encode(extensions.gen_random_bytes(32),'hex');
  v_admin_token text := encode(extensions.gen_random_bytes(32),'hex');
  v_existing_lots uuid[];
  v_config jsonb;
  v_policy_version integer;
  v_id uuid;
  v_timer_id uuid;
  v_definition text;
  v_clock_definition text;
  v_payload jsonb;
  v_add_payload jsonb;
  v_validate_payload jsonb;
  v_status_payload jsonb;
  v_last_status_payload jsonb;
  v_result jsonb;
  v_proof jsonb;
  v_status text;
  v_lot uuid;
  v_events integer;
  v_audits bigint;
  v_lots bigint;
  v_before_lots bigint;
  v_pending bigint;
  v_hashes text[];
  v_row record;
begin
  -- Use the same lock as the real audit/batching functions, in the same order.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('talleres_digital_auditoria_chain'));
  if public.blockchain_envio_habilitado() is distinct from false then
    raise exception 'QA requires blockchain sending disabled; it will not change integration state';
  end if;
  select coalesce(jsonb_agg(to_jsonb(c) order by c.version),'[]'::jsonb)
    into v_config from public.configuracion_blockchain_publica c;
  select coalesce(array_agg(id),'{}'::uuid[]) into v_existing_lots from public.lotes_merkle_auditoria;

  -- Fail on an ID collision rather than reuse or overwrite a real member.
  insert into public.socios(numero_socio,nombre,fecha_alta,habilitado)
    values(v_owner,'QA_BATCH_SYNTHETIC_OWNER',current_date,true),
          (v_admin,'QA_BATCH_SYNTHETIC_ADMIN',current_date,true);
  insert into public.administradores(numero_socio,habilitado,es_principal) values(v_admin,true,false);
  perform public.crear_sesion_segura_interno(v_owner,v_owner_token,5,'scouting_batch_test','{}'::jsonb);
  perform public.crear_sesion_segura_interno(v_admin,v_admin_token,5,'scouting_batch_test','{}'::jsonb);

  -- Real versioning function, never UPDATE an immutable policy or disable triggers.
  perform public.crear_nueva_politica_anclaje(
    4,24,'[{"codigo":"QA_SCOUTING_BATCH","nombre":"QA cierre transaccional","habilitada":true}]'::jsonb,
    'QA scouting: four movements, rollback only','Regression synthetic fixtures; rollback required',v_admin);
  select version into v_policy_version from public.obtener_ultima_politica_anclaje_vigente();
  if not exists(select 1 from public.obtener_ultima_politica_anclaje_vigente() p
    where p.movimientos_por_anclaje=4 and p.max_horas_sin_anclaje=24
      and p.causas_extraordinarias @> '[{"codigo":"QA_SCOUTING_BATCH","habilitada":true}]'::jsonb) then
    raise exception 'QA policy was not installed transactionally';
  end if;

  -- Normalize any pre-existing tail and fixture audit rows inside this rollback only.
  -- Preparing a lot writes one technical audit event, deliberately left for the next lot.
  perform public.preparar_lote_extraordinario_auditoria('QA_SCOUTING_BATCH','QA baseline, rollback only');
  select count(*) into v_before_lots from public.lotes_merkle_auditoria;

  v_payload := jsonb_build_object('panel_context','socio','request_id',gen_random_uuid(),
    'club_id',null,'club_manual',jsonb_build_object('province','Córdoba','city','Localidad QA',
      'name','QA_BATCH_CLUB_'||v_owner,'league','Liga QA sintética'),
    'competition_id','liga-local','category','Sub-17','player_id',null,
    'player',jsonb_build_object('first_name','QA_BATCH_PLAYER','last_name','QA_BATCH_LASTNAME',
      'position','Lateral','sector','derecha','age_at_recommendation',16),
    'reason','QA_BATCH_REASON: referencia deportiva sintética para probar lotes pendientes',
    'observation','QA_BATCH_OBSERVATION','video_url',null,'transfermarkt_url',null);
  perform set_config('app.actor_socio',v_owner::text,true);
  v_result := public.scouting_api(v_owner_token,'create',v_payload);
  v_id := (v_result#>>'{recommendation,id}')::uuid;
  if v_id is null then raise exception 'Synthetic recommendation was not created'; end if;
  v_add_payload := jsonb_build_object('id',v_id,'request_id',gen_random_uuid(),
    'message','QA_BATCH_INFO: información pública adicional sintética');
  perform public.scouting_api(v_owner_token,'add_info',v_add_payload);

  foreach v_status in array array['contactado','visitado','convocado_a_prueba','prueba_realizada','no_avanza'] loop
    v_status_payload := jsonb_build_object('id',v_id,'request_id',gen_random_uuid(),
      'status',v_status,'message','QA_BATCH_STATUS: motivo sintético para '||v_status);
    perform public.scouting_api(v_admin_token,'admin_update',v_status_payload);
    v_last_status_payload := v_status_payload;
  end loop;
  v_validate_payload := jsonb_build_object('id',v_id,'request_id',gen_random_uuid(),
    'message','QA_BATCH_VALIDATION: club sintético validado para la regresión');
  perform public.scouting_api(v_admin_token,'admin_validate_club',v_validate_payload);
  if current_setting('app.actor_socio',true) is distinct from v_owner::text then
    raise exception 'Scouting audit did not restore the caller actor context';
  end if;
  select count(*) into v_events from scouting.events where recommendation_id=v_id;
  if v_events<>8 or exists(
    select 1 from (values ('created','recibida'),('information_added','recibida'),
      ('status_updated','contactado'),('status_updated','visitado'),
      ('status_updated','convocado_a_prueba'),('status_updated','prueba_realizada'),
      ('status_updated','no_avanza'),('club_validated','no_avanza')) expected(kind,status)
    where not exists(select 1 from scouting.events e where e.recommendation_id=v_id
      and e.event_type=expected.kind and e.status=expected.status)) then
    raise exception 'Expected eight scouting actions were not recorded';
  end if;
  if not exists(select 1 from scouting.club_validations where recommendation_id=v_id) then
    raise exception 'Synthetic club validation is missing';
  end if;

  -- The ordinary insert trigger must already have closed at least one count-based lot.
  if (select count(*) from public.lotes_merkle_auditoria)<=v_before_lots or not exists(
    select 1 from public.lotes_merkle_auditoria l join scouting.events e
      on e.audit_event_id between l.primer_evento_id and l.ultimo_evento_id
    where e.recommendation_id=v_id and l.tipo='ordinario' and l.politica_version=v_policy_version
      and l.cantidad_eventos=4 and l.metadata->>'disparador'='cantidad_movimientos') then
    raise exception 'Count threshold did not automatically prepare a scouting lot';
  end if;

  -- Below threshold: ordinary evaluation must do nothing; the allowed QA cause closes the tail.
  select count(*) into v_pending from public.auditoria_administrativa
    where id>public.ultimo_evento_cubierto_por_lote_auditoria();
  if v_pending<1 or v_pending>=4 then raise exception 'Expected a nonempty subthreshold tail, got %',v_pending; end if;
  if public.preparar_lote_ordinario_si_corresponde() is not null then
    raise exception 'Ordinary evaluation closed a subthreshold, freshly prepared tail';
  end if;
  v_lot := public.preparar_lote_extraordinario_auditoria('QA_SCOUTING_BATCH','QA final scouting tail, rollback only');
  if v_lot is null or not exists(select 1 from public.lotes_merkle_auditoria
    where id=v_lot and tipo='extraordinario' and politica_version=v_policy_version
      and causa_extraordinaria='QA_SCOUTING_BATCH' and cantidad_eventos=v_pending) then
    raise exception 'Authorized extraordinary close did not cover the final tail';
  end if;

  -- Exercise the real time-branch body without changing the immutable prepared_at
  -- of any real lot, wall clock, policy hours, or public function definition.
  -- Fail if the reviewed header/clock fragment is absent, duplicated or drifts.
  v_definition := pg_get_functiondef('public.preparar_lote_ordinario_si_corresponde()'::regprocedure);
  if length(v_definition)-length(replace(v_definition,'<= now() - make_interval',''))
      <>length('<= now() - make_interval')
    or length(v_definition)-length(replace(v_definition,
      'CREATE OR REPLACE FUNCTION public.preparar_lote_ordinario_si_corresponde()',''))
      <>length('CREATE OR REPLACE FUNCTION public.preparar_lote_ordinario_si_corresponde()') then
    raise exception 'Live function drift: cannot safely create the clock-only QA clone';
  end if;
  v_clock_definition := replace(replace(v_definition,
    'CREATE OR REPLACE FUNCTION public.preparar_lote_ordinario_si_corresponde()',
    'CREATE OR REPLACE FUNCTION pg_temp.scouting_prepare_at_test_time(p_now timestamp with time zone)'),
    '<= now() - make_interval','<= p_now - make_interval');
  if replace(replace(v_clock_definition,
    'CREATE OR REPLACE FUNCTION pg_temp.scouting_prepare_at_test_time(p_now timestamp with time zone)',
    'CREATE OR REPLACE FUNCTION public.preparar_lote_ordinario_si_corresponde()'),
    '<= p_now - make_interval','<= now() - make_interval') is distinct from v_definition then
    raise exception 'Time clone differs beyond its header and clock';
  end if;
  execute v_clock_definition;
  v_result := public.scouting_api(v_owner_token,'create',
    v_payload||jsonb_build_object('request_id',gen_random_uuid()));
  v_timer_id := (v_result#>>'{recommendation,id}')::uuid;
  if v_timer_id is null or v_timer_id=v_id then raise exception 'Time fixture was not independently created'; end if;
  select count(*) into v_pending from public.auditoria_administrativa
    where id>public.ultimo_evento_cubierto_por_lote_auditoria();
  if v_pending<1 or v_pending>=4 then raise exception 'Time fixture is not below the count threshold'; end if;
  if public.preparar_lote_ordinario_si_corresponde() is not null then
    raise exception 'Real clock unexpectedly closed the fresh time fixture';
  end if;
  v_lot := pg_temp.scouting_prepare_at_test_time(clock_timestamp()+interval '25 hours');
  if v_lot is null or not exists(select 1 from public.lotes_merkle_auditoria l
    join scouting.events e on e.audit_event_id between l.primer_evento_id and l.ultimo_evento_id
    where l.id=v_lot and e.recommendation_id=v_timer_id and l.tipo='ordinario'
      and l.politica_version=v_policy_version and l.cantidad_eventos=v_pending
      and l.metadata->>'disparador'='tiempo_maximo') then
    raise exception 'The clock-only clone failed to close a subthreshold scouting event by time';
  end if;
  if pg_get_functiondef('public.preparar_lote_ordinario_si_corresponde()'::regprocedure)
      is distinct from v_definition then raise exception 'QA changed the public ordinary batching function'; end if;

  -- Anti-joins inspect actual membership, not only MAX(ultimo_evento_id).
  if exists(select 1 from scouting.events e left join public.auditoria_administrativa a on a.id=e.audit_event_id
    where e.recommendation_id in (v_id,v_timer_id) and a.id is null) then
    raise exception 'A scouting action has no corresponding audit event';
  end if;
  if exists(select 1 from scouting.events e where e.recommendation_id in (v_id,v_timer_id) and not exists(
    select 1 from public.lotes_merkle_auditoria l where l.estado in ('preparado','enviado','anclado')
      and e.audit_event_id between l.primer_evento_id and l.ultimo_evento_id)) then
    raise exception 'A scouting audit event remains outside all pending/confirmed lots';
  end if;
  if exists(select 1 from scouting.events e join public.lotes_merkle_auditoria l
    on e.audit_event_id between l.primer_evento_id and l.ultimo_evento_id
    where e.recommendation_id in (v_id,v_timer_id) group by e.id having count(*)<>1) then
    raise exception 'A synthetic scouting action is covered by overlapping lots';
  end if;

  -- Public audit contains only salted commitments, not the member/player/message/nonce.
  if exists(select 1 from scouting.events e join public.auditoria_administrativa a on a.id=e.audit_event_id
    where e.recommendation_id in (v_id,v_timer_id) and (a.actor_numero_socio is not null or a.actor_nombre is not null
      or a.actor_rol is not null or a.origen is distinct from 'scouting_api'
      or a.entidad is distinct from 'scouting_commitment' or a.entidad_id is distinct from e.id::text
      or a.datos_anteriores is not null
      or a.datos_nuevos is distinct from jsonb_build_object('schema','scouting-event-v2','commitment_sha256',e.event_hash)
      or to_jsonb(a)::text like '%QA_BATCH_%' or position(e.private_nonce in to_jsonb(a)::text)>0)) then
    raise exception 'Scouting audit leaked plaintext identity/content or lost its commitment';
  end if;

  -- Recompute every new lot from actual ordered audit leaves, including setup lots.
  for v_row in select * from public.lotes_merkle_auditoria where not(id=any(v_existing_lots)) loop
    select array_agg(a.event_hash order by a.id) into v_hashes from public.auditoria_administrativa a
      where a.id between v_row.primer_evento_id and v_row.ultimo_evento_id;
    if cardinality(v_hashes) is distinct from v_row.cantidad_eventos
      or public.merkle_root_sha256_sorted_pairs_v1(v_hashes) is distinct from v_row.raiz_merkle_sha256
      or v_hashes[1] is distinct from v_row.primer_event_hash
      or v_hashes[cardinality(v_hashes)] is distinct from v_row.ultimo_event_hash then
      raise exception 'Lot % has inconsistent leaves/count/root',v_row.id;
    end if;
    if v_row.estado is distinct from 'preparado' or v_row.transaccion_hash is not null
      or v_row.bloque_numero is not null or v_row.anclado_en is not null then
      raise exception 'Disabled integration produced an alleged send/anchor for lot %',v_row.id;
    end if;
  end loop;
  for v_row in select * from scouting.events where recommendation_id in (v_id,v_timer_id) loop
    v_result := public.scouting_api(v_owner_token,'event_proof',jsonb_build_object('event_id',v_row.id));
    v_proof := v_result->'proof';
    if v_result->>'event_id' is distinct from v_row.id::text
      or v_proof->>'status' is distinct from 'preparada'
      or (v_proof->>'merkle_valid')::boolean is distinct from true
      or v_proof->>'audit_event_id' is distinct from v_row.audit_event_id::text
      or v_proof->>'commitment_hash' is distinct from v_row.event_hash
      or v_proof->>'transaction_hash' is not null then
      raise exception 'Event % lacks a valid prepared proof without a transaction',v_row.id;
    end if;
  end loop;

  -- Replayed user operations and repeated ordinary ticks add neither events nor lots.
  -- Do not assert idempotency of forced close: it would close the previous close's own audit event.
  select count(*) into v_audits from public.auditoria_administrativa;
  select count(*) into v_lots from public.lotes_merkle_auditoria;
  perform public.scouting_api(v_owner_token,'create',v_payload);
  perform public.scouting_api(v_owner_token,'add_info',v_add_payload);
  perform public.scouting_api(v_admin_token,'admin_update',v_last_status_payload);
  perform public.scouting_api(v_admin_token,'admin_validate_club',v_validate_payload);
  if public.preparar_lote_ordinario_si_corresponde() is not null
    or public.preparar_lote_ordinario_si_corresponde() is not null
    or (select count(*) from public.lotes_merkle_auditoria)<>v_lots
    or (select count(*) from public.auditoria_administrativa)<>v_audits
    or (select count(*) from scouting.events where recommendation_id=v_id)<>v_events then
    raise exception 'An idempotent replay or an ordinary tick duplicated events/lots';
  end if;
  if public.blockchain_envio_habilitado() is distinct from false
    or (select coalesce(jsonb_agg(to_jsonb(c) order by c.version),'[]'::jsonb)
      from public.configuracion_blockchain_publica c) is distinct from v_config
    or exists(select 1 from public.anclajes_lotes_blockchain b join public.lotes_merkle_auditoria l
      on l.id=b.lote_id where b.tipo_lote='auditoria' and not(l.id=any(v_existing_lots))) then
    raise exception 'QA changed blockchain integration or created a confirmed anchor';
  end if;
  raise notice 'PASS scouting batching: eight actions + time fixture audited, automatic count + clock-only time branch + final tail covered, roots/proofs valid, no plaintext audit, idempotent, sending disabled. ROLLBACK follows.';
end;
$test$;

rollback;
