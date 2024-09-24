import random
import pandas as pd

# Binomial function to simulate flips
def binomial(p, n):
    flips = [random.random() < p for _ in range(n)]
    return sum(flips)

# List to store results
data = []

# Generate data for 1000 players (4 players per game, 250 games)
for i in range(1000):
    gameID = (i // 4) + 1  # Each 4 players have the same gameID
    playerID = i + 1
    trueP = 0.7 if i < 500 else 0.3  # Treatment: 0.7 for first 500, 0.3 for second 500
    n = random.randint(0, 9)  # Random number of total animals
    nRabbits = binomial(trueP, n)
    nSquirrels = n - nRabbits
    
    # Append the result to the list
    data.append({
        'gameID': gameID,
        'playerID': playerID,
        'nRabbits': nRabbits,
        'nSquirrels': nSquirrels
    })

# Create DataFrame
df = pd.DataFrame(data)

# Save DataFrame to CSV file
df.to_csv('game_results.csv', index=False)

print("File 'game_results.csv' generated with 1000 examples.")

