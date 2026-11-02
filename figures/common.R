# Shared settings for the revision figures.
# Condition names in the data are mapped to the labels used in the revised manuscript.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggthemes)
  library(patchwork)
})

# Directory containing this file (scripts are run with Rscript from any folder)
fig_dir <- local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", args[grep("^--file=", args)])
  if (length(f) == 1) dirname(normalizePath(f)) else getwd()
})
repo_dir <- normalizePath(file.path(fig_dir, "..", ".."))

condition_breaks <- c("slider", "unidirectional", "interactive")
condition_labels <- c(
  "slider"         = "Slider (numerical estimates)",
  "unidirectional" = "Delayed messaging",
  "interactive"    = "Real-time messaging"
)
# Palette from analysis/exp1/exp1_main_analysis.qmd (Exp 2 reuses slider and interactive)
condition_colors <- c(
  "slider"         = "#E69F00",
  "unidirectional" = "#56B4E9",
  "interactive"    = "#009E73"
)

save_fig <- function(plot, name, width, height) {
  ggsave(file.path(fig_dir, paste0(name, ".pdf")), plot, width = width, height = height,
         device = cairo_pdf)
  ggsave(file.path(fig_dir, paste0(name, ".png")), plot, width = width, height = height,
         dpi = 300, bg = "white")
  cat("Saved", name, "(.pdf, .png)\n")
}

# Load the Exp 2 data prepared by revision/exp2_sr_primary/prep.R.
# subset: "SR" (primary analysis), "RS", or "" (all games).
load_exp2 <- function(subset = "") {
  old <- getwd()
  on.exit({ setwd(old); Sys.unsetenv("SUBSET") })
  setwd(file.path(repo_dir, "revision", "exp2_sr_primary"))
  Sys.setenv(SUBSET = subset)
  env <- new.env()
  invisible(capture.output(suppressMessages(suppressWarnings(
    sys.source("prep.R", envir = env)
  ))))
  list(d.all = env$d.all, d.slider_baseline = env$d.slider_baseline)
}
