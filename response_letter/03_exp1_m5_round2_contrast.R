# Response letter: the M5 (stabilization) condition coefficients are evaluated at
# idx_shifted = 0, but the first observed change is at idx_shifted = 2. Prints the
# condition contrasts vs slider at idx_shifted = 2, old and new (+network) model.
# Input: data/derived/exp1_clean_data.csv. Output: printed. Run from response_letter/.
source("../lib/common.R"); source("../lib/exp1_data.R"); suppressPackageStartupMessages(library(emmeans))
d.stabilization <- load_exp1()$d.stabilization
emm_options(lmer.df = "satterthwaite")
cat("min idx_shifted in stabilization data:", min(d.stabilization$idx_shifted), "\n")
for (v in c("old","new")) {
  f <- if (v=="old") abs_change ~ idx_shifted * condition + (1 + idx_shifted | playerID) else abs_change ~ idx_shifted * condition + (1 + idx_shifted | playerID) + (1 | gameID)
  m <- lmer(f, data = d.stabilization, control = ctrl)
  cat("\n==", v, "== contrasts vs slider at idx_shifted = 2\n")
  print(contrast(emmeans(m, ~ condition | idx_shifted, at = list(idx_shifted = 2)), "trt.vs.ctrl", ref = 1, adjust = "none"))
}
