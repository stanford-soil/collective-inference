import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def binomial(p, n):
    flips = np.random.rand(n) < p
    return np.sum(flips)

def representation_degroot_update(agent_belief, neighbor_belief, agent_info_pct, neighbor_info_pct, discount_factor):
    """
    Update belief and information percentage using representation degroot formula:
    belief(agent, trial) = (1-discount_factor) * belief(agent, trial-1) + discount_factor * belief(neighbor, trial-1)
    info_pct(agent, trial) = (agent_info + discount_factor * neighbor_info) / total_possible_info
    """
    new_belief = (1 - discount_factor) * agent_belief + discount_factor * neighbor_belief
    new_info_pct = agent_info_pct + discount_factor * neighbor_info_pct
    
    return new_belief, new_info_pct

# Parameters
true_p = 0.7
n_agents = 4
n_trials = 9
discount_factor = 0.3
max_total_info = 30  # Maximum possible information units

# Initialize arrays
beliefs = np.zeros((n_agents, n_trials))
info_percentages = np.zeros((n_agents, n_trials))

# Initialize first trial
for agent in range(n_agents):
    n = 9  # Initial observations
    n_rabbits = binomial(true_p, n) 
    beliefs[agent, 0] = n_rabbits / n
    info_percentages[agent, 0] = n / max_total_info  # Percentage of total possible info

# Run simulation
for trial in range(1, n_trials):
    new_beliefs = beliefs[:, trial-1].copy()
    new_info_pcts = info_percentages[:, trial-1].copy()
    
    for agent in range(n_agents):
        neighbors = [i for i in range(n_agents) if i != agent]
        neighbor_belief_avg = np.mean(beliefs[neighbors, trial-1])
        neighbor_info_avg = np.mean(info_percentages[neighbors, trial-1])
        
        new_beliefs[agent], new_info_pcts[agent] = representation_degroot_update(
            beliefs[agent, trial-1], 
            neighbor_belief_avg,
            info_percentages[agent, trial-1],
            neighbor_info_avg,
            discount_factor
        )
    
    beliefs[:, trial] = new_beliefs
    info_percentages[:, trial] = new_info_pcts

# Create output dataframes
beliefs_df = pd.DataFrame(beliefs.T, columns=[f'Agent {i+1}_belief' for i in range(n_agents)])
info_df = pd.DataFrame(info_percentages.T, columns=[f'Agent {i+1}_info_pct' for i in range(n_agents)])

# Combine into single dataframe
result_df = pd.concat([beliefs_df, info_df], axis=1)
result_df.index.name = 'Trial'
result_df.to_csv('representation_version_degroot.csv')

print("Representation version degroot model created and saved to representation_version_degroot.csv")
print(f"Final beliefs: {beliefs[:, -1]}")
print(f"Final info percentages: {info_percentages[:, -1]}")