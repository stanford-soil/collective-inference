# Experiment 2 clean data: merges the raw Empirica exports, parses each player's
# critter sample from the emoji string, keeps games with four players who all
# finished, computes game-level statistics and matches each game to its generated
# configuration (designatedGame).
# Input: data/exp2/raw/<batch>/, stimuli/exp2_combined_generation/generated_files_used/*.json.
# Output: data/derived/exp2_clean_data.csv (all games, SR and RS; the SR restriction
#   is applied when the data are loaded, see lib/exp2_data.R).
# Run from prep/ under a UTF-8 locale. Logic from the original analysis/exp2/1_data_cleaning.qmd.
source("../lib/common.R")
library(jsonlite)

# The critter counts below are parsed from emoji strings. Under a non-UTF-8
# locale the emoji do not match and every player silently gets 0 critters,
# so stop early instead.
if (!isTRUE(l10n_info()$`UTF-8`)) {
  stop("Run this script under a UTF-8 locale (e.g. LC_ALL=en_US.UTF-8 or C.UTF-8).")
}

# Batches, in the order used for the original clean data file
batches <- c("11-22-2101", "11-20-2234", "11-20-2246", "11-21-0329", "11-22-1731", "11-26-1646", "01-02-1848", "01-02-2022", "01-02-2134", "01-02-2211", "01-03-2051", "01-03-2201", "01-03-2348", "01-04-0302", "01-04-0431", "01-10-0257", "01-10-0433", "01-11-2206", "01-14-2139", "01-17-2124", "01-17-2245", "01-19-0217", "01-19-0243")
read_batches <- function(file) {
  suppressMessages(bind_rows(lapply(batches, function(b)
    read_csv(repo_path("data", "exp2", "raw", b, file), show_col_types = FALSE))))
}

d.1 <- read_batches("playerStage.csv")
d.2 <- read_batches("round.csv") %>% rename(roundID = id)
d.3 <- read_batches("stage.csv") %>% rename(stageID = id) %>% rename(stageName = name)
d.5 <- read_batches("playerGame.csv")
d.6 <- read_batches("player.csv") %>%
  rename(playerID = id) %>%
  select(-contains("LastChangedAt")) %>%
  filter(ended == "game ended")
d.8 <- read_batches("game.csv") %>% rename(gameID = id)
d.9 <- read_batches("batch.csv") %>% rename(batchID = id)

# Generated game configurations (configuration 10120 is listed with five players;
# its games were played with four and are handled below)
decode1 <- read_json(repo_path('stimuli', 'exp2_combined_generation', 'generated_files_used', 'games_dontoverwrite.json'), simplifyVector = TRUE) %>%
  as_tibble() %>%
  rename(nCrittersGame = totalCritters) %>%
  rename(designatedGame = gameID)%>%
   filter(designatedGame != 10120) %>%
  mutate(representation = as.character(representation))

decode3 <- read_json(repo_path('stimuli', 'exp2_combined_generation', 'generated_files_used', 'games_2_dontoverwrite.json'), simplifyVector = TRUE) %>%
  as_tibble() %>%
  rename(nCrittersGame = totalCritters) %>%
  rename(designatedGame = gameID)%>%
  mutate(nCrittersGame = as.integer(nCrittersGame)) %>%
  mutate(representation = as.character(representation))

decode <- bind_rows(decode1, decode3)

# Merge games, batches, players and guesses
d.gamebatch <- merge(d.8, d.9, by = c("batchID"), all=T)%>%
  select(-contains("LastChangedAt"))

d.playergamebatch <-merge(d.6, d.gamebatch, by="gameID", all = T)

d.59 <-merge(d.playergamebatch,d.5, by = c("gameID", "playerID"), all = T)%>%
  select(-contains("LastChangedAt"))

rm(d.8, d.9, d.6, d.gamebatch, d.playergamebatch, d.5)

d.stageID <- merge(d.1, d.3, by = c("stageID", "gameID", "roundID"), all = T) %>%
  select(-contains("LastChangedAt"))


d.playerstageround <-merge(d.stageID,d.2, by = c("roundID", "gameID"), all = T)%>%
  select(-contains("LastChangedAt"))%>%
  select(gameID, stageName, roundID, confidence, guess, playerID, stageID,idx)

rm(d.1, d.2, d.stageID, d.3)

d.all <-merge(d.playerstageround,d.59, by = c("playerID", "gameID"), all = T)%>%
  select(gameID, playerID, stageName, treatmentName.x, ended.x, roundID, confidence, guess, stageID.x, idx, emojiArray, exitSurvey, participantID, recipient,treatment.x, chat,messages, participantIdentifier)%>%
  mutate(
    emojiArray = str_remove_all(emojiArray, "\\s"),
    emojiArray = str_extract_all(emojiArray, "🐇|🐿️"),
    nRabbits = sapply(emojiArray, function(x) sum(x == "🐇")),
    nSquirrels = sapply(emojiArray, function(x) sum(x == "🐿️")),
    nCritters = nSquirrels + nRabbits,
    mleEstimate = nRabbits / (nRabbits + nSquirrels)
  ) 

stopifnot("No critters parsed; check the locale" = sum(d.all$nCritters, na.rm = TRUE) > 0)

rm(d.59, d.playerstageround)

# Keep games with four players who all finished; one row per observe stage
d.all <- d.all %>%
  distinct() %>%
  group_by(gameID) %>%
  mutate(num_players = n_distinct(playerID)) %>%
  ungroup() %>%
  filter(num_players == 4) %>%
  filter(ended.x == 'game ended') %>%
  filter(stageName == 'observe')

# Game-level statistics from all four assigned players
d.allgameplayers <- d.all %>%
   distinct(playerID, gameID, .keep_all = TRUE) %>%
  group_by(gameID) %>%
  mutate(
    nRabbitsGame = sum(nRabbits, na.rm = TRUE),
    nSquirrelsGame = sum(nSquirrels, na.rm = TRUE),
    nCrittersGame = sum(nCritters, na.rm = TRUE),
    mleGame = round(nRabbitsGame / (nRabbitsGame + nSquirrelsGame),4),
    prob = round(nCritters / nCrittersGame, 4),
    entropy = round(-sum(ifelse(prob > 0, prob * log(prob), 0)), 4),
    representation = round(mean(abs(mleEstimate - mleGame)), 4)
  ) %>%
  ungroup()

# Match played games to generated configurations. Configurations 10297 and 3627 are
# identical random draws; keep the first entry of each designatedGame.
d.decode <- decode%>%
  distinct(designatedGame, .keep_all = TRUE)

d.allgameplayers <- d.allgameplayers %>%
  mutate(across(c(nCrittersGame, representation, entropy), as.character))

d.decode <- d.decode %>%
  mutate(across(c(nCrittersGame, representation, entropy), as.character))

d.allgameplayers <- d.allgameplayers %>%
  mutate(representation_formatted = sprintf("%.3f", as.numeric(representation)))

d.decode <- d.decode %>%
  mutate(representation_formatted = sprintf("%.3f", as.numeric(representation)))

d.allgameplayers <- d.allgameplayers %>%
  left_join(
    d.decode %>%
      distinct(
        nCrittersGame, nRabbitsGame, nSquirrelsGame, mleGame, representation_formatted, designatedGame, entropy_bin, representation_bin, nCrittersGame_bin
      ),
    by = c("nCrittersGame", "nRabbitsGame", "nSquirrelsGame", "mleGame", "representation_formatted")
  )


d.all <- d.all %>%
  left_join(
    d.allgameplayers %>%
      select(nSquirrelsGame, nRabbitsGame, nCrittersGame, gameID, mleGame, prob, entropy, representation, designatedGame, entropy_bin, representation_bin,nCrittersGame_bin) %>%
      distinct(gameID, .keep_all = TRUE), 
    by = c("gameID")
  )

# Games without a matching configuration were generated from configuration 10120
# (listed with five players, played with four): designatedGame = 0
d.modified <- d.all %>%
  filter(is.na(designatedGame))%>%
  mutate(
    designatedGame = 0,
    entropy_bin = '(0.81,1.1]',
    representation_bin = '(0.24,0.36]',
    nCrittersGame_bin = '(20,25]'
  )
d.all$designatedGame <- as.character(d.all$designatedGame)
d.modified$designatedGame <- as.character(d.modified$designatedGame)

d.all <- d.all %>% 
  filter(!is.na(designatedGame))%>%
  bind_rows(d.modified)

# Write the clean data (list columns collapsed to strings)
list_cols <- sapply(d.all, is.list)
d.all[list_cols] <- lapply(d.all[list_cols], function(col) {
  sapply(col, paste, collapse = ";") # Collapse lists into strings
})
d.all <- d.all %>%
  select(-messages, -emojiArray, -treatment.x, -num_players, -chat)
dir.create(repo_path("data", "derived"), showWarnings = FALSE)
write.csv(d.all, EXP2_CLEAN, row.names = FALSE)
cat("Wrote", EXP2_CLEAN, ":", n_distinct(d.all$gameID), "games,", n_distinct(d.all$playerID), "players\n")

# The analysed Experiment 2 networks are listed in lib/exp2_sr_games.csv (the SR
# treatments in both conditions). Check that the list matches the clean data.
sr_list <- read_csv(EXP2_SR_GAMES, show_col_types = FALSE)$gameID
sr_data <- unique(d.all$gameID[grepl("^SR_", d.all$treatmentName.x)])
stopifnot(setequal(sr_list, sr_data))
cat("SR networks:", length(sr_list), "(matches lib/exp2_sr_games.csv)\n")
