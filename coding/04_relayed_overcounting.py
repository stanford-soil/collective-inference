"""Over-counting in relayed counts (Experiment 2 chat, analysed networks).

When participants pass on counts they heard from others, the same animals can be
counted twice. For every message whose final code includes sn (counts attributed to
other players or to the group), we extract the stated numbers of rabbits and
squirrels and compare them with the numbers seen by all four members of the
network together. A stated count above the network total cannot be an accurate
tally. This is a lower bound: a tally can count evidence twice without exceeding
the network total.

Fractions ("21/28 are rabbits", "8 out of 30") and pairs that sum to 100
(percentages) are not treated as counts.

Reads   coding/exp2_message_codes_final.csv, data/derived/exp2_clean_data.csv
Writes  exp2_relayed_overcounts.csv (the messages stating a count above the network total)
Prints  how many messages and networks are affected
"""
import re
import sys
import pandas as pd

sys.path.insert(0, '../lib')
import common

NUMBER_WORDS = {'zero': 0, 'no': 0, 'none': 0, 'one': 1, 'a': 1, 'an': 1, 'single': 1, 'two': 2,
                'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
                'ten': 10, 'eleven': 11, 'twelve': 12}
# A number, optionally one word, then an animal: "27 rabbits", "one grey squirrel"
COUNT = re.compile(r"(?<![/\d])\b(\d+|" + '|'.join(NUMBER_WORDS) + r")\s+(?:\w+\s+)?(rab|bunn|squ|sq)", re.I)
FRACTION = re.compile(r"\d+\s*/\s*\d+|\bout of\s+\d+", re.I)

codes = common.keep_sr(pd.read_csv(common.EXP2_FINAL_CODES, keep_default_na=False))
relayed = codes[codes.code_final.str.contains('sn')]

# What the whole network saw
samples = pd.read_csv(common.EXP2_CLEAN).drop_duplicates(['gameID', 'playerID'])
network_total = samples.groupby('gameID')[['nRabbits', 'nSquirrels']].sum()

rows = []
for _, message in relayed.iterrows():
    text = FRACTION.sub(' ', message.text.lower())
    rabbit_counts, squirrel_counts = [], []
    for number, animal in COUNT.findall(text):
        value = int(number) if number.isdigit() else NUMBER_WORDS[number]
        if animal.startswith(('rab', 'bunn')):
            rabbit_counts.append(value)
        else:
            squirrel_counts.append(value)
    if not rabbit_counts and not squirrel_counts:
        continue
    rabbits = max(rabbit_counts, default=0)
    squirrels = max(squirrel_counts, default=0)
    if rabbit_counts and squirrel_counts and rabbits + squirrels == 100:
        continue                                           # percentages, not counts
    total = network_total.loc[message.gameID]
    rows.append(dict(
        gameID=message.gameID, round=message['round'], sender=message['sender.id'], text=message.text,
        stated_rabbits=rabbits, stated_squirrels=squirrels,
        network_rabbits=int(total.nRabbits), network_squirrels=int(total.nSquirrels),
        excess=max(rabbits - int(total.nRabbits), squirrels - int(total.nSquirrels))))
counts = pd.DataFrame(rows)
over = counts[counts.excess > 0]
worst_per_network = counts.groupby('gameID').excess.max()

print('messages with relayed counts (sn):', len(relayed), 'in', relayed.gameID.nunique(), 'networks')
print('  with counts that could be extracted:', len(counts), 'in', counts.gameID.nunique(), 'networks')
print(f'messages stating a count above the network total: {len(over)} ({100 * len(over) / len(counts):.1f}%)')
print('networks with at least one such message:', int((worst_per_network > 0).sum()), 'of', len(worst_per_network),
      '| above the total by more than one:', int((worst_per_network > 1).sum()))

# Is the stated proportion of rabbits further from the truth when the counts are too high?
both = counts[(counts.stated_rabbits > 0) & (counts.stated_squirrels > 0)].copy()
stated = both.stated_rabbits / (both.stated_rabbits + both.stated_squirrels)
true = both.network_rabbits / (both.network_rabbits + both.network_squirrels)
both['deviation'] = (100 * (stated - true)).abs()
both['above_network_total'] = both.excess > 0
print('\nDistance of the stated proportion from the network proportion (points), messages stating both counts:')
print(both.groupby('above_network_total').deviation.agg(['size', 'mean']).round(1).to_string())

over.to_csv('exp2_relayed_overcounts.csv', index=False)
