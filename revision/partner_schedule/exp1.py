import pandas as pd, json, os
R='../../data/exp1/raw'
rows=[];P=[];G=[]
for b in sorted(d for d in os.listdir(R) if d.startswith('1_prereg_')):
    g=pd.read_csv(f'{R}/{b}/games.csv',encoding='utf-8-sig'); p=pd.read_csv(f'{R}/{b}/players.csv',encoding='utf-8-sig')
    p['batch']=b; P.append(p[['id','gameID','name','recipient','batch']]); G.append(g[['id','groupID','treatmentName']].assign(batch=b))
    for _,r in g.iterrows():
        if pd.isna(r.get('messages')): continue
        for k,m in enumerate(json.loads(r.messages)):
            rows.append(dict(batch=b,gameID=r.id,groupID=r.groupID,k=k,text=m.get('text'),time=m.get('time'),round=m.get('round'),recipient=m.get('recipient'),sender=m['sender']['id'],sender_name=m['sender'].get('name')))
raw=pd.DataFrame(rows);P=pd.concat(P);G=pd.concat(G)
print('raw messages', raw.shape, 'games', raw.gameID.nunique())
print('groupID->games max', G.groupby('groupID').id.nunique().max())
ex=pd.read_csv(f'{R}/1_extracted_msgs_prereg/extracted_messages.csv')
print('extracted', ex.shape, 'groups', ex.groupID.nunique())
key=['groupID','sender.id','round','time','text']
r2=raw.rename(columns={'sender':'sender.id','recipient':'raw_recipient'})
m=ex.merge(r2[key+['raw_recipient']].drop_duplicates(key),on=key,how='left',indicator=True)
print(m._merge.value_counts().to_dict())
print('extracted recipient == raw message recipient', (m.recipient==m.raw_recipient).sum(), m._merge.eq('both').sum())
# schedule
P2=P.dropna(subset=['gameID','name'])
idx={(r.gameID,r.id):int(r.name.split()[-1])-1 for r in P2.itertuples()}
n={gid:len(s) for gid,s in P2.groupby('gameID')}
g2grp=dict(zip(G.id,G.groupID)); grp2g={v:k for k,v in g2grp.items()}
ex['gameID']=ex.groupID.map(grp2g)
ex['si']=[idx.get((g,s)) for g,s in zip(ex.gameID,ex['sender.id'])]
ex['ri']=[idx.get((g,s)) for g,s in zip(ex.gameID,ex.recipient)]
ex['n']=ex.gameID.map(n)
def sched(N,i,t):
    o=[j for j in range(N) if j!=i]; return o[(i+t)%len(o)]
ok=ex.dropna(subset=['si','ri','n','round'])
ex['sched_ri']=[sched(int(N),int(i),int(t)) if pd.notna(N) and pd.notna(i) and pd.notna(t) else None for N,i,t in zip(ex.n,ex.si,ex['round'])]
print('n players dist', ex.n.value_counts(dropna=False).to_dict())
ex['agree']=ex.ri==ex.sched_ri
print('extracted recipient == schedule', ex.agree.sum(), ex.sched_ri.notna().sum())
print(ex.groupby('round').agree.agg(['mean','size']))
ex.to_csv('exp1_extracted_sched.csv',index=False); raw.to_csv('exp1_msgs_raw.csv',index=False); P.to_csv('exp1_players_raw.csv',index=False); G.to_csv('exp1_games_raw.csv',index=False)
