# Experiment 1: from the raw Empirica exports to the clean data.
#
# Step 1 merges the raw exports (one folder per batch) into one row per estimate.
# Step 2 applies the preregistered exclusion (participants who answered fewer than
#        80% of the 12 rounds) and computes each estimate's error.
#
# Reads   data/exp1/raw/1_prereg_*/
# Writes  data/exp1/PreregMergedGuesses.csv      all estimates (committed)
#         data/derived/exp1_responders.csv       everyone with at least one estimate
#         data/derived/exp1_clean_data.csv       the analysed sample
# Run under a UTF-8 locale: each participant's sample is stored as a string of emoji.
source("../lib/common.R")
source("../lib/exp1_data.R")
dir.create(repo_path("data", "derived"), showWarnings = FALSE)

# ---- Step 1: merge the raw exports ---------------------------------------------
load_batch <- function(batch_dir) {
  read_raw <- function(file) read_csv(file.path(batch_dir, file), show_col_types = FALSE)

  games <- read_raw("games.csv") %>% select(gameID = id, treatmentName) %>% distinct()
  rounds <- read_raw("rounds.csv") %>% select(gameID, roundID = id, idx) %>% distinct()
  # Each participant's sample: count the rabbits and squirrels they were shown
  players <- read_raw("players.csv") %>%
    mutate(nSquirrels = str_count(emojiArray, "🐿️"),
           nRabbits = str_count(emojiArray, "🐇")) %>%
    select(playerID = id, gameID, nSquirrels, nRabbits) %>%
    distinct()

  read_raw("playerStages.csv") %>%
    filter(!is.na(guess)) %>%
    select(gameID, roundID, playerID, guess, confidence) %>%
    left_join(rounds, by = c("gameID", "roundID")) %>%
    left_join(games, by = "gameID") %>%
    left_join(players, by = c("gameID", "playerID")) %>%
    distinct() %>%
    mutate(batch = basename(batch_dir))
}

batch_dirs <- list.files(repo_path("data", "exp1", "raw"), pattern = "^1_prereg_", full.names = TRUE)
estimates <- map_df(batch_dirs, load_batch)

# The batched messaging ("unidirectional") exports contain duplicated rows; keep one of each.
batched <- c("rerun-unidirectional- 0.7", "rerun-unidirectional- 0.3")
estimates <- bind_rows(
  estimates %>% filter(!(treatmentName %in% batched)),
  estimates %>% filter(treatmentName %in% batched) %>%
    distinct(playerID, gameID, guess, roundID, .keep_all = TRUE))

# The target of each estimate (mleEstimateGame): the percentage of rabbits in the combined
# sample of the network members who entered at least one estimate. It is one value per
# network, the same definition as in Experiment 2. mleEstimateIndiv is the same for the
# participant's own sample.
network_samples <- estimates %>%
  distinct(gameID, playerID, nRabbits, nSquirrels) %>%
  group_by(gameID) %>%
  summarise(nRabbitsGame = sum(nRabbits, na.rm = TRUE),
            nSquirrelsGame = sum(nSquirrels, na.rm = TRUE), .groups = "drop")
merged <- estimates %>%
  left_join(network_samples, by = "gameID") %>%
  mutate(mleEstimateIndiv = floor((nRabbits / (nRabbits + nSquirrels)) * 100),
         mleEstimateIndiv = ifelse(is.na(mleEstimateIndiv), 50, mleEstimateIndiv),
         mleEstimateGame = floor((nRabbitsGame / (nRabbitsGame + nSquirrelsGame)) * 100))

write_csv(merged, EXP1_MERGED)
cat("Merged estimates:", n_distinct(merged$playerID), "participants in",
    n_distinct(merged$gameID), "networks\n")

# ---- Step 2: exclusion and error ------------------------------------------------
# Four participants are in a network whose condition was not recorded; they are dropped.
merged <- read_csv(EXP1_MERGED, show_col_types = FALSE) %>% filter(!is.na(treatmentName))

# Split the treatment name (for example "rerun-slider- 0.7") into the condition and
# the true proportion of rabbits, and compute the error of each estimate.
add_condition_and_error <- function(d) {
  d %>%
    mutate(treatmentName = str_remove_all(str_remove(treatmentName, "^rerun-"), " ")) %>%
    separate(treatmentName, into = c("condition", "treatment"), sep = "-") %>%
    mutate(error = abs(guess - mleEstimateGame),
           condition = factor(condition, levels = condition_breaks)) %>%
    arrange(playerID, idx)
}

responders <- add_condition_and_error(merged)
excluded <- exp1_response_rates(merged) %>% filter(response_rate < 0.80) %>% pull(playerID)
clean <- merged %>%
  filter(!(playerID %in% excluded)) %>%
  add_condition_and_error() %>%
  mutate(idx_c = idx - mean(idx))

write_csv(responders, EXP1_RESPONDERS)
write_csv(clean, EXP1_CLEAN)

cat("Participants with at least one estimate:", n_distinct(responders$playerID), "\n")
cat("Excluded (fewer than 80% of rounds answered):", length(excluded), "\n")
cat("Analysed sample:", n_distinct(clean$playerID), "participants in",
    n_distinct(clean$gameID), "networks\n")
print(clean %>% group_by(condition, treatment) %>%
        summarise(networks = n_distinct(gameID), participants = n_distinct(playerID), .groups = "drop"))
