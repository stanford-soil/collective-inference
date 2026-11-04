"""Builds the per-round partner tables implied by the recipient rule in
experiments/server/src/callbacks.js: in round t, player i (0-based, from the player
name) sends to otherPlayers[(i + t) % (N - 1)], where otherPlayers lists the other
players in index order. For each player and round the tables give the recipient, the
player(s) who send to this player (partnerID when there is exactly one) and whether
the pair is mutual (reciprocal) in that round.

Inputs: data/derived/exp1_players_raw.csv, exp2_players_raw.csv (01_load_raw_logs.py).
Outputs: exp1_partners.csv (12 rounds), exp2_partners.csv (8 rounds).
Run from partner_schedule/.
"""
import os
import sys
import pandas as pd

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib'))
import common

DERIVED = common.repo_path('data', 'derived')


def outp(N, i, t):
    """Recipient of player i in round t in a network of N players."""
    return [j for j in range(N) if j != i][(i + t) % (N - 1)]


def table(P, nrounds):
    P = P.dropna(subset=['gameID', 'name']).drop_duplicates(['gameID', 'id'])
    rows = []
    for g, df in P.groupby('gameID'):
        N = len(df)
        byidx = {int(n.split()[-1]) - 1: pid for pid, n in zip(df.id, df.name)}
        if N < 2 or sorted(byidx) != list(range(N)):
            continue
        for t in range(1, nrounds + 1):
            for i, pid in byidx.items():
                o = outp(N, i, t)
                ins = [k for k in range(N) if outp(N, k, t) == i]
                rows.append(dict(gameID=g, playerID=pid, player_name=f'player {i+1}', round=t, nPlayers=N,
                                 recipientID=byidx[o], senderToPlayerIDs=';'.join(byidx[k] for k in ins),
                                 partnerID=byidx[ins[0]] if len(ins) == 1 else None,
                                 reciprocal=(outp(N, o, t) == i)))
    return pd.DataFrame(rows)


t1 = table(pd.read_csv(f'{DERIVED}/exp1_players_raw.csv'), 12)
t2 = table(pd.read_csv(f'{DERIVED}/exp2_players_raw.csv'), 8)
t1.to_csv('exp1_partners.csv', index=False)
t2.to_csv('exp2_partners.csv', index=False)
print('Exp 1 partner table', t1.shape, 'games', t1.gameID.nunique(), '| rows with in-degree != 1:', t1.partnerID.isna().sum())
print('Exp 1 share of mutual pairs by round (4-player networks):',
      t1[t1.nPlayers == 4].groupby('round').reciprocal.mean().to_dict())
print('Exp 2 partner table', t2.shape, 'games', t2.gameID.nunique())
