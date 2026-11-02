"""Extracts the message logs and player lists from the raw Empirica exports.

Experiment 1: every message stored in the games.csv columns `messages` and `chat`
(column `src`), with sender, recorded recipient, round and time; players.csv and
games.csv rows (player names give the index used by the recipient rule).
Experiment 2: every chat message in game.csv; player.csv rows.

Inputs: data/exp1/raw/1_prereg_*/, data/exp2/raw/<batch>/.
Outputs (data/derived/, not committed): exp1_messages_raw.csv, exp1_players_raw.csv,
exp1_games_raw.csv, exp2_chat_raw.csv, exp2_players_raw.csv.
Run from partner_schedule/ (any folder works).
"""
import json
import os
import sys
import pandas as pd

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib'))
import common

OUT = common.repo_path('data', 'derived')
os.makedirs(OUT, exist_ok=True)

# ---- Experiment 1
rows, P, G = [], [], []
for b in sorted(d for d in os.listdir(common.EXP1_RAW) if d.startswith('1_prereg_')):
    g = pd.read_csv(f'{common.EXP1_RAW}/{b}/games.csv', encoding='utf-8-sig')
    p = pd.read_csv(f'{common.EXP1_RAW}/{b}/players.csv', encoding='utf-8-sig')
    p['batch'] = b
    P.append(p[['id', 'gameID', 'name', 'recipient', 'batch']])
    G.append(g[['id', 'groupID', 'treatmentName']].assign(batch=b))
    for _, r in g.iterrows():
        for col in ['messages', 'chat']:
            v = r.get(col)
            if pd.isna(v):
                continue
            j = json.loads(v)
            j = j if isinstance(j, list) else [j]       # `chat` holds a single message
            for k, m in enumerate(j):
                if isinstance(m, str):
                    m = json.loads(m)
                rows.append(dict(batch=b, gameID=r.id, groupID=r.groupID, treatmentName=r.treatmentName,
                                 src=col, k=k, text=m.get('text'), time=m.get('time'), round=m.get('round'),
                                 recipient=m.get('recipient'), sender=m['sender']['id'],
                                 sender_name=m['sender'].get('name')))
msgs1 = pd.DataFrame(rows)
msgs1.to_csv(f'{OUT}/exp1_messages_raw.csv', index=False)
pd.concat(P).to_csv(f'{OUT}/exp1_players_raw.csv', index=False)
pd.concat(G).to_csv(f'{OUT}/exp1_games_raw.csv', index=False)
print('Exp 1 messages by column:', msgs1.groupby('src').size().to_dict(), '| games:', msgs1.gameID.nunique())

# ---- Experiment 2
rows, P = [], []
for b in sorted(d for d in os.listdir(common.EXP2_RAW) if not d.startswith('.')):
    g = pd.read_csv(f'{common.EXP2_RAW}/{b}/game.csv')
    p = pd.read_csv(f'{common.EXP2_RAW}/{b}/player.csv')
    p['batch'] = b
    P.append(p[['id', 'gameID', 'name', 'recipient', 'recipientLastChangedAt', 'batch']])
    for _, r in g.iterrows():
        if pd.isna(r.get('chat')):
            continue
        tr = json.loads(r.treatment) if isinstance(r.treatment, str) else {}
        for k, m in enumerate(json.loads(r.chat)):
            rows.append(dict(batch=b, gameID=r.id, condition=tr.get('condition'), k=k, text=m.get('text'),
                             time=m.get('time'), round=m.get('round'), recipient=m.get('recipient'),
                             sender=m['sender']['id'], sender_name=m['sender'].get('name')))
chat2 = pd.DataFrame(rows)
chat2.to_csv(f'{OUT}/exp2_chat_raw.csv', index=False)
pd.concat(P).to_csv(f'{OUT}/exp2_players_raw.csv', index=False)
print('Exp 2 chat messages:', len(chat2), chat2.condition.value_counts().to_dict(), '| games:', chat2.gameID.nunique())
