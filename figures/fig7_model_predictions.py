"""Figure 7: what the two models, fitted to Experiment 1, predict for Experiment 2.

Each analysed Experiment 2 network is simulated 1,000 times with each model, using
the parameters fitted to Experiment 1 (models/fit_results.csv) and the partner
schedule that actually ran (partner_schedule/exp2_partners.csv).

    Belief model (slider timing): the first estimate is the participant's own
    sample proportion; each of the 7 later estimates averages the participant's
    previous estimate with the previous estimate of that round's sender.

    Evidence model (messaging timing): messages come before the estimate, so each
    of the 8 estimates moves toward the pooled proportion of the participant's own
    sample and the samples of every sender heard so far.

Gaussian noise with the fitted residual SD is added at every update. The predicted
error is the mean absolute error of the individual final estimates, the same
measure as for the data.

Reads   models/fit_results.csv, data/derived/exp2_clean_data.csv, partner_schedule/exp2_partners.csv
Writes  figures/fig7_model_predictions.pdf
Prints  predicted and observed final-round error by representativeness
"""
import sys
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

sys.path.insert(0, '../lib')
import common

N_SIMULATIONS = 1000
rng = np.random.default_rng(42)

# ---- Parameters fitted to Experiment 1 (models without response weights) -----------------
fits = pd.read_csv(common.FIT_RESULTS)
fits = fits[(fits.timing == 'corrected') & ~fits.response_weights]
belief = fits[(fits.condition == 'slider') & (fits.model == 'belief')].iloc[0]
evidence = fits[(fits.condition == 'interactive') & (fits.model == 'evidence')].iloc[0]
print(f'Belief model:   alpha = {belief.alpha:.2f}, noise SD = {belief.sigma:.3f}')
print(f'Evidence model: delta = {evidence.delta:.2f}, alpha = {evidence.alpha:.2f}, noise SD = {evidence.sigma:.3f}')

# ---- Experiment 2 networks ------------------------------------------------------------------
data = common.keep_sr(pd.read_csv(common.EXP2_CLEAN))
data['condition'] = np.where(data['treatmentName.x'].str.contains('interactive'), 'interactive', 'slider')
schedule = common.keep_sr(pd.read_csv(common.EXP2_PARTNERS))

networks = data.groupby('gameID').first().reset_index()[['gameID', 'nCrittersGame', 'nRabbitsGame', 'representation']]
networks['truth'] = networks.nRabbitsGame / networks.nCrittersGame
# Median split on representativeness (a lower value means more representative samples)
networks['rep_bin'] = np.where(networks.representation <= networks.representation.median(),
                               'Representative', 'Unrepresentative')


# ---- Simulation ------------------------------------------------------------------------------
def senders_by_round(game_id, player_ids):
    """For each round, the index of the player each player received from."""
    index_of = {player: index for index, player in enumerate(player_ids)}
    senders = {}
    for round_number, round_schedule in schedule[schedule.gameID == game_id].groupby('round'):
        senders[int(round_number)] = np.array([index_of[sender] for sender in
                                               round_schedule.set_index('playerID').partnerID[player_ids]])
    return senders


def simulate(rabbits, critters, senders, noise):
    """Final estimates of every player under each model: arrays of shape (simulations, players)."""
    n_players = len(rabbits)
    own_proportion = np.where(critters > 0, rabbits / np.maximum(critters, 1), 0.5)
    start = np.tile(own_proportion, (N_SIMULATIONS if noise else 1, 1))

    estimates = start.copy()
    for round_number in range(1, 8):
        estimates = belief.alpha * estimates + (1 - belief.alpha) * estimates[:, senders[round_number]]
        if noise:
            estimates = np.clip(estimates + rng.normal(0, belief.sigma, estimates.shape), 0, 1)
    belief_final = estimates

    estimates = start.copy()
    heard = [set() for _ in range(n_players)]
    for round_number in range(1, 9):
        for player in range(n_players):
            heard[player].add(senders[round_number][player])
        heard_rabbits = np.array([sum(rabbits[other] for other in heard[player]) for player in range(n_players)])
        heard_critters = np.array([sum(critters[other] for other in heard[player]) for player in range(n_players)])
        pooled = (rabbits + evidence.delta * heard_rabbits) / (critters + evidence.delta * heard_critters)
        estimates = evidence.alpha * estimates + (1 - evidence.alpha) * pooled
        if noise:
            estimates = np.clip(estimates + rng.normal(0, evidence.sigma, estimates.shape), 0, 1)
    return belief_final, estimates


first_round = data[data.idx == 1].drop_duplicates(['gameID', 'playerID'])
predictions = []
for network in networks.itertuples():
    players = first_round[first_round.gameID == network.gameID]
    rabbits = players.nRabbits.values.astype(float)
    critters = players.nCritters.values.astype(float)
    senders = senders_by_round(network.gameID, list(players.playerID))

    belief_final, evidence_final = simulate(rabbits, critters, senders, noise=True)
    belief_exact, evidence_exact = simulate(rabbits, critters, senders, noise=False)
    predictions.append(dict(
        gameID=network.gameID, rep_bin=network.rep_bin,
        belief_error=100 * np.abs(belief_final - network.truth).mean(),
        evidence_error=100 * np.abs(evidence_final - network.truth).mean(),
        # The measure of the original submission: error of the network's mean estimate, without noise
        belief_error_network_mean=100 * abs(belief_exact.mean() - network.truth),
        evidence_error_network_mean=100 * abs(evidence_exact.mean() - network.truth)))
predictions = pd.DataFrame(predictions)

print('\nPredicted final-round error (mean over', len(predictions), 'networks)')
print(predictions.groupby('rep_bin')[['belief_error', 'evidence_error',
                                      'belief_error_network_mean', 'evidence_error_network_mean']]
      .mean().round(1).T.to_string())

observed = data[data.idx == 8].merge(networks[['gameID', 'truth', 'rep_bin']], on='gameID')
observed['error'] = (observed.guess - 100 * observed.truth).abs()
print('\nObserved final-round error')
print(observed.groupby(['condition', 'rep_bin']).error.mean().round(1).to_string())


# ---- Figure ------------------------------------------------------------------------------------
def bootstrap_ci(values, n_boot=1000, seed=42):
    np.random.seed(seed)
    means = [np.mean(np.random.choice(values, size=len(values), replace=True)) for _ in range(n_boot)]
    return np.percentile(means, [2.5, 97.5])


plt.rcParams.update({'font.family': 'sans-serif', 'font.size': 11, 'axes.labelsize': 12, 'axes.titlesize': 12,
                     'xtick.labelsize': 10, 'ytick.labelsize': 10, 'legend.fontsize': 10, 'figure.dpi': 150})
fig, ax = plt.subplots(figsize=(4.5, 4))
bins = ['Unrepresentative', 'Representative']
lines = [('evidence_error', 'interactive', 'Evidence model: '), ('belief_error', 'slider', 'Belief model: ')]
for column, condition, label in lines:
    by_bin = [predictions[predictions.rep_bin == rep_bin][column].values for rep_bin in bins]
    means = [values.mean() for values in by_bin]
    intervals = [bootstrap_ci(values) for values in by_bin]
    ax.errorbar([0, 1], means,
                yerr=[[mean - low for mean, (low, high) in zip(means, intervals)],
                      [high - mean for mean, (low, high) in zip(means, intervals)]],
                color=common.CONDITION_COLORS[condition], marker='o', markersize=8, linewidth=2, capsize=3,
                label=label + common.CONDITION_LABELS[condition])
ax.set_xticks([0, 1])
ax.set_xticklabels(bins, rotation=30, ha='right')
ax.set_ylabel('Predicted error (final round)')
ax.set_title('Representativeness')
ax.set_xlim(-0.4, 1.4)
ax.set_ylim(0, None)
ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.38), frameon=False)
plt.tight_layout()
plt.savefig(f'{common.FIGURES}/fig7_model_predictions.pdf', bbox_inches='tight')
print('\nSaved fig7_model_predictions.pdf')
