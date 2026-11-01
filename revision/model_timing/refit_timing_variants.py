"""
Refit of Exp 1 Belief (DeGroot) and Evidence (Count) models with selectable partner timing.

Model definitions, optimizer, bounds, start grids, k and AIC are copied from
models/fit.py; only the predictions are vectorized (numpy) for speed, and
prepare_transitions takes a `timing` argument.

timing='original'  : exact fit.py logic. Transition t -> t+1 uses the round-t
                     partner (who player received from in round t), that partner's
                     round-t belief, and cumulative evidence over partners of kept
                     transitions up to round t.
timing='corrected' : SLIDER identical to 'original'. INTERACTIVE: transition
                     t -> t+1 uses the round-(t+1) partner (chat precedes the
                     round-(t+1) guess). partner counts = that partner's sample;
                     partner_belief = that partner's round-t guess (their most
                     recent submitted numerical belief before the round-(t+1)
                     chat); cumulative evidence = all distinct partners the player
                     received a message from in rounds 1..t+1 (incl. round 1,
                     whose chat preceded the round-1 guess).
timing='timing_only': INTERACTIVE uses the round-(t+1) partner and their round-t
                     belief, but keeps fit.py's cumulative bookkeeping (adds a
                     partner only at kept transitions, so the round-1 partner is
                     never counted). Sensitivity check.
timing='corrected_simbelief': as 'corrected' but partner_belief = partner's
                     round-(t+1) guess (not actually available to receiver;
                     sensitivity only).

Usage: python refit.py <timing> <out_csv> [partner_source=msgs|sched]
"""
import sys
import numpy as np
import pandas as pd
from scipy.optimize import minimize

CLEAN = '../../analysis/exp1/exp1_clean_data.csv'
MSGS = '../../data/exp1/raw/1_extracted_msgs_prereg/extracted_messages.csv'
SCHED = '../partner_schedule/exp1_partners.csv'


def load(partner_source='msgs'):
    beliefs = pd.read_csv(CLEAN)
    beliefs['belief'] = beliefs['guess'] / 100.0
    if partner_source == 'msgs':
        msgs = pd.read_csv(MSGS).dropna(subset=['round', 'recipient', 'sender.id', 'groupID'])
        lk = {}
        for g, r, rd, s in zip(msgs['groupID'], msgs['recipient'], msgs['round'], msgs['sender.id']):
            lk.setdefault((g, r, int(rd)), s)
    else:
        p = pd.read_csv(SCHED).dropna(subset=['partnerID'])
        lk = {(g, a, int(r)): b for g, a, r, b in zip(p.gameID, p.playerID, p['round'], p.partnerID)}
    samples = {}
    for _, row in beliefs.drop_duplicates(['gameID', 'playerID']).iterrows():
        samples[(row['gameID'], row['playerID'])] = (int(row['nRabbits']), int(row['nSquirrels']))
    return beliefs, lk, samples


def prepare(beliefs, lk, samples, condition, timing):
    shift = timing != 'original' and condition != 'slider'
    cond = beliefs[beliefs['condition'] == condition]
    out = []
    for gid in cond['gameID'].unique():
        gdf = cond[cond['gameID'] == gid]
        bel = {(p, int(i)): b for p, i, b in zip(gdf['playerID'], gdf['idx'], gdf['belief'])}
        for pid in gdf['playerID'].unique():
            pdf = gdf[gdf['playerID'] == pid].sort_values('idx')
            rounds = pdf['idx'].values
            pb = pdf['belief'].values
            own_r, own_s = samples.get((gid, pid), (0, 0))
            own_n = own_r + own_s
            own_mle = own_r / own_n if own_n > 0 else 0.5
            seen, cr, cs = set(), 0, 0
            if timing in ('corrected', 'corrected_simbelief') and shift:
                # partners received from in rounds 1..t+1, built on the fly
                cum_by_round = {}
                s2, r2, sq2 = set(), 0, 0
                for rr in range(1, 13):
                    q = lk.get((gid, pid, rr))
                    if q is not None and q not in s2 and (gid, q) in samples:
                        s2.add(q); r2 += samples[(gid, q)][0]; sq2 += samples[(gid, q)][1]
                    cum_by_round[rr] = (r2, sq2)
            for ti in range(len(rounds) - 1):
                t = int(rounds[ti])
                pr = t + 1 if shift else t
                partner = lk.get((gid, pid, pr))
                if partner is None:
                    continue
                ps = samples.get((gid, partner))
                if ps is None:
                    continue
                brd = t + 1 if timing == 'corrected_simbelief' and shift else t
                if (partner, brd) not in bel:
                    continue
                if timing in ('corrected', 'corrected_simbelief') and shift:
                    cr, cs = cum_by_round[pr]
                elif partner not in seen:
                    seen.add(partner); cr += ps[0]; cs += ps[1]
                out.append(dict(game_id=gid, player_id=pid, round=t, partner_id=partner,
                                own_belief=pb[ti], actual_next=pb[ti + 1], own_r=own_r, own_s=own_s,
                                own_mle=own_mle, partner_belief=bel[(partner, brd)],
                                cumulative_r=cr, cumulative_s=cs))
    return pd.DataFrame(out)


def dg_pred(T, alpha, wu, wm, wr):
    step = alpha * T['own_belief'] + (1 - alpha) * T['partner_belief']
    return wu * step + wm * T['own_mle'] + wr * 0.5


def ct_pred(T, delta, alpha, wu, wm, wr):
    own_n = T['own_r'] + T['own_s']
    cum_n = T['cumulative_r'] + T['cumulative_s']
    pr = T['own_r'] + delta * T['cumulative_r']
    pn = own_n + delta * cum_n
    pooled = np.where(pn > 0, pr / np.where(pn > 0, pn, 1), 0.5)
    step = alpha * T['own_belief'] + (1 - alpha) * pooled
    return wu * step + wm * T['own_mle'] + wr * 0.5


def fit_dg(T, anchor):
    y = T['actual_next']
    if anchor:
        def obj(x):
            if not (0 < x[0] < 1): return 1e10
            return np.mean((dg_pred(T, *x) - y) ** 2)
        starts = [[a, b, c, d] for a in [0.6, 0.75, 0.85] for b in [0.5, 0.7, 0.9]
                  for c in [0.0, 0.1, 0.2] for d in [0.0, 0.1, 0.3]]
        bounds = [(0.01, 0.99), (-2.0, 2.0), (-1.0, 1.0), (-1.0, 2.0)]
    else:
        def obj(x):
            if not (0 < x[0] < 1): return 1e10
            return np.mean((dg_pred(T, x[0], 1.0, 0.0, 0.0) - y) ** 2)
        starts = [[a] for a in [0.6, 0.75, 0.85]]
        bounds = [(0.01, 0.99)]
    best = min((minimize(obj, x0=s, bounds=bounds, method='L-BFGS-B') for s in starts), key=lambda r: r.fun)
    x = list(best.x) + ([] if anchor else [1.0, 0.0, 0.0])
    return dict(alpha=x[0], w_update=x[1], w_mle=x[2], w_mid=x[3], delta=np.nan), best.fun


def fit_ct(T, anchor):
    y = T['actual_next']
    if anchor:
        def obj(x):
            if not (0 < x[0] < 3 and 0 < x[1] < 1): return 1e10
            return np.mean((ct_pred(T, *x) - y) ** 2)
        starts = [[d, a, b, c, e] for d in [0.3, 0.5, 0.7] for a in [0.3, 0.5, 0.7] for b in [0.5, 0.7, 0.9]
                  for c in [0.0, 0.1, 0.2] for e in [0.0, 0.1, 0.3]]
        bounds = [(0.01, 2.0), (0.01, 0.99), (-2.0, 2.0), (-1.0, 1.0), (-1.0, 2.0)]
    else:
        def obj(x):
            if not (0 < x[0] < 3 and 0 < x[1] < 1): return 1e10
            return np.mean((ct_pred(T, x[0], x[1], 1.0, 0.0, 0.0) - y) ** 2)
        starts = [[d, a] for d in [0.3, 0.5, 0.7] for a in [0.3, 0.5, 0.7]]
        bounds = [(0.01, 2.0), (0.01, 0.99)]
    best = min((minimize(obj, x0=s, bounds=bounds, method='L-BFGS-B') for s in starts), key=lambda r: r.fun)
    x = list(best.x) + ([] if anchor else [1.0, 0.0, 0.0])
    return dict(delta=x[0], alpha=x[1], w_update=x[2], w_mle=x[3], w_mid=x[4]), best.fun


def aic(mse, n, k):
    s = np.sqrt(mse)
    return 2 * k - 2 * (-n / 2 * np.log(2 * np.pi) - n * np.log(s) - n / 2)


def run(timing, partner_source='msgs', conds=(('slider', 'slider'), ('chat', 'interactive'))):
    beliefs, lk, samples = load(partner_source)
    rows, trans = [], {}
    for name, c in conds:
        T = prepare(beliefs, lk, samples, c, timing)
        trans[name] = T
        Tn = {k: T[k].values.astype(float) for k in ['own_belief', 'partner_belief', 'own_mle', 'own_r', 'own_s',
                                                      'cumulative_r', 'cumulative_s', 'actual_next']}
        n = len(T)
        for model, f, kb in [('degroot', fit_dg, 1), ('count', fit_ct, 2)]:
            for anchor in [False, True]:
                p, mse = f(Tn, anchor)
                k = kb + 3 * int(anchor)
                rows.append(dict(timing=timing, partner_source=partner_source, condition=name, model=model,
                                 anchor=anchor, n=n, mse=mse, aic=aic(mse, n, k), k=k, sigma=np.sqrt(mse), **p))
    return pd.DataFrame(rows), trans


if __name__ == '__main__':
    timing = sys.argv[1]
    out = sys.argv[2]
    src = sys.argv[3] if len(sys.argv) > 3 else 'msgs'
    conds = (('slider', 'slider'), ('chat', 'interactive'))
    if timing != 'original' and len(sys.argv) > 4 and sys.argv[4] == 'uni':
        conds = conds + (('unidirectional', 'unidirectional'),)
    res, trans = run(timing, src, conds)
    res.to_csv(out, index=False)
    for k, T in trans.items():
        T.to_csv(out.replace('.csv', f'_transitions_{k}.csv'), index=False)
    pd.set_option('display.width', 200)
    print(res[['condition', 'model', 'anchor', 'n', 'aic', 'k', 'sigma', 'alpha', 'delta',
               'w_update', 'w_mle', 'w_mid']].round(4).to_string(index=False))
