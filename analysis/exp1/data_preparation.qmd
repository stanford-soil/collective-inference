---
title: "Experiment 1: Data Preparation Pipeline"
format: html
editor: visual
---

This notebook documents how the merged data file `PreregMergedGuesses.csv` was created from raw Empirica batch exports.

## Import packages

```{r, message=FALSE, warning=FALSE}
library(conflicted)
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")
library(tidyverse)
library(here)
library(jsonlite)

# Helper function to parse JSON columns
ParseJSONColumn <- function(x) {
  str_c("[ ", str_c(x, collapse = ",", sep=" "), " ]")  %>%
    fromJSON(flatten = T)
}
```

## Load raw batch files

Data were collected across 11 batches (prereg_1 through prereg_11).

```{r, message=FALSE, warning=FALSE}
# Get all batch directories
batch_dirs <- list.files(
  here('data/exp1/raw'),
  pattern = '^1_prereg_',
  full.names = TRUE
)

cat("Found", length(batch_dirs), "batch directories\n")

# Function to load data from a single batch
load_batch <- function(batch_dir) {
  batch_name <- basename(batch_dir)

  # Load games (for treatment assignments)
  games <- read_csv(file.path(batch_dir, 'games.csv'), show_col_types = FALSE) %>%
    select(gameID = id, treatmentName) %>%
    distinct()

  # Load players (for critter assignments)
  players <- read_csv(file.path(batch_dir, 'players.csv'), show_col_types = FALSE) %>%
    mutate(
      nSquirrels = str_count(emojiArray, '🐿️'),
      nRabbits = str_count(emojiArray, '🐇')
    ) %>%
    select(playerID = id, gameID, nSquirrels, nRabbits) %>%
    distinct()

  # Load rounds (for round indices)
  rounds <- read_csv(file.path(batch_dir, 'rounds.csv'), show_col_types = FALSE) %>%
    select(gameID, roundID = id, idx) %>%
    distinct()

  # Load player stages (the actual guesses)
  guesses <- read_csv(file.path(batch_dir, 'playerStages.csv'), show_col_types = FALSE) %>%
    filter(!is.na(guess)) %>%  # Only keep participants who provided guesses
    select(gameID, roundID, playerID, guess, confidence) %>%
    left_join(rounds, by = c("gameID", "roundID")) %>%
    left_join(games, by = "gameID") %>%
    left_join(players, by = c("gameID", "playerID")) %>%
    distinct() %>%
    mutate(batch = batch_name)

  return(guesses)
}

# Load all batches
all_batches <- map_df(batch_dirs, load_batch)

cat("\nRaw merged data:\n")
cat("  Total rows:", nrow(all_batches), "\n")
cat("  Unique participants:", n_distinct(all_batches$playerID), "\n")
cat("  Unique games:", n_distinct(all_batches$gameID), "\n")
```

## Report recruitment statistics

```{r, message=FALSE, warning=FALSE}
# Count participants in raw player files (before guess filter)
all_raw_players <- map_df(batch_dirs, function(batch_dir) {
  players_file <- file.path(batch_dir, 'players.csv')
  if(file.exists(players_file)) {
    df <- read_csv(players_file, show_col_types = FALSE)
    df$batch <- basename(batch_dir)
    return(df %>% select(playerID = id, gameID, batch))
  }
  return(NULL)
})

# Filter to only games that are in our merged data
valid_games <- unique(all_batches$gameID)
recruited_players <- all_raw_players %>%
  filter(gameID %in% valid_games) %>%
  distinct(playerID, gameID)

cat("\n=== RECRUITMENT & ATTRITION ===\n")
cat("Participants recruited (assigned to games):", n_distinct(recruited_players$playerID), "\n")
cat("Participants who provided ≥1 response:", n_distinct(all_batches$playerID), "\n")
cat("Participants who dropped out (no responses):",
    n_distinct(recruited_players$playerID) - n_distinct(all_batches$playerID), "\n")
cat("Attrition rate:",
    round(100 * (n_distinct(recruited_players$playerID) - n_distinct(all_batches$playerID)) /
          n_distinct(recruited_players$playerID), 1), "%\n\n")

cat("Games:\n")
cat("  Total games:", n_distinct(all_batches$gameID), "\n")
cat("  Games with valid treatments:",
    n_distinct(all_batches$gameID[!is.na(all_batches$treatmentName)]), "\n")
cat("  Games with NA treatment:",
    n_distinct(all_batches$gameID[is.na(all_batches$treatmentName)]), "\n")
```

## Handle duplicate rows

Some games have duplicate rows due to data export issues (particularly in unidirectional condition).
IMPORTANT: Remove duplicates BEFORE calculating game-level statistics to avoid inflated totals.

```{r}
# Check for duplicates
duplicates_before <- nrow(all_batches) - nrow(distinct(all_batches, playerID, gameID, roundID, guess))
cat("Duplicate rows found:", duplicates_before, "\n")

# Remove duplicates in unidirectional condition
unique_rows_unidirectional <- all_batches %>%
  filter(treatmentName %in% c("rerun-unidirectional- 0.7", "rerun-unidirectional- 0.3")) %>%
  distinct(playerID, gameID, guess, roundID, .keep_all = TRUE)

all_batches_dedup <- all_batches %>%
  filter(!(treatmentName %in% c("rerun-unidirectional- 0.7", "rerun-unidirectional- 0.3"))) %>%
  bind_rows(unique_rows_unidirectional)

cat("After removing duplicates:\n")
cat("  Total rows:", nrow(all_batches_dedup), "\n")
cat("  Participants:", n_distinct(all_batches_dedup$playerID), "\n")
cat("  Games:", n_distinct(all_batches_dedup$gameID), "\n")
```

## Calculate game-level statistics

Now calculate game totals from deduplicated data.

```{r}
# Calculate total critters per game (using deduplicated data)
d.merged <- all_batches_dedup %>%
  group_by(idx, gameID) %>%
  mutate(
    nRabbitsGame = sum(nRabbits, na.rm = TRUE),
    nSquirrelsGame = sum(nSquirrels, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    mleEstimateIndiv = floor((nRabbits / (nRabbits + nSquirrels)) * 100),
    mleEstimateIndiv = ifelse(is.na(mleEstimateIndiv), 50, mleEstimateIndiv),
    mleEstimateGame = floor((nRabbitsGame / (nRabbitsGame + nSquirrelsGame)) * 100)
  )

cat("Added game-level statistics from deduplicated data\n")
```

## Export merged files

```{r}
# Export filtered version (used for main analysis)
output_file <- here('data/exp1/PreregMergedGuesses.csv')
write_csv(d.merged, output_file)

cat("\nExported FILTERED data to:", output_file, "\n")
cat("  Participants:", n_distinct(d.merged$playerID), "\n")
cat("  Games:", n_distinct(d.merged$gameID), "\n")
cat("  Rows:", nrow(d.merged), "\n")

# Also export UNFILTERED version (includes NA guesses for diagnostics)
# Re-load without the !is.na(guess) filter
all_batches_unfiltered <- map_df(batch_dirs, function(batch_dir) {
  batch_name <- basename(batch_dir)

  games <- read_csv(file.path(batch_dir, 'games.csv'), show_col_types = FALSE) %>%
    select(gameID = id, treatmentName) %>%
    distinct()

  players <- read_csv(file.path(batch_dir, 'players.csv'), show_col_types = FALSE) %>%
    mutate(
      nSquirrels = str_count(emojiArray, '🐿️'),
      nRabbits = str_count(emojiArray, '🐇')
    ) %>%
    select(playerID = id, gameID, nSquirrels, nRabbits) %>%
    distinct()

  rounds <- read_csv(file.path(batch_dir, 'rounds.csv'), show_col_types = FALSE) %>%
    select(gameID, roundID = id, idx) %>%
    distinct()

  # NO filter on !is.na(guess) - keeps all rows
  guesses <- read_csv(file.path(batch_dir, 'playerStages.csv'), show_col_types = FALSE) %>%
    select(gameID, roundID, playerID, guess, confidence) %>%
    left_join(rounds, by = c("gameID", "roundID")) %>%
    left_join(games, by = "gameID") %>%
    left_join(players, by = c("gameID", "playerID")) %>%
    distinct() %>%
    mutate(batch = batch_name)

  return(guesses)
})

# Handle duplicates in unfiltered version (BEFORE calculating game stats)
unique_rows_unfiltered <- all_batches_unfiltered %>%
  filter(treatmentName %in% c("rerun-unidirectional- 0.7", "rerun-unidirectional- 0.3")) %>%
  distinct(playerID, gameID, guess, roundID, .keep_all = TRUE)

all_batches_unfiltered_dedup <- all_batches_unfiltered %>%
  filter(!(treatmentName %in% c("rerun-unidirectional- 0.7", "rerun-unidirectional- 0.3"))) %>%
  bind_rows(unique_rows_unfiltered)

# Calculate game-level statistics from deduplicated unfiltered data
d.merged_unfiltered <- all_batches_unfiltered_dedup %>%
  group_by(idx, gameID) %>%
  mutate(
    nRabbitsGame = sum(nRabbits, na.rm = TRUE),
    nSquirrelsGame = sum(nSquirrels, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    mleEstimateIndiv = floor((nRabbits / (nRabbits + nSquirrels)) * 100),
    mleEstimateIndiv = ifelse(is.na(mleEstimateIndiv), 50, mleEstimateIndiv),
    mleEstimateGame = floor((nRabbitsGame / (nRabbitsGame + nSquirrelsGame)) * 100)
  )

# Export unfiltered version
output_file_unfiltered <- here('data/exp1/PreregMergedGuesses_UNFILTERED.csv')
write_csv(d.merged_unfiltered, output_file_unfiltered)

cat("\nExported UNFILTERED data to:", output_file_unfiltered, "\n")
cat("  Participants:", n_distinct(d.merged_unfiltered$playerID), "\n")
cat("  Games:", n_distinct(d.merged_unfiltered$gameID), "\n")
cat("  Rows:", nrow(d.merged_unfiltered), "\n")
cat("  NA guesses:", sum(is.na(d.merged_unfiltered$guess)), "\n")
```

## Summary

This pipeline:

1. **Loaded** 11 batch directories from `data/exp1/raw/`
2. **Recruited** N=973 participants assigned to N=237 games
3. **Attrition** N=83 participants (8.5%) dropped out without responding
4. **Merged** data from N=890 participants who provided ≥1 response
5. **Removed** duplicate rows from unidirectional condition
6. **Exported TWO versions:**
   - `PreregMergedGuesses.csv` - **Filtered** (N=890, only participants who responded) - used for main analysis
   - `PreregMergedGuesses_UNFILTERED.csv` - **Unfiltered** (N=973, includes dropouts) - used for diagnostics

The filtered file is used by `exp1_main_analysis.qmd` for all statistical analyses reported in the manuscript.
