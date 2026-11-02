# Shared data preparation for Exp 1, copied verbatim (logic) from
# analysis/exp1/exp1_main_analysis.qmd. Sourced by the other scripts.
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(stringr)
  library(lme4); library(lmerTest)
})
REPO <- "../.."

uni <- c("rerun-unidirectional- 0.7", "rerun-unidirectional- 0.3")
clean_names <- function(d) {
  d %>%
    mutate(treatmentName = case_when(
      treatmentName == "rerun-unidirectional- 0.7" ~ 'unidirectional-0.7',
      treatmentName == "rerun-unidirectional- 0.3" ~ 'unidirectional-0.3',
      treatmentName == "rerun-interactive-0.3" ~ 'interactive-0.3',
      treatmentName == "rerun-interactive- 0.7" ~ 'interactive-0.7',
      treatmentName == "rerun-slider- 0.3" ~ 'slider-0.3',
      treatmentName == "rerun-slider- 0.7" ~ 'slider-0.7',
      TRUE ~ treatmentName)) %>%
    separate(treatmentName, into = c('condition', 'treatment'), sep = '-') %>%
    mutate(error = abs(guess - mleEstimateGame),
           condition = factor(condition, levels = c("slider", "unidirectional", "interactive"))) %>%
    arrange(playerID, idx)
}

d.raw <- suppressMessages(read_csv(file.path(REPO, 'data/exp1/PreregMergedGuesses.csv'), show_col_types = FALSE))

d.pre <- d.raw %>% filter(!is.na(treatmentName))
ur <- d.pre %>% filter(treatmentName %in% uni) %>% distinct(playerID, gameID, guess, roundID, .keep_all = TRUE)
d.pre <- d.pre %>% filter(!(treatmentName %in% uni)) %>% bind_rows(ur)

response_rates <- d.pre %>% group_by(playerID) %>%
  summarise(response_rate = n_distinct(idx) / 12, .groups = "drop")

# d.pre = all responders with valid treatment, before the 80% exclusion
d.pre.clean <- clean_names(d.pre)

exclude_prereg <- response_rates %>% filter(response_rate < 0.80) %>% pull(playerID)
d.guesses <- d.pre %>% filter(!(playerID %in% exclude_prereg)) %>% clean_names()

make_shifted <- function(d) {
  d %>% mutate(
    idx_shifted = if_else(condition == "slider", idx - 1, idx),
    idx_final_centered = if_else(condition == "slider", idx_shifted - 11, idx_shifted - 12),
    condition_interactive = relevel(condition, ref = "interactive"))
}
d.shifted <- make_shifted(d.guesses)

d.guesses <- d.guesses %>% mutate(idx_c = idx - mean(idx))

# Adaptive-weighting data
d.revisions <- d.guesses %>%
  group_by(playerID, gameID) %>% mutate(sample_size = nRabbits + nSquirrels) %>% ungroup() %>%
  group_by(gameID, idx) %>%
  mutate(others_mean_estimate = (sum(guess) - guess) / (n() - 1),
         social_discrepancy = abs(guess - others_mean_estimate)) %>% ungroup() %>%
  arrange(playerID, idx) %>% group_by(playerID) %>%
  mutate(belief_revision = abs(guess - lag(guess)),
         prior_social_discrepancy = lag(social_discrepancy)) %>% ungroup() %>%
  filter(!is.na(belief_revision), !is.na(prior_social_discrepancy))

# Stabilization data
d.stabilization <- d.shifted %>% filter(idx_shifted >= 1) %>%
  arrange(playerID, idx_shifted) %>% group_by(playerID) %>%
  mutate(abs_change = abs(guess - lag(guess))) %>% ungroup() %>%
  filter(!is.na(abs_change))

ctrl <- lmerControl(optimizer = "bobyqa")
