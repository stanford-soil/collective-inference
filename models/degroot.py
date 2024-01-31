import numpy as np

def binomial(p, n):
    flips = np.random.rand(n) < p
    return np.sum(flips)
true_p = 0.7
beliefs = np.zeros((4, 9))

for agent in range(4):
    n = 9  
    n_rabbits = binomial(true_p, n) 
    beliefs[agent, 0] = n_rabbits 

def degroot_update(beliefs, t):
    n_agents = beliefs.shape[0]
    new_beliefs = np.copy(beliefs)
    for i in range(n_agents):
        #each agent updates their belief based on the average belief of all agents at time t
        new_beliefs[i, t+1] = np.mean(beliefs[:, t])
    return new_beliefs

#apply the DeGroot model over 9 time steps
for t in range(8):
    beliefs = degroot_update(beliefs, t)

print(beliefs)