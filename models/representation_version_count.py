import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def binomial(p, n):
    flips = np.random.rand(n) < p
    return np.sum(flips)

def representation_count_update(own_rabbits, own_total, stranger_rabbits, stranger_totals, discount_factor, max_total_info):
    """
    Count version formula with representation tracking:
    belief = rabbits/(own_total + discount_factor * stranger_totals) 
    where rabbits = (own_rabbits + discount_factor * stranger_rabbits)
    info_pct = (own_total + discount_factor * stranger_totals) / max_total_info
    """
    total_rabbits = own_rabbits + discount_factor * stranger_rabbits
    total_observations = own_total + discount_factor * stranger_totals
    
    belief = total_rabbits / total_observations
    info_pct = total_observations / max_total_info
    
    return belief, info_pct, total_rabbits, total_observations

# Parameters
true_p = 0.7
n_agents = 4
n_trials = 9
discount_factor = 0.3
max_total_info = 30  # Maximum possible information units

# Initialize arrays
beliefs = np.zeros((n_agents, n_trials))
info_percentages = np.zeros((n_agents, n_trials))
rabbit_counts = np.zeros((n_agents, n_trials))
total_counts = np.zeros((n_agents, n_trials))

# Initialize first trial
for agent in range(n_agents):
    n = 9  # Initial observations
    n_rabbits = binomial(true_p, n) 
    rabbit_counts[agent, 0] = n_rabbits
    total_counts[agent, 0] = n
    beliefs[agent, 0] = n_rabbits / n
    info_percentages[agent, 0] = n / max_total_info

# Run simulation
for trial in range(1, n_trials):
    for agent in range(n_agents):
        own_rabbits = rabbit_counts[agent, trial-1]
        own_total = total_counts[agent, trial-1]
        
        neighbors = [i for i in range(n_agents) if i != agent]
        stranger_rabbits = np.sum(rabbit_counts[neighbors, trial-1])
        stranger_totals = np.sum(total_counts[neighbors, trial-1])
        
        belief, info_pct, new_rabbits, new_total = representation_count_update(
            own_rabbits, own_total, 
            stranger_rabbits, stranger_totals, 
            discount_factor, max_total_info
        )
        
        beliefs[agent, trial] = belief
        info_percentages[agent, trial] = info_pct
        rabbit_counts[agent, trial] = new_rabbits
        total_counts[agent, trial] = new_total

# Create output dataframes
beliefs_df = pd.DataFrame(beliefs.T, columns=[f'Agent {i+1}_belief' for i in range(n_agents)])
info_df = pd.DataFrame(info_percentages.T, columns=[f'Agent {i+1}_info_pct' for i in range(n_agents)])

# Combine into single dataframe
result_df = pd.concat([beliefs_df, info_df], axis=1)
result_df.index.name = 'Trial'
result_df.to_csv('representation_version_count.csv')

print("Representation version count model created and saved to representation_version_count.csv")
print(f"Final beliefs: {beliefs[:, -1]}")
print(f"Final info percentages: {info_percentages[:, -1]}")