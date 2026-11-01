def sched(N,t):
    return {i:[j for j in range(N) if j!=i][(i+t)%(N-1)] for i in range(N)}
for N in [2,3,4,5,6,7,8,9]:
    out=[]
    for t in range(1,13):
        s=sched(N,t); perm=len(set(s.values()))==N; sym=all(s[s[i]]==i for i in s)
        out.append(f"{t}:{'P' if perm else 'np'}{'S' if sym else ''}")
    print(N,' '.join(out))
print('N=4 detail'); [print(t,sched(4,t)) for t in range(1,9)]
