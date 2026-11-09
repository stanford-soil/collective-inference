"""Over-counting in relayed counts (Experiment 2 chat, SR networks by default).
For every message whose final code includes sn (counts attributed to other players
or to the group), extract the stated numbers of rabbits and squirrels and compare
them with the true number of each animal seen by all four members of the network.
A stated count above the network's true total cannot be an accurate tally, so it
indicates double counting or a misreport somewhere along the way. This is a lower
bound: a tally can double count evidence without exceeding the network total.
Fractions ("21/28 are rabbits", "8 out of 30") and pairs that sum to 100 (percentages)
are not treated as counts. Set SUBSET=ALL for all coded chat networks.
Inputs: coding/exp2_message_codes_final.csv, data/derived/exp2_clean_data.csv.
Output: exp2_relayed_overcounts.csv (flagged messages) and printed summary. Run from coding/."""
import os, sys, re
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib'))
import common
import pandas as pd

W = {'zero': 0, 'no': 0, 'none': 0, 'one': 1, 'a': 1, 'an': 1, 'single': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
     'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11, 'twelve': 12}
PAT = re.compile(r"(?<![/\d])\b(\d+|zero|no|none|one|a|an|single|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\s+(?:\w+\s+)?(rab|bunn|squ|sq)", re.I)
FRACTION = re.compile(r"\d+\s*/\s*\d+|\bout of\s+\d+", re.I)

fin = pd.read_csv(common.repo_path('coding', 'exp2_message_codes_final.csv'), keep_default_na=False)
fin = common.filter_exp2(fin)
x = pd.read_csv(common.EXP2_CLEAN)
tot = x.drop_duplicates(['gameID', 'playerID']).groupby('gameID')[['nRabbits', 'nSquirrels']].sum()

sn = fin[fin.code_final.str.contains('sn')]
rows = []
for _, m in sn.iterrows():
    text = FRACTION.sub(' ', m.text.lower())
    R, S = [], []
    for n, k in PAT.findall(text):
        v = int(n) if n.isdigit() else W[n]
        (R if k.startswith(('rab', 'bunn')) else S).append(v)
    if not R and not S:
        continue
    r, s = max(R, default=0), max(S, default=0)
    if R and S and r + s == 100:
        continue
    t = tot.loc[m.gameID]
    rows.append(dict(gameID=m.gameID, round=m['round'], sender=m['sender.id'], text=m.text, stated_rabbits=r, stated_squirrels=s,
                     network_rabbits=int(t.nRabbits), network_squirrels=int(t.nSquirrels),
                     excess=max(r - int(t.nRabbits), s - int(t.nSquirrels))))
r = pd.DataFrame(rows)
r['over'] = r.excess > 0
print('Networks:', common.exp2_subset())
print('messages with relayed counts (sn):', len(sn), 'in', sn.gameID.nunique(), 'networks; with parsed counts:', len(r), 'in', r.gameID.nunique(), 'networks')
print('messages stating a count above the network total:', int(r.over.sum()), '(%.1f%%)' % (100 * r.over.mean()),
      '| by more than one:', int((r.excess > 1).sum()))
g = r.groupby('gameID').excess.max()
print('networks with at least one such message:', int((g > 0).sum()), 'of', len(g), '| by more than one:', int((g > 1).sum()))
print('senders with at least one such message:', r[r.over].sender.nunique(), 'of', r.sender.nunique())
r[r.over].drop(columns='over').to_csv('exp2_relayed_overcounts.csv', index=False)
# How far the stated proportion of rabbits is from the network's true proportion,
# for messages that state both counts
b = r[(r.stated_rabbits + r.stated_squirrels > 0) & (r.stated_rabbits > 0) & (r.stated_squirrels > 0)].copy()
b['dev'] = (100 * (b.stated_rabbits / (b.stated_rabbits + b.stated_squirrels) - b.network_rabbits / (b.network_rabbits + b.network_squirrels))).abs()
print('absolute deviation of stated from true proportion (points), messages stating both counts:')
print(b.groupby('over').dev.agg(['size', 'mean', 'median']).round(1).to_string())
pd.set_option('display.width', 250); pd.set_option('display.max_colwidth', 100)
print(r[r.over][['round', 'text', 'stated_rabbits', 'stated_squirrels', 'network_rabbits', 'network_squirrels']].to_string(index=False))
