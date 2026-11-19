#!/usr/bin/env python3
"""Parse saved Transfermarkt main HTML, with exact row identity and provenance.

Inputs: all-club-jobs.json and raw/*.json from TinyFish fetch_content (HTML,
include_selectors=[main]), with fetched_at UTC. No networking, no database writes.
Display names are not asserted to be legal given/surnames. Mononyms stay intact.
Only first-team / explicit reserve-team rows are catalogued; youth-team links are
retained as discovery evidence and are not silently classified as Reserva.
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
    'Goalkeeper':'Arquero', 'Portero':'Arquero',
    'Centre-Back':'Defensor Central', 'Defensa central':'Defensor Central',
    'Left-Back':'Lateral', 'Right-Back':'Lateral', 'Lateral izquierdo':'Lateral', 'Lateral derecho':'Lateral',
    'Defensive Midfield':'Volante central', 'Pivote':'Volante central',
    'Central Midfield':'Volante Mixto', 'Mediocentro':'Volante Mixto',
    'Right Midfield':'Volante por derecha', 'Interior derecho':'Volante por derecha',
    'Left Midfield':'Volante por Izquierda', 'Interior izquierdo':'Volante por Izquierda',
    'Left Winger':'Delantero Extremo', 'Right Winger':'Delantero Extremo', 'Extremo izquierdo':'Delantero Extremo', 'Extremo derecho':'Delantero Extremo',
    'Centre-Forward':'Delantero de Area', 'Delantero centro':'Delantero de Area',
}
BR_STATES = {'AC':'Acre','AL':'Alagoas','AP':'Amapá','AM':'Amazonas','BA':'Bahia','CE':'Ceará','DF':'Distrito Federal','ES':'Espírito Santo','GO':'Goiás','MA':'Maranhão','MT':'Mato Grosso','MS':'Mato Grosso do Sul','MG':'Minas Gerais','PA':'Pará','PB':'Paraíba','PR':'Paraná','PE':'Pernambuco','PI':'Piauí','RJ':'Rio de Janeiro','RN':'Rio Grande do Norte','RS':'Rio Grande do Sul','RO':'Rondônia','RR':'Roraima','SC':'Santa Catarina','SP':'São Paulo','SE':'Sergipe','TO':'Tocantins'}

def txt(node):
    return ' '.join(node.text_content().split())

def id_from_url(url):
    m = re.search(r'/verein/(\d+)', url or '')
    return m[1] if m else None

def name_stem(name):
    name=re.sub(r'\s+(?:B|II|Reserves?|Reserva)$','',name or '',flags=re.I)
    return re.sub(r'[^a-z0-9]','',unicodedata.normalize('NFKD',name).encode('ascii','ignore').decode().lower())

def selected(doc):
    options = doc.xpath('.//select[@name="saison_id"]/option[@selected]')
    values = list(dict.fromkeys((txt(o),o.get('value')) for o in options))
    if len(values) == 1:
        return *values[0], 'selected_source_option'
    widgets = doc.xpath('.//div[contains(concat(" ",normalize-space(@class)," ")," inline-select ")]//li[contains(concat(" ",normalize-space(@class)," ")," result-selected ")]')
    labels = list(dict.fromkeys(txt(w) for w in widgets))
    if len(labels) == 1:
        return labels[0], None, 'selected_source_widget'
    return None, None, 'no_explicit_source_season'

def geography(doc, job, source_url):
    """Only parse explicitly published postal-address values, not club names.

    Transfermarkt incorrectly tags the city+postal-code line as postalCode and
    the country as addressLocality. Preserve raw fields and parse only that
    documented address line; unknown/ambiguous geography remains null.
    """
    address = {}
    for field in ['streetAddress','postalCode','addressLocality','addressRegion']:
        vals = list(dict.fromkeys(txt(x) for x in doc.xpath('.//*[@itemprop="'+field+'"]') if txt(x)))
        address[field] = vals
    city = province = None
    reason = None
    postal = address['postalCode']
    if len(postal) == 1:
        value = postal[0]
        value = re.sub(r'^(?:CP\s+)?\s*\d[\d.\- ]*\s+', '', value).strip()
        # Country is rendered in a separate locality line, not included here.
        if value and not re.fullmatch(r'[\d.\- ]+', value):
            if job['country_code'] == 'BR':
                state = re.search(r'(?:\s+-\s+|,\s*|\s*/\s*|\s*\()([A-Z]{2})\)?$', value)
                if state and state[1] in BR_STATES:
                    province = 'Brasil — ' + BR_STATES[state[1]]
                    value = value[:state.start()].strip()
            if value and not any(c in value for c in ['\n',';']):
                city = value
                reason = 'explicit_city_in_published_postal_address_line'
    if job['country_code'] == 'BR' and len(address['addressRegion']) == 1:
        state = address['addressRegion'][0]
        if state in BR_STATES:
            province = 'Brasil — ' + BR_STATES[state]
        elif state in BR_STATES.values():
            province = 'Brasil — ' + state
    return {'city':city,'province':province,'geography_source_urls':[source_url] if city or province else [],'geography_evidence':{'address_fields':address,'city_extraction':reason,'province_extraction':'explicit_address_state' if province else None}}

def subteams(doc, job, source_url, checked_at):
    found = {}
    for a in doc.xpath('.//header[contains(concat(" ",normalize-space(@class)," ")," data-header ")]//a[contains(@href,"/startseite/verein/")]'):
        teamid = id_from_url(a.get('href'))
        label = txt(a) or a.get('title')
        if not teamid or teamid == job['tm_club_id'] or not label:
            continue
        is_reserve = bool(re.search(r'(?:\b(?:II|B|Reserves?|Reserva)\b|2nd team)',label,re.I))
        # Age-group teams retain their exact category; never relabel as Reserva.
        if re.search(r'\b(?:U|Sub[ -]?)(?:1[3-9]|2[0-3])\b',label,re.I):
            is_reserve = False
        found[teamid] = {'country_code':job['country_code'],'country_name':job['country_name'],'tm_club_id':teamid,'parent_tm_club_id':job['tm_club_id'],'club_source_key':job['club_source_key'],'club_name':job['club_name'],'source_team_name':label,'source_category_literal':label,'category':'Reserva' if is_reserve else None,'url':urljoin(source_url,a.get('href')),'discovered_from':source_url,'discovered_at':checked_at,'competition_memberships':job['competition_memberships']}
    return list(found.values())

def parse_result(result, job, checked_at, raw_file):
    source_url = result.get('final_url') or result['url']
    doc = html.fromstring('<div>' + result['text'] + '</div>')
    season, parameter, season_evidence = selected(doc)
    tables = doc.xpath('.//table[contains(concat(" ",normalize-space(@class)," ")," items ")]')
    table = next((t for t in tables if any(txt(h) in ['Player','Jugador','Jugadores'] for h in t.xpath('./thead/tr/th'))),None)
    headings = [txt(x) for x in doc.xpath('.//h2')]
    if table is None and not any(h.startswith(('Squad ','Equipo ')) for h in headings):
        raise ValueError('no_verified_squad_table_or_empty_squad_heading')
    columns = [txt(x) for x in table.xpath('./thead/tr/th')] if table is not None else []
    birth_index = next((i for i,x in enumerate(columns) if 'birth' in x.lower() or 'nacim' in x.lower()),None)
    rows = [r for r in table.xpath('./tbody/tr') if r.xpath('.//a[contains(@href,"/profil/spieler/")]')] if table is not None else []
    players, excluded = [], []
    for index, row in enumerate(rows):
        cells = row.xpath('./td')
        anchors = row.xpath('.//a[contains(@href,"/profil/spieler/")]')
        links = [(urljoin(source_url,a.get('href')),txt(a)) for a in anchors]
        ids = {re.search(r'/profil/spieler/(\d+)',u)[1] for u,n in links}
        if len(ids) != 1:
            raise ValueError('multiple_player_identities_within_single_row')
        playerid = next(iter(ids))
        url, name = next(((u,n) for u,n in links if n),(None,None))
        if not name:
            excluded.append({'transfermarkt_id':playerid,'reason':'no_source_display_name; no inferred name'})
            continue
        parts = name.split(' ',1)
        first, last = parts[0], parts[1] if len(parts)>1 else ''
        name_kind = 'display_name_parts' if last else 'sporting_mononym'
        if not (2 <= len(first) <= 100 and (not last or 2 <= len(last) <= 100)):
            excluded.append({'transfermarkt_id':playerid,'full_name':name,'reason':'display_name_outside_existing_name_contract'})
            continue
        inline = row.xpath('.//table[contains(concat(" ",normalize-space(@class)," ")," inline-table ")]')
        source_position = None
        if inline:
            inner_rows = inline[0].xpath('./tr | ./tbody/tr')
            if len(inner_rows)>=2:
                source_position = txt(inner_rows[-1])
        birth = None
        if birth_index is not None and birth_index<len(cells):
            match = re.search(r'\b(\d{2})/(\d{2})/(\d{4})\b',txt(cells[birth_index]))
            if match:
                try:
                    birth = dt.date(int(match[3]),int(match[2]),int(match[1])).isoformat()
                except ValueError:
                    pass
        observed_value = txt(cells[-1]) if cells and columns and any(x in columns[-1].lower() for x in ['value','valor']) else None
        players.append({'transfermarkt_id':playerid,'transfermarkt_url':url,'full_name':name,'first_name':first,'last_name':last,'name_kind':name_kind,'source_display_name':name,'full_name_source_url':source_url,'name_partition':'source_sporting_mononym' if name_kind=='sporting_mononym' else 'first_display_token_and_remaining_display_name','position':POSITIONS.get(source_position),'source_position':source_position,'birth_date':birth,'birth_date_source_url':source_url if birth else None,'birth_date_verified_at':checked_at if birth else None,'market_value_eur':None,'market_value_as_of':None,'market_value_observed_text':observed_value,'market_value_verified':False,'source_row':index+1})
    if len({p['transfermarkt_id'] for p in players}) != len(players):
        raise ValueError('duplicate_profile_in_squad')
    complete = bool(players and season and not excluded)
    historical_label = re.search(r'\(\s*-\s*(20\d\d)\s*\)',job.get('source_team_name',''))
    outdated = bool(historical_label and int(historical_label[1]) < 2026) or bool(season and season not in {'2026','25/26','2025/26','26/27','2026/27'})
    if season and season not in {'2026','25/26','2025/26','26/27','2026/27'}:
        complete = False
    primary = next((m for m in job['competition_memberships'] if m['scope_role']=='national_league'),job['competition_memberships'][0])
    squad = {'country_code':job['country_code'],'country':job['country_name'],'club_source_key':job['club_source_key'],'club_name':job['club_name'],'category':job['category'],'source_team_name':job.get('source_team_name',job['club_name']),'source_category_literal':job.get('source_category_literal','First team'),'season':primary['source_season'],'source_season':season,'source_season_parameter':parameter,'source_season_evidence':season_evidence,'source':'verified_manual','source_url':source_url,'requested_url':result['url'],'source_title':result.get('title'),'transfermarkt_team_id':job['tm_club_id'],'checked_at':checked_at,'completeness':'complete' if complete else 'partial','completeness_scope':'all player rows in retrieved table; not exhaustive real-world or Transfermarkt country coverage','expected_count':len(rows),'players':players,'excluded':excluded,'source_html_sha256':hashlib.sha256(result['text'].encode()).hexdigest(),'raw_evidence_file':raw_file,'category_evidence_url':job.get('discovered_from') or source_url,'notes':'Fuente consultada; sin jugadores publicados en la nómina recuperada.' if not players else ('Temporada de fuente fuera de2026; revisión necesaria.' if season and season not in {'2026','25/26','2025/26','26/27','2026/27'} else None)}
    if outdated:
        squad.update({'source_status':'outdated','historical_players':players,'players':[],'expected_count':None,'completeness':'unavailable','notes':'La fuente identifica un equipo histórico o una temporada fuera del alcance actual; no se publican jugadores como plantilla vigente.'})
    club = None
    children = []
    if job['category'] == 'Primera':
        legal = doc.xpath('.//*[@itemprop="legalName"]')
        club = {**job,'source_legal_name':txt(legal[0]) if legal else None,'source_url':source_url,'source_urls':[source_url],'checked_at':checked_at,'source':'verified_manual',**geography(doc,job,source_url)}
        children = subteams(doc,job,source_url,checked_at)
    return squad,club,children

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--directory',type=Path,required=True)
    root=ap.parse_args().directory
    jobs={j['tm_club_id']:j for j in json.loads((root/'all-club-jobs.json').read_text())}
    results=collections.defaultdict(list);fetch_errors=[];raw_manifest=[]
    for fn in sorted((root/'raw').glob('*.json')):
        data=fn.read_bytes();payload=json.loads(data)
        raw_manifest.append({'file':fn.name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
        for r in payload.get('results',[]):
            if not isinstance(r,dict) or not r.get('text') or '/startseite/verein/' not in r.get('url',''):
                continue
            clubid=id_from_url(r['url']);checked_at=r.get('fetched_at') or r.get('checked_at') or payload.get('fetched_at')
            if not checked_at:
                raise ValueError('Missing fetch timestamp: '+fn.name)
            results[clubid].append((checked_at,r,fn.name))
        for error in payload.get('errors',[]):
            if '/verein/' in error.get('url',''):
                fetch_errors.append({**error,'checked_at':payload.get('fetched_at'),'raw_evidence_file':fn.name})
    squads={};clubfacts={};subteamfacts={};parse_errors=[]
    def run_job(job):
        for checked_at,result,raw_file in sorted(results.get(job['tm_club_id'],[]),key=lambda x:x[0],reverse=True):
            try:
                squad,club,children=parse_result(result,job,checked_at,raw_file)
                squads[(job['club_source_key'],job['category'])]=squad
                if club:
                    clubfacts[job['tm_club_id']]=club
                for child in children:
                    subteamfacts[(job['tm_club_id'],child['tm_club_id'])]=child
                return
            except Exception as exc:
                parse_errors.append({'tm_club_id':job['tm_club_id'],'url':result['url'],'raw_evidence_file':raw_file,'reason':str(exc)})
    for job in jobs.values():
        run_job(job)
    reserve_candidates=[j for j in subteamfacts.values() if j['category']=='Reserva']
    reserve_identity_parents=collections.defaultdict(set)
    for job in reserve_candidates:
        reserve_identity_parents[job['tm_club_id']].add(job['parent_tm_club_id'])
    reservejobs=[]
    reserve_excluded=[]
    for job in reserve_candidates:
        if len(reserve_identity_parents[job['tm_club_id']])!=1:
            candidates=[j for j in reserve_candidates if j['tm_club_id']==job['tm_club_id']]
            matching=[j for j in candidates if name_stem(j['source_team_name']) in {name_stem(j['club_name']),name_stem(clubfacts.get(j['parent_tm_club_id'],{}).get('source_legal_name'))}]
            if len(matching)!=1 or job['parent_tm_club_id']!=matching[0]['parent_tm_club_id']:
                reserve_excluded.append({**job,'reason':'affiliated_group_header; exact reserve name belongs to a different parent club' if len(matching)==1 else 'reserve_has_multiple_parent_clubs; unresolved'})
                continue
            job['parent_resolution']='exact source reserve name without B/II/Reserves matches this parent club name; other group member excluded'
        reservejobs.append(job)
    for job in reservejobs:
        run_job(job)
    missing=[j for j in list(jobs.values())+reservejobs if (j['club_source_key'],j['category']) not in squads]
    player_memberships=collections.defaultdict(list)
    for squad in squads.values():
        for p in squad['players']:
            player_memberships[p['transfermarkt_id']].append({'club_source_key':squad['club_source_key'],'category':squad['category'],'full_name':p['full_name'],'birth_date':p['birth_date'],'source_url':squad['source_url'],'checked_at':squad['checked_at']})
    conflicts=[{'transfermarkt_id':pid,'memberships':memberships,'reason':'multiple_parent_clubs_observed; no automatic affiliation reconciliation'} for pid,memberships in player_memberships.items() if len({m['club_source_key'] for m in memberships})>1]
    facts={'metadata':{'schema_version':2,'kind':'reviewed_south_america_source_facts','review_date':'2026-11-19','countries':['BR','CL','CO','EC','UY'],'market_values_policy':'No valuation date in squad table; all current valuation fields remain null.','coverage_policy':'All rows retrieved from the explicitly listed sources. Not an exhaustive list of all clubs in a country or Transfermarkt.'},'clubs':list(clubfacts.values()),'squads':list(squads.values()),'subteam_discovery':list(subteamfacts.values()),'reserve_parent_exclusions':reserve_excluded,'unavailable_jobs':missing,'fetch_errors':fetch_errors,'parse_errors':parse_errors,'cross_club_player_conflicts':conflicts,'raw_evidence_manifest':raw_manifest}
    report={'clubs_discovered':len(jobs),'clubs_with_parsed_source':len(clubfacts),'squads':len(squads),'reserve_jobs':len(reservejobs),'memberships':sum(len(s['players']) for s in squads.values()),'unique_player_ids':len(player_memberships),'cross_club_conflicts':len(conflicts),'missing_jobs':len(missing),'parse_errors':len(parse_errors),'source_seasons':dict(collections.Counter(s['source_season'] for s in squads.values())),'completeness':dict(collections.Counter(s['completeness'] for s in squads.values())),'by_country':{code:{'clubs':sum(c['country_code']==code for c in clubfacts.values()),'players':len({p['transfermarkt_id'] for s in squads.values() if s['country_code']==code for p in s['players']})} for code in ['BR','CL','CO','EC','UY']}}
    for name,value in [('source-facts.json',facts),('reserve-club-jobs.json',reservejobs),('youth-subteam-discovery.json',[j for j in subteamfacts.values() if j['category'] is None]),('missing-club-jobs.json',missing),('parse-report.json',report)]:
        (root/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(report,ensure_ascii=False))

if __name__=='__main__':
    main()
