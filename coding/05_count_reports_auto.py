"""Automated detection of messages that report animal counts, used where no hand
coding exists: (a) Experiment 1 messages (the hand coding covers Experiment 2 only)
and (b) the Experiment 2 chat networks that are missing from the original coding
file (data/exp2/coded_messages.csv covers 158 of the 180 chat networks).
A message is flagged when it contains a number (digits or a number word) followed
by an animal word ("3 rabbits", "one brown squirrel") or a digit followed by r/s
("3r 2s"). The detector is validated against the adjudicated Experiment 2 codes
(a message "contains counts" if its final code includes pn or sn).
Inputs: coding/exp2_message_codes_final.csv, data/derived/exp2_chat_raw.csv,
exp1_messages_raw.csv (partner_schedule/01_load_raw_logs.py), exp2_clean_data.csv,
exp1_clean_data.csv. Output: printed. Run from coding/."""
import os, sys, re
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib'))
import common
import numpy as np, pandas as pd
from sklearn.metrics import cohen_kappa_score

NUM = r"(?:\d+|zero|no|none|one|a|an|single|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)"
ANI = r"(?:rab+its?|rabits?|bunn(?:y|ies)|squir+els?|sq[a-z]*r+[a-z]*ls?|squirel|rabs?|sqs?)"
P1 = re.compile(rf"\b{NUM}\s+(?:\w+\s+)?{ANI}\b", re.I)
P2 = re.compile(r"\b\d+\s*[rs]\b", re.I)


def has_counts(text):
    t = str(text)
    return bool(P1.search(t) or P2.search(t))


def validity(auto, human):
    tp = (auto & human).sum(); fp = (auto & ~human).sum(); fn = (~auto & human).sum(); tn = (~auto & ~human).sum()
    return dict(n=len(auto), sensitivity=round(tp / (tp + fn), 3), specificity=round(tn / (tn + fp), 3),
                ppv=round(tp / (tp + fp), 3), kappa=round(cohen_kappa_score(auto, human), 3),
                share_hand=round(human.mean(), 3), share_auto=round(auto.mean(), 3))


D = common.repo_path('data', 'derived')
fin = pd.read_csv(common.repo_path('coding', 'exp2_message_codes_final.csv'), keep_default_na=False)
fin['auto'] = fin.text.map(has_counts)
fin['hand'] = fin.code_final.str.contains('pn|sn')
sr = common.sr_games()
print('1. Validation against the adjudicated Experiment 2 codes (message contains counts: pn or sn)')
print('   all coded messages:', validity(fin.auto, fin.hand))
print('   SR networks:       ', validity(fin.auto[fin.gameID.isin(sr)], fin.hand[fin.gameID.isin(sr)]))

# (b) Experiment 2 chat networks without hand codes
x = pd.read_csv(common.EXP2_CLEAN)
g = x.drop_duplicates('gameID').set_index('gameID')['treatmentName.x']
chat_games = set(g.index[g.str.contains('interactive')])
raw = pd.read_csv(os.path.join(D, 'exp2_chat_raw.csv'), keep_default_na=False)
raw = raw.drop_duplicates(['gameID', 'sender', 'time', 'text'])
raw = raw[raw.gameID.isin(chat_games)].copy()
raw['coded'] = raw.gameID.isin(set(fin.gameID)); raw['SR'] = raw.gameID.isin(sr); raw['auto'] = raw.text.map(has_counts)
print('\n2. Experiment 2 chat networks in the analysed sample, by whether the original coding file includes them')
cov = pd.DataFrame({'networks': pd.Series(sorted(chat_games)).isin(set(fin.gameID)).groupby(pd.Series(sorted(chat_games)).isin(sr).values).agg(['sum', 'size']).apply(tuple, axis=1)})
print('   chat networks (coded, total): SR', cov.networks.get(True), ' RS', cov.networks.get(False))
t = raw.groupby(['SR', 'coded']).agg(networks=('gameID', 'nunique'), messages=('text', 'size'), share_with_counts=('auto', 'mean')).round(3)
print(t.to_string())
pn = raw[raw.SR].groupby(['coded', 'gameID']).auto.mean().reset_index()
print('   per-network share with counts, SR: coded mean %.3f (n=%d), not coded mean %.3f (n=%d)' % (
    pn[pn.coded].auto.mean(), pn.coded.sum(), pn[~pn.coded].auto.mean(), (~pn.coded).sum()))

# (a) Experiment 1
e1 = pd.read_csv(os.path.join(D, 'exp1_messages_raw.csv'), keep_default_na=False)
e1 = e1[e1.src == 'messages'].drop_duplicates(['gameID', 'sender', 'time', 'text'])
e1['cond'] = e1.treatmentName.str.extract(r'rerun-(\w+)')[0]
c1 = pd.read_csv(common.EXP1_CLEAN)
kept = set(zip(c1.gameID, c1.playerID))
e1['analysed'] = [(a, b) in kept for a, b in zip(e1.gameID, e1.sender)]
e1 = e1[e1.cond.isin(['interactive', 'unidirectional'])].copy()
e1['auto'] = e1.text.map(has_counts)
print('\n3. Experiment 1 messages (messaging conditions): share that report counts (automated)')
for lab, d in [('all senders', e1), ('senders in the analysed sample', e1[e1.analysed])]:
    print('  ', lab)
    print(d.groupby('cond').agg(networks=('gameID', 'nunique'), senders=('sender', 'nunique'), messages=('text', 'size'),
                                share_with_counts=('auto', 'mean')).round(3).to_string())
pn1 = e1[e1.analysed].groupby(['cond', 'gameID']).auto.mean().groupby('cond').agg(['mean', 'median', 'size']).round(3)
print('   per-network share (analysed senders):'); print(pn1.to_string())
