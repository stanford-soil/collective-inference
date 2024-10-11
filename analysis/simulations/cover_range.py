import random
import pandas as pd
from scipy.stats import binom
import numpy as np
import json  # Import for JSON handling

# Helper function to simulate binomial outcomes
def binomial(p, n):
    flips = list(range(n))
    flips = [random.random() < p for _ in flips]
    return sum(flips)

# Function to assign a value to a bin in the heatmap
def assign_bin(value, min_val, max_val, num_bins=5):
    bin_width = (max_val - min_val) / num_bins
    return min(int((value - min_val) // bin_width), num_bins - 1)

# Check if all bins are filled with the required number of rows (3)
def all_bins_filled():
    return all(len(bin_dict) == 25 and all(count == max_rows_per_bin for count in bin_dict.values()) 
               for bin_dict in heatmap_bins.values())

# Initialize variables
data = []
heatmap_bins = {
    'representativeness_vs_entropy': {},
    'entropy_vs_nCritters': {},
    'representativeness_vs_nCritters': {}
}
max_rows_per_bin = 3
max_attempts = 1000000  # Set a high number to try filling bins many times

# Loop until all bins are filled or max_attempts is reached
attempts = 0
while not all_bins_filled() and attempts < max_attempts:
    attempts += 1
    gameID = (len(data) // 4) + 1
    players = []
    
    # Generate data for 4 players in one game
    for _ in range(4):
        playerID = len(data) + 1
        trueP = 0.7  # Always set to 0.7 for all players
        n = random.randint(1, 30)  # nCritters in the range of 1-30
        nRabbits = binom.rvs(n, trueP, size=1)[0]
        nSquirrels = n - nRabbits
        players.append({'playerID': playerID, 'nRabbits': int(nRabbits), 'nSquirrels': int(nSquirrels)})

    # Game-level calculations
    total_nRabbits = sum(player['nRabbits'] for player in players)
    total_nSquirrels = sum(player['nSquirrels'] for player in players)
    total_nCritters = total_nRabbits + total_nSquirrels
    if total_nCritters == 0:
        continue  # Avoid division by zero if no critters in the game

    mleGame = total_nRabbits / total_nCritters
    prob = np.array([total_nRabbits, total_nSquirrels]) / total_nCritters

    # Calculate entropy
    entropy = -np.sum([p * np.log(p) for p in prob if p > 0])

    # Calculate representation
    mleEstimates = [player['nRabbits'] / (player['nRabbits'] + player['nSquirrels']) 
                    if (player['nRabbits'] + player['nSquirrels']) > 0 else 0 for player in players]
    representation = np.mean([abs(mleEstimate - mleGame) for mleEstimate in mleEstimates])

    # Assign bins for heatmaps
    rep_bin = assign_bin(representation, 0, 0.5, 5)
    entropy_bin = assign_bin(entropy, 0, 1.5, 5)
    nCritters_bin = assign_bin(total_nCritters, 0, 30, 5)

    # Check if this game meets criteria for any of the heatmaps
    meets_criteria = False

    if (rep_bin, entropy_bin) not in heatmap_bins['representativeness_vs_entropy']:
        heatmap_bins['representativeness_vs_entropy'][(rep_bin, entropy_bin)] = 0
    if heatmap_bins['representativeness_vs_entropy'][(rep_bin, entropy_bin)] < max_rows_per_bin:
        heatmap_bins['representativeness_vs_entropy'][(rep_bin, entropy_bin)] += 1
        meets_criteria = True

    if (entropy_bin, nCritters_bin) not in heatmap_bins['entropy_vs_nCritters']:
        heatmap_bins['entropy_vs_nCritters'][(entropy_bin, nCritters_bin)] = 0
    if heatmap_bins['entropy_vs_nCritters'][(entropy_bin, nCritters_bin)] < max_rows_per_bin:
        heatmap_bins['entropy_vs_nCritters'][(entropy_bin, nCritters_bin)] += 1
        meets_criteria = True

    if (rep_bin, nCritters_bin) not in heatmap_bins['representativeness_vs_nCritters']:
        heatmap_bins['representativeness_vs_nCritters'][(rep_bin, nCritters_bin)] = 0
    if heatmap_bins['representativeness_vs_nCritters'][(rep_bin, nCritters_bin)] < max_rows_per_bin:
        heatmap_bins['representativeness_vs_nCritters'][(rep_bin, nCritters_bin)] += 1
        meets_criteria = True

    # If the game meets criteria for any of the heatmaps, store the data
    if meets_criteria:
        data.append({
            'gameID': gameID,
            'players': players,  # Include player details
            'total_nRabbits': total_nRabbits,
            'total_nSquirrels': total_nSquirrels,
            'mleGame': mleGame,
            'total_nCritters': total_nCritters,
            'entropy': entropy,
            'representation': representation
        })
        print(f"Row {len(data)}: {data[-1]}")

# Save the results to a CSV file, converting players list to JSON strings
df = pd.DataFrame(data)

# Ensure that all player details are serializable and convert players list to JSON strings
df['players'] = df['players'].apply(lambda x: json.dumps(x, default=str))  # Convert list of dicts to JSON strings

# Save the DataFrame to a CSV file
df.to_csv('cover_range.csv', index=False)

print(f"Total attempts: {attempts}")
print(f"Total rows generated: {len(data)}")



