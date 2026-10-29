-- Argentina 2026: reviewed manual catalogue batch.
-- Club memberships and geography are corroborated with institutional sources.
-- Transfermarkt identifiers are observed references, not a licensed provider feed.
-- Only officially corroborated current player memberships become selectable.
-- Pending/conflicting candidates are retained in the import evidence, not in active players.
-- Snapshot SHA-256: 56a956e43987ef246504a6076723ff8adde22feb22e914068efad7f241bfc19c
set local lock_timeout = '5s';
set local statement_timeout = '45s';

do $import$
declare
  v_data jsonb := $catalogue${
  "metadata": {
    "schema_version": 2,
    "batch_key": "argentina-manual-2026-10-29",
    "country": "Argentina",
    "season": "2026",
    "reviewed_at": "2026-10-29T20:51:32.931Z",
    "club_count": 153,
    "published_club_count": 153,
    "transfermarkt_club_reference_count": 153,
    "player_reference_count": 121,
    "published_player_count": 21,
    "pending_player_count": 98,
    "conflicting_player_count": 2,
    "competition_counts": [
      {
        "id": "primera-division",
        "name": "Primera División / Liga Profesional",
        "expected": 30,
        "collected": 30,
        "published": 30,
        "with_transfermarkt": 30
      },
      {
        "id": "primera-nacional",
        "name": "Primera Nacional",
        "expected": 36,
        "collected": 36,
        "published": 36,
        "with_transfermarkt": 36
      },
      {
        "id": "federal-a",
        "name": "Federal A",
        "expected": 37,
        "collected": 37,
        "published": 37,
        "with_transfermarkt": 37
      },
      {
        "id": "primera-b",
        "name": "Primera B",
        "expected": 22,
        "collected": 22,
        "published": 22,
        "with_transfermarkt": 22
      },
      {
        "id": "primera-c",
        "name": "Primera C",
        "expected": 28,
        "collected": 28,
        "published": 28,
        "with_transfermarkt": 28
      }
    ],
    "coverage": "Primeros equipos masculinos de cinco competencias argentinas, temporada 2026. Cobertura completa de los clubes de esas competencias; cobertura parcial de jugadores. No incluye todas las ligas, el Regional Amateur ni todas las divisiones formativas.",
    "provenance": "Recopilación manual de hechos mínimos de AFA, clubes, organismos públicos y referencias indexadas de Transfermarkt. No es una descarga integral, API ni feed licenciado de Transfermarkt.",
    "geography_scope": "Localidad deportiva estable de la institución, según estadio propio o sede deportiva. Se conserva la sede administrativa divergente como dato adicional. No se usa una cancha prestada temporal.",
    "league_scope": "Liga local sólo cuando existe una fuente explícita. Vacío significa no verificado; no significa ausencia de afiliación.",
    "freshness": "La fecha de revisión indica consulta documental. Los enlaces e identificadores de Transfermarkt fueron recuperados de resultados indexados con distinta antigüedad. Sólo se publican jugadores corroborados con una fuente oficial reciente del club.",
    "transfermarkt_season_note": "Se preservan los parámetros de temporada de las URLs observadas. La temporada deportiva 2026 se comprueba con AFA; no se cambia automáticamente saison_id.",
    "update_policy": "Carga manual puntual. Para el siguiente corte, revisar cambios contra el catálogo por clave estable, validar las altas y afiliaciones, conservar fuentes y publicar sin borrar recomendaciones históricas. No hay actualización mensual automática activa.",
    "review_sources": [
      {
        "country": "Argentina",
        "season": "2026",
        "verified_at": "2026-10-29T20:47:46Z",
        "coverage_expected": {
          "primera-division": 30,
          "primera-nacional": 36
        },
        "coverage_obtained": {
          "primera-division": 30,
          "primera-nacional": 36
        },
        "clubs_expected": 66,
        "clubs_obtained": 66,
        "clubs_with_transfermarkt_ids": 66,
        "clubs_with_verified_geography": 66,
        "clubs_complete_for_selected_competitions": true,
        "all_argentina_competitions_complete": false,
        "provenance": "Recopilación manual puntual de hechos mínimos verificados en AFA, sitios oficiales de clubes y resultados públicos indexados de Transfermarkt. Sin API ni feed licenciado; no se declara una licencia del proveedor.",
        "method": "Búsqueda y lectura manual; sin bots, crawlers ni elusión de 403. Normalización local de datos observados.",
        "geography_policy": "Localidad deportiva estable del club, usando estadio propio o sede deportiva; se conserva la sede administrativa divergente en campos adicionales.",
        "transfermarkt_season_note": "Las referencias indexadas tituladas 2026 enlazan a saison_id/2025. Se conservan las URLs observadas; la temporada deportiva 2026 se verifica con AFA. No sustituir el parámetro numérico automáticamente.",
        "source_freshness": "verified_at indica fecha de revisión documental. AFA y las fuentes actuales del club Talleres fueron recuperadas directamente. Las referencias Transfermarkt son del índice del buscador, con rastreos de 3–5 meses anteriores; no constituyen un feed actualizado al día.",
        "player_coverage": {
          "players_obtained": 61,
          "clubs_sampled": 2,
          "complete_for_competitions": false,
          "complete_current_rosters": false,
          "current_roster_verified_count": 21,
          "pending_current_roster_review_count": 38,
          "excluded_conflicting_current_club_count": 2,
          "import_eligibility": "Sólo las filas current_roster_verified=true se presentan como corroboradas para publicación actual. Las demás se conservan como candidatos para revisión.",
          "position_mapping_note": "Attacking Midfield y Second Striker conservan position=null: el formulario debe pedir la posición local al socio; no se infiere Volante Mixto."
        },
        "component_metadata": [
          {
            "competition": "Primera División / Liga Profesional de Fútbol",
            "season": "2026",
            "country": "Argentina",
            "clubs_expected": 30,
            "clubs_obtained": 30,
            "clubs_with_transfermarkt_ids": 30,
            "clubs_with_verified_geography": 30,
            "coverage": "30 participantes de Primera División 2026 cotejados con AFA. Referencias Transfermarkt observadas manualmente en resultado indexado; no se afirma cobertura de todas las categorías del club.",
            "provenance": "Compilación manual puntual de hechos mínimos: AFA, clubes oficiales y referencias públicas indexadas de Transfermarkt; no API ni feed licenciado.",
            "verified_at": "2026-10-29T20:47:46Z",
            "membership_source_urls": [
              "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
            ],
            "geography_source_urls": [
              "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
              "https://cap.org.ar/datos-de-interes/",
              "https://aldosivi.com/club/estatuto"
            ],
            "transfermarkt_index_url": "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
            "transfermarkt_index_query": "site:transfermarkt.com \"Torneo Clausura\" \"startseite/verein\" \"Club\"",
            "transfermarkt_index_title": "Torneo Clausura 2026",
            "transfermarkt_season_note": "La página indexada titulada 2026 enlaza a saison_id/2025; se conservan las URLs observadas y AFA fija la temporada deportiva 2026. No sustituir automáticamente por saison_id/2026.",
            "geography_policy": "Localidad deportiva estable, usando estadio propio o sede deportiva. Se conserva la localidad administrativa divergente en campos adicionales. No se toma una cancha prestada temporal como domicilio.",
            "players_expected": null,
            "players_obtained": 30,
            "players_complete_for_competition": false,
            "players_current_roster_verified": false,
            "source_freshness": "AFA directorio recuperado directamente hoy; referencias Transfermarkt recuperadas del buscador con rastreo indicado hace 3 meses. verified_at indica comprobación documental, no fecha de actualización de Transfermarkt.",
            "player_clubs_obtained": 1,
            "player_identity_ids_obtained": 30,
            "player_current_roster_verified_count": 21,
            "player_coverage": "30 candidatos identificados de Talleres; 21 corroborados en fuentes actuales del club, 7 pendientes y 2 excluidos por conflicto de club. No constituye plantel completo de Talleres ni de la competición.",
            "current_roster_source_urls": [
              "https://www.clubtalleres.com.ar/plantel-profesional/",
              "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
            ],
            "player_identity_metadata": {
              "requested_players": 30,
              "identified_players": 30,
              "missing_players": [],
              "all_profile_urls_observed": true,
              "requested_tm_club_id": "3938",
              "requested_club": "Club Atlético Talleres",
              "verified_at": "2026-10-29T20:46:43Z",
              "coverage": "Identificación manual de los 30 nombres solicitados; no equivale a un plantel vigente completo.",
              "source_method": "manual_indexed_search",
              "source_freshness": "Perfiles recuperados mediante buscador; antigüedad de rastreo informada entre 3 y 5 meses. No se afirma comprobación directa en vivo.",
              "current_club_conflicts": 2,
              "category_review_required": 4,
              "provenance": "Referencias públicas de Transfermarkt verificadas manualmente, sin API, feed licenciado, bots ni evasión de 403.",
              "important_identity_note": "Matías Galarza de Talleres es ID909737 (Matías Alejandro Galarza), no el homónimo ID661269 (Matías Galarza Fonda) de River.",
              "profile_club_verification_note": "profile_current_club_verified significa que el campo club actual fue observado en el perfil indexado. current_club_confirmed_live permanece false.",
              "privacy_scope": "Sólo nombres, posición y referencias deportivas. No se guardan fechas de nacimiento, domicilios, contactos, agentes, salarios ni valores de mercado."
            }
          },
          {
            "competition": "Primera Nacional",
            "season": "2026",
            "country": "Argentina",
            "clubs_expected": 36,
            "clubs_obtained": 36,
            "clubs_with_transfermarkt_ids": 36,
            "clubs_with_verified_geography": 36,
            "coverage": "36 participantes de Primera Nacional 2026 cotejados con AFA. Referencias Transfermarkt observadas manualmente en índice; planteles de la categoría no completos.",
            "provenance": "Compilación manual puntual de hechos mínimos: AFA y referencias públicas indexadas de Transfermarkt; no API ni feed licenciado.",
            "verified_at": "2026-10-29T20:44:36Z",
            "membership_source_urls": [
              "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
            ],
            "geography_source_urls": [
              "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
            ],
            "transfermarkt_index_url": "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
            "transfermarkt_index_query": "site:transfermarkt.com \"Club Deportivo Morón\" \"startseite/verein\"",
            "transfermarkt_index_title": "Primera Nacional 2026",
            "transfermarkt_direct_access": "Prueba directa del plantel de Godoy Cruz devolvió HTTP 403; no se intentó eludir.",
            "transfermarkt_season_note": "La página indexada titulada 2026 enlaza a saison_id/2025; se conservan las URLs observadas y AFA fija la temporada deportiva 2026. No sustituir automáticamente por saison_id/2026: el índice de un plantel observado lo titula 2027.",
            "geography_policy": "Localidad deportiva estable, usando estadio propio o sede deportiva. Donde difiere la secretaría administrativa se conserva en administrative_city/province. No se toma cancha prestada temporal como domicilio.",
            "players_expected": null,
            "players_obtained": 31,
            "player_clubs_obtained": 1,
            "players_complete_for_competition": false,
            "players_current_roster_verified": false,
            "player_coverage": "Muestra de 31 jugadores listados en la versión indexada del primer plantel de Godoy Cruz. Otra variante indexada muestra 33: no se declara plantel actual completo.",
            "player_identity_ids_obtained": 3,
            "position_mapping_note": "Posiciones originales preservadas. Attacking Midfield y Second Striker quedan position:null para que se elija la categoría local sin inferir equivalencias.",
            "source_freshness": "AFA fixture y directorio recuperados directamente. Referencias y muestra Transfermarkt recuperadas del buscador: rastreos indicados entre 3 y 5 meses antes de verificación."
          }
        ]
      },
      {
        "expected_clubs": 87,
        "obtained_clubs": 87,
        "competition_coverage": {
          "federal-a": {
            "expected": 37,
            "obtained": 37,
            "tm_references_observed": 37,
            "geo_verified": 37
          },
          "primera-b": {
            "expected": 22,
            "obtained": 22,
            "tm_references_observed": 22,
            "geo_verified": 22
          },
          "primera-c": {
            "expected": 28,
            "obtained": 28,
            "tm_references_observed": 28,
            "geo_verified": 28
          }
        },
        "geography": {
          "verified": 87,
          "pending": [],
          "criterion": "Localidad deportiva estable del club; en ausencia de instalación propia verificable se conserva sede institucional, con excepción documentada. No se utiliza cancha prestada temporal.",
          "note": "geo_verified confirma la localidad mediante fuente institucional o gubernamental. Algunas fuentes usan la ciudad de origen sin dirección; nombres de provincia normalizados. Camioneros conserva precisión de partido."
        },
        "transfermarkt": {
          "club_references_observed": 87,
          "method": "Consulta manual de resultados indexados de búsqueda. Las páginas abiertas de torneos y Olimpo devolvieron 403; no se evadió el bloqueo.",
          "official_integration": false,
          "complete_database_download": false,
          "reference_scope": "Identidad y enlace del club. URLs históricas de perfiles preservadas tal como se observaron; la temporada 2026 y geografía provienen de las fuentes oficiales citadas."
        },
        "scope": "Participación del primer equipo masculino en temporada 2026; no constituye catálogo exhaustivo de todas las categorías, ligas ni jugadores de Argentina.",
        "source_notes": [
          "El directorio AFA conserva URL y fecha editorial 2025, pero el contenido observado contiene los 22 equipos de Primera B y 28 de Primera C de 2026; participación corroborada con fixtures oficiales 2026.",
          "Las fichas de Copa Argentina se usan para identidad/localidad, nunca para adjudicar la división actual cuando muestran una temporada antigua.",
          "Los datos de contacto, dirigentes, contratos, valoraciones económicas y fechas de nacimiento no se recopilan.",
          "La ausencia de league significa afiliación local no verificada, no inexistencia de liga."
        ],
        "player_coverage": {
          "import_ready": 0,
          "candidates": 60,
          "current_roster_verified": 0,
          "policy": "Los candidatos se incluyen sólo en planilla y registro de lote para revisión; no deben cargarse como jugadores actuales del catálogo.",
          "samples": [
            {
              "club_source_key": "ar:club:olimpo",
              "observed_rows": 28,
              "source_url": "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468",
              "index_freshness_reported": "3 months ago"
            },
            {
              "club_source_key": "ar:club:brown-adrogue",
              "observed_rows": 32,
              "source_url": "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681",
              "index_freshness_reported": "4 months ago"
            }
          ],
          "limitations": [
            "Las fechas relativas de rastreo son las informadas por el buscador; no equivalen a fecha de actualización de la fuente ni de alta deportiva.",
            "Brown de Adrogué muestra 32 nombres en el perfil indexado y 33 en otra captura de /kader/ rastreada tres meses antes; se conserva la primera captura identificada, sin presentarla como nómina vigente ni fusionar planteles de fechas diferentes.",
            "No se incluyen menores identificados como tales, fechas de nacimiento, edades, contratos, valoraciones económicas ni datos de contacto.",
            "Mediapunta, mediocentro ofensivo y centrocampista genérico quedan sin posición normalizada hasta revisión deportiva."
          ]
        },
        "dataset_status": "closed_for_consolidation",
        "closed_at": "2026-10-29T20:51:07Z"
      }
    ]
  },
  "clubs": [
    {
      "source_key": "ar-caba-argentinos-juniors",
      "name": "Asociación Atlética Argentinos Juniors",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "1030",
      "tm_url": "https://www.transfermarkt.com/argentinos-juniors/startseite/verein/1030/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/argentinos-juniors/startseite/verein/1030/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-cordoba-estudiantes-rio-cuarto",
      "name": "Asociación Atlética Estudiantes de Río Cuarto",
      "province": "Córdoba",
      "city": "Río Cuarto",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "14602",
      "tm_url": "https://www.transfermarkt.com/aa-estudiantes-de-rio-cuarto/startseite/verein/14602/saison_id/2025",
      "source_urls": [
        "https://www.aaestudiantesriocuarto.com/",
        "https://www.lpf.org.ar/clubes/estudiantes-de-rio-cuarto/",
        "https://www.ligaprofesional.ar/notas/primera/2026/09/07/agenda-de-la-fecha-8-a-la-11/",
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/aa-estudiantes-de-rio-cuarto/startseite/verein/14602/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-aldosivi",
      "name": "Club Atlético Aldosivi",
      "province": "Buenos Aires",
      "city": "Mar del Plata",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "12301",
      "tm_url": "https://www.transfermarkt.com/club-atletico-aldosivi/startseite/verein/12301/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-aldosivi/startseite/verein/12301/saison_id/2025",
        "https://aldosivi.com/club/estatuto"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://aldosivi.com/club/estatuto"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-banfield",
      "name": "Club Atlético Banfield",
      "province": "Buenos Aires",
      "city": "Banfield",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "830",
      "tm_url": "https://www.transfermarkt.com/club-atletico-banfield/startseite/verein/830/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-banfield/startseite/verein/830/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-caba-barracas-central",
      "name": "Club Atlético Barracas Central",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "25184",
      "tm_url": "https://www.transfermarkt.com/club-atletico-barracas-central/startseite/verein/25184/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-barracas-central/startseite/verein/25184/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-cordoba-belgrano",
      "name": "Club Atlético Belgrano",
      "province": "Córdoba",
      "city": "Córdoba",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "2417",
      "tm_url": "https://www.transfermarkt.com/ca-belgrano/startseite/verein/2417/saison_id/2025",
      "source_urls": [
        "https://www.ligaprofesional.ar/clubes/belgrano/",
        "https://belgrano.com.ar/estadio/",
        "https://www.ligaprofesional.ar/notas/primera/2026/09/07/agenda-de-la-fecha-8-a-la-11/",
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/ca-belgrano/startseite/verein/2417/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-caba-boca-juniors",
      "name": "Club Atlético Boca Juniors",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "189",
      "tm_url": "https://www.transfermarkt.com/club-atletico-boca-juniors/startseite/verein/189/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-boca-juniors/startseite/verein/189/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-santiago-del-estero-central-cordoba",
      "name": "Club Atlético Central Córdoba de Santiago del Estero",
      "province": "Santiago del Estero",
      "city": "Santiago del Estero",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "31284",
      "tm_url": "https://www.transfermarkt.com/club-atletico-central-cordoba-sde-/startseite/verein/31284/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-central-cordoba-sde-/startseite/verein/31284/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-mendoza-gimnasia-y-esgrima",
      "name": "Club Atlético Gimnasia y Esgrima de Mendoza",
      "province": "Mendoza",
      "city": "Mendoza",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "14687",
      "tm_url": "https://www.transfermarkt.com/gimnasia-y-esgrima-de-mendoza/startseite/verein/14687/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/gimnasia-y-esgrima-de-mendoza/startseite/verein/14687/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-caba-huracan",
      "name": "Club Atlético Huracán",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "2063",
      "tm_url": "https://www.transfermarkt.com/club-atletico-huracan/startseite/verein/2063/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-huracan/startseite/verein/2063/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-independiente",
      "name": "Club Atlético Independiente",
      "province": "Buenos Aires",
      "city": "Avellaneda",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "1234",
      "tm_url": "https://www.transfermarkt.com/club-atletico-independiente/startseite/verein/1234/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-independiente/startseite/verein/1234/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-lanus",
      "name": "Club Atlético Lanús",
      "province": "Buenos Aires",
      "city": "Lanús",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "333",
      "tm_url": "https://www.transfermarkt.com/club-atletico-lanus/startseite/verein/333/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-lanus/startseite/verein/333/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "geo_note": "La dirección deportiva de AFA corresponde a Lanús Este, ciudad de Lanús.",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-santa-fe-newells-old-boys",
      "name": "Club Atlético Newell's Old Boys",
      "province": "Santa Fe",
      "city": "Rosario",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "1286",
      "tm_url": "https://www.transfermarkt.com/club-atletico-newells-old-boys/startseite/verein/1286/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-newells-old-boys/startseite/verein/1286/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-platense",
      "name": "Club Atlético Platense",
      "province": "Buenos Aires",
      "city": "Florida",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "928",
      "tm_url": "https://www.transfermarkt.com/club-atletico-platense/startseite/verein/928/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-platense/startseite/verein/928/saison_id/2025",
        "https://cap.org.ar/datos-de-interes/"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://cap.org.ar/datos-de-interes/"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "municipality": "Vicente López",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-caba-river-plate",
      "name": "Club Atlético River Plate",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "209",
      "tm_url": "https://www.transfermarkt.com/club-atletico-river-plate/startseite/verein/209/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-river-plate/startseite/verein/209/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-santa-fe-rosario-central",
      "name": "Club Atlético Rosario Central",
      "province": "Santa Fe",
      "city": "Rosario",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "1418",
      "tm_url": "https://www.transfermarkt.com/club-atletico-rosario-central/startseite/verein/1418/saison_id/2025",
      "source_urls": [
        "https://rosariocentral.com/wp-content/uploads/2025/10/Balance.pdf",
        "https://rosariocentral.com/el-club/",
        "https://www.ligaprofesional.ar/notas/primera/2026/09/07/agenda-de-la-fecha-8-a-la-11/",
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-rosario-central/startseite/verein/1418/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-caba-san-lorenzo",
      "name": "Club Atlético San Lorenzo de Almagro",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "1775",
      "tm_url": "https://www.transfermarkt.com/club-atletico-san-lorenzo-de-almagro/startseite/verein/1775/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-san-lorenzo-de-almagro/startseite/verein/1775/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-sarmiento-junin",
      "name": "Club Atlético Sarmiento de Junín",
      "province": "Buenos Aires",
      "city": "Junín",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "12454",
      "tm_url": "https://www.transfermarkt.com/club-atletico-sarmiento-junin-/startseite/verein/12454/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-sarmiento-junin-/startseite/verein/12454/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-cordoba-talleres",
      "name": "Club Atlético Talleres",
      "province": "Córdoba",
      "city": "Córdoba",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "3938",
      "tm_url": "https://www.transfermarkt.com/club-atletico-talleres/startseite/verein/3938/saison_id/2025",
      "source_urls": [
        "https://www.ligaprofesional.ar/clubes/talleres/",
        "https://tienda.clubtalleres.com.ar/sede-social-html/",
        "https://www.ligaprofesional.ar/notas/primera/2026/09/07/agenda-de-la-fecha-8-a-la-11/",
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-talleres/startseite/verein/3938/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-tigre",
      "name": "Club Atlético Tigre",
      "province": "Buenos Aires",
      "city": "Victoria",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "11831",
      "tm_url": "https://www.transfermarkt.com/club-atletico-tigre/startseite/verein/11831/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-tigre/startseite/verein/11831/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-tucuman-atletico-tucuman",
      "name": "Club Atlético Tucumán",
      "province": "Tucumán",
      "city": "San Miguel de Tucumán",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "14554",
      "tm_url": "https://www.transfermarkt.com/club-atletico-tucuman/startseite/verein/14554/saison_id/2025",
      "source_urls": [
        "https://www.clubatleticotucuman.com.ar/noticias/1186/preguntas-frecuentes-para-socios.html",
        "https://www.ligaprofesional.ar/clubes/atletico-tucuman/",
        "https://www.ligaprofesional.ar/notas/primera/2026/09/07/agenda-de-la-fecha-8-a-la-11/",
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-tucuman/startseite/verein/14554/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-santa-fe-union",
      "name": "Club Atlético Unión",
      "province": "Santa Fe",
      "city": "Santa Fe",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "7097",
      "tm_url": "https://www.transfermarkt.com/club-atletico-union/startseite/verein/7097/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-union/startseite/verein/7097/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-caba-velez-sarsfield",
      "name": "Club Atlético Vélez Sarsfield",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "1029",
      "tm_url": "https://www.transfermarkt.com/club-atletico-velez-sarsfield/startseite/verein/1029/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-atletico-velez-sarsfield/startseite/verein/1029/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-gimnasia-la-plata",
      "name": "Club de Gimnasia y Esgrima La Plata",
      "province": "Buenos Aires",
      "city": "La Plata",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "1106",
      "tm_url": "https://www.transfermarkt.com/club-de-gimnasia-y-esgrima-la-plata/startseite/verein/1106/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-de-gimnasia-y-esgrima-la-plata/startseite/verein/1106/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-caba-deportivo-riestra",
      "name": "Club Deportivo Riestra",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "19775",
      "tm_url": "https://www.transfermarkt.com/cd-riestra/startseite/verein/19775/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/cd-riestra/startseite/verein/19775/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-estudiantes-la-plata",
      "name": "Club Estudiantes de La Plata",
      "province": "Buenos Aires",
      "city": "La Plata",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "288",
      "tm_url": "https://www.transfermarkt.com/club-estudiantes-de-la-plata/startseite/verein/288/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/club-estudiantes-de-la-plata/startseite/verein/288/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-defensa-y-justicia",
      "name": "Club Social y Deportivo Defensa y Justicia",
      "province": "Buenos Aires",
      "city": "Florencio Varela",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "2402",
      "tm_url": "https://www.transfermarkt.com/defensa-y-justicia/startseite/verein/2402/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/defensa-y-justicia/startseite/verein/2402/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "administrative_city": "Bosques",
      "administrative_province": "Buenos Aires",
      "administrative_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "geo_note": "Florencio Varela corresponde al estadio estable y atención de socios; la secretaría se ubica en Bosques.",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-mendoza-independiente-rivadavia",
      "name": "Club Sportivo Independiente Rivadavia",
      "province": "Mendoza",
      "city": "Mendoza",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "12179",
      "tm_url": "https://www.transfermarkt.com/independiente-rivadavia/startseite/verein/12179/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/independiente-rivadavia/startseite/verein/12179/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-cordoba-instituto",
      "name": "Instituto Atlético Central Córdoba",
      "province": "Córdoba",
      "city": "Córdoba",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "1829",
      "tm_url": "https://www.transfermarkt.com/instituto-ac-cordoba/startseite/verein/1829/saison_id/2025",
      "source_urls": [
        "https://institutoacc.com.ar/index.php/contacto-y-ubicacion/",
        "https://institutoacc.com.ar/index.php/convocatoria-a-asamblea-general-ordinaria-2026/",
        "https://www.ligaprofesional.ar/notas/primera/2026/09/07/agenda-de-la-fecha-8-a-la-11/",
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/instituto-ac-cordoba/startseite/verein/1829/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-racing-club",
      "name": "Racing Club",
      "province": "Buenos Aires",
      "city": "Avellaneda",
      "league": null,
      "competition_slug": "primera-division",
      "season": "2026",
      "tm_id": "1444",
      "tm_url": "https://www.transfermarkt.com/racing-club/startseite/verein/1444/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC",
        "https://www.transfermarkt.com/racing-club/startseite/verein/1444/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:45:56Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/es/posts/sorteo-de-la-liga-profesional-2026-se-definen-los-grupos-del-torneo-apertura-y-torneo-clausura"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/torneo-final/startseite/wettbewerb/ARGC"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera División / Liga Profesional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-santa-fe-atletico-rafaela",
      "name": "Atlético de Rafaela",
      "province": "Santa Fe",
      "city": "Rafaela",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "10233",
      "tm_url": "https://www.transfermarkt.com/atletico-de-rafaela/startseite/verein/10233/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/atletico-de-rafaela/startseite/verein/10233/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-agropecuario",
      "name": "Club Agropecuario Argentino",
      "province": "Buenos Aires",
      "city": "Carlos Casares",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "38545",
      "tm_url": "https://www.transfermarkt.com/argentino-agropecuario/startseite/verein/38545/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/argentino-agropecuario/startseite/verein/38545/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-almagro",
      "name": "Club Almagro",
      "province": "Buenos Aires",
      "city": "José Ingenieros",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "14977",
      "tm_url": "https://www.transfermarkt.com/club-almagro/startseite/verein/14977/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-almagro/startseite/verein/14977/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "administrative_city": "Ciudad Autónoma de Buenos Aires",
      "administrative_province": "Ciudad Autónoma de Buenos Aires",
      "administrative_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-almirante-brown",
      "name": "Club Almirante Brown",
      "province": "Buenos Aires",
      "city": "Isidro Casanova",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "12672",
      "tm_url": "https://www.transfermarkt.com/club-almirante-brown/startseite/verein/12672/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-almirante-brown/startseite/verein/12672/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "administrative_city": "San Justo",
      "administrative_province": "Buenos Aires",
      "administrative_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-acassuso",
      "name": "Club Atlético Acassuso",
      "province": "Buenos Aires",
      "city": "Boulogne Sur Mer",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "12677",
      "tm_url": "https://www.transfermarkt.com/acassuso-cf/startseite/verein/12677/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/acassuso-cf/startseite/verein/12677/saison_id/2025",
        "https://clubacassuso.com.ar/estadio/"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://clubacassuso.com.ar/estadio/"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "administrative_city": "San Isidro",
      "administrative_province": "Buenos Aires",
      "administrative_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-caba-all-boys",
      "name": "Club Atlético All Boys",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "12100",
      "tm_url": "https://www.transfermarkt.com/ca-all-boys-buenos-aires/startseite/verein/12100/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/ca-all-boys-buenos-aires/startseite/verein/12100/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-caba-atlanta",
      "name": "Club Atlético Atlanta",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "8057",
      "tm_url": "https://www.transfermarkt.com/club-atletico-atlanta/startseite/verein/8057/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-atletico-atlanta/startseite/verein/8057/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-salta-central-norte",
      "name": "Club Atlético Central Norte",
      "province": "Salta",
      "city": "Salta",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "14670",
      "tm_url": "https://www.transfermarkt.com/club-atletico-central-norte/startseite/verein/14670/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-atletico-central-norte/startseite/verein/14670/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-chacarita",
      "name": "Club Atlético Chacarita Juniors",
      "province": "Buenos Aires",
      "city": "Villa Maipú",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "2154",
      "tm_url": "https://www.transfermarkt.com/ca-chacarita-juniors/startseite/verein/2154/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/ca-chacarita-juniors/startseite/verein/2154/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "administrative_city": "Ciudad Autónoma de Buenos Aires",
      "administrative_province": "Ciudad Autónoma de Buenos Aires",
      "administrative_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-chaco-chaco-for-ever",
      "name": "Club Atlético Chaco For Ever",
      "province": "Chaco",
      "city": "Resistencia",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "12681",
      "tm_url": "https://www.transfermarkt.com/chaco-for-ever/startseite/verein/12681/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/chaco-for-ever/startseite/verein/12681/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-colegiales",
      "name": "Club Atlético Colegiales",
      "province": "Buenos Aires",
      "city": "Munro",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "13339",
      "tm_url": "https://www.transfermarkt.com/club-atletico-colegiales/startseite/verein/13339/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-atletico-colegiales/startseite/verein/13339/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-santa-fe-colon",
      "name": "Club Atlético Colón",
      "province": "Santa Fe",
      "city": "Santa Fe",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "1070",
      "tm_url": "https://www.transfermarkt.com/club-atletico-colon/startseite/verein/1070/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-atletico-colon/startseite/verein/1070/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-caba-defensores-belgrano",
      "name": "Club Atlético Defensores de Belgrano",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "6062",
      "tm_url": "https://www.transfermarkt.com/defensores-de-belgrano/startseite/verein/6062/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/defensores-de-belgrano/startseite/verein/6062/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-estudiantes-caseros",
      "name": "Club Atlético Estudiantes de Caseros",
      "province": "Buenos Aires",
      "city": "Caseros",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "14312",
      "tm_url": "https://www.transfermarkt.com/ca-estudiantes-buenos-aires-/startseite/verein/14312/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/ca-estudiantes-buenos-aires-/startseite/verein/14312/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "administrative_city": "Ciudad Autónoma de Buenos Aires",
      "administrative_province": "Ciudad Autónoma de Buenos Aires",
      "administrative_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-ferrocarril-midland",
      "name": "Club Atlético Ferrocarril Midland",
      "province": "Buenos Aires",
      "city": "Libertad",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "14686",
      "tm_url": "https://www.transfermarkt.com/ferrocarril-midland/startseite/verein/14686/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/ferrocarril-midland/startseite/verein/14686/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-jujuy-gimnasia-esgrima",
      "name": "Club Atlético Gimnasia y Esgrima de Jujuy",
      "province": "Jujuy",
      "city": "San Salvador de Jujuy",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "10885",
      "tm_url": "https://www.transfermarkt.com/gimnasia-y-esgrima-de-jujuy/startseite/verein/10885/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/gimnasia-y-esgrima-de-jujuy/startseite/verein/10885/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-santiago-del-estero-guemes",
      "name": "Club Atlético Güemes",
      "province": "Santiago del Estero",
      "city": "Santiago del Estero",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "58188",
      "tm_url": "https://www.transfermarkt.com/club-atletico-guemes/startseite/verein/58188/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-atletico-guemes/startseite/verein/58188/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-los-andes",
      "name": "Club Atlético Los Andes",
      "province": "Buenos Aires",
      "city": "Lomas de Zamora",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "5208",
      "tm_url": "https://www.transfermarkt.com/ca-los-andes/startseite/verein/5208/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/ca-los-andes/startseite/verein/5208/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-santiago-del-estero-mitre",
      "name": "Club Atlético Mitre",
      "province": "Santiago del Estero",
      "city": "Santiago del Estero",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "30038",
      "tm_url": "https://www.transfermarkt.com/club-atletico-mitre/startseite/verein/30038/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-atletico-mitre/startseite/verein/30038/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-caba-nueva-chicago",
      "name": "Club Atlético Nueva Chicago",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "10534",
      "tm_url": "https://www.transfermarkt.com/nueva-chicago/startseite/verein/10534/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/nueva-chicago/startseite/verein/10534/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-entre-rios-patronato",
      "name": "Club Atlético Patronato",
      "province": "Entre Ríos",
      "city": "Paraná",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "19806",
      "tm_url": "https://www.transfermarkt.com/club-atletico-patronato/startseite/verein/19806/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-atletico-patronato/startseite/verein/19806/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-cordoba-racing",
      "name": "Club Atlético Racing de Córdoba",
      "province": "Córdoba",
      "city": "Córdoba",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "10403",
      "tm_url": "https://www.transfermarkt.com/atletico-racing-cordoba/startseite/verein/10403/saison_id/2025",
      "source_urls": [
        "https://racingcba.com.ar/bienvenido/complejo-racing/",
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/atletico-racing-cordoba/startseite/verein/10403/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-san-juan-san-martin",
      "name": "Club Atlético San Martín de San Juan",
      "province": "San Juan",
      "city": "San Juan",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "10511",
      "tm_url": "https://www.transfermarkt.com/club-atletico-san-martin-sj-/startseite/verein/10511/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-atletico-san-martin-sj-/startseite/verein/10511/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-tucuman-san-martin",
      "name": "Club Atlético San Martín de Tucumán",
      "province": "Tucumán",
      "city": "San Miguel de Tucumán",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "12709",
      "tm_url": "https://www.transfermarkt.com/ca-san-martin-tucuman-/startseite/verein/12709/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/ca-san-martin-tucuman-/startseite/verein/12709/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-san-miguel",
      "name": "Club Atlético San Miguel",
      "province": "Buenos Aires",
      "city": "Los Polvorines",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "19634",
      "tm_url": "https://www.transfermarkt.com/ca-san-miguel/startseite/verein/19634/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/ca-san-miguel/startseite/verein/19634/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "administrative_city": "San Miguel",
      "administrative_province": "Buenos Aires",
      "administrative_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-san-telmo",
      "name": "Club Atlético San Telmo",
      "province": "Buenos Aires",
      "city": "Isla Maciel",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "13651",
      "tm_url": "https://www.transfermarkt.com/ca-san-telmo/startseite/verein/13651/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/ca-san-telmo/startseite/verein/13651/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "administrative_city": "Ciudad Autónoma de Buenos Aires",
      "administrative_province": "Ciudad Autónoma de Buenos Aires",
      "administrative_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-temperley",
      "name": "Club Atlético Temperley",
      "province": "Buenos Aires",
      "city": "Temperley",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "14542",
      "tm_url": "https://www.transfermarkt.com/club-atletico-temperley/startseite/verein/14542/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-atletico-temperley/startseite/verein/14542/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-ciudad-bolivar",
      "name": "Club Ciudad de Bolívar",
      "province": "Buenos Aires",
      "city": "Bolívar",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "91422",
      "tm_url": "https://www.transfermarkt.com/club-ciudad-de-bolivar/startseite/verein/91422/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-ciudad-de-bolivar/startseite/verein/91422/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-salta-gimnasia-tiro",
      "name": "Club de Gimnasia y Tiro",
      "province": "Salta",
      "city": "Salta",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "14688",
      "tm_url": "https://www.transfermarkt.com/gimnasia-y-tiro-salta-/startseite/verein/14688/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/gimnasia-y-tiro-salta-/startseite/verein/14688/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-mendoza-godoy-cruz",
      "name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "province": "Mendoza",
      "city": "Godoy Cruz",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "12574",
      "tm_url": "https://www.transfermarkt.com/club-deportivo-godoy-cruz-antonio-tomba/startseite/verein/12574/saison_id/2025",
      "source_urls": [
        "https://clubgodoycruz.com.ar/contacto/",
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-deportivo-godoy-cruz-antonio-tomba/startseite/verein/12574/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-mendoza-deportivo-maipu",
      "name": "Club Deportivo Maipú",
      "province": "Mendoza",
      "city": "Maipú",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "19523",
      "tm_url": "https://www.transfermarkt.com/cd-maipu-mendoza-/startseite/verein/19523/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/cd-maipu-mendoza-/startseite/verein/19523/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-deportivo-moron",
      "name": "Club Deportivo Morón",
      "province": "Buenos Aires",
      "city": "Morón",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "12458",
      "tm_url": "https://www.transfermarkt.com/cd-moron/startseite/verein/12458/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/cd-moron/startseite/verein/12458/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-caba-ferro-carril-oeste",
      "name": "Club Ferro Carril Oeste",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Ciudad Autónoma de Buenos Aires",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "4557",
      "tm_url": "https://www.transfermarkt.com/club-ferro-carril-oeste/startseite/verein/4557/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/club-ferro-carril-oeste/startseite/verein/4557/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-chubut-deportivo-madryn",
      "name": "Club Social y Deportivo Madryn",
      "province": "Chubut",
      "city": "Puerto Madryn",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "14318",
      "tm_url": "https://www.transfermarkt.com/csd-madryn/startseite/verein/14318/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/csd-madryn/startseite/verein/14318/saison_id/2025",
        "https://assets1.afa.com.ar/2025/Boletin-Comite-Ejecutivo-6772-%2816-10-2025%29.pdf"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://assets1.afa.com.ar/2025/Boletin-Comite-Ejecutivo-6772-%2816-10-2025%29.pdf"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-tristan-suarez",
      "name": "Club Tristán Suárez",
      "province": "Buenos Aires",
      "city": "Tristán Suárez",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "1771",
      "tm_url": "https://www.transfermarkt.com/csd-tristan-suarez/startseite/verein/1771/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/csd-tristan-suarez/startseite/verein/1771/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-buenos-aires-quilmes",
      "name": "Quilmes Atlético Club",
      "province": "Buenos Aires",
      "city": "Quilmes",
      "league": null,
      "competition_slug": "primera-nacional",
      "season": "2026",
      "tm_id": "1826",
      "tm_url": "https://www.transfermarkt.com/quilmes-atletico-club/startseite/verein/1826/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc",
        "https://www.transfermarkt.com/quilmes-atletico-club/startseite/verein/1826/saison_id/2025"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "geo_verified": true,
      "geo_basis": "localidad_deportiva_estable_del_club_estadio_propio_o_sede_deportiva",
      "geo_source_urls": [
        "https://www.afa.com.ar/8603/posts/clubes-afiliados-2025"
      ],
      "membership_source_urls": [
        "https://www.afa.com.ar/n/posts/primera-nacional-fixture-para-la-temporada-2026"
      ],
      "tm_reference_source_urls": [
        "https://www.transfermarkt.com/purimera-nashionaru/startseite/wettbewerb/ARG2/saison_id/sort/anzahl_spieler_hidden.desc"
      ],
      "tm_season_parameter": "2025",
      "competition_name": "Primera Nacional",
      "division": null,
      "reference_scope": "primer_equipo_masculino",
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:san-martin-mendoza",
      "name": "Atlético Club San Martín",
      "province": "Mendoza",
      "city": "San Martín",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "8413",
      "tm_url": "https://www.transfermarkt.com.ar/san-martin-de-mendoza/startseite/verein/8413",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.mendoza.gov.ar/prensa/nuevo-pavimento-para-el-tramo-mas-transitado-de-la-ruta-50-en-san-martin/",
        "https://www.mendoza.gov.ar/wp-content/uploads/boletin.old/20000407-26132-edictos.pdf",
        "https://www.transfermarkt.com.ar/san-martin-de-mendoza/startseite/verein/8413"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.mendoza.gov.ar/prensa/nuevo-pavimento-para-el-tramo-mas-transitado-de-la-ruta-50-en-san-martin/"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "geo_notes": "La ubicación institucional en ciudad de General San Martín se documenta en Boletín Oficial; denominación de ciudad normalizada a San Martín.",
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:atletico-escobar",
      "name": "Atlético Escobar Fútbol Club",
      "province": "Buenos Aires",
      "city": "Ingeniero Maschwitz",
      "league": "Liga Escobarense de Fútbol",
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "135792",
      "tm_url": "https://www.transfermarkt.com.ar/atletico-escobar-fc/startseite/verein/135792",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.afa.com.ar/n/posts/estas-seran-las-cuatro-finales-del-torneo-regional",
        "https://atleticoescobar.com.ar/",
        "https://www.transfermarkt.com.ar/atletico-escobar-fc/startseite/verein/135792"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_afa_y_club",
      "geo_source_urls": [
        "https://www.afa.com.ar/n/posts/estas-seran-las-cuatro-finales-del-torneo-regional"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "geo_notes": "AFA identifica a Escobar FC como Ingeniero Maschwitz y el club documenta su origen deportivo allí. No se asigna la localidad por el estadio prestado de Armenio.",
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:juventud-antoniana",
      "name": "Centro Juventud Antoniana",
      "province": "Salta",
      "city": "Salta",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "10129",
      "tm_url": "https://www.transfermarkt.es/centro-juventud-antoniana/startseite/verein/10129",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/164_Juventud-Antoniana.html",
        "https://www.transfermarkt.es/centro-juventud-antoniana/startseite/verein/10129"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/164_Juventud-Antoniana.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:9-de-julio-rafaela",
      "name": "Club Atlético 9 de Julio (Rafaela)",
      "province": "Santa Fe",
      "city": "Rafaela",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "12487",
      "tm_url": "https://www.transfermarkt.com.ar/ca-9-de-julio/startseite/verein/12487",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/221_9-de-Julio-R-.html",
        "https://www.transfermarkt.com.ar/ca-9-de-julio/startseite/verein/12487"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/221_9-de-Julio-R-.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:alvarado",
      "name": "Club Atlético Alvarado",
      "province": "Buenos Aires",
      "city": "Mar del Plata",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "12563",
      "tm_url": "https://www.transfermarkt.com.ar/ca-alvarado/startseite/verein/12563",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/209_Alvarado.html",
        "https://www.transfermarkt.com.ar/ca-alvarado/startseite/verein/12563"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/209_Alvarado.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:bartolome-mitre",
      "name": "Club Atlético Bartolomé Mitre (Posadas)",
      "province": "Misiones",
      "city": "Posadas",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "117574",
      "tm_url": "https://www.transfermarkt.com/ca-bartolome-mitre-pos-/startseite/verein/117574",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://cabmitre.com/",
        "https://www.transfermarkt.com/ca-bartolome-mitre-pos-/startseite/verein/117574"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://cabmitre.com/"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:boca-unidos",
      "name": "Club Atlético Boca Unidos",
      "province": "Corrientes",
      "city": "Corrientes",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "13549",
      "tm_url": "https://www.transfermarkt.es/ca-boca-unidos/startseite/verein/13549",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/89_Boca-Unidos.html",
        "https://www.transfermarkt.es/ca-boca-unidos/startseite/verein/13549"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/89_Boca-Unidos.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:costa-brava",
      "name": "Club Atlético Costa Brava",
      "province": "La Pampa",
      "city": "General Pico",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "79503",
      "tm_url": "https://www.transfermarkt.com.ar/ca-costa-brava/startseite/verein/79503",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://boletinoficial.lapampa.gob.ar/images/Archivos/BoletinOficial/2021/Bof3459.pdf",
        "https://www.transfermarkt.com.ar/ca-costa-brava/startseite/verein/79503"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://boletinoficial.lapampa.gob.ar/images/Archivos/BoletinOficial/2021/Bof3459.pdf"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:douglas-haig",
      "name": "Club Atlético Douglas Haig",
      "province": "Buenos Aires",
      "city": "Pergamino",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "14718",
      "tm_url": "https://www.transfermarkt.com.ar/ca-douglas-haig/startseite/verein/14718/saison_id/2023",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/172_Douglas-Haig.html",
        "https://www.transfermarkt.com.ar/ca-douglas-haig/startseite/verein/14718/saison_id/2023"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/172_Douglas-Haig.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:el-linqueno",
      "name": "Club Atlético El Linqueño",
      "province": "Buenos Aires",
      "city": "Lincoln",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "18534",
      "tm_url": "https://www.transfermarkt.com.ar/club-atletico-el-linqueno/startseite/verein/18534/saison_id/2022",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/211_El-Linqueno.html",
        "https://www.transfermarkt.com.ar/club-atletico-el-linqueno/startseite/verein/18534/saison_id/2022"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/211_El-Linqueno.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:germinal",
      "name": "Club Atlético Germinal",
      "province": "Chubut",
      "city": "Rawson",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "14316",
      "tm_url": "https://www.transfermarkt.com/club-atletico-germinal-rawson-/startseite/verein/14316",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/282_Germinal.html",
        "https://www.transfermarkt.com/club-atletico-germinal-rawson-/startseite/verein/14316"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/282_Germinal.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:huracan-las-heras",
      "name": "Club Atlético Huracán Las Heras",
      "province": "Mendoza",
      "city": "Las Heras",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "17591",
      "tm_url": "https://www.transfermarkt.com.ar/ca-huracan-las-heras/startseite/verein/17591",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://clubhuracanlasheras.com.ar/club/",
        "https://www.transfermarkt.com.ar/ca-huracan-las-heras/startseite/verein/17591"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://clubhuracanlasheras.com.ar/club/"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:independiente-chivilcoy",
      "name": "Club Atlético Independiente (Chivilcoy)",
      "province": "Buenos Aires",
      "city": "Chivilcoy",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "29680",
      "tm_url": "https://www.transfermarkt.com/ca-independiente-chivilcoy-/startseite/verein/29680/saison_id/2026",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/274_Independiente-CH-.html",
        "https://www.transfermarkt.com/ca-independiente-chivilcoy-/startseite/verein/29680/saison_id/2026"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/274_Independiente-CH-.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:juventud-unida-san-luis",
      "name": "Club Atlético Juventud Unida Universitario",
      "province": "San Luis",
      "city": "San Luis",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "18911",
      "tm_url": "https://www.transfermarkt.com.ar/club-atletico-ca-juventud-unida-universitario/startseite/verein/18911",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/179_Juventud-Unida-de-San-Luis.html",
        "https://www.transfermarkt.com.ar/club-atletico-ca-juventud-unida-universitario/startseite/verein/18911"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/179_Juventud-Unida-de-San-Luis.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:kimberley",
      "name": "Club Atlético Kimberley",
      "province": "Buenos Aires",
      "city": "Mar del Plata",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "28619",
      "tm_url": "https://www.transfermarkt.com.ar/club-atletico-kimberley-de-mar-del-plata/startseite/verein/28619",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/345_Kimberley.html",
        "https://www.transfermarkt.com.ar/club-atletico-kimberley-de-mar-del-plata/startseite/verein/28619"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/345_Kimberley.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:sarmiento-la-banda",
      "name": "Club Atlético Sarmiento (La Banda)",
      "province": "Santiago del Estero",
      "city": "La Banda",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "30079",
      "tm_url": "https://www.transfermarkt.com.ar/ca-sarmiento-la-banda-/startseite/verein/30079",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/254_sarmiento-de-la-banda.html",
        "https://www.transfermarkt.com.ar/ca-sarmiento-la-banda-/startseite/verein/30079"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/254_sarmiento-de-la-banda.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:sarmiento-resistencia",
      "name": "Club Atlético Sarmiento (Resistencia)",
      "province": "Chaco",
      "city": "Resistencia",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "30838",
      "tm_url": "https://www.transfermarkt.com.ar/club-sarmiento/startseite/verein/30838",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/228_Sarmiento-de-Resistencia.html",
        "https://www.transfermarkt.com.ar/club-sarmiento/startseite/verein/30838"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/228_Sarmiento-de-Resistencia.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:tucuman-central",
      "name": "Club Atlético Tucumán Central",
      "province": "Tucumán",
      "city": "San Miguel de Tucumán",
      "league": "Liga Tucumana de Fútbol",
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "128105",
      "tm_url": "https://www.transfermarkt.es/ca-tucuman-central/startseite/verein/128105",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://assets1.afa.com.ar/2026/BOLETINES/BOLETIN-NRO-27-26.pdf",
        "https://www.estadiosdeargentina.com.ar/cancha-de-tucuman-central-villa-alem/",
        "https://indicadores.ar/empresa/30691830345-club-tucuman-central",
        "https://www.transfermarkt.es/ca-tucuman-central/startseite/verein/128105",
        "https://old.fontagro.org/new/uploads/productos/16108_-_Producto_2_11.pdf"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "predio_del_club_documentado_en_investigacion_institucional_primaria",
      "geo_source_urls": [
        "https://old.fontagro.org/new/uploads/productos/16108_-_Producto_2_11.pdf",
        "https://www.estadiosdeargentina.com.ar/cancha-de-tucuman-central-villa-alem/",
        "https://indicadores.ar/empresa/30691830345-club-tucuman-central"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "geo_notes": "Informe FONTAGRO/BID (2020), con observación de campo del 12/10/2019, ubica el predio propio del Club Tucumán Central en Villa Alem, San Miguel de Tucumán (páginas 8, 11 y 24). La localidad coincide con referencias públicas consultadas en 2026; la fuente institucional geográfica es histórica y se conserva su fecha.",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:defensores-belgrano-villa-ramallo",
      "name": "Club Atlético y Social Defensores de Belgrano (Villa Ramallo)",
      "province": "Buenos Aires",
      "city": "Villa Ramallo",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "25348",
      "tm_url": "https://www.transfermarkt.com.ar/cas-defensores-de-belgrano/startseite/verein/25348",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/175_Defensores-VR-.html",
        "https://www.transfermarkt.com.ar/cas-defensores-de-belgrano/startseite/verein/25348"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/175_Defensores-VR-.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:cipolletti",
      "name": "Club Cipolletti",
      "province": "Río Negro",
      "city": "Cipolletti",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "19870",
      "tm_url": "https://www.transfermarkt.es/club-cipolletti/startseite/verein/19870",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/180_Cipolletti.html",
        "https://www.transfermarkt.es/club-cipolletti/startseite/verein/19870"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/180_Cipolletti.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:circulo-deportivo",
      "name": "Club Círculo Deportivo",
      "province": "Buenos Aires",
      "city": "Comandante Nicanor Otamendi",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "78072",
      "tm_url": "https://www.transfermarkt.es/circulo-deportivo/startseite/verein/78072",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/411_Circulo-Deportivo.html",
        "https://www.transfermarkt.es/circulo-deportivo/startseite/verein/78072"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/411_Circulo-Deportivo.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:defensores-vilelas",
      "name": "Club Defensores de Puerto Vilelas",
      "province": "Chaco",
      "city": "Puerto Vilelas",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "107445",
      "tm_url": "https://www.transfermarkt.es/defensores-de-vilelas/startseite/verein/107445/saison_id/2025",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://loteria.chaco.gov.ar/detalle_noticia/532",
        "https://www.transfermarkt.es/defensores-de-vilelas/startseite/verein/107445/saison_id/2025",
        "https://www.transfermarkt.es/torneo-federal-a/startseite/wettbewerb/ARG3"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://loteria.chaco.gov.ar/detalle_noticia/532"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "tm_reference_observation": "Enlace relativo observado en tabla indexada del Torneo Federal A; resuelto sobre dominio de la página de origen.",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-cordoba-argentino-monte-maiz",
      "name": "Club Deportivo Argentino de Monte Maíz",
      "province": "Córdoba",
      "city": "Monte Maíz",
      "league": "Liga Regional de Fútbol Dr. Adrián Beccar Varela",
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "97822",
      "tm_url": "https://www.transfermarkt.com.ar/cd-argentino-monte-maiz-/startseite/verein/97822",
      "source_urls": [
        "https://argentinocrece.com.ar/Contacto",
        "https://labeccar.com.ar/noticias/cumpleanos-argentino-de-monte-maiz/",
        "https://labeccar.com.ar/noticias/federal-a-argentino-de-monte-maiz-volvio-al-trabajo/",
        "https://www.afa.com.ar/es/posts/federal-a-hoy-circulo-deportivo-costa-brava",
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/news/11158_Club-Deportivo-Argentino-de-Monte-Maiz.html",
        "https://www.transfermarkt.com.ar/cd-argentino-monte-maiz-/startseite/verein/97822"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/news/11158_Club-Deportivo-Argentino-de-Monte-Maiz.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:deportivo-rincon",
      "name": "Club Deportivo Rincón",
      "province": "Neuquén",
      "city": "Rincón de los Sauces",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "83668",
      "tm_url": "https://www.transfermarkt.com.ar/club-deportivo-rincon/startseite/verein/83668",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/409_deportivo-rincon.html",
        "https://www.transfermarkt.com.ar/club-deportivo-rincon/startseite/verein/83668"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/409_deportivo-rincon.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:gimnasia-concepcion-uruguay",
      "name": "Club Gimnasia y Esgrima (Concepción del Uruguay)",
      "province": "Entre Ríos",
      "city": "Concepción del Uruguay",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "14561",
      "tm_url": "https://www.transfermarkt.com.ar/club-gimnasia-y-esgrima-conc-del-uruguay-/startseite/verein/14561",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/edicion_2/equipos/177_Gimnasia-ER-.html",
        "https://www.transfermarkt.com.ar/club-gimnasia-y-esgrima-conc-del-uruguay-/startseite/verein/14561"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/edicion_2/equipos/177_Gimnasia-ER-.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:olimpo",
      "name": "Club Olimpo",
      "province": "Buenos Aires",
      "city": "Bahía Blanca",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "7468",
      "tm_url": "https://www.transfermarkt.com.ar/club-olimpo/startseite/verein/7468",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/pwa/equipos/76_olimpo.html",
        "https://www.transfermarkt.com.ar/club-olimpo/startseite/verein/7468"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/pwa/equipos/76_olimpo.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:guillermo-brown",
      "name": "Club Social y Atlético Guillermo Brown",
      "province": "Chubut",
      "city": "Puerto Madryn",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "14683",
      "tm_url": "https://www.transfermarkt.com.ar/csa-guillermo-brown/startseite/verein/14683",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/96_Guillermo-Brown.html",
        "https://www.transfermarkt.com.ar/csa-guillermo-brown/startseite/verein/14683"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/96_Guillermo-Brown.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:sol-de-mayo",
      "name": "Club Social y Deportivo Sol de Mayo",
      "province": "Río Negro",
      "city": "Viedma",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "63109",
      "tm_url": "https://www.transfermarkt.es/club-sol-de-mayo/startseite/verein/63109",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/297_Sol-de-Mayo.html",
        "https://www.transfermarkt.es/club-sol-de-mayo/startseite/verein/63109"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/297_Sol-de-Mayo.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:gimnasia-chivilcoy",
      "name": "Club Social, Cultural y Deportivo Gimnasia y Esgrima de Chivilcoy",
      "province": "Buenos Aires",
      "city": "Chivilcoy",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "123665",
      "tm_url": "https://www.transfermarkt.com.ar/club-gimnasia-y-esgrima-chivilcoy-/startseite/verein/123665",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://clubgimnasia.com.ar/",
        "https://www.transfermarkt.com.ar/club-gimnasia-y-esgrima-chivilcoy-/startseite/verein/123665"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://clubgimnasia.com.ar/"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:sol-america-formosa",
      "name": "Club Sol de América (Formosa)",
      "province": "Formosa",
      "city": "Formosa",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "23173",
      "tm_url": "https://www.transfermarkt.com.ar/club-sol-de-america-formosa-/startseite/verein/23173",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/286_Sol-de-America.html",
        "https://www.transfermarkt.com.ar/club-sol-de-america-formosa-/startseite/verein/23173"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/286_Sol-de-America.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-cordoba-sportivo-belgrano-san-francisco",
      "name": "Club Sportivo Belgrano",
      "province": "Córdoba",
      "city": "San Francisco",
      "league": "Liga Regional de Fútbol de San Francisco",
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "15414",
      "tm_url": "https://www.transfermarkt.com.ar/sportivo-belgrano-san-francisco-/startseite/verein/15414",
      "source_urls": [
        "https://sportivobelgrano.com.ar/contacto/",
        "https://www.afa.com.ar/es/posts/federal-a-hoy-tucuman-central-escobar-fc",
        "https://www.afa.com.ar/es/posts/federal-a-hoy-circulo-deportivo-costa-brava",
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://sportivobelgrano.com.ar/",
        "https://www.ligaregionalsanfrancisco.com.ar/contenidos/sportivo-belgrano-sf-45",
        "https://www.transfermarkt.com.ar/sportivo-belgrano-san-francisco-/startseite/verein/15414"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://sportivobelgrano.com.ar/"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:san-martin-formosa",
      "name": "Club Sportivo General San Martín (Formosa)",
      "province": "Formosa",
      "city": "Formosa",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "58993",
      "tm_url": "https://www.transfermarkt.com.ar/cs-general-san-martin-formosa-/startseite/verein/58993",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/229_san-martin-de-formosa.html",
        "https://www.transfermarkt.com.ar/cs-general-san-martin-formosa-/startseite/verein/58993"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/229_san-martin-de-formosa.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar-cordoba-atenas-rio-cuarto",
      "name": "Club Sportivo y Biblioteca Atenas",
      "province": "Córdoba",
      "city": "Río Cuarto",
      "league": "Liga Regional de Fútbol de Río Cuarto",
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "30084",
      "tm_url": "https://www.transfermarkt.com.ar/csb-atenas-rio-cuarto-/startseite/verein/30084",
      "source_urls": [
        "https://csybatenas.com/socios/",
        "https://csybatenas.com/historia/",
        "https://www.afa.com.ar/es/posts/torneo-federal-a-definidos-los-cruces-de-los-cuartos-de-final",
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/239_Atenas-de-Rio-Cuarto.html",
        "https://www.transfermarkt.com.ar/csb-atenas-rio-cuarto-/startseite/verein/30084"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/239_Atenas-de-Rio-Cuarto.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:villa-mitre",
      "name": "Club Villa Mitre",
      "province": "Buenos Aires",
      "city": "Bahía Blanca",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "12741",
      "tm_url": "https://www.transfermarkt.com.ar/villa-mitre/startseite/verein/12741",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/205_Villa-Mitre.html",
        "https://www.transfermarkt.com.ar/villa-mitre/startseite/verein/12741"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/205_Villa-Mitre.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:santamarina",
      "name": "Club y Biblioteca Ramón Santamarina",
      "province": "Buenos Aires",
      "city": "Tandil",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "9638",
      "tm_url": "https://www.transfermarkt.com.ar/cb-ramon-santamarina/startseite/verein/9638",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/171_Santamarina.html",
        "https://www.transfermarkt.com.ar/cb-ramon-santamarina/startseite/verein/9638"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/171_Santamarina.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:fadep",
      "name": "Fundación Amigos por el Deporte",
      "province": "Mendoza",
      "city": "Russell",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "92982",
      "tm_url": "https://www.transfermarkt.com.ar/fadep/startseite/verein/92982",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://par.maipu.gob.ar/budgets/39/investments/609",
        "https://www.transfermarkt.com.ar/fadep/startseite/verein/92982"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://par.maipu.gob.ar/budgets/39/investments/609"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:sportivo-las-parejas",
      "name": "Sportivo Atlético Club (Las Parejas)",
      "province": "Santa Fe",
      "city": "Las Parejas",
      "league": null,
      "competition_slug": "federal-a",
      "season": "2026",
      "tm_id": "14597",
      "tm_url": "https://www.transfermarkt.com.ar/sportivo-ac-las-parejas-/startseite/verein/14597",
      "source_urls": [
        "https://assets1.afa.com.ar/2026/BOLETINES/14-REGLAMENTO-FEDERAL-A-2026-14.04.26.pdf",
        "https://www.copaargentina.org/es/equipos/260_Sportivo-Las-Parejas.html",
        "https://www.transfermarkt.com.ar/sportivo-ac-las-parejas-/startseite/verein/14597"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_documentada",
      "geo_source_urls": [
        "https://www.copaargentina.org/es/equipos/260_Sportivo-Las-Parejas.html",
        "https://www.escobar.gob.ar/finde-en-escobar-juveactiva-talleres-y-propuestas-para-disfrutar-el-fin-de-semana/"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "geo_notes": "Localidad en ficha de Copa Argentina; provincia Santa Fe corroborada por comunicación oficial del Municipio de Escobar sobre la visita al club.",
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Federal A",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:arsenal-sarandi",
      "name": "Arsenal Fútbol Club",
      "province": "Buenos Aires",
      "city": "Sarandí",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "4673",
      "tm_url": "https://www.transfermarkt.com.ar/arsenal-fc/startseite/verein/4673",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/arsenal-fc/startseite/verein/4673"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:argentino-merlo",
      "name": "Club Atlético Argentino de Merlo",
      "province": "Buenos Aires",
      "city": "Merlo",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "17486",
      "tm_url": "https://www.transfermarkt.com.ar/ca-argentino-merlo-/startseite/verein/17486",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ca-argentino-merlo-/startseite/verein/17486"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:argentino-quilmes",
      "name": "Club Atlético Argentino de Quilmes",
      "province": "Buenos Aires",
      "city": "Quilmes",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "22603",
      "tm_url": "https://www.transfermarkt.com.ar/ca-argentino-de-quilmes/startseite/verein/22603",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ca-argentino-de-quilmes/startseite/verein/22603"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:brown-adrogue",
      "name": "Club Atlético Brown (Adrogué)",
      "province": "Buenos Aires",
      "city": "Adrogué",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "14681",
      "tm_url": "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:defensores-unidos",
      "name": "Club Atlético Defensores Unidos",
      "province": "Buenos Aires",
      "city": "Zárate",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "24749",
      "tm_url": "https://www.transfermarkt.com.ar/ca-defensores-unidos-zarate-/startseite/verein/24749",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ca-defensores-unidos-zarate-/startseite/verein/24749"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:excursionistas",
      "name": "Club Atlético Excursionistas",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Buenos Aires",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "19632",
      "tm_url": "https://www.transfermarkt.com.ar/ca-excursionistas/startseite/verein/19632",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ca-excursionistas/startseite/verein/19632"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:ituzaingo",
      "name": "Club Atlético Ituzaingó",
      "province": "Buenos Aires",
      "city": "Ituzaingó",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "22501",
      "tm_url": "https://www.transfermarkt.com.ar/club-atletico-ituzaingo/startseite/verein/22501/saison_id/2022",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-atletico-ituzaingo/startseite/verein/22501/saison_id/2022"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:camioneros",
      "name": "Club Atlético Social y Deportivo Camioneros",
      "province": "Buenos Aires",
      "city": "Esteban Echeverría",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "52852",
      "tm_url": "https://www.transfermarkt.com.ar/casd-camioneros/startseite/verein/52852",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.clubcamioneros.com.ar/ladeportiva/index.php/contacto/",
        "https://www.clubcamioneros.com.ar/ladeportiva/index.php/2026/02/trabajo-integral-en-todas-las-categorias/",
        "https://www.transfermarkt.com.ar/casd-camioneros/startseite/verein/52852"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "predio_deportivo_estable_del_club",
      "geo_source_urls": [
        "https://www.clubcamioneros.com.ar/ladeportiva/index.php/contacto/",
        "https://www.clubcamioneros.com.ar/ladeportiva/index.php/2026/02/trabajo-integral-en-todas-las-categorias/"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "city_precision": "partido",
      "geo_notes": "Se conserva Esteban Echeverría, denominación publicada por el club para su predio; es un partido. No se utiliza la oficina administrativa de CABA ni el origen General Rodríguez que figura en Copa Argentina.",
      "institutional_city": "Buenos Aires",
      "institutional_province": "Ciudad Autónoma de Buenos Aires",
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:talleres-remedios-escalada",
      "name": "Club Atlético Talleres (Remedios de Escalada)",
      "province": "Buenos Aires",
      "city": "Remedios de Escalada",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "14519",
      "tm_url": "https://www.transfermarkt.com.ar/ca-talleres-remedios-de-escalada-/startseite/verein/14519",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ca-talleres-remedios-de-escalada-/startseite/verein/14519"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:villa-san-carlos",
      "name": "Club Atlético Villa San Carlos",
      "province": "Buenos Aires",
      "city": "Berisso",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "19517",
      "tm_url": "https://www.transfermarkt.com.ar/ca-villa-san-carlos/startseite/verein/19517",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ca-villa-san-carlos/startseite/verein/19517"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:comunicaciones",
      "name": "Club Comunicaciones",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Buenos Aires",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "15377",
      "tm_url": "https://www.transfermarkt.com.ar/club-comunicaciones/startseite/verein/15377",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-comunicaciones/startseite/verein/15377"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:deportivo-armenio",
      "name": "Club Deportivo Armenio",
      "province": "Buenos Aires",
      "city": "Ingeniero Maschwitz",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "13264",
      "tm_url": "https://www.transfermarkt.com.ar/club-deportivo-armenio/startseite/verein/13264",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-deportivo-armenio/startseite/verein/13264"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "institutional_city": "Buenos Aires",
      "institutional_province": "Ciudad Autónoma de Buenos Aires",
      "geo_notes": "La sede administrativa publicada en AFA está en CABA; para scouting se utiliza la sede deportiva estable publicada en el mismo directorio.",
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:uai-urquiza",
      "name": "Club Deportivo UAI Urquiza",
      "province": "Buenos Aires",
      "city": "Villa Lynch",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "45560",
      "tm_url": "https://www.transfermarkt.com.ar/cd-uai-urquiza/startseite/verein/45560/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/cd-uai-urquiza/startseite/verein/45560/saison_id/2025"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "institutional_city": "Buenos Aires",
      "institutional_province": "Ciudad Autónoma de Buenos Aires",
      "geo_notes": "La sede administrativa publicada en AFA está en CABA; para scouting se utiliza la sede deportiva estable publicada en el mismo directorio.",
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:deportivo-laferrere",
      "name": "Club Social y Cultural Deportivo Laferrere",
      "province": "Buenos Aires",
      "city": "Gregorio de Laferrere",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "19636",
      "tm_url": "https://www.transfermarkt.com.ar/csc-deportivo-laferrere/startseite/verein/19636/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/csc-deportivo-laferrere/startseite/verein/19636/saison_id/2025"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:flandria",
      "name": "Club Social y Deportivo Flandria",
      "province": "Buenos Aires",
      "city": "Jáuregui",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "13341",
      "tm_url": "https://www.transfermarkt.com.ar/csd-flandria/startseite/verein/13341",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/csd-flandria/startseite/verein/13341"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:liniers-san-justo",
      "name": "Club Social y Deportivo Liniers",
      "province": "Buenos Aires",
      "city": "San Justo",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "98564",
      "tm_url": "https://www.transfermarkt.com.ar/club-social-y-deportivo-liniers/startseite/verein/98564/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-social-y-deportivo-liniers/startseite/verein/98564/saison_id/2025"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:deportivo-merlo",
      "name": "Club Social y Deportivo Merlo",
      "province": "Buenos Aires",
      "city": "Parque San Martín",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "19529",
      "tm_url": "https://www.transfermarkt.com.ar/club-social-y-deportivo-merlo/startseite/verein/19529",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-social-y-deportivo-merlo/startseite/verein/19529"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "city_precision": "localidad",
      "geo_notes": "Parque San Martín, partido de Merlo, según secretaría y estadio publicados por AFA.",
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:san-martin-burzaco",
      "name": "Club Social y Deportivo San Martín (Burzaco)",
      "province": "Buenos Aires",
      "city": "Burzaco",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "28142",
      "tm_url": "https://www.transfermarkt.com.ar/csd-san-martin-burzaco-/startseite/verein/28142",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/csd-san-martin-burzaco-/startseite/verein/28142"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:dock-sud",
      "name": "Club Sportivo Dock Sud",
      "province": "Buenos Aires",
      "city": "Dock Sud",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "14675",
      "tm_url": "https://www.transfermarkt.com.ar/cs-dock-sud/startseite/verein/14675",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/cs-dock-sud/startseite/verein/14675"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:sportivo-italiano",
      "name": "Club Sportivo Italiano",
      "province": "Buenos Aires",
      "city": "Ciudad Evita",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "15378",
      "tm_url": "https://www.transfermarkt.com.ar/club-sportivo-italiano/startseite/verein/15378",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-sportivo-italiano/startseite/verein/15378"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:villa-dalmine",
      "name": "Club Villa Dálmine",
      "province": "Buenos Aires",
      "city": "Campana",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "8356",
      "tm_url": "https://www.transfermarkt.com.ar/club-villa-dalmine/startseite/verein/8356",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-villa-dalmine/startseite/verein/8356"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:real-pilar",
      "name": "Real Pilar Fútbol Club",
      "province": "Buenos Aires",
      "city": "Pilar",
      "league": null,
      "competition_slug": "primera-b",
      "season": "2026",
      "tm_id": "75858",
      "tm_url": "https://www.transfermarkt.com.ar/real-pilar/startseite/verein/75858/saison_id/2025",
      "source_urls": [
        "https://www.afa.com.ar/Sitio/posts/primera-b-se-realizo-el-sorteo-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/real-pilar/startseite/verein/75858/saison_id/2025"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_verification_scope": "club_identity_only; season_participation_from_afa",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera B",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:berazategui",
      "name": "Asociación Deportiva Berazategui",
      "province": "Buenos Aires",
      "city": "Berazategui",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "22134",
      "tm_url": "https://www.transfermarkt.com.ar/ad-berazategui/startseite/verein/22134",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ad-berazategui/startseite/verein/22134"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:justo-jose-urquiza",
      "name": "Asociación Social y Deportiva Justo José de Urquiza",
      "province": "Buenos Aires",
      "city": "El Libertador",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "18676",
      "tm_url": "https://www.transfermarkt.com.ar/asd-justo-jose-de-urquiza/startseite/verein/18676",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/asd-justo-jose-de-urquiza/startseite/verein/18676"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "institutional_city": "Caseros",
      "institutional_province": "Buenos Aires",
      "geo_notes": "Se utiliza El Libertador, localidad del estadio propio; AFA publica la secretaría en Caseros.",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:canuelas",
      "name": "Cañuelas Fútbol Club",
      "province": "Buenos Aires",
      "city": "Cañuelas",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "14391",
      "tm_url": "https://www.transfermarkt.com.ar/canuelas-futbol-club/startseite/verein/14391",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/canuelas-futbol-club/startseite/verein/14391"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:centro-espanol",
      "name": "Centro Social y Recreativo Español",
      "province": "Buenos Aires",
      "city": "Villa Sarmiento",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "78190",
      "tm_url": "https://www.transfermarkt.com.ar/centro-sr-espanol/startseite/verein/78190",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/centro-sr-espanol/startseite/verein/78190"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_institucional_afa_sin_cancha_propia_verificada",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "geo_notes": "Se utiliza Villa Sarmiento, sede institucional AFA. No se atribuye como ciudad una cancha prestada.",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:argentino-rosario",
      "name": "Club Atlético Argentino (Rosario)",
      "province": "Santa Fe",
      "city": "Rosario",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "14552",
      "tm_url": "https://www.transfermarkt.com.ar/club-atletico-argentino-de-rosario/startseite/verein/14552",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-atletico-argentino-de-rosario/startseite/verein/14552"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:atlas",
      "name": "Club Atlético Atlas",
      "province": "Buenos Aires",
      "city": "General Rodríguez",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "25673",
      "tm_url": "https://www.transfermarkt.com.ar/ca-atlas/startseite/verein/25673",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ca-atlas/startseite/verein/25673"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "institutional_city": "Buenos Aires",
      "institutional_province": "Ciudad Autónoma de Buenos Aires",
      "geo_notes": "La sede administrativa publicada en AFA está en CABA; para scouting se utiliza la sede deportiva estable publicada en el mismo directorio.",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:central-cordoba-rosario",
      "name": "Club Atlético Central Córdoba (Rosario)",
      "province": "Santa Fe",
      "city": "Rosario",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "14523",
      "tm_url": "https://www.transfermarkt.com.ar/ca-central-cordoba-rosario-/startseite/verein/14523",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ca-central-cordoba-rosario-/startseite/verein/14523"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:claypole",
      "name": "Club Atlético Claypole",
      "province": "Buenos Aires",
      "city": "Claypole",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "78158",
      "tm_url": "https://www.transfermarkt.com.ar/ca-claypole/kader/verein/78158",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ca-claypole/kader/verein/78158"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:deportivo-paraguayo",
      "name": "Club Atlético Deportivo Paraguayo",
      "province": "Buenos Aires",
      "city": "González Catán",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "18678",
      "tm_url": "https://www.transfermarkt.com.ar/club-atletico-deportivo-paraguayo/startseite/verein/18678",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://ri.conicet.gov.ar/bitstream/handle/11336/229747/CONICET_Digital_Nro.203400f5-4a7f-45a2-8efc-ac54a1368215_B.pdf?isAllowed=y&sequence=2",
        "https://www.transfermarkt.com.ar/club-atletico-deportivo-paraguayo/startseite/verein/18678"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_documentada_investigacion_conicet",
      "geo_source_urls": [
        "https://ri.conicet.gov.ar/bitstream/handle/11336/229747/CONICET_Digital_Nro.203400f5-4a7f-45a2-8efc-ac54a1368215_B.pdf?isAllowed=y&sequence=2"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "institutional_city": "Buenos Aires",
      "institutional_province": "Ciudad Autónoma de Buenos Aires",
      "geo_notes": "Sede deportiva en Villa Scasso, González Catán; sede social en CABA. La fuente de CONICET documenta el predio propio.",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:fenix",
      "name": "Club Atlético Fénix",
      "province": "Buenos Aires",
      "city": "Marcos Paz",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "18087",
      "tm_url": "https://www.transfermarkt.com.ar/ca-fenix/startseite/verein/18087",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://marcospaz.gov.ar/noticias/item/10041-reuni%C3%B3n-de-trabajo-con-autoridades-del-club-f%C3%A9nix.html",
        "https://www.transfermarkt.com.ar/ca-fenix/startseite/verein/18087"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "radicacion_deportiva_confirmada_por_municipio",
      "geo_source_urls": [
        "https://marcospaz.gov.ar/noticias/item/10041-reuni%C3%B3n-de-trabajo-con-autoridades-del-club-f%C3%A9nix.html"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "geo_notes": "El Municipio de Marcos Paz confirma la instalación del club y construcción de su estadio desde finales de 2024; no se afirma que el estadio esté habilitado o terminado. El domicilio administrativo AFA continúa en CABA.",
      "institutional_city": "Buenos Aires",
      "institutional_province": "Ciudad Autónoma de Buenos Aires",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:general-lamadrid",
      "name": "Club Atlético General Lamadrid",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Buenos Aires",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "19633",
      "tm_url": "https://www.transfermarkt.com.ar/ca-general-lamadrid/startseite/verein/19633",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ca-general-lamadrid/startseite/verein/19633"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:lugano",
      "name": "Club Atlético Lugano",
      "province": "Buenos Aires",
      "city": "Tapiales",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "78186",
      "tm_url": "https://www.transfermarkt.com.ar/club-atletico-lugano/startseite/verein/78186/saison_id/2012",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-atletico-lugano/startseite/verein/78186/saison_id/2012"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "institutional_city": "Buenos Aires",
      "institutional_province": "Ciudad Autónoma de Buenos Aires",
      "geo_notes": "La sede administrativa publicada en AFA está en CABA; para scouting se utiliza la sede deportiva estable publicada en el mismo directorio.",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:puerto-nuevo",
      "name": "Club Atlético Puerto Nuevo",
      "province": "Buenos Aires",
      "city": "Campana",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "78188",
      "tm_url": "https://www.transfermarkt.com.ar/club-atletico-puerto-nuevo/startseite/verein/78188/saison_id/2021",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-atletico-puerto-nuevo/startseite/verein/78188/saison_id/2021"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:victoriano-arenas",
      "name": "Club Atlético Victoriano Arenas",
      "province": "Buenos Aires",
      "city": "Valentín Alsina",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "75690",
      "tm_url": "https://www.transfermarkt.com.ar/ca-victoriano-arenas/startseite/verein/75690",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/ca-victoriano-arenas/startseite/verein/75690"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "localidad_institucional_publicada_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "geo_notes": "Secretaría en Valentín Alsina; AFA describe la ubicación del estadio como Avellaneda. Se conserva la localidad institucional, sin tratar el municipio del estadio como una ciudad nueva.",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:defensores-cambaceres",
      "name": "Club Defensores de Cambaceres",
      "province": "Buenos Aires",
      "city": "Ensenada",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "14676",
      "tm_url": "https://www.transfermarkt.com.ar/club-defensores-de-cambaceres/startseite/verein/14676",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-defensores-de-cambaceres/startseite/verein/14676"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:juventud-unida-san-miguel",
      "name": "Club Deportivo y Social Juventud Unida",
      "province": "Buenos Aires",
      "city": "San Miguel",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "31553",
      "tm_url": "https://www.transfermarkt.com.ar/cds-juventud-unida-san-miguel-/startseite/verein/31553",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/cds-juventud-unida-san-miguel-/startseite/verein/31553"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:leandro-n-alem",
      "name": "Club Deportivo, Mutual y Biblioteca Popular Leandro N. Alem",
      "province": "Buenos Aires",
      "city": "General Rodríguez",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "12180",
      "tm_url": "https://www.transfermarkt.com.ar/cdm-leandro-n-alem/startseite/verein/12180",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/cdm-leandro-n-alem/startseite/verein/12180"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:el-porvenir",
      "name": "Club El Porvenir",
      "province": "Buenos Aires",
      "city": "Lanús Oeste",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "12362",
      "tm_url": "https://www.transfermarkt.com.ar/club-el-porvenir/startseite/verein/12362",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-el-porvenir/startseite/verein/12362"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:leones-rosario",
      "name": "Club Leones de Rosario Fútbol Club",
      "province": "Santa Fe",
      "city": "Alvear",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "136678",
      "tm_url": "https://www.transfermarkt.es/leones-de-rosario-fc/startseite/verein/136678",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.es/leones-de-rosario-fc/startseite/verein/136678",
        "https://www.santafe.gob.ar/tramites/igpj-tramiteweb/entidades/27817/imprimir"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "institutional_city": "Rosario",
      "institutional_province": "Santa Fe",
      "geo_notes": "Se usa Alvear, sede deportiva publicada por AFA. Registro provincial de personas jurídicas conserva sede administrativa en Rosario. No se usa el estadio temporal de San Nicolás.",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:lujan",
      "name": "Club Luján",
      "province": "Buenos Aires",
      "city": "Luján",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "41636",
      "tm_url": "https://www.transfermarkt.com.ar/club-lujan/startseite/verein/41636",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-lujan/startseite/verein/41636"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:mercedes",
      "name": "Club Mercedes",
      "province": "Buenos Aires",
      "city": "Mercedes",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "119449",
      "tm_url": "https://www.transfermarkt.com.ar/club-mercedes/kader/verein/119449",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-mercedes/kader/verein/119449"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:muniz",
      "name": "Club Social Cultural y Deportivo Muñiz",
      "province": "Buenos Aires",
      "city": "Muñiz",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "95540",
      "tm_url": "https://www.transfermarkt.com.ar/club-social-cultural-y-deportivo-muniz/kader/verein/95540/sort/trikotNumber.desc",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-social-cultural-y-deportivo-muniz/kader/verein/95540/sort/trikotNumber.desc"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_institucional_afa_sin_cancha_propia_verificada",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "geo_notes": "Se utiliza Muñiz, sede institucional AFA. No se atribuye como ciudad una cancha prestada.",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:central-ballester",
      "name": "Club Social y Deportivo Central Ballester",
      "province": "Buenos Aires",
      "city": "José León Suárez",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "54651",
      "tm_url": "https://www.transfermarkt.com.ar/csd-central-ballester/startseite/verein/54651",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/csd-central-ballester/startseite/verein/54651"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:yupanqui",
      "name": "Club Social y Deportivo Yupanqui",
      "province": "Buenos Aires",
      "city": "Ciudad Evita",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "27960",
      "tm_url": "https://www.transfermarkt.com.ar/csd-yupanqui/startseite/verein/27960",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/csd-yupanqui/startseite/verein/27960"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "institutional_city": "Buenos Aires",
      "institutional_province": "Ciudad Autónoma de Buenos Aires",
      "geo_notes": "La sede administrativa publicada en AFA está en CABA; para scouting se utiliza la sede deportiva estable publicada en el mismo directorio.",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:deportivo-espanol",
      "name": "Club Social, Deportivo y Cultural Español de la República Argentina",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Buenos Aires",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "14546",
      "tm_url": "https://www.transfermarkt.com.ar/club-deportivo-espanol/startseite/verein/14546",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-deportivo-espanol/startseite/verein/14546"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:sportivo-barracas",
      "name": "Club Sportivo Barracas",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Buenos Aires",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "20696",
      "tm_url": "https://www.transfermarkt.com.ar/club-sportivo-barracas/startseite/verein/20696",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-sportivo-barracas/startseite/verein/20696"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_institucional_afa_sin_cancha_propia_verificada",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "geo_notes": "Barracas, Ciudad Autónoma de Buenos Aires; se mantiene la sede social, sin atribuir una cancha prestada como domicilio del club.",
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:estrella-del-sur",
      "name": "Escuela de Recreación y Deportes Estrella del Sur",
      "province": "Buenos Aires",
      "city": "Alejandro Korn",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "123820",
      "tm_url": "https://www.transfermarkt.com.ar/club-estrella-del-sur/startseite/verein/123820",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/club-estrella-del-sur/startseite/verein/123820"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    },
    {
      "source_key": "ar:club:sacachispas",
      "name": "Sacachispas Fútbol Club",
      "province": "Ciudad Autónoma de Buenos Aires",
      "city": "Buenos Aires",
      "league": null,
      "competition_slug": "primera-c",
      "season": "2026",
      "tm_id": "25374",
      "tm_url": "https://www.transfermarkt.com.ar/sacachispas-fc/startseite/verein/25374",
      "source_urls": [
        "https://www.afa.com.ar/en/posts/primera-c-fixture-para-la-temporada-2026",
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025",
        "https://www.transfermarkt.com.ar/sacachispas-fc/startseite/verein/25374"
      ],
      "source_method": "manual_official_sources_with_transfermarkt_index_reference",
      "verified_at": "2026-10-29T20:51:07Z",
      "geo_verified": true,
      "geo_basis": "sede_deportiva_estable_en_directorio_afa",
      "geo_source_urls": [
        "https://www.afa.com.ar/11169/posts/clubes-afiliados-2025"
      ],
      "reference_scope": "primer_equipo_masculino",
      "participation_verified": true,
      "tm_reference_scope": "identidad_del_club; la participación 2026 se verifica con AFA",
      "competition_name": "Primera C",
      "division": null,
      "source": "official_reference",
      "publication_status": "published"
    }
  ],
  "players": [
    {
      "source_key": "ar:player-candidate:brown-adrogue:carlos-aguirre:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Carlos",
      "last_name": "Aguirre",
      "full_name": "Carlos Aguirre",
      "source_position": "Defensa central",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Defensa central",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:bruno-baez:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Bruno",
      "last_name": "Báez",
      "full_name": "Bruno Báez",
      "source_position": "Delantero centro",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Delantero centro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:jonatan-bogado:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Jonatan",
      "last_name": "Bogado",
      "full_name": "Jonatan Bogado",
      "source_position": "Lateral derecho",
      "position": "Lateral",
      "sector": "derecha",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Lateral derecho",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:juan-bourquin:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Juan",
      "last_name": "Bourquín",
      "full_name": "Juan Bourquín",
      "source_position": "Portero",
      "position": "Arquero",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Portero",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:valentin-cabrejas:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Valentín",
      "last_name": "Cabrejas",
      "full_name": "Valentín Cabrejas",
      "source_position": "Lateral izquierdo",
      "position": "Lateral",
      "sector": "izquierda",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Lateral izquierdo",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:dante-cardozo:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Dante",
      "last_name": "Cardozo",
      "full_name": "Dante Cardozo",
      "source_position": "Defensa central",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Defensa central",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:fabrizzio-carrizo:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Fabrizzio",
      "last_name": "Carrizo",
      "full_name": "Fabrizzio Carrizo",
      "source_position": "Pivote",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Pivote",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:alexis-castano:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Alexis",
      "last_name": "Castaño",
      "full_name": "Alexis Castaño",
      "source_position": "Mediocentro",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediocentro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:marcelo-cerulo:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Marcelo",
      "last_name": "Cerulo",
      "full_name": "Marcelo Cerulo",
      "source_position": "Delantero centro",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Delantero centro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:lucas-cesare:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Lucas",
      "last_name": "Cesare",
      "full_name": "Lucas Cesare",
      "source_position": "Lateral derecho",
      "position": "Lateral",
      "sector": "derecha",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Lateral derecho",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:facundo-ferrario:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Facundo",
      "last_name": "Ferrario",
      "full_name": "Facundo Ferrario",
      "source_position": "Mediocentro ofensivo",
      "position": null,
      "sector": "no_especificado",
      "position_mapping_status": "pending_manual_review",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediocentro ofensivo",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:victor-galeano:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Víctor",
      "last_name": "Galeano",
      "full_name": "Víctor Galeano",
      "source_position": "Extremo derecho",
      "position": "Delantero Extremo",
      "sector": "derecha",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Extremo derecho",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:lucas-galvan:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Lucas",
      "last_name": "Galván",
      "full_name": "Lucas Galván",
      "source_position": "Mediocentro ofensivo",
      "position": null,
      "sector": "no_especificado",
      "position_mapping_status": "pending_manual_review",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediocentro ofensivo",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:sebastian-giovini:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Sebastián",
      "last_name": "Giovini",
      "full_name": "Sebastián Giovini",
      "source_position": "Portero",
      "position": "Arquero",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Portero",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:agustin-gonzalez:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Agustín",
      "last_name": "González",
      "full_name": "Agustín González",
      "source_position": "Extremo derecho",
      "position": "Delantero Extremo",
      "sector": "derecha",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Extremo derecho",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:luciano-gonzalez:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Luciano",
      "last_name": "González",
      "full_name": "Luciano González",
      "source_position": "Centrocampista",
      "position": null,
      "sector": "no_especificado",
      "position_mapping_status": "pending_manual_review",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Centrocampista",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:brahian-guayquinao:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Brahian",
      "last_name": "Guayquinao",
      "full_name": "Brahian Guayquinao",
      "source_position": "Pivote",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Pivote",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:braian-guerrero:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Braian",
      "last_name": "Guerrero",
      "full_name": "Braian Guerrero",
      "source_position": "Lateral izquierdo",
      "position": "Lateral",
      "sector": "izquierda",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Lateral izquierdo",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:lucas-irusta:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Lucas",
      "last_name": "Irusta",
      "full_name": "Lucas Irusta",
      "source_position": "Defensa central",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Defensa central",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:gaston-luraschi:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Gastón",
      "last_name": "Luraschi",
      "full_name": "Gastón Luraschi",
      "source_position": "Extremo izquierdo",
      "position": "Delantero Extremo",
      "sector": "izquierda",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Extremo izquierdo",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:nicolas-meaurio:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Nicolás",
      "last_name": "Meaurio",
      "full_name": "Nicolás Meaurio",
      "source_position": "Mediapunta",
      "position": null,
      "sector": "no_especificado",
      "position_mapping_status": "pending_manual_review",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediapunta",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:adriel-ortiz:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Adriel",
      "last_name": "Ortíz",
      "full_name": "Adriel Ortíz",
      "source_position": "Lateral izquierdo",
      "position": "Lateral",
      "sector": "izquierda",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Lateral izquierdo",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:octavio-padovani:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Octavio",
      "last_name": "Padovani",
      "full_name": "Octavio Padovani",
      "source_position": "Delantero centro",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Delantero centro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:tomas-patrizio:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Tomás",
      "last_name": "Patrizio",
      "full_name": "Tomás Patrizio",
      "source_position": "Mediocentro",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediocentro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:mariano-pieres:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Mariano",
      "last_name": "Pieres",
      "full_name": "Mariano Pieres",
      "source_position": "Defensa central",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Defensa central",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:juan-reboiras:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Juan",
      "last_name": "Reboiras",
      "full_name": "Juan Reboiras",
      "source_position": "Mediocentro",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediocentro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:elian-robles:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Elián",
      "last_name": "Robles",
      "full_name": "Elián Robles",
      "source_position": "Mediocentro",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediocentro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:santiago-rodriguez:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Santiago",
      "last_name": "Rodríguez",
      "full_name": "Santiago Rodríguez",
      "source_position": "Pivote",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Pivote",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:juan-ignacio-silva:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Juan Ignacio",
      "last_name": "Silva",
      "full_name": "Juan Ignacio Silva",
      "source_position": "Pivote",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Pivote",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:matias-sproat:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Matías",
      "last_name": "Sproat",
      "full_name": "Matías Sproat",
      "source_position": "Extremo derecho",
      "position": "Delantero Extremo",
      "sector": "derecha",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Extremo derecho",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:alan-visco:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Alan",
      "last_name": "Visco",
      "full_name": "Alan Visco",
      "source_position": "Extremo derecho",
      "position": "Delantero Extremo",
      "sector": "derecha",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Extremo derecho",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:brown-adrogue:matias-wysocki:2026",
      "club_source_key": "ar:club:brown-adrogue",
      "competition_slug": "primera-b",
      "season": "2026",
      "category": "Primera",
      "first_name": "Matías",
      "last_name": "Wysocki",
      "full_name": "Matías Wysocki",
      "source_position": "Portero",
      "position": "Arquero",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/ca-brown-adrogue-/startseite/verein/14681"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "4 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Atlético Brown (Adrogué)",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Portero",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 4 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "roster_name": "Ignacio Alastra",
      "tm_player_id": "1378149",
      "tm_url": "https://www.transfermarkt.com/ignacio-alastra/profil/spieler/1378149",
      "full_name": "Ignacio Alastra",
      "full_name_basis": "profile_display_name",
      "position_original": "Right Winger",
      "current_club_text": "CA Talleres II",
      "primary_tm_club_id": "55574",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/ignacio-alastra/profil/spieler/1378149"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_search",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": false,
      "exclude_from_current_talleres_import": false,
      "category_review_required": true,
      "secondary_club_text": "CA Talleres",
      "secondary_tm_club_id": "3938",
      "category": "Primera",
      "category_note": "El perfil tiene CA Talleres II como club principal y CA Talleres como segundo club. Revisar la categoría antes de un registro que sólo admite una.",
      "roster_match_status": "talleres_institution_observed_in_indexed_individual_profile",
      "source_key": "manual-talleres-2026-tm-1378149",
      "tm_id": "1378149",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Ignacio",
      "last_name": "Alastra",
      "season": "2026",
      "position": "Delantero Extremo",
      "sector": "derecha",
      "current_roster_verified": false,
      "official_roster_source_urls": [],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "pending_current_roster_review",
      "conflict_note": "El perfil indexado identifica el club, pero no se corroboró pertenencia actual en las fuentes oficiales recientes consultadas. Esto no afirma que haya dejado el club.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club."
    },
    {
      "roster_name": "Gabriel Báez",
      "tm_player_id": "376858",
      "tm_url": "https://www.transfermarkt.com/gabriel-baez/profil/spieler/376858",
      "full_name": "Gabriel Alejandro Báez Corradi",
      "full_name_basis": "home_country_name",
      "position_original": "Left-Back",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/gabriel-baez/profil/spieler/376858",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 4,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-376858",
      "tm_id": "376858",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Gabriel Alejandro",
      "last_name": "Báez Corradi",
      "season": "2026",
      "category": "Primera",
      "position": "Lateral",
      "sector": "izquierda",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Santino Barbi",
      "tm_player_id": "1197308",
      "tm_url": "https://www.transfermarkt.com/santino-barbi/profil/spieler/1197308",
      "full_name": "Santino Barbi",
      "full_name_basis": "profile_display_name",
      "position_original": "Goalkeeper",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/santino-barbi/profil/spieler/1197308",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-1197308",
      "tm_id": "1197308",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Santino",
      "last_name": "Barbi",
      "season": "2026",
      "category": "Primera",
      "position": "Arquero",
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Giovanni Baroni",
      "tm_player_id": "1265841",
      "tm_url": "https://www.transfermarkt.com/giovanni-baroni/profil/spieler/1265841",
      "full_name": "Giovanni Emir Baroni",
      "full_name_basis": "home_country_name",
      "position_original": "Attacking Midfield",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/giovanni-baroni/profil/spieler/1265841",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-1265841",
      "tm_id": "1265841",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Giovanni Emir",
      "last_name": "Baroni",
      "season": "2026",
      "category": "Primera",
      "position": null,
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Bruno Barticciotto",
      "tm_player_id": "737920",
      "tm_url": "https://www.transfermarkt.com/bruno-barticciotto/profil/spieler/737920",
      "full_name": "Bruno Barticciotto Di Bartolo",
      "full_name_basis": "home_country_name",
      "position_original": "Centre-Forward",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/bruno-barticciotto/profil/spieler/737920",
        "https://www.clubtalleres.com.ar/plantel-profesional/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-737920",
      "tm_id": "737920",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Bruno",
      "last_name": "Barticciotto Di Bartolo",
      "season": "2026",
      "category": "Primera",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Mateo Cáceres",
      "tm_player_id": "907835",
      "tm_url": "https://www.transfermarkt.com/mateo-caceres/profil/spieler/907835",
      "full_name": "Mateo Valentín Cáceres",
      "full_name_basis": "home_country_name",
      "position_original": "Central Midfield",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/mateo-caceres/profil/spieler/907835",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 4,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-907835",
      "tm_id": "907835",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Mateo Valentín",
      "last_name": "Cáceres",
      "season": "2026",
      "category": "Primera",
      "position": "Volante central",
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Matías Catalán",
      "tm_player_id": "237051",
      "tm_url": "https://www.transfermarkt.com/matias-catalan/profil/spieler/237051",
      "full_name": "Matías Ezequiel Catalán Echevarría",
      "full_name_basis": "home_country_name",
      "position_original": "Centre-Back",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/matias-catalan/profil/spieler/237051",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-237051",
      "tm_id": "237051",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Matías Ezequiel",
      "last_name": "Catalán Echevarría",
      "season": "2026",
      "category": "Primera",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Emiliano Chiavassa",
      "tm_player_id": "1296331",
      "tm_url": "https://www.transfermarkt.com/emiliano-chiavassa/profil/spieler/1296331",
      "full_name": "Emiliano Miguel Chiavassa",
      "full_name_basis": "home_country_name",
      "position_original": "Right Winger",
      "current_club_text": "CA Talleres II",
      "primary_tm_club_id": "55574",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/emiliano-chiavassa/profil/spieler/1296331",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "secondary_club_text": "CA Talleres",
      "secondary_tm_club_id": "3938",
      "category": "Primera",
      "category_note": "El perfil tiene CA Talleres II como club principal y CA Talleres como segundo club. Revisar la categoría antes de un registro que sólo admite una.",
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-1296331",
      "tm_id": "1296331",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Emiliano Miguel",
      "last_name": "Chiavassa",
      "season": "2026",
      "position": "Delantero Extremo",
      "sector": "derecha",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "category_resolution": "Aunque Transfermarkt identifica a Talleres II como club principal, la fuente actual del club lo incluye en el plantel profesional de Primera.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Franco Cristaldo",
      "tm_player_id": "332259",
      "tm_url": "https://www.transfermarkt.com/franco-cristaldo/profil/spieler/332259",
      "full_name": "Franco Cristaldo",
      "full_name_basis": "profile_display_name",
      "position_original": "Attacking Midfield",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/franco-cristaldo/profil/spieler/332259",
        "https://www.clubtalleres.com.ar/plantel-profesional/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-332259",
      "tm_id": "332259",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Franco",
      "last_name": "Cristaldo",
      "season": "2026",
      "category": "Primera",
      "position": null,
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Valentín Dávila",
      "tm_player_id": "1280274",
      "tm_url": "https://www.transfermarkt.com/valentin-davila/profil/spieler/1280274",
      "full_name": "Valentín Dávila",
      "full_name_basis": "profile_display_name",
      "position_original": "Centre-Forward",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/valentin-davila/profil/spieler/1280274",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-1280274",
      "tm_id": "1280274",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Valentín",
      "last_name": "Dávila",
      "season": "2026",
      "category": "Primera",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Valentín Depietri",
      "tm_player_id": "697056",
      "tm_url": "https://www.transfermarkt.com/valentin-depietri/profil/spieler/697056",
      "full_name": "Valentín Depietri",
      "full_name_basis": "profile_display_name",
      "position_original": "Left Winger",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/valentin-depietri/profil/spieler/697056",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-697056",
      "tm_id": "697056",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Valentín",
      "last_name": "Depietri",
      "season": "2026",
      "category": "Primera",
      "position": "Delantero Extremo",
      "sector": "izquierda",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Santiago Fernández",
      "tm_player_id": "1106217",
      "tm_url": "https://www.transfermarkt.com/santiago-fernandez/profil/spieler/1106217",
      "full_name": "Santiago Abel Fernández",
      "full_name_basis": "home_country_name",
      "position_original": "Centre-Back",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/santiago-fernandez/profil/spieler/1106217",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-1106217",
      "tm_id": "1106217",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Santiago Abel",
      "last_name": "Fernández",
      "season": "2026",
      "category": "Primera",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Lucio Ferrari",
      "tm_player_id": "1245894",
      "tm_url": "https://www.transfermarkt.com/lucio-ferrari/profil/spieler/1245894",
      "full_name": "Lucio Ferrari",
      "full_name_basis": "profile_display_name",
      "position_original": "Centre-Back",
      "current_club_text": "CA Talleres II",
      "primary_tm_club_id": "55574",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/lucio-ferrari/profil/spieler/1245894"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_search",
      "index_crawl_age_months_reported": 5,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": false,
      "exclude_from_current_talleres_import": false,
      "category_review_required": true,
      "secondary_club_text": "CA Talleres",
      "secondary_tm_club_id": "3938",
      "category": "Primera",
      "category_note": "El perfil tiene CA Talleres II como club principal y CA Talleres como segundo club. Revisar la categoría antes de un registro que sólo admite una.",
      "roster_match_status": "talleres_institution_observed_in_indexed_individual_profile",
      "source_key": "manual-talleres-2026-tm-1245894",
      "tm_id": "1245894",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Lucio",
      "last_name": "Ferrari",
      "season": "2026",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "current_roster_verified": false,
      "official_roster_source_urls": [],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "pending_current_roster_review",
      "conflict_note": "El perfil indexado identifica el club, pero no se corroboró pertenencia actual en las fuentes oficiales recientes consultadas. Esto no afirma que haya dejado el club.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club."
    },
    {
      "roster_name": "Jeremías Florentín",
      "tm_player_id": "1197896",
      "tm_url": "https://www.transfermarkt.com/jeremias-florentin/profil/spieler/1197896",
      "full_name": "Jeremías Nisael Florentín",
      "full_name_basis": "home_country_name",
      "position_original": "Goalkeeper",
      "current_club_text": "CA Talleres II",
      "primary_tm_club_id": "55574",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/jeremias-florentin/profil/spieler/1197896",
        "https://www.clubtalleres.com.ar/plantel-profesional/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "secondary_club_text": "CA Talleres",
      "secondary_tm_club_id": "3938",
      "category": "Primera",
      "category_note": "El perfil tiene CA Talleres II como club principal y CA Talleres como segundo club. Revisar la categoría antes de un registro que sólo admite una.",
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-1197896",
      "tm_id": "1197896",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Jeremías Nisael",
      "last_name": "Florentín",
      "season": "2026",
      "position": "Arquero",
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "category_resolution": "Aunque Transfermarkt identifica a Talleres II como club principal, la fuente actual del club lo incluye en el plantel profesional de Primera.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Matías Galarza",
      "tm_player_id": "909737",
      "tm_url": "https://www.transfermarkt.com/matias-galarza/profil/spieler/909737",
      "full_name": "Matías Alejandro Galarza",
      "full_name_basis": "home_country_name",
      "position_original": "Defensive Midfield",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/matias-galarza/profil/spieler/909737",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-909737",
      "tm_id": "909737",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Matías Alejandro",
      "last_name": "Galarza",
      "season": "2026",
      "category": "Primera",
      "position": "Volante central",
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Jeremías Gallard",
      "tm_player_id": "1271301",
      "tm_url": "https://www.transfermarkt.com/jeremias-gallard/profil/spieler/1271301",
      "full_name": "Jeremías Gallard",
      "full_name_basis": "profile_display_name",
      "position_original": "Attacking Midfield",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/jeremias-gallard/profil/spieler/1271301",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 4,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-1271301",
      "tm_id": "1271301",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Jeremías",
      "last_name": "Gallard",
      "season": "2026",
      "category": "Primera",
      "position": null,
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Matías Gómez",
      "tm_player_id": "1150517",
      "tm_url": "https://www.transfermarkt.com/matias-gomez/profil/spieler/1150517",
      "full_name": "Matías Ezequiel Gómez",
      "full_name_basis": "home_country_name",
      "position_original": "Central Midfield",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/matias-gomez/profil/spieler/1150517",
        "https://www.clubtalleres.com.ar/plantel-profesional/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 4,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-1150517",
      "tm_id": "1150517",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Matías Ezequiel",
      "last_name": "Gómez",
      "season": "2026",
      "category": "Primera",
      "position": "Volante central",
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Rodrigo Guth",
      "tm_player_id": "492313",
      "tm_url": "https://www.transfermarkt.com/rodrigo-guth/profil/spieler/492313",
      "full_name": "Rodrigo Guth",
      "full_name_basis": "profile_display_name",
      "position_original": "Centre-Back",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/rodrigo-guth/profil/spieler/492313"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_search",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": false,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "talleres_institution_observed_in_indexed_individual_profile",
      "source_key": "manual-talleres-2026-tm-492313",
      "tm_id": "492313",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Rodrigo",
      "last_name": "Guth",
      "season": "2026",
      "category": "Primera",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "current_roster_verified": false,
      "official_roster_source_urls": [],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "pending_current_roster_review",
      "conflict_note": "El perfil indexado identifica el club, pero no se corroboró pertenencia actual en las fuentes oficiales recientes consultadas. Esto no afirma que haya dejado el club.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club."
    },
    {
      "roster_name": "Guido Herrera",
      "tm_player_id": "230014",
      "tm_url": "https://www.transfermarkt.com/guido-herrera/profil/spieler/230014",
      "full_name": "Guido Gabriel Herrera",
      "full_name_basis": "home_country_name",
      "position_original": "Goalkeeper",
      "current_club_text": "Esporte Clube Bahia",
      "primary_tm_club_id": null,
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/guido-herrera/profil/spieler/230014"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_search",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": false,
      "exclude_from_current_talleres_import": true,
      "category_review_required": false,
      "roster_match_status": "contradicted_by_indexed_individual_profile",
      "conflict_note": "El plantel indexado más antiguo incluye al jugador en Talleres, pero el perfil individual indexado muestra otro club. No incorporar como jugador vigente de Talleres sin nueva verificación.",
      "current_club_joined_text": "10/07/2026",
      "source_key": "manual-talleres-2026-tm-230014",
      "tm_id": "230014",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Guido Gabriel",
      "last_name": "Herrera",
      "season": "2026",
      "category": "Primera",
      "position": "Arquero",
      "sector": "no_especificado",
      "current_roster_verified": false,
      "official_roster_source_urls": [],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "excluded_conflict",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club."
    },
    {
      "roster_name": "Rick",
      "tm_player_id": "645955",
      "tm_url": "https://www.transfermarkt.com/rick/profil/spieler/645955",
      "full_name": "Rick Jhonatan Lima Morais",
      "full_name_basis": "full_name_field",
      "position_original": "Left Winger",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/rick/profil/spieler/645955",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 4,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-645955",
      "tm_id": "645955",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Rick Jhonatan",
      "last_name": "Lima Morais",
      "season": "2026",
      "category": "Primera",
      "position": "Delantero Extremo",
      "sector": "izquierda",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Alexandro Maidana",
      "tm_player_id": "1371519",
      "tm_url": "https://www.transfermarkt.es/alexandro-maidana/profil/spieler/1371519",
      "full_name": "Alexandro Maidana Mendieta",
      "full_name_basis": "home_country_name",
      "position_original": "Left-Back",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.es/alexandro-maidana/profil/spieler/1371519",
        "https://www.transfermarkt.com/alexandro-maidana/marktwertverlauf/spieler/1371519",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-1371519",
      "tm_id": "1371519",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Alexandro",
      "last_name": "Maidana Mendieta",
      "season": "2026",
      "category": "Primera",
      "position": "Lateral",
      "sector": "izquierda",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Ronaldo Martínez",
      "tm_player_id": "567736",
      "tm_url": "https://www.transfermarkt.com/ronaldo-martinez/profil/spieler/567736",
      "full_name": "Ronaldo Iván Martínez Rolón",
      "full_name_basis": "home_country_name",
      "position_original": "Centre-Forward",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/ronaldo-martinez/profil/spieler/567736"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_search",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": false,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "talleres_institution_observed_in_indexed_individual_profile",
      "source_key": "manual-talleres-2026-tm-567736",
      "tm_id": "567736",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Ronaldo Iván",
      "last_name": "Martínez Rolón",
      "season": "2026",
      "category": "Primera",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "current_roster_verified": false,
      "official_roster_source_urls": [],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "pending_current_roster_review",
      "conflict_note": "El perfil indexado identifica el club, pero no se corroboró pertenencia actual en las fuentes oficiales recientes consultadas. Esto no afirma que haya dejado el club.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club."
    },
    {
      "roster_name": "Ulises Ortegoza",
      "tm_player_id": "654814",
      "tm_url": "https://www.transfermarkt.com/ulises-ortegoza/profil/spieler/654814",
      "full_name": "Diego Ulises Ortegoza",
      "full_name_basis": "home_country_name",
      "position_original": "Defensive Midfield",
      "current_club_text": "Racing Club",
      "primary_tm_club_id": "1444",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/ulises-ortegoza/profil/spieler/654814"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_search",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": false,
      "exclude_from_current_talleres_import": true,
      "category_review_required": false,
      "roster_match_status": "contradicted_by_indexed_individual_profile",
      "conflict_note": "El plantel indexado más antiguo incluye al jugador en Talleres, pero el perfil individual indexado muestra otro club. No incorporar como jugador vigente de Talleres sin nueva verificación.",
      "current_club_joined_text": "01/07/2026",
      "source_key": "manual-talleres-2026-tm-654814",
      "tm_id": "654814",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Diego Ulises",
      "last_name": "Ortegoza",
      "season": "2026",
      "category": "Primera",
      "position": "Volante central",
      "sector": "no_especificado",
      "current_roster_verified": false,
      "official_roster_source_urls": [],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "excluded_conflict",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club."
    },
    {
      "roster_name": "José Luis Palomino",
      "tm_player_id": "125020",
      "tm_url": "https://www.transfermarkt.com/jose-luis-palomino/profil/spieler/125020",
      "full_name": "José Luis Palomino",
      "full_name_basis": "profile_display_name",
      "position_original": "Centre-Back",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/jose-luis-palomino/profil/spieler/125020"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_search",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": false,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "talleres_institution_observed_in_indexed_individual_profile",
      "source_key": "manual-talleres-2026-tm-125020",
      "tm_id": "125020",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "José Luis",
      "last_name": "Palomino",
      "season": "2026",
      "category": "Primera",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "current_roster_verified": false,
      "official_roster_source_urls": [],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "pending_current_roster_review",
      "conflict_note": "El perfil indexado identifica el club, pero no se corroboró pertenencia actual en las fuentes oficiales recientes consultadas. Esto no afirma que haya dejado el club.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club."
    },
    {
      "roster_name": "Martín Río",
      "tm_player_id": "816843",
      "tm_url": "https://www.transfermarkt.com/martin-rio/profil/spieler/816843",
      "full_name": "Martín Río",
      "full_name_basis": "profile_display_name",
      "position_original": "Central Midfield",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/martin-rio/profil/spieler/816843"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_search",
      "index_crawl_age_months_reported": 4,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": false,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "talleres_institution_observed_in_indexed_individual_profile",
      "source_key": "manual-talleres-2026-tm-816843",
      "tm_id": "816843",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Martín",
      "last_name": "Río",
      "season": "2026",
      "category": "Primera",
      "position": "Volante central",
      "sector": "no_especificado",
      "current_roster_verified": false,
      "official_roster_source_urls": [],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "pending_current_roster_review",
      "conflict_note": "El perfil indexado identifica el club, pero no se corroboró pertenencia actual en las fuentes oficiales recientes consultadas. Esto no afirma que haya dejado el club.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club."
    },
    {
      "roster_name": "Juan Gabriel Rodríguez",
      "tm_player_id": "189448",
      "tm_url": "https://www.transfermarkt.com/juan-gabriel-rodriguez/profil/spieler/189448",
      "full_name": "Juan Gabriel Rodríguez",
      "full_name_basis": "profile_display_name",
      "position_original": "Centre-Back",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/juan-gabriel-rodriguez/profil/spieler/189448"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_search",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": false,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "talleres_institution_observed_in_indexed_individual_profile",
      "source_key": "manual-talleres-2026-tm-189448",
      "tm_id": "189448",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Juan Gabriel",
      "last_name": "Rodríguez",
      "season": "2026",
      "category": "Primera",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "current_roster_verified": false,
      "official_roster_source_urls": [],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "pending_current_roster_review",
      "conflict_note": "El perfil indexado identifica el club, pero no se corroboró pertenencia actual en las fuentes oficiales recientes consultadas. Esto no afirma que haya dejado el club.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club."
    },
    {
      "roster_name": "Augusto Schott",
      "tm_player_id": "670566",
      "tm_url": "https://www.transfermarkt.com/augusto-schott/profil/spieler/670566",
      "full_name": "Augusto Schott",
      "full_name_basis": "profile_display_name",
      "position_original": "Right-Back",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/augusto-schott/profil/spieler/670566",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-670566",
      "tm_id": "670566",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Augusto",
      "last_name": "Schott",
      "season": "2026",
      "category": "Primera",
      "position": "Lateral",
      "sector": "derecha",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Juan Sforza",
      "tm_player_id": "659264",
      "tm_url": "https://www.transfermarkt.com/juan-sforza/profil/spieler/659264",
      "full_name": "Juan Sebastián Sforza",
      "full_name_basis": "home_country_name",
      "position_original": "Defensive Midfield",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/juan-sforza/profil/spieler/659264",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-659264",
      "tm_id": "659264",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Juan Sebastián",
      "last_name": "Sforza",
      "season": "2026",
      "category": "Primera",
      "position": "Volante central",
      "sector": "no_especificado",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Diego Valoyes",
      "tm_player_id": "413983",
      "tm_url": "https://www.transfermarkt.com/diego-valoyes/profil/spieler/413983",
      "full_name": "Diego Luis Valoyes Ruíz",
      "full_name_basis": "home_country_name",
      "position_original": "Right Winger",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/diego-valoyes/profil/spieler/413983",
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-413983",
      "tm_id": "413983",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Diego Luis",
      "last_name": "Valoyes Ruíz",
      "season": "2026",
      "category": "Primera",
      "position": "Delantero Extremo",
      "sector": "derecha",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/",
        "https://www.clubtalleres.com.ar/talleres-no-pudo-ante-el-halcon/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "official_roster_event_date": "2026-10-24",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "roster_name": "Alex Vigo",
      "tm_player_id": "648520",
      "tm_url": "https://www.transfermarkt.com/alex-vigo/profil/spieler/648520",
      "full_name": "Alex Gamaliel Vigo",
      "full_name_basis": "home_country_name",
      "position_original": "Right-Back",
      "current_club_text": "CA Talleres",
      "primary_tm_club_id": "3938",
      "requested_tm_club_id": "3938",
      "club_source_key": "ar-cordoba-talleres",
      "source_urls": [
        "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
        "https://www.transfermarkt.com/alex-vigo/profil/spieler/648520",
        "https://www.clubtalleres.com.ar/plantel-profesional/"
      ],
      "roster_source_url": "https://www.transfermarkt.com/ca-talleres/kader/verein/3938",
      "source_method": "manual_indexed_profile_and_live_official_club",
      "index_crawl_age_months_reported": 3,
      "verified_at": "2026-10-29T20:47:46Z",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": true,
      "exclude_from_current_talleres_import": false,
      "category_review_required": false,
      "roster_match_status": "corroborated_by_current_official_club_source",
      "source_key": "manual-talleres-2026-tm-648520",
      "tm_id": "648520",
      "tm_club_id": "3938",
      "club_name": "Club Atlético Talleres",
      "first_name": "Alex Gamaliel",
      "last_name": "Vigo",
      "season": "2026",
      "category": "Primera",
      "position": "Lateral",
      "sector": "derecha",
      "current_roster_verified": true,
      "official_roster_source_urls": [
        "https://www.clubtalleres.com.ar/plantel-profesional/"
      ],
      "current_roster_checked_at": "2026-10-29T20:47:46Z",
      "publication_status": "published",
      "roster_verification_basis": "El club lo incluye en su Plantel Profesional consultado hoy o en la ficha oficial de Primera del 24/10/2026.",
      "source_snapshot_note": "El ID y la posición provienen de un perfil indexado de Transfermarkt; la vigencia actual sólo se afirma cuando current_roster_verified es true y se aporta una fuente oficial reciente del club.",
      "source": "official_reference"
    },
    {
      "source_key": "manual-godoy-cruz-2026-camilo-alessandria",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Camilo",
      "last_name": "Alessandria",
      "full_name": "Camilo Alessandria",
      "category": "Primera",
      "season": "2026",
      "position_original": "Centre-Back",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-juan-andrada",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Juan",
      "last_name": "Andrada",
      "full_name": "Juan Andrada",
      "category": "Primera",
      "season": "2026",
      "position_original": "Defensive Midfield",
      "position": "Volante central",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-lucas-arce",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Lucas",
      "last_name": "Arce",
      "full_name": "Lucas Arce",
      "category": "Primera",
      "season": "2026",
      "position_original": "Right-Back",
      "position": "Lateral",
      "sector": "derecha",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-bruno-barrionuevo",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Bruno",
      "last_name": "Barrionuevo",
      "full_name": "Bruno Barrionuevo",
      "category": "Primera",
      "season": "2026",
      "position_original": "Centre-Forward",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-nahuel-brunet",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Nahuel",
      "last_name": "Brunet",
      "full_name": "Nahuel Brunet",
      "category": "Primera",
      "season": "2026",
      "position_original": "Centre-Back",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-esteban-burgos",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Esteban",
      "last_name": "Burgos",
      "full_name": "Esteban Burgos",
      "category": "Primera",
      "season": "2026",
      "position_original": "Centre-Back",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-bautista-cejas",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Bautista",
      "last_name": "Cejas",
      "full_name": "Bautista Cejas",
      "category": "Primera",
      "season": "2026",
      "position_original": "Attacking Midfield",
      "position": null,
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-nicolas-claa",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Nicolás",
      "last_name": "Cláa",
      "full_name": "Nicolás Cláa",
      "category": "Primera",
      "season": "2026",
      "position_original": "Goalkeeper",
      "position": "Arquero",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-francisco-gerometta",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Francisco",
      "last_name": "Gerometta",
      "full_name": "Francisco Gerometta",
      "category": "Primera",
      "season": "2026",
      "position_original": "Right-Back",
      "position": "Lateral",
      "sector": "derecha",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-gaston-gil-romero",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Gastón",
      "last_name": "Gil Romero",
      "full_name": "Gastón Gil Romero",
      "category": "Primera",
      "season": "2026",
      "position_original": "Defensive Midfield",
      "position": "Volante central",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-santiago-martinez",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Santiago",
      "last_name": "Martínez",
      "full_name": "Santiago Martínez",
      "category": "Primera",
      "season": "2026",
      "position_original": "Attacking Midfield",
      "position": null,
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-mateo-mendoza",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": "1103933",
      "tm_url": "https://www.transfermarkt.com/mateo-mendoza/profil/spieler/1103933",
      "first_name": "Mateo",
      "last_name": "Mendoza",
      "full_name": "Mateo Mendoza",
      "category": "Primera",
      "season": "2026",
      "position_original": "Centre-Back",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574",
        "https://www.transfermarkt.com/mateo-mendoza/profil/spieler/1103933"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": false,
      "current_club_text": "CD Godoy Cruz Antonio Tomba",
      "current_club_verification_method": "manual_indexed_individual_profile",
      "roster_membership_only": false,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-federico-milo",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Federico",
      "last_name": "Milo",
      "full_name": "Federico Milo",
      "category": "Primera",
      "season": "2026",
      "position_original": "Left-Back",
      "position": "Lateral",
      "sector": "izquierda",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-juan-moran",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Juan",
      "last_name": "Morán",
      "full_name": "Juan Morán",
      "category": "Primera",
      "season": "2026",
      "position_original": "Left-Back",
      "position": "Lateral",
      "sector": "izquierda",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-brian-orosco",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Brian",
      "last_name": "Orosco",
      "full_name": "Brian Orosco",
      "category": "Primera",
      "season": "2026",
      "position_original": "Attacking Midfield",
      "position": null,
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-martin-pino",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Martín",
      "last_name": "Pino",
      "full_name": "Martín Pino",
      "category": "Primera",
      "season": "2026",
      "position_original": "Centre-Forward",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-vicente-poggi",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": "657744",
      "tm_url": "https://www.transfermarkt.com/vicente-poggi/profil/spieler/657744",
      "first_name": "Vicente",
      "last_name": "Poggi",
      "full_name": "Vicente Poggi",
      "category": "Primera",
      "season": "2026",
      "position_original": "Central Midfield",
      "position": "Volante central",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574",
        "https://www.transfermarkt.com/vicente-poggi/profil/spieler/657744"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": false,
      "current_club_text": "CD Godoy Cruz Antonio Tomba",
      "current_club_verification_method": "manual_indexed_individual_profile",
      "roster_membership_only": false,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-tomas-pozzo",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Tomás",
      "last_name": "Pozzo",
      "full_name": "Tomás Pozzo",
      "category": "Primera",
      "season": "2026",
      "position_original": "Attacking Midfield",
      "position": null,
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-gonzalo-quinteros",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Gonzalo",
      "last_name": "Quinteros",
      "full_name": "Gonzalo Quinteros",
      "category": "Primera",
      "season": "2026",
      "position_original": "Defensive Midfield",
      "position": "Volante central",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-leandro-quiroz",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Leandro",
      "last_name": "Quiroz",
      "full_name": "Leandro Quiroz",
      "category": "Primera",
      "season": "2026",
      "position_original": "Centre-Back",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-matias-ramirez",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Matías",
      "last_name": "Ramírez",
      "full_name": "Matías Ramírez",
      "category": "Primera",
      "season": "2026",
      "position_original": "Left Winger",
      "position": "Delantero Extremo",
      "sector": "izquierda",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-roberto-ramirez",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": "332248",
      "tm_url": "https://www.transfermarkt.com/roberto-ramirez/profil/spieler/332248",
      "first_name": "Roberto",
      "last_name": "Ramírez",
      "full_name": "Roberto Ramírez",
      "category": "Primera",
      "season": "2026",
      "position_original": "Goalkeeper",
      "position": "Arquero",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574",
        "https://www.transfermarkt.com/roberto-ramirez/profil/spieler/332248"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": true,
      "current_club_confirmed_live": false,
      "current_club_text": "CD Godoy Cruz Antonio Tomba",
      "current_club_verification_method": "manual_indexed_individual_profile",
      "roster_membership_only": false,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-willian-riquelme",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Willian",
      "last_name": "Riquelme",
      "full_name": "Willian Riquelme",
      "category": "Primera",
      "season": "2026",
      "position_original": "Centre-Forward",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-axel-rodriguez",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Axel",
      "last_name": "Rodríguez",
      "full_name": "Axel Rodríguez",
      "category": "Primera",
      "season": "2026",
      "position_original": "Centre-Forward",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-tomas-rossi",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Tomás",
      "last_name": "Rossi",
      "full_name": "Tomás Rossi",
      "category": "Primera",
      "season": "2026",
      "position_original": "Centre-Back",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-mariano-santiago",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Mariano",
      "last_name": "Santiago",
      "full_name": "Mariano Santiago",
      "category": "Primera",
      "season": "2026",
      "position_original": "Central Midfield",
      "position": "Volante central",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-misael-sosa",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Misael",
      "last_name": "Sosa",
      "full_name": "Misael Sosa",
      "category": "Primera",
      "season": "2026",
      "position_original": "Second Striker",
      "position": null,
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-juan-strumia",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Juan",
      "last_name": "Strumia",
      "full_name": "Juan Strumia",
      "category": "Primera",
      "season": "2026",
      "position_original": "Goalkeeper",
      "position": "Arquero",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-exequiel-tejada",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Exequiel",
      "last_name": "Tejada",
      "full_name": "Exequiel Tejada",
      "category": "Primera",
      "season": "2026",
      "position_original": "Central Midfield",
      "position": "Volante central",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-nahuel-ulariaga",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Nahuel",
      "last_name": "Ulariaga",
      "full_name": "Nahuel Ulariaga",
      "category": "Primera",
      "season": "2026",
      "position_original": "Centre-Forward",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "manual-godoy-cruz-2026-agustin-valverde",
      "club_source_key": "ar-mendoza-godoy-cruz",
      "club_name": "Club Deportivo Godoy Cruz Antonio Tomba",
      "tm_club_id": "12574",
      "tm_id": null,
      "tm_url": null,
      "first_name": "Agustín",
      "last_name": "Valverde",
      "full_name": "Agustín Valverde",
      "category": "Primera",
      "season": "2026",
      "position_original": "Right Midfield",
      "position": "Volante por derecha",
      "sector": "no_especificado",
      "source_urls": [
        "https://www.transfermarkt.com/cd-godoy-cruz-antonio-tomba/kader/verein/12574"
      ],
      "source_method": "manual_indexed_search",
      "verified_at": "2026-10-29T20:44:36Z",
      "source_snapshot_note": "Extracto indexado con rastreo indicado hace 4 meses; no equivale a confirmación del plantel vigente hoy.",
      "profile_current_club_verified": false,
      "current_club_confirmed_live": false,
      "current_club_text": null,
      "current_club_verification_method": null,
      "roster_membership_only": true,
      "current_roster_verified": false,
      "publication_status": "pending_current_roster_review",
      "current_roster_note": "Muestra de plantel indexado; no se hizo corroboración actual con el club."
    },
    {
      "source_key": "ar:player-candidate:olimpo:marcos-acosta:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Marcos",
      "last_name": "Acosta",
      "full_name": "Marcos Acosta",
      "source_position": "Interior derecho",
      "position": "Volante por derecha",
      "sector": "derecha",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Interior derecho",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:cristian-amarilla:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Cristian",
      "last_name": "Amarilla",
      "full_name": "Cristian Amarilla",
      "source_position": "Mediocentro ofensivo",
      "position": null,
      "sector": "no_especificado",
      "position_mapping_status": "pending_manual_review",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediocentro ofensivo",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:agustin-bellone:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Agustin",
      "last_name": "Bellone",
      "full_name": "Agustin Bellone",
      "source_position": "Lateral derecho",
      "position": "Lateral",
      "sector": "derecha",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Lateral derecho",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:cristian-chimino:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Cristian",
      "last_name": "Chimino",
      "full_name": "Cristian Chimino",
      "source_position": "Lateral derecho",
      "position": "Lateral",
      "sector": "derecha",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Lateral derecho",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:enzo-coacci:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Enzo",
      "last_name": "Coacci",
      "full_name": "Enzo Coacci",
      "source_position": "Extremo derecho",
      "position": "Delantero Extremo",
      "sector": "derecha",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Extremo derecho",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:marco-colmenares:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Marco",
      "last_name": "Colmenares",
      "full_name": "Marco Colmenares",
      "source_position": "Delantero centro",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Delantero centro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:leandro-espejo:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Leandro",
      "last_name": "Espejo",
      "full_name": "Leandro Espejo",
      "source_position": "Extremo derecho",
      "position": "Delantero Extremo",
      "sector": "derecha",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Extremo derecho",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:sebastian-fernandez:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Sebastián",
      "last_name": "Fernández",
      "full_name": "Sebastián Fernández",
      "source_position": "Pivote",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Pivote",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:martin-ferreyra:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Martín",
      "last_name": "Ferreyra",
      "full_name": "Martín Ferreyra",
      "source_position": "Defensa central",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Defensa central",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:cristian-geist:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Cristian",
      "last_name": "Geist",
      "full_name": "Cristian Geist",
      "source_position": "Portero",
      "position": "Arquero",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": "1051506",
      "tm_url": "https://www.transfermarkt.com.ar/cristian-geist/profil/spieler/1051506",
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468",
        "https://www.transfermarkt.com.ar/cristian-geist/profil/spieler/1051506"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "profile_observation": "Perfil individual indexado cuatro meses antes de la consulta; coincide con club de la captura de plantilla. No confirma pertenencia actual al 29/10/2026.",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Portero",
      "source_snapshot_note": "Perfil individual indexado cuatro meses antes de la consulta; coincide con club de la captura de plantilla. No confirma pertenencia actual al 29/10/2026.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:federico-gonzalez:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Federico",
      "last_name": "González",
      "full_name": "Federico González",
      "source_position": "Delantero centro",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Delantero centro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:gonzalo-groba:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Gonzalo",
      "last_name": "Groba",
      "full_name": "Gonzalo Groba",
      "source_position": "Mediocentro ofensivo",
      "position": null,
      "sector": "no_especificado",
      "position_mapping_status": "pending_manual_review",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediocentro ofensivo",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:brian-guille:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Brian",
      "last_name": "Guille",
      "full_name": "Brian Guille",
      "source_position": "Mediapunta",
      "position": null,
      "sector": "no_especificado",
      "position_mapping_status": "pending_manual_review",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediapunta",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:antu-hernandez:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Antú",
      "last_name": "Hernández",
      "full_name": "Antú Hernández",
      "source_position": "Interior izquierdo",
      "position": "Volante por Izquierda",
      "sector": "izquierda",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Interior izquierdo",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:leonardo-hertel:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Leonardo",
      "last_name": "Hertel",
      "full_name": "Leonardo Hertel",
      "source_position": "Defensa central",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Defensa central",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:cristian-ibarra:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Cristian",
      "last_name": "Ibarra",
      "full_name": "Cristian Ibarra",
      "source_position": "Mediapunta",
      "position": null,
      "sector": "no_especificado",
      "position_mapping_status": "pending_manual_review",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediapunta",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:luciano-lapetina:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Luciano",
      "last_name": "Lapetina",
      "full_name": "Luciano Lapetina",
      "source_position": "Lateral izquierdo",
      "position": "Lateral",
      "sector": "izquierda",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Lateral izquierdo",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:santiago-llanos:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Santiago",
      "last_name": "Llanos",
      "full_name": "Santiago Llanos",
      "source_position": "Extremo derecho",
      "position": "Delantero Extremo",
      "sector": "derecha",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Extremo derecho",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:juan-pablo-lungarzo:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Juan Pablo",
      "last_name": "Lungarzo",
      "full_name": "Juan Pablo Lungarzo",
      "source_position": "Portero",
      "position": "Arquero",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Portero",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:nestor-moiraghi:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Néstor",
      "last_name": "Moiraghi",
      "full_name": "Néstor Moiraghi",
      "source_position": "Defensa central",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Defensa central",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:marcelo-olivera:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Marcelo",
      "last_name": "Olivera",
      "full_name": "Marcelo Olivera",
      "source_position": "Delantero centro",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Delantero centro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:agustin-osinaga:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Agustín",
      "last_name": "Osinaga",
      "full_name": "Agustín Osinaga",
      "source_position": "Defensa central",
      "position": "Defensor Central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Defensa central",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:alvaro-pavon:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Álvaro",
      "last_name": "Pavón",
      "full_name": "Álvaro Pavón",
      "source_position": "Mediocentro",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediocentro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:diego-ramirez:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Diego",
      "last_name": "Ramírez",
      "full_name": "Diego Ramírez",
      "source_position": "Mediocentro",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediocentro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:agustin-stancato:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Agustín",
      "last_name": "Stancato",
      "full_name": "Agustín Stancato",
      "source_position": "Mediocentro",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediocentro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:joaquin-susvielles:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Joaquín",
      "last_name": "Susvielles",
      "full_name": "Joaquín Susvielles",
      "source_position": "Delantero centro",
      "position": "Delantero de Area",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Delantero centro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:manuel-vargas:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Manuel",
      "last_name": "Vargas",
      "full_name": "Manuel Vargas",
      "source_position": "Mediocentro",
      "position": "Volante central",
      "sector": "no_especificado",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Mediocentro",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    },
    {
      "source_key": "ar:player-candidate:olimpo:gaston-vega:2026",
      "club_source_key": "ar:club:olimpo",
      "competition_slug": "federal-a",
      "season": "2026",
      "category": "Primera",
      "first_name": "Gastón",
      "last_name": "Vega",
      "full_name": "Gastón Vega",
      "source_position": "Lateral izquierdo",
      "position": "Lateral",
      "sector": "izquierda",
      "position_mapping_status": "literal_sports_equivalence",
      "tm_id": null,
      "tm_url": null,
      "source_urls": [
        "https://www.transfermarkt.com.ar/club-olimpo/kader/verein/7468"
      ],
      "source_method": "manual_transfermarkt_search_index",
      "observed_at": "2026-10-29T20:51:07Z",
      "source_crawled_relative": "3 months ago",
      "current_roster_verified": false,
      "import_ready": false,
      "verification_status": "pending_current_club_confirmation",
      "club_name": "Club Olimpo",
      "verified_at": "2026-10-29T20:51:07Z",
      "position_original": "Lateral izquierdo",
      "source_snapshot_note": "Referencia indexada; rastreo informado: 3 months ago. Falta corroborar la pertenencia actual al club.",
      "publication_status": "pending_current_roster_review"
    }
  ]
}$catalogue$::jsonb;
  v_row jsonb;
  v_run uuid;
  v_club uuid;
  v_key_club uuid;
  v_identity_club uuid;
  v_before_count bigint;
  v_after_count bigint;
  v_before_recommendations bigint;
  v_before_events bigint;
  v_processed integer := 0;
  v_players integer := 0;
begin
  if v_data#>>'{metadata,country}' <> 'Argentina'
    or v_data#>>'{metadata,season}' <> '2026'
    or jsonb_array_length(v_data->'clubs') <> 153
    or (v_data#>>'{metadata,published_player_count}')::integer <> 21 then
    raise exception 'Unexpected catalogue input';
  end if;

  -- Serialize this batch and prevent manual club validation from racing identity joins.
  perform pg_advisory_xact_lock(hashtextextended('scouting:catalogue:argentina-manual-2026-10-29',0));
  if exists(select 1 from scouting.catalogue_runs where status='published'
    and metadata->>'batch_key'=v_data#>>'{metadata,batch_key}') then
    if not exists(select 1 from scouting.catalogue_runs where status='published'
      and metadata->>'batch_key'=v_data#>>'{metadata,batch_key}'
      and metadata->>'snapshot_sha256'='56a956e43987ef246504a6076723ff8adde22feb22e914068efad7f241bfc19c') then
      raise exception 'Batch key already published with different content; use a new reviewed batch';
    end if;
    raise notice 'Catalogue batch already published; data left unchanged';
    return;
  end if;
  lock table scouting.clubs in share row exclusive mode;
  select count(*) into v_before_count from scouting.clubs;
  select count(*) into v_before_recommendations from scouting.recommendations;
  select count(*) into v_before_events from scouting.events;
  insert into scouting.catalogue_runs(source,status,metadata)
    values('manual_official_catalogue_with_transfermarkt_references','staging',
      (v_data->'metadata') || jsonb_build_object('snapshot_sha256','56a956e43987ef246504a6076723ff8adde22feb22e914068efad7f241bfc19c',
        'player_references',v_data->'players','club_references',v_data->'clubs'))
    returning id into v_run;

  for v_row in select value from jsonb_array_elements(v_data->'clubs') loop
    if v_row->>'publication_status'<>'published' or not (v_row->>'geo_verified')::boolean
      or not exists(select 1 from scouting.provinces where name=v_row->>'province')
      or not exists(select 1 from scouting.competitions where id=v_row->>'competition_slug')
      or jsonb_array_length(v_row->'source_urls')=0 then
      raise exception 'Unverified club input: %',v_row->>'source_key';
    end if;
    v_key_club:=null; v_identity_club:=null;
    select id into v_key_club from scouting.clubs where source_key=v_row->>'source_key';
    select id into v_identity_club from scouting.clubs where province=v_row->>'province'
      and lower(city)=lower(v_row->>'city') and lower(name)=lower(v_row->>'name');
    if v_key_club is not null and v_identity_club is not null and v_key_club<>v_identity_club then
      raise exception 'Conflicting catalogue identities for %',v_row->>'source_key';
    end if;
    v_club:=coalesce(v_key_club,v_identity_club);
    if v_club is null then
      insert into scouting.clubs(source_key,name,province,city,league,source,source_urls,checked_at,catalogue_run_id)
        values(v_row->>'source_key',v_row->>'name',v_row->>'province',v_row->>'city',nullif(v_row->>'league',''),
          'official_reference',v_row->'source_urls',(v_row->>'verified_at')::timestamptz,v_run)
        returning id into v_club;
    else
      update scouting.clubs c set
        name=v_row->>'name',province=v_row->>'province',city=v_row->>'city',
        league=coalesce(nullif(v_row->>'league',''),c.league),
        source='official_reference',
        source_urls=(select coalesce(jsonb_agg(x order by x),'[]'::jsonb)
          from (select distinct value as x from jsonb_array_elements(c.source_urls || (v_row->'source_urls'))) distinct_urls),
        checked_at=(v_row->>'verified_at')::timestamptz,catalogue_run_id=v_run
        where c.id=v_club;
      -- Keep the existing source_key and ID when a member-validated identical club already exists.
      -- Do not reactivate a deliberately inactive record silently.
    end if;
    insert into scouting.club_competitions(club_id,competition_id,season,division,reference_scope,source_urls,checked_at)
      values(v_club,v_row->>'competition_slug',v_row->>'season',v_row->>'division',
        'primer_equipo_masculino',v_row->'source_urls',(v_row->>'verified_at')::timestamptz)
      on conflict(club_id,competition_id,season) do update set
        division=coalesce(excluded.division,scouting.club_competitions.division),
        reference_scope=excluded.reference_scope,source_urls=excluded.source_urls,checked_at=excluded.checked_at;
    v_processed:=v_processed+1;
  end loop;

  for v_row in select value from jsonb_array_elements(v_data->'players')
    where value->>'current_roster_verified'='true' loop
    if v_row->>'publication_status'<>'published'
      or coalesce(jsonb_array_length(v_row->'official_roster_source_urls'),0)=0
      or coalesce((v_row->>'exclude_from_current_talleres_import')::boolean,false)
      or coalesce((v_row->>'category_review_required')::boolean,false) then
      raise exception 'Uncorroborated player: %',v_row->>'source_key';
    end if;
    select c.id into v_club from scouting.clubs c where c.source_key=v_row->>'club_source_key';
    if v_club is null then
      select c.id into v_club from scouting.clubs c
        join jsonb_array_elements(v_data->'clubs') j on c.name=j->>'name'
          and c.province=j->>'province' and c.city=j->>'city'
        where j->>'source_key'=v_row->>'club_source_key';
    end if;
    if v_club is null then raise exception 'Missing player club: %',v_row->>'club_source_key';end if;
    insert into scouting.players(source_key,club_id,first_name,last_name,category,position,transfermarkt_url,source,checked_at,catalogue_run_id)
      values(v_row->>'source_key',v_club,v_row->>'first_name',v_row->>'last_name',v_row->>'category',
        v_row->>'position',v_row->>'tm_url','official_reference',
        coalesce(v_row->>'current_roster_checked_at',v_row->>'verified_at')::timestamptz,v_run)
      on conflict(source_key) do update set club_id=excluded.club_id,first_name=excluded.first_name,
        last_name=excluded.last_name,category=excluded.category,position=excluded.position,
        transfermarkt_url=excluded.transfermarkt_url,source=excluded.source,
        checked_at=excluded.checked_at,catalogue_run_id=excluded.catalogue_run_id;
    v_players:=v_players+1;
  end loop;
  if v_processed<>153 or v_players<>21 then raise exception 'Import count mismatch';end if;
  select count(*) into v_after_count from scouting.clubs;
  if v_after_count<v_before_count then
    raise exception 'Import removed clubs';
  end if;
  update scouting.catalogue_runs set status='published',published_at=clock_timestamp(),
    metadata=metadata||jsonb_build_object('processed_clubs',v_processed,'processed_players',v_players,
      'new_clubs',v_after_count-v_before_count,'prior_club_count',v_before_count,
      'recommendations_before_import',v_before_recommendations,'events_before_import',v_before_events)
    where id=v_run;
end;
$import$;

-- Add public source-reference fields to the existing authenticated player lookup.
create or replace function public.scouting_api(p_token text,p_action text,p_payload jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path=pg_catalog as $$
declare
  v_actor bigint;
  v_admin boolean;
  v_role text;
  v_action text:=coalesce(p_action,'');
  v_payload jsonb:=coalesce(p_payload,'{}'::jsonb);
  v_id uuid;
  v_request uuid;
  v_request_hash text;
  v_previous_request scouting.requests%rowtype;
  v_rec scouting.recommendations%rowtype;
  v_club scouting.clubs%rowtype;
  v_player scouting.players%rowtype;
  v_comp scouting.competitions%rowtype;
  v_club_id uuid;
  v_player_id uuid;
  v_club_json jsonb;
  v_player_json jsonb;
  v_snapshot jsonb;
  v_nonce text;
  v_hash text;
  v_code text;
  v_category text;
  v_position text;
  v_sector text;
  v_reason text;
  v_observation text;
  v_video text;
  v_tm text;
  v_message text;
  v_status text;
  v_query text;
  v_province text;
  v_competition text;
  v_items jsonb;
  v_events jsonb;
  v_next text;
  v_offset integer:=0;
  v_positions constant text[]:=array['Arquero','Lateral','Defensor Central','Volante central','Volante por derecha','Volante por Izquierda','Volante Mixto','Delantero de Area','Delantero Extremo'];
  v_categories constant text[]:=array['Primera','Reserva','Proyección/Tercera','4ª división','5ª división','6ª división','7ª división','8ª división','9ª división','10ª división','11ª división','Sub-21','Sub-20','Sub-19','Sub-17','Sub-16','Sub-15','Sub-14','Sub-13','Sub-12','Infantil','Otra'];
begin
  if p_token is null or char_length(p_token) not between 32 and 512 then
    raise exception using errcode='PT401',message='Ingresá nuevamente con tu número de socio';
  end if;
  begin
    v_actor:=public.validar_sesion_segura_interno(p_token);
  exception when others then
    raise exception using errcode='PT401',message='La sesión venció o no está habilitada';
  end;
  if v_actor is null or not exists(select 1 from public.socios where numero_socio=v_actor and habilitado) then
    raise exception using errcode='PT401',message='La sesión venció o no está habilitada';
  end if;
  select exists(select 1 from public.administradores where numero_socio=v_actor and habilitado) into v_admin;
  v_role:=case when v_admin then 'admin' else 'socio' end;
  if jsonb_typeof(v_payload)<>'object' or octet_length(v_payload::text)>32768 then
    raise exception using errcode='PT422',message='Los datos del formulario no son válidos o son demasiado extensos';
  end if;
  if v_action not in ('bootstrap','clubs','players','create','feed','mine','detail','add_info','admin_list','admin_update','admin_validate_club') then
    raise exception using errcode='PT422',message='La operación solicitada no está disponible';
  end if;
  if v_action in ('admin_list','admin_update','admin_validate_club') and not v_admin then
    raise exception using errcode='PT403',message='Esta operación requiere un administrador habilitado';
  end if;
  if nullif(v_payload->>'internal_note','') is not null then
    raise exception using errcode='PT422',message='Las devoluciones de scouting son visibles para todos los socios. Usá el campo mensaje';
  end if;

  if v_action='bootstrap' then
    return jsonb_build_object('ok',true,'actor',jsonb_build_object('numero_socio',v_actor,'role',v_role),
      'provinces',(select jsonb_agg(name order by name) from scouting.provinces),
      'competitions',(select jsonb_agg(jsonb_build_object('id',id,'name',name,'season',season) order by sort_order,name) from scouting.competitions where active),
      'positions',to_jsonb(v_positions),'categories',to_jsonb(v_categories),
      'catalogue',jsonb_build_object('club_count',(select count(*) from scouting.clubs where active),
        'player_count',(select count(*) from scouting.players where active),
        'provider_status','pending_authorization','coverage','partial_official_references',
        'last_verified_at',(select max(checked_at) from scouting.clubs where active)));
  end if;

  if v_action in ('clubs','players','feed','mine','admin_list') then
    if nullif(v_payload->>'cursor','') is not null then
      if v_payload->>'cursor' !~ '^[0-9]{1,6}$' then raise exception using errcode='PT422',message='La página solicitada no es válida'; end if;
      v_offset:=(v_payload->>'cursor')::integer;
      if v_offset>100000 then raise exception using errcode='PT422',message='Refiná la búsqueda para ver más resultados'; end if;
    end if;
    v_query:=scouting.text_value(v_payload->'query',0,100,'búsqueda',true);
    v_province:=scouting.text_value(v_payload->'province',0,100,'provincia',true);
    v_competition:=scouting.text_value(v_payload->'competition_id',0,60,'competencia',true);
    if v_province is not null and not exists(select 1 from scouting.provinces where name=v_province) then
      raise exception using errcode='PT422',message='Seleccioná una provincia válida';
    end if;
  end if;

  if v_action='clubs' then
    with matches as (
      select c.id,c.name,c.province,c.city,c.league,c.checked_at,c.source,c.source_urls,
        co.id as competition_id,co.name as competition_name,cc.division,cc.season,cc.reference_scope,
        coalesce((select jsonb_agg(jsonb_build_object('id',cx.id,'name',cx.name,
          'season',mx.season,'division',mx.division,'reference_scope',mx.reference_scope) order by mx.season desc,cx.sort_order)
          from scouting.club_competitions mx join scouting.competitions cx on cx.id=mx.competition_id
          where mx.club_id=c.id and cx.active),'[]'::jsonb) as competitions
      from scouting.clubs c
      left join lateral (select m.* from scouting.club_competitions m
        where m.club_id=c.id and (v_competition is null or m.competition_id=v_competition)
        order by m.season desc,m.competition_id limit 1) cc on true
      left join scouting.competitions co on co.id=cc.competition_id
      where c.active and (v_province is null or c.province=v_province)
        and (v_competition is null or cc.competition_id=v_competition)
        and (v_query is null or strpos(lower(c.name||' '||c.city),lower(v_query))>0)
      order by lower(c.name),c.id limit 26 offset v_offset
    ) select coalesce(jsonb_agg(to_jsonb(matches)),'[]'::jsonb) into v_items from matches;
  elsif v_action='players' then
    v_club_id:=nullif(v_payload->>'club_id','')::uuid;
    if v_club_id is null or not exists(select 1 from scouting.clubs where id=v_club_id and active) then
      raise exception using errcode='PT422',message='Seleccioná un club del catálogo';
    end if;
    v_category:=scouting.text_value(v_payload->'category',0,100,'categoría',true);
    with matches as (
      select id,first_name,last_name,category,position,transfermarkt_url,checked_at from scouting.players
      where active and club_id=v_club_id and (v_category is null or category=v_category)
        and (v_query is null or strpos(lower(first_name||' '||last_name),lower(v_query))>0)
      order by lower(last_name),lower(first_name),id limit 26 offset v_offset
    ) select coalesce(jsonb_agg(to_jsonb(matches)),'[]'::jsonb) into v_items from matches;
  elsif v_action in ('feed','mine','admin_list') then
    if v_payload ? 'mine_only' and jsonb_typeof(v_payload->'mine_only')<>'boolean' then
      raise exception using errcode='PT422',message='El filtro de autor no es válido';
    end if;
    v_status:=scouting.text_value(v_payload->'status',0,40,'estado',true);
    if v_status is not null and v_status not in ('recibida','en_revision','informacion_solicitada','en_seguimiento','cerrada') then
      raise exception using errcode='PT422',message='Seleccioná un estado válido';
    end if;
    with matches as (
      select r.id from scouting.recommendations r
      where ((v_action<>'mine' and not coalesce((v_payload->>'mine_only')::boolean,false)) or r.owner_numero_socio=v_actor)
        and (v_status is null or r.status=v_status)
        and (v_query is null or strpos(lower(concat_ws(' ',r.code,r.snapshot#>>'{player,first_name}',r.snapshot#>>'{player,last_name}',r.snapshot#>>'{club,name}')),lower(v_query))>0)
      order by r.created_at desc,r.id desc limit 26 offset v_offset
    ) select coalesce(jsonb_agg(scouting.recommendation_json(id,v_admin,v_actor)),'[]'::jsonb) into v_items from matches;
  end if;
  if v_action in ('clubs','players','feed','mine','admin_list') then
    if jsonb_array_length(v_items)>25 then v_items:=v_items-25;v_next:=(v_offset+25)::text;end if;
    return jsonb_build_object('ok',true,'items',v_items,'next_cursor',v_next);
  end if;

  if v_action='detail' then
    v_id:=nullif(v_payload->>'id','')::uuid;
    select * into v_rec from scouting.recommendations where id=v_id;
    if not found then raise exception using errcode='PT404',message='No se encontró la recomendación';end if;
    select coalesce(jsonb_agg(jsonb_build_object('id',e.id,'type',e.event_type,'status',e.status,
      'actor_role',e.actor_role,'actor_name',s.nombre,'message',e.member_message,'created_at',e.created_at,'event_hash',e.event_hash)
      order by e.sequence_no),'[]'::jsonb)
      into v_events from scouting.events e join public.socios s on s.numero_socio=e.actor_numero_socio where e.recommendation_id=v_id;
    return jsonb_build_object('ok',true,'recommendation',scouting.recommendation_json(v_id,v_admin,v_actor),
      'events',v_events,'proof',scouting.proof_json(v_id));
  end if;

  -- Serialize all writes by actor, then lock the selected record. Duplicate clicks
  -- and retries use the same UUID and fingerprint without adding events or quotas.
  v_request:=nullif(v_payload->>'request_id','')::uuid;
  if v_request is null then raise exception using errcode='PT422',message='Falta la identificación del envío';end if;
  v_request_hash:=encode(extensions.digest(convert_to(jsonb_build_object('action',v_action,'payload',v_payload-'request_id')::text,'UTF8'),'sha256'),'hex');
  perform pg_advisory_xact_lock(hashtextextended('scouting:actor:'||v_actor::text,0));
  select * into v_previous_request from scouting.requests where actor_numero_socio=v_actor and request_id=v_request;
  if found then
    if v_previous_request.action<>v_action or v_previous_request.request_hash<>v_request_hash then
      raise exception using errcode='PT409',message='Ese envío ya se usó con otros datos. Iniciá un nuevo envío';
    end if;
    return jsonb_build_object('ok',true,'recommendation',scouting.recommendation_json(v_previous_request.recommendation_id,v_admin,v_actor),'replayed',true);
  end if;

  if v_action='create' then
    if (select count(*) from scouting.recommendations where owner_numero_socio=v_actor and created_at>clock_timestamp()-interval '24 hours')>=20 then
      raise exception using errcode='PT429',message='Alcanzaste el límite de 20 recomendaciones en 24 horas';
    end if;
    v_club_id:=nullif(v_payload->>'club_id','')::uuid;
    v_competition:=scouting.text_value(v_payload->'competition_id',0,60,'competencia',true);
    v_category:=scouting.text_value(v_payload->'category',2,100,'categoría');
    if lower(v_category)='otra' then raise exception using errcode='PT422',message='Indicá el nombre de la categoría';end if;
    if v_club_id is null then
      if jsonb_typeof(v_payload->'club_manual') is distinct from 'object' then
        raise exception using errcode='PT422',message='Completá los datos de Otro club';
      end if;
      v_province:=scouting.text_value(v_payload#>'{club_manual,province}',2,100,'provincia del club');
      if not exists(select 1 from scouting.provinces where name=v_province) then
        raise exception using errcode='PT422',message='Seleccioná una provincia argentina válida';
      end if;
      if v_competition is not null then
        select * into v_comp from scouting.competitions where id=v_competition and active;
        if not found then raise exception using errcode='PT422',message='Seleccioná una competencia válida';end if;
      end if;
      v_club_json:=jsonb_build_object('id',null,'source','manual',
        'name',scouting.text_value(v_payload#>'{club_manual,name}',2,160,'nombre del club'),
        'province',v_province,'city',scouting.text_value(v_payload#>'{club_manual,city}',2,100,'ciudad del club'),
        'league',scouting.text_value(v_payload#>'{club_manual,league}',2,160,'liga del club'),
        'competition_id',v_comp.id,'competition_name',v_comp.name,'division',null,
        'season',v_comp.season,'reference_scope','declarado_por_socio','provenance','member_submission');
    else
      select * into v_club from scouting.clubs where id=v_club_id and active;
      if not found then raise exception using errcode='PT422',message='El club seleccionado no está disponible';end if;
      if v_competition is not null and not exists(select 1 from scouting.club_competitions where club_id=v_club_id and competition_id=v_competition) then
        raise exception using errcode='PT422',message='La competencia no corresponde al club seleccionado';
      end if;
      select c.* into v_comp from scouting.club_competitions cc join scouting.competitions c on c.id=cc.competition_id
        where cc.club_id=v_club_id and c.active and (v_competition is null or c.id=v_competition)
        order by cc.season desc,c.sort_order limit 1;
      v_club_json:=jsonb_build_object('id',v_club.id,'source','catalogue','name',v_club.name,'province',v_club.province,
        'city',v_club.city,'league',v_club.league,'competition_id',v_comp.id,'competition_name',v_comp.name,
        'division',(select division from scouting.club_competitions where club_id=v_club_id and competition_id=v_comp.id order by season desc limit 1),
        'season',(select season from scouting.club_competitions where club_id=v_club_id and competition_id=v_comp.id order by season desc limit 1),
        'reference_scope',(select reference_scope from scouting.club_competitions where club_id=v_club_id and competition_id=v_comp.id order by season desc limit 1),
        'provenance',v_club.source,'source_urls',v_club.source_urls,'verified_at',v_club.checked_at);
    end if;

    v_player_id:=nullif(v_payload->>'player_id','')::uuid;
    v_position:=scouting.text_value(v_payload#>'{player,position}',2,60,'posición');
    if not(v_position=any(v_positions)) then raise exception using errcode='PT422',message='Seleccioná una posición válida';end if;
    v_sector:=coalesce(scouting.text_value(v_payload#>'{player,sector}',0,30,'sector',true),'no_especificado');
    if v_sector not in ('derecha','izquierda','ambos','no_especificado') then raise exception using errcode='PT422',message='Seleccioná un sector válido';end if;
    if v_position not in ('Lateral','Delantero Extremo') then v_sector:='no_especificado';end if;
    if v_player_id is not null then
      select * into v_player from scouting.players where id=v_player_id and active and club_id=v_club_id;
      if not found then raise exception using errcode='PT422',message='El jugador no corresponde al club seleccionado';end if;
      if v_player.category<>v_category then raise exception using errcode='PT422',message='La categoría no corresponde al jugador seleccionado';end if;
      v_player_json:=jsonb_build_object('id',v_player.id,'first_name',v_player.first_name,'last_name',v_player.last_name,
        'position',v_position,'sector',v_sector,'source','catalogue','verified_at',v_player.checked_at);
    else
      v_player_json:=jsonb_build_object('id',null,'first_name',scouting.text_value(v_payload#>'{player,first_name}',2,100,'nombre del jugador'),
        'last_name',scouting.text_value(v_payload#>'{player,last_name}',2,100,'apellido del jugador'),
        'position',v_position,'sector',v_sector,'source','manual');
    end if;
    v_reason:=scouting.text_value(v_payload->'reason',20,4000,'motivo de la recomendación');
    v_observation:=scouting.text_value(v_payload->'observation',0,2000,'contexto de observación',true);
    v_video:=scouting.url_value(v_payload->'video_url','video');
    v_tm:=scouting.url_value(v_payload->'transfermarkt_url','transfermarkt');
    v_snapshot:=jsonb_build_object('schema_version',1,'category',v_category,'club',v_club_json,'player',v_player_json,
      'reason',v_reason,'observation',v_observation,'video_url',v_video,'transfermarkt_url',v_tm,
      'source',case when v_player_id is null then 'manual' else 'catalogue' end);
    v_id:=gen_random_uuid();v_nonce:=encode(extensions.gen_random_bytes(32),'hex');
    v_hash:=encode(extensions.digest(convert_to(jsonb_build_object('schema','scouting-recommendation-v1','id',v_id,'owner',v_actor,'snapshot',v_snapshot,'nonce',v_nonce)::text,'UTF8'),'sha256'),'hex');
    v_code:='SC-'||upper(substr(replace(v_id::text,'-',''),1,12));
    insert into scouting.recommendations(id,code,owner_numero_socio,snapshot,private_nonce,commitment_hash)
      values(v_id,v_code,v_actor,v_snapshot,v_nonce,v_hash);
    perform scouting.append_event(v_id,v_actor,v_role,'created','recibida','Recomendación recibida');
  else
    v_id:=nullif(v_payload->>'id','')::uuid;
    select * into v_rec from scouting.recommendations where id=v_id and
      ((v_action='add_info' and owner_numero_socio=v_actor) or (v_action in ('admin_update','admin_validate_club') and v_admin)) for update;
    if not found then raise exception using errcode='PT404',message='No se encontró la recomendación';end if;
    v_message:=scouting.text_value(v_payload->'message',2,4000,'mensaje');
    if v_action='admin_validate_club' then
      if v_rec.snapshot#>>'{club,source}' is distinct from 'manual' then
        raise exception using errcode='PT409',message='El club de esta recomendación ya pertenece al catálogo';
      end if;
      if exists(select 1 from scouting.club_validations where recommendation_id=v_id) then
        raise exception using errcode='PT409',message='El club de esta recomendación ya fue validado';
      end if;
      v_club_json:=v_rec.snapshot->'club';
      perform pg_advisory_xact_lock(hashtextextended('scouting:club:'||
        (v_club_json->>'province')||':'||lower(v_club_json->>'city')||':'||lower(v_club_json->>'name'),0));
      select id into v_club_id from scouting.clubs where province=v_club_json->>'province'
        and lower(city)=lower(v_club_json->>'city') and lower(name)=lower(v_club_json->>'name');
      if not found then
        insert into scouting.clubs(source_key,name,province,city,league,source,checked_at)
          values('manual:'||v_id::text,v_club_json->>'name',v_club_json->>'province',v_club_json->>'city',
            v_club_json->>'league','verified_manual',clock_timestamp()) returning id into v_club_id;
        if v_club_json->>'competition_id' is not null then
          insert into scouting.club_competitions(club_id,competition_id,season,reference_scope,checked_at)
            select v_club_id,c.id,c.season,'declarado_por_socio_validado',clock_timestamp() from scouting.competitions c
              where c.id=v_club_json->>'competition_id' and c.active;
        end if;
      end if;
      insert into scouting.club_validations(recommendation_id,club_id,actor_numero_socio,reason)
        values(v_id,v_club_id,v_actor,v_message);
      perform scouting.append_event(v_id,v_actor,v_role,'club_validated',v_rec.status,
        'Club validado e incorporado o vinculado al catálogo. Motivo: '||v_message);
      update scouting.recommendations set updated_at=clock_timestamp() where id=v_id;
    elsif v_action='add_info' then
      if v_rec.status='cerrada' then raise exception using errcode='PT409',message='La recomendación está cerrada';end if;
      perform scouting.append_event(v_id,v_actor,v_role,'information_added',v_rec.status,v_message);
      update scouting.recommendations set updated_at=clock_timestamp() where id=v_id;
    else
      v_status:=scouting.text_value(v_payload->'status',2,40,'estado');
      if v_status not in ('recibida','en_revision','informacion_solicitada','en_seguimiento','cerrada') then
        raise exception using errcode='PT422',message='Seleccioná un estado válido';
      end if;
      -- Reopening is deliberate and auditable; the member-visible message is required.
      perform scouting.append_event(v_id,v_actor,v_role,'status_updated',v_status,v_message);
      update scouting.recommendations set status=v_status,updated_at=clock_timestamp() where id=v_id;
    end if;
  end if;
  insert into scouting.requests(actor_numero_socio,request_id,action,request_hash,recommendation_id)
    values(v_actor,v_request,v_action,v_request_hash,v_id);
  return jsonb_build_object('ok',true,'recommendation',scouting.recommendation_json(v_id,v_admin,v_actor),'replayed',false);
exception
  when invalid_text_representation or numeric_value_out_of_range or check_violation then
    raise exception using errcode='PT422',message='Revisá los datos del formulario';
end;
$$;

revoke all on function public.scouting_api(text,text,jsonb) from public, anon, authenticated;
grant execute on function public.scouting_api(text,text,jsonb) to service_role;
