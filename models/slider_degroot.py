import numpy as np
import pandas as pd

def binomial(p, n):
    flips = np.random.rand(n) < p
    return np.sum(flips)

def slider_belief_update(agent_belief, neighbor_belief, discount_factor):
    """
    Update belief using slider (degroot) formula:
    belief(agent, trial) = (1-discount_factor) * belief(agent, trial-1) + discount_factor * belief(neighbor, trial-1)
    """
    return (1 - discount_factor) * agent_belief + discount_factor * neighbor_belief

true_p = 0.7
n_agents = 4
n_trials = 9
discount_factor = 0.3

beliefs = np.zeros((n_agents, n_trials))

for agent in range(n_agents):
    n = 9  
    n_rabbits = binomial(true_p, n) 
    beliefs[agent, 0] = n_rabbits / n

for trial in range(1, n_trials):
    new_beliefs = beliefs[:, trial-1].copy()
    
    for agent in range(n_agents):
        neighbors = [i for i in range(n_agents) if i != agent]
        neighbor_avg = np.mean(beliefs[neighbors, trial-1])
        
        new_beliefs[agent] = slider_belief_update(
            beliefs[agent, trial-1], 
            neighbor_avg, 
            discount_factor
        )
    
    beliefs[:, trial] = new_beliefs

beliefs_df = pd.DataFrame(beliefs.T, columns=[f'Agent {i+1}' for i in range(n_agents)])
beliefs_df.index.name = 'Trial'
beliefs_df.to_csv('slider_degroot.csv')