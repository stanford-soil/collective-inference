"""
Experiment 2 Model Predictions

Uses parameters fitted to Experiment 1 (from models/01_fit.py) to generate predictions
for Experiment 2. Simulates full 8-round belief trajectories.

Models (base models without response weights)
------
- Belief model (α): Simulates slider condition (belief averaging)
- Evidence model (δ, α): Simulates chat condition (evidence pooling)

Simulation
----------
For each Exp2 game:
1. Initialize beliefs at each player's individual MLE
2. Simulate 8 rounds of belief updates with partner interactions
3. Add Gaussian noise N(0, σ) at each round (from fitting residuals)
4. Compute final prediction error vs network MLE

Output
------
- figures/fig7_model_predictions.pdf: predicted final error for unrepresentative and
  representative networks (SR networks, as in the analyses)
- Console: means and effects by representativeness

Usage
-----
  python3 fig7_model_predictions.py   (from figures/; needs a UTF-8 locale)
  Inputs: models/fit_results.csv (models/01_fit.py, corrected timing),
  data/derived/exp2_clean_data.csv (prep/).

This replaces the original models/predict.py. Changes from that script: paths come from
lib/common.py, the games are the SR networks (SUBSET=ALL for all networks), the
figure is written to figures/, and the legend sits below the axes with the revised
condition names and palette. The simulations, parameters and random seed are unchanged.
"""

import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib'))
import common

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# =============================================================================
# LOAD FITTED PARAMETERS FROM models/01_fit.py (base models, no response weights)
# =============================================================================

fit_results = pd.read_csv(common.FIT_RESULTS)

# Base Belief model: slider, degroot, anchor=False (1 param: α)
belief_fit = fit_results[(fit_results['condition'] == 'slider') &
                         (fit_results['model'] == 'degroot') &
                         (fit_results['anchor'] == False)].iloc[0]

# Base Evidence model: chat, count, anchor=False (2 params: δ, α)
evidence_fit = fit_results[(fit_results['condition'] == 'chat') &
                           (fit_results['model'] == 'count') &
                           (fit_results['anchor'] == False)].iloc[0]

BELIEF_ALPHA = belief_fit['alpha']
BELIEF_SIGMA = belief_fit['sigma']

EVIDENCE_DELTA = evidence_fit['delta']
EVIDENCE_ALPHA = evidence_fit['alpha']
EVIDENCE_SIGMA = evidence_fit['sigma']

print("=" * 70)
print("EXPERIMENT 2: MODEL PREDICTIONS (base models)")
print("=" * 70)
print(f"\nLoaded parameters from fit_results.csv:")
print(f"  Belief (Slider):   α={BELIEF_ALPHA:.2f}, σ={BELIEF_SIGMA:.3f}")
print(f"  Evidence (Chat):   δ={EVIDENCE_DELTA:.2f}, α={EVIDENCE_ALPHA:.2f}, σ={EVIDENCE_SIGMA:.3f}")

# =============================================================================
# SETUP
# =============================================================================

plt.rcParams.update({
    'font.family': 'sans-serif',
    'font.size': 11,
    'axes.labelsize': 12,
    'axes.titlesize': 12,
    'xtick.labelsize': 10,
    'ytick.labelsize': 10,
    'legend.fontsize': 10,
    'figure.dpi': 150,
})

EVIDENCE_COLOR = common.CONDITION_COLORS['interactive']
BELIEF_COLOR = common.CONDITION_COLORS['slider']


# =============================================================================
# LOAD AND PREPARE DATA
# =============================================================================

exp2 = pd.read_csv(common.EXP2_CLEAN)

# Derive condition and direction from treatmentName
treat_col = 'treatmentName.x' if 'treatmentName.x' in exp2.columns else 'treatmentName'
exp2['condition'] = exp2[treat_col].apply(lambda x: 'interactive' if 'interactive' in str(x) else 'slider')
exp2['direction'] = exp2[treat_col].apply(lambda x: 'RS' if str(x).startswith('RS_') else 'SR')

exp2 = common.filter_exp2(exp2)   # SR networks by default (lib/common.py)
print(f"Loaded Exp 2: {exp2['gameID'].nunique()} games")

# Get game-level data
game_data = exp2.groupby('gameID').first().reset_index()
game_data = game_data[['gameID', 'condition', 'direction', 'nCrittersGame',
                        'nRabbitsGame', 'entropy', 'representation']]

# Network MLE aligned for direction
game_data['network_mle_raw'] = game_data['nRabbitsGame'] / game_data['nCrittersGame']
game_data['network_mle_aligned'] = np.where(
    game_data['direction'] == 'RS',
    1 - game_data['network_mle_raw'],
    game_data['network_mle_raw']
)

# Representativeness bins (median split)
rep_median = game_data['representation'].median()
game_data['rep_bin'] = np.where(
    game_data['representation'] <= rep_median, 'Representative', 'Unrepresentative'
)


# =============================================================================
# MODEL SIMULATIONS
# =============================================================================
# Both models are simulated on the partner schedule that actually ran (who each
# player received from in each round; partner_schedule/exp2_partners.csv), with the
# timing used in models/01_fit.py:
#   Belief model (slider timing): the first estimate is the player's own-sample
#     proportion; each of the 7 later estimates averages the player's previous
#     estimate with the previous estimate of that round's sender.
#   Evidence model (messaging timing): messages precede the estimate, so each of the
#     8 estimates moves toward the pooled proportion of the player's own sample and
#     the samples of every distinct sender heard up to and including that round.
# Gaussian noise with the fitted residual SD is added at every update. Predicted
# error is the mean absolute error of individual final estimates (the measure used
# for the data). The error of the network's mean estimate without noise, which the
# original submission reported, is printed for comparison.

partners = common.filter_exp2(pd.read_csv(common.EXP2_PARTNERS))
N_SIMS = 1000
rng = np.random.default_rng(42)


def sender_index(game_id, ids):
    """sender[t] = array giving, for each player, the index of the player they received from in round t."""
    idx = {p: i for i, p in enumerate(ids)}
    sender = {}
    for rd, sch in partners[partners.gameID == game_id].groupby('round'):
        a = np.full(len(ids), -1)
        for pid, sid in zip(sch.playerID, sch.partnerID):
            if pid in idx and sid in idx:
                a[idx[pid]] = idx[sid]
        sender[int(rd)] = a
    if any(t not in sender or (sender[t] < 0).any() for t in range(1, 9)):
        return None
    return sender


def simulate_game(game_df, truth):
    players = game_df.drop_duplicates('playerID')
    ids = list(players.playerID)
    r = players.nRabbits.values.astype(float)
    n = players.nCritters.values.astype(float)
    mle = np.where(n > 0, r / np.maximum(n, 1), 0.5)
    sender = sender_index(game_df.gameID.iloc[0], ids)
    if sender is None:
        return None
    out = {}
    for noise in (True, False):
        B = np.tile(mle, (N_SIMS if noise else 1, 1))
        for t in range(1, 8):
            B = BELIEF_ALPHA * B + (1 - BELIEF_ALPHA) * B[:, sender[t]]
            if noise:
                B = np.clip(B + rng.normal(0, BELIEF_SIGMA, B.shape), 0, 1)
        E = np.tile(mle, (N_SIMS if noise else 1, 1))
        heard = [set() for _ in ids]
        for t in range(1, 9):
            for i in range(len(ids)):
                heard[i].add(sender[t][i])
            cum_r = np.array([sum(r[j] for j in heard[i]) for i in range(len(ids))])
            cum_n = np.array([sum(n[j] for j in heard[i]) for i in range(len(ids))])
            pooled = (r + EVIDENCE_DELTA * cum_r) / (n + EVIDENCE_DELTA * cum_n)
            E = EVIDENCE_ALPHA * E + (1 - EVIDENCE_ALPHA) * pooled
            if noise:
                E = np.clip(E + rng.normal(0, EVIDENCE_SIGMA, E.shape), 0, 1)
        tag = '' if noise else '_netmean_nonoise'
        if noise:
            out['belief_error'] = 100 * np.abs(B - truth).mean()
            out['evidence_error'] = 100 * np.abs(E - truth).mean()
        else:
            out['belief_error' + tag] = 100 * abs(B.mean() - truth)
            out['evidence_error' + tag] = 100 * abs(E.mean() - truth)
    return out


# =============================================================================
# COMPUTE PREDICTIONS
# =============================================================================

print("\nComputing model predictions...")
model_errors = []
for _, row in game_data.iterrows():
    game_df = exp2[(exp2['gameID'] == row['gameID']) & (exp2['idx'] == 1)]
    if len(game_df) < 2:
        continue
    o = simulate_game(game_df, row['network_mle_aligned'] if row['direction'] == 'SR' else row['network_mle_raw'])
    if o is None:
        continue
    o.update(gameID=row['gameID'], rep_bin=row['rep_bin'])
    model_errors.append(o)

model_df = pd.DataFrame(model_errors)
print(f"Model predictions: {len(model_df)} games")

# Observed final-round error (individual estimates) for comparison
obs = exp2[exp2['idx'] == 8].merge(game_data[['gameID', 'network_mle_aligned', 'rep_bin']], on='gameID')
obs['error'] = (obs['guess'] - 100 * obs['network_mle_aligned']).abs()
print("\nObserved final-round error by condition (individual estimates):")
print(obs.groupby(['condition', 'rep_bin']).error.agg(['mean', 'size']).round(1).to_string())

# =============================================================================
# COMPUTE AND PRINT RESULTS
# =============================================================================

print("\n" + "=" * 70)
print("PREDICTIONS BY REPRESENTATIVENESS")
print("=" * 70)

for model_name, col in [('Belief', 'belief_error'), ('Evidence', 'evidence_error'),
                        ('Belief, network mean without noise', 'belief_error_netmean_nonoise'),
                        ('Evidence, network mean without noise', 'evidence_error_netmean_nonoise')]:
    rep = model_df[model_df['rep_bin'] == 'Representative'][col]
    unrep = model_df[model_df['rep_bin'] == 'Unrepresentative'][col]
    print(f"\n{model_name} model:")
    print(f"  Representative:   {rep.mean():.1f} (SD={rep.std():.1f})")
    print(f"  Unrepresentative: {unrep.mean():.1f} (SD={unrep.std():.1f})")
    print(f"  Effect:           {unrep.mean() - rep.mean():.1f}")


# =============================================================================
# CREATE FIGURE (matching Figure 5B layout)
# =============================================================================

print("\nCreating figure...")

fig, ax = plt.subplots(figsize=(4.5, 4))

x = np.array([0, 1])
# Unrepresentative on left, Representative on right (matching Fig 5B)
labels = ['Unrepresentative', 'Representative']

# Compute means and bootstrap CIs
def bootstrap_ci(values, n_boot=1000, seed=42):
    np.random.seed(seed)
    means = [np.mean(np.random.choice(values, size=len(values), replace=True))
             for _ in range(n_boot)]
    return np.percentile(means, [2.5, 97.5])

belief_means = []
belief_cis = []
evidence_means = []
evidence_cis = []

for rep_level in labels:
    b_vals = model_df[model_df['rep_bin'] == rep_level]['belief_error'].values
    e_vals = model_df[model_df['rep_bin'] == rep_level]['evidence_error'].values

    belief_means.append(np.mean(b_vals))
    belief_cis.append(bootstrap_ci(b_vals))
    evidence_means.append(np.mean(e_vals))
    evidence_cis.append(bootstrap_ci(e_vals))

# Error bars
belief_errs = [[belief_means[i] - belief_cis[i][0] for i in range(2)],
               [belief_cis[i][1] - belief_means[i] for i in range(2)]]
evidence_errs = [[evidence_means[i] - evidence_cis[i][0] for i in range(2)],
                 [evidence_cis[i][1] - evidence_means[i] for i in range(2)]]

# Connected lines with error bars (matching Fig 5B style)
ax.errorbar(x, evidence_means, yerr=evidence_errs,
            color=EVIDENCE_COLOR, marker='o', markersize=8, linewidth=2, capsize=3,
            label='Evidence model: ' + common.CONDITION_LABELS['interactive'])
ax.errorbar(x, belief_means, yerr=belief_errs,
            color=BELIEF_COLOR, marker='o', markersize=8, linewidth=2, capsize=3,
            label='Belief model: ' + common.CONDITION_LABELS['slider'])

ax.set_xticks(x)
ax.set_xticklabels(labels, rotation=30, ha='right')
ax.set_ylabel('Predicted error (final round)')
ax.set_title('Representativeness')
ax.set_xlim(-0.4, 1.4)
ax.set_ylim(0, None)
ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.38), frameon=False)  # below axes (revision)

plt.tight_layout()
plt.savefig(os.path.join(common.FIGURES, 'fig7_model_predictions.pdf'), bbox_inches='tight')
print("Saved fig7_model_predictions.pdf")
