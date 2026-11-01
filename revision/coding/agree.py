import pandas as pd, glob
from sklearn.metrics import cohen_kappa_score
d=pd.read_csv('../../data/exp2/coded_messages.csv')
d['text_norm']=d.text.fillna('').str.strip()
u=pd.read_csv('unique_texts.csv')
o=pd.concat([pd.read_csv(f) for f in sorted(glob.glob('out_*.csv'))])
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
d.to_pickle('merged.pkl')
