# Do estimates improve more in mutual rounds than in one-way rounds? Mixed model of
# the round-to-round change in error with round fixed effects (absorbing changes
# shared by all conditions); int_recip / uni_recip test whether mutual rounds differ
# for real-time / delayed messaging relative to the slider. Exp 2: SR networks.
# Inputs: data/derived/exp1_error_changes.csv, exp2_error_changes.csv
# (05_prep_mutual_vs_oneway.py). Output: printed. Run from partner_schedule/.
source("../lib/common.R")
sr_games <- read.csv(EXP2_SR_GAMES)$gameID
for (exp in c("exp1", "exp2")) {
  f <- repo_path("data", "derived", paste0(exp, "_error_changes.csv"))
  d <- read.csv(f); d$round <- factor(d$idx)
  if (exp == "exp2") d <- d[d$gameID %in% sr_games, ]
  d$condition <- relevel(factor(d$condition), ref = "slider")
  d$int_recip <- as.integer(d$condition == "interactive" & d$recip == 1)
  d$uni_recip <- as.integer(d$condition == "unidirectional" & d$recip == 1)
  form <- if (exp == "exp1") d_err ~ round + condition + int_recip + uni_recip + (1|gameID) + (1|playerID) else d_err ~ round + condition + int_recip + (1|gameID) + (1|playerID)
  m <- lmer(form, data = d)
  cat("\n=====", exp, "n =", nrow(d), "\n")
  print(round(coef(summary(m))[grep("recip|condition", rownames(coef(summary(m)))), ], 4))
}
