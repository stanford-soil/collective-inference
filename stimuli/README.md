# Experiment 2 Stimuli Generation

This directory contains scripts for generating game stimuli for Experiment 2, which manipulated information quality along three dimensions: total critter count, entropy (distribution across players), and representation (how well individual samples reflect the true distribution).

## Directory Structure

### `exp2_random_game_generation/`
Initial random generation of 100,000 simulated games (25,000 games × 4 players).

- `random_generation.py`: Generates games with 15-40 critters per game, 75% rabbit probability, randomly distributed across 4 players
- Outputs: `game_results_fixed_075.csv`, `games.csv`, `games.json`
- `combined_and_game_generation.qmd`: Analysis script that reads the random generation output

### `exp2_missing_game_generation/`
Targeted generation to fill gaps in the design space.

- `fill_in_gaps.py`: Generates additional games targeting specific rare combinations of:
  - Entropy (information distribution across players)
  - Representation (how well individual samples match the true distribution)
  - Total critter count
- Outputs: `games_2.csv`, `games_2.json`
- `merge jsons.qmd`: Combines targeted games with random generation
- `results_2_confirmation.qmd`: Validates the combined dataset

### `exp2_combined_generation/`
Final stimuli combining random and targeted generation.

- `combined_and_game_generation.qmd`: Combines outputs from both generation methods
- `generated_files_used/`: Final stimuli files used in the actual experiment
  - `games_dontoverwrite.csv/json`: Original random generation
  - `games_2_dontoverwrite.csv/json`: Targeted generation
  - `game_results_2_FIXED.csv`: Combined final dataset

## Workflow

1. Run `exp2_random_game_generation/random_generation.py` to generate initial large-scale simulation
2. Analyze the distribution to identify gaps in the design space
3. Run `exp2_missing_game_generation/fill_in_gaps.py` to generate targeted games for rare combinations
4. Use `exp2_combined_generation/combined_and_game_generation.qmd` to merge and prepare final stimuli
5. Final stimuli stored in `exp2_combined_generation/generated_files_used/`
