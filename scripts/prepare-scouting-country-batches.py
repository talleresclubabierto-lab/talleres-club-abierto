#!/usr/bin/env python3
"""Prepare reviewed Scouting templates for ordered, small country imports.

No database, network, credentials or publish operation. Fingerprints remain
placeholders until the operator reviews the live country state before each batch.
Existing output with different bytes is never overwritten.
"""
from __future__ import annotations

import argparse
import copy
from collections import defaultdict
from datetime import date
import hashlib
import json
from pathlib import Path

COUNTRIES = {'AR':'Argentina','BR':'Brasil','CL':'Chile','CO':'Colombia','EC':'Ecuador','UY':'Uruguay'}
DEFAULT_ORDER = ['CL','EC','UY','BR','CO']
PLACEHOLDER = 'REQUIRES_CURRENT_COUNTRY_FINGERPRINT'
FINGERPRINT_FIELDS = {
    'clubs': ('expected_clubs_sha256','expected_competitions_sha256','expected_club_competitions_sha256'),
    'rosters': ('expected_players_sha256','expected_clubs_sha256'),
}


def encode(document: dict) -> bytes:
    return (json.dumps(document,ensure_ascii=False,separators=(',',':'),sort_keys=True)+'\n').encode('utf-8')


def sha256(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def read_reviewed_templates(folder: Path, country_order: list[str]):
    manifest_path = folder/'manifest.json'
    manifest_bytes = manifest_path.read_bytes()
    manifest = json.loads(manifest_bytes)
    references = {Path(f['path']).name:f for f in manifest['files']}
    documents = {}
    hashes = {}
    # Read every reviewed template in the manifest, including countries omitted
    # from a requested subset, so a cross-country ambiguity cannot become first-wins.
    for filename,reference in sorted(references.items()):
        if not filename.endswith('.template.json'):
            continue
        content = (folder/filename).read_bytes()
        actual = sha256(content)
        if actual!=reference['sha256'] or len(content)!=reference['bytes']:
            raise ValueError(f'Reviewed template changed: {filename}; review and update its source manifest first')
        document = json.loads(content)
        metadata = document.get('metadata',{})
        country = metadata.get('country_code')
        if country not in COUNTRIES or metadata.get('country')!=COUNTRIES[country]:
            raise ValueError(f'Invalid country metadata: {filename}')
        mode = 'clubs' if 'clubs' in document else 'rosters' if 'squads' in document else None
        if mode is None or (country,mode) in documents:
            raise ValueError(f'Missing or duplicated country/mode template: {filename}')
        if document.get('membership_retirements'):
            raise ValueError('Explicit membership retirements need a separately reviewed document with both complete rosters; this splitter does not distribute corrections')
        documents[(country,mode)] = document
        hashes[(country,mode)] = {'file':filename,'sha256':actual,'bytes':len(content)}
    for country in country_order:
        for mode in ('clubs','rosters'):
            if (country,mode) not in documents:
                raise ValueError(f'Missing reviewed template for {country}/{mode}')
    excluded = set(map(str,manifest.get('cross_club_player_conflicts_excluded',[])))
    observed = defaultdict(set)
    club_countries = {}
    for (country,mode),document in documents.items():
        if mode=='clubs':
            for club in document['clubs']:
                tm_id = str(club['transfermarkt_id'])
                if tm_id in club_countries:
                    raise ValueError(f'Club Transfermarkt identity repeated across country templates: {tm_id}')
                club_countries[tm_id] = country
        else:
            for squad in document['squads']:
                for player in squad['players']:
                    tm_id = str(player['transfermarkt_id'])
                    if tm_id in excluded:
                        raise ValueError(f'Globally excluded player is still present in a template: {tm_id}')
                    observed[tm_id].add((country,squad['club_source_key']))
    ambiguous = {pid:sorted(clubs) for pid,clubs in observed.items() if len(clubs)>1}
    if ambiguous:
        raise ValueError('Review cross-club player identities before splitting: '+json.dumps(ambiguous,ensure_ascii=False))
    return manifest,sha256(manifest_bytes),documents,hashes


def make_batch(template, records, mode, country, ordinal, snapshot_date, source, source_manifest, source_manifest_hash):
    record_key = 'clubs' if mode=='clubs' else 'squads'
    document = {key:copy.deepcopy(value) for key,value in template.items() if key!=record_key}
    document[record_key] = records
    # New competition identities must exist before later club memberships. They
    # occur exactly once, in the first club batch of their country.
    if mode=='clubs' and ordinal>1:
        document['competitions'] = []
    metadata = document['metadata']
    metadata['batch_key'] = f'scouting-{snapshot_date}-country-{country.lower()}-{mode}-{ordinal:03d}'
    metadata['fingerprint_scope'] = 'country'
    for field in FINGERPRINT_FIELDS[mode]:
        metadata[field] = PLACEHOLDER
    metadata['preparation'] = {
        'parent_batch_key':template['metadata']['batch_key'],
        'country_batch_index':ordinal,
        'source_template':source['file'],
        'source_template_sha256':source['sha256'],
        'source_manifest_sha256':source_manifest_hash,
        'source_facts_sha256':source_manifest['source_facts_sha256'],
    }
    # Preserve template metadata while making the global exclusion decision
    # explicit in every batch and in the preparation manifest.
    exclusions = source_manifest.get('cross_club_player_conflicts_excluded',[])
    previous = metadata.get('cross_club_player_conflicts_excluded',[])
    metadata['cross_club_player_conflicts_excluded'] = list(dict.fromkeys(map(str,[*previous,*exclusions])))
    return document


def size_with_fingerprints(document, mode):
    final_shape = copy.deepcopy(document)
    for field in FINGERPRINT_FIELDS[mode]:
        final_shape['metadata'][field] = '0'*64
    return len(encode(final_shape))


def split_template(template, mode, country, snapshot_date, max_records, max_bytes, source, source_manifest, source_manifest_hash):
    record_key = 'clubs' if mode=='clubs' else 'squads'
    records = template[record_key]
    if not isinstance(records,list) or not records:
        raise ValueError(f'{country}/{mode}: expected a nonempty reviewed record list')
    batches = []
    current = []
    ordinal = 1
    for record in records:
        candidate = make_batch(template,[*current,record],mode,country,ordinal,snapshot_date,source,source_manifest,source_manifest_hash)
        if len(current)+1>max_records or size_with_fingerprints(candidate,mode)>max_bytes:
            if not current:
                raise ValueError(f'{country}/{mode}: one record plus preserved metadata exceeds {max_bytes} bytes; review this record separately')
            batches.append(make_batch(template,current,mode,country,ordinal,snapshot_date,source,source_manifest,source_manifest_hash))
            ordinal += 1
            current = []
            candidate = make_batch(template,[record],mode,country,ordinal,snapshot_date,source,source_manifest,source_manifest_hash)
            if size_with_fingerprints(candidate,mode)>max_bytes:
                raise ValueError(f'{country}/{mode}: one record exceeds the byte limit in batch {ordinal}')
        current.append(record)
    if current:
        batches.append(make_batch(template,current,mode,country,ordinal,snapshot_date,source,source_manifest,source_manifest_hash))
    reconstructed = [r for batch in batches for r in batch[record_key]]
    if reconstructed!=records:
        raise AssertionError(f'{country}/{mode}: preparation changed the source records or their order')
    if mode=='clubs' and [c for batch in batches for c in batch.get('competitions',[])]!=template.get('competitions',[]):
        raise AssertionError(f'{country}: preparation duplicated or lost new competitions')
    return batches


def prepare(args):
    country_order = [c.upper() for c in args.countries]
    if len(country_order)!=len(set(country_order)) or any(c not in COUNTRIES for c in country_order):
        raise ValueError('Countries must be unique codes from AR BR CL CO EC UY')
    if not 1<=args.clubs_per_batch<=40 or not 1<=args.rosters_per_batch<=20 or not 1000<=args.max_bytes<=400000:
        raise ValueError('Limits: clubs 1..40, rosters 1..20, JSON bytes 1000..400000')
    snapshot_date = date.fromisoformat(args.date).isoformat()
    folder = args.templates.resolve()
    output = args.output.resolve()
    source_manifest,source_manifest_hash,documents,hashes = read_reviewed_templates(folder,country_order)
    files = {}
    entries = []
    totals = {}
    for country in country_order:
        totals[country] = {}
        for mode in ('clubs','rosters'):
            template = documents[(country,mode)]
            record_key = 'clubs' if mode=='clubs' else 'squads'
            max_records = args.clubs_per_batch if mode=='clubs' else args.rosters_per_batch
            batches = split_template(template,mode,country,snapshot_date,max_records,args.max_bytes,hashes[(country,mode)],source_manifest,source_manifest_hash)
            totals[country][mode] = {'records':len(template[record_key]),'batches':len(batches)}
            for ordinal,batch in enumerate(batches,1):
                sequence = len(entries)+1
                filename = f'{sequence:03d}-{country.lower()}-{mode}-{ordinal:03d}.json'
                content = encode(batch)
                files[filename] = content
                entries.append({'sequence':sequence,'mode':mode,'country':country,'country_code':country,
                    'path':str(output/filename),'relative_path':filename,'count':len(batch[record_key]),
                    'batch_key':batch['metadata']['batch_key'],'bytes':len(content),
                    'bytes_with_fingerprints':size_with_fingerprints(batch,mode),
                    'pending_sha256':sha256(content),'source_template_sha256':hashes[(country,mode)]['sha256'],
                    'new_competitions':len(batch.get('competitions',[])),
                    'player_observations':sum(len(s['players']) for s in batch.get('squads',[]))})
    manifest = {'schema_version':1,'status':'pending_current_country_fingerprints','date':snapshot_date,
        'country_order':country_order,'execution_order':'all club batches then roster batches within each country',
        'limits':{'clubs_per_batch':args.clubs_per_batch,'rosters_per_batch':args.rosters_per_batch,'json_bytes':args.max_bytes},
        'source_manifest_sha256':source_manifest_hash,'source_facts_sha256':source_manifest['source_facts_sha256'],
        'cross_club_player_conflicts_excluded':source_manifest.get('cross_club_player_conflicts_excluded',[]),
        'totals':totals,'batch_count':len(entries),'batches':entries,
        'execution_note':'Fill only the required expected_*_sha256 fields from current country fingerprints immediately before each reviewed import. Recompute UTF-8 bytes and SHA256 after filling. The pending hash is not the executed-content hash.'}
    files['manifest.json'] = encode(manifest)
    output.mkdir(parents=True,exist_ok=True)
    # Complete collision check before writing anything; never replace an operator's
    # already-filled/imported payload or a different plan.
    for filename,content in files.items():
        path = output/filename
        if path.exists() and path.read_bytes()!=content:
            raise ValueError(f'Output differs and was not overwritten: {path}')
    for filename,content in files.items():
        path = output/filename
        if not path.exists():
            with path.open('xb') as stream:
                stream.write(content)
    return {'manifest':str(output/'manifest.json'),'batch_count':len(entries),'countries':country_order,
        'club_records':sum(v['clubs']['records'] for v in totals.values()),
        'squad_records':sum(v['rosters']['records'] for v in totals.values()),
        'player_observations':sum(e['player_observations'] for e in entries),
        'max_pending_bytes':max(e['bytes'] for e in entries),'max_bytes_with_fingerprints':max(e['bytes_with_fingerprints'] for e in entries),
        'new_competitions':sum(e['new_competitions'] for e in entries),
        'manifest_sha256':sha256(files['manifest.json'])}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--templates',required=True,type=Path,help='Folder with frozen *.template.json and the reviewed manifest.json')
    parser.add_argument('--output',required=True,type=Path,help='Pending-plan folder; different existing files are never overwritten')
    parser.add_argument('--date',required=True,help='Reviewed snapshot date YYYY-MM-DD used in stable batch keys')
    parser.add_argument('--countries',nargs='+',default=DEFAULT_ORDER,help='Ordered ISO2 list; default CL EC UY BR CO. AR requires explicit selection.')
    parser.add_argument('--clubs-per-batch',type=int,default=40)
    parser.add_argument('--rosters-per-batch',type=int,default=20)
    parser.add_argument('--max-bytes',type=int,default=400000)
    args = parser.parse_args()
    try:
        print(json.dumps(prepare(args),ensure_ascii=False,indent=2))
    except (ValueError,KeyError,FileNotFoundError,FileExistsError,json.JSONDecodeError) as error:
        parser.exit(2,f'Preparation stopped: {error}\n')


if __name__=='__main__':
    main()
