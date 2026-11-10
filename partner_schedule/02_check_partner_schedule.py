"""Checks the reconstructed partner schedule against the logged messages.

1. What the recipient rule produces for each network size: in which rounds every
   player receives from exactly one other player, and in which rounds all pairs are
   mutual.
2. Experiment 1: the recipient logged with every message agrees with the schedule;
   pairs exchanged messages in both directions only in the mutual rounds.
3. Experiment 2: the same agreement for the coded messages and the raw chat log.

Reads   data/derived/exp1_partners.csv, exp2_partners.csv (01_build_partner_tables.py),
        data/derived/exp1_messages_raw.csv, exp2_chat_raw.csv (prep/03_message_logs.py),
        data/exp1/PreregMergedGuesses.csv, data/exp1/raw/1_extracted_msgs_prereg/,
        data/exp2/coded_messages.csv
Prints  the checks
"""
import sys
import pandas as pd

sys.path.insert(0, '../lib')
import common

pd.set_option('display.width', 200)


# ---- 1. What the rule produces ---------------------------------------------------------
def recipients(n_players, round_number):
    """Who each player sends to in this round: {sender index: recipient index}."""
    result = {}
    for sender in range(n_players):
        others = [player for player in range(n_players) if player != sender]
        result[sender] = others[(sender + round_number) % (n_players - 1)]
    return result


print('1. Recipient rule by network size and round')
print('   P = every player receives from exactly one player; S = all pairs are mutual')
for n_players in range(2, 10):
    flags = []
    for round_number in range(1, 13):
        sends_to = recipients(n_players, round_number)
        everyone_receives_once = len(set(sends_to.values())) == n_players
        all_mutual = all(sends_to[sends_to[player]] == player for player in sends_to)
        flags.append(f"{round_number}:{'P' if everyone_receives_once else 'np'}{'S' if all_mutual else ''}")
    print(n_players, 'players:', ' '.join(flags))
print('Four players, recipient of each player by round:')
for round_number in range(1, 9):
    print(round_number, recipients(4, round_number))

# ---- 2. Experiment 1 ------------------------------------------------------------------
schedule = pd.read_csv(common.EXP1_PARTNERS)
scheduled_recipient = {(game, player, round_number): recipient
                       for game, player, round_number, recipient
                       in zip(schedule.gameID, schedule.playerID, schedule['round'], schedule.recipientID)}

messages = pd.read_csv(common.EXP1_MESSAGES)
print('\n2. Experiment 1 raw messages by column:', messages.groupby('src').size().to_dict())
# The same message can be logged in both columns; keep one copy.
messages = messages.drop_duplicates(['gameID', 'sender', 'round', 'time', 'text'])
messages['condition'] = messages.treatmentName.str.extract(r'rerun-(\w+)')
print('unique messages:', len(messages), messages.condition.value_counts().to_dict())

messages['matches_schedule'] = [
    scheduled_recipient.get((game, sender, int(round_number))) == recipient
    for game, sender, round_number, recipient
    in zip(messages.gameID, messages.sender, messages['round'], messages.recipient)]
print('messages whose logged recipient is the scheduled recipient, by condition:')
print(messages.groupby('condition').matches_schedule.agg(['sum', 'size']).to_string())

# For each sender-recipient pair in a round: did the recipient also message the sender?
pairs = messages.drop_duplicates(['gameID', 'round', 'sender', 'recipient'])
exchanged = set(zip(pairs.gameID, pairs['round'], pairs.sender, pairs.recipient))
pairs = pairs.assign(reverse_also_used=[
    (game, round_number, recipient, sender) in exchanged
    for game, round_number, sender, recipient
    in zip(pairs.gameID, pairs['round'], pairs.sender, pairs.recipient)])
print('Share of sender-recipient pairs whose reverse pair also exchanged a message, by round:')
print(pairs.pivot_table(index='round', columns='condition', values='reverse_also_used',
                        aggfunc='mean').round(3).to_string())

# Number of players each network was launched with
estimates = pd.read_csv(common.EXP1_MERGED).drop_duplicates('gameID')
estimates['condition'] = estimates.treatmentName.str.extract(r'rerun-(\w+)')
estimates['players_at_launch'] = estimates.gameID.map(
    schedule.drop_duplicates('gameID').set_index('gameID').nPlayers)
print('Networks with estimates, by number of players at launch and condition:')
print(pd.crosstab(estimates.players_at_launch, estimates.condition))

# The extracted messages are the partner source used for the model fits (models/01_fit.py).
extracted = pd.read_csv(common.EXP1_EXTRACTED_MSGS)
extracted = extracted.merge(schedule, how='left',
                            left_on=['groupID', 'sender.id', 'round'],
                            right_on=['gameID', 'playerID', 'round'])
print('Extracted messages:', len(extracted),
      '| sender in schedule:', extracted.recipientID.notna().sum(),
      '| logged recipient is the scheduled recipient:', (extracted.recipient == extracted.recipientID).sum())

# ---- 3. Experiment 2 ------------------------------------------------------------------
schedule = pd.read_csv(common.EXP2_PARTNERS)[['gameID', 'playerID', 'round', 'recipientID', 'reciprocal']]

coded = pd.read_csv(common.EXP2_CODED_MSGS)
coded = coded.merge(schedule, how='left',
                    left_on=['gameID', 'sender.id', 'round'], right_on=['gameID', 'playerID', 'round'])
print('\n3. Experiment 2 coded messages:', len(coded),
      '| logged recipient is the scheduled recipient:', (coded.recipient == coded.recipientID).sum())
print('coded messages in mutual rounds:', int(coded.reciprocal.sum()),
      '| in one-way rounds:', int((~coded.reciprocal.astype(bool)).sum()))

chat = pd.read_csv(common.EXP2_CHAT)
chat = chat.merge(schedule, how='left',
                  left_on=['gameID', 'sender', 'round'], right_on=['gameID', 'playerID', 'round'])
print('Experiment 2 raw chat messages:', len(chat),
      '| logged recipient is the scheduled recipient:', (chat.recipient == chat.recipientID).sum())
