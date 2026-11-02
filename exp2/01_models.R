# Experiment 2 models reported in the revised paper, on the SR networks (set
# SUBSET=RS or SUBSET=ALL to refit on other networks; see lib/exp2_data.R).
#   Analysis 1: error over rounds (model1_basic) and by condition (model1_condition).
#   Analysis 3: condition x difficulty interactions with centered continuous
#   difficulty predictors (model3_full), correlation between difficulty dimensions,
#   cell means, and final-round error by condition and representativeness half.
# Input: data/derived/exp2_clean_data.csv (prep/). Output: printed. Run from exp2/.
# Logic from the original analysis/exp2/exp2_main_analysis.qmd.
source("../lib/common.R")
source("../lib/exp2_data.R")
suppressPackageStartupMessages(library(broom.mixed))
options(width = 200)

e2 <- load_exp2()
d.all <- e2$d.all
cat("=== SAMPLE (", e2$subset, " networks) ===\n", sep = "")
cat("Participants:", n_distinct(d.all$playerID), " Games:", n_distinct(d.all$gameID),
    " Observations:", nrow(d.all), "\n")
print(d.all %>% distinct(gameID, condition) %>% count(condition))
cat("Active players per game:\n")
print(d.all %>% filter(!is.na(guess)) %>% distinct(gameID, playerID) %>% count(gameID, name = "n_active") %>% count(n_active))

# ---- Analysis 1: error over rounds
model1_basic <- lmer(error ~ idx_c + (1 + idx_c | gameID/playerID), data = d.all)
cat("\n=== Model 1: Error ~ Round (centered) ===\n"); print(coef(summary(model1_basic)))

model1_condition <- lmer(error ~ condition_c * idx_c + (1 + idx_c | gameID/playerID), data = d.all)
cat("\n=== Model 2: Error ~ Round x Condition (effect-coded: slider +0.5, real-time messaging -0.5) ===\n")
print(coef(summary(model1_condition)))

cat("\nCondition means:\n")
print(d.all %>% group_by(condition) %>%
        summarise(mean_error = round(mean(error, na.rm = TRUE), 1), sd_error = round(sd(error, na.rm = TRUE), 1), n = n()))
cat("\nFinal-round means:\n")
print(d.all %>% group_by(condition) %>% filter(idx_shifted == max(idx_shifted, na.rm = TRUE)) %>%
        summarise(final_error = round(mean(error, na.rm = TRUE), 1), n = n()))

# ---- Analysis 3: centered continuous difficulty predictors
game_level <- d.all %>% distinct(gameID, entropy_actual, representation_actual)
cat("\nCorrelation between entropy and representativeness: r =",
    round(cor(game_level$entropy_actual, game_level$representation_actual, use = "complete.obs"), 2), "\n")

model3_full <- lmer(
  error ~ idx_c +
    condition_c * critters_c +
    condition_c * entropy_c +
    condition_c * rep_c +
    critters_c * entropy_c +
    critters_c * rep_c +
    entropy_c * rep_c +
    (1 | gameID/playerID),
  data = d.all
)
cat("\n=== Full factorial model (difficulty scaled 0-1, higher = harder, centered) ===\n")
coefs <- coef(summary(model3_full)); print(coefs)

format_stat <- function(coefs, term) {
  b <- coefs[term, "Estimate"]; t_val <- coefs[term, "t value"]
  df <- coefs[term, "df"]; p <- coefs[term, "Pr(>|t|)"]
  p_str <- ifelse(p < 0.001, "< .001", sprintf("= %.3f", p))
  sprintf("b = %5.2f, t(%3.0f) = %5.2f, p %s", b, df, t_val, p_str)
}
terms <- c("Round" = "idx_c", "Condition" = "condition_c", "Sample size" = "critters_c",
           "Entropy" = "entropy_c", "Representativeness" = "rep_c",
           "Cond x Sample size" = "condition_c:critters_c", "Cond x Entropy" = "condition_c:entropy_c",
           "Cond x Rep" = "condition_c:rep_c", "Sample x Entropy" = "critters_c:entropy_c",
           "Sample x Rep" = "critters_c:rep_c", "Entropy x Rep" = "entropy_c:rep_c")
cat("\n")
for (k in names(terms)) cat(sprintf("  %-20s %s\n", k, format_stat(coefs, terms[[k]])))

cat("\nInteraction coefficients with 95% CIs:\n")
print(tidy(model3_full, effects = "fixed", conf.int = TRUE) %>%
        filter(str_detect(term, "condition_c:") & !str_detect(term, ":.*:")) %>%
        select(term, estimate, conf.low, conf.high, p.value))

cat("\n=== Cell means: representativeness x condition (all rounds) ===\n")
print(d.all %>% filter(!is.na(error)) %>% group_by(rep_bin, condition) %>%
        summarise(mean_error = round(mean(error, na.rm = TRUE), 1), sd_error = round(sd(error, na.rm = TRUE), 1),
                  n = n(), .groups = "drop"))

cat("\n=== Final-round error by condition and representativeness half (rep_scaled above the median = less representative) ===\n")
print(as.data.frame(d.all %>% group_by(gameID) %>% filter(idx_shifted == max(idx_shifted)) %>% ungroup() %>%
  mutate(less_representative = rep_scaled > median(rep_scaled, na.rm = TRUE)) %>%
  group_by(condition, less_representative) %>% summarise(mean_error = round(mean(error, na.rm = TRUE), 1), .groups = "drop")))
