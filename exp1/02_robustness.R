# Experiment 1 robustness of the final-round condition model (M3, with the network
# random intercept): (1) alternative exclusion thresholds (none, 50%, 80% as
# preregistered, 100% of rounds answered); (2) complete networks only (exactly 4,
# or at least 4, retained participants). Versions without the network intercept
# are in response_letter/01_exp1_old_vs_new.R.
# Input: data/derived/exp1_clean_data.csv, exp1_responders.csv (prep/). Output: printed.
# Run from exp1/.
source("../lib/common.R")
source("../lib/exp1_data.R")
options(width = 200)

e1 <- load_exp1()
d.guesses <- e1$d.guesses; d.shifted <- e1$d.shifted
d.pre.clean <- load_exp1_responders()
response_rates <- exp1_response_rates(d.pre.clean)

f3 <- error ~ poly(idx_final_centered, 2) * condition_interactive + (1 + idx_final_centered | playerID) + (1 | gameID)
cond_terms <- c("condition_interactiveslider", "condition_interactiveunidirectional")

# (1) Exclusion thresholds
thresholds <- c(0, 0.5, 0.8, 1.0); labs <- c("None", "50%", "80% (prereg)", "100%")
rob <- list()
for (i in seq_along(thresholds)) {
  ex <- response_rates %>% filter(response_rate < thresholds[i]) %>% pull(playerID)
  d.sub <- if (thresholds[i] == 0) d.pre.clean else d.pre.clean %>% filter(!(playerID %in% ex))
  d.sub <- make_shifted(d.sub)
  f <- fit_lmer(f3, d.sub, paste("Thresh", labs[i]))
  s <- coef(summary(f$model))
  rob[[i]] <- tibble(threshold = labs[i], N = n_distinct(d.sub$playerID), networks = n_distinct(d.sub$gameID),
    slider_b = s[cond_terms[1], "Estimate"], slider_t = s[cond_terms[1], "t value"],
    slider_df = s[cond_terms[1], "df"], slider_p = s[cond_terms[1], "Pr(>|t|)"],
    unidir_b = s[cond_terms[2], "Estimate"], unidir_t = s[cond_terms[2], "t value"],
    unidir_df = s[cond_terms[2], "df"], unidir_p = s[cond_terms[2], "Pr(>|t|)"],
    singular = f$singular, warnings = paste(f$warnings, collapse = " | "))
}
cat("==== Exclusion-threshold robustness (M3, +network) ====\n"); print(as.data.frame(bind_rows(rob)))

# (2) Complete networks
ret <- d.guesses %>% distinct(gameID, playerID) %>% count(gameID, name = "n_ret")
for (def in c("exactly4", "atleast4")) {
  g <- if (def == "exactly4") ret$gameID[ret$n_ret == 4] else ret$gameID[ret$n_ret >= 4]
  dd <- d.shifted %>% filter(gameID %in% g)
  cat("\n==== Complete networks (", def, ") ====\n", sep = "")
  print(dd %>% distinct(gameID, playerID, condition) %>% group_by(condition) %>%
          summarise(networks = n_distinct(gameID), participants = n_distinct(playerID)))
  report_fit(fit_lmer(f3, dd, paste("Complete", def, "| +network")))
  full <- lmer(f3, data = dd, control = ctrl, REML = FALSE)
  red <- lmer(update(f3, . ~ . - poly(idx_final_centered, 2):condition_interactive), data = dd, control = ctrl, REML = FALSE)
  cat("LRT condition x time:\n"); print(anova(red, full))
  print(dd %>% filter(idx_final_centered == 0) %>% group_by(condition) %>%
          summarise(mean_error = mean(error), sd = sd(error), n = n()))
}
