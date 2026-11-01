import pandas as pd, json, os
from collections import Counter
R='../../data/exp1/raw'; rows=[]
for b in sorted(d for d in os.listdir(R) if d.startswith('1_prereg_')):
    g=pd.read_csv(f'{R}/{b}/games.csv',encoding='utf-8-sig')
    for _,r in g.iterrows():
        for col in ['messages','chat']:
            v=r.get(col)
            if pd.isna(v): continue
            j=json.loads(v); j=j if isinstance(j,list) else [j]
            for m in j:
                if isinstance(m,str): m=json.loads(m)
                rows.append(dict(gameID=r.id,tn=r.treatmentName,src=col,round=m.get('round'),rec=m.get('recipient'),snd=m['sender']['id'],time=m.get('time'),text=m.get('text')))
d=pd.DataFrame(rows)
print(d.groupby('src').size().to_dict())
d=d.drop_duplicates(['gameID','snd','round','time','text'])
d['cond']=d.tn.str.extract(r'rerun-(\w+)')
print('unique msgs',len(d), d.cond.value_counts().to_dict())
pairs=d.drop_duplicates(['gameID','round','snd','rec'])
S=set(zip(pairs.gameID,pairs['round'],pairs.snd,pairs.rec))
pairs=pairs.assign(sym=[(g,t,r,s) in S for g,t,s,r in zip(pairs.gameID,pairs['round'],pairs.snd,pairs.rec)])
# only count directed edges whose reverse could be observed: restrict to games where all senders sent in that round
print(pairs.pivot_table(index='round',columns='cond',values='sym',aggfunc='mean').round(3).to_string())
# recipient changes within same (game,round,sender)? 
print('multiple recipients per sender-round:', (d.groupby(['gameID','round','snd']).rec.nunique()>1).sum())
# schedule check by condition
t=pd.read_csv('exp1_partners.csv'); T={(a,b,c):r for a,b,c,r in zip(t.gameID,t.playerID,t['round'],t.recipientID)}
d['ok']=[T.get((g,s,int(r)))==x for g,s,r,x in zip(d.gameID,d.snd,d['round'],d.rec)]
print('matches schedule by cond', d.groupby('cond').ok.agg(['sum','size']).to_dict())
# game sizes among games with guesses
gs=pd.read_csv('../../data/exp1/PreregMergedGuesses.csv')
gs['cond']=gs.treatmentName.str.extract(r'rerun-(\w+)')
n=t.drop_duplicates('gameID').set_index('gameID').nPlayers
gg=gs.drop_duplicates('gameID'); gg['N']=gg.gameID.map(n)
print('games with guesses by N and cond'); print(pd.crosstab(gg.N,gg.cond))
# per-player: count per other-player of out, in, mutual rounds (N=4, 12 rounds)
t4=t[t.nPlayers==4]
c=Counter()
for (g,p),df in t4.groupby(['gameID','playerID']):
    others={}
    for r in df.itertuples():
        for o in set([r.recipientID,r.partnerID]):
            others.setdefault(o,[0,0,0])
        others[r.recipientID][0]+=1; others[r.partnerID][1]+=1
        if r.reciprocal: others[r.recipientID][2]+=1
    c[tuple(sorted(tuple(v) for v in others.values()))]+=1
print('N=4 per-player (out,in,mutual) counts across 3 others:', dict(c))
