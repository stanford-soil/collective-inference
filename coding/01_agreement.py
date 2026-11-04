"""Agreement between the original codes of the Experiment 2 messages (coded_messages.csv,
column `coding`) and the second coder's labels for each unique message text
(second_coder_labels.csv, blind to the original codes): per-code prevalence, percent
agreement and Cohen's kappa, exact agreement of the code sets, and kappa for any
social code (sn or sb).
Inputs: data/exp2/coded_messages.csv, unique_texts.csv, second_coder_labels.csv.
Output: data/derived/exp2_codes_compared.pkl (messages with both code sets, for
02_apply_rules.py; not committed) and printed agreement. Run from coding/."""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib'))
import common
DERIVED = common.repo_path('data', 'derived')
import pandas as pd
from sklearn.metrics import cohen_kappa_score
d=pd.read_csv(common.EXP2_CODED_MSGS)
d['text_norm']=d.text.fillna('').str.strip()
u=pd.read_csv('unique_texts.csv')
o=pd.read_csv('second_coder_labels.csv')
print('coded uids',o.uid.nunique(),'of',len(u))
u=u.merge(o,on='uid',how='left')
d=d.merge(u[['text_norm','uid','codes']],on='text_norm',how='left')
C=['pn','pb','sn','sb','q','o']
def parse_y(s):
    s='' if pd.isna(s) else s
    out=set()
    for c in ['pn','pb','sn','sb']:
        if c in s: out.add(c); s=s.replace(c,'',1) if False else s
    rest=s
    for c in ['pn','pb','sn','sb']: rest=rest.replace(c,'')
    if 'q' in rest: out.add('q')
    if 'o' in rest: out.add('o')
    return out
def parse_c(s): return set(str(s).split('+')) if pd.notna(s) else set()
d['Y']=d.coding.map(parse_y); d['C']=d.codes.map(parse_c)
d=d[d.coding.notna() & (d.coding!='n')]
print('messages compared',len(d))
rows=[]
for c in C:
    y=d.Y.map(lambda s:c in s); k=d.C.map(lambda s:c in s)
    rows.append((c,y.mean().round(3),k.mean().round(3),(y==k).mean().round(3),round(cohen_kappa_score(y,k),3)))
print(pd.DataFrame(rows,columns=['code','prev_Y','prev_2nd','pct_agree','kappa']).to_string(index=False))
d['exact']=d.Y==d.C
print('exact set agreement',d.exact.mean().round(3),' disagreements',(~d.exact).sum(),' unique-text disagreements',d[~d.exact].text_norm.nunique())
# relay (any s code)
y=d.Y.map(lambda s:bool(s&{'sn','sb'})); k=d.C.map(lambda s:bool(s&{'sn','sb'}))
print('any-social kappa',round(cohen_kappa_score(y,k),3),' prev Y',y.mean().round(3),'2nd',k.mean().round(3))
d.to_pickle(f'{DERIVED}/exp2_codes_compared.pkl')
