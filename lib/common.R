# Shared constants and helpers for the R scripts: repository paths, condition
# names, labels and palette, and the figure-saving function.
# Every script is run from its own folder (one level below the repository root)
# and starts with source("../lib/common.R").

suppressPackageStartupMessages({
  library(tidyverse)
  library(lme4)
  library(lmerTest)
})

REPO <- normalizePath("..")
repo_path <- function(...) file.path(REPO, ...)

# Data files. The derived files are written by prep/ and are not committed.
EXP1_MERGED      <- repo_path("data", "exp1", "PreregMergedGuesses.csv")
EXP1_CLEAN       <- repo_path("data", "derived", "exp1_clean_data.csv")
EXP1_RESPONDERS  <- repo_path("data", "derived", "exp1_responders.csv")
EXP2_CLEAN       <- repo_path("data", "derived", "exp2_clean_data.csv")
EXP2_CODED_MSGS  <- repo_path("data", "exp2", "coded_messages.csv")
# Experiment 2 networks analysed in the paper (SR treatments, both conditions).
# RS networks are excluded because their slider messages were inverted.
EXP2_SR_GAMES    <- repo_path("lib", "exp2_sr_games.csv")
EXP1_PARTNERS    <- repo_path("partner_schedule", "exp1_partners.csv")
EXP2_PARTNERS    <- repo_path("partner_schedule", "exp2_partners.csv")

# Condition names in the data and code, and the labels used in the revised manuscript
condition_breaks <- c("slider", "unidirectional", "interactive")
condition_labels <- c(
  "slider"         = "Slider (numerical estimates)",
  "unidirectional" = "Delayed messaging",
  "interactive"    = "Real-time messaging"
)
condition_colors <- c(
  "slider"         = "#E69F00",
  "unidirectional" = "#56B4E9",
  "interactive"    = "#009E73"
)

ctrl <- lmerControl(optimizer = "bobyqa")

# Save a figure as PDF into figures/
save_fig <- function(plot, name, width, height) {
  ggsave(repo_path("figures", paste0(name, ".pdf")), plot, width = width, height = height,
         device = cairo_pdf)
  cat("Saved", paste0(name, ".pdf"), "\n")
}

# Fit a mixed model, recording warnings, convergence messages and singularity
fit_lmer <- function(formula, data, label) {
  w <- character(0)
  m <- withCallingHandlers(
    lmer(formula, data = data, control = ctrl),
    warning = function(cond) { w <<- c(w, conditionMessage(cond)); invokeRestart("muffleWarning") },
    message = function(cond) { w <<- c(w, conditionMessage(cond)); invokeRestart("muffleMessage") })
  conv_msgs <- m@optinfo$conv$lme4$messages
  list(model = m, label = label, warnings = unique(c(w, conv_msgs)),
       singular = isSingular(m), vc = as.data.frame(VarCorr(m)), nobs = nobs(m),
       ngroups = ngrps(m))
}

# Print a fitted model: sample, singularity, warnings, variance components, fixed effects
report_fit <- function(f) {
  cat("\n==== ", f$label, " ====\n", sep = "")
  cat("nobs:", f$nobs, " groups:", paste(names(f$ngroups), f$ngroups, collapse = ", "), "\n")
  cat("singular:", f$singular, "\n")
  cat("warnings/convergence messages:", if (length(f$warnings)) paste(f$warnings, collapse = " | ") else "none", "\n")
  print(f$vc[, c("grp", "var1", "var2", "vcov", "sdcor")])
  print(coef(summary(f$model)))
}

# Fixed effects of a fitted model as a tibble
tidy_fit <- function(f) {
  s <- coef(summary(f$model))
  tibble(model = f$label, term = rownames(s), b = s[, "Estimate"], se = s[, "Std. Error"],
         df = s[, "df"], t = s[, "t value"], p = s[, "Pr(>|t|)"])
}
