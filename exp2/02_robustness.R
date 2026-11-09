# Experiment 2: robustness of the condition x representativeness interaction (Appendix C).
#
# The difficulty model of the main text is refitted
#   1. without participants who answered fewer than 80% of the 8 rounds
#      (the exclusion criterion of Experiment 1), and
#   2. without estimates of exactly 0, 50 or 100.
#
# Reads   data/derived/exp2_clean_data.csv
# Prints  the fixed effects of each refit, and the response rates by condition
source("../lib/common.R")
source("../lib/exp2_data.R")

exp2 <- load_exp2()
d <- exp2$data

fit_difficulty <- function(data, label) {
  with_estimate <- data %>% filter(!is.na(error))
  fit(difficulty_model, data, paste0(label, " (", n_distinct(with_estimate$playerID), " participants in ",
                                     n_distinct(with_estimate$gameID), " networks)"))
}
fit_difficulty(d, "Main analysis")

# ---- 1. Response-rate exclusion -----------------------------------------------------------
# Share of the 8 rounds answered, counting the slider condition's first (pre-social) round.
response_rates <- bind_rows(d, exp2$slider_baseline) %>%
  group_by(playerID, condition) %>%
  summarise(response_rate = sum(!is.na(guess)) / 8, .groups = "drop") %>%
  mutate(answered_80 = response_rate >= 0.80)

cat("\nParticipants who answered at least 80% of rounds, by condition:\n")
print(table(response_rates$condition, response_rates$answered_80))
print(chisq.test(table(response_rates$condition, response_rates$answered_80)))

d_80 <- d %>% filter(playerID %in% response_rates$playerID[response_rates$answered_80])
fit_difficulty(d_80, "Answered at least 80% of rounds")

cat("\nMean error by representativeness and condition after the exclusion:\n")
print(d_80 %>% group_by(rep_bin, condition) %>%
        summarise(mean_error = round(mean(error, na.rm = TRUE), 1), .groups = "drop"))

# ---- 2. Without estimates of 0, 50 or 100 -------------------------------------------------
fit_difficulty(d %>% filter(!guess %in% c(0, 50, 100)), "Estimates of 0, 50 and 100 removed")
