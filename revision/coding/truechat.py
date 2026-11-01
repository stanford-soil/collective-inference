import pandas as pd, json, glob
rows=[]
for f in glob.glob('../../data/exp2/raw/*/game.csv'):
    g=pd.read_csv(f)
    for _,r in g.iterrows():
        if pd.isna(r.get('chat')): continue
        for m in json.loads(r['chat']):
            rows.append(dict(gameID=r['id'],round=m.get('round'),sender=m['sender']['id'],recipient=m.get('recipient'),time=m.get('time'),text=(m.get('text') or '').strip()))
c=pd.DataFrame(rows).drop_duplicates(['gameID','sender','time','text'])
print('raw chat messages',len(c),'games',c.gameID.nunique())
c.to_pickle('truechat.pkl')
d=pd.read_pickle('merged_rules.pkl')
m=d.merge(c,left_on=['gameID','sender.id','round','text_norm'],right_on=['gameID','sender','round','text'],how='left',suffixes=('','_true'))
m=m.drop_duplicates('row')
print('coded messages matched to raw',m.time.notna().mean().round(4))
ok=m[m.time.notna()]
print('cleaned recipient == true recipient',(ok.recipient==ok.recipient_true).mean().round(3))
print(ok.assign(agree=ok.recipient==ok.recipient_true).groupby('round').agree.mean().round(2).to_dict())
