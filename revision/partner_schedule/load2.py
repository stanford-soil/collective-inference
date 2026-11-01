import pandas as pd, json, glob, os
R='../../data/exp2/raw'
rows=[];players=[]
for b in sorted(os.listdir(R)):
    g=pd.read_csv(f'{R}/{b}/game.csv')
    p=pd.read_csv(f'{R}/{b}/player.csv')
    p['batch']=b; players.append(p[['id','gameID','name','recipient','recipientLastChangedAt','batch']])
    for _,r in g.iterrows():
        if pd.isna(r.get('chat')): continue
        tr=json.loads(r.treatment) if isinstance(r.treatment,str) else {}
        for k,m in enumerate(json.loads(r.chat)):
            rows.append(dict(batch=b,gameID=r.id,condition=tr.get('condition'),k=k,text=m.get('text'),time=m.get('time'),round=m.get('round'),
              recipient=m.get('recipient'),sender=m['sender']['id'],sender_name=m['sender'].get('name')))
chat=pd.DataFrame(rows); P=pd.concat(players)
chat.to_csv('exp2_chat_raw.csv',index=False); P.to_csv('exp2_players_raw.csv',index=False)
print(chat.shape, chat.condition.value_counts().to_dict(), chat.gameID.nunique())
print(chat.groupby(['gameID']).k.count().describe())
