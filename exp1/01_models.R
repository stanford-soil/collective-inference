# Experiment 1: the models reported in the paper.
#
#   M1  error decreases over rounds
#   M2  error over rounds by condition
#   M3  condition differences in the final round
#   M4  adaptive weighting: belief revision by own sample size and social discrepancy
#   M4b adaptive weighting by condition
#   M5  stabilization: change in estimate between consecutive rounds, by condition
#
# Every model has random intercepts for participants and for networks.
# Condition names: slider, unidirectional (batched messaging), interactive (live messaging).
#
# Reads   data/derived/exp1_clean_data.csv
# Prints  the fixed effects of each model and the follow-up tests
source("../lib/common.R")
source("../lib/exp1_data.R")
suppressPackageStartupMessages(library(emmeans))

exp1 <- load_exp1()
cat("Sample:", n_distinct(exp1$guesses$playerID), "participants in",
    n_distinct(exp1$guesses$gameID), "networks\n")

# ---- M1: error over rounds (centered linear and quadratic terms) ---------------------
m1 <- fit(error ~ idx_c + I(idx_c^2) + (1 + idx_c | playerID) + (1 | gameID),
          exp1$guesses, "M1: error over rounds")

# ---- M2: error over rounds by condition (slider = reference) --------------------------
m2 <- fit(error ~ idx * condition + (1 + idx | playerID) + (1 | gameID),
          exp1$guesses, "M2: error over rounds by condition")

# ---- M3: condition differences in the final round -------------------------------------
# idx_final_centered is 0 in each condition's last round, so the condition
# coefficients are differences in the final round. Live messaging = reference.
m3_formula <- error ~ poly(idx_final_centered, 2) * condition_interactive +
  (1 + idx_final_centered | playerID) + (1 | gameID)
m3 <- fit(m3_formula, exp1$shifted, "M3: condition differences in the final round")

cat("\nM3: likelihood-ratio test of the condition x round interaction\n")
m3_ml <- lmer(m3_formula, data = exp1$shifted, control = ctrl, REML = FALSE)
m3_no_interaction <- update(m3_ml, . ~ . - poly(idx_final_centered, 2):condition_interactive)
print(anova(m3_no_interaction, m3_ml))

cat("\nFinal-round error by condition:\n")
print(exp1$shifted %>%
        filter(idx_final_centered == 0) %>%
        group_by(condition) %>%
        summarise(mean_error = mean(error), se_error = sd(error) / sqrt(n()), n = n()))

# ---- M4: adaptive weighting -------------------------------------------------------------
# ss = own sample size, disc = previous-round distance from the other members' mean
# estimate, round = round number; all standardized.
revisions <- exp1$revisions %>%
  mutate(ss = as.numeric(scale(sample_size)),
         disc = as.numeric(scale(prior_social_discrepancy)),
         round = as.numeric(scale(idx)))
m4 <- fit(belief_revision ~ ss * disc + round + (1 + round | playerID) + (1 | gameID),
          revisions, "M4: adaptive weighting")

# ---- M4b: adaptive weighting by condition ----------------------------------------------
# The same model with condition interactions, fitted once with each condition as the
# reference. For the reference condition, `disc` is the weight on social discrepancy
# and `ss:disc` is how that weight changes with sample size; the `:condition` rows
# are differences from the reference condition.
m4b_formula <- belief_revision ~ ss * disc * condition + round + (1 + round | playerID) + (1 | gameID)
for (reference in c("interactive", "slider", "unidirectional")) {
  d <- revisions %>% mutate(condition = relevel(factor(as.character(condition)), ref = reference))
  coefs <- coef(summary(lmer(m4b_formula, data = d, control = ctrl)))
  cat("\n==== M4b: adaptive weighting by condition, reference =", reference, "====\n")
  print(round(coefs[grepl("^disc|^ss:disc", rownames(coefs)), ], 4))
}

cat("\nM4b: likelihood-ratio tests of the condition interactions\n")
m4b_ml <- lmer(m4b_formula, data = revisions, control = ctrl, REML = FALSE)
m4b_no_three_way <- update(m4b_ml, . ~ . - ss:disc:condition)
m4b_no_two_way <- update(m4b_no_three_way, . ~ . - disc:condition)
cat("sample size x discrepancy x condition:\n"); print(anova(m4b_no_three_way, m4b_ml))
cat("discrepancy x condition (without the three-way term):\n"); print(anova(m4b_no_two_way, m4b_no_three_way))

# ---- M5: stabilization -------------------------------------------------------------------
m5 <- fit(abs_change ~ idx_shifted * condition + (1 + idx_shifted | playerID) + (1 | gameID),
          exp1$stabilization, "M5: change in estimate between rounds")

# The M5 condition coefficients are evaluated at round 0, but the first change that can
# be observed is at round 2. Condition contrasts at round 2, and slopes by condition:
cat("\nM5: condition contrasts at the first observable change (round 2)\n")
print(contrast(emmeans(m5, ~ condition | idx_shifted, at = list(idx_shifted = 2)), "pairwise", adjust = "none"))
cat("\nM5: change per round by condition, and differences between conditions\n")
print(emtrends(m5, pairwise ~ condition, var = "idx_shifted", adjust = "none"))
