import numpy as np
import pandas as pd

def binomial(p, n):
    flips = np.random.rand(n) < p
    return np.sum(flips)

def count_version_update(own_rabbits, own_total, stranger_rabbits, stranger_totals, discount_factor):
    """
    Count version formula:
    rabbits/(own_total + discount_factor * stranger_totals) 
    where rabbits = (own_rabbits + discount_factor * stranger_rabbits)
    """
    total_rabbits = own_rabbits + discount_factor * stranger_rabbits
    total_observations = own_total + discount_factor * stranger_totals
    return total_rabbits / total_observations

true_p = 0.7
n_agents = 4
n_trials = 9
discount_factor = 0.3

beliefs = np.zeros((n_agents, n_trials))
rabbit_counts = np.zeros((n_agents, n_trials))
total_counts = np.zeros((n_agents, n_trials))

for agent in range(n_agents):
    n = 9  
    n_rabbits = binomial(true_p, n) 
    rabbit_counts[agent, 0] = n_rabbits
    total_counts[agent, 0] = n
    beliefs[agent, 0] = n_rabbits / n

for trial in range(1, n_trials):
    for agent in range(n_agents):
        own_rabbits = rabbit_counts[agent, trial-1]
        own_total = total_counts[agent, trial-1]
        
        neighbors = [i for i in range(n_agents) if i != agent]
        stranger_rabbits = np.sum(rabbit_counts[neighbors, trial-1])
        stranger_totals = np.sum(total_counts[neighbors, trial-1])
        
        beliefs[agent, trial] = count_version_update(
            own_rabbits, own_total, 
            stranger_rabbits, stranger_totals, 
            discount_factor
        )
        
        rabbit_counts[agent, trial] = own_rabbits + discount_factor * stranger_rabbits
        total_counts[agent, trial] = own_total + discount_factor * stranger_totals

beliefs_df = pd.DataFrame(beliefs.T, columns=[f'Agent {i+1}' for i in range(n_agents)])
beliefs_df.index.name = 'Trial'
beliefs_df.to_csv('count_version.csv')