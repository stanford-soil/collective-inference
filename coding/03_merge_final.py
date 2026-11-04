"""Combines the agreed codes, the rule-based resolutions and the adjudicator's decisions
(adjudication/items.json, decisions.json) into the final code of every Experiment 2
message. Prints how the disagreements were resolved.
Inputs: data/derived/exp2_codes_rules.pkl (02_apply_rules.py), adjudication/.
Output: exp2_message_codes_final.csv (original, second and final code of every message,
with how each disagreement was resolved). Run from coding/."""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib'))
import common
DERIVED = common.repo_path('data', 'derived')
import json, pandas as pd
P='adjudication/'
items={str(i['id']):i for i in json.load(open(P+'items.json'))}
dec=json.load(open('adjudication/decisions.json'))
dec={k:(v.get('data',v)) for k,v in dec.items()}
orph=[k for k in dec if k not in items]; missing=[k for k in items if k not in dec]
print('decisions',len(dec),'orphans (old grouped items, ignored):',orph,' items without decision:',len(missing))
d=pd.read_pickle(f'{DERIVED}/exp2_codes_rules.pkl').copy()
d['how']=d.how.astype(object)
src_count={}
for k,it in items.items():
    if k not in dec: continue
    v=dec[k]; final=set(v['final'])
    rows=[it['row']] if it.get('row') is not None else list(d[(d.uid==it['uid'])&d.final.isna()].row)
    for r in rows:
        i=d.index[d.row==r][0]; d.at[i,'final']=final; d.at[i,'how']='adjudicated:'+str(v.get('src',v.get('choice')))
    src_count[v.get('src',v.get('choice'))]=src_count.get(v.get('src',v.get('choice')),0)+len(rows)
print('remaining undecided messages:',d.final.isna().sum())
print('adjudication sources (messages):',src_count)
print(d.how.str.split(':').str[0].value_counts().to_dict())
out=d[['row','gameID','round','sender.id','recipient','text']].copy()
out['code_coder1']=d.Y.map(lambda s:'+'.join(sorted(s))); out['code_coder2']=d.C.map(lambda s:'+'.join(sorted(s)))
out['code_final']=d.final.map(lambda s:'+'.join(sorted(s)) if isinstance(s,set) else None); out['resolution']=d.how
out.drop(columns='row').to_csv('exp2_message_codes_final.csv',index=False)
