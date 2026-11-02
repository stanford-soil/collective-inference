"""Checks the reconstructed partner schedule against the logged messages.

1. Structure of the recipient rule by network size: in which rounds the sends form a
   permutation (P) and in which every pair is mutual (S). With N = 4 players, rounds
   1, 4, 7 and 10 are mutual and all other rounds are one-way.
2. Experiment 1 raw messages (games.csv `messages` and `chat`): share of messages
   whose reverse edge was also used in the same round, by round and condition; agreement
   of the recorded recipient with exp1_partners.csv; networks by size and condition;
   out/in/mutual counts per player in 4-player networks.
3. Experiment 1 extracted messages (the partner source of models/01_fit.py): agreement
   of the recorded recipient with exp1_partners.csv.
4. Experiment 2 coded messages and raw chat: agreement of the recorded recipient with
   exp2_partners.csv; coded messages in mutual and one-way rounds.

Inputs: data/derived/exp1_messages_raw.csv, exp2_chat_raw.csv (01_load_raw_logs.py),
exp1_partners.csv, exp2_partners.csv (02_build_partner_tables.py),
data/exp1/PreregMergedGuesses.csv, data/exp1/raw/1_extracted_msgs_prereg/,
data/exp2/coded_messages.csv. Output: printed. Run from partner_schedule/.
"""
import os
import sys
from collections import Counter
import pandas as pd

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib'))
import common

DERIVED = common.repo_path('data', 'derived')
pd.set_option('display.width', 200)

# ---- 1. Structure of the recipient rule
def sched(N, t):
    return {i: [j for j in range(N) if j != i][(i + t) % (N - 1)] for i in range(N)}

print('1. Recipient rule by network size (P = every player receives once, S = all pairs mutual)')
for N in range(2, 10):
    out = []
    for t in range(1, 13):
        s = sched(N, t)
        perm = len(set(s.values())) == N
        sym = all(s[s[i]] == i for i in s)
        out.append(f"{t}:{'P' if perm else 'np'}{'S' if sym else ''}")
    print(N, ' '.join(out))
print('N = 4, recipient of each player by round:')
for t in range(1, 9):
    print(t, sched(4, t))

# ---- 2. Experiment 1 raw messages
d = pd.read_csv(f'{DERIVED}/exp1_messages_raw.csv').rename(
    columns={'treatmentName': 'tn', 'recipient': 'rec', 'sender': 'snd'})
print('\n2. Experiment 1 raw messages by column:', d.groupby('src').size().to_dict())
d = d.drop_duplicates(['gameID', 'snd', 'round', 'time', 'text'])
d['cond'] = d.tn.str.extract(r'rerun-(\w+)')
print('unique messages', len(d), d.cond.value_counts().to_dict())
pairs = d.drop_duplicates(['gameID', 'round', 'snd', 'rec'])
S = set(zip(pairs.gameID, pairs['round'], pairs.snd, pairs.rec))
pairs = pairs.assign(sym=[(g, t, r, s) in S for g, t, s, r in zip(pairs.gameID, pairs['round'], pairs.snd, pairs.rec)])
print('Share of sender-recipient pairs whose reverse pair also exchanged a message, by round:')
print(pairs.pivot_table(index='round', columns='cond', values='sym', aggfunc='mean').round(3).to_string())
print('sender-rounds with more than one recipient:', (d.groupby(['gameID', 'round', 'snd']).rec.nunique() > 1).sum())
t = pd.read_csv('exp1_partners.csv')
T = {(a, b, c): r for a, b, c, r in zip(t.gameID, t.playerID, t['round'], t.recipientID)}
d['ok'] = [T.get((g, s, int(r))) == x for g, s, r, x in zip(d.gameID, d.snd, d['round'], d.rec)]
print('recorded recipient == schedule, by condition', d.groupby('cond').ok.agg(['sum', 'size']).to_dict())
gs = pd.read_csv(common.EXP1_MERGED)
gs['cond'] = gs.treatmentName.str.extract(r'rerun-(\w+)')
n = t.drop_duplicates('gameID').set_index('gameID').nPlayers
gg = gs.drop_duplicates('gameID').copy()
gg['N'] = gg.gameID.map(n)
print('Networks with estimates, by size and condition')
print(pd.crosstab(gg.N, gg.cond))
t4 = t[t.nPlayers == 4]
c = Counter()
for (g, p), df in t4.groupby(['gameID', 'playerID']):
    others = {}
    for r in df.itertuples():
        for o in set([r.recipientID, r.partnerID]):
            others.setdefault(o, [0, 0, 0])
        others[r.recipientID][0] += 1
        others[r.partnerID][1] += 1
        if r.reciprocal:
            others[r.recipientID][2] += 1
    c[tuple(sorted(tuple(v) for v in others.values()))] += 1
print('4-player networks: (sent to, received from, mutual) round counts with each of the 3 others:', dict(c))

# ---- 3. Experiment 1 extracted messages (groupID is the game id)
ex = pd.read_csv(common.EXP1_EXTRACTED_MSGS)
m = ex.merge(t, left_on=['groupID', 'sender.id', 'round'], right_on=['gameID', 'playerID', 'round'], how='left')
print('\n3. Experiment 1 extracted messages:', len(ex), '| in schedule:', m.recipientID.notna().sum(),
      '| recorded recipient == schedule:', (m.recipient == m.recipientID).sum())

# ---- 4. Experiment 2
t2 = pd.read_csv('exp2_partners.csv')
cm = pd.read_csv(common.EXP2_CODED_MSGS)
m2 = cm.merge(t2[['gameID', 'playerID', 'round', 'recipientID', 'reciprocal']],
              left_on=['gameID', 'sender.id', 'round'], right_on=['gameID', 'playerID', 'round'], how='left')
print('\n4. Experiment 2 coded messages matched', m2.recipientID.notna().sum(), 'of', len(m2),
      '| recorded recipient == schedule', (m2.recipient == m2.recipientID).sum())
print('coded messages in mutual rounds:', int(m2.reciprocal.sum()), '| one-way rounds:', int((~m2.reciprocal.astype(bool)).sum()))
print(m2.groupby('round').reciprocal.agg(['mean', 'size']).to_string())
c2 = pd.read_csv(f'{DERIVED}/exp2_chat_raw.csv')
mc = c2.merge(t2, left_on=['gameID', 'sender', 'round'], right_on=['gameID', 'playerID', 'round'], how='left')
print('Experiment 2 raw chat: recorded recipient == schedule', (mc.recipient == mc.recipientID).sum(),
      '| in schedule', mc.recipientID.notna().sum(), '| messages', len(mc))
