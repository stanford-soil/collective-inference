import numpy as np
import pandas as pd

def binomial(p, n):
    return np.sum(np.random.rand(n) < p)

def update_beliefs_for_pairs(beliefs, pairs, influence_matrix):
    new_beliefs = np.copy(beliefs)
    for pair in pairs:
        flat_pair = np.array(pair).flatten()
        avg_belief = np.mean(beliefs[:, flat_pair])
        # Update beliefs for each agent in the pair
        for agent in flat_pair:
            new_beliefs[:, agent] = avg_belief + np.dot(influence_matrix[:, agent], beliefs[:, agent])
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

# initialize influence matrix
influence_matrix = np.array([[0.1, 0.2, 0.3, 0.4],
                             [0.2, 0.1, 0.4, 0.3],
                             [0.4, 0.3, 0.1, 0.2],
                             [0.3, 0.4, 0.2, 0.1]])

for t in range(8):
    # use the pairing for the current step
    current_pairing = pairings[t % len(pairings)]
    beliefs[:, t+1] = update_beliefs_for_pairs(beliefs[:, t], current_pairing, influence_matrix)

beliefs_df = pd.DataFrame(beliefs.T, columns=[f'Agent {i+1}' for i in range(4)])
beliefs_df.index.name = 'Time Step'
beliefs_df.to_csv('dyadic_with_influence.csv')

