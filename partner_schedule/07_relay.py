import pandas as pd, re, numpy as np
m=pd.read_csv('../partner_schedule/exp1_msgs_raw.csv').drop_duplicates(['gameID','sender','time','text'])
G=pd.read_csv('../partner_schedule/exp1_games_raw.csv').rename(columns={'id':'gameID'})
reg=pd.read_csv('../../data/exp1/PreregMergedGuesses.csv')
samp=reg.groupby(['gameID','playerID'])[['nRabbits','nSquirrels']].first()
samp={k:(int(v.nRabbits),int(v.nSquirrels)) for k,v in samp.iterrows()}
cond=G.drop_duplicates('gameID').set_index('gameID').treatmentName
m['cond']=m.gameID.map(cond)
W={'zero':0,'no':0,'none':0,'one':1,'a':1,'an':1,'single':1,'two':2,'three':3,'four':4,'five':5,'six':6,'seven':7,'eight':8,'nine':9,'ten':10,'eleven':11,'twelve':12}
def counts(t):
    t=str(t).lower(); R=[];S=[]
    for n,k in re.findall(r"(\d+|zero|no|none|one|a|an|single|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\s+(?:\w+\s+)?(rabbit|bunn|bunnie|squir|sq)",t):
        v=int(n) if n.isdigit() else W[n]
        (R if k.startswith(('rabbit','bunn')) else S).append(v)
    return R,S
def has(t,smp):
    R,S=counts(t); r,s=smp
    # require the sample's distinctive nonzero count(s) to appear
    okR = (r in R) if r>0 else True; okS=(s in S) if s>0 else True
    return okR and okS and (r>0 or s>0)
rows=[]
for (g,rd),x in m[m['round']==2].groupby(['gameID','round']):
    for sp,mine in x.groupby('sender'):
        rec=mine.recipient.iloc[0]
        inc=x[x.recipient==sp]
        if inc.empty: continue
        ip=inc.sender.iloc[0]
        if ip==rec: continue          # mutual, skip
        r1=m[(m.gameID==g)&(m['round']==1)]
        p1=set(r1[r1.sender==sp].recipient)|set(r1[r1.recipient==sp].sender)
        if (g,ip) not in samp or (g,sp) not in samp: continue
        others=[samp[(g,sp)]]+[samp[(g,p)] for p in p1 if (g,p) in samp]
        if samp[(g,ip)] in others or samp[(g,ip)]==(0,0): continue   # in-partner's sample indistinguishable
        t0=inc.time.min()
        after=mine[mine.time>t0]
        rows.append(dict(game=g,cond=m.loc[mine.index[0],'cond'],sender=sp,
            n_msgs=len(mine),n_after=len(after),
            relayed=any(has(t,samp[(g,ip)]) for t in mine.text),
            relayed_after=any(has(t,samp[(g,ip)]) for t in after.text)))
r=pd.DataFrame(rows)
print(r.groupby('cond').agg(players=('sender','size'),games=('game','nunique'),relayed=('relayed','mean'),relayed_after=('relayed_after','mean'),any_after=('n_after',lambda s:(s>0).mean())).round(3))
r.to_csv('relay_round2.csv',index=False)
for c in r.cond.unique():
    print(c, r[(r.cond==c)].relayed.sum())
