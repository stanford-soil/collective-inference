# Experiment 1 clean data: removes duplicated unidirectional rows, applies the
# preregistered exclusion (< 80% of rounds answered) and computes error.
# Input: data/exp1/PreregMergedGuesses.csv (prep/01_exp1_merge_raw.R).
# Output: data/derived/exp1_clean_data.csv (analysed sample) and
#   data/derived/exp1_responders.csv (all responders, before the exclusion).
# Run from prep/. Logic from the original analysis/exp1/exp1_main_analysis.qmd.
source("../lib/common.R")
source("../lib/exp1_data.R")
dir.create(repo_path("data", "derived"), showWarnings = FALSE)

d.raw <- read_csv(EXP1_MERGED, show_col_types = FALSE)
cat("PreregMergedGuesses.csv: games", n_distinct(d.raw$gameID),
    "| games with valid treatments", n_distinct(d.raw$gameID[!is.na(d.raw$treatmentName)]),
    "| participants", n_distinct(d.raw$playerID), "\n")

# Valid treatments only; unidirectional games have duplicated rows
uni <- c("rerun-unidirectional- 0.7", "rerun-unidirectional- 0.3")
d.pre <- d.raw %>% filter(!is.na(treatmentName))
ur <- d.pre %>% filter(treatmentName %in% uni) %>% distinct(playerID, gameID, guess, roundID, .keep_all = TRUE)
d.pre <- d.pre %>% filter(!(treatmentName %in% uni)) %>% bind_rows(ur)
cat("After removing duplicate rows:", n_distinct(d.pre$playerID), "participants in",
    n_distinct(d.pre$gameID), "games\n")

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
           condition = factor(condition, levels = condition_breaks)) %>%
    arrange(playerID, idx)
}

# Preregistered exclusion: fewer than 80% of the 12 rounds answered
exclude_prereg <- exp1_response_rates(d.pre) %>% filter(response_rate < 0.80) %>% pull(playerID)
cat("Excluded", length(exclude_prereg), "participants with <80% response rate\n")

d.guesses <- d.pre %>% filter(!(playerID %in% exclude_prereg)) %>% clean_names() %>%
  mutate(idx_c = idx - mean(idx))
cat("Final sample:", n_distinct(d.guesses$playerID), "participants in",
    n_distinct(d.guesses$gameID), "networks\n")
print(d.guesses %>% filter(idx == 1) %>% group_by(condition, treatment) %>%
        summarise(n_networks = n_distinct(gameID), n_participants = n_distinct(playerID), .groups = "drop"))

write_csv(d.guesses, EXP1_CLEAN)
write_csv(clean_names(d.pre), EXP1_RESPONDERS)
cat("Wrote", EXP1_CLEAN, "and", EXP1_RESPONDERS, "\n")
