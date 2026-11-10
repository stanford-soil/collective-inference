"""Reconstructs who sent to whom in every round.

The experiment code (experiments/server/src/callbacks.js) chose each player's
recipient with the rule

    recipient = otherPlayers[(i + round) % (N - 1)]

where i is the player's index (0, 1, 2, ...), N is the number of players in the
network and otherPlayers lists the other players in index order. This script
applies the rule to every network and writes, for each player and round:

    recipientID   the player this player sent to
    partnerID     the player this player received from (empty if not exactly one)
    reciprocal    True if the recipient also sent to this player (a mutual pair)

With four players the rule gives mutual pairs in rounds 1, 4, 7 and 10 and a
one-way cycle in the other rounds.

Reads   data/derived/exp1_players_raw.csv, exp2_players_raw.csv (prep/03_message_logs.py)
Writes  data/derived/exp1_partners.csv (12 rounds), exp2_partners.csv (8 rounds)
"""
import sys
import pandas as pd

sys.path.insert(0, '../lib')
import common


def recipient_of(n_players, sender, round_number):
    """Index of the player that `sender` sends to in this round."""
    others = [player for player in range(n_players) if player != sender]
    return others[(sender + round_number) % (n_players - 1)]


def partner_table(players, n_rounds):
    players = players.dropna(subset=['gameID', 'name']).drop_duplicates(['gameID', 'id'])
    rows = []
    for game_id, game_players in players.groupby('gameID'):
        n_players = len(game_players)
        # Player names are "player 1", "player 2", ...; the index is the number minus one.
        id_of = {int(name.split()[-1]) - 1: player_id
                 for player_id, name in zip(game_players.id, game_players.name)}
        if n_players < 2 or sorted(id_of) != list(range(n_players)):
            continue
        for round_number in range(1, n_rounds + 1):
            for player, player_id in id_of.items():
                recipient = recipient_of(n_players, player, round_number)
                senders = [other for other in range(n_players)
                           if recipient_of(n_players, other, round_number) == player]
                rows.append(dict(
                    gameID=game_id, playerID=player_id, player_name=f'player {player + 1}',
                    round=round_number, nPlayers=n_players,
                    recipientID=id_of[recipient],
                    senderToPlayerIDs=';'.join(id_of[sender] for sender in senders),
                    partnerID=id_of[senders[0]] if len(senders) == 1 else None,
                    reciprocal=recipient_of(n_players, recipient, round_number) == player))
    return pd.DataFrame(rows)


exp1 = partner_table(pd.read_csv(common.derived('exp1_players_raw.csv')), n_rounds=12)
exp1.to_csv(common.EXP1_PARTNERS, index=False)
print('Experiment 1:', exp1.gameID.nunique(), 'networks; by number of players:',
      exp1.drop_duplicates('gameID').nPlayers.value_counts().sort_index().to_dict())

exp2 = partner_table(pd.read_csv(common.derived('exp2_players_raw.csv')), n_rounds=8)
exp2.to_csv(common.EXP2_PARTNERS, index=False)
print('Experiment 2:', exp2.gameID.nunique(), 'networks; by number of players:',
      exp2.drop_duplicates('gameID').nPlayers.value_counts().sort_index().to_dict())
