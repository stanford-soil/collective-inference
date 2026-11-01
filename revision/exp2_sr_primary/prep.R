## -----------------------------------------------------------------------------
#| label: setup
#| message: false
#| warning: false

library(conflicted)
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")

library(tidyverse)
library(lme4)
library(lmerTest)
conflicts_prefer(lmerTest::lmer)
library(here)


# Colors for conditions
condition_colors <- c("slider" = "#E69F00", "interactive" = "#009E73")  # Match Exp 1 palette


## -----------------------------------------------------------------------------
#| label: load-data
#| message: false

# Load clean data (produced by 1_data_cleaning.qmd)
d.all <- read_csv('../../analysis/exp2/exp2_clean_data.csv', show_col_types=FALSE) %>% (function(d){ s<-Sys.getenv('SUBSET'); if(s=='SR') d<-dplyr::filter(d, grepl('^SR_',treatmentName.x)); if(s=='RS') d<-dplyr::filter(d, grepl('^RS_',treatmentName.x)); d })

# Derive condition and direction from treatmentName
d.all <- d.all %>%
  mutate(
    condition = ifelse(str_detect(treatmentName.x, "interactive"), "interactive", "slider"),
    direction = ifelse(str_detect(treatmentName.x, "^RS_"), "RS", "SR")
  )

# Shift slider index so round 1 = first round with social information
# In slider condition, round 1 is the initial guess BEFORE seeing others' numbers
# In chat condition, round 1 already includes discussion
# This aligns the conditions for fair comparison

# Create shifted index (baseline will be saved AFTER error is computed below)
d.all <- d.all %>%
  mutate(
    idx_shifted = if_else(condition == "slider", idx - 1, idx)
  )

cat("=== DATA SUMMARY (Intent-to-Treat, with index shift) ===\n")
cat("Participants:", n_distinct(d.all$playerID), "\n")
cat("Games:", n_distinct(d.all$gameID), "\n")
cat("Observations:", nrow(d.all), "\n")

# Check conditions
cat("\nBy condition:\n")
d.all %>%
  distinct(gameID, condition) %>%
  count(condition) %>%
  print()


## -----------------------------------------------------------------------------
#| label: actual-network-metrics

# Identify active players (those who responded)
active_players <- d.all %>%
  filter(!is.na(guess)) %>%
  distinct(gameID, playerID, nCritters, nRabbits, nSquirrels)

cat("Active players per game:\n")
active_players %>%
  count(gameID, name = "n_active") %>%
  count(n_active) %>%
  print()

# Recompute game-level metrics based on active players
game_metrics_actual <- active_players %>%
  group_by(gameID) %>%
  summarise(
    n_active_players = n(),
    nCrittersGame_actual = sum(nCritters),
    nRabbitsGame_actual = sum(nRabbits),
    mleGame_actual = nRabbitsGame_actual / nCrittersGame_actual,
    .groups = "drop"
  )

# Entropy based on active players
entropy_actual <- active_players %>%
  group_by(gameID) %>%
  mutate(
    total_critters = sum(nCritters),
    p_i = nCritters / total_critters
  ) %>%
  summarise(
    entropy_actual = -sum(p_i * log(p_i + 1e-10)),
    .groups = "drop"
  )

# Representativeness: use the existing column from the data
# This is mean |individual_MLE - collective_MLE|, measuring how misleading individual samples are
# (NOT |mle - 0.5| which measures distance from 50%)
game_metrics_actual <- game_metrics_actual %>%
  left_join(entropy_actual, by = "gameID") %>%
  left_join(
    d.all %>% distinct(gameID, representation) %>% rename(representation_actual = representation),
    by = "gameID"
  )

# Merge back to all participants
d.all <- d.all %>%
  left_join(game_metrics_actual, by = "gameID")

# CRITICAL: Align MLE for direction
# In RS direction games, the majority was squirrels, but participants still report % rabbits
# So the "true" network MLE needs to be inverted for RS games
d.all <- d.all %>%
  mutate(
    mleGame_aligned = ifelse(direction == "RS", 1 - mleGame_actual, mleGame_actual)
  )

cat("\nActual network metrics computed for", n_distinct(game_metrics_actual$gameID), "games\n")
cat("Direction distribution:\n")
d.all %>%
  distinct(gameID, direction) %>%
  count(direction) %>%
  print()


## -----------------------------------------------------------------------------
#| label: compute-error

# Compute absolute error from ALIGNED network MLE
# This accounts for direction (RS games have inverted MLE)
d.all <- d.all %>%
  mutate(error = abs(guess - mleGame_aligned * 100))

# Now save slider's baseline (pre-social, idx_shifted=0) for visualization
d.slider_baseline <- d.all %>%
  filter(condition == "slider", idx_shifted == 0)

# Filter to only include rounds with social information (idx_shifted >= 1)
d.all <- d.all %>%
  filter(idx_shifted >= 1)

cat("Error summary:\n")
summary(d.all$error)

# Check for magnet values
cat("\nMagnet value frequencies:\n")
d.all %>%
  filter(!is.na(error)) %>%
  mutate(is_magnet = guess %in% c(0, 50, 100)) %>%
  count(condition, is_magnet) %>%
  group_by(condition) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  print()


## -----------------------------------------------------------------------------
#| label: create-bins

# Median split on each difficulty dimension (using actual network metrics)
d.all <- d.all %>%
  mutate(
    # Median splits for easy/hard classification
    critters_easy = nCrittersGame_actual >= median(nCrittersGame_actual, na.rm = TRUE),
    entropy_easy = entropy_actual >= median(entropy_actual, na.rm = TRUE),
    rep_easy = representation_actual <= median(representation_actual, na.rm = TRUE),  # Lower = easier

    # Create combined difficulty profile
    difficulty_profile = paste0(
      ifelse(critters_easy, "E", "H"),  # Critters
      ifelse(entropy_easy, "E", "H"),   # Entropy
      ifelse(rep_easy, "E", "H")        # Representativeness
    ),

    # Count hard dimensions
    n_hard = (!critters_easy) + (!entropy_easy) + (!rep_easy),

    # Create factor bins for plotting
    critters_bin = factor(ifelse(critters_easy, "Many", "Few"), levels = c("Few", "Many")),
    entropy_bin = factor(ifelse(entropy_easy, "High", "Low"), levels = c("Low", "High")),
    rep_bin = factor(ifelse(rep_easy, "Representative", "Unrepresentative"),
                     levels = c("Representative", "Unrepresentative"))
  )

cat("Difficulty profile distribution:\n")
d.all %>%
  distinct(gameID, difficulty_profile) %>%
  count(difficulty_profile) %>%
  arrange(desc(n)) %>%
  print()

# Add difficulty bins to slider baseline data (for plotting)
d.slider_baseline <- d.slider_baseline %>%
  left_join(
    d.all %>% distinct(gameID, n_hard, critters_bin, entropy_bin, rep_bin),
    by = "gameID"
  )


## -----------------------------------------------------------------------------
#| label: effect-coding

# Effect coding for all analyses
# Condition: -0.5 = chat, +0.5 = slider
# Difficulty: scaled 0-1 and mean-centered (continuous predictors)

# First, verify the difficulty dimensions are continuous (not factorial design)
cat("=== DIFFICULTY DIMENSION DISTRIBUTIONS ===\n")
game_difficulty <- d.all %>%
  distinct(gameID, nCrittersGame_actual, entropy_actual, representation_actual)
cat("Sample size: ", n_distinct(game_difficulty$nCrittersGame_actual), "unique values\n")
cat("Entropy: ", n_distinct(round(game_difficulty$entropy_actual, 3)), "unique values\n")
cat("Representativeness: ", n_distinct(round(game_difficulty$representation_actual, 3)), "unique values\n")
cat("Total unique combinations:", nrow(game_difficulty), "(vs 8 expected for 2×2×2 factorial)\n\n")
cat("Since difficulty dimensions are CONTINUOUS, we use centered continuous predictors.\n\n")

d.all <- d.all %>%
  mutate(
    # Effect-coded condition
    condition_c = ifelse(condition == "slider", 0.5, -0.5),
    idx_c = idx_shifted - mean(idx_shifted, na.rm = TRUE),

    # Scale difficulty to 0-1 range, then mean-center
    # Higher values = MORE DIFFICULT for all three
    critters_scaled = 1 - (nCrittersGame_actual - min(nCrittersGame_actual, na.rm = TRUE)) /
                          (max(nCrittersGame_actual, na.rm = TRUE) - min(nCrittersGame_actual, na.rm = TRUE)),  # Fewer = harder
    entropy_scaled = 1 - (entropy_actual - min(entropy_actual, na.rm = TRUE)) /
                         (max(entropy_actual, na.rm = TRUE) - min(entropy_actual, na.rm = TRUE)),  # Lower entropy = harder
    rep_scaled = (representation_actual - min(representation_actual, na.rm = TRUE)) /
                 (max(representation_actual, na.rm = TRUE) - min(representation_actual, na.rm = TRUE)),  # Higher = harder (less representative)

    # Mean-center
    critters_c = critters_scaled - mean(critters_scaled, na.rm = TRUE),
    entropy_c = entropy_scaled - mean(entropy_scaled, na.rm = TRUE),
    rep_c = rep_scaled - mean(rep_scaled, na.rm = TRUE)
  )

cat("Effect coding applied:\n")
cat("  condition_c: chat = -0.5, slider = +0.5\n")
cat("  idx_c: centered at mean round\n")
