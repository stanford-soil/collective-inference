# Experiment 2: the models reported in the paper.
#
#   1. Error over rounds by condition
#   2. Difficulty model: does the condition difference depend on total sample size,
#      on how evenly the sample is split (entropy), or on how representative each
#      participant's sample is?
#
# Condition is effect coded (-0.5 chat, +0.5 slider), so a positive condition
# coefficient means higher error in the slider condition. The difficulty predictors
# are scaled 0-1 (higher = harder) and centered (see lib/exp2_data.R).
#
# Reads   data/derived/exp2_clean_data.csv
# Prints  the sample, the fixed effects of both models and the cell means
source("../lib/common.R")
source("../lib/exp2_data.R")

d <- load_exp2()$data

cat("==== Sample ====\n")
cat(n_distinct(d$playerID), "participants in", n_distinct(d$gameID), "networks;",
    n_distinct(d$playerID[!is.na(d$guess)]), "participants entered at least one estimate\n")
print(d %>% distinct(gameID, condition) %>% count(condition, name = "networks"))

# ---- 1. Error over rounds by condition --------------------------------------------------
m_condition <- fit(error ~ condition_c * idx_c + (1 + idx_c | gameID/playerID), d,
                   "Error over rounds by condition")
cat("\nMean error by condition (all rounds):\n")
print(d %>% group_by(condition) %>%
        summarise(mean_error = round(mean(error, na.rm = TRUE), 1), sd_error = round(sd(error, na.rm = TRUE), 1)))

# ---- 2. Difficulty model ------------------------------------------------------------------
m_difficulty <- fit(difficulty_model, d, "Difficulty model")

networks <- d %>% distinct(gameID, entropy_actual, representation_actual)
cat("\nCorrelation between entropy and representativeness across networks: r =",
    round(cor(networks$entropy_actual, networks$representation_actual, use = "complete.obs"), 2), "\n")

cat("\nMean error by representativeness (median split) and condition, all rounds:\n")
print(d %>% filter(!is.na(error)) %>%
        group_by(rep_bin, condition) %>%
        summarise(mean_error = round(mean(error), 1), sd_error = round(sd(error), 1), .groups = "drop"))
