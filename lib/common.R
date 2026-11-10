# Shared by every R script: packages, file paths, condition names, and two helpers.
# Each script is run from its own folder and starts with source("../lib/common.R").

suppressPackageStartupMessages({
  library(tidyverse)
  library(lme4)
  library(lmerTest)   # Satterthwaite degrees of freedom and p values for lmer
})
options(width = 200)

# ---- File paths ---------------------------------------------------------------
repo_path <- function(...) file.path(normalizePath(".."), ...)
derived   <- function(file) repo_path("data", "derived", file)   # rebuilt by the pipeline, not committed

EXP1_MERGED     <- repo_path("data", "exp1", "PreregMergedGuesses.csv")
EXP1_CLEAN      <- derived("exp1_clean_data.csv")
EXP1_RESPONDERS <- derived("exp1_responders.csv")
EXP1_PARTNERS   <- derived("exp1_partners.csv")

EXP2_CLEAN      <- derived("exp2_clean_data.csv")
EXP2_SR_GAMES   <- repo_path("lib", "exp2_sr_games.csv")   # the analysed Experiment 2 networks
EXP2_PARTNERS   <- derived("exp2_partners.csv")
EXP2_CODED_MSGS <- repo_path("data", "exp2", "coded_messages.csv")

# ---- Conditions ---------------------------------------------------------------
# The data use the original condition names; the paper uses the labels below.
condition_breaks <- c("slider", "unidirectional", "interactive")
condition_labels <- c(
  "slider"         = "Slider (numerical estimates)",
  "unidirectional" = "Batched messaging",
  "interactive"    = "Live messaging"
)
# Experiment 2 had only the live version of messaging, called "messaging" in the paper.
exp2_condition_labels <- c(
  "slider"      = "Slider (numerical estimates)",
  "interactive" = "Messaging"
)
condition_colors <- c(
  "slider"         = "#E69F00",
  "unidirectional" = "#56B4E9",
  "interactive"    = "#009E73"
)

# ---- Helpers ------------------------------------------------------------------
# All mixed models are fitted with the bobyqa optimizer.
ctrl <- lmerControl(optimizer = "bobyqa")

# Fit a mixed model and print its fixed effects (estimate, SE, df, t, p).
# lme4 prints any convergence warning itself; a singular fit is flagged here.
fit <- function(formula, data, label) {
  model <- lmer(formula, data = data, control = ctrl)
  groups <- ngrps(model)
  cat("\n==== ", label, " ====\n", sep = "")
  cat("observations:", nobs(model), "| groups:", paste(names(groups), groups, collapse = ", "),
      if (isSingular(model)) "| singular fit" else "", "\n")
  print(coef(summary(model)))
  invisible(model)
}

# Save a figure as a PDF in figures/.
save_fig <- function(plot, name, width, height) {
  ggsave(repo_path("figures", paste0(name, ".pdf")), plot, width = width, height = height,
         device = cairo_pdf)
  cat("Saved", paste0(name, ".pdf"), "\n")
}
