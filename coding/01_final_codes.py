"""Builds the final code of every Experiment 2 message from two independent codings.

Codes (see codebook.md): pn own counts, pb own belief, sn others' counts,
sb others' or the group's belief, q question, o other. A message can have several.

Steps
1. Agreement between the first coding (first author) and the second coding
   (a language model given the codebook and the message texts only).
2. Where the two codings agree, that is the final code.
3. Two rules settle part of the disagreements mechanically (adjudication/RULES.md):
   A. a speaker's own estimate is pb, not sb, unless the message refers to other players;
   B. a question added to a report gets the code q.
4. The remaining disagreements were decided one by one by the senior author
   (adjudication/items.json shows what he saw, adjudication/decisions.json what he decided).

The messages were coded in two batches.
  Batch 1: the 5,453 messages in the first author's coding file (158 networks).
  Batch 2: 326 messages from the 11 analysed networks that the file omits. The first
           coder of these is the senior author, who also resolved their remaining
           disagreements. The second coding is again a language model.

Reads   data/exp2/coded_messages.csv     batch 1, first coding (column `coding`)
        unique_texts.csv                 batch 1, every distinct message text, with an id
        second_coder_labels.csv          batch 1, second coding of each distinct text
        adjudication/items.json, adjudication/decisions.json
        batch2_first_coding.csv, batch2_unique_texts.csv, batch2_second_coder_labels.csv,
        adjudication/batch2_decisions.json
Writes  exp2_message_codes_final.csv     first, second and final code of every message
Prints  agreement statistics and how the disagreements were resolved, for each batch
"""
import json
import re
import sys
import pandas as pd
from sklearn.metrics import cohen_kappa_score

sys.path.insert(0, '../lib')
import common

CODES = ['pn', 'pb', 'sn', 'sb', 'q', 'o']


def first_coder_set(label):
    """The first coding is written without separators, for example 'pnq' or 'pbsb'."""
    label = '' if pd.isna(label) else label
    codes = {code for code in ['pn', 'pb', 'sn', 'sb'] if code in label}
    rest = label
    for code in ['pn', 'pb', 'sn', 'sb']:
        rest = rest.replace(code, '')
    if 'q' in rest:
        codes.add('q')
    if 'o' in rest:
        codes.add('o')
    return codes


def second_coder_set(label):
    """The second coding separates codes with '+', for example 'pn+q'."""
    return set(str(label).split('+')) if pd.notna(label) else set()


def as_text(codes):
    return '+'.join(sorted(codes)) if isinstance(codes, set) else None


# ---- Load both codings ---------------------------------------------------------------------
messages = pd.read_csv(common.EXP2_CODED_MSGS)
messages['text_norm'] = messages.text.fillna('').str.strip()
second = pd.read_csv('unique_texts.csv').merge(pd.read_csv('second_coder_labels.csv'), on='uid', how='left')
messages = messages.merge(second[['text_norm', 'uid', 'codes']], on='text_norm', how='left')
messages = messages[messages.coding.notna() & (messages.coding != 'n')].reset_index(drop=True)
messages['row'] = messages.index
messages['first'] = messages.coding.map(first_coder_set)
messages['second'] = messages.codes.map(second_coder_set)
messages['agree'] = messages['first'] == messages['second']

# ---- Steps 1 to 3, used for both batches ---------------------------------------------------
REFERS_TO_OTHERS = re.compile(
    r"\b(other|others|neighbou?r|neighbou?rs|everyone|everybody|we|they|people|partner|partners|total|"
    r"all of us|combined|someone|anyone|he|she|their|group|overall)\b", re.I)
ENDS_WITH_YOU = re.compile(r"\b(you|u)\W*$", re.I)


def print_agreement(messages):
    rows = []
    for code in CODES:
        in_first = messages['first'].map(lambda codes: code in codes)
        in_second = messages['second'].map(lambda codes: code in codes)
        rows.append(dict(code=code, share_first=round(in_first.mean(), 3), share_second=round(in_second.mean(), 3),
                         percent_agreement=round((in_first == in_second).mean(), 3),
                         kappa=round(cohen_kappa_score(in_first, in_second), 3)))
    print(pd.DataFrame(rows).to_string(index=False))
    print('messages with identical code sets:', round(messages.agree.mean(), 3),
          '| disagreements:', int((~messages.agree).sum()))


def apply_agreement_and_rules(messages):
    """Final code where the codings agree or where rule A or B settles the disagreement."""
    messages['final'] = None
    messages['resolution'] = None
    messages.loc[messages.agree, 'final'] = messages.loc[messages.agree, 'first']
    messages.loc[messages.agree, 'resolution'] = 'agree'
    for index, message in messages[~messages.agree].iterrows():
        difference = message['first'] ^ message['second']      # codes given by only one coder
        if difference == {'pb', 'sb'} and not REFERS_TO_OTHERS.search(message.text_norm):
            messages.at[index, 'final'] = (message['first'] - {'sb'}) | {'pb'}
            messages.at[index, 'resolution'] = 'ruleA'
        elif difference == {'q'} and ('?' in message.text_norm or ENDS_WITH_YOU.search(message.text_norm)):
            messages.at[index, 'final'] = message['first'] | message['second']
            messages.at[index, 'resolution'] = 'ruleB'


def print_resolution(messages):
    print(messages.resolution.value_counts().to_string())
    print('first coding identical to the final code:',
          round((messages['first'] == messages.final).mean(), 3),
          '| second coding:', round((messages['second'] == messages.final).mean(), 3))


# ---- Batch 1 ---------------------------------------------------------------------------------
print('Batch 1: agreement between the two codings,', len(messages), 'messages')
print_agreement(messages)
apply_agreement_and_rules(messages)

# ---- 4. Adjudicated decisions ----------------------------------------------------------------
# An item is one disputed message text. Its decision applies to one message (`row`)
# or to every still-undecided message with that text (`uid`). The decision records
# which coding the adjudicator chose: y = first, c2 = second, own = a different set
# of codes, rule_same = rule C ("same" takes the code of the earlier description).
items = json.load(open('adjudication/items.json'))
decisions = json.load(open('adjudication/decisions.json'))
for item in items:
    decision = decisions[str(item['id'])]
    decision = decision.get('data', decision)
    if item.get('row') is not None:
        rows = [item['row']]
    else:
        rows = list(messages[(messages.uid == item['uid']) & messages.final.isna()].row)
    for row in rows:
        messages.at[row, 'final'] = set(decision['final'])
        messages.at[row, 'resolution'] = 'adjudicated:' + decision['src']
assert messages.final.notna().all()

print('\nBatch 1: how each message got its final code')
print_resolution(messages)

# ---- Batch 2 ---------------------------------------------------------------------------------
batch2 = pd.read_csv('batch2_first_coding.csv', keep_default_na=False)
batch2['text_norm'] = batch2.text.str.strip()
second = pd.read_csv('batch2_unique_texts.csv', keep_default_na=False).merge(
    pd.read_csv('batch2_second_coder_labels.csv'), on='uid')
batch2 = batch2.merge(second[['text_norm', 'codes']], on='text_norm', how='left')
batch2['first'] = batch2.coding.map(second_coder_set)        # both codings of batch 2 use '+'
batch2['second'] = batch2.codes.map(second_coder_set)
batch2['agree'] = batch2['first'] == batch2['second']

print('\nBatch 2: agreement between the two codings,', len(batch2), 'messages')
print_agreement(batch2)
apply_agreement_and_rules(batch2)
decisions = json.load(open('adjudication/batch2_decisions.json'))
for index, message in batch2[batch2.final.isna()].iterrows():
    batch2.at[index, 'final'] = set(decisions[message.message_id].split('+'))
    batch2.at[index, 'resolution'] = 'adjudicated'
assert batch2.final.notna().all()
print('\nBatch 2: how each message got its final code')
print_resolution(batch2)

# ---- Write -----------------------------------------------------------------------------------
messages['batch'] = 1
batch2['batch'] = 2
both = pd.concat([messages, batch2], ignore_index=True)
output = both[['gameID', 'round', 'sender.id', 'recipient', 'text']].copy()
output['code_coder1'] = both['first'].map(as_text)
output['code_coder2'] = both['second'].map(as_text)
output['code_final'] = both.final.map(as_text)
output['resolution'] = both.resolution
output['batch'] = both.batch
output.to_csv(common.EXP2_FINAL_CODES, index=False)
print('\nWrote', len(output), 'messages from', output.gameID.nunique(), 'networks')
