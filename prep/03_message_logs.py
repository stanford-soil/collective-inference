"""Extracts every logged message and the player list from the raw Empirica exports.

In the raw exports the messages of a network are stored as JSON inside one cell of
the games table. This script unpacks them into one row per message, with the
sender, the recorded recipient, the round and the time.

Reads   data/exp1/raw/1_prereg_*/, data/exp2/raw/<batch>/
Writes  data/derived/exp1_messages_raw.csv, exp1_players_raw.csv, exp1_games_raw.csv,
        exp2_chat_raw.csv, exp2_players_raw.csv
"""
import json
import os
import sys
import pandas as pd

sys.path.insert(0, '../lib')
import common

os.makedirs(common.repo_path('data', 'derived'), exist_ok=True)

# ---- Experiment 1 -------------------------------------------------------------------
# Messages are stored in two columns of games.csv: `messages` (a list) and `chat`
# (a single message). The column each message came from is kept in `src`.
messages, players, games = [], [], []
batches = sorted(name for name in os.listdir(common.EXP1_RAW) if name.startswith('1_prereg_'))
for batch in batches:
    batch_games = pd.read_csv(f'{common.EXP1_RAW}/{batch}/games.csv', encoding='utf-8-sig')
    batch_players = pd.read_csv(f'{common.EXP1_RAW}/{batch}/players.csv', encoding='utf-8-sig')
    batch_players['batch'] = batch
    players.append(batch_players[['id', 'gameID', 'name', 'recipient', 'batch']])
    games.append(batch_games[['id', 'groupID', 'treatmentName']].assign(batch=batch))

    for _, game in batch_games.iterrows():
        for column in ['messages', 'chat']:
            cell = game.get(column)
            if pd.isna(cell):
                continue
            logged = json.loads(cell)
            if not isinstance(logged, list):
                logged = [logged]
            for position, message in enumerate(logged):
                if isinstance(message, str):
                    message = json.loads(message)
                messages.append(dict(
                    batch=batch, gameID=game.id, groupID=game.groupID, treatmentName=game.treatmentName,
                    src=column, k=position, text=message.get('text'), time=message.get('time'),
                    round=message.get('round'), recipient=message.get('recipient'),
                    sender=message['sender']['id'], sender_name=message['sender'].get('name')))

messages = pd.DataFrame(messages)
messages.to_csv(common.EXP1_MESSAGES, index=False)
pd.concat(players).to_csv(common.derived('exp1_players_raw.csv'), index=False)
pd.concat(games).to_csv(common.derived('exp1_games_raw.csv'), index=False)
print('Experiment 1 messages by column:', messages.groupby('src').size().to_dict(),
      '| networks:', messages.gameID.nunique())

# ---- Experiment 2 -------------------------------------------------------------------
messages, players = [], []
batches = sorted(name for name in os.listdir(common.EXP2_RAW) if not name.startswith('.'))
for batch in batches:
    batch_games = pd.read_csv(f'{common.EXP2_RAW}/{batch}/game.csv')
    batch_players = pd.read_csv(f'{common.EXP2_RAW}/{batch}/player.csv')
    batch_players['batch'] = batch
    players.append(batch_players[['id', 'gameID', 'name', 'recipient', 'recipientLastChangedAt', 'batch']])

    for _, game in batch_games.iterrows():
        if pd.isna(game.get('chat')):
            continue
        treatment = json.loads(game.treatment) if isinstance(game.treatment, str) else {}
        for position, message in enumerate(json.loads(game.chat)):
            messages.append(dict(
                batch=batch, gameID=game.id, condition=treatment.get('condition'), k=position,
                text=message.get('text'), time=message.get('time'), round=message.get('round'),
                recipient=message.get('recipient'), sender=message['sender']['id'],
                sender_name=message['sender'].get('name')))

messages = pd.DataFrame(messages)
messages.to_csv(common.EXP2_CHAT, index=False)
pd.concat(players).to_csv(common.derived('exp2_players_raw.csv'), index=False)
print('Experiment 2 chat messages:', len(messages), messages.condition.value_counts().to_dict(),
      '| networks:', messages.gameID.nunique())
