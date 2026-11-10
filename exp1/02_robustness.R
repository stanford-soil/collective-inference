# Experiment 1: robustness of the final-round condition differences (model M3).
#
#   1. Other exclusion thresholds: no exclusion, 50%, 80% (preregistered) and 100% of rounds answered
#   2. Complete networks only: networks that kept exactly four participants
#   3. Networks launched with exactly four players (17 of 236 were launched with 2 to 9)
#
# Reads   data/derived/exp1_clean_data.csv, exp1_responders.csv, partner_schedule/exp1_partners.csv
# Prints  the condition coefficients for each subset (Appendix A)
source("../lib/common.R")
source("../lib/exp1_data.R")

exp1 <- load_exp1()
responders <- load_exp1_responders()

# Live messaging is the reference: the two condition coefficients are the
# final-round differences slider - live and batched - live.
m3_formula <- error ~ poly(idx_final_centered, 2) * condition_interactive +
  (1 + idx_final_centered | playerID) + (1 | gameID)

fit_m3 <- function(d, label) {
  model <- lmer(m3_formula, data = d, control = ctrl)
  coefs <- coef(summary(model))
  cat("\n==== ", label, ": ", n_distinct(d$playerID), " participants in ", n_distinct(d$gameID),
      " networks ====\n", sep = "")
  print(round(coefs[c("condition_interactiveslider", "condition_interactiveunidirectional"), ], 4))
}

# ---- 1. Exclusion thresholds -----------------------------------------------------------
response_rates <- exp1_response_rates(responders)
for (threshold in c(0, 0.5, 0.8, 1)) {
  kept <- response_rates %>% filter(response_rate >= threshold) %>% pull(playerID)
  fit_m3(responders %>% filter(playerID %in% kept) %>% align_rounds(),
         paste0("Answered at least ", 100 * threshold, "% of rounds"))
}

# ---- 2. Complete networks ----------------------------------------------------------------
retained <- exp1$guesses %>% distinct(gameID, playerID) %>% count(gameID, name = "n_retained")
fit_m3(exp1$shifted %>% filter(gameID %in% retained$gameID[retained$n_retained == 4]),
       "Networks with exactly four retained participants")

# ---- 3. Networks launched with four players ---------------------------------------------
launched <- read_csv(EXP1_PARTNERS, show_col_types = FALSE) %>% distinct(gameID, nPlayers)
cat("\nAnalysed networks by number of players at launch:\n")
print(exp1$guesses %>% distinct(gameID, condition) %>%
        left_join(launched, by = "gameID") %>%
        count(nPlayers, condition) %>%
        pivot_wider(names_from = condition, values_from = n, values_fill = 0))
fit_m3(exp1$shifted %>% filter(gameID %in% launched$gameID[launched$nPlayers == 4]),
       "Networks launched with four players")
