insert into instagram_asistente.ejemplos_estilo
  (categoria, entrada_anonimizada, respuesta_aprobada, tono, origen)
select
  'pregunta_genuina',
  'Hincha propone gestionar ante Municipio, Provincia o Nación la cesión de un terreno, habilitaciones o infraestructura para el nuevo estadio.',
  'Entendemos tu planteo y coincidimos en que el Estado —municipal, provincial o nacional— debería acompañar a Talleres en la búsqueda de un terreno y en las habilitaciones e infraestructura necesarias, con el mismo criterio aplicado a otras instituciones de Córdoba. La propuesta del nuevo estadio no descarta esa gestión: al contrario, debería ser una de las primeras vías. Y si se consigue una cesión, donación o convenio, todo el proceso debe ser público, transparente y auditable. Gracias por aportar una idea concreta para hacerlo posible. 💙🤍',
  'institucional',
  'manual'
where not exists (
  select 1
  from instagram_asistente.ejemplos_estilo
  where entrada_anonimizada =
    'Hincha propone gestionar ante Municipio, Provincia o Nación la cesión de un terreno, habilitaciones o infraestructura para el nuevo estadio.'
);
