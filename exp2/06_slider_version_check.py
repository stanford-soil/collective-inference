"""Experiment 2: accuracy and apparent scale reversals by slider version (SR vs RS)
and condition, for the retained networks. Supports the decision to analyse only the
SR networks in both conditions (manuscript Appendix C).
(1) Mean absolute error by condition and slider version, all rounds with social
    information.
(2) Apparent scale reversals in the first estimate: among participants whose own
    sample proportion is at least 20 points from 50%, the share whose first estimate
    is more than 20 points closer to the complement of their own sample proportion
    than to the proportion itself. In the slider condition the first estimate is made
    before any social information.
Input: data/derived/exp2_clean_data.csv. Output: printed. Run from exp2/."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib'))
import common
import numpy as np, pandas as pd
from scipy.stats import chi2_contingency

x = pd.read_csv(common.EXP2_CLEAN)
t = x['treatmentName.x']
x['condition'] = np.where(t.str.contains('interactive'), 'chat', 'slider')
x['version'] = np.where(t.str.startswith('RS_'), 'RS', 'SR')

# (1) error against the network proportion over active players, aligned to the slider version
act = x[x.guess.notna()].drop_duplicates(['gameID', 'playerID'])
g = act.groupby('gameID').agg(r=('nRabbits', 'sum'), n=('nCritters', 'sum'))
truth = 100 * g.r / g.n
x['truth'] = x.gameID.map(truth)
x['truth'] = np.where(x.version == 'RS', 100 - x.truth, x.truth)
x['error'] = (x.guess - x.truth).abs()
social = x[~((x.condition == 'slider') & (x.idx == 1))]
print('1. Mean absolute error, rounds with social information')
print(social.groupby(['condition', 'version']).agg(networks=('gameID', 'nunique'), mean_error=('error', 'mean')).round(1).to_string())

# (2) first estimates on the apparently wrong end of the scale
first = x[x.guess.notna()].sort_values('idx').groupby('playerID').first().reset_index()
own = 100 * first.nRabbits / first.nCritters
own = np.where(first.version == 'RS', 100 - own, own)
first['own'] = own
first = first[(first.own - 50).abs() >= 20].copy()
first['reversed'] = (first.guess - (100 - first.own)).abs() + 20 < (first.guess - first.own).abs()
print('\n2. First estimates more than 20 points closer to the complement of the own-sample proportion')
print(first.groupby(['condition', 'version']).agg(participants=('reversed', 'size'), reversed=('reversed', 'sum'), share=('reversed', 'mean')).round(3).to_string())
for c in ['chat', 'slider']:
    tab = pd.crosstab(first[first.condition == c].version, first[first.condition == c].reversed)
    chi2, p, _, _ = chi2_contingency(tab)
    print(f'   {c}: chi2(1) = {chi2:.2f}, p = {p:.3f}')
