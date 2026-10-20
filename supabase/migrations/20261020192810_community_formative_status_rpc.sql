create or replace function public.community_formative_status()
returns jsonb
language sql
stable
security definer
set search_path = pg_catalog
as $$
  select jsonb_build_object(
    'module', 'comunidad_formativa',
    'phase', 'foundation_created',
    'intake_enabled', false,
    'case_submission_enabled', false,
    'blockchain_anchor_enabled', false
  );
$$;
revoke all on function public.community_formative_status() from public, anon, authenticated;
grant execute on function public.community_formative_status() to service_role;
