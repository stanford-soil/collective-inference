# Experiment 1 analysis data sets, built from the clean data written by
# prep/02_exp1_clean.R. Sourced after lib/common.R.
#   load_exp1()        -> list(d.guesses, d.shifted, d.revisions, d.stabilization)
#   load_exp1_responders() -> all responders before the 80% response-rate exclusion
# The constructions follow the original Experiment 1 notebook (Analyses 1-5).

exp1_read <- function(path) {
  read_csv(path, show_col_types = FALSE) %>%
    mutate(condition = factor(condition, levels = condition_breaks)) %>%
    arrange(playerID, idx)
}

# Slider round 1 is the estimate made before any social information, so the slider
# rounds are shifted down by one. idx_final_centered is 0 in each condition's last round.
make_shifted <- function(d) {
  d %>% mutate(
    idx_shifted = if_else(condition == "slider", idx - 1, idx),
    idx_final_centered = if_else(condition == "slider", idx_shifted - 11, idx_shifted - 12),
    condition_interactive = relevel(condition, ref = "interactive"))
}

load_exp1 <- function(path = EXP1_CLEAN) {
  d.guesses <- exp1_read(path)
  d.shifted <- make_shifted(d.guesses)

  # Adaptive weighting (Analysis 4): belief revision against the previous round's
  # distance from the other network members' mean estimate
  d.revisions <- d.guesses %>%
    group_by(playerID, gameID) %>% mutate(sample_size = nRabbits + nSquirrels) %>% ungroup() %>%
    group_by(gameID, idx) %>%
    mutate(others_mean_estimate = (sum(guess) - guess) / (n() - 1),
           social_discrepancy = abs(guess - others_mean_estimate)) %>% ungroup() %>%
    arrange(playerID, idx) %>% group_by(playerID) %>%
    mutate(belief_revision = abs(guess - lag(guess)),
           prior_social_discrepancy = lag(social_discrepancy)) %>% ungroup() %>%
    filter(!is.na(belief_revision), !is.na(prior_social_discrepancy))

  # Stabilization (Analysis 5): change in estimate between consecutive rounds with
  # social information (the slider's pre-social round is excluded)
  d.stabilization <- d.shifted %>% filter(idx_shifted >= 1) %>%
    arrange(playerID, idx_shifted) %>% group_by(playerID) %>%
    mutate(abs_change = abs(guess - lag(guess))) %>% ungroup() %>%
    filter(!is.na(abs_change))

  list(d.guesses = d.guesses, d.shifted = d.shifted,
       d.revisions = d.revisions, d.stabilization = d.stabilization)
}

load_exp1_responders <- function(path = EXP1_RESPONDERS) exp1_read(path)

# Response rate per participant (preregistered exclusion: < 80% of the 12 rounds)
exp1_response_rates <- function(d) {
  d %>% group_by(playerID) %>% summarise(response_rate = n_distinct(idx) / 12, .groups = "drop")
}
