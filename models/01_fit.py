"""Belief and Evidence models of how participants updated their estimates (Experiment 1).

Both models predict a participant's next estimate from their current estimate and
the social information they received in between.

    Belief model (DeGroot averaging): move toward the sender's estimate.
        next = alpha * own_estimate + (1 - alpha) * sender_estimate

    Evidence model (count pooling): move toward the proportion of rabbits in the
    participant's own sample pooled with the samples of everyone heard so far,
    with others' samples discounted by delta.
        pooled = (own_rabbits + delta * heard_rabbits) / (own_total + delta * heard_total)
        next   = alpha * own_estimate + (1 - alpha) * pooled

Each model is also fitted with three response weights (Appendix B):
        response = w_update * next + w_mle * own_sample_proportion + w_mid * 0.5

The models are fitted by least squares to every pair of consecutive estimates and
compared by AIC. Estimates and proportions are on a 0-1 scale.

Timing of the social information. In the slider condition the estimate in round
t+1 follows the estimate the sender submitted in round t. In the messaging
conditions the messages come before the estimate within a round, so the estimate
in round t+1 follows the messages of the round-(t+1) sender. The original
submission paired messaging updates with the round-t sender; this is corrected
here ("corrected" timing). Three further variants show that the model comparison
does not depend on the details (see TIMINGS below).

Reads   data/derived/exp1_clean_data.csv
        data/exp1/raw/1_extracted_msgs_prereg/extracted_messages.csv   who sent to whom
        partner_schedule/exp1_partners.csv                             (one variant only)
Writes  fit_results.csv   every fit: parameters, error and AIC
Prints  the AIC table, the fitted parameters and the AIC differences for every variant
"""
import itertools
import sys
import numpy as np
import pandas as pd
from scipy.optimize import minimize

sys.path.insert(0, '../lib')
import common

# Timing variants: (name, conditions fitted, description)
TIMINGS = [
    ('corrected', ['slider', 'interactive', 'unidirectional'],
     'reported in the paper'),
    ('original', ['slider', 'interactive', 'unidirectional'],
     'as in the original submission: messaging updates paired with the previous round\'s sender'),
    ('sender_only', ['slider', 'interactive'],
     'corrected sender, but evidence accumulated as in the original code'),
    ('same_round_estimate', ['slider', 'interactive'],
     'corrected, with the sender\'s estimate from the same round instead of the previous one'),
    ('schedule', ['slider', 'interactive'],
     'corrected, with senders taken from the reconstructed schedule instead of the message log'),
]


# =============================================================================================
# The two models
# =============================================================================================

def belief_model(data, alpha, w_update=1.0, w_mle=0.0, w_mid=0.0):
    step = alpha * data['own_estimate'] + (1 - alpha) * data['sender_estimate']
    return w_update * step + w_mle * data['own_proportion'] + w_mid * 0.5


def evidence_model(data, delta, alpha, w_update=1.0, w_mle=0.0, w_mid=0.0):
    own_total = data['own_rabbits'] + data['own_squirrels']
    heard_total = data['heard_rabbits'] + data['heard_squirrels']
    pooled_rabbits = data['own_rabbits'] + delta * data['heard_rabbits']
    pooled_total = own_total + delta * heard_total
    pooled = np.where(pooled_total > 0, pooled_rabbits / np.where(pooled_total > 0, pooled_total, 1), 0.5)
    step = alpha * data['own_estimate'] + (1 - alpha) * pooled
    return w_update * step + w_mle * data['own_proportion'] + w_mid * 0.5


# Free parameters of each model, with bounds and the starting values tried.
ALPHA = dict(bounds=(0.01, 0.99))
DELTA = dict(bounds=(0.01, 2.0))
RESPONSE_WEIGHTS = [dict(bounds=(-2.0, 2.0), starts=[0.5, 0.7, 0.9]),    # w_update
                    dict(bounds=(-1.0, 1.0), starts=[0.0, 0.1, 0.2]),    # w_mle
                    dict(bounds=(-1.0, 2.0), starts=[0.0, 0.1, 0.3])]    # w_mid
MODELS = {
    'belief':   dict(predict=belief_model, names=['alpha'],
                     parameters=[dict(ALPHA, starts=[0.6, 0.75, 0.85])]),
    'evidence': dict(predict=evidence_model, names=['delta', 'alpha'],
                     parameters=[dict(DELTA, starts=[0.3, 0.5, 0.7]), dict(ALPHA, starts=[0.3, 0.5, 0.7])]),
}


def fit(model_name, data, response_weights):
    """Least-squares fit from a grid of starting values. Returns the parameters and the mean squared error."""
    model = MODELS[model_name]
    parameters = model['parameters'] + (RESPONSE_WEIGHTS if response_weights else [])
    names = model['names'] + (['w_update', 'w_mle', 'w_mid'] if response_weights else [])

    def mean_squared_error(values):
        return np.mean((model['predict'](data, *values) - data['next_estimate']) ** 2)

    best = None
    for start in itertools.product(*[parameter['starts'] for parameter in parameters]):
        result = minimize(mean_squared_error, x0=list(start), method='L-BFGS-B',
                          bounds=[parameter['bounds'] for parameter in parameters])
        if best is None or result.fun < best.fun:
            best = result
    return dict(zip(names, best.x)), best.fun


def aic(mse, n, k):
    """AIC of a least-squares fit with Gaussian errors."""
    log_likelihood = -n / 2 * np.log(2 * np.pi) - n * np.log(np.sqrt(mse)) - n / 2
    return 2 * k - 2 * log_likelihood


# =============================================================================================
# Data: one row per pair of consecutive estimates
# =============================================================================================

def load_senders(source):
    """{(network, participant, round): the participant they received from}"""
    if source == 'schedule':
        schedule = pd.read_csv(common.EXP1_PARTNERS).dropna(subset=['partnerID'])
        return {(game, player, int(round_number)): sender for game, player, round_number, sender
                in zip(schedule.gameID, schedule.playerID, schedule['round'], schedule.partnerID)}
    log = pd.read_csv(common.EXP1_EXTRACTED_MSGS).dropna(subset=['round', 'recipient', 'sender.id', 'groupID'])
    senders = {}
    for game, recipient, round_number, sender in zip(log.groupID, log.recipient, log['round'], log['sender.id']):
        senders.setdefault((game, recipient, int(round_number)), sender)
    return senders


def transitions(estimates, senders, condition, timing):
    messaging = condition != 'slider'
    use_same_round_sender = messaging and timing != 'original'
    accumulate_from_round_1 = messaging and timing in ('corrected', 'same_round_estimate', 'schedule')
    use_same_round_estimate = messaging and timing == 'same_round_estimate'

    estimates = estimates[estimates.condition == condition]
    sample = {(row.gameID, row.playerID): (int(row.nRabbits), int(row.nSquirrels))
              for row in estimates.drop_duplicates(['gameID', 'playerID']).itertuples()}
    rows = []
    for game, game_estimates in estimates.groupby('gameID', sort=False):
        estimate_of = {(player, int(round_number)): estimate for player, round_number, estimate
                       in zip(game_estimates.playerID, game_estimates.idx, game_estimates.estimate)}
        for player, own in game_estimates.groupby('playerID', sort=False):
            own = own.sort_values('idx')
            rounds, own_estimates = own.idx.values, own.estimate.values
            own_rabbits, own_squirrels = sample[(game, player)]
            own_total = own_rabbits + own_squirrels

            # Evidence heard so far: the samples of every distinct sender up to each round.
            heard_by_round, heard, heard_rabbits, heard_squirrels = {}, set(), 0, 0
            for round_number in range(1, 13):
                sender = senders.get((game, player, round_number))
                if sender is not None and sender not in heard and (game, sender) in sample:
                    heard.add(sender)
                    heard_rabbits += sample[(game, sender)][0]
                    heard_squirrels += sample[(game, sender)][1]
                heard_by_round[round_number] = (heard_rabbits, heard_squirrels)
            heard, heard_rabbits, heard_squirrels = set(), 0, 0     # running total for the other variants

            for position in range(len(rounds) - 1):
                round_number = int(rounds[position])
                sender_round = round_number + 1 if use_same_round_sender else round_number
                estimate_round = round_number + 1 if use_same_round_estimate else round_number
                sender = senders.get((game, player, sender_round))
                if sender is None or (game, sender) not in sample or (sender, estimate_round) not in estimate_of:
                    continue
                if accumulate_from_round_1:
                    heard_rabbits, heard_squirrels = heard_by_round[sender_round]
                elif sender not in heard:
                    heard.add(sender)
                    heard_rabbits += sample[(game, sender)][0]
                    heard_squirrels += sample[(game, sender)][1]
                rows.append(dict(
                    own_estimate=own_estimates[position], next_estimate=own_estimates[position + 1],
                    own_rabbits=own_rabbits, own_squirrels=own_squirrels,
                    own_proportion=own_rabbits / own_total if own_total > 0 else 0.5,
                    sender_estimate=estimate_of[(sender, estimate_round)],
                    heard_rabbits=heard_rabbits, heard_squirrels=heard_squirrels))
    return {column: values.values.astype(float) for column, values in pd.DataFrame(rows).items()}


# =============================================================================================
# Fit every model in every condition and timing variant
# =============================================================================================

estimates = pd.read_csv(common.EXP1_CLEAN)
estimates['estimate'] = estimates.guess / 100.0

fits = []
for timing, conditions, _ in TIMINGS:
    senders = load_senders('schedule' if timing == 'schedule' else 'message log')
    for condition in conditions:
        data = transitions(estimates, senders, condition, timing)
        n = len(data['next_estimate'])
        for model_name in MODELS:
            for response_weights in [False, True]:
                parameters, mse = fit(model_name, data, response_weights)
                k = len(parameters)
                fits.append(dict(timing=timing, condition=condition, model=model_name,
                                 response_weights=response_weights, n=n, k=k, mse=mse,
                                 sigma=np.sqrt(mse), aic=aic(mse, n, k), **parameters))
fits = pd.DataFrame(fits)
fits.to_csv(common.FIT_RESULTS, index=False)

# ---- Report ------------------------------------------------------------------------------
pd.set_option('display.width', 200)
reported = fits[fits.timing == 'corrected']
print('AIC by model and condition (corrected timing; lower is better)')
print(reported.pivot_table(index=['model', 'response_weights', 'k'], columns='condition', values='aic')
      .round(1).to_string())
print('\nFitted parameters (corrected timing)')
print(reported[['condition', 'model', 'response_weights', 'n', 'alpha', 'delta', 'w_update', 'w_mle', 'w_mid', 'sigma']]
      .round(3).to_string(index=False))

# AIC difference, Evidence minus Belief: negative favours the Evidence model.
aic_table = fits.pivot_table(index=['timing', 'condition', 'response_weights'], columns='model', values='aic', sort=False)
aic_table['evidence_minus_belief'] = aic_table.evidence - aic_table.belief
print('\nAIC difference (Evidence - Belief) for every timing variant')
for timing, _, description in TIMINGS:
    print(f'  {timing}: {description}')
print(aic_table.round(1).to_string())
