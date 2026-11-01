import pandas as pd, json, os
R='../../data/exp1/raw'
rows=[];P=[];G=[]
for b in sorted(d for d in os.listdir(R) if d.startswith('1_prereg_')):
    g=pd.read_csv(f'{R}/{b}/games.csv',encoding='utf-8-sig'); p=pd.read_csv(f'{R}/{b}/players.csv',encoding='utf-8-sig')
    p['batch']=b; P.append(p[['id','gameID','name','recipient','batch']]); G.append(g[['id','groupID','treatmentName']].assign(batch=b))
    for _,r in g.iterrows():
        if pd.isna(r.get('chat')): continue
        for k,m in enumerate(json.loads(r.chat)):
            rows.append(dict(batch=b,gameID=r.id,groupID=r.groupID,treatmentName=r.treatmentName,k=k,text=m.get('text'),time=m.get('time'),round=m.get('round'),recipient=m.get('recipient'),sender=m['sender']['id'],sender_name=m['sender'].get('name')))
chat=pd.DataFrame(rows);P=pd.concat(P);G=pd.concat(G)
chat.to_csv('exp1_chat_raw.csv',index=False);P.to_csv('exp1_players_raw.csv',index=False);G.to_csv('exp1_games_raw.csv',index=False)
print(chat.shape, chat.gameID.nunique(), chat.treatmentName.value_counts().to_dict())
print('groupID unique per game?', G.groupby('groupID').id.nunique().max())
P2=P.dropna(subset=['gameID']); print(P2.groupby('gameID').id.nunique().value_counts())
