"""Round-to-round change in error by round type (mutual vs one-way).
Run from this folder after regenerating the clean data files
(analysis/exp1/exp1_clean_data.csv, analysis/exp2/exp2_clean_data.csv).
Writes exp1_d.csv and exp2_d.csv for mutual_vs_oneway.R."""
import pandas as pd, numpy as np
# Exp 1 (4-player games only; mutual rounds are 1, 4, 7, 10)
e=pd.read_csv('../../analysis/exp1/exp1_clean_data.csv')
p=pd.read_csv('exp1_partners.csv'); four=set(p[p.nPlayers==4].gameID)
e=e[e.gameID.isin(four)].sort_values(['playerID','idx'])
e['prev_err']=e.groupby('playerID').error.shift(); e['prev_idx']=e.groupby('playerID').idx.shift()
e=e[(e.prev_idx==e.idx-1)]
e['d_err']=e.error-e.prev_err; e['recip']=e.idx.isin([4,7,10]).astype(int)
e[['gameID','playerID','condition','idx','recip','d_err','error','prev_err']].to_csv('exp1_d.csv',index=False)
# Exp 2 (mutual rounds are 1, 4, 7). In RS treatments the slider measures the
# squirrel share, so convert to a rabbit share before scoring.
x=pd.read_csv('../../analysis/exp2/exp2_clean_data.csv').dropna(subset=['guess'])
x['cond']=x['treatmentName.x'].str.split('_').str[1]; x['orient']=x['treatmentName.x'].str[:2]
x['g']=np.where(x.orient=='RS',100-x.guess,x.guess)
x['error']=(x.g-x.mleGame*100).abs()
x=x.groupby(['gameID','playerID','idx','cond']).error.last().reset_index().sort_values(['playerID','idx'])
x['prev_err']=x.groupby('playerID').error.shift(); x['prev_idx']=x.groupby('playerID').idx.shift()
x=x[x.prev_idx==x.idx-1]; x['d_err']=x.error-x.prev_err; x['recip']=x.idx.isin([4,7]).astype(int)
x.rename(columns={'cond':'condition'}).to_csv('exp2_d.csv',index=False)
