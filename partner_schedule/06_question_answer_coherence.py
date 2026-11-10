"""Could participants tell that their partner was not answering them?

Experiment 2, messaging condition. In a one-way round, the messages a participant receives come
from someone who never saw the participant's own messages. If conversations in
one-way rounds had looked incoherent, participants could have noticed the schedule.

For every question a participant sent, we check whether a message reached them
within 20 seconds and whether that message looks like an answer (it starts with
"yes", "no", a number, "I have", ... or states a count). We compare mutual rounds,
where the incoming message can be a real answer, with one-way rounds, where it cannot.

Reads   data/derived/exp2_chat_raw.csv (prep/03_message_logs.py)
Prints  the share of questions followed by an answer-like message, and examples
"""
import re
import sys
import pandas as pd

sys.path.insert(0, '../lib')
import common

QUESTION = re.compile(r"\?|\b(?:how many|what about|and you|you\?|hbu|wbu|what do you|what did you|"
                      r"do you see|any squirrels|any rabbits)\b", re.I)
ANSWER_LIKE = re.compile(r"^\s*(?:yes|yeah|yep|no|nope|none|same|zero|\d+|one|two|three|four|five|six|"
                         r"i have|i see|i saw|i got|just|only|mine)\b"
                         r"|\b\d+\s*(?:r|s|rabbit|bunn|squir)", re.I)
WINDOW_MS = 20000

# keep_default_na=False keeps message texts such as "none" as text
chat = pd.read_csv(common.EXP2_CHAT, keep_default_na=False, na_values=[''])
chat['text'] = chat.text.fillna('').str.strip()
chat = chat[['gameID', 'round', 'sender', 'recipient', 'time', 'text']]
chat = chat.drop_duplicates(['gameID', 'sender', 'time', 'text']).dropna(subset=['time']).sort_values('time')
chat = common.keep_sr(chat)
print('messages:', len(chat), '| networks:', chat.gameID.nunique())

rows, examples = [], []
for (game, round_number), round_messages in chat.groupby(['gameID', 'round']):
    for player, own_messages in round_messages.groupby('sender'):
        incoming = round_messages[round_messages.recipient == player]
        if incoming.empty:
            continue
        mutual = incoming.sender.mode().iloc[0] == own_messages.recipient.mode().iloc[0]
        questions = own_messages[own_messages.text.str.contains(QUESTION, na=False)]
        for _, question in questions.iterrows():
            replies = incoming[(incoming.time > question.time) & (incoming.time <= question.time + WINDOW_MS)]
            got_reply = len(replies) > 0
            answer_like = got_reply and bool(ANSWER_LIKE.search(replies.iloc[0].text))
            rows.append(dict(mutual=mutual, got_reply=got_reply, answer_like=answer_like))
            if not mutual and answer_like and len(examples) < 12:
                delay = round((replies.iloc[0].time - question.time) / 1000, 1)
                examples.append((round_number, question.text, replies.iloc[0].text, delay))

result = pd.DataFrame(rows)
print(result.groupby('mutual').agg(
    questions=('got_reply', 'size'),
    message_within_20s=('got_reply', 'mean'),
    answer_like_message=('answer_like', 'mean')).round(3).to_string())

print('\nExamples from one-way rounds (the incoming message is from someone who never saw the question):')
for round_number, question, reply, delay in examples:
    print(f'round {round_number} | asked: {question!r} | {delay}s later received: {reply!r}')
