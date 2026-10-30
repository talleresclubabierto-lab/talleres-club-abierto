-- Verified player details and two officially corroborated club corrections.
-- Snapshot: scouting/catalogue-player-details-2026-10-30.json
-- SHA-256: 23d77f77bb21429e55a4c4bb7dd638c71ea192d372558b91b3009ffb2ef70257
-- One dated enrichment, not a recurring importer. Preserve the full October snapshot.
set local lock_timeout='5s';
set local statement_timeout='45s';

do $player_details_import$
declare
  v_document jsonb := $player_details_document$
{
  "metadata": {
    "schema_version": 1,
    "batch_key": "argentina-player-details-2026-10-30",
    "scope": "player_details_enrichment",
    "country": "Argentina",
    "reviewed_at": "2026-10-30T18:49:30Z",
    "base_snapshot": "scouting/catalogue-argentina-2026-10.json",
    "base_catalogue_batch_key": "argentina-manual-2026-10-29",
    "player_count": 21,
    "verified_birth_dates": 21,
    "verified_market_values": 20,
    "corrected_affiliations": 2,
    "provenance": "Lectura individual de perfiles públicos de Transfermarkt y corroboración de pertenencias con comunicados oficiales. Los datos de valoración conservan su fecha de referencia y la consulta por separado.",
    "limitations": "La valoración es una referencia publicada por Transfermarkt, no una oferta ni el precio de una transferencia. La edad se calcula desde la fecha de nacimiento verificada. Este enriquecimiento no sustituye el catálogo completo ni sus referencias pendientes.",
    "history_policy": "Conservar UUID, source_key, recomendaciones, eventos y snapshots previos. No asumir retornos o extensiones al finalizar un préstamo."
  },
  "players": [
    {
      "source_key": "manual-talleres-2026-tm-376858",
      "full_name": "Gabriel Alejandro Báez Corradi",
      "transfermarkt_id": "376858",
      "identity_reference_url": "https://www.transfermarkt.com/gabriel-baez/profil/spieler/376858",
      "birth_date": "1995-07-21",
      "birth_date_source_url": "https://www.transfermarkt.com/gabriel-baez/profil/spieler/376858",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 31,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 600000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/gabriel-baez/profil/spieler/376858",
        "provider": "Transfermarkt",
        "source_display": "€600K"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Gabriel Báez - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "1995-07-21; 31 años; 600000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-1197308",
      "full_name": "Santino Barbi",
      "transfermarkt_id": "1197308",
      "identity_reference_url": "https://www.transfermarkt.com/santino-barbi/profil/spieler/1197308",
      "birth_date": "2005-06-14",
      "birth_date_source_url": "https://www.transfermarkt.com/santino-barbi/profil/spieler/1197308",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 21,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 200000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/santino-barbi/profil/spieler/1197308",
        "provider": "Transfermarkt",
        "source_display": "€200K"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Santino Barbi - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "2005-06-14; 21 años; 200000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-1265841",
      "full_name": "Giovanni Emir Baroni",
      "transfermarkt_id": "1265841",
      "identity_reference_url": "https://www.transfermarkt.com/giovanni-baroni/profil/spieler/1265841",
      "birth_date": "2009-01-21",
      "birth_date_source_url": "https://www.transfermarkt.com/giovanni-baroni/profil/spieler/1265841",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 17,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 2500000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/giovanni-baroni/profil/spieler/1265841",
        "provider": "Transfermarkt",
        "source_display": "€2.5M"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Giovanni Baroni - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "2009-01-21; 17 años; 2500000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-737920",
      "full_name": "Bruno Barticciotto Di Bartolo",
      "transfermarkt_id": "737920",
      "identity_reference_url": "https://www.transfermarkt.com/bruno-barticciotto/profil/spieler/737920",
      "birth_date": "2001-05-07",
      "birth_date_source_url": "https://www.transfermarkt.com/bruno-barticciotto/profil/spieler/737920",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 25,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 1500000,
        "currency": "EUR",
        "as_of": "2026-09-17",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/bruno-barticciotto/profil/spieler/737920",
        "provider": "Transfermarkt",
        "source_display": "€1.5M"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Bruno Barticciotto - Player profile 2026",
      "source_valuation_label": "Last update: 17/09/2026",
      "evidence_excerpt": "2001-05-07; 25 años; 1500000 EUR; valoración 2026-09-17.",
      "affiliation_review": {
        "status": "resolved_by_official_announcement",
        "current_club_source_key": "ar-caba-huracan",
        "official_source_url": "https://www.clubtalleres.com.ar/informacion-de-mercado-las-ultimas-novedades-en-el-mundo-talleres/",
        "announcement_date": "2026-09-02",
        "checked_at": "2026-10-30T18:43:29Z",
        "previous_roster_discrepancy": "La página general Plantel Profesional de Talleres todavía lo lista. El comunicado específico del propio club identifica su salida y coincide con el perfil TM actual."
      },
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-907835",
      "full_name": "Mateo Valentín Cáceres",
      "transfermarkt_id": "907835",
      "identity_reference_url": "https://www.transfermarkt.com/mateo-caceres/profil/spieler/907835",
      "birth_date": "2002-09-25",
      "birth_date_source_url": "https://www.transfermarkt.com/mateo-caceres/profil/spieler/907835",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 24,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 500000,
        "currency": "EUR",
        "as_of": "2026-09-17",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/mateo-caceres/profil/spieler/907835",
        "provider": "Transfermarkt",
        "source_display": "€500K"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Mateo Cáceres - Player profile 2026",
      "source_valuation_label": "Last update: 17/09/2026",
      "evidence_excerpt": "2002-09-25; 24 años; 500000 EUR; valoración 2026-09-17.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-237051",
      "full_name": "Matías Ezequiel Catalán Echevarría",
      "transfermarkt_id": "237051",
      "identity_reference_url": "https://www.transfermarkt.com/matias-catalan/profil/spieler/237051",
      "birth_date": "1992-08-19",
      "birth_date_source_url": "https://www.transfermarkt.com/matias-catalan/profil/spieler/237051",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 34,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 500000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/matias-catalan/profil/spieler/237051",
        "provider": "Transfermarkt",
        "source_display": "€500K"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Matías Catalán - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "1992-08-19; 34 años; 500000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-1296331",
      "full_name": "Emiliano Miguel Chiavassa",
      "transfermarkt_id": "1296331",
      "identity_reference_url": "https://www.transfermarkt.com/emiliano-chiavassa/profil/spieler/1296331",
      "birth_date": "2006-01-02",
      "birth_date_source_url": "https://www.transfermarkt.com/emiliano-chiavassa/profil/spieler/1296331",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 20,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 25000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/emiliano-chiavassa/profil/spieler/1296331",
        "provider": "Transfermarkt",
        "source_display": "€25K"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Emiliano Chiavassa - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "2006-01-02; 20 años; 25000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-332259",
      "full_name": "Franco Cristaldo",
      "transfermarkt_id": "332259",
      "identity_reference_url": "https://www.transfermarkt.com/franco-cristaldo/profil/spieler/332259",
      "birth_date": "1996-08-15",
      "birth_date_source_url": "https://www.transfermarkt.com/franco-cristaldo/profil/spieler/332259",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 30,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 3500000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/franco-cristaldo/profil/spieler/332259",
        "provider": "Transfermarkt",
        "source_display": "€3.5M"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Franco Cristaldo - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "1996-08-15; 30 años; 3500000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-1280274",
      "full_name": "Valentín Dávila",
      "transfermarkt_id": "1280274",
      "identity_reference_url": "https://www.transfermarkt.com/valentin-davila/profil/spieler/1280274",
      "birth_date": "2007-01-19",
      "birth_date_source_url": "https://www.transfermarkt.com/valentin-davila/profil/spieler/1280274",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 19,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 1500000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/valentin-davila/profil/spieler/1280274",
        "provider": "Transfermarkt",
        "source_display": "€1.5M"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Valentín Dávila - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "2007-01-19; 19 años; 1500000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-697056",
      "full_name": "Valentín Depietri",
      "transfermarkt_id": "697056",
      "identity_reference_url": "https://www.transfermarkt.com/valentin-depietri/profil/spieler/697056",
      "birth_date": "2000-10-31",
      "birth_date_source_url": "https://www.transfermarkt.com/valentin-depietri/profil/spieler/697056",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 25,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 500000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/valentin-depietri/profil/spieler/697056",
        "provider": "Transfermarkt",
        "source_display": "€500K"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Valentín Depietri - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "2000-10-31; 25 años; 500000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-1106217",
      "full_name": "Santiago Abel Fernández",
      "transfermarkt_id": "1106217",
      "identity_reference_url": "https://www.transfermarkt.com/santiago-fernandez/profil/spieler/1106217",
      "birth_date": "2005-03-30",
      "birth_date_source_url": "https://www.transfermarkt.com/santiago-fernandez/profil/spieler/1106217",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 21,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 4500000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/santiago-fernandez/profil/spieler/1106217",
        "provider": "Transfermarkt",
        "source_display": "€4.5M"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Santiago Fernández - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "2005-03-30; 21 años; 4500000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-1197896",
      "full_name": "Jeremías Nisael Florentín",
      "transfermarkt_id": "1197896",
      "identity_reference_url": "https://www.transfermarkt.com/jeremias-florentin/profil/spieler/1197896",
      "birth_date": "2006-09-01",
      "birth_date_source_url": "https://www.transfermarkt.com/jeremias-florentin/profil/spieler/1197896",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 20,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": null,
      "market_value_status": "provider_displays_no_value",
      "market_value_confidence": null,
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age"
      ],
      "source_title": "Jeremías Florentín - Player profile 2026",
      "source_valuation_label": null,
      "evidence_excerpt": "2006-09-01; 20 años; valor de mercado mostrado: -.",
      "affiliation_review": null,
      "category_scope_note": "TM lo incluye en CA Talleres II; conservar evidencia oficial previa de participación de Primera y no inferir categoría exclusiva desde la ficha TM."
    },
    {
      "source_key": "manual-talleres-2026-tm-909737",
      "full_name": "Matías Alejandro Galarza",
      "transfermarkt_id": "909737",
      "identity_reference_url": "https://www.transfermarkt.com/matias-galarza/profil/spieler/909737",
      "birth_date": "2002-03-04",
      "birth_date_source_url": "https://www.transfermarkt.com/matias-galarza/profil/spieler/909737",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 24,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 5500000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/matias-galarza/profil/spieler/909737",
        "provider": "Transfermarkt",
        "source_display": "€5.5M"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Matías Galarza - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "2002-03-04; 24 años; 5500000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-1271301",
      "full_name": "Jeremías Gallard",
      "transfermarkt_id": "1271301",
      "identity_reference_url": "https://www.transfermarkt.com/jeremias-gallard/profil/spieler/1271301",
      "birth_date": "2004-04-10",
      "birth_date_source_url": "https://www.transfermarkt.com/jeremias-gallard/profil/spieler/1271301",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 22,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 25000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/jeremias-gallard/profil/spieler/1271301",
        "provider": "Transfermarkt",
        "source_display": "€25K"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Jeremías Gallard - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "2004-04-10; 22 años; 25000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": "TM lo incluye en CA Talleres II; conservar evidencia oficial previa de participación de Primera y no inferir categoría exclusiva desde la ficha TM."
    },
    {
      "source_key": "manual-talleres-2026-tm-1150517",
      "full_name": "Matías Ezequiel Gómez",
      "transfermarkt_id": "1150517",
      "identity_reference_url": "https://www.transfermarkt.com/matias-gomez/profil/spieler/1150517",
      "birth_date": "2005-11-23",
      "birth_date_source_url": "https://www.transfermarkt.com/matias-gomez/profil/spieler/1150517",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 20,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 75000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/matias-gomez/profil/spieler/1150517",
        "provider": "Transfermarkt",
        "source_display": "€75K"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Matías Gómez - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "2005-11-23; 20 años; 75000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-645955",
      "full_name": "Rick Jhonatan Lima Morais",
      "transfermarkt_id": "645955",
      "identity_reference_url": "https://www.transfermarkt.com/rick/profil/spieler/645955",
      "birth_date": "1999-09-02",
      "birth_date_source_url": "https://www.transfermarkt.com/rick/profil/spieler/645955",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 27,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 2500000,
        "currency": "EUR",
        "as_of": "2026-09-17",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/rick/profil/spieler/645955",
        "provider": "Transfermarkt",
        "source_display": "€2.5M"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Rick - Player profile 2026",
      "source_valuation_label": "Last update: 17/09/2026",
      "evidence_excerpt": "1999-09-02; 27 años; 2500000 EUR; valoración 2026-09-17.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-1371519",
      "full_name": "Alexandro Maidana Mendieta",
      "transfermarkt_id": "1371519",
      "identity_reference_url": "https://www.transfermarkt.es/alexandro-maidana/profil/spieler/1371519",
      "birth_date": "2005-07-26",
      "birth_date_source_url": "https://www.transfermarkt.es/alexandro-maidana/profil/spieler/1371519",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 21,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 2500000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.es/alexandro-maidana/profil/spieler/1371519",
        "provider": "Transfermarkt",
        "source_display": "2,5 M€"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Alexandro Maidana - Perfil del jugador 2026",
      "source_valuation_label": "Última revisión: 22/05/2026",
      "evidence_excerpt": "2005-07-26; 21 años; 2500000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-670566",
      "full_name": "Augusto Schott",
      "transfermarkt_id": "670566",
      "identity_reference_url": "https://www.transfermarkt.com/augusto-schott/profil/spieler/670566",
      "birth_date": "2000-01-17",
      "birth_date_source_url": "https://www.transfermarkt.com/augusto-schott/profil/spieler/670566",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 26,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 1200000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/augusto-schott/profil/spieler/670566",
        "provider": "Transfermarkt",
        "source_display": "€1.2M"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Augusto Schott - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "2000-01-17; 26 años; 1200000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-659264",
      "full_name": "Juan Sebastián Sforza",
      "transfermarkt_id": "659264",
      "identity_reference_url": "https://www.transfermarkt.com/juan-sforza/profil/spieler/659264",
      "birth_date": "2002-02-14",
      "birth_date_source_url": "https://www.transfermarkt.com/juan-sforza/profil/spieler/659264",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 24,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 1300000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/juan-sforza/profil/spieler/659264",
        "provider": "Transfermarkt",
        "source_display": "€1.3M"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Juan Sforza - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "2002-02-14; 24 años; 1300000 EUR; valoración 2026-05-22.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-413983",
      "full_name": "Diego Luis Valoyes Ruíz",
      "transfermarkt_id": "413983",
      "identity_reference_url": "https://www.transfermarkt.com/diego-valoyes/profil/spieler/413983",
      "birth_date": "1996-09-22",
      "birth_date_source_url": "https://www.transfermarkt.com/diego-valoyes/profil/spieler/413983",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 30,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 1200000,
        "currency": "EUR",
        "as_of": "2026-09-17",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/diego-valoyes/profil/spieler/413983",
        "provider": "Transfermarkt",
        "source_display": "€1.2M"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Diego Valoyes - Player profile 2026",
      "source_valuation_label": "Last update: 17/09/2026",
      "evidence_excerpt": "1996-09-22; 30 años; 1200000 EUR; valoración 2026-09-17.",
      "affiliation_review": null,
      "category_scope_note": null
    },
    {
      "source_key": "manual-talleres-2026-tm-648520",
      "full_name": "Alex Gamaliel Vigo",
      "transfermarkt_id": "648520",
      "identity_reference_url": "https://www.transfermarkt.com/alex-vigo/profil/spieler/648520",
      "birth_date": "1999-04-28",
      "birth_date_source_url": "https://www.transfermarkt.com/alex-vigo/profil/spieler/648520",
      "birth_date_verified_at": "2026-10-30T18:39:39Z",
      "birth_date_confidence": "high_public_primary_profile",
      "age": 27,
      "age_as_of": "2026-10-30",
      "age_method": "calculated_from_verified_birth_date",
      "market_value": {
        "amount": 600000,
        "currency": "EUR",
        "as_of": "2026-05-22",
        "verified_at": "2026-10-30T18:39:39Z",
        "source_url": "https://www.transfermarkt.com/alex-vigo/profil/spieler/648520",
        "provider": "Transfermarkt",
        "source_display": "€600K"
      },
      "market_value_status": "verified_provider_value",
      "market_value_confidence": "high_public_primary_profile",
      "verification_status": "verified_fields_individually",
      "verified_fields": [
        "birth_date",
        "age",
        "market_value_amount",
        "market_value_currency",
        "market_value_as_of"
      ],
      "source_title": "Alex Vigo - Player profile 2026",
      "source_valuation_label": "Last update: 22/05/2026",
      "evidence_excerpt": "1999-04-28; 27 años; 600000 EUR; valoración 2026-05-22.",
      "affiliation_review": {
        "status": "resolved_by_official_announcement",
        "current_club_source_key": "ar-mendoza-independiente-rivadavia",
        "official_source_url": "https://www.clubtalleres.com.ar/alex-vigo-continuara-su-carrera-en-independiente-rivadavia/",
        "announcement_date": "2026-08-08",
        "checked_at": "2026-10-30T18:43:29Z",
        "previous_roster_discrepancy": "La página general Plantel Profesional de Talleres todavía lo lista. El comunicado específico del propio club identifica su salida y coincide con el perfil TM actual."
      },
      "category_scope_note": null
    }
  ],
  "affiliation_changes": [
    {
      "source_key": "manual-talleres-2026-tm-648520",
      "player_name": "Alex Gamaliel Vigo",
      "transfermarkt_player_id": "648520",
      "expected_club_source_key": "ar-cordoba-talleres",
      "destination_club": {
        "source_key": "ar-mendoza-independiente-rivadavia",
        "name": "Club Sportivo Independiente Rivadavia",
        "province": "Mendoza",
        "city": "Mendoza"
      },
      "official_source": {
        "url": "https://www.clubtalleres.com.ar/alex-vigo-continuara-su-carrera-en-independiente-rivadavia/",
        "title": "Alex Vigo continuará su carrera en Independiente Rivadavia - Club Atlético Talleres",
        "published_at": "2026-08-08T13:00:00+00:00",
        "announcement_date": "2026-08-08",
        "checked_at": "2026-10-30T18:43:29Z",
        "summary": "Talleres anuncia la continuidad de Alex Vigo en Club Sportivo Independiente Rivadavia y conserva parte de sus derechos económicos. La ficha Transfermarkt actual coincide."
      },
      "transfermarkt_source": {
        "url": "https://www.transfermarkt.com/alex-vigo/profil/spieler/648520",
        "joined_date_displayed": "2026-08-08",
        "checked_at": "2026-10-30T18:43:29Z"
      },
      "transfer_type": "salida_anunciada_por_club_con_derechos_economicos_parciales_retenidos",
      "loan_until": null,
      "confidence": "high",
      "previous_conflict": "La página general Plantel Profesional de Talleres todavía lo lista. El comunicado específico del propio club identifica su salida y coincide con el perfil TM actual.",
      "monitoring_note": "No confundir retención de derechos económicos con pertenencia deportiva al plantel de Talleres."
    },
    {
      "source_key": "manual-talleres-2026-tm-737920",
      "player_name": "Bruno Barticciotto Di Bartolo",
      "transfermarkt_player_id": "737920",
      "expected_club_source_key": "ar-cordoba-talleres",
      "destination_club": {
        "source_key": "ar-caba-huracan",
        "name": "Club Atlético Huracán",
        "province": "Ciudad Autónoma de Buenos Aires",
        "city": "Ciudad Autónoma de Buenos Aires"
      },
      "official_source": {
        "url": "https://www.clubtalleres.com.ar/informacion-de-mercado-las-ultimas-novedades-en-el-mundo-talleres/",
        "title": "Información de mercado: las últimas novedades en el Mundo Talleres - Club Atlético Talleres",
        "published_at": "2026-09-02T16:51:03+00:00",
        "announcement_date": "2026-09-02",
        "checked_at": "2026-10-30T18:43:29Z",
        "summary": "Talleres anuncia el préstamo de Bruno Barticciotto a Club Atlético Huracán hasta31/12/2026, con opciones de extensión y compra. La ficha Transfermarkt actual coincide."
      },
      "transfermarkt_source": {
        "url": "https://www.transfermarkt.com/bruno-barticciotto/profil/spieler/737920",
        "joined_date_displayed": "2026-09-02",
        "checked_at": "2026-10-30T18:43:29Z"
      },
      "transfer_type": "prestamo_vigente",
      "loan_until": "2026-12-31",
      "confidence": "high",
      "previous_conflict": "La página general Plantel Profesional de Talleres todavía lo lista. El comunicado específico del propio club identifica su salida y coincide con el perfil TM actual.",
      "monitoring_note": "Revisar vigencia del préstamo antes de cualquier cambio posterior al31/12/2026; no asumir extensión ni retorno automáticamente."
    }
  ]
}
$player_details_document$::jsonb;
  v_hash text := '23d77f77bb21429e55a4c4bb7dd638c71ea192d372558b91b3009ffb2ef70257';
  v_batch text := v_document#>>'{metadata,batch_key}';
  v_run uuid;
  v_existing scouting.catalogue_runs%rowtype;
  v_item jsonb;
  v_change jsonb;
  v_player scouting.players%rowtype;
  v_destination scouting.clubs%rowtype;
  v_club_source_key text;
  v_before jsonb;
  v_after jsonb;
  v_updated integer := 0;
  v_rows integer;
  v_club_changes integer := 0;
  v_new_club_id uuid;
  v_checked_at timestamptz;
begin
  perform pg_advisory_xact_lock(hashtextextended('scouting.catalogue.refresh',0));
  lock table scouting.clubs in share row exclusive mode;
  lock table scouting.players in share row exclusive mode;

  select * into v_existing from scouting.catalogue_runs
    where metadata->>'batch_key'=v_batch order by created_at desc limit 1;
  if found then
    if v_existing.status='published' and v_existing.metadata->>'snapshot_sha256'=v_hash then
      raise notice 'Player details batch already published; no changes';
      return;
    end if;
    raise exception 'Player details batch key already exists with different content or unfinished state';
  end if;

  if jsonb_array_length(v_document->'players')<>21
    or (select count(distinct x->>'source_key') from jsonb_array_elements(v_document->'players') x)<>21
    or (select count(*) from scouting.players p join jsonb_array_elements(v_document->'players') x
      on x->>'source_key'=p.source_key)<>21 then
    raise exception 'Player identity coverage differs from the reviewed snapshot';
  end if;

  select jsonb_agg(to_jsonb(p)||jsonb_build_object('club_source_key',c.source_key) order by p.source_key)
    into v_before from scouting.players p join scouting.clubs c on c.id=p.club_id
    join jsonb_array_elements(v_document->'players') x on x->>'source_key'=p.source_key;

  insert into scouting.catalogue_runs(source,status,authorization_reference,metadata)
    values('reviewed_player_profile_fields_with_official_club_updates','staging',
      'User request: scouting shared dashboard, age and Transfermarkt market values, 2026-10-30',
      jsonb_build_object('batch_key',v_batch,'scope','player_details_enrichment','snapshot_sha256',v_hash,
        'snapshot_path','scouting/catalogue-player-details-2026-10-30.json',
        'base_catalogue_batch_key',v_document#>>'{metadata,base_catalogue_batch_key}',
        'document',v_document,'players_before',v_before)) returning id into v_run;

  for v_item in select value from jsonb_array_elements(v_document->'players') loop
    select * into strict v_player from scouting.players where source_key=v_item->>'source_key';
    if not v_player.active then raise exception 'A reviewed player was deliberately deactivated; reconcile before importing'; end if;
    if substring(v_player.transfermarkt_url from '/spieler/([0-9]+)') is distinct from v_item->>'transfermarkt_id'
      or substring(v_item->>'birth_date_source_url' from '/spieler/([0-9]+)') is distinct from v_item->>'transfermarkt_id' then
      raise exception 'Player profile identity changed since review';
    end if;
    if v_item->'market_value'<>'null'::jsonb
      and substring(v_item#>>'{market_value,source_url}' from '/spieler/([0-9]+)') is distinct from v_item->>'transfermarkt_id' then
      raise exception 'Market value source belongs to a different profile';
    end if;
    if v_player.birth_date is not null and
      (v_player.birth_date is distinct from (v_item->>'birth_date')::date
       or v_player.birth_date_verified_at>(v_item->>'birth_date_verified_at')::timestamptz) then
      raise exception 'A different or newer birth-date review exists; reconcile before importing';
    end if;
    if v_player.market_value_verified and
      (v_item->'market_value'='null'::jsonb
       or v_player.market_value_as_of>(v_item#>>'{market_value,as_of}')::date
       or v_player.market_value_verified_at>(v_item#>>'{market_value,verified_at}')::timestamptz
       or (v_player.market_value_as_of=(v_item#>>'{market_value,as_of}')::date
         and (v_player.market_value_amount is distinct from (v_item#>>'{market_value,amount}')::numeric
           or v_player.market_value_currency is distinct from v_item#>>'{market_value,currency}'))) then
      raise exception 'A newer or conflicting market-value review exists; reconcile before importing';
    end if;

    v_new_club_id:=v_player.club_id;
    v_checked_at:=v_player.checked_at;
    select value into v_change from jsonb_array_elements(v_document->'affiliation_changes')
      where value->>'source_key'=v_player.source_key;
    if found then
      select source_key into strict v_club_source_key from scouting.clubs where id=v_player.club_id;
      select * into strict v_destination from scouting.clubs where source_key=v_change#>>'{destination_club,source_key}';
      if not v_destination.active or v_destination.name is distinct from v_change#>>'{destination_club,name}'
        or v_destination.province is distinct from v_change#>>'{destination_club,province}'
        or v_destination.city is distinct from v_change#>>'{destination_club,city}' then
        raise exception 'Verified destination club no longer matches the catalogue';
      end if;
      if v_club_source_key<>v_change->>'expected_club_source_key' and v_player.club_id<>v_destination.id then
        raise exception 'Player club changed concurrently; preserve the newer affiliation for review';
      end if;
      if v_player.club_id<>v_destination.id then v_club_changes:=v_club_changes+1; end if;
      v_new_club_id:=v_destination.id;
      v_checked_at:=greatest(v_player.checked_at,(v_change#>>'{official_source,checked_at}')::timestamptz);
    end if;

    update scouting.players set
      birth_date=(v_item->>'birth_date')::date,
      birth_date_source_url=v_item->>'birth_date_source_url',
      birth_date_verified_at=(v_item->>'birth_date_verified_at')::timestamptz,
      market_value_amount=(v_item#>>'{market_value,amount}')::numeric,
      market_value_currency=v_item#>>'{market_value,currency}',
      market_value_source_url=v_item#>>'{market_value,source_url}',
      market_value_as_of=(v_item#>>'{market_value,as_of}')::date,
      market_value_verified_at=(v_item#>>'{market_value,verified_at}')::timestamptz,
      market_value_verified=v_item->'market_value'<>'null'::jsonb,
      club_id=v_new_club_id,checked_at=v_checked_at,catalogue_run_id=v_run
      where id=v_player.id and source_key=v_player.source_key;
    get diagnostics v_rows=row_count;
    if v_rows<>1 then raise exception 'Player update lost its stable identity'; end if;
    v_updated:=v_updated+v_rows;
  end loop;

  if v_updated<>21 or (select count(*) from scouting.players where catalogue_run_id=v_run and birth_date is not null)<>21
    or (select count(*) from scouting.players where catalogue_run_id=v_run and market_value_verified)<>20 then
    raise exception 'Published player-detail counts differ from reviewed evidence';
  end if;
  if (select count(*) from scouting.players p join jsonb_array_elements(v_document->'affiliation_changes') x
      on x->>'source_key'=p.source_key join scouting.clubs c on c.id=p.club_id
      where c.source_key=x#>>'{destination_club,source_key}')<>2 then
    raise exception 'Corroborated affiliations were not applied to their exact catalogue identities';
  end if;
  if exists(select 1 from jsonb_array_elements(v_before) old_row join scouting.players p
      on p.source_key=old_row->>'source_key' where p.id::text<>old_row->>'id' or p.active is distinct from (old_row->>'active')::boolean) then
    raise exception 'Player identity or prior active state changed';
  end if;
  select jsonb_agg(to_jsonb(p)||jsonb_build_object('club_source_key',c.source_key) order by p.source_key)
    into v_after from scouting.players p join scouting.clubs c on c.id=p.club_id where p.catalogue_run_id=v_run;
  update scouting.catalogue_runs set status='published',published_at=clock_timestamp(),
    metadata=metadata||jsonb_build_object('players_after',v_after,'updated_players',v_updated,
      'verified_birth_dates',21,'verified_market_values',20,'affiliations_corrected',v_club_changes,
      'preserved_recommendations',true,'preserved_events',true)
    where id=v_run;
end;
$player_details_import$;
