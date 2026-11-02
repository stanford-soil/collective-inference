"""Apparent question-answer coherence in Experiment 2 chat: for each question a
player sent, whether a message reached them within 20 s and whether it looked like an
answer, separately for mutual rounds (the questioned player can answer) and one-way
rounds (the incoming message comes from someone who never saw the question). Prints
examples from one-way rounds. Uses all networks with chat (SR and RS).
Input: data/derived/exp2_chat_raw.csv (01_load_raw_logs.py). Output: printed.
Run from partner_schedule/."""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib'))
import common
import pandas as pd, re, numpy as np
# Exp 2 raw chat with true sender, recipient and time; duplicated log entries removed
c=pd.read_csv(common.repo_path('data','derived','exp2_chat_raw.csv'),keep_default_na=False,na_values=[''])  # keep texts such as 'none'
c['text']=c.text.fillna('').str.strip()
c=c[['gameID','round','sender','recipient','time','text']].drop_duplicates(['gameID','sender','time','text'])
c=c.dropna(subset=['time']).sort_values('time')
q=re.compile(r"\?|\b(?:how many|what about|and you|you\?|hbu|wbu|what do you|what did you|do you see|any squirrels|any rabbits)\b",re.I)
ans=re.compile(r"^\s*(?:yes|yeah|yep|no|nope|none|same|zero|\d+|one|two|three|four|five|six|i have|i see|i saw|i got|just|only|mine)\b|\b\d+\s*(?:r|s|rabbit|bunn|squir)",re.I)
rows=[]; ex=[]
for (g,rd),x in c.groupby(['gameID','round']):
    for a,mine in x.groupby('sender'):
        tgt=mine.recipient.mode().iloc[0]
        inc=x[x.recipient==a]
        if inc.empty: continue
        src=inc.sender.mode().iloc[0]
        mutual = (src==tgt)
        for _,qm in mine[mine.text.str.contains(q,na=False)].iterrows():
            nxt=inc[(inc.time>qm.time)&(inc.time<=qm.time+20000)]
            got=len(nxt)>0
            a_like= got and bool(ans.search(nxt.iloc[0].text))
            rows.append(dict(mutual=mutual,got=got,answer_like=a_like))
            if not mutual and a_like and len(ex)<12:
                ex.append((rd,qm.text,nxt.iloc[0].text,round((nxt.iloc[0].time-qm.time)/1000,1)))
r=pd.DataFrame(rows)
print(r.groupby('mutual').agg(questions=('got','size'),incoming_within_20s=('got','mean'),answer_like_reply=('answer_like','mean')).round(3))
print('\nOne-way rounds: own question -> next incoming message (from someone who never saw the question)')
for e in ex: print(f"rd {e[0]} | asked: {e[1]!r} | {e[3]}s later got: {e[2]!r}")
