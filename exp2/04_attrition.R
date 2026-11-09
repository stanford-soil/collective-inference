# Experiment 2: recruitment and attrition by condition (Appendix A).
#
# A network was retained when all four of its participants finished the session.
# The counts are given for all networks and for the networks with the unaffected
# slider version ("SR"), which are the ones analysed.
#
# Reads   data/exp2/raw/<batch>/ (player.csv, game.csv, playerStage.csv),
#         data/derived/exp2_clean_data.csv
# Prints  the attrition tables and the tests of condition differences
source("../lib/common.R")

clean <- read_csv(EXP2_CLEAN, show_col_types = FALSE)   # one row per participant and round, retained networks

batch_dirs <- list.files(repo_path("data", "exp2", "raw"), full.names = TRUE)
read_raw <- function(file) {
  map_df(batch_dirs, ~ read_csv(file.path(.x, file), show_col_types = FALSE, col_types = cols(.default = "c")))
}
estimates <- read_raw("playerStage.csv") %>% filter(!is.na(guess))
treatments <- read_raw("game.csv") %>%
  filter(!is.na(treatmentName)) %>%
  distinct(gameID = id, treatmentName) %>%
  mutate(condition = ifelse(str_detect(treatmentName, "interactive"), "interactive", "slider"),
         slider_version = str_sub(treatmentName, 1, 2))

# ---- Everyone assigned to a started network ----------------------------------------------
# A network counts as started if it recorded at least one estimate. (One retained
# network recorded none; it is counted as started too.)
started <- union(estimates$gameID, clean$gameID)
assigned <- read_raw("player.csv") %>%
  filter(gameID %in% started) %>%
  distinct(playerID = id, gameID) %>%
  left_join(treatments, by = "gameID") %>%
  mutate(retained = playerID %in% clean$playerID)

networks <- assigned %>%
  group_by(gameID, condition, slider_version) %>%
  summarise(n_assigned = n(), .groups = "drop") %>%
  mutate(retained = gameID %in% clean$gameID)

count_networks <- function(d) {
  d %>% summarise(networks_started = n(), participants_assigned = sum(n_assigned),
                  networks_retained = sum(retained), share_retained = mean(retained),
                  participants_retained = 4 * sum(retained))
}
attrition_table <- function(d) {
  print(as.data.frame(bind_rows(d %>% group_by(condition) %>% count_networks(),
                                d %>% count_networks() %>% mutate(condition = "Total"))))
}

cat("==== All networks ====\n")
attrition_table(networks)
cat("\nStarted networks that were retained, by condition:\n")
print(chisq.test(table(networks$condition, networks$retained)))
cat("Assigned participants who were retained, by condition:\n")
print(chisq.test(table(assigned$condition, assigned$retained)))

# ---- Networks with the unaffected slider version (analysed) ------------------------------
networks_sr <- networks %>% filter(slider_version == "SR")
cat("\n==== Networks with the unaffected slider version (analysed) ====\n")
attrition_table(networks_sr)
cat("\nStarted networks that were retained, by condition:\n")
print(chisq.test(table(networks_sr$condition, networks_sr$retained)))

# Participants in the analysed networks: how many of the 8 rounds each answered
participants <- clean %>%
  filter(gameID %in% networks_sr$gameID) %>%
  mutate(condition = ifelse(str_detect(treatmentName.x, "interactive"), "interactive", "slider")) %>%
  group_by(playerID, condition) %>%
  summarise(rounds_answered = sum(!is.na(guess)), .groups = "drop")

cat("Participants who never entered an estimate (TRUE), by condition:\n")
print(table(participants$condition, participants$rounds_answered == 0))
print(fisher.test(table(participants$condition, participants$rounds_answered == 0)))

cat("Participants who answered at least 80% of the 8 rounds (TRUE), by condition:\n")
print(table(participants$condition, participants$rounds_answered / 8 >= 0.8))
print(chisq.test(table(participants$condition, participants$rounds_answered / 8 >= 0.8)))
