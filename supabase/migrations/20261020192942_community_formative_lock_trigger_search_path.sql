create or replace function comunidad_formativa.bloquear_mutacion_append_only()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  raise exception 'Registro inmutable: agregue una nueva actuación';
end;
$$;
revoke all on function comunidad_formativa.bloquear_mutacion_append_only() from public, anon, authenticated;
