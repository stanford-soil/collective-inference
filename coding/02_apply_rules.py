"""Applies the two adjudication rules (adjudication/RULES.md) to the disagreements
between the original and second codes: rule A, a speaker's own population estimate
is pb (not sb) unless the message refers to other players; rule B, a trailing
question adds q. Lists the remaining disagreements with their conversational context.
Input: data/derived/exp2_codes_compared.pkl (01_agreement.py).
Outputs (data/derived/, not committed): exp2_codes_rules.pkl (for 03_merge_final.py)
and exp2_codes_disputed.json (the disputed unique texts). Run from coding/."""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib'))
import common
DERIVED = common.repo_path('data', 'derived')
import pandas as pd, re, json
d=pd.read_pickle(f'{DERIVED}/exp2_codes_compared.pkl')
d=d.reset_index(drop=True); d['row']=d.index
d['final']=None; d['how']=None
d.loc[d.exact,'final']=d.loc[d.exact,'Y']; d.loc[d.exact,'how']='agree'
other=re.compile(r"\b(other|others|neighbou?r|neighbou?rs|everyone|everybody|we|they|people|partner|partners|total|all of us|combined|someone|anyone|he|she|their|group|overall)\b",re.I)
def ruleA(r):
    Y,C=r.Y,r.C
    if Y^C=={'pb','sb'} and not other.search(r.text_norm): return (Y-{'sb'})|{'pb'}
def ruleB(r):
    Y,C=r.Y,r.C
    if Y^C=={'q'} and (('?' in r.text_norm) or re.search(r"\b(you|u)\W*$",r.text_norm,re.I)): return Y|C
for i,r in d[~d.exact].iterrows():
    for name,f in [('ruleA',ruleA),('ruleB',ruleB)]:
        v=f(r)
        if v: d.at[i,'final']=v; d.at[i,'how']=name; break
print(d.how.value_counts(dropna=False))
d['pair']=d.apply(lambda r:'|'.join(sorted([str(r['sender.id']),str(r.recipient)])),axis=1)
todo=d[d.final.isna()]
print('manual messages',len(todo),'unique texts',todo.text_norm.nunique())
# context: previous 2 messages in same game+round between same pair (row order)
d['pair']=d.apply(lambda r:'|'.join(sorted([str(r['sender.id']),str(r.recipient)])),axis=1)
items=[]
for t,g in todo.groupby('text_norm',sort=False):
    r=g.iloc[0]
    conv=d[(d.gameID==r.gameID)&(d['round']==r['round'])&(d.pair==r.pair)&(d.row<r.row)].tail(2)
    ctx=[{'who':'A' if c['sender.id']==r['sender.id'] else 'B','text':c.text_norm} for _,c in conv.iterrows()]
    items.append({'id':int(r.uid),'text':t,'n':len(g),'ctx':ctx,'Y':sorted(r.Y),'C':sorted(r.C)})
json.dump(items,open(f'{DERIVED}/exp2_codes_disputed.json','w'))
d.to_pickle(f'{DERIVED}/exp2_codes_rules.pkl')
print(len(items))
