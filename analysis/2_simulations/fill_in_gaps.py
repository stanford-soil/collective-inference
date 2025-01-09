import random
import pandas as pd
import numpy as np

class GameFilter:
    def __init__(self, required_pairwise_matches=None):
        self.required_pairwise_matches = required_pairwise_matches or []

    def passes_criteria(self, game_metrics):
        for (var1, range1), (var2, range2) in self.required_pairwise_matches:
            if (
                var1 in game_metrics and var2 in game_metrics and
                any(min1 <= game_metrics[var1] <= max1 for min1, max1 in range1) and
                any(min2 <= game_metrics[var2] <= max2 for min2, max2 in range2)
            ):
                return True
        return False


def generate_game_data(n_games, rabbit_proportion=0.75, game_filter=None):
    data = []
    game_id = 1
    while len(data) < n_games * 4:
        total_critters = random.randint(15, 40)
        n_rabbits = int(total_critters * rabbit_proportion)
        critters = [1] * n_rabbits + [0] * (total_critters - n_rabbits)
        random.shuffle(critters)
        partitions = [0] + sorted(random.sample(range(1, total_critters), 3)) + [total_critters]
        player_subsets = [critters[partitions[i]:partitions[i+1]] for i in range(4)]
        player_data = []
        total_rabbits = sum([sum(subset) for subset in player_subsets])
        probs = [len(subset)/total_critters for subset in player_subsets]
        game_metrics = {
            'total_critters': total_critters,
            'entropy': -sum(p * np.log(p) if p > 0 else 0 for p in probs),
            'representation': np.mean([abs(sum(subset)/len(subset) - total_rabbits/total_critters)
                                        for subset in player_subsets])
        }
        if game_filter is None or game_filter.passes_criteria(game_metrics):
            for idx, subset in enumerate(player_subsets):
                player_data.append({
                    'gameID': game_id,
                    'playerID': (game_id - 1) * 4 + idx + 1,
                    'nRabbits': sum(subset),
                    'nSquirrels': len(subset) - sum(subset)
                })
            data.extend(player_data)
            game_id += 1
    return pd.DataFrame(data)

# Define specific pairs of ranges
pairwise_matches = [
    #missing in original generation
     (('representation', [(0, 0.12)]), ('entropy', [(0.27, 0.54)])),
      #(('representation', [(0.48, 0.6)]), ('entropy', [(0.27, 0.54)])),
       (('representation', [(0.36, 0.48)]), ('entropy', [(1.4, 1.6)])),
        (('representation', [(0.48, 0.6)]), ('entropy', [(1.4, 1.6)])),

    (('entropy', [(0.27, 0.54)]), ('total_critters', [(15, 20)])),

    #(('representation', [(0.48, 0.6)]), ('total_critters', [(25, 30)])),
     #(('representation', [(0.48, 0.6)]), ('total_critters', [(30, 35)])),
      #(('representation', [(0.48, 0.6)]), ('total_critters', [(35, 40)])),

    #missing in data (bc of game 10120)
    #(('representation', [(0.48, 0.6)]), ('total_critters', [(20, 25)])),
]

# Create the filter with pairwise ranges
game_filter = GameFilter(required_pairwise_matches=pairwise_matches)

# Generate game data
df = generate_game_data(10, 0.75, game_filter)

# Save DataFrame to CSV file
df.to_csv('game_results_2_FIXED_2.csv', index=False)

