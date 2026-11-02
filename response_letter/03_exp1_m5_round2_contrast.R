# Check: M5 condition coefficients are at idx_shifted = 0; first observed change is idx_shifted = 2.
source("00_prep_exp1.R"); suppressPackageStartupMessages(library(emmeans))
emm_options(lmer.df = "satterthwaite")
cat("min idx_shifted in stabilization data:", min(d.stabilization$idx_shifted), "\n")
for (v in c("old","new")) {
  f <- if (v=="old") abs_change ~ idx_shifted * condition + (1 + idx_shifted | playerID) else abs_change ~ idx_shifted * condition + (1 + idx_shifted | playerID) + (1 | gameID)
  m <- lmer(f, data = d.stabilization, control = ctrl)
  cat("\n==", v, "== contrasts vs slider at idx_shifted = 2\n")
  print(contrast(emmeans(m, ~ condition | idx_shifted, at = list(idx_shifted = 2)), "trt.vs.ctrl", ref = 1, adjust = "none"))
}
