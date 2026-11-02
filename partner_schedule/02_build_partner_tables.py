import pandas as pd, numpy as np
def outp(N,i,t): return [j for j in range(N) if j!=i][(i+t)%(N-1)]
def table(P, nrounds, exp):
    P=P.dropna(subset=['gameID','name']).drop_duplicates(['gameID','id'])
    rows=[]
    for g,df in P.groupby('gameID'):
        N=len(df); byidx={int(n.split()[-1])-1:pid for pid,n in zip(df.id,df.name)}
        if N<2 or sorted(byidx)!=list(range(N)): continue
        for t in range(1,nrounds+1):
            for i,pid in byidx.items():
                o=outp(N,i,t); ins=[k for k in range(N) if outp(N,k,t)==i]
                rows.append(dict(gameID=g,playerID=pid,player_name=f'player {i+1}',round=t,nPlayers=N,
                  recipientID=byidx[o], senderToPlayerIDs=';'.join(byidx[k] for k in ins),
                  partnerID=byidx[ins[0]] if len(ins)==1 else None,
                  reciprocal=(outp(N,o,t)==i)))
    return pd.DataFrame(rows)
P1=pd.read_csv('exp1_players_raw.csv'); P2=pd.read_csv('exp2_players_raw.csv')
t1=table(P1,12,1); t2=table(P2,8,2)
t1.to_csv('exp1_partners.csv',index=False)
print('exp1 partner table', t1.shape, 'games', t1.gameID.nunique(), 'in-degree!=1 rows', t1.partnerID.isna().sum())
print('exp1 reciprocal share by round (N=4):', t1[t1.nPlayers==4].groupby('round').reciprocal.mean().to_dict())
# validate exp1 table vs messages
ex=pd.read_csv('exp1_extracted_sched.csv')
m=ex.merge(t1,left_on=['gameID','sender.id','round'],right_on=['gameID','playerID','round'],how='left')
print('exp1 msgs: recipient==table recipientID', (m.recipient==m.recipientID).sum(), len(m))
# exp2 message-level
cm=pd.read_csv('../../data/exp2/coded_messages.csv')
m2=cm.merge(t2[['gameID','playerID','round','nPlayers','recipientID','senderToPlayerIDs','reciprocal']],left_on=['gameID','sender.id','round'],right_on=['gameID','playerID','round'],how='left')
print('exp2 coded msgs matched', m2.recipientID.notna().sum(), len(m2), ' recipient==scheduled', (m2.recipient==m2.recipientID).sum())
m2['replies_reach_sender']=m2.reciprocal
out=m2[['gameID','sender.id','sender.name','round','text','coding','recipient','recipientID','senderToPlayerIDs','reciprocal','nPlayers']].rename(columns={'recipient':'recipient_recorded','recipientID':'recipient_scheduled','senderToPlayerIDs':'sender_receives_from','reciprocal':'reciprocal_round'})
out.to_csv('exp2_partners.csv',index=False)
print('exp2 coded msgs in reciprocal rounds:', out.reciprocal_round.sum(), 'non-reciprocal', (~out.reciprocal_round.astype(bool)).sum())
print(out.groupby('round').reciprocal_round.agg(['mean','size']).to_string())
t2.to_csv('exp2_partners_playerround.csv',index=False)
# exp2 all raw chat vs schedule
c=pd.read_csv('exp2_chat_raw.csv')
mc=c.merge(t2,left_on=['gameID','sender','round'],right_on=['gameID','playerID','round'],how='left')
print('exp2 raw chat recipient == schedule', (mc.recipient==mc.recipientID).sum(), mc.recipientID.notna().sum(), len(mc))
