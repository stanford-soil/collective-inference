# Experiment 1 attrition by condition: recruitment funnel, network sizes after the
# exclusion, and tests of whether attrition differed between conditions.
# Input: data/exp1/raw/1_prereg_*/ (players.csv, games.csv), data/exp1/PreregMergedGuesses.csv,
#   data/derived/exp1_clean_data.csv, exp1_responders.csv.
# Output: exp1_network_sizes.csv, exp1_attrition_by_condition.csv (and printed tests).
# Run from exp1/.
source("../lib/common.R")
source("../lib/exp1_data.R")
options(width = 200)
d.raw <- read_csv(EXP1_MERGED, show_col_types = FALSE)
d.pre <- load_exp1_responders()
d.guesses <- load_exp1()$d.guesses
exclude_prereg <- exp1_response_rates(d.pre) %>% filter(response_rate < 0.80) %>% pull(playerID)
rd <- function(dirs, f) map_df(dirs, ~{
  x <- read_csv(file.path(.x, f), show_col_types = FALSE, col_types = cols(.default = "c"))
  names(x)[1] <- "id"; x %>% mutate(batch = basename(.x)) })
cond_of <- function(tn) case_when(str_detect(tn, "interactive") ~ "interactive",
                                   str_detect(tn, "unidirectional") ~ "unidirectional",
                                   str_detect(tn, "slider") ~ "slider")

############################ EXP 1 ############################
dirs1 <- list.files(repo_path("data", "exp1", "raw"), pattern = "^1_prereg_", full.names = TRUE)
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

