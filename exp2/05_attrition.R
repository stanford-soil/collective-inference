# Experiment 2 attrition by condition: recruitment funnel, networks retained in the
# final sample (all four players finished), active players and 80% response rate,
# and tests of whether these differed between conditions. Counts cover all
# networks (SR and RS), since the SR restriction is a choice made after data collection.
# Input: data/exp2/raw/<batch>/ (player.csv, game.csv, playerStage.csv),
#   data/derived/exp2_clean_data.csv.
# Output: exp2_network_sizes.csv, exp2_attrition_by_condition.csv (and printed tests).
# Run from exp2/.
source("../lib/common.R")
options(width = 200)
rd <- function(dirs, f) map_df(dirs, ~{
  x <- read_csv(file.path(.x, f), show_col_types = FALSE, col_types = cols(.default = "c"))
  names(x)[1] <- "id"; x %>% mutate(batch = basename(.x)) })
cond_of <- function(tn) case_when(str_detect(tn, "interactive") ~ "interactive",
                                   str_detect(tn, "unidirectional") ~ "unidirectional",
                                   str_detect(tn, "slider") ~ "slider")

############################ EXP 2 ############################
dirs2 <- list.files(repo_path("data", "exp2", "raw"), full.names = TRUE)
rd2 <- function(f) map_df(dirs2, ~read_csv(file.path(.x, f), show_col_types = FALSE, col_types = cols(.default = "c")) %>% mutate(batch = basename(.x)))
pl2 <- rd2("player.csv"); gm2 <- rd2("game.csv"); ps2 <- rd2("playerStage.csv")
d2 <- read_csv(EXP2_CLEAN, show_col_types = FALSE) %>%
  mutate(condition = ifelse(str_detect(treatmentName.x, "interactive"), "interactive", "slider"))
gtreat2 <- gm2 %>% filter(!is.na(treatmentName)) %>% distinct(gameID = id, treatmentName) %>%
  mutate(condition = ifelse(str_detect(treatmentName, "interactive"), "interactive", "slider"))
final_games0 <- unique(d2$gameID)
# started = >=1 recorded guess, plus any final-sample network (one final network has no guesses at all)
started2 <- union(unique(ps2$gameID[!is.na(ps2$guess)]), final_games0)
cat("Final networks with zero recorded guesses:", length(setdiff(final_games0, unique(ps2$gameID[!is.na(ps2$guess)]))), "\n")
assigned2 <- pl2 %>% filter(gameID %in% started2) %>% distinct(playerID = id, gameID, ended) %>%
  left_join(gtreat2, by = "gameID")
resp2 <- unique(ps2$playerID[!is.na(ps2$guess)])
final_games <- unique(d2$gameID)

cat("\n\n=== EXP 2 FUNNEL ===\n")
cat("Networks started (>=1 recorded guess or in final sample):", length(started2), "\n")
cat("Participants assigned to those networks:", n_distinct(assigned2$playerID), "\n")
cat("  ... provided >=1 guess:", sum(unique(assigned2$playerID) %in% resp2), "\n")
cat("Final analysed (exp2 cleaning: exactly 4 players, all with ended=='game ended'):",
    n_distinct(d2$playerID), "in", length(final_games), "networks\n")
cat("Final-sample participants who never entered a guess:",
    n_distinct(d2$playerID) - n_distinct(d2$playerID[!is.na(d2$guess)]), "\n")

# response rate (as in exp2 Robustness 1: responses / 8 over all 8 rounds incl. slider baseline)
rr2 <- d2 %>% group_by(playerID, gameID, condition) %>%
  summarise(responses = sum(!is.na(guess)), .groups = "drop") %>% mutate(rate = responses / 8)
net2 <- assigned2 %>% count(gameID, condition, name = "n_assigned") %>%
  left_join(assigned2 %>% filter(playerID %in% resp2) %>% count(gameID, name = "n_responded"), by = "gameID") %>%
  left_join(d2 %>% distinct(gameID, playerID) %>% count(gameID, name = "n_final"), by = "gameID") %>%
  left_join(d2 %>% filter(!is.na(guess)) %>% distinct(gameID, playerID) %>% count(gameID, name = "n_active"), by = "gameID") %>%
  left_join(rr2 %>% filter(rate >= 0.8) %>% count(gameID, name = "n_80"), by = "gameID") %>%
  mutate(across(c(n_responded, n_final, n_active, n_80), ~replace_na(., 0L)),
         in_final = gameID %in% final_games)
write_csv(net2, "exp2_network_sizes.csv")

s2 <- function(g) g %>% summarise(
  networks_started = n(), assigned = sum(n_assigned), responded = sum(n_responded),
  networks_final = sum(in_final), retained_final = sum(n_final),
  prop_networks_retained = mean(in_final),
  active_final = sum(n_active), active3 = sum(in_final & n_active == 3), active4 = sum(in_final & n_active == 4),
  active_other = sum(in_final & !(n_active %in% c(3, 4))),
  pass80 = sum(n_80),
  net80_size0 = sum(in_final & n_80 == 0), net80_size1 = sum(in_final & n_80 == 1), net80_size2 = sum(in_final & n_80 == 2),
  net80_size3 = sum(in_final & n_80 == 3), net80_size4 = sum(in_final & n_80 == 4),
  .groups = "drop")
summ2 <- bind_rows(net2 %>% group_by(condition) %>% s2(), net2 %>% s2() %>% mutate(condition = "Total"))
cat("\n=== EXP 2 ATTRITION BY CONDITION ===\n"); print(as.data.frame(summ2))
write_csv(summ2, "exp2_attrition_by_condition.csv")

cat("\n--- Exp 2 tests ---\n")
cat("Network retained in final sample (all 4 finished) vs not, among started networks:\n")
print(table(net2$condition, net2$in_final)); print(chisq.test(table(net2$condition, net2$in_final)))
f2 <- net2 %>% filter(in_final)
cat("Among final networks: all 4 active (>=1 guess) vs not:\n")
print(table(f2$condition, f2$n_active == 4)); print(chisq.test(table(f2$condition, f2$n_active == 4)))
cat("Among final networks: all 4 pass 80% rule vs not:\n")
print(table(f2$condition, f2$n_80 == 4)); print(chisq.test(table(f2$condition, f2$n_80 == 4)))
cat("Kruskal-Wallis, # passing 80% per final network:\n"); print(kruskal.test(n_80 ~ factor(condition), data = f2))
cat("Kruskal-Wallis, # active per final network:\n"); print(kruskal.test(n_active ~ factor(condition), data = f2))
pp2 <- assigned2 %>% mutate(final = playerID %in% d2$playerID)
cat("Participant-level: in final sample among assigned:\n")
print(table(pp2$condition, pp2$final)); print(chisq.test(table(pp2$condition, pp2$final)))
cat("Assigned-player 'ended' status by condition (started networks):\n")
print(table(assigned2$condition, assigned2$ended, useNA = "ifany"))
