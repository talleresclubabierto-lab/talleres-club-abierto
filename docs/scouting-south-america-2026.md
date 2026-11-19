# Catálogo sudamericano de scouting — corte del 19/11/2026

## Estado y alcance del corte

La ampliación incorpora datos de **Brasil, Chile, Colombia, Ecuador y Uruguay** al catálogo de Scouting, junto con **Argentina y su catálogo previo**. El corte argentino conserva sus 153 clubes y 5.627 identidades de jugadores, sus UUID, recomendaciones, actuaciones y evidencia histórica. La validación anterior está en [`catalogue-squads-2026-10-30.validation.json`](../scouting/catalogue-squads-2026-10-30.validation.json).

**Los 44 lotes se aplicaron y verificaron en Supabase: 458 clubes y 11.764 jugadores nuevos, con un total de 611 clubes y 17.391 jugadores activos.** El cruce con Argentina no encontró identidades repetidas. Las huellas de sus clubes y jugadores, y las de todas las recomendaciones y eventos anteriores, coinciden con las previas a la ampliación. El [manifiesto de importación](../scouting/catalogue-south-america-2026-11-19.import-manifest.json) conserva los documentos, hashes y recibos; la [verificación de la API](../scouting/catalogue-south-america-2026-11-19.api-validation.json) recorrió seis países y 47 competencias con datos. La publicación web de esta versión se verifica mediante el PR y sus despliegues; una carga de datos por sí sola no acredita un despliegue web.

El corte nuevo reúne **458 clubes únicos**, **42 competiciones con participación verificada en 2026** y **778 relaciones de clubes con competiciones**. Hay 13 ligas nacionales, 26 campeonatos estaduales brasileños y 3 copas nacionales. Un club puede participar en una liga, un estadual y una copa; sigue siendo un único club identificado por su ID de Transfermarkt. Véanse el [índice de fuentes](../scouting/catalogue-south-america-2026-11-19.sources.json.gz) y la [cobertura congelada](../scouting/catalogue-south-america-2026-11-19.coverage.json).

## Cobertura verificada por país

| País | Clubes únicos | Competiciones | Fuentes de Primera | Primera con filas de jugadores | Fuentes de Reserva/B/II | Reserva con filas | Jugadores incorporados y verificados |
|---|---:|---:|---:|---:|---:|---:|---:|
| Brasil | 275 | 31 | 275 | 275 | 35 | 10 | 6.634 |
| Chile | 46 | 3 | 46 | 46 | 7 | 1 | 1.276 |
| Colombia | 36 | 2 | 36 | 36 | 23 | 15 | 1.146 |
| Ecuador | 51 | 3 | 51 | 49 | 11 | 2 | 1.216 |
| Uruguay | 50 | 3 | 50 | 48 | 25 | 22 | 1.492 |
| **Total de la ampliación** | **458** | **42** | **458** | **454** | **101** | **50** | **11.764** |

Se consultaron las **559 fuentes previstas de planteles**: 458 de Primera y 101 de equipos explícitos de Reserva/B/II. Todas tienen resultado documentado; no quedan lecturas pendientes ni errores del parser. Esto acredita la revisión de esas fuentes concretas, sin asegurar que cada nómina coincida con todos los futbolistas reales del club.

Las fuentes contienen **11.863 filas y 11.813 identidades distintas**. Se detectaron **49 identidades presentes en más de un club padre**, con 98 observaciones en total. Se excluyeron todas esas observaciones antes de dividir por país, conservando las fuentes y los motivos en el archivo de hechos. Así se evita que el orden de carga decida una afiliación. Se incorporaron **11.765 membresías y 11.764 jugadores**; una identidad aparece en dos categorías del mismo club. Los 44 lotes finalizaron sin omisiones ni conflictos adicionales. La [validación de fuentes](../scouting/catalogue-south-america-2026-11-19.validation.json) y el manifiesto de importación distinguen los datos observados de los efectivamente cargados.

### Fuentes sin jugadores y equipo histórico

Cuatro páginas de Primera no publican filas de jugadores en la nómina recuperada:

| País | Club | Fuente consultada |
|---|---|---|
| Ecuador | Nazareno SC | [Plantel en Transfermarkt](https://www.transfermarkt.com/nazareno-sc/startseite/verein/140910) |
| Ecuador | Club Deportivo Bejucal Sport | [Plantel en Transfermarkt](https://www.transfermarkt.com/club-deportivo-bejucal-sport/startseite/verein/140907) |
| Uruguay | Gladiador FC | [Plantel en Transfermarkt](https://www.transfermarkt.com/gladiador-fc/startseite/verein/145948) |
| Uruguay | Racing Durazno | [Plantel en Transfermarkt](https://www.transfermarkt.com/racing-durazno/startseite/verein/145947) |

De las 101 fuentes de Reserva, **50 contienen jugadores, 50 están vacías y una identifica un equipo histórico**: [Grêmio FBPA B (-2022)](https://www.transfermarkt.com/gremio-porto-alegre-b/startseite/verein/14704). Ese equipo se conserva como evidencia `unavailable`, sin jugadores seleccionables como plantilla vigente. Que el selector de una página ofrezca una temporada reciente no elimina la indicación explícita de que el equipo es histórico.

Las páginas de U20, U21 y otras categorías juveniles enlazadas desde las fichas se conservan como descubrimiento. No se las convirtió en Reserva. Una tabla recuperada completa significa que se procesaron todas sus filas; no garantiza una plantilla completa fuera de la fuente.

## Navegación y datos geográficos

La búsqueda recomendada y predeterminada para esta ampliación es **país → competencia → club → categoría → jugador**. Puede complementarse con la búsqueda del club por nombre. Así se puede encontrar un equipo aunque su provincia, estado o región todavía no esté verificado. El filtro geográfico se aplica únicamente a los datos con evidencia.

| País | Clubes con ciudad explícita | Clubes con provincia/estado explícito |
|---|---:|---:|
| Brasil | 101 | 4 |
| Chile | 39 | 0 |
| Colombia | 32 | 0 |
| Ecuador | 23 | 0 |
| Uruguay | 37 | 0 |
| **Total** | **232** | **4** |

Las ciudades se extrajeron del domicilio publicado en la ficha del club. Las cuatro regiones verificadas proceden también del domicilio explícito:

| Club | Ciudad | Estado | Fuente |
|---|---|---|---|
| Clube Náutico Marcílio Dias (SC) | Itajaí | Santa Catarina | [Ficha del club](https://www.transfermarkt.com/clube-nautico-marcilio-dias-sc-/startseite/verein/4759) |
| EC Democrata | Governador Valadares | Minas Gerais | [Ficha del club](https://www.transfermarkt.com/ec-democrata-mg-/startseite/verein/3364) |
| Várzea Grande EC (MT) | Várzea Grande | Mato Grosso | [Ficha del club](https://www.transfermarkt.com/operario-futebol-clube-ltda-mt-/startseite/verein/32542) |
| São Raimundo EC (PA) | Santarém | Pará | [Ficha del club](https://www.transfermarkt.com/sao-raimundo-esporte-clube-pa-/startseite/verein/32192) |

Los demás campos geográficos quedan en `NULL`. No se deduce una región por el nombre del club, por conocer informalmente su ciudad ni por competir en un torneo estadual. La clave existente de región, cuando se conoce, conserva su formato estable; por ejemplo, `Brasil — Santa Catarina`.

**Otro club** continúa disponible para un equipo que no figure en el catálogo. El socio puede indicar su país, provincia/estado/región, ciudad, nombre y liga; esa información conserva su procedencia manual hasta la revisión correspondiente.

## Fuentes de las 42 competiciones

Las siguientes páginas públicas de Transfermarkt fueron consultadas el **19/11/2026** y muestran la edición **2026**. El número indica filas de clubes en esa fuente: no se deben sumar para obtener clubes únicos, porque un club puede aparecer en varias competiciones. Las URLs son las observadas durante la revisión, incluidas sus variantes de nombre.

### Ligas nacionales y copas: 16 fuentes

| País | Competición publicada | ID de Transfermarkt | Clubes en la fuente | Fuente |
|---|---|---|---:|---|
| Brasil | Série A | `BRA1` | 20 | [Fuente 2026](https://www.transfermarkt.com/campeonato-brasileiro-serie-a/startseite/wettbewerb/BRA1) |
| Brasil | Série B | `BRA2` | 20 | [Fuente 2026](https://www.transfermarkt.com/campeonato-brasileiro-serie-b/startseite/wettbewerb/BRA2) |
| Brasil | Série C | `BRA3` | 20 | [Fuente 2026](https://www.transfermarkt.com/campeonato-brasileiro-serie-c/teilnehmer/pokalwettbewerb/BRA3) |
| Brasil | Série D | `BRA4` | 96 | [Fuente 2026](https://www.transfermarkt.com/campeonato-brasileiro-serie-d/teilnehmer/pokalwettbewerb/BRA4) |
| Brasil | Copa do Brasil | `BRC` | 126 | [Fuente 2026](https://www.transfermarkt.com/kopa-do-burajiru/teilnehmer/pokalwettbewerb/BRC) |
| Chile | Segunda División | `CHI3` | 14 | [Fuente 2026](https://www.transfermarkt.com/segunda-division-profesional/startseite/wettbewerb/CHI3) |
| Chile | Liga de Ascenso | `CL2B` | 16 | [Fuente 2026](https://www.transfermarkt.com/liga-de-ascenso/startseite/wettbewerb/CL2B) |
| Chile | Liga Primera | `CLPD` | 16 | [Fuente 2026](https://www.transfermarkt.com/liga-de-primera/startseite/wettbewerb/CLPD) |
| Colombia | Torneo DIMAYOR II | `CO22` | 16 | [Fuente 2026](https://www.transfermarkt.com/torneo-dimayor-ii/startseite/wettbewerb/CO22) |
| Colombia | Liga DIMAYOR II | `COL1` | 20 | [Fuente 2026](https://www.transfermarkt.com/liga-dimayor-finalizacion/startseite/wettbewerb/COL1) |
| Ecuador | LigaPro Serie A | `EC1N` | 16 | [Fuente 2026](https://www.transfermarkt.com/ligapro-serie-a/startseite/wettbewerb/EC1N) |
| Ecuador | Liga Pro Serie B | `EC2L` | 12 | [Fuente 2026](https://www.transfermarkt.com/liga-pro-serie-b/startseite/wettbewerb/EC2L) |
| Ecuador | Copa Ecuador | `ECUP` | 51 | [Fuente 2026](https://www.transfermarkt.com/copa-ecuador/teilnehmer/pokalwettbewerb/ECUP) |
| Uruguay | Segunda División | `URU2` | 14 | [Fuente 2026](https://www.transfermarkt.com/segunda-division-fase-regular/startseite/wettbewerb/URU2) |
| Uruguay | Liga AUF Clausura | `URUC` | 16 | [Fuente 2026](https://www.transfermarkt.com/liga-auf-clausura/startseite/wettbewerb/URUC) |
| Uruguay | Copa AUF Uruguay | `URP1` | 44 | [Fuente 2026](https://www.transfermarkt.com/copa-auf-uruguay/teilnehmer/pokalwettbewerb/URP1) |

### Campeonatos estaduales brasileños: 26 fuentes

| Competición publicada | ID de Transfermarkt | Clubes en la fuente | Fuente |
|---|---|---:|---|
| Campeonato Acreano | `BRAC` | 8 | [Fuente 2026](https://www.transfermarkt.com/campeonato-acreano/teilnehmer/pokalwettbewerb/BRAC) |
| Campeonato Alagoano | `BRAL` | 9 | [Fuente 2026](https://www.transfermarkt.com/cempionat-alagoano/teilnehmer/pokalwettbewerb/BRAL) |
| Campeonato Amapaense | `BRAP` | 8 | [Fuente 2026](https://www.transfermarkt.com/campeonato-amapaense/teilnehmer/pokalwettbewerb/BRAP) |
| Campeonato Baiano | `BRCB` | 10 | [Fuente 2026](https://www.transfermarkt.com/campeonato-baiano/teilnehmer/pokalwettbewerb/BRCB) |
| Campeonato Brasiliense | `BRDF` | 10 | [Fuente 2026](https://www.transfermarkt.com/campeonato-brasiliense/teilnehmer/pokalwettbewerb/BRDF) |
| Campeonato Capixaba | `BRES` | 10 | [Fuente 2026](https://www.transfermarkt.com/campeonato-capixaba/teilnehmer/pokalwettbewerb/BRES) |
| Campeonato Carioca | `BRCG` | 12 | [Fuente 2026](https://www.transfermarkt.com/campeonato-carioca/teilnehmer/pokalwettbewerb/BRCG) |
| Campeonato Catarinense | `BRSC` | 12 | [Fuente 2026](https://www.transfermarkt.com/campeonato-catarinense/teilnehmer/pokalwettbewerb/BRSC) |
| Campeonato Cearense | `BRCE` | 10 | [Fuente 2026](https://www.transfermarkt.com/campeonato-cearense/teilnehmer/pokalwettbewerb/BRCE) |
| Campeonato Gaúcho | `BRRS` | 12 | [Fuente 2026](https://www.transfermarkt.com/campeonato-gaucho/teilnehmer/pokalwettbewerb/BRRS) |
| Campeonato Goiano | `BRGO` | 12 | [Fuente 2026](https://www.transfermarkt.com/campeonato-goiano/teilnehmer/pokalwettbewerb/BRGO) |
| Campeonato Maranhense | `BRMA` | 8 | [Fuente 2026](https://www.transfermarkt.com/campeonato-maranhense/teilnehmer/pokalwettbewerb/BRMA) |
| Campeonato Mato-Grossense | `BRMS` | 10 | [Fuente 2026](https://www.transfermarkt.com/campeonato-mato-grossense/teilnehmer/pokalwettbewerb/BRMS) |
| Campeonato Mineiro | `BRCM` | 12 | [Fuente 2026](https://www.transfermarkt.com/campeonato-mineiro/teilnehmer/pokalwettbewerb/BRCM) |
| Campeonato Paraense | `BRPA` | 12 | [Fuente 2026](https://www.transfermarkt.com/campeonato-paraense/teilnehmer/pokalwettbewerb/BRPA) |
| Campeonato Paraibano | `BRPB` | 10 | [Fuente 2026](https://www.transfermarkt.com/campeonato-paraibano/teilnehmer/pokalwettbewerb/BRPB) |
| Campeonato Paranaense | `BRPR` | 12 | [Fuente 2026](https://www.transfermarkt.com/campeonato-paranaense/teilnehmer/pokalwettbewerb/BRPR) |
| Campeonato Paulista | `BCP1` | 16 | [Fuente 2026](https://www.transfermarkt.com/campeonato-paulista/startseite/wettbewerb/BCP1) |
| Campeonato Pernambucano | `BRPE` | 8 | [Fuente 2026](https://www.transfermarkt.com/kanpionato-perunanbukano/teilnehmer/pokalwettbewerb/BRPE) |
| Campeonato Piauiense | `BRPI` | 8 | [Fuente 2026](https://www.transfermarkt.com/campeonato-piauiense/startseite/wettbewerb/BRPI) |
| Campeonato Potiguar | `BRRN` | 8 | [Fuente 2026](https://www.transfermarkt.com/campeonato-potiguar/teilnehmer/pokalwettbewerb/BRRN) |
| Campeonato Rondoniense | `BRRD` | 7 | [Fuente 2026](https://www.transfermarkt.com/campeonato-rondoniense/teilnehmer/pokalwettbewerb/BRRD) |
| Campeonato Roraimense | `BRRR` | 9 | [Fuente 2026](https://www.transfermarkt.com/campeonato-roraimense/teilnehmer/pokalwettbewerb/BRRR) |
| Campeonato Sergipano | `BRSE` | 10 | [Fuente 2026](https://www.transfermarkt.com/campeonato-sergipano/teilnehmer/pokalwettbewerb/BRSE) |
| Campeonato Sul-Mato-Grossense | `BRMT` | 10 | [Fuente 2026](https://www.transfermarkt.com/campeonato-sul-mato-grossense/teilnehmer/pokalwettbewerb/BRMT) |
| Campeonato Tocantinense | `BRTO` | 8 | [Fuente 2026](https://www.transfermarkt.com/campeonato-tocantinense/teilnehmer/pokalwettbewerb/BRTO) |

### Límites de la cobertura deportiva

El núcleo de las 13 ligas nacionales aporta 296 clubes únicos. Estaduales y copas amplían el conjunto a 458. La Copa Ecuador aporta 23 clubes fuera de las dos ligas nacionales revisadas y la Copa AUF Uruguay aporta 20 fuera de Primera y Segunda. Esos clubes reciben la **membresía de copa realmente verificada**; no una adscripción imaginada a una liga inferior.

El [Campeonato Amazonense consultado](https://www.transfermarkt.com/campeonato-amazonense/teilnehmer/pokalwettbewerb/BRAM) publica la edición **2024**. Se conserva como exclusión y no se renombra como 2026. Un club de Amazonas puede aparecer por otra competición actual que sí tenga evidencia.

No se verificó en esta adquisición una nómina nacional adicional para Chile Tercera A/B, Ecuador Segunda Categoría, Uruguay Divisional C/D/OFI o Colombia Primera C. Que esas opciones existan en la estructura de competencias de la plataforma no significa que sus clubes o plantillas estén cargados. La presencia de clubes inferiores mediante una copa tampoco equivale a cubrir toda su liga.

Este corte no representa todos los clubes de los cinco países ni toda la base de Transfermarkt. La cifra global de clubes de una captura del proveedor es una referencia de escala y no un conteo por país ni un denominador comprobado para este catálogo.

## Identidad, temporadas y valores

La identidad se apoya en el ID numérico y la URL de perfil de Transfermarkt, nunca únicamente en un nombre. El nombre publicado se conserva literalmente. Un nombre deportivo de una sola palabra se identifica como `sporting_mononym` y mantiene el apellido vacío; no se inventa un apellido. Para los demás, la separación de campos se declara como partición del nombre mostrado, sin afirmar que sea el nombre legal completo. La fecha de nacimiento sólo se incorpora cuando la fila fuente aporta una fecha exacta. Las posiciones ambiguas permanecen sin asignación automática.

La temporada de la competencia, la etiqueta del plantel y el parámetro de URL son campos distintos. Las 42 listas de participantes revisadas están rotuladas **2026**; las etiquetas literales de los 559 planteles son `2026`, `25/26` o `26/27` y se conservan tal como aparecen. Por ejemplo, una opción seleccionada `2026` puede tener `value="2025"`. La fecha de consulta no reemplaza la temporada ni la fecha del hecho deportivo.

Las tablas de planteles pueden mostrar un importe de mercado, pero no aportan una fecha individual de valuación verificable. Por eso, **esta ampliación no publica esos importes como valores vigentes**: los campos verificables de importe y fecha quedan vacíos y corresponde mostrar **«sin valor informado»**. La observación textual de la fuente queda en la evidencia. Los valores previamente verificados no se sobrescriben con vacíos al reconciliar identidades existentes.

## Panel compartido, auditoría y Polygon

Se mantiene la premisa **«Paredes de cristal»**: los socios activos y administradores acceden al mismo tablero, listado, detalle e historial global de recomendaciones. Elegir un país en el formulario o en el catálogo no limita el feed, el ranking ni el tablero a ese país, ni oculta aportes de otros socios. La antigüedad no determina la visibilidad o la prioridad deportiva de una recomendación.

La recomendación se inicia desde el panel del socio activo. El administrador conserva las actuaciones autorizadas —como contactado, visitado y prueba realizada—, con identidad del actor, fecha y transición de estado en el historial. Las recomendaciones repetidas se agregan en el conteo del jugador sin borrar la autoría y evidencia de cada aporte. El contrato y la auditoría se detallan en [Scouting: backend](scouting-backend.md).

La ampliación del catálogo no activa la integración institucional de Polygon. Las recomendaciones y actuaciones siguen entrando en la auditoría existente y sus lotes pendientes; los eventos y lotes conservan sus fechas, rangos y compromisos para el anclaje posterior cuando se habilite institucionalmente. Se distinguen registro guardado, lote preparado, envío y anclaje confirmado. Sólo una constancia de cadena válida permite mostrar el último estado. Un hash local o un lote preparado no equivalen a confirmación en Polygon; véase [acumulación de lotes con Polygon inactiva](scouting-backend.md#acumulación-de-lotes-con-polygon-inactiva).

El alcance de este trabajo es **Scouting**. Comunidad Formativa y sus recorridos quedan fuera de esta ampliación.

## Archivos, validación y actualización

Los artefactos versionados de este corte son:

| Archivo | Contenido |
|---|---|
| [`scouting/catalogue-south-america-2026-11-19.json.xz`](../scouting/catalogue-south-america-2026-11-19.json.xz) | Hechos completos: clubes, planteles, filas de jugadores, fuentes, exclusiones, conflictos y huellas de evidencia. |
| [`scouting/catalogue-south-america-2026-11-19.sources.json.gz`](../scouting/catalogue-south-america-2026-11-19.sources.json.gz) | Índice de las 42 competiciones, relación de clubes, reservas y exclusión de la edición Amazonense 2024. |
| [`scouting/catalogue-south-america-2026-11-19.coverage.json`](../scouting/catalogue-south-america-2026-11-19.coverage.json) | Recuentos por país, fuentes vacías e históricas, geografía documentada y límites. |
| [`scouting/catalogue-south-america-2026-11-19.validation.json`](../scouting/catalogue-south-america-2026-11-19.validation.json) | Validaciones, hashes, tamaños y manifiesto de plantillas elegibles. |

El archivo de hechos usa XZ para reducir el tamaño de transporte; el índice y el paquete de importaciones usan gzip reproducible con `mtime=0`. Se comprobó la descompresión exacta y ninguno contiene HTML crudo. El JSON de hechos sin comprimir tiene SHA-256 `bdfe8e85ecba7fd7abddd906548006af72ef62c2e2834eacb7d3fe3ae763adaf`; su XZ tiene SHA-256 `388d67028cebb99992d720c7f3277a944106822430da2fb4d1b0f1d4d6b0006d`. Leer XZ con `lzma.open` y gzip con `gzip.open`; el cambio de compresión no modifica los datos ni su hash descomprimido. El manifiesto es la referencia para comprobar los demás archivos.

Los scripts reutilizables operan sobre evidencia ya recuperada y requieren un directorio explícito:

```bash
python scripts/discover-scouting-south-america.py --directory /ruta/a/la/revision
python scripts/parse-scouting-south-america-rosters.py --directory /ruta/a/la/revision
python scripts/build-scouting-country-import-templates.py --directory /ruta/a/la/revision
```

El primero organiza participantes de las fuentes guardadas, el segundo extrae filas con identidad y procedencia, y el tercero genera `import-templates/{br,cl,co,ec,uy}-{clubs,rosters}.template.json` y `import-templates/manifest.json`. Esas plantillas son insumos de revisión: sus marcadores `REQUIRES_CURRENT_COUNTRY_FINGERPRINT` deben reemplazarse por las huellas vigentes de la base antes de cada transacción autorizada. La conciliación de identidades es global y precede a la división en lotes.

El procedimiento de actualización y publicación está en [Actualización mensual del catálogo de scouting](scouting-monthly-refresh.md). Cada revisión mensual necesita fuentes y fechas nuevas; ejecutar el parser sobre este corte congelado no lo convierte en una actualización del mes siguiente. El archivo histórico se conserva y el siguiente corte se publica con fecha e integridad propias.
