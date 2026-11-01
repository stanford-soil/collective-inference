import pandas as pd
chat=pd.read_csv('exp2_chat_raw.csv'); P=pd.read_csv('exp2_players_raw.csv')
def sched(n,idx):
    out={}
    for i in range(n):
        others=[j for j in range(n) if j!=i]; out[i]=others[(i+idx)%len(others)]
    return out
for idx in range(1,9): print(idx, sched(4,idx))
# map sender name -> index within game
chat['si']=chat.sender_name.str.extract(r'player (\d+)').astype(float)-1
name=chat.drop_duplicates(['gameID','sender'])[['gameID','sender','si']]
idmap={ (r.gameID,r.sender):r.si for r in name.itertuples()}
# also from player.csv names
for r in P.dropna(subset=['name']).itertuples():
    idmap.setdefault((r.gameID,r.id), int(r.name.split()[-1])-1)
chat['ri']=[idmap.get((g,x)) for g,x in zip(chat.gameID,chat.recipient)]
nplayers=P.dropna(subset=['gameID']).groupby('gameID').id.nunique()
chat['n']=chat.gameID.map(nplayers)
chat['sched_ri']=[sched(int(n),int(r))[int(s)] if pd.notna(s) and pd.notna(n) and pd.notna(r) else None for s,n,r in zip(chat.si,chat.n,chat['round'])]
print(chat.n.value_counts())
chat['match']=chat.ri==chat.sched_ri
print('chat recipient == schedule:', chat.match.mean(), chat.match.sum(), len(chat))
print(chat.groupby('round').match.agg(['mean','size']))
print(chat[~chat.match][['gameID','round','si','ri','sched_ri','n','text']].head(15))
chat.to_csv('exp2_chat_sched.csv',index=False)
