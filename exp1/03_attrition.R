# Experiment 1: recruitment, exclusions and attrition by condition (Appendix A).
#
# Reads   data/exp1/raw/1_prereg_*/players.csv and games.csv, data/exp1/PreregMergedGuesses.csv,
#         data/derived/exp1_clean_data.csv, exp1_responders.csv
# Prints  the recruitment funnel, the attrition table and the tests of condition differences
source("../lib/common.R")
source("../lib/exp1_data.R")

merged     <- read_csv(EXP1_MERGED, show_col_types = FALSE)   # every estimate
responders <- load_exp1_responders()                          # at least one estimate, condition recorded
retained   <- load_exp1()$guesses                             # the analysed sample

# ---- Everyone assigned to a network that recorded at least one estimate -----------------
batch_dirs <- list.files(repo_path("data", "exp1", "raw"), pattern = "^1_prereg_", full.names = TRUE)
read_raw <- function(file) {
  map_df(batch_dirs, ~ read_csv(file.path(.x, file), show_col_types = FALSE, col_types = cols(.default = "c")))
}
conditions <- read_raw("games.csv") %>%
  filter(!is.na(treatmentName)) %>%
  distinct(gameID = id, treatmentName) %>%
  mutate(condition = factor(str_extract(treatmentName, "slider|unidirectional|interactive"),
                            levels = condition_breaks))
assigned <- read_raw("players.csv") %>%
  filter(gameID %in% merged$gameID) %>%
  distinct(playerID = id, gameID) %>%
  left_join(conditions, by = "gameID") %>%
  mutate(responded = playerID %in% merged$playerID,
         retained = playerID %in% retained$playerID)

cat("==== Recruitment funnel ====\n")
cat("Participants assigned to networks:", n_distinct(assigned$playerID), "\n")
cat("  never entered an estimate:", sum(!assigned$responded), "\n")
cat("  in a network without a recorded condition:", sum(is.na(assigned$condition)), "\n")
cat("  entered at least one estimate, condition recorded:", n_distinct(responders$playerID), "\n")
cat("  excluded, fewer than 80% of rounds answered:",
    n_distinct(responders$playerID) - n_distinct(retained$playerID), "\n")
cat("Analysed:", n_distinct(retained$playerID), "participants in", n_distinct(retained$gameID), "networks\n")

assigned <- assigned %>% filter(!is.na(condition))

# ---- One row per network: participants assigned, responding and retained ----------------
networks <- assigned %>%
  group_by(gameID, condition) %>%
  summarise(n_assigned = n(), n_responded = sum(responded), n_retained = sum(retained), .groups = "drop") %>%
  mutate(complete = n_retained >= 4)

attrition_table <- function(d) {
  d %>% summarise(
    networks_started = n(),
    participants_assigned = sum(n_assigned),
    entered_an_estimate = sum(n_responded),
    retained = sum(n_retained),
    networks_analysed = sum(n_retained > 0),
    networks_with_0 = sum(n_retained == 0), with_1 = sum(n_retained == 1), with_2 = sum(n_retained == 2),
    with_3 = sum(n_retained == 3), with_4 = sum(n_retained == 4), with_5_or_more = sum(n_retained >= 5),
    share_analysed_with_4_or_more = sum(complete) / sum(n_retained > 0))
}
cat("\n==== Attrition by condition (network counts by number of retained participants) ====\n")
print(as.data.frame(bind_rows(
  networks %>% group_by(condition) %>% attrition_table() %>% mutate(condition = as.character(condition)),
  networks %>% attrition_table() %>% mutate(condition = "Total"))))

# ---- Did attrition differ by condition? ---------------------------------------------------
analysed <- networks %>% filter(n_retained > 0)

cat("\n==== Analysed networks that retained at least four participants, by condition ====\n")
print(chisq.test(table(analysed$condition, analysed$complete)))
print(fisher.test(table(analysed$condition, analysed$complete)))

cat("\n==== Number of retained participants per analysed network, by condition ====\n")
print(kruskal.test(n_retained ~ condition, data = analysed))

cat("\n==== Networks lost entirely (no participant retained), by condition ====\n")
print(fisher.test(table(networks$condition, networks$n_retained == 0)))

cat("\n==== Assigned participants who were retained, by condition ====\n")
print(table(assigned$condition, assigned$retained))
print(chisq.test(table(assigned$condition, assigned$retained)))

cat("\n==== Assigned participants who entered at least one estimate, by condition ====\n")
print(table(assigned$condition, assigned$responded))
print(chisq.test(table(assigned$condition, assigned$responded)))
