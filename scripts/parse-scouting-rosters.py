#!/usr/bin/env python3
"""Normalize explicitly retrieved Transfermarkt squad tables; never crawl or fetch.

Usage: python scripts/parse-scouting-rosters.py --directory /absolute/review-folder
Inputs: *jobs.json lists (club_source_key, club_name, competition_slug, category,
tm_club_id, season, url), and raw/*.json TinyFish fetch_content results with
include_selectors=[table,h2], format=html and a captured UTC fetched_at timestamp.
Only rows inside the squad table, never transfers/news/league tables, become players.
Outputs parsed-squads.json and parse-report.json in that explicitly chosen folder.
The parser neither fetches websites nor writes to the database. Review report
conflicts and unavailable sources before creating an import document.
"""
import argparse
import collections
import datetime as dt
import hashlib
import json
import re
import unicodedata
from pathlib import Path
from urllib.parse import urljoin
from lxml import html

POSITIONS = {
    'Goalkeeper': 'Arquero', 'Portero': 'Arquero',
    'Centre-Back': 'Defensor Central', 'Defensa central': 'Defensor Central',
    'Left-Back': 'Lateral', 'Right-Back': 'Lateral',
    'Lateral izquierdo': 'Lateral', 'Lateral derecho': 'Lateral',
    'Defensive Midfield': 'Volante central', 'Pivote': 'Volante central',
    'Central Midfield': 'Volante Mixto', 'Mediocentro': 'Volante Mixto',
    'Right Midfield': 'Volante por derecha', 'Interior derecho': 'Volante por derecha',
    'Left Midfield': 'Volante por Izquierda', 'Interior izquierdo': 'Volante por Izquierda',
    'Left Winger': 'Delantero Extremo', 'Right Winger': 'Delantero Extremo',
    'Extremo izquierdo': 'Delantero Extremo', 'Extremo derecho': 'Delantero Extremo',
    'Centre-Forward': 'Delantero de Area', 'Delantero centro': 'Delantero de Area',
}

def text(n):
    return re.sub(r'\s+', ' ', ''.join(n.itertext())).strip()

def club_id(url):
    m = re.search(r'/verein/(\d+)', url or '')
    return m.group(1) if m else None

def source_season(doc):
    opts = doc.xpath('//select[@name="saison_id"]/option[@selected]')
    values = list(dict.fromkeys((text(x), x.get('value')) for x in opts))
    if not values:
        selected_widgets = doc.xpath('//div[contains(concat(" ",normalize-space(@class)," ")," inline-select ")]//li[contains(concat(" ",normalize-space(@class)," ")," result-selected ")]')
        labels = list(dict.fromkeys(text(x) for x in selected_widgets))
        if len(labels) == 1:
            return labels[0], None, 'selected_source_widget'
        return None, None, 'current_default_page_no_explicit_season'
    if len(values) != 1:
        raise ValueError('A unique selected source season is required: ' + str(values))
    return (*values[0], 'selected_source_option')

def folded_name(value):
    return re.sub(r'[^a-z0-9]', '', unicodedata.normalize('NFKD', value).encode('ascii','ignore').decode().lower())

def parse_partial_visible_rows(result, job, fetched_at, raw_file):
    """Use only already retrieved named rows; never reconstruct missing names.

    The normal extractor strips some anchor names. A visible name must exactly
    match the observed profile slug in the same source-document ordinal slot.
    If any named row disagrees, refuse the entire fallback, rather than shift IDs.
    """
    if '/saison_id/' in result['url']:
        raise ValueError('Partial fallback requires current default URL')
    doc = html.fromstring('<div>' + result['text'] + '</div>')
    tables = doc.xpath('//table')
    table = next((t for t in tables if any(text(x) in ('Player','Jugador','Jugadores') for x in t.xpath('./thead/tr/th'))), None)
    if table is None:
        raise ValueError('No partial squad table')
    rows = table.xpath('./tbody/tr')
    profiles = list(dict.fromkeys(u for u in result.get('links',[]) if re.search(r'/profil/spieler/\d+$',u)))
    if len(profiles) < len(rows):
        raise ValueError('Fewer observed profile URLs than squad rows')
    players, excluded = [], []
    for index, row in enumerate(rows):
        cells = row.xpath('./td'); nested = cells[1].xpath('./table') if len(cells)>1 else []
        if not nested:
            raise ValueError('Partial squad row has no player cell')
        inner = nested[0].xpath('./tr | ./tbody/tr')
        if len(inner) == 1:
            excluded.append({'source_row':index+1,'transfermarkt_url':profiles[index],'reason':'player_name_omitted_by_original_extraction; no_name_inferred'})
            continue
        name = text(inner[0]); position=text(inner[-1]); url=profiles[index]
        slug=url.split('/profil/spieler/')[0].rsplit('/',1)[-1]
        if folded_name(name) != folded_name(slug):
            raise ValueError('Visible name and profile slot differ: ' + name + ' / ' + slug)
        if len(name.split())<2:
            excluded.append({'source_row':index+1,'name':name,'reason':'display_name_cannot_be_split'})
            continue
        first,last=name.split(' ',1)
        birth=None;m=re.search(r'\b(\d{2})/(\d{2})/(\d{4})\b',text(cells[2]))
        if m:birth=dt.date(int(m[3]),int(m[2]),int(m[1])).isoformat()
        players.append({
            'transfermarkt_id':url.rsplit('/',1)[-1],'transfermarkt_url':url,
            'full_name':name,'first_name':first,'last_name':last,
            'source_display_name':name,'full_name_source_url':result['final_url'],
            'name_partition':'first_display_token_and_remaining_display_name',
            'source_position':position,'position':POSITIONS.get(position),
            'birth_date':birth,'birth_date_source_url':result['final_url'] if birth else None,
            'birth_date_verified_at':fetched_at if birth else None,
            'market_value_observed_text':text(cells[-1]),'market_value_verified':False,
            'market_value_note':'Squad amount has no individual valuation date; not published as a verified valuation.',
            'source_row':index+1,
        })
    if not players:
        raise ValueError('No named rows qualify for partial extraction')
    return {
        'club_source_key':job['club_source_key'],'club_name':job['club_name'],
        'competition_slug':job['competition_slug'],'category':job['category'],
        'season':job['season'],'source_season':None,'source_season_parameter':None,
        'source_season_evidence':'current_default_page_no_explicit_season',
        'source_roster_status':'partial_original_extraction',
        'source':'verified_manual','source_url':result['final_url'],'requested_url':result['url'],
        'source_title':result['title'],'transfermarkt_team_id':club_id(result['url']),
        'checked_at':fetched_at,'completeness':'partial',
        'completeness_scope':'only visible original names whose observed profile URL slot agrees exactly; omitted names remain pending',
        'expected_count':len(rows),'players':players,'excluded':excluded,
        'source_html_sha256':hashlib.sha256(result['text'].encode()).hexdigest(),
        'raw_evidence_file':Path(raw_file).name,
        'category_evidence_url':job.get('discovered_from') or result['final_url'],
        'extraction_method':'visible_named_rows_and_verified_same_ordinal_profile_URL; all_named_rows_crosschecked',
    }

def parse_squad(result, job, fetched_at, raw_file, profile_names=None):
    doc = html.fromstring('<div>' + result['text'] + '</div>')
    season, season_parameter, season_evidence = source_season(doc)
    expected_season = str(job['season'])
    allowed_source_seasons = {None, expected_season}
    if re.fullmatch(r'20\d\d', expected_season):
        following = str(int(expected_season)+1)[-2:]
        allowed_source_seasons.update({expected_season[-2:]+'/'+following,expected_season+'/'+following})
    if season not in allowed_source_seasons:
        raise ValueError('Source current-season selector is outside this review: ' + season)
    if season is None and '/saison_id/' in result['url']:
        raise ValueError('Undated source page has an explicit historical season selector')
    tables = doc.xpath('//table[contains(concat(" ", normalize-space(@class), " "), " items ")]')
    table = next((t for t in tables if any(text(x) in ('Player', 'Jugador', 'Jugadores') for x in t.xpath('./thead/tr/th'))), None)
    if table is None:
        headings = [text(x) for x in doc.xpath('//h2')]
        if not any(x.startswith(('Squad ', 'Equipo ')) for x in headings) or doc.xpath('//a[contains(@href,"/profil/spieler/")]'):
            raise ValueError('No squad table with Player/Jugador heading; empty-squad source not established')
    columns = [text(x) for x in table.xpath('./thead/tr/th')] if table is not None else []
    dob_index = next((i for i, v in enumerate(columns) if 'birth' in v or 'Nacimiento' in v or 'Nacim' in v), None)
    out, excluded = [], []
    raw_rows = table.xpath('./tbody/tr') if table is not None else []
    player_rows = [row for row in raw_rows if row.xpath('.//a[contains(@href,"/profil/spieler/")]')]
    for row in player_rows:
        cells = row.xpath('./td')
        anchors = row.xpath('.//a[contains(@href,"/profil/spieler/")]')
        links = [(urljoin(result['final_url'], a.get('href')), text(a)) for a in anchors]
        ids = {re.search(r'/profil/spieler/(\d+)', u).group(1) for u, _ in links}
        if len(ids) != 1:
            raise ValueError('More than one distinct profile identity in squad row')
        url, name = next(((u, n) for u, n in links if n), (None, None))
        identity = next(iter(ids))
        source_display_name = name
        name_evidence = (profile_names or {}).get(identity)
        if name_evidence and (not name or len(name.split()) < 2):
            name = name_evidence['full_name']
        if not name or len(name.split()) < 2:
            excluded.append({'transfermarkt_id': identity, 'name': name, 'reason': 'source_display_name_cannot_be_split_without_invention'})
            continue
        first, last = name.split(' ', 1)
        if not (2 <= len(first) <= 100 and 2 <= len(last) <= 100):
            excluded.append({'transfermarkt_id': identity, 'name': name, 'reason': 'source_display_name_outside_existing_name_contract'})
            continue
        inners = row.xpath('.//table[contains(concat(" ",normalize-space(@class)," ")," inline-table ")]')
        position = None
        if inners:
            position_rows = inners[0].xpath('./tr | ./tbody/tr')
            if len(position_rows) >= 2:
                position = text(position_rows[-1])
        birth = None
        if dob_index is not None and dob_index < len(cells):
            m = re.search(r'\b(\d{2})/(\d{2})/(\d{4})\b', text(cells[dob_index]))
            if m:
                try:
                    birth = dt.date(int(m[3]), int(m[2]), int(m[1])).isoformat()
                except ValueError:
                    pass
        observed_value = text(cells[-1]) if cells and 'value' in columns[-1].lower() or cells and 'valor' in columns[-1].lower() else None
        player = {
            'transfermarkt_id': identity, 'transfermarkt_url': url,
            'full_name': name, 'first_name': first, 'last_name': last,
            'source_display_name': source_display_name,
            'full_name_source_url': name_evidence['source_url'] if name_evidence else result['final_url'],
            'name_partition': 'first_display_token_and_remaining_display_name',
            'source_position': position, 'position': POSITIONS.get(position),
            'birth_date': birth, 'birth_date_source_url': result['final_url'] if birth else None,
            'birth_date_verified_at': fetched_at if birth else None,
            'market_value_observed_text': observed_value,
            'market_value_verified': False,
            'market_value_note': 'Squad amount has no individual valuation date; not published as a verified valuation.',
        }
        out.append(player)
    if len({p['transfermarkt_id'] for p in out}) != len(out):
        raise ValueError('Duplicate profile ID in one squad')
    return {
        'club_source_key': job['club_source_key'], 'club_name': job['club_name'],
        'competition_slug': job['competition_slug'], 'category': job['category'],
        'season': job['season'], 'source_season': season,
        'source_season_parameter': season_parameter,
        'source_season_evidence': season_evidence,
        'source_roster_status': 'player_rows_present' if player_rows else 'no_player_rows_in_retrieved_source',
        'source': 'verified_manual', 'source_url': result['final_url'],
        'requested_url': result['url'], 'source_title': result['title'],
        'transfermarkt_team_id': club_id(result['url']), 'checked_at': fetched_at,
        'completeness': 'partial' if excluded or not player_rows or not season else 'complete',
        'completeness_scope': 'all_player_rows_in_retrieved_source_table; not a guarantee of full real-world squad coverage',
        'expected_count': len(player_rows), 'players': out, 'excluded': excluded,
        'source_html_sha256': hashlib.sha256(result['text'].encode()).hexdigest(),
        'raw_evidence_file': Path(raw_file).name,
        'category_evidence_url': job.get('discovered_from') or result['final_url'],
    }

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--directory', type=Path, required=True, help='Review folder containing *jobs.json and raw/*.json; never assumed from the repository path')
    args = ap.parse_args(); root = args.directory
    jobs = {}
    for fn in root.glob('*jobs.json'):
        for j in json.loads(fn.read_text()):
            jobs[j['tm_club_id']] = j
    candidates = {}
    partial_candidates = {}
    errors = []
    profile_names = {}
    for fn in sorted((root / 'raw').glob('*.json')):
        payload = json.loads(fn.read_text())
        for r in payload.get('results', []):
            profile = re.search(r'/profil/spieler/(\d+)', r.get('url',''))
            if profile:
                raw_text = text(html.fromstring('<div>' + r.get('text','') + '</div>'))
                match = re.search(r'(?:Name in home country|Nombre en país de origen|Full name|Nombre completo):\s*(.+?)(?=\s+(?:Full name|Nombre completo|Date of birth/Age|F\. Nacim\./Edad):)', raw_text)
                if match:
                    profile_names[profile.group(1)] = {'full_name':match.group(1).strip(),'source_url':r.get('final_url',r['url'])}
                continue
            cid = club_id(r.get('url'))
            source_html = r.get('text', '')
            if cid not in jobs or not ('class="items"' in source_html or ('class="content-box-headline"' in source_html and 'class="auflistung"' in source_html)):
                checked = r.get('fetched_at') or payload.get('fetched_at')
                if cid in jobs and checked and '<thead>' in source_html and '/saison_id/' not in r.get('url',''):
                    old = partial_candidates.get(cid)
                    if old is None or checked > old[0]:partial_candidates[cid] = (checked,r,fn)
                continue
            fetched_at = r.get('fetched_at') or payload.get('fetched_at')
            if not fetched_at:
                continue
            prior = candidates.get(cid)
            if prior is None or fetched_at > prior[0]:
                candidates[cid] = (fetched_at, r, fn)
    squads = []
    for cid, (checked_at, result, fn) in candidates.items():
        try:
            squads.append(parse_squad(result, jobs[cid], checked_at, fn, profile_names))
        except (ValueError, IndexError, TypeError) as e:
            errors.append({'tm_club_id': cid, 'url': result.get('url'), 'error': str(e), 'file': fn.name})
    completed = {s['transfermarkt_team_id'] for s in squads}
    for cid,(checked_at,result,fn) in partial_candidates.items():
        if cid in completed:continue
        try:
            squads.append(parse_partial_visible_rows(result,jobs[cid],checked_at,fn))
        except (ValueError,IndexError,TypeError) as e:
            errors.append({'tm_club_id':cid,'url':result.get('url'),'error':str(e),'file':fn.name,'method':'partial_fallback'})
    squads.sort(key=lambda x: (x['competition_slug'], x['club_source_key'], x['category']))
    identities = collections.defaultdict(list)
    for squad in squads:
        for p in squad['players']:
            identities[p['transfermarkt_id']].append((squad, p))
    conflicts = []
    for identity, memberships in identities.items():
        clubs = {s['club_source_key'] for s, _ in memberships}
        names = {p['full_name'] for _, p in memberships}
        birth_dates = {p['birth_date'] for _, p in memberships if p['birth_date']}
        if len(clubs) > 1 or len(birth_dates) > 1:
            conflicts.append({'transfermarkt_id': identity, 'clubs': sorted(clubs), 'names': sorted(names), 'birth_dates': sorted(birth_dates), 'memberships': [{'club_source_key': s['club_source_key'], 'category': s['category'], 'source_url': s['source_url'], 'name': p['full_name']} for s, p in memberships]})
    report = {
        'squads': len(squads), 'first_teams': sum(s['category'] == 'Primera' for s in squads),
        'reserves': sum(s['category'] == 'Reserva' for s in squads),
        'memberships': sum(len(s['players']) for s in squads), 'unique_players': len(identities),
        'by_competition': dict(collections.Counter(s['competition_slug'] for s in squads)),
        'missing_jobs': [j for cid, j in jobs.items() if cid not in {s['transfermarkt_team_id'] for s in squads}],
        'parse_errors': errors, 'conflicts': conflicts,
        'unmapped_positions': dict(collections.Counter(p['source_position'] for s in squads for p in s['players'] if not p['position'])),
        'excluded_players': [dict(squad=s['club_source_key'],category=s['category'],**p) for s in squads for p in s['excluded']],
    }
    (root / 'parsed-squads.json').write_text(json.dumps({'squads': squads}, ensure_ascii=False, indent=2) + '\n')
    (root / 'parse-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({k:v for k,v in report.items() if k not in ('conflicts','missing_jobs','excluded_players')}, ensure_ascii=False, indent=2))
    print(json.dumps({'missing_jobs':len(report['missing_jobs']), 'conflicts':len(conflicts),'excluded':len(report['excluded_players'])}))

if __name__ == '__main__': main()
