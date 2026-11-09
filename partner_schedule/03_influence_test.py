"""Did estimates move toward the person the schedule says each participant heard from?

Experiment 2, chat condition, round 2. Round 2 is the first one-way round: each
participant receives from one new person (the sender) and sends to a different new
person (the recipient). We regress the change in the participant's estimate from
round 1 to round 2 on

    toward_sender      sender's sample proportion    minus the round-1 estimate
    toward_recipient   recipient's sample proportion minus the round-1 estimate

with standard errors clustered by network. If the reconstructed schedule is right,
estimates should move toward the sender's sample and not the recipient's.

Reads   data/exp2/coded_messages.csv, data/derived/exp2_clean_data.csv, exp2_partners.csv
Prints  the regression table
"""
import sys
import pandas as pd
import statsmodels.formula.api as smf

sys.path.insert(0, '../lib')
import common

coded = common.keep_sr(pd.read_csv(common.EXP2_CODED_MSGS))
estimates = common.keep_sr(pd.read_csv(common.EXP2_CLEAN)).dropna(subset=['guess'])
schedule = common.keep_sr(pd.read_csv(common.EXP2_PARTNERS))

# Sample proportion (percentage of rabbits) of every participant who sent a coded message
sample = coded.groupby(['gameID', 'sender.id'])['mleEstimate.x'].first() * 100
# Estimate of every participant in every round
estimate = estimates.groupby(['gameID', 'playerID', 'idx']).guess.last()

rows = []
round_2 = schedule[(schedule['round'] == 2) & (~schedule.reciprocal)]
for _, row in round_2.iterrows():
    before = (row.gameID, row.playerID, 1)
    after = (row.gameID, row.playerID, 2)
    sender = (row.gameID, row.partnerID)
    recipient = (row.gameID, row.recipientID)
    if before not in estimate.index or after not in estimate.index:
        continue
    if sender not in sample.index or recipient not in sample.index:
        continue
    rows.append(dict(
        network=row.gameID,
        change=estimate[after] - estimate[before],
        toward_sender=sample[sender] - estimate[before],
        toward_recipient=sample[recipient] - estimate[before]))
data = pd.DataFrame(rows)

model = smf.ols('change ~ toward_sender + toward_recipient', data).fit(
    cov_type='cluster', cov_kwds={'groups': data.network.astype('category').cat.codes})
print('participants:', len(data), '| networks:', data.network.nunique())
print(model.summary().tables[1])
