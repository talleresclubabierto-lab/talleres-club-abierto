-- Estructura institucional: campos de origen electoral y LinkedIn validado.
-- Aplicado en Supabase el 20-10-2026; no ejecutar dos veces sin revisar el estado.
alter table public.estructura_asambleistas add column if not exists agrupacion_origen text;
alter table public.estructura_asambleistas add column if not exists linkedin_url text;
alter table public.estructura_asambleistas add column if not exists linkedin_validado boolean not null default false;
alter table public.estructura_personas add column if not exists linkedin_validado boolean not null default false;
-- Los registros historicos sin fuente conservan NULL hasta validacion documental.
-- La obligatoriedad de nuevas altas debe validarse en API y formulario de administracion.
