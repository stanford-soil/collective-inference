# Response letter: formats the old-vs-new Experiment 1 tables written by
# 01_exp1_old_vs_new.R as Markdown (coefficients, exclusion thresholds,
# complete networks). Input: the three CSV files in this folder. Output: printed.
# Run from response_letter/ after 01_exp1_old_vs_new.R.
suppressPackageStartupMessages({library(dplyr);library(readr);library(tidyr);library(stringr)})
co <- read_csv("exp1_coefs_old_vs_new.csv", show_col_types=FALSE) %>%
  mutate(base = str_remove(model, " \\| .*$"), version = ifelse(str_detect(model, "\\+network"), "new", "old"))
fp <- function(p) ifelse(p < .001, "<.001", sub("^0", "", sprintf("%.3f", p)))
w <- co %>% filter(term != "(Intercept)") %>%
  mutate(cell = sprintf("%.2f (%.2f), t(%.1f)=%.2f, p=%s", b, se, df, t, fp(p))) %>%
  select(base, term, version, cell) %>% pivot_wider(names_from = version, values_from = cell)
cat("| Model | Term | Original b (SE), t(df), p | + network RI b (SE), t(df), p |\n|---|---|---|---|\n")
for (i in seq_len(nrow(w))) cat(sprintf("| %s | `%s` | %s | %s |\n", w$base[i], w$term[i], w$old[i], w$new[i]))
cat("\n")
r <- read_csv("exp1_threshold_robustness.csv", show_col_types=FALSE)
cat("| Threshold | N | Networks | Version | Slider vs Int. b, t(df), p | Unidir. vs Int. b, t(df), p |\n|---|---|---|---|---|---|\n")
for (i in seq_len(nrow(r))) cat(sprintf("| %s | %d | %d | %s | %.2f, t(%.1f)=%.2f, p=%s | %.2f, t(%.1f)=%.2f, p=%s |\n",
  r$threshold[i], r$N[i], r$networks[i], r$version[i], r$slider_b[i], r$slider_df[i], r$slider_t[i], fp(r$slider_p[i]),
  r$unidir_b[i], r$unidir_df[i], r$unidir_t[i], fp(r$unidir_p[i])))
cat("\n")
cr <- read_csv("exp1_complete_network_robustness.csv", show_col_types=FALSE) %>% filter(str_detect(term, "^condition"))
for (i in seq_len(nrow(cr))) cat(sprintf("%s %s N=%d nets=%d %s: b=%.2f SE=%.2f t(%.1f)=%.2f p=%s\n", cr$definition[i], cr$version[i], cr$N[i], cr$networks[i], cr$term[i], cr$b[i], cr$se[i], cr$df[i], cr$t[i], fp(cr$p[i])))
