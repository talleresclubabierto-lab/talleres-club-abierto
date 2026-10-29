-- Initial Argentine club references from the official sources recorded below.
-- Partial coverage: first men's team competition in 2026. No player/provider import.
do $seed$
declare
  v_seed jsonb := $catalog${
  "metadata": {
    "schema_version": 1,
    "coverage": "Catálogo inicial verificado; no exhaustivo",
    "provenance": "Fuentes oficiales de AFA, Liga Profesional de Fútbol, clubes y ligas; sin Transfermarkt",
    "country": "Argentina",
    "season": "2026",
    "verified_at": "2026-10-29T20:21:17Z",
    "club_count": 11,
    "competition_scope": "La competencia indicada corresponde al primer equipo masculino en la temporada 2026. No describe todas las competencias ni todas las categorías de cada institución.",
    "league_scope": "Liga local o regional explícitamente verificada. Vacío significa dato no verificado, no ausencia de afiliación.",
    "division_scope": "No se infiere un nivel numérico ni una categoría juvenil. El valor null significa que el dato no se ha incorporado a esta semilla.",
    "geography_scope": "La provincia y la ciudad corresponden a la sede o identificación institucional del club, no necesariamente al estadio donde juega cada partido.",
    "api_mapping": "competition_slug utiliza los identificadores acordados con el backend; mapear a competition_id al importar. verified_at puede mapearse a checked_at.",
    "players_included": false,
    "transfermarkt_imported": false
  },
  "clubs": [
    {
      "source_key": "ar-cordoba-talleres",
      "name": "Club Atlético Talleres",
      "province": "Córdoba",
      "city": "Córdoba",
      "league": "",
      "competition_slug": "primera-division",
      "competition_name": "Primera División — Liga Profesional de Fútbol",
      "season": "2026",
      "division": null,
      "source_urls": [
        "https://www.ligaprofesional.ar/clubes/talleres/",
        "https://tienda.clubtalleres.com.ar/sede-social-html/",
        "https://www.ligaprofesional.ar/notas/primera/2026/09/07/agenda-de-la-fecha-8-a-la-11/"
      ],
      "verified_at": "2026-10-29T20:21:17Z"
    },
    {
      "source_key": "ar-cordoba-belgrano",
      "name": "Club Atlético Belgrano",
      "province": "Córdoba",
      "city": "Córdoba",
      "league": "",
      "competition_slug": "primera-division",
      "competition_name": "Primera División — Liga Profesional de Fútbol",
      "season": "2026",
      "division": null,
      "source_urls": [
        "https://www.ligaprofesional.ar/clubes/belgrano/",
        "https://belgrano.com.ar/estadio/",
        "https://www.ligaprofesional.ar/notas/primera/2026/09/07/agenda-de-la-fecha-8-a-la-11/"
      ],
      "verified_at": "2026-10-29T20:21:17Z"
    },
    {
      "source_key": "ar-cordoba-instituto",
      "name": "Instituto Atlético Central Córdoba",
      "province": "Córdoba",
      "city": "Córdoba",
      "league": "",
      "competition_slug": "primera-division",
      "competition_name": "Primera División — Liga Profesional de Fútbol",
      "season": "2026",
      "division": null,
      "source_urls": [
        "https://institutoacc.com.ar/index.php/contacto-y-ubicacion/",
        "https://institutoacc.com.ar/index.php/convocatoria-a-asamblea-general-ordinaria-2026/",
        "https://www.ligaprofesional.ar/notas/primera/2026/09/07/agenda-de-la-fecha-8-a-la-11/"
      ],
      "verified_at": "2026-10-29T20:21:17Z"
    },
    {
      "source_key": "ar-cordoba-racing",
      "name": "Club Atlético Racing de Córdoba",
      "province": "Córdoba",
      "city": "Córdoba",
      "league": "",
      "competition_slug": "primera-nacional",
      "competition_name": "Primera Nacional",
      "season": "2026",
      "division": null,
      "source_urls": [
        "https://racingcba.com.ar/bienvenido/complejo-racing/",
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "verified_at": "2026-10-29T20:21:17Z"
    },
    {
      "source_key": "ar-cordoba-estudiantes-rio-cuarto",
      "name": "Asociación Atlética Estudiantes de Río Cuarto",
      "province": "Córdoba",
      "city": "Río Cuarto",
      "league": "",
      "competition_slug": "primera-division",
      "competition_name": "Primera División — Liga Profesional de Fútbol",
      "season": "2026",
      "division": null,
      "source_urls": [
        "https://www.aaestudiantesriocuarto.com/",
        "https://www.lpf.org.ar/clubes/estudiantes-de-rio-cuarto/",
        "https://www.ligaprofesional.ar/notas/primera/2026/09/07/agenda-de-la-fecha-8-a-la-11/"
      ],
      "verified_at": "2026-10-29T20:21:17Z"
    },
    {
      "source_key": "ar-cordoba-sportivo-belgrano-san-francisco",
      "name": "Club Sportivo Belgrano",
      "province": "Córdoba",
      "city": "San Francisco",
      "league": "",
      "competition_slug": "federal-a",
      "competition_name": "Torneo Federal A",
      "season": "2026",
      "division": null,
      "source_urls": [
        "https://sportivobelgrano.com.ar/contacto/",
        "https://www.afa.com.ar/es/posts/federal-a-hoy-tucuman-central-escobar-fc",
        "https://www.afa.com.ar/es/posts/federal-a-hoy-circulo-deportivo-costa-brava"
      ],
      "verified_at": "2026-10-29T20:21:17Z"
    },
    {
      "source_key": "ar-cordoba-argentino-monte-maiz",
      "name": "Club Deportivo Argentino de Monte Maíz",
      "province": "Córdoba",
      "city": "Monte Maíz",
      "league": "Liga Regional de Fútbol Dr. Adrián Beccar Varela",
      "competition_slug": "federal-a",
      "competition_name": "Torneo Federal A",
      "season": "2026",
      "division": null,
      "source_urls": [
        "https://argentinocrece.com.ar/Contacto",
        "https://labeccar.com.ar/noticias/cumpleanos-argentino-de-monte-maiz/",
        "https://labeccar.com.ar/noticias/federal-a-argentino-de-monte-maiz-volvio-al-trabajo/",
        "https://www.afa.com.ar/es/posts/federal-a-hoy-circulo-deportivo-costa-brava"
      ],
      "verified_at": "2026-10-29T20:21:17Z"
    },
    {
      "source_key": "ar-cordoba-atenas-rio-cuarto",
      "name": "Club Sportivo y Biblioteca Atenas",
      "province": "Córdoba",
      "city": "Río Cuarto",
      "league": "Liga Regional de Fútbol de Río Cuarto",
      "competition_slug": "federal-a",
      "competition_name": "Torneo Federal A",
      "season": "2026",
      "division": null,
      "source_urls": [
        "https://csybatenas.com/socios/",
        "https://csybatenas.com/historia/",
        "https://www.afa.com.ar/es/posts/torneo-federal-a-definidos-los-cruces-de-los-cuartos-de-final"
      ],
      "verified_at": "2026-10-29T20:21:17Z"
    },
    {
      "source_key": "ar-santa-fe-rosario-central",
      "name": "Club Atlético Rosario Central",
      "province": "Santa Fe",
      "city": "Rosario",
      "league": "",
      "competition_slug": "primera-division",
      "competition_name": "Primera División — Liga Profesional de Fútbol",
      "season": "2026",
      "division": null,
      "source_urls": [
        "https://rosariocentral.com/wp-content/uploads/2025/10/Balance.pdf",
        "https://rosariocentral.com/el-club/",
        "https://www.ligaprofesional.ar/notas/primera/2026/09/07/agenda-de-la-fecha-8-a-la-11/"
      ],
      "verified_at": "2026-10-29T20:21:17Z"
    },
    {
      "source_key": "ar-mendoza-godoy-cruz",
      "name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "province": "Mendoza",
      "city": "Godoy Cruz",
      "league": "",
      "competition_slug": "primera-nacional",
      "competition_name": "Primera Nacional",
      "season": "2026",
      "division": null,
      "source_urls": [
        "https://clubgodoycruz.com.ar/contacto/",
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "verified_at": "2026-10-29T20:21:17Z"
    },
    {
      "source_key": "ar-tucuman-atletico-tucuman",
      "name": "Club Atlético Tucumán",
      "province": "Tucumán",
      "city": "San Miguel de Tucumán",
      "league": "",
      "competition_slug": "primera-division",
      "competition_name": "Primera División — Liga Profesional de Fútbol",
      "season": "2026",
      "division": null,
      "source_urls": [
        "https://www.clubatleticotucuman.com.ar/noticias/1186/preguntas-frecuentes-para-socios.html",
        "https://www.ligaprofesional.ar/clubes/atletico-tucuman/",
        "https://www.ligaprofesional.ar/notas/primera/2026/09/07/agenda-de-la-fecha-8-a-la-11/"
      ],
      "verified_at": "2026-10-29T20:21:17Z"
    }
  ]
}$catalog$::jsonb;
  v_item jsonb;
  v_run uuid;
  v_club uuid;
begin
  if v_seed->'metadata'->>'country' <> 'Argentina'
     or (v_seed->'metadata'->>'transfermarkt_imported')::boolean
     or jsonb_array_length(v_seed->'clubs') <> (v_seed->'metadata'->>'club_count')::integer then
    raise exception 'Invalid initial scouting catalogue';
  end if;
  insert into scouting.catalogue_runs(source,status,metadata)
  values('official_reference','staging',v_seed->'metadata') returning id into v_run;
  for v_item in select value from jsonb_array_elements(v_seed->'clubs') loop
    if not exists(select 1 from scouting.provinces where name=v_item->>'province')
       or not exists(select 1 from scouting.competitions where id=v_item->>'competition_slug')
       or jsonb_array_length(v_item->'source_urls')=0 then
      raise exception 'Invalid club reference in initial scouting catalogue';
    end if;
    insert into scouting.clubs(source_key,name,province,city,league,source,source_urls,checked_at,catalogue_run_id)
    values(v_item->>'source_key',v_item->>'name',v_item->>'province',v_item->>'city',
      nullif(v_item->>'league',''),'official_reference',v_item->'source_urls',
      (v_item->>'verified_at')::timestamptz,v_run)
    returning id into v_club;
    insert into scouting.club_competitions(club_id,competition_id,season,division,reference_scope,source_urls,checked_at)
    values(v_club,v_item->>'competition_slug',v_item->>'season',v_item->>'division',
      'primer_equipo_masculino',v_item->'source_urls',(v_item->>'verified_at')::timestamptz);
  end loop;
  update scouting.catalogue_runs set status='published',published_at=clock_timestamp() where id=v_run;
end;
$seed$;
