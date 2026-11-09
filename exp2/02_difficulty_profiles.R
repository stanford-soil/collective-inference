# Experiment 2 condition differences by binned difficulty (median splits on sample
# size, entropy and representativeness): all-hard vs all-easy networks, all eight
# difficulty profiles with estimated marginal means, and two-way hard combinations.
# Input: data/derived/exp2_clean_data.csv (prep/). Output: printed. Run from exp2/.
# Logic from the original analysis/exp2/exp2_main_analysis.qmd (Analysis 2).
source("../lib/common.R")
source("../lib/exp2_data.R")
suppressPackageStartupMessages(library(emmeans))
options(width = 200)

d.all <- load_exp2()$d.all

cat("Difficulty profiles (critters/entropy/representativeness; E = easy, H = hard):\n")
print(d.all %>% distinct(gameID, difficulty_profile) %>% count(difficulty_profile) %>% arrange(desc(n)))

# All-hard (HHH) vs all-easy (EEE) networks
d.extreme <- d.all %>% filter(difficulty_profile %in% c("HHH", "EEE"))
cat("\nSample sizes for extreme profiles:\n")
print(d.extreme %>% distinct(gameID, condition, difficulty_profile) %>% count(difficulty_profile, condition))
model2_extreme <- lmer(error ~ condition * difficulty_profile + (1 | gameID/playerID), data = d.extreme, control = ctrl)
cat("\n=== Model: extreme difficulty profiles ===\n"); print(coef(summary(model2_extreme)))

# All eight profiles
model2_full <- lmer(error ~ condition * difficulty_profile + (1 | gameID/playerID), data = d.all, control = ctrl)
cat("\n=== Model: all difficulty profiles ===\n"); print(coef(summary(model2_full)))
cat("\n=== Estimated marginal means ===\n"); print(emmeans(model2_full, ~ condition | difficulty_profile))

# Two-way hard combinations
d.all <- d.all %>%
  mutate(hard_entropy_rep = (!entropy_easy) & (!rep_easy),
         hard_critters_rep = (!critters_easy) & (!rep_easy),
         hard_entropy_critters = (!entropy_easy) & (!critters_easy))
subsets <- list(
  "Hard entropy x hard representativeness" = quote(hard_entropy_rep),
  "Hard critters x hard representativeness" = quote(hard_critters_rep),
  "Hard entropy x hard critters (easy representativeness)" = quote(hard_entropy_critters & rep_easy))
for (k in names(subsets)) {
  d.subset <- d.all %>% filter(!!subsets[[k]])
  cat("\n===", k, "===\n")
  if (nrow(d.subset) > 100) print(coef(summary(lmer(error ~ condition + (1 | gameID/playerID), data = d.subset, control = ctrl))))
}
