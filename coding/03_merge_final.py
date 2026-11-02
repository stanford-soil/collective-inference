import json, glob, os, pandas as pd
P='adjudication/'
items={str(i['id']):i for i in json.load(open(P+'items.json'))}
dec=json.load(open('adjudication/decisions.json'))
dec={k:(v.get('data',v)) for k,v in dec.items()}
orph=[k for k in dec if k not in items]; missing=[k for k in items if k not in dec]
print('decisions',len(dec),'orphans (old grouped items, ignored):',orph,' items without decision:',len(missing))
d=pd.read_pickle('merged_rules.pkl').copy()
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
d.to_pickle('final_codes.pkl')
out=d[['row','gameID','round','sender.id','recipient','text']].copy()
out['code_coder1']=d.Y.map(lambda s:'+'.join(sorted(s))); out['code_coder2']=d.C.map(lambda s:'+'.join(sorted(s)))
out['code_final']=d.final.map(lambda s:'+'.join(sorted(s)) if isinstance(s,set) else None); out['resolution']=d.how
out.drop(columns='row').to_csv('exp2_message_codes_final.csv',index=False)
