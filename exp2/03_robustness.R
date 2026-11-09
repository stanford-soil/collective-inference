# Experiment 2 robustness of the condition x representativeness interaction:
# (1) excluding participants who answered fewer than 80% of the 8 rounds,
# (2) excluding magnet values (estimates of 0, 50 or 100),
# (3) networks with four participants only; compared with model3_full.
# Input: data/derived/exp2_clean_data.csv (prep/). Output: printed. Run from exp2/.
# Logic from the original analysis/exp2/exp2_main_analysis.qmd (Robustness 1-3).
source("../lib/common.R")
source("../lib/exp2_data.R")
options(width = 200)

e2 <- load_exp2()
d.all <- e2$d.all; d.slider_baseline <- e2$d.slider_baseline

model3_full <- lmer(error ~ idx_c + condition_c * critters_c + condition_c * entropy_c + condition_c * rep_c +
                      critters_c * entropy_c + critters_c * rep_c + entropy_c * rep_c + (1 | gameID/playerID),
                    data = d.all, control = ctrl)

# (1) 80% response rate (8 rounds, including the slider's pre-social round)
response_rates <- d.all %>% bind_rows(d.slider_baseline) %>% group_by(playerID) %>%
  summarise(responses = sum(!is.na(guess)), response_rate = responses / 8, .groups = "drop")
cat("Response rate distribution:\n"); print(summary(response_rates$response_rate))
exclude_low_response <- response_rates %>% filter(response_rate < 0.80) %>% pull(playerID)
cat("Participants excluded (response rate < 80%):", length(exclude_low_response), "\n")
d.robust1 <- d.all %>% filter(!(playerID %in% exclude_low_response))
cat("Remaining:", n_distinct(d.robust1$playerID), "participants,", n_distinct(d.robust1$gameID), "games\n")
model_robust1 <- lmer(error ~ condition_c * rep_c + (1 | gameID/playerID), data = d.robust1, control = ctrl)
cat("\n=== (1) 80% response rate ===\n"); print(coef(summary(model_robust1)))

# (2) Magnet values
cat("\nMagnet value frequencies:\n")
print(d.all %>% mutate(magnet_type = case_when(guess == 0 ~ "0%", guess == 50 ~ "50%", guess == 100 ~ "100%",
                                               TRUE ~ "Other")) %>%
        count(magnet_type) %>% mutate(pct = round(n / sum(n) * 100, 1)))
d.robust2 <- d.all %>% filter(!guess %in% c(0, 50, 100))
cat("After excluding magnet values:", nrow(d.robust2), "observations\n")
model_robust2 <- lmer(error ~ condition_c * rep_c + (1 | gameID/playerID), data = d.robust2, control = ctrl)
cat("\n=== (2) No magnet values ===\n"); print(coef(summary(model_robust2)))

# (3) Networks with four participants. As in the original notebook, participants are
# counted in the analysis data, which include players who never answered, so every
# network has four and this subset equals the full sample.
games_by_size <- d.all %>% group_by(gameID) %>% summarise(n_active = n_distinct(playerID), .groups = "drop")
cat("\nGames by number of players:\n"); print(table(games_by_size$n_active))
d.robust3 <- d.all %>% filter(gameID %in% games_by_size$gameID[games_by_size$n_active == 4])
model_robust3 <- lmer(error ~ condition_c * rep_c + (1 | gameID/playerID), data = d.robust3, control = ctrl)
cat("\n=== (3) Four-player networks ===\n"); print(coef(summary(model_robust3)))

# The same subsets with the full difficulty model (the specification of the main analysis)
f_full <- formula(model3_full)
model_robust1_full <- lmer(f_full, data = d.robust1, control = ctrl)
model_robust2_full <- lmer(f_full, data = d.robust2, control = ctrl)
cat("\n=== (1) 80% response rate, full difficulty model ===\n"); print(coef(summary(model_robust1_full)))
cat("\n=== (2) No magnet values, full difficulty model ===\n"); print(coef(summary(model_robust2_full)))
cat("\nParticipants answering at least 80% of rounds, by condition:\n")
rr_cond <- response_rates %>% left_join(d.all %>% bind_rows(d.slider_baseline) %>% distinct(playerID, condition), by = "playerID")
print(rr_cond %>% group_by(condition) %>% summarise(n = n(), pass80 = sum(response_rate >= 0.8), prop = mean(response_rate >= 0.8)))
print(chisq.test(table(rr_cond$condition, rr_cond$response_rate >= 0.8)))
cat("\nCell means (all rounds) after the 80% exclusion:\n")
print(d.robust1 %>% group_by(rep_bin, condition) %>% summarise(mean_error = mean(error, na.rm = TRUE), n = n(), .groups = "drop"))

cat("\n=== Summary: condition x representativeness interaction ===\n")
models <- list("Main (model3_full)" = model3_full,
               "80% response rate, full model" = model_robust1_full, "No magnet values, full model" = model_robust2_full,
               "80% response rate, reduced model" = model_robust1, "No magnet values, reduced model" = model_robust2,
               "Four-player networks, reduced model" = model_robust3)
print(map_dfr(names(models), function(n) {
  s <- coef(summary(models[[n]]))["condition_c:rep_c", ]
  tibble(analysis = n, b = round(s[["Estimate"]], 2), t = round(s[["t value"]], 2), df = round(s[["df"]], 1),
         p = signif(s[["Pr(>|t|)"]], 3))
}))
