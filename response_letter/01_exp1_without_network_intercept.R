# Response letter: the Experiment 1 models as in the original submission, without
# the network random intercept. The revised paper reports the versions with the
# network intercept (exp1/01_models.R and exp1/02_robustness.R); compare the two
# outputs to see what the intercept changes.
#
# Reads   data/derived/exp1_clean_data.csv, exp1_responders.csv
# Prints  the fixed effects of each model
source("../lib/common.R")
source("../lib/exp1_data.R")
suppressPackageStartupMessages(library(emmeans))

exp1 <- load_exp1()
revisions <- exp1$revisions %>%
  mutate(ss = as.numeric(scale(sample_size)),
         disc = as.numeric(scale(prior_social_discrepancy)),
         round = as.numeric(scale(idx)))

m1 <- fit(error ~ idx_c + I(idx_c^2) + (1 + idx_c | playerID),
          exp1$guesses, "M1: error over rounds")
m2 <- fit(error ~ idx * condition + (1 + idx | playerID),
          exp1$guesses, "M2: error over rounds by condition")
m3_formula <- error ~ poly(idx_final_centered, 2) * condition_interactive + (1 + idx_final_centered | playerID)
m3 <- fit(m3_formula, exp1$shifted, "M3: condition differences in the final round")
m4 <- fit(belief_revision ~ ss * disc + round + (1 + round | playerID),
          revisions, "M4: adaptive weighting")
m4b <- fit(belief_revision ~ ss * disc * condition + round + (1 + round | playerID),
           revisions, "M4b: adaptive weighting by condition (slider = reference)")
m5 <- fit(abs_change ~ idx_shifted * condition + (1 + idx_shifted | playerID),
          exp1$stabilization, "M5: change in estimate between rounds")
cat("\nM5: condition contrasts at the first observable change (round 2)\n")
print(contrast(emmeans(m5, ~ condition | idx_shifted, at = list(idx_shifted = 2)), "pairwise", adjust = "none"))

# ---- Robustness of M3 without the network intercept -----------------------------------
fit_m3 <- function(d, label) {
  coefs <- coef(summary(lmer(m3_formula, data = d, control = ctrl)))
  cat("\n==== ", label, ": ", n_distinct(d$playerID), " participants in ", n_distinct(d$gameID),
      " networks ====\n", sep = "")
  print(round(coefs[c("condition_interactiveslider", "condition_interactiveunidirectional"), ], 4))
}

responders <- load_exp1_responders()
response_rates <- exp1_response_rates(responders)
for (threshold in c(0, 0.5, 0.8, 1)) {
  kept <- response_rates %>% filter(response_rate >= threshold) %>% pull(playerID)
  fit_m3(responders %>% filter(playerID %in% kept) %>% align_rounds(),
         paste0("Answered at least ", 100 * threshold, "% of rounds"))
}

retained <- exp1$guesses %>% distinct(gameID, playerID) %>% count(gameID, name = "n_retained")
fit_m3(exp1$shifted %>% filter(gameID %in% retained$gameID[retained$n_retained == 4]),
       "Networks with exactly four retained participants")
