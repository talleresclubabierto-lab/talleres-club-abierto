#!/usr/bin/env python3
"""Create reviewable import templates from frozen evidence, never execute imports.

Optimistic-lock fingerprints MUST be injected from the current country database
state just before each reviewed transaction. Templates intentionally are not
executable while they contain REQUIRES_CURRENT_COUNTRY_FINGERPRINT markers.
"""
import argparse
import collections
import copy
import hashlib
import json
import re
import unicodedata
from pathlib import Path

EXISTING = {'BRA1':'brasil-serie-a','BRA2':'brasil-serie-b','BRA3':'brasil-serie-c','BRA4':'brasil-serie-d','CLPD':'chile-primera-division','CL2B':'chile-primera-b','CHI3':'chile-segunda-profesional','EC1N':'ecuador-serie-a','EC2L':'ecuador-serie-b','URUC':'uruguay-primera-division','URU2':'uruguay-segunda-profesional','COL1':'colombia-liga-betplay','CO22':'colombia-torneo-betplay'}
COUNTRIES={'BR':'Brasil','CL':'Chile','CO':'Colombia','EC':'Ecuador','UY':'Uruguay'}
DIVISIONS={'First Tier':'Primera División','Second Tier':'Segunda División','Third Tier':'Tercera División','Fourth Tier':'Cuarta División'}

def slug(value):
    return re.sub(r'[^a-z0-9]+','-',unicodedata.normalize('NFKD',value).encode('ascii','ignore').decode().lower()).strip('-')

def iso(value):
    import datetime as dt
    return dt.datetime.fromisoformat(value.replace(' UTC','+00:00').replace('Z','+00:00')).astimezone(dt.timezone.utc).isoformat().replace('+00:00','Z')

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--directory',type=Path,required=True)
    root=ap.parse_args().directory
    facts=json.loads((root/'source-facts.json').read_text())
    observations=json.loads((root/'all-competition-observations.json').read_text())
    comps={c['tm_competition_id']:c for c in observations}
    compids={cid:EXISTING.get(cid) or slug(c['country_name']+'-'+c['name']) for cid,c in comps.items()}
    if len(set(compids.values()))!=len(compids):
        raise ValueError('Competition slug collision')
    conflicts={c['transfermarkt_id'] for c in facts['cross_club_player_conflicts']}
    output=root/'import-templates';output.mkdir(exist_ok=True)
    manifest={'status':'review_templates_require_current_fingerprints','source_facts_sha256':hashlib.sha256((root/'source-facts.json').read_bytes()).hexdigest(),'competition_id_mapping':compids,'cross_club_player_conflicts_excluded':sorted(conflicts,key=int),'countries':{},'files':[]}
    for code,country in COUNTRIES.items():
        new_comps=[]
        for order,(cid,c) in enumerate(comps.items()):
            if c['country_code']!=code or cid in EXISTING:
                continue
            new_comps.append({'id':compids[cid],'name':country+' · '+c['name'],'season':'2026','sort_order':200+order,'source_url':c['source_url']})
        clubs=[]
        for club in facts['clubs']:
            if club['country_code']!=code:
                continue
            memberships=[]
            for membership in club['competition_memberships']:
                role=membership['scope_role']
                division=DIVISIONS.get(membership.get('tier_label')) if role=='national_league' else ('Campeonato estadual' if role=='state_championship' else 'Copa nacional')
                if not division:
                    raise ValueError('No factual division mapping: '+str(membership))
                memberships.append({'competition_id':compids[membership['tm_competition_id']],'season':membership['source_season'],'division':division,'reference_scope':'primer_equipo_masculino','source_url':membership['source_url'],'checked_at':iso(membership['checked_at'])})
            primary=next((m for m in club['competition_memberships'] if m['scope_role']=='national_league'),club['competition_memberships'][0])
            clubs.append({'transfermarkt_id':club['tm_club_id'],'source_key':club['club_source_key'],'name':club['club_name'],'province':club['province'],'city':club['city'],'league':primary['competition_name'],'source':'verified_manual','source_urls':club['source_urls'],'geography_source_urls':club['geography_source_urls'],'checked_at':iso(club['checked_at']),'competitions':memberships})
        clubdoc={'metadata':{'schema_version':1,'kind':'reviewed_clubs','country_code':code,'country':country,'batch_key':code.lower()+'-clubs-2026-11-19','expected_clubs_sha256':'REQUIRES_CURRENT_COUNTRY_FINGERPRINT','expected_competitions_sha256':'REQUIRES_CURRENT_COUNTRY_FINGERPRINT','expected_club_competitions_sha256':'REQUIRES_CURRENT_COUNTRY_FINGERPRINT'},'competitions':new_comps,'clubs':clubs}
        squads=[];excluded_count=0
        for fact in facts['squads']:
            if fact['country_code']!=code:
                continue
            squad={k:copy.deepcopy(fact[k]) for k in ['club_source_key','category','season','source_season','source_url','source_title','source','checked_at','completeness','expected_count','notes']}
            squad['checked_at']=iso(squad['checked_at'])
            players=[]
            for p in fact['players']:
                if p['transfermarkt_id'] in conflicts:
                    excluded_count+=1
                    continue
                fields=['transfermarkt_id','transfermarkt_url','first_name','last_name','full_name','name_kind','position','birth_date','birth_date_source_url','birth_date_verified_at']
                player={k:p.get(k) for k in fields}
                if player.get('birth_date_verified_at'):
                    player['birth_date_verified_at']=iso(player['birth_date_verified_at'])
                players.append(player)
            if len(players)!=len(fact['players']):
                squad['completeness']='partial'
                squad['notes']='Se omitieron identidades presentes en más de un club de las fuentes revisadas; afiliación pendiente de reconciliación explícita.'
            squad['players']=players
            if not players and squad['completeness']=='complete':
                raise ValueError('Empty complete squad')
            squads.append(squad)
        rosterdoc={'metadata':{'schema_version':2,'country_code':code,'country':country,'fingerprint_scope':'country','batch_key':code.lower()+'-squads-2026-11-19','expected_players_sha256':'REQUIRES_CURRENT_COUNTRY_FINGERPRINT','expected_clubs_sha256':'REQUIRES_CURRENT_COUNTRY_FINGERPRINT'},'squads':squads}
        for kind,document in [('clubs',clubdoc),('rosters',rosterdoc)]:
            fn=output/(code.lower()+'-'+kind+'.template.json')
            data=(json.dumps(document,ensure_ascii=False,separators=(',',':'))+'\n').encode();fn.write_bytes(data)
            manifest['files'].append({'path':str(fn.relative_to(root)),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
        manifest['countries'][code]={'clubs':len(clubs),'new_competitions':len(new_comps),'competition_memberships':sum(len(c['competitions'])for c in clubs),'squads':len(squads),'player_memberships':sum(len(s['players'])for s in squads),'unique_player_ids':len({p['transfermarkt_id'] for s in squads for p in s['players']}),'ambiguous_player_memberships_excluded':excluded_count,'mononym_memberships':sum(p['name_kind']=='sporting_mononym'for s in squads for p in s['players']),'review_statuses':dict(collections.Counter(s['completeness']for s in squads))}
    (output/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'countries':manifest['countries'],'files':manifest['files']},ensure_ascii=False))

if __name__=='__main__':
    main()
