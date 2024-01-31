import numpy as np

def binomial(p, n):
    return np.sum(np.random.rand(n) < p)

def update_beliefs_for_pairs(beliefs, pairs):
    new_beliefs = np.copy(beliefs)
    for pair in pairs:
        #each agent in the pair takes the average belief of themselves and their partner
        avg_belief = np.mean(beliefs[pair])
        new_beliefs[pair] = avg_belief
    return new_beliefs

true_p = 0.7
n_agents = 4
beliefs = np.zeros((n_agents, 9))

for agent in range(n_agents):
    n = 9  
    n_rabbits = binomial(true_p, n)
    beliefs[agent, 0] = n_rabbits 

#define pairings for each time step
pairings = [([0, 1], [2, 3]), 
            ([1, 2], [3, 0]),
            ([2, 3], [0, 1]),  
            ([3, 0], [1, 2])] 

for t in range(8):
    #use the pairing for the current step
    current_pairing = pairings[t % len(pairings)]
    beliefs[:, t+1] = update_beliefs_for_pairs(beliefs[:, t], current_pairing)

print(beliefs)
