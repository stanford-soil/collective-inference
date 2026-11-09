# Experiment 1 analysis data, built from the clean data written by prep/01_exp1_clean.R.
# Source after lib/common.R.
#
#   exp1 <- load_exp1()
#   exp1$guesses        one row per participant and round (the analysed sample)
#   exp1$shifted        the same, with rounds aligned across conditions
#   exp1$revisions      change in estimate and previous-round social discrepancy (model M4)
#   exp1$stabilization  change in estimate between consecutive rounds (model M5)

read_exp1 <- function(path) {
  read_csv(path, show_col_types = FALSE) %>%
    mutate(condition = factor(condition, levels = condition_breaks)) %>%
    arrange(playerID, idx)
}

# In the slider condition the round-1 estimate is made before any social information,
# so slider rounds are shifted down by one. idx_final_centered is 0 in the last
# round of each condition. Real-time messaging is the reference condition.
align_rounds <- function(d) {
  d %>% mutate(
    idx_shifted = if_else(condition == "slider", idx - 1, idx),
    idx_final_centered = if_else(condition == "slider", idx_shifted - 11, idx_shifted - 12),
    condition_interactive = relevel(condition, ref = "interactive"))
}

load_exp1 <- function() {
  guesses <- read_exp1(EXP1_CLEAN)
  shifted <- align_rounds(guesses)

  # Social discrepancy: distance between a participant's estimate and the mean
  # estimate of the other network members in the same round.
  # Belief revision: absolute change from the participant's previous estimate.
  revisions <- guesses %>%
    mutate(sample_size = nRabbits + nSquirrels) %>%
    group_by(gameID, idx) %>%
    mutate(others_mean_estimate = (sum(guess) - guess) / (n() - 1),
           social_discrepancy = abs(guess - others_mean_estimate)) %>%
    ungroup() %>%
    arrange(playerID, idx) %>%
    group_by(playerID) %>%
    mutate(belief_revision = abs(guess - lag(guess)),
           prior_social_discrepancy = lag(social_discrepancy)) %>%
    ungroup() %>%
    filter(!is.na(belief_revision), !is.na(prior_social_discrepancy))

  # Change in estimate between consecutive rounds with social information
  # (the slider's pre-social round is excluded).
  stabilization <- shifted %>%
    filter(idx_shifted >= 1) %>%
    arrange(playerID, idx_shifted) %>%
    group_by(playerID) %>%
    mutate(abs_change = abs(guess - lag(guess))) %>%
    ungroup() %>%
    filter(!is.na(abs_change))

  list(guesses = guesses, shifted = shifted, revisions = revisions, stabilization = stabilization)
}

# All participants with at least one estimate, before the 80% response-rate exclusion.
load_exp1_responders <- function() read_exp1(EXP1_RESPONDERS)

# Share of the 12 rounds each participant answered (preregistered exclusion: below 80%).
exp1_response_rates <- function(d) {
  d %>% group_by(playerID) %>% summarise(response_rate = n_distinct(idx) / 12, .groups = "drop")
}
