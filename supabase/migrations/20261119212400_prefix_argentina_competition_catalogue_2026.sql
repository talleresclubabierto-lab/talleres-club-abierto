-- Prefix the existing Argentine choices so every competition is shown with its country.
update scouting.competitions
set name = case id
  when 'primera-division' then 'Argentina · Primera División — Liga Profesional de Fútbol'
  when 'primera-nacional' then 'Argentina · Primera Nacional'
  when 'federal-a' then 'Argentina · Torneo Federal A'
  when 'primera-b' then 'Argentina · Primera B'
  when 'primera-c' then 'Argentina · Primera C'
  when 'regional-amateur' then 'Argentina · Torneo Regional Federal Amateur'
  when 'promocional-amateur' then 'Argentina · Torneo Promocional Amateur'
  when 'liga-local' then 'Argentina · Liga local o regional'
  else name
end
where id in ('primera-division','primera-nacional','federal-a','primera-b','primera-c','regional-amateur','promocional-amateur','liga-local');
