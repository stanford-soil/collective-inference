"""Did participants relay counts they had just received, within the same round?

Experiment 1, round 2 (a one-way round). In the real-time condition a participant
could see an incoming message while still writing, and could pass its counts on to
their own recipient. In the delayed condition incoming messages appeared only after
the round, so this was impossible, and that condition gives the rate of chance matches.

For every participant who received a message in round 2 from someone other than
their own recipient, we check whether any of their own round-2 messages states the
sender's counts ("3 rabbits and 2 squirrels"). A participant is only counted when
the sender's sample differs from their own sample and from the samples of their
round-1 partners, so that a match cannot come from another source.

Reads   data/derived/exp1_messages_raw.csv (prep/03_message_logs.py),
        data/exp1/PreregMergedGuesses.csv
Prints  the number and share of participants who relayed, by condition
"""
import re
import sys
import pandas as pd

sys.path.insert(0, '../lib')
import common

NUMBER_WORDS = {'zero': 0, 'no': 0, 'none': 0, 'one': 1, 'a': 1, 'an': 1, 'single': 1, 'two': 2,
                'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
                'ten': 10, 'eleven': 11, 'twelve': 12}
# A number, optionally one word ("brown"), then an animal: "3 rabbits", "one grey squirrel"
COUNT = re.compile(r"(\d+|" + '|'.join(NUMBER_WORDS) + r")\s+(?:\w+\s+)?(rabbit|bunn|bunnie|squir|sq)")


def stated_counts(text):
    """All rabbit counts and all squirrel counts stated in a message."""
    rabbits, squirrels = [], []
    for number, animal in COUNT.findall(str(text).lower()):
        value = int(number) if number.isdigit() else NUMBER_WORDS[number]
        if animal.startswith(('rabbit', 'bunn')):
            rabbits.append(value)
        else:
            squirrels.append(value)
    return rabbits, squirrels


def states_sample(text, sample):
    """True if the message states the nonzero counts of this sample."""
    rabbits, squirrels = stated_counts(text)
    n_rabbits, n_squirrels = sample
    if n_rabbits == 0 and n_squirrels == 0:
        return False
    rabbits_stated = n_rabbits in rabbits if n_rabbits > 0 else True
    squirrels_stated = n_squirrels in squirrels if n_squirrels > 0 else True
    return rabbits_stated and squirrels_stated


messages = pd.read_csv(common.EXP1_MESSAGES)
messages = messages[messages.src == 'messages'].drop_duplicates(['gameID', 'sender', 'time', 'text'])
messages['condition'] = messages.treatmentName.str.extract(r'rerun-(\w+)')[0]

estimates = pd.read_csv(common.EXP1_MERGED)
sample = {key: (int(row.nRabbits), int(row.nSquirrels))
          for key, row in estimates.groupby(['gameID', 'playerID'])[['nRabbits', 'nSquirrels']].first().iterrows()}

rows = []
for game, round_2 in messages[messages['round'] == 2].groupby('gameID'):
    round_1 = messages[(messages.gameID == game) & (messages['round'] == 1)]
    for player, own_messages in round_2.groupby('sender'):
        incoming = round_2[round_2.recipient == player]
        if incoming.empty:
            continue
        sender = incoming.sender.iloc[0]
        if sender == own_messages.recipient.iloc[0]:
            continue                                   # a mutual pair
        if (game, sender) not in sample or (game, player) not in sample:
            continue
        # Samples the participant already knew: their own and their round-1 partners'
        round_1_partners = (set(round_1[round_1.sender == player].recipient) |
                            set(round_1[round_1.recipient == player].sender))
        known_samples = [sample[(game, player)]] + [sample[(game, partner)] for partner in round_1_partners
                                                     if (game, partner) in sample]
        sender_sample = sample[(game, sender)]
        if sender_sample in known_samples or sender_sample == (0, 0):
            continue
        sent_after_receiving = own_messages[own_messages.time > incoming.time.min()]
        rows.append(dict(
            network=game, condition=own_messages.condition.iloc[0],
            relayed=any(states_sample(text, sender_sample) for text in own_messages.text),
            relayed_after_receiving=any(states_sample(text, sender_sample)
                                        for text in sent_after_receiving.text)))

result = pd.DataFrame(rows)
print(result.groupby('condition').agg(
    participants=('relayed', 'size'),
    networks=('network', 'nunique'),
    relayed=('relayed', 'sum'),
    share_relayed=('relayed', 'mean'),
    relayed_after_receiving=('relayed_after_receiving', 'sum')).round(3).to_string())
