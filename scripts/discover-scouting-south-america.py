#!/usr/bin/env python3
"""Extract country/competition club facts from saved, public TinyFish HTML.

No network and no database writes. Only rows within an observed participant table
with a Squad column qualify. Competition editions other than 2026 are recorded
as excluded, never relabelled. Club IDs are global; multiple competitions are
relationships, not duplicate clubs. Source season labels are independent of the
site's numerical URL season parameter.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path
from urllib.parse import urljoin
from lxml import html

def txt(node):
    return ' '.join(node.text_content().split())

def selected(doc):
    options = doc.xpath('.//select[@name="saison_id"]/option[@selected]')
    values = list(dict.fromkeys((txt(o), o.get('value')) for o in options))
    if len(values) == 1:
        return values[0]
    return None, None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--directory', type=Path, required=True)
    root = ap.parse_args().directory
    competition_jobs = {c['tm_competition_id']: c for c in json.loads((root / 'competition-jobs.json').read_text())}
    core_jobs = json.loads((root / 'club-jobs.json').read_text())
    clubs = {c['tm_club_id']: c for c in core_jobs}
    for c in clubs.values():
        c['club_source_key'] = 'tm-club-' + c['tm_club_id']
    observations = json.loads((root / 'competition-observations.json').read_text())
    seen_competitions = {c['tm_competition_id'] for c in observations}
    excluded = []
    files = [root / 'raw/competition-brazil-cd-participants.json']
    files += sorted((root / 'raw').glob('competitions-extra-*.json'))
    files += sorted((root / 'raw').glob('competitions-participants-*.json'))
    for fn in files:
        payload = json.loads(fn.read_text())
        for result in payload.get('results', []):
            match = re.search(r'/(?:wettbewerb|pokalwettbewerb)/([^/]+)', result['url'])
            if not match:
                continue
            compid = match[1]
            if compid in seen_competitions or compid not in competition_jobs:
                continue
            comp = competition_jobs[compid]
            doc = html.fromstring('<div>' + result.get('text', '') + '</div>')
            tables = [t for t in doc.xpath('.//table[contains(concat(" ",normalize-space(@class)," ")," items ")]') if 'Squad' in [txt(x) for x in t.xpath('./thead/tr/th')]]
            if not tables:
                continue
            season, parameter = selected(doc)
            if not season:
                heads = [txt(h) for h in doc.xpath('.//h2')]
                observed = [re.search(r'\b(20\d\d)\b', h)[1] for h in heads if h.startswith('Clubs - ') and re.search(r'\b(20\d\d)\b', h)]
                if len(set(observed)) == 1:
                    season = observed[0]
            source_url = result.get('final_url') or result['url']
            checked_at = result.get('fetched_at') or payload.get('fetched_at')
            fact = {**comp, 'source_url': source_url, 'requested_url': result['url'], 'source_title': result.get('title'), 'source_season': season, 'source_season_parameter': parameter, 'checked_at': checked_at, 'raw_evidence_file': fn.name, 'source_html_sha256': hashlib.sha256(result['text'].encode()).hexdigest()}
            if season != '2026':
                excluded.append({**fact, 'reason': 'source_competition_edition_is_not_2026; no relabelling or current participation inferred'})
                seen_competitions.add(compid)
                continue
            participants = {}
            for table in tables:
                for row in table.xpath('./tbody/tr'):
                    anchors = [a for a in row.xpath('.//a[contains(@href,"/startseite/verein/")]') if txt(a)]
                    if not anchors:
                        continue
                    anchor = anchors[0]
                    clubid = re.search(r'/verein/(\d+)', anchor.get('href'))[1]
                    participants[clubid] = {'tm_club_id': clubid, 'club_name': txt(anchor), 'url': urljoin(source_url, anchor.get('href'))}
            fact['observed_club_count'] = len(participants)
            fact['participant_ids'] = list(participants)
            observations.append(fact)
            seen_competitions.add(compid)
            for clubid, row in participants.items():
                membership = {'tm_competition_id': compid, 'competition_name': comp['name'], 'scope_role': comp['scope_role'], 'tier_label': comp.get('tier_label'), 'source_url': source_url, 'source_title': result.get('title'), 'source_season': season, 'source_season_parameter': parameter, 'checked_at': checked_at}
                if clubid not in clubs:
                    clubs[clubid] = {'country_code': comp['country_code'], 'country_name': comp['country_name'], 'tm_club_id': clubid, 'club_source_key': 'tm-club-' + clubid, 'club_name': row['club_name'], 'category': 'Primera', 'url': row['url'], 'competition_memberships': []}
                club = clubs[clubid]
                if club['country_code'] != comp['country_code']:
                    raise ValueError('Club observed in conflicting countries: ' + clubid)
                if compid not in {m['tm_competition_id'] for m in club['competition_memberships']}:
                    club['competition_memberships'].append(membership)
    ordered = list(clubs.values())
    existing_ids = {c['tm_club_id'] for c in core_jobs}
    cd_ids = {c['tm_club_id'] for c in json.loads((root / 'additional-cd-club-jobs.json').read_text())}
    extra = [c for c in ordered if c['tm_club_id'] not in existing_ids | cd_ids]
    for filename, value in [('all-club-jobs.json', ordered), ('extra-club-jobs.json', extra), ('all-competition-observations.json', observations), ('excluded-competition-editions.json', excluded)]:
        (root / filename).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')
    report = {'clubs': len(ordered), 'additional_state_cup_clubs': len(extra), 'competitions_with_2026_participants': len(observations), 'excluded_competition_editions': [{'id': x['tm_competition_id'], 'season': x['source_season']} for x in excluded], 'by_country': {code: sum(c['country_code'] == code for c in ordered) for code in ['BR','CL','CO','EC','UY']}}
    (root / 'discovery-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(report, ensure_ascii=False))

if __name__ == '__main__':
    main()
