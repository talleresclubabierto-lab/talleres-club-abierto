#!/usr/bin/env python3
"""Package the completed 44-batch 2026-11-19 Scouting import, offline.

Release-operator helper: run only after all planned imports have receipts.
No network, database writes, deployment, or changes to source documents.

Example, from the repository root:
  python scripts/package-scouting-country-imports.py \
    --plan ../imports/pending/manifest.json \
    --receipts ../imports/receipts --applied ../imports/applied \
    --output-prefix scouting/catalogue-south-america-2026-11-19

The archive contains 44 documents as exact UTF-8 strings, not reserialized
JSON objects. Its manifest records database receipts, not web deployment.
Identical reruns are allowed; different existing outputs are never overwritten.
Complete release/web QA metadata only after the final packaging invocation.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import gzip
import hashlib
import io
import json
import os
from pathlib import Path
import re
import sys
import tempfile
from uuid import UUID


EXPECTED_BATCHES = 44
RELEASE_DATE = "2026-11-19"
COUNTRIES = {"BR": "Brasil", "CL": "Chile", "CO": "Colombia", "EC": "Ecuador", "UY": "Uruguay"}
HASH_RE = re.compile(r"^[a-f0-9]{64}$")
TM_ID_RE = re.compile(r"^[1-9][0-9]{0,11}$")
FINGERPRINT_KEYS = (
    "expected_clubs_sha256", "expected_players_sha256",
    "expected_competitions_sha256", "expected_club_competitions_sha256",
)
REQUIRED_BEFORE = {
    "clubs": (FINGERPRINT_KEYS[0], FINGERPRINT_KEYS[2], FINGERPRINT_KEYS[3]),
    "rosters": (FINGERPRINT_KEYS[0], FINGERPRINT_KEYS[1]),
}


class PackagingError(ValueError):
    """Evidence is incomplete or inconsistent; no package should be published."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise PackagingError(message)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def integer(value: object, label: str, minimum: int = 0) -> int:
    require(type(value) is int and value >= minimum, f"{label}: expected integer >= {minimum}")
    return value


def hash_value(value: object, label: str) -> str:
    require(isinstance(value, str) and HASH_RE.fullmatch(value) is not None, f"{label}: invalid SHA-256")
    return value


def file_name(value: object) -> str:
    require(isinstance(value, str) and re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*\.json", value) is not None,
            "A planned file name must be a plain relative JSON basename")
    return value


def unique_object(pairs: list[tuple[str, object]]) -> dict:
    result = {}
    for key, value in pairs:
        require(key not in result, f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def invalid_constant(value: str) -> None:
    raise PackagingError(f"Non-finite JSON number: {value}")


def parse_json(data: bytes, label: str) -> tuple[object, str]:
    try:
        text = data.decode("utf-8", errors="strict")
        value = json.loads(text, object_pairs_hook=unique_object, parse_constant=invalid_constant)
    except (UnicodeError, json.JSONDecodeError) as error:
        raise PackagingError(f"{label}: invalid UTF-8 JSON") from error
    require(text.encode("utf-8") == data, f"{label}: UTF-8 round trip changed bytes")
    return value, text


def read_json(path: Path, observed: dict[Path, str]) -> tuple[dict, str, bytes]:
    require(path.is_file() and not path.is_symlink(), f"Missing or symlinked input: {path.name}")
    raw = path.read_bytes()
    value, text = parse_json(raw, path.name)
    require(isinstance(value, dict), f"{path.name}: expected a JSON object")
    observed[path] = digest(raw)
    return value, text, raw


def no_local_paths(value: object, label: str) -> None:
    """Do not redact an applied document: rejecting it preserves its hash."""
    if isinstance(value, dict):
        for key, child in value.items():
            no_local_paths(key, label)
            no_local_paths(child, label)
    elif isinstance(value, list):
        for child in value:
            no_local_paths(child, label)
    elif isinstance(value, str):
        require(not value.startswith(("/", "\\", "file://"))
                and re.match(r"^[A-Za-z]:[\\/]", value) is None,
                f"{label}: absolute local path found; cannot alter applied evidence")


def no_errors(value: dict, label: str) -> None:
    for key in ("error", "errors", "failure", "failures", "error_count"):
        require(value.get(key) in (None, False, [], {}), f"{label}: nonempty {key}")
    require(value.get("isError") is not True and value.get("ok") is not False, f"{label}: failed result")
    require(value.get("status") not in ("error", "failed", "failure", "aborted"), f"{label}: failed status")


def inventory(directory: Path, expected: set[str], label: str) -> None:
    require(directory.is_dir(), f"Missing {label} directory")
    found = {path.name for path in directory.glob("*.json")}
    require(found == expected,
            f"{label}: require exactly 44/44 planned files; missing={sorted(expected - found)}, extra={sorted(found - expected)}")


def json_bytes(value: object, pretty: bool = False) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, allow_nan=False,
                       indent=2 if pretty else None,
                       separators=(",", ": ") if pretty else (",", ":")) + "\n").encode("utf-8")


def deterministic_gzip(raw: bytes) -> bytes:
    output = io.BytesIO()
    with gzip.GzipFile(filename="", mode="wb", fileobj=output, compresslevel=9, mtime=0) as archive:
        archive.write(raw)
    return output.getvalue()


def build_package(plan_path: Path, receipts_dir: Path, applied_dir: Path, prefix: Path) -> tuple[dict[Path, bytes], dict]:
    observed: dict[Path, str] = {}
    plan, _, plan_raw = read_json(plan_path, observed)
    require(plan.get("schema_version") == 1 and plan.get("date") == RELEASE_DATE, "Unexpected release plan/version")
    require(plan.get("batch_count") == EXPECTED_BATCHES, "Plan must declare exactly 44 batches")
    batches = plan.get("batches")
    require(isinstance(batches, list) and len(batches) == EXPECTED_BATCHES, "Plan must contain 44 batches")
    require(all(isinstance(batch, dict) for batch in batches), "Invalid plan batch")
    require([batch.get("sequence") for batch in batches] == list(range(1, EXPECTED_BATCHES + 1)), "Plan sequence must be 1..44 in execution order")
    names = [file_name(batch.get("relative_path")) for batch in batches]
    require(len(set(names)) == EXPECTED_BATCHES, "Duplicate planned file name")
    keys = [batch.get("batch_key") for batch in batches]
    require(all(isinstance(key, str) and re.fullmatch(r"[a-z0-9][a-z0-9-]{4,120}", key) for key in keys)
            and len(set(keys)) == EXPECTED_BATCHES, "Invalid or duplicate batch key")
    country_order = plan.get("country_order")
    require(isinstance(country_order, list) and all(isinstance(code, str) for code in country_order) and len(country_order) == len(COUNTRIES)
            and set(country_order) == set(COUNTRIES), "Plan must cover the five new countries exactly once")
    source_facts_hash = hash_value(plan.get("source_facts_sha256"), "Source facts")
    source_manifest_hash = hash_value(plan.get("source_manifest_sha256"), "Source manifest")
    excluded_list = plan.get("cross_club_player_conflicts_excluded")
    require(isinstance(excluded_list, list) and all(isinstance(item, str) and TM_ID_RE.fullmatch(item) for item in excluded_list)
            and len(set(excluded_list)) == len(excluded_list), "Invalid excluded identity list")
    excluded = set(excluded_list)
    limits = plan.get("limits", {})
    max_bytes = integer(limits.get("json_bytes"), "Plan byte limit", 1)
    inventory(receipts_dir, set(names), "Receipts")
    inventory(applied_dir, set(names), "Applied documents")

    documents, receipts = [], []
    totals = {code: Counter() for code in country_order}
    review_statuses = {code: Counter() for code in country_order}
    planned_totals = {code: {"clubs": Counter(), "rosters": Counter()} for code in country_order}
    after_by_country, run_ids, seen_roster_countries = {}, set(), set()
    club_ids, club_keys, competition_ids, squad_keys, player_clubs = {}, {}, set(), set(), {}
    country_players = defaultdict(set)
    last_country_index = -1
    previous_global = None
    first_global = None

    for batch, name in zip(batches, names):
        label = f"Batch {batch['sequence']} ({name})"
        country, mode = batch.get("country_code"), batch.get("mode")
        require(country in COUNTRIES and mode in REQUIRED_BEFORE and batch.get("country") == country, f"{label}: invalid country/mode")
        country_index = country_order.index(country)
        require(country_index >= last_country_index, f"{label}: country execution order differs from plan")
        last_country_index = country_index
        require(mode != "clubs" or country not in seen_roster_countries, f"{label}: club batch follows a roster batch")
        if mode == "rosters":
            seen_roster_countries.add(country)
        count = integer(batch.get("count"), label + " count", 1)
        require(count <= integer(limits.get("clubs_per_batch" if mode == "clubs" else "rosters_per_batch"), "Plan row limit", 1), f"{label}: exceeds planned row limit")
        template_hash = hash_value(batch.get("source_template_sha256"), label + " template")
        pending, _, pending_raw = read_json(plan_path.parent / name, observed)
        require(len(pending_raw) == batch.get("bytes") and digest(pending_raw) == batch.get("pending_sha256"), f"{label}: pending document differs from frozen plan")
        receipt, _, receipt_raw = read_json(receipts_dir / name, observed)
        no_errors(receipt, label + " receipt")
        document, document_text, raw = read_json(applied_dir / name, observed)
        no_local_paths(document, label + " document")
        content_hash = digest(raw)
        require(0 < len(raw) <= max_bytes, f"{label}: invalid applied byte length")
        require(len(raw) == batch.get("bytes_with_fingerprints") == receipt.get("bytes") == receipt.get("bytes_with_fingerprints"), f"{label}: byte counts disagree")
        require(content_hash == receipt.get("content_sha256"), f"{label}: applied SHA-256 differs from receipt")
        for key in ("batch_key", "sequence", "relative_path", "country", "country_code", "mode", "count", "new_competitions", "player_observations", "pending_sha256", "source_template_sha256"):
            require(receipt.get(key) == batch.get(key), f"{label}: receipt/plan mismatch in {key}")
        metadata = document.get("metadata")
        require(isinstance(metadata, dict) and metadata.get("batch_key") == batch["batch_key"]
                and metadata.get("country_code") == country and metadata.get("country") == COUNTRIES[country]
                and metadata.get("fingerprint_scope") == "country", f"{label}: invalid applied metadata")
        require(metadata.get("schema_version") == (1 if mode == "clubs" else 2), f"{label}: wrong document schema")
        require(mode != "clubs" or metadata.get("kind") == "reviewed_clubs", f"{label}: wrong club document kind")
        require(metadata.get("cross_club_player_conflicts_excluded") == excluded_list, f"{label}: excluded identities changed")
        preparation = metadata.get("preparation", {})
        require(preparation.get("source_facts_sha256") == source_facts_hash
                and preparation.get("source_manifest_sha256") == source_manifest_hash
                and preparation.get("source_template_sha256") == template_hash, f"{label}: source provenance differs from plan")
        required_keys = REQUIRED_BEFORE[mode]
        before = {key: hash_value(metadata.get(key), label + " " + key) for key in required_keys}
        require(isinstance(pending.get("metadata"), dict), f"{label}: pending metadata absent")
        require({key for key in metadata if key.startswith("expected_") and key.endswith("_sha256")} == set(required_keys), f"{label}: unexpected fingerprint fields")
        for key in required_keys:
            require(key in pending["metadata"], f"{label}: precondition was not planned")
            pending["metadata"][key] = before[key]
        require(pending == document, f"{label}: applied data changed beyond the planned fingerprint substitutions")

        result = receipt.get("result")
        require(isinstance(result, dict), f"{label}: database result missing")
        no_errors(result, label + " database result")
        no_local_paths(result, label + " database result")
        require(result.get("conflicts", []) == [] and result.get("observations_skipped", 0) == 0
                and result.get("membership_retirements", 0) == 0, f"{label}: unexpected conflicts, omissions or retirements")
        require(result.get("batch_key") == batch["batch_key"] and result.get("content_sha256") == content_hash
                and result.get("country_code") == country and type(result.get("replayed")) is bool, f"{label}: database receipt identity/hash mismatch")
        run_id = result.get("run_id")
        try:
            require(isinstance(run_id, str) and str(UUID(run_id)) == run_id and run_id not in run_ids, f"{label}: invalid or reused run_id")
        except (ValueError, AttributeError) as error:
            raise PackagingError(f"{label}: invalid run_id") from error
        run_ids.add(run_id)
        after = receipt.get("after_fingerprints")
        require(isinstance(after, dict) and after.get("country_code") == country
                and after.get("fingerprint_scope") == "country", f"{label}: after fingerprints missing")
        after = {"country_code": country, "fingerprint_scope": "country",
                 "club_count": integer(after.get("club_count"), label + " club_count"),
                 "player_count": integer(after.get("player_count"), label + " player_count"),
                 **{key: hash_value(after.get(key), label + " after " + key) for key in FINGERPRINT_KEYS}}
        previous = after_by_country.get(country)
        if previous:
            require(all(before[key] == previous[key] for key in required_keys), f"{label}: country fingerprint chain is broken")
        rows_key = "clubs" if mode == "clubs" else "squads"
        rows = document.get(rows_key)
        require(isinstance(rows, list) and len(rows) == count and all(isinstance(row, dict) for row in rows), f"{label}: planned row count differs")
        country_total = totals[country]
        country_total["batches"] += 1
        country_total["club_batches" if mode == "clubs" else "roster_batches"] += 1
        planned_totals[country][mode].update(batches=1, records=count)

        if mode == "clubs":
            competitions = document.get("competitions", [])
            require(isinstance(competitions, list) and all(isinstance(item, dict) for item in competitions)
                    and len(competitions) == batch.get("new_competitions"), f"{label}: planned competitions differ")
            for competition in competitions:
                comp_id = competition.get("id")
                require(isinstance(comp_id, str) and comp_id not in competition_ids, f"{label}: duplicate new competition")
                competition_ids.add(comp_id)
            memberships = 0
            for club in rows:
                tm_id, source_key = club.get("transfermarkt_id"), club.get("source_key")
                require(isinstance(tm_id, str) and TM_ID_RE.fullmatch(tm_id) is not None
                        and source_key == "tm-club-" + tm_id and tm_id not in club_ids and source_key not in club_keys,
                        f"{label}: duplicate or invalid global club identity")
                club_ids[tm_id] = country
                club_keys[source_key] = country
                links = club.get("competitions")
                require(isinstance(links, list) and links and all(isinstance(link, dict) for link in links), f"{label}: club competition links missing")
                link_keys = [(link.get("competition_id"), link.get("season")) for link in links]
                require(all(isinstance(a, str) and isinstance(b, str) for a, b in link_keys)
                        and len(set(link_keys)) == len(link_keys), f"{label}: duplicate/invalid club competition link")
                memberships += len(links)
            for key in ("clubs_inserted", "clubs_refreshed", "competitions_inserted", "club_competitions_observed", "clubs_after"):
                integer(result.get(key), label + " " + key)
            require(result["clubs_inserted"] + result["clubs_refreshed"] == count
                    and result["competitions_inserted"] == len(competitions)
                    and result["club_competitions_observed"] == memberships
                    and result["clubs_after"] == after["club_count"]
                    and batch.get("player_observations") == 0, f"{label}: club import counts disagree")
            if previous:
                require(after["club_count"] == previous["club_count"] + result["clubs_inserted"]
                        and after["player_count"] == previous["player_count"]
                        and after["expected_players_sha256"] == previous["expected_players_sha256"], f"{label}: club import changed players or wrong club count")
            for key in ("clubs_inserted", "clubs_refreshed", "competitions_inserted", "club_competitions_observed"):
                country_total[key] += result[key]
            country_total["clubs_observed"] += count
        else:
            ids = set()
            observations = 0
            for squad in rows:
                club_key, category = squad.get("club_source_key"), squad.get("category")
                require(club_keys.get(club_key) == country and isinstance(category, str), f"{label}: roster has an unplanned club/category")
                squad_key = (club_key, category)
                require(squad_key not in squad_keys, f"{label}: club/category split or repeated across batches")
                squad_keys.add(squad_key)
                players, status = squad.get("players"), squad.get("completeness")
                require(isinstance(players, list) and status in ("complete", "partial", "unavailable"), f"{label}: invalid squad coverage")
                require(status != "complete" or 0 < len(players) == squad.get("expected_count"), f"{label}: incomplete source marked complete")
                require(status != "unavailable" or not players, f"{label}: unavailable source contains observations")
                review_statuses[country][status] += 1
                in_squad = set()
                for player in players:
                    require(isinstance(player, dict), f"{label}: invalid player")
                    tm_id = player.get("transfermarkt_id")
                    require(isinstance(tm_id, str) and TM_ID_RE.fullmatch(tm_id) is not None
                            and tm_id not in in_squad and tm_id not in excluded, f"{label}: duplicate/excluded/invalid player identity")
                    require(tm_id not in player_clubs or player_clubs[tm_id] == club_key, f"{label}: player observed for more than one club/country")
                    player_clubs[tm_id] = club_key
                    in_squad.add(tm_id)
                    ids.add(tm_id)
                observations += len(players)
            require(observations == batch.get("player_observations"), f"{label}: planned player observations differ")
            for key in ("players_before", "players_after", "players_inserted", "player_observations_refreshed", "memberships_before", "memberships_after", "squads_reviewed", "observations_skipped", "membership_retirements", "snapshot_players_before", "snapshot_players_after"):
                integer(result.get(key), label + " " + key)
            require(result.get("conflicts") == [] and result["observations_skipped"] == 0
                    and result["membership_retirements"] == 0 and result.get("fingerprint_scope") == "country", f"{label}: unexpected import conflict, omission or retirement")
            require(result["squads_reviewed"] == count
                    and result["players_inserted"] + result["player_observations_refreshed"] == observations
                    and result["players_after"] - result["players_before"] == result["players_inserted"]
                    and result["snapshot_players_before"] + result["players_inserted"] == result["snapshot_players_after"] == len(ids), f"{label}: player import counts disagree")
            added_memberships = result["memberships_after"] - result["memberships_before"]
            require(result["players_inserted"] <= added_memberships <= observations, f"{label}: invalid membership delta")
            require(previous is not None and after["club_count"] == previous["club_count"]
                    and after["player_count"] == previous["player_count"] + result["players_inserted"]
                    and all(after[key] == previous[key] for key in (FINGERPRINT_KEYS[0], FINGERPRINT_KEYS[2], FINGERPRINT_KEYS[3])), f"{label}: roster import changed club/competition state")
            if previous_global:
                require(result["players_before"] == previous_global["players_after"]
                        and result["memberships_before"] == previous_global["memberships_after"], f"{label}: global import count chain is broken")
            if first_global is None:
                first_global = {"players": result["players_before"], "memberships": result["memberships_before"]}
            previous_global = result
            country_players[country].update(ids)
            for key in ("players_inserted", "player_observations_refreshed", "squads_reviewed"):
                country_total[key] += result[key]
            country_total["player_observations"] += observations
            country_total["memberships_added"] += added_memberships

        after_by_country[country] = after
        documents.append({"file_name": name, "content_sha256": content_hash, "document_utf8": document_text})
        receipts.append({"sequence": batch["sequence"], "file_name": name, "country_code": country,
                         "mode": mode, "batch_key": batch["batch_key"], "bytes": len(raw),
                         "content_sha256": content_hash, "pending_sha256": batch["pending_sha256"],
                         "source_template_sha256": template_hash, "receipt_sha256": digest(receipt_raw),
                         "before_fingerprints": {"country_code": country, "fingerprint_scope": "country", **before},
                         "after_fingerprints": after, "result": result})

    calculated_plan_totals = {code: {mode: dict(counts) for mode, counts in groups.items()} for code, groups in planned_totals.items()}
    require(calculated_plan_totals == plan.get("totals"), "Computed country totals differ from frozen plan")
    require(previous_global is not None and set(after_by_country) == set(COUNTRIES), "Missing completed country results")
    country_totals = {}
    aggregate = Counter()
    for country in country_order:
        counts = dict(totals[country])
        aggregate.update(counts)
        country_totals[country] = {"country_name": COUNTRIES[country], **counts,
                                  "unique_player_ids_in_documents": len(country_players[country]),
                                  "database_clubs_after": after_by_country[country]["club_count"],
                                  "database_players_after": after_by_country[country]["player_count"],
                                  "squad_source_statuses": dict(sorted(review_statuses[country].items())),
                                  "import_conflicts": 0, "observations_skipped": 0}
    aggregate["unique_player_ids_in_documents"] = len(player_clubs)
    aggregate["import_conflicts"] = 0
    aggregate["observations_skipped"] = 0
    archive_raw = json_bytes({"schema_version": 1, "kind": "scouting_applied_country_imports",
                              "date": RELEASE_DATE, "batch_count": EXPECTED_BATCHES, "documents": documents})
    archive_gzip = deterministic_gzip(archive_raw)
    restored, _ = parse_json(gzip.decompress(archive_gzip), "Archive self-check")
    require(len(restored["documents"]) == EXPECTED_BATCHES and all(
        original == recovered and digest(recovered["document_utf8"].encode("utf-8")) == recovered["content_sha256"]
        for original, recovered in zip(documents, restored["documents"])), "Archive round trip changed applied bytes")
    archive_path = prefix.parent / (prefix.name + ".imports.json.gz")
    manifest_path = prefix.parent / (prefix.name + ".import-manifest.json")
    manifest = {
        "schema_version": 1, "kind": "scouting_country_import_receipts", "date": RELEASE_DATE,
        "status": "database_loaded_pending_web_verification", "batch_count": EXPECTED_BATCHES,
        "verification_scope": "Offline verification of frozen plan, exact applied documents and database import receipts; no live database or web request.",
        "coverage": "Reviewed source subset in the five countries listed; not universal coverage. Argentina is not imported by this package.",
        "web_verification": {"status": "pending", "commit": None, "pull_request": None, "verified_at": None},
        "country_order": country_order,
        "plan": {"file_name": plan_path.name, "content_sha256": digest(plan_raw), "batch_count": EXPECTED_BATCHES},
        "source_facts_sha256": source_facts_hash, "source_manifest_sha256": source_manifest_hash,
        "source_conflicts_excluded_before_import": excluded_list,
        "archive": {"file_name": archive_path.name, "gzip_mtime": 0, "gzip_bytes": len(archive_gzip),
                    "gzip_sha256": digest(archive_gzip), "uncompressed_bytes": len(archive_raw),
                    "uncompressed_sha256": digest(archive_raw), "document_count": EXPECTED_BATCHES},
        "before_fingerprints_note": "Exact country preconditions from each applied document; only the fields required by its importer were recorded before the call.",
        "totals": dict(aggregate), "totals_by_country": country_totals,
        "global_catalogue_counts": {"before_first_roster_batch": first_global,
                                    "after_last_roster_batch": {"players": previous_global["players_after"], "memberships": previous_global["memberships_after"]}},
        "receipts": receipts,
    }
    no_local_paths(manifest, "Public manifest")
    # Read once more before publication so an input modified during packaging
    # cannot quietly produce a mixed release. Input bytes are never rewritten.
    for path, expected_hash in observed.items():
        require(path.is_file() and not path.is_symlink() and digest(path.read_bytes()) == expected_hash,
                f"Input changed while packaging: {path.name}")
    return {archive_path: archive_gzip, manifest_path: json_bytes(manifest, pretty=True)}, manifest


def write_outputs(outputs: dict[Path, bytes]) -> None:
    for path, raw in outputs.items():
        require(not path.is_symlink(), f"Refusing symlinked output: {path.name}")
        require(not path.exists() or path.is_file() and path.read_bytes() == raw,
                f"Existing output differs: {path.name}; reconcile or choose another prefix")
    for path, raw in outputs.items():
        if path.exists():
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(dir=path.parent, prefix=".scouting-package-", delete=False) as target:
                temporary = Path(target.name)
                target.write(raw)
                target.flush()
                os.fsync(target.fileno())
            try:
                os.link(temporary, path)  # Atomic creation; never replace a competing writer.
            except FileExistsError:
                require(not path.is_symlink() and path.is_file() and path.read_bytes() == raw,
                        f"Output appeared with different content: {path.name}")
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--plan", type=Path, required=True)
    parser.add_argument("--receipts", type=Path, required=True)
    parser.add_argument("--applied", type=Path, required=True)
    parser.add_argument("--output-prefix", type=Path, required=True)
    args = parser.parse_args()
    try:
        outputs, manifest = build_package(args.plan, args.receipts, args.applied, args.output_prefix)
        write_outputs(outputs)
    except (PackagingError, OSError) as error:
        print(f"Scouting packaging refused: {error}", file=sys.stderr)
        return 2
    print(json.dumps({"status": manifest["status"], "batch_count": manifest["batch_count"],
                      "files": [{"file_name": path.name, "bytes": len(raw), "sha256": digest(raw)} for path, raw in outputs.items()],
                      "totals_by_country": manifest["totals_by_country"]}, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
