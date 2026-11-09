# Experiment 2: from the raw Empirica exports to the clean data.
#
# Merges the raw exports, counts each participant's sample, keeps the networks in
# which all four participants finished, computes each network's difficulty
# statistics, and matches each network to the game configuration it was generated from.
#
# Reads   data/exp2/raw/<batch>/
#         stimuli/exp2_combined_generation/generated_files_used/*.json
# Writes  data/derived/exp2_clean_data.csv   one row per participant and round, all
#         379 retained networks. The analyses use the 193 networks listed in
#         lib/exp2_sr_games.csv (see lib/exp2_data.R).
# Run under a UTF-8 locale: each participant's sample is stored as a string of emoji.
source("../lib/common.R")
suppressPackageStartupMessages(library(jsonlite))
if (!isTRUE(l10n_info()$`UTF-8`)) stop("Run this script under a UTF-8 locale (for example LC_ALL=C.UTF-8).")

# ---- Read the raw exports --------------------------------------------------------
batches <- c("11-22-2101", "11-20-2234", "11-20-2246", "11-21-0329", "11-22-1731", "11-26-1646",
             "01-02-1848", "01-02-2022", "01-02-2134", "01-02-2211", "01-03-2051", "01-03-2201",
             "01-03-2348", "01-04-0302", "01-04-0431", "01-10-0257", "01-10-0433", "01-11-2206",
             "01-14-2139", "01-17-2124", "01-17-2245", "01-19-0217", "01-19-0243")
read_raw <- function(file) {
  suppressMessages(bind_rows(lapply(batches, function(batch)
    read_csv(repo_path("data", "exp2", "raw", batch, file), show_col_types = FALSE))))
}
drop_timestamps <- function(d) d %>% select(-contains("LastChangedAt"))

player_stages <- read_raw("playerStage.csv")
rounds        <- read_raw("round.csv") %>% rename(roundID = id)
stages        <- read_raw("stage.csv") %>% rename(stageID = id, stageName = name)
player_games  <- read_raw("playerGame.csv")
players       <- read_raw("player.csv") %>% rename(playerID = id) %>% drop_timestamps() %>%
  filter(ended == "game ended")
games         <- read_raw("game.csv") %>% rename(gameID = id)
batch_info    <- read_raw("batch.csv") %>% rename(batchID = id)

# ---- Merge into one row per participant and stage ---------------------------------
games_with_batch <- merge(games, batch_info, by = "batchID", all = TRUE) %>% drop_timestamps()
players_with_game <- merge(players, games_with_batch, by = "gameID", all = TRUE)
players_with_game <- merge(players_with_game, player_games, by = c("gameID", "playerID"), all = TRUE) %>%
  drop_timestamps()

estimates <- merge(player_stages, stages, by = c("stageID", "gameID", "roundID"), all = TRUE) %>%
  drop_timestamps()
estimates <- merge(estimates, rounds, by = c("roundID", "gameID"), all = TRUE) %>%
  drop_timestamps() %>%
  select(gameID, stageName, roundID, confidence, guess, playerID, stageID, idx)

d <- merge(estimates, players_with_game, by = c("playerID", "gameID"), all = TRUE) %>%
  select(gameID, playerID, stageName, treatmentName.x, ended.x, roundID, confidence, guess, stageID.x, idx,
         emojiArray, exitSurvey, participantID, recipient, treatment.x, chat, messages, participantIdentifier)

# Each participant's sample: count the rabbits and squirrels they were shown
d <- d %>% mutate(
  emojiArray = str_extract_all(str_remove_all(emojiArray, "\\s"), "🐇|🐿️"),
  nRabbits = sapply(emojiArray, function(x) sum(x == "🐇")),
  nSquirrels = sapply(emojiArray, function(x) sum(x == "🐿️")),
  nCritters = nSquirrels + nRabbits,
  mleEstimate = nRabbits / (nRabbits + nSquirrels))
stopifnot("No critters parsed; check the locale" = sum(d$nCritters, na.rm = TRUE) > 0)

# ---- Keep networks with four participants who all finished -------------------------
# One row per participant and round (the "observe" stage holds the estimate).
d <- d %>%
  distinct() %>%
  group_by(gameID) %>%
  mutate(num_players = n_distinct(playerID)) %>%
  ungroup() %>%
  filter(num_players == 4, ended.x == "game ended", stageName == "observe")

# ---- Network difficulty statistics (from all four assigned participants) -----------
#   nCrittersGame    total sample size
#   mleGame          proportion of rabbits in the combined sample
#   entropy          how evenly the sample is split across the four participants
#   representation   mean distance between each participant's proportion and the network's
network_stats <- d %>%
  distinct(playerID, gameID, .keep_all = TRUE) %>%
  group_by(gameID) %>%
  mutate(nRabbitsGame = sum(nRabbits, na.rm = TRUE),
         nSquirrelsGame = sum(nSquirrels, na.rm = TRUE),
         nCrittersGame = sum(nCritters, na.rm = TRUE),
         mleGame = round(nRabbitsGame / (nRabbitsGame + nSquirrelsGame), 4),
         prob = round(nCritters / nCrittersGame, 4),
         entropy = round(-sum(ifelse(prob > 0, prob * log(prob), 0)), 4),
         representation = round(mean(abs(mleEstimate - mleGame)), 4)) %>%
  ungroup()

# ---- Match each network to its generated configuration -----------------------------
# The configurations are in two files. Configuration 10120 is listed with five
# players but was played with four; it is handled separately below.
read_configurations <- function(file) {
  read_json(repo_path("stimuli", "exp2_combined_generation", "generated_files_used", file),
            simplifyVector = TRUE) %>%
    as_tibble() %>%
    rename(nCrittersGame = totalCritters, designatedGame = gameID) %>%
    mutate(nCrittersGame = as.integer(nCrittersGame), representation = as.character(representation))
}
configurations <- bind_rows(
  read_configurations("games_dontoverwrite.json") %>% filter(designatedGame != 10120),
  read_configurations("games_2_dontoverwrite.json")) %>%
  distinct(designatedGame, .keep_all = TRUE)

# A network matches a configuration when its counts and statistics agree.
match_keys <- c("nCrittersGame", "nRabbitsGame", "nSquirrelsGame", "mleGame", "representation_formatted")
as_match_table <- function(x) {
  x %>% mutate(across(c(nCrittersGame, representation, entropy), as.character),
               representation_formatted = sprintf("%.3f", as.numeric(representation)))
}
network_stats <- as_match_table(network_stats) %>%
  left_join(as_match_table(configurations) %>%
              distinct(across(all_of(match_keys)), designatedGame, entropy_bin, representation_bin, nCrittersGame_bin),
            by = match_keys, relationship = "many-to-many")

# Two configurations are identical draws, so their networks match both; the first match is kept.
d <- d %>%
  left_join(network_stats %>%
              select(nSquirrelsGame, nRabbitsGame, nCrittersGame, gameID, mleGame, prob, entropy, representation,
                     designatedGame, entropy_bin, representation_bin, nCrittersGame_bin) %>%
              distinct(gameID, .keep_all = TRUE),
            by = "gameID")

# Networks without a match were generated from configuration 10120: designatedGame = 0.
from_10120 <- d %>%
  filter(is.na(designatedGame)) %>%
  mutate(designatedGame = 0, entropy_bin = "(0.81,1.1]", representation_bin = "(0.24,0.36]",
         nCrittersGame_bin = "(20,25]")
d <- bind_rows(d %>% filter(!is.na(designatedGame)) %>% mutate(designatedGame = as.character(designatedGame)),
               from_10120 %>% mutate(designatedGame = as.character(designatedGame)))

# ---- Write -------------------------------------------------------------------------
d <- d %>% select(-messages, -emojiArray, -treatment.x, -num_players, -chat)
dir.create(repo_path("data", "derived"), showWarnings = FALSE)
write.csv(d, EXP2_CLEAN, row.names = FALSE)
cat("Wrote exp2_clean_data.csv:", n_distinct(d$gameID), "networks,", n_distinct(d$playerID), "participants\n")

# The analysed networks (lib/exp2_sr_games.csv) are those with the "SR" slider version.
sr_listed <- read_csv(EXP2_SR_GAMES, show_col_types = FALSE)$gameID
sr_in_data <- unique(d$gameID[grepl("^SR_", d$treatmentName.x)])
stopifnot(setequal(sr_listed, sr_in_data))
cat("Analysed networks (SR slider version):", length(sr_listed), "\n")
