# Do estimates improve more in mutual rounds than in one-way rounds?
#
# In four-player networks the pairs are mutual in rounds 1, 4, 7 (and 10 in
# Experiment 1) and one-way in the other rounds. The outcome is the change in each
# participant's error from the previous round. Round (as a factor) absorbs changes
# shared by all conditions, so the mutual-round terms test whether the messaging
# conditions gained more than the slider condition in mutual rounds.
#
# Reads   data/derived/exp1_clean_data.csv, exp2_clean_data.csv, exp1_partners.csv
# Prints  the condition and mutual-round coefficients (Appendix D)
source("../lib/common.R")

# Change in error from the previous round, for consecutive rounds only
error_changes <- function(d) {
  d %>%
    arrange(playerID, idx) %>%
    group_by(playerID) %>%
    mutate(error_change = error - lag(error), previous_round = lag(idx)) %>%
    ungroup() %>%
    filter(previous_round == idx - 1) %>%
    mutate(round = factor(idx), condition = relevel(factor(condition), ref = "slider"))
}

print_terms <- function(model) {
  coefs <- coef(summary(model))
  print(round(coefs[grep("mutual|condition", rownames(coefs)), ], 4))
}

# ---- Experiment 1: networks launched with four players ---------------------------------
four_player_networks <- read_csv(EXP1_PARTNERS, show_col_types = FALSE) %>%
  filter(nPlayers == 4) %>% distinct(gameID) %>% pull(gameID)
exp1 <- read_csv(EXP1_CLEAN, show_col_types = FALSE) %>%
  filter(gameID %in% four_player_networks) %>%
  error_changes() %>%
  mutate(mutual = idx %in% c(4, 7, 10),
         live_mutual    = as.integer(condition == "interactive" & mutual),
         batched_mutual = as.integer(condition == "unidirectional" & mutual))

cat("\n==== Experiment 1:", nrow(exp1), "changes ====\n")
print_terms(lmer(error_change ~ round + condition + live_mutual + batched_mutual +
                   (1 | gameID) + (1 | playerID), data = exp1))

# ---- Experiment 2: the analysed networks -----------------------------------------------
# Error is the distance from the proportion of rabbits in the network's full sample.
sr_games <- read_csv(EXP2_SR_GAMES, show_col_types = FALSE)$gameID
exp2 <- read_csv(EXP2_CLEAN, show_col_types = FALSE) %>%
  filter(gameID %in% sr_games, !is.na(guess)) %>%
  mutate(condition = ifelse(str_detect(treatmentName.x, "interactive"), "interactive", "slider"),
         error = abs(guess - mleGame * 100)) %>%
  error_changes() %>%
  mutate(mutual = idx %in% c(4, 7),
         chat_mutual = as.integer(condition == "interactive" & mutual))

cat("\n==== Experiment 2:", nrow(exp2), "changes ====\n")
print_terms(lmer(error_change ~ round + condition + chat_mutual + (1 | gameID) + (1 | playerID), data = exp2))
