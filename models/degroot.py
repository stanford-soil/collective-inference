import numpy as np
import pandas as pd

def binomial(p, n):
    flips = np.random.rand(n) < p
    return np.sum(flips)

true_p = 0.7
beliefs = np.zeros((4, 9))
#each row vector represents that agents influence from others
influence_matrix = np.array([[0.5, 0.1, 0.2, 0.2],
                             [0.1, 0.5, 0.2, 0.2], 
                             [0.2, 0.2, 0.5, 0.1],  
                             [0.2, 0.2, 0.1, 0.5]]) 

for agent in range(4):
    n = 9  
    n_rabbits = binomial(true_p, n) 
    beliefs[agent, 0] = n_rabbits 

def degroot_update(beliefs, influence_matrix):
    return np.dot(influence_matrix, beliefs)

#apply the DeGroot model over 9 time steps
for t in range(8):
    beliefs[:, t+1] = degroot_update(beliefs[:, t], influence_matrix)

beliefs_df = pd.DataFrame(beliefs.T, columns=[f'Agent {i+1}' for i in range(4)])
beliefs_df.index.name = 'Time Step'
beliefs_df.to_csv('degroot.csv')
