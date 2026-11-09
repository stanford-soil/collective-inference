"""Why only the networks with the "SR" slider version are analysed (Appendix C).

In the "RS" version the slider measured the proportion of squirrels, but the
message generated from it reported the value as a proportion of rabbits. This
script compares the two versions, within each condition, on

1. mean absolute error over the rounds with social information, and
2. apparent scale reversals in the first estimate: among participants whose own
   sample proportion is at least 20 points from 50%, the share whose first estimate
   is more than 20 points closer to the complement of their sample proportion than
   to the proportion itself.

Reads   data/derived/exp2_clean_data.csv (all retained networks)
Prints  both comparisons
"""
import sys
import numpy as np
import pandas as pd
from scipy.stats import chi2_contingency

sys.path.insert(0, '../lib')
import common

data = pd.read_csv(common.EXP2_CLEAN)
treatment = data['treatmentName.x']
data['condition'] = np.where(treatment.str.contains('interactive'), 'chat', 'slider')
data['version'] = np.where(treatment.str.startswith('RS_'), 'RS', 'SR')

# ---- 1. Error by condition and slider version --------------------------------------------
# The target is the percentage of rabbits in the combined sample of the active
# participants; RS estimates are percentages of squirrels, so the target is inverted.
active = data[data.guess.notna()].drop_duplicates(['gameID', 'playerID'])
network_total = active.groupby('gameID').agg(rabbits=('nRabbits', 'sum'), critters=('nCritters', 'sum'))
target = data.gameID.map(100 * network_total.rabbits / network_total.critters)
data['target'] = np.where(data.version == 'RS', 100 - target, target)
data['error'] = (data.guess - data.target).abs()

# The slider condition's first estimate is made before any social information.
social_rounds = data[~((data.condition == 'slider') & (data.idx == 1))]
print('1. Mean absolute error, rounds with social information')
print(social_rounds.groupby(['condition', 'version']).agg(
    networks=('gameID', 'nunique'), mean_error=('error', 'mean')).round(1).to_string())

# ---- 2. First estimates on the apparently wrong end of the scale -------------------------
first = data[data.guess.notna()].sort_values('idx').groupby('playerID').first().reset_index()
own = 100 * first.nRabbits / first.nCritters
first['own'] = np.where(first.version == 'RS', 100 - own, own)
first = first[(first.own - 50).abs() >= 20].copy()
distance_to_own = (first.guess - first.own).abs()
distance_to_complement = (first.guess - (100 - first.own)).abs()
first['reversed'] = distance_to_complement + 20 < distance_to_own

print('\n2. First estimates more than 20 points closer to the complement of the own-sample proportion')
print(first.groupby(['condition', 'version']).agg(
    participants=('reversed', 'size'), reversed=('reversed', 'sum'), share=('reversed', 'mean')).round(3).to_string())
for condition in ['chat', 'slider']:
    in_condition = first[first.condition == condition]
    chi2, p, _, _ = chi2_contingency(pd.crosstab(in_condition.version, in_condition.reversed))
    print(f'   {condition}, RS vs SR: chi2(1) = {chi2:.2f}, p = {p:.3f}')
