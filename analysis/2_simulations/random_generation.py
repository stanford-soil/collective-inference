import random
import pandas as pd

# List to store results
data = []

# Generate data for 100000 players (4 players per game, 25000 games)
for game_id in range(1, 25001):
    # Create a random-sized list of critters for the game (15-35 critters, 70% rabbits)
    total_critters = random.randint(15, 40)
    if total_critters < 15:  # Extra safeguard to skip cases with fewer than 15 critters
        continue
    n_rabbits = int(total_critters * 0.75)
    critters = [1] * n_rabbits + [0] * (total_critters - n_rabbits)
    random.shuffle(critters)  # Shuffle to randomize rabbit and squirrel positions

    # Split critters list into 4 random, non-empty chunks
    partitions = [0] + sorted(random.sample(range(1, total_critters), 3)) + [total_critters]
    player_subsets = [critters[partitions[i]:partitions[i+1]] for i in range(4)]

    # Convert each subset to nRabbits and nSquirrels for each player
    for player_idx, subset in enumerate(player_subsets, start=1):
        player_id = (game_id - 1) * 4 + player_idx
        n_rabbits_player = sum(subset)
        n_squirrels_player = len(subset) - n_rabbits_player

        # Append the result to the list
        data.append({
            'gameID': game_id,
            'playerID': player_id,
            'nRabbits': n_rabbits_player,
            'nSquirrels': n_squirrels_player
        })

# Create DataFrame
df = pd.DataFrame(data)

# Save DataFrame to CSV file
df.to_csv('game_results_fixed.csv', index=False)

