# Experiment 1 with the scoring target of the original submission.
#
# In the original submission each estimate was scored against the percentage of rabbits
# in the combined sample of the members who entered an estimate in the same round, so the
# target of a network could change from round to round. The revised paper uses one target
# per network: the combined sample of the members who entered at least one estimate
# (prep/01_exp1_clean.R), as in Experiment 2. This script shows the final-round model
# with the original target, with and without the network random intercept; the version
# without it reproduces the original submission.
#
# Reads   data/exp1/PreregMergedGuesses.csv, data/derived/exp1_clean_data.csv
# Prints  how often the two targets differ, and the final-round model with the original target
source("../lib/common.R")
source("../lib/exp1_data.R")

exp1 <- load_exp1()

# The original target: summed over the members with an estimate in that round
round_targets <- read_csv(EXP1_MERGED, show_col_types = FALSE) %>%
  group_by(gameID, idx) %>%
  summarise(rabbits = sum(nRabbits, na.rm = TRUE), squirrels = sum(nSquirrels, na.rm = TRUE), .groups = "drop") %>%
  mutate(round_target = floor(100 * rabbits / (rabbits + squirrels)))

data <- exp1$shifted %>%
  left_join(round_targets %>% select(gameID, idx, round_target), by = c("gameID", "idx")) %>%
  mutate(error_round_target = abs(guess - round_target))

cat("Observations in which the two targets are equal:",
    round(mean(data$round_target == data$mleEstimateGame), 3), "\n")
cat("Mean absolute difference between the two targets (percentage points):",
    round(mean(abs(data$round_target - data$mleEstimateGame)), 2), "\n")
cat("Analysed networks in which the original target changed across rounds:",
    data %>% group_by(gameID) %>% summarise(changed = n_distinct(round_target) > 1) %>% pull(changed) %>% sum(),
    "of", n_distinct(data$gameID), "\n")

fit(error_round_target ~ poly(idx_final_centered, 2) * condition_interactive +
      (1 + idx_final_centered | playerID) + (1 | gameID),
    data, "Original target, with the network random intercept")
fit(error_round_target ~ poly(idx_final_centered, 2) * condition_interactive +
      (1 + idx_final_centered | playerID),
    data, "Original target, without the network random intercept (original submission)")

cat("\nFinal-round error by condition, original target:\n")
data %>% filter(idx_final_centered == 0) %>%
  group_by(condition) %>%
  summarise(mean_error = mean(error_round_target), n = n(), .groups = "drop") %>%
  as.data.frame() %>% print()
