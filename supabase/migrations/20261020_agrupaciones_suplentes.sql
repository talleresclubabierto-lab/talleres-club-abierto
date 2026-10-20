-- Carga 2026-10-20: bloques de suplentes cotejados con distribucion electoral 2025.
-- Adelante Talleres: suplentes 1-36; Talleres Somos Todos: suplentes 37-40.
-- Verificar identidad nominal con actas oficiales antes de futuras modificaciones.
update public.estructura_asambleistas
set agrupacion_origen = case when posicion between 1 and 36 then 'Adelante Talleres' when posicion between 37 and 40 then 'Talleres Somos Todos' end,
    actualizado_en = now()
where condicion = 'suplente' and posicion between 1 and 40
  and agrupacion_origen is null;
