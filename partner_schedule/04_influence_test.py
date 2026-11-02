"""Whose information moved participants' estimates in a one-way round?
Exp 2, real-time messaging condition, round 2 (the first one-way round; neither
the sender nor the recipient had been encountered before). Regresses the change
in estimate on the distance to the sender's sample (received from) and to the
recipient's sample (sent to). Run from this folder."""
import pandas as pd, numpy as np, statsmodels.formula.api as smf
d=pd.read_csv('../../data/exp2/coded_messages.csv')
x=pd.read_csv('../../analysis/exp2/exp2_clean_data.csv'); s=pd.read_csv('exp2_partners_playerround.csv')
samp=d.groupby(['gameID','sender.id'])['mleEstimate.x'].first()*100
orient=d.groupby('gameID').direction.first()
x=x.dropna(subset=['guess'])
x['g']=np.where(x.gameID.map(orient)=='RS',100-x.guess,x.guess)   # rabbit share
G=x.groupby(['gameID','playerID','idx']).g.last()
rows=[]
for _,r in s[(s['round']==2)&(~s.reciprocal)].iterrows():
    k1=(r.gameID,r.playerID,1); k2=(r.gameID,r.playerID,2)
    if k1 not in G.index or k2 not in G.index: continue
    a=(r.gameID,r.partnerID); b=(r.gameID,r.recipientID)
    if a not in samp.index or b not in samp.index: continue
    g1=G[k1]; rows.append(dict(game=r.gameID,update=G[k2]-g1,d_in=samp[a]-g1,d_out=samp[b]-g1))
df=pd.DataFrame(rows)
m=smf.ols('update ~ d_in + d_out',df).fit(cov_type='cluster',cov_kwds={'groups':df.game.astype('category').cat.codes})
print('n',len(df),'games',df.game.nunique()); print(m.summary().tables[1])
