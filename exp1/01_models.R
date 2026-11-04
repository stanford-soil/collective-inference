# Experiment 1 models reported in the revised paper. Every model includes a network
# (gameID) random intercept; the versions without it (original submission) are in
# response_letter/01_exp1_old_vs_new.R.
#   M1 convergence (Analysis 1), M2 error x condition over rounds (Analysis 2),
#   M3 condition differences at the final round (Analysis 3), M4 adaptive weighting
#   (Analysis 4) and its condition follow-up M4b, M5 stabilization (Analysis 5).
# Input: data/derived/exp1_clean_data.csv (prep/). Output: printed. Run from exp1/.
source("../lib/common.R")
source("../lib/exp1_data.R")
suppressPackageStartupMessages(library(emmeans))
options(width = 200)

e1 <- load_exp1()
d.guesses <- e1$d.guesses; d.shifted <- e1$d.shifted
d.revisions <- e1$d.revisions; d.stabilization <- e1$d.stabilization
cat("Sample:", n_distinct(d.guesses$playerID), "participants in", n_distinct(d.guesses$gameID), "networks\n")

# M1: error decreases over rounds (centered linear and quadratic terms)
m1 <- fit_lmer(error ~ idx_c + I(idx_c^2) + (1 + idx_c | playerID) + (1 | gameID), d.guesses,
               "M1 convergence | +network")
report_fit(m1)

# M2: error over rounds by condition
m2 <- fit_lmer(error ~ idx * condition + (1 + idx | playerID) + (1 | gameID), d.guesses,
               "M2 error x condition | +network")
report_fit(m2)

# M3: condition differences at the final round (real-time messaging = reference;
# idx_final_centered = 0 in each condition's last round)
f3 <- error ~ poly(idx_final_centered, 2) * condition_interactive + (1 + idx_final_centered | playerID) + (1 | gameID)
m3 <- fit_lmer(f3, d.shifted, "M3 condition@final | +network")
report_fit(m3)
# Omnibus likelihood-ratio test of the condition x time interaction (4 df)
m3_red <- lmer(update(f3, . ~ . - poly(idx_final_centered, 2):condition_interactive), data = d.shifted, control = ctrl, REML = FALSE)
m3_full <- lmer(f3, data = d.shifted, control = ctrl, REML = FALSE)
cat("\n==== M3 LRT: condition x time interaction (4 df) ====\n"); print(anova(m3_red, m3_full))
cat("\nFinal-round means by condition:\n")
print(d.shifted %>%
        filter((condition == "slider" & idx_shifted == 11) | (condition != "slider" & idx_shifted == 12)) %>%
        group_by(condition) %>%
        summarise(mean_error = mean(error, na.rm = TRUE), se_error = sd(error, na.rm = TRUE) / sqrt(n()), n = n()))

# M4: adaptive weighting by own sample size and previous-round social discrepancy
f4 <- belief_revision ~ scale(sample_size) * scale(prior_social_discrepancy) + scale(idx) + (1 + scale(idx) | playerID) + (1 | gameID)
m4 <- fit_lmer(f4, d.revisions, "M4 adaptive weighting | +network")
report_fit(m4)
# M4b: the same with condition interactions. This model is not in the original
# notebook; it was reconstructed as the full three-way interaction with condition
# (slider reference).
f4b <- belief_revision ~ scale(sample_size) * scale(prior_social_discrepancy) * condition + scale(idx) + (1 + scale(idx) | playerID) + (1 | gameID)
m4b <- fit_lmer(f4b, d.revisions, "M4b adaptive x condition (RECONSTRUCTED) | +network")
report_fit(m4b)

# M5: stabilization (change in estimate between consecutive rounds)
f5 <- abs_change ~ idx_shifted * condition + (1 + idx_shifted | playerID) + (1 | gameID)
m5 <- fit_lmer(f5, d.stabilization, "M5 belief revision | +network")
report_fit(m5)
# The M5 condition coefficients are at idx_shifted = 0; the first observed change is
# at idx_shifted = 2. Condition contrasts vs slider at idx_shifted = 2:
emm_options(lmer.df = "satterthwaite")
cat("\n==== M5 contrasts vs slider at idx_shifted = 2 ====\n")
print(contrast(emmeans(m5$model, ~ condition | idx_shifted, at = list(idx_shifted = 2)), "trt.vs.ctrl", ref = 1, adjust = "none"))
