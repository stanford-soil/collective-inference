"""An automated detector of messages that report animal counts, for messages that
were not coded by hand.

A message is flagged when it contains a number followed by an animal word
("3 rabbits", "one brown squirrel") or a digit followed by r or s ("3r 2s").

1. The detector is validated against the final hand codes of Experiment 2
   (a message reports counts if its final code includes pn or sn).
2. Count reports are compared between the two coding batches of Experiment 2
   (batch 2 holds the networks that the original coding file omitted).
3. It is applied to the Experiment 1 messages, which were never coded by hand.

Reads   coding/exp2_message_codes_final.csv, data/derived/exp1_messages_raw.csv,
        exp1_clean_data.csv
Prints  the validation and the share of messages that report counts
"""
import re
import sys
import pandas as pd
from sklearn.metrics import cohen_kappa_score

sys.path.insert(0, '../lib')
import common

NUMBER = r"(?:\d+|zero|no|none|one|a|an|single|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)"
ANIMAL = r"(?:rab+its?|rabits?|bunn(?:y|ies)|squir+els?|sq[a-z]*r+[a-z]*ls?|squirel|rabs?|sqs?)"
NUMBER_THEN_ANIMAL = re.compile(rf"\b{NUMBER}\s+(?:\w+\s+)?{ANIMAL}\b", re.I)   # "3 rabbits", "one brown squirrel"
DIGIT_THEN_LETTER = re.compile(r"\b\d+\s*[rs]\b", re.I)                         # "3r 2s"


def reports_counts(text):
    text = str(text)
    return bool(NUMBER_THEN_ANIMAL.search(text) or DIGIT_THEN_LETTER.search(text))


def validate(detected, hand_coded):
    hits = (detected & hand_coded).sum()
    misses = (~detected & hand_coded).sum()
    false_alarms = (detected & ~hand_coded).sum()
    correct_rejections = (~detected & ~hand_coded).sum()
    return (f'{len(detected)} messages | sensitivity {hits / (hits + misses):.3f} | '
            f'specificity {correct_rejections / (correct_rejections + false_alarms):.3f} | '
            f'kappa {cohen_kappa_score(detected, hand_coded):.3f} | '
            f'share by hand {hand_coded.mean():.3f} | share detected {detected.mean():.3f}')


sr_games = common.sr_games()

# ---- 1. Validation against the hand codes ---------------------------------------------------
coded = pd.read_csv(common.EXP2_FINAL_CODES, keep_default_na=False)
coded['detected'] = coded.text.map(reports_counts)
coded['hand_coded'] = coded.code_final.str.contains('pn|sn')
analysed = coded[coded.gameID.isin(sr_games)]
print('1. Validation against the final hand codes of Experiment 2')
print('   analysed networks: ', validate(analysed.detected, analysed.hand_coded))
print('   all coded networks:', validate(coded.detected, coded.hand_coded))

# ---- 2. The two coding batches (analysed networks) ------------------------------------------
# Batch 2 holds the networks that the original coding file omitted. If they resemble
# the batch 1 networks, both the detector and the hand codes should say so.
print('\n2. Analysed networks by coding batch')
print(analysed.groupby('batch').agg(
    networks=('gameID', 'nunique'), messages=('text', 'size'),
    share_by_hand=('hand_coded', 'mean'), share_detected=('detected', 'mean')).round(3).to_string())

# ---- 3. Experiment 1 --------------------------------------------------------------------------
messages = pd.read_csv(common.EXP1_MESSAGES, keep_default_na=False)
messages = messages[messages.src == 'messages'].drop_duplicates(['gameID', 'sender', 'time', 'text'])
messages['condition'] = messages.treatmentName.str.extract(r'rerun-(\w+)')[0]
messages = messages[messages.condition.isin(['interactive', 'unidirectional'])].copy()

# Keep messages sent by participants in the analysed sample
analysed_sample = pd.read_csv(common.EXP1_CLEAN)
analysed_senders = set(zip(analysed_sample.gameID, analysed_sample.playerID))
messages = messages[[(game, sender) in analysed_senders for game, sender in zip(messages.gameID, messages.sender)]]
messages['detected'] = messages.text.map(reports_counts)
print('\n3. Experiment 1 messaging conditions, senders in the analysed sample')
print(messages.groupby('condition').agg(
    networks=('gameID', 'nunique'), senders=('sender', 'nunique'), messages=('text', 'size'),
    share_reporting_counts=('detected', 'mean')).round(3).to_string())
