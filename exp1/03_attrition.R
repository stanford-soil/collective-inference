# Task 2: attrition by condition for Exp 1 and Exp 2.
source("00_prep_exp1.R")
suppressPackageStartupMessages(library(purrr))
options(width = 200)
rd <- function(dirs, f) map_df(dirs, ~{
  x <- read_csv(file.path(.x, f), show_col_types = FALSE, col_types = cols(.default = "c"))
  names(x)[1] <- "id"; x %>% mutate(batch = basename(.x)) })
cond_of <- function(tn) case_when(str_detect(tn, "interactive") ~ "interactive",
                                   str_detect(tn, "unidirectional") ~ "unidirectional",
                                   str_detect(tn, "slider") ~ "slider")

############################ EXP 1 ############################
dirs1 <- list.files(file.path(REPO, "data/exp1/raw"), pattern = "^1_prereg_", full.names = TRUE)
pl1 <- rd(dirs1, "players.csv"); gm1 <- rd(dirs1, "games.csv")
started_games <- unique(d.raw$gameID)  # games with >=1 recorded guess (as in data_preparation.qmd)
assigned1 <- pl1 %>% filter(gameID %in% started_games) %>% distinct(playerID = id, gameID)
gtreat1 <- gm1 %>% filter(!is.na(treatmentName)) %>% distinct(gameID = id, treatmentName)
assigned1 <- assigned1 %>% left_join(gtreat1, by = "gameID") %>% mutate(condition = cond_of(treatmentName))

cat("=== EXP 1 FUNNEL ===\n")
cat("Networks with >=1 guess:", length(started_games), "\n")
cat("Participants assigned to those networks:", n_distinct(assigned1$playerID), "\n")
resp_all <- unique(d.raw$playerID)
cat("  ... provided >=1 guess:", length(resp_all), "\n")
cat("  ... never provided a guess:", sum(!(unique(assigned1$playerID) %in% resp_all)), "\n")
na_game <- assigned1 %>% filter(is.na(condition))
cat("Networks with missing treatment label:", n_distinct(na_game$gameID), " participants:", nrow(na_game),
    " of whom responded:", sum(na_game$playerID %in% resp_all), "\n")
cat("Responders in labelled networks (= 'no exclusions' N):", n_distinct(d.pre$playerID), "\n")
cat("Excluded by <80% response rule:", length(exclude_prereg), "\n")
cat("Final:", n_distinct(d.guesses$playerID), "in", n_distinct(d.guesses$gameID), "networks\n")

# dropouts: what did never-responders look like?
nonresp <- setdiff(unique(assigned1$playerID), resp_all)
cat("Never-responders by players.ended:\n")
print(pl1 %>% filter(id %in% nonresp) %>% group_by(id) %>%
        summarise(ended = paste(unique(na.omit(ended)), collapse = "/"),
                  introDone = any(introDone == "true", na.rm = TRUE)) %>% count(ended, introDone))

# Over-assignment
asz <- assigned1 %>% filter(!is.na(condition)) %>% count(gameID, condition, name = "n_assigned")
cat("Networks with >4 participants assigned (Empirica over-assignment):", sum(asz$n_assigned > 4), "\n")
print(table(asz$n_assigned))

net1 <- asz %>%
  left_join(d.pre %>% distinct(gameID, playerID) %>% count(gameID, name = "n_responded"), by = "gameID") %>%
  left_join(d.guesses %>% distinct(gameID, playerID) %>% count(gameID, name = "n_retained"), by = "gameID") %>%
  mutate(across(c(n_responded, n_retained), ~replace_na(., 0L)),
         condition = factor(condition, levels = c("slider", "unidirectional", "interactive")),
         complete = n_retained >= 4)
write_csv(net1, "exp1_network_sizes.csv")

summ1 <- net1 %>% group_by(condition) %>% summarise(
  networks_started = n(),
  assigned = sum(n_assigned),
  responded = sum(n_responded),
  retained = sum(n_retained),
  networks_analysed = sum(n_retained > 0),
  size0 = sum(n_retained == 0), size1 = sum(n_retained == 1), size2 = sum(n_retained == 2),
  size3 = sum(n_retained == 3), size4 = sum(n_retained == 4), size5plus = sum(n_retained >= 5),
  complete = sum(complete),
  prop_complete_of_started = mean(complete),
  prop_complete_of_analysed = sum(complete) / sum(n_retained > 0),
  mean_retained_analysed = mean(n_retained[n_retained > 0]),
  median_retained_analysed = median(n_retained[n_retained > 0]),
  .groups = "drop")
tot1 <- net1 %>% summarise(condition = "Total", networks_started = n(), assigned = sum(n_assigned),
  responded = sum(n_responded), retained = sum(n_retained), networks_analysed = sum(n_retained > 0),
  size0 = sum(n_retained == 0), size1 = sum(n_retained == 1), size2 = sum(n_retained == 2),
  size3 = sum(n_retained == 3), size4 = sum(n_retained == 4), size5plus = sum(n_retained >= 5),
  complete = sum(complete), prop_complete_of_started = mean(complete),
  prop_complete_of_analysed = sum(complete) / sum(n_retained > 0),
  mean_retained_analysed = mean(n_retained[n_retained > 0]),
  median_retained_analysed = median(n_retained[n_retained > 0]))
summ1 <- bind_rows(summ1 %>% mutate(condition = as.character(condition)), tot1)
cat("\n=== EXP 1 ATTRITION BY CONDITION ===\n"); print(as.data.frame(summ1))
write_csv(summ1, "exp1_attrition_by_condition.csv")

cat("\n--- Exp 1 tests ---\n")
an1 <- net1 %>% filter(n_retained > 0)
cat("Chi-square, complete (>=4 retained) vs not, analysed networks (N=", nrow(an1), "):\n", sep = "")
print(chisq.test(table(an1$condition, an1$complete)))
cat("Fisher exact (same table):\n"); print(fisher.test(table(an1$condition, an1$complete)))
cat("Chi-square, complete vs not, all started labelled networks (N=", nrow(net1), "):\n", sep = "")
print(chisq.test(table(net1$condition, net1$complete)))
cat("Kruskal-Wallis, retained per network, analysed networks:\n")
print(kruskal.test(n_retained ~ condition, data = an1))
cat("Kruskal-Wallis, retained per network, all started labelled networks (zeros included):\n")
print(kruskal.test(n_retained ~ condition, data = net1))
cat("Chi-square, networks lost entirely (0 retained) vs not:\n")
print(fisher.test(table(net1$condition, net1$n_retained == 0)))
# participant-level retention: retained / assigned and retained / responded
pp1 <- assigned1 %>% filter(!is.na(condition)) %>%
  mutate(responded = playerID %in% d.pre$playerID, retained = playerID %in% d.guesses$playerID,
         condition = factor(condition, levels = c("slider", "unidirectional", "interactive")))
cat("Participant-level: retained among assigned, by condition\n")
print(table(pp1$condition, pp1$retained)); print(chisq.test(table(pp1$condition, pp1$retained)))
cat("Participant-level: responded (>=1 guess) among assigned\n")
print(table(pp1$condition, pp1$responded)); print(chisq.test(table(pp1$condition, pp1$responded)))
cat("Participant-level: passed 80% rule among responders\n")
rr <- pp1 %>% filter(responded)
print(table(rr$condition, rr$retained)); print(chisq.test(table(rr$condition, rr$retained)))

############################ EXP 2 ############################
dirs2 <- list.files(file.path(REPO, "data/exp2/raw"), full.names = TRUE)
rd2 <- function(f) map_df(dirs2, ~read_csv(file.path(.x, f), show_col_types = FALSE, col_types = cols(.default = "c")) %>% mutate(batch = basename(.x)))
pl2 <- rd2("player.csv"); gm2 <- rd2("game.csv"); ps2 <- rd2("playerStage.csv")
d2 <- read_csv("exp2_clean_data.csv", show_col_types = FALSE) %>%
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
