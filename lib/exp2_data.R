# Experiment 2 analysis data, built from the clean data written by
# prep/03_exp2_clean.R. Sourced after lib/common.R.
#   load_exp2(subset) -> list(d.all, d.slider_baseline)
# subset: "SR" (default; the networks analysed in the paper, listed in
# lib/exp2_sr_games.csv), "RS" (the excluded networks) or "ALL". The default can be
# overridden with the environment variable SUBSET. This is the only place where the
# SR restriction is applied for the R analyses.
# The derived variables follow the original Experiment 2 notebook
# (analysis/exp2/exp2_main_analysis.qmd, sections Load Data to Effect Coding).

exp2_subset <- function(subset = NULL) {
  if (is.null(subset)) subset <- Sys.getenv("SUBSET", "SR")
  if (subset == "") subset <- "SR"
  stopifnot(subset %in% c("SR", "RS", "ALL"))
  subset
}

load_exp2 <- function(subset = NULL) {
  subset <- exp2_subset(subset)
  d.all <- read_csv(EXP2_CLEAN, show_col_types = FALSE)
  sr_games <- read_csv(EXP2_SR_GAMES, show_col_types = FALSE)$gameID
  if (subset == "SR") d.all <- d.all %>% filter(gameID %in% sr_games)
  if (subset == "RS") d.all <- d.all %>% filter(!(gameID %in% sr_games))

  # Condition and slider direction from the treatment name
  d.all <- d.all %>%
    mutate(
      condition = ifelse(str_detect(treatmentName.x, "interactive"), "interactive", "slider"),
      direction = ifelse(str_detect(treatmentName.x, "^RS_"), "RS", "SR")
    )

  # Slider round 1 is the estimate made before any social information: shift the
  # slider rounds so that round 1 is the first round with social information
  d.all <- d.all %>% mutate(idx_shifted = if_else(condition == "slider", idx - 1, idx))

  # Game-level statistics recomputed over active players (at least one estimate)
  active_players <- d.all %>%
    filter(!is.na(guess)) %>%
    distinct(gameID, playerID, nCritters, nRabbits, nSquirrels)

  game_metrics_actual <- active_players %>%
    group_by(gameID) %>%
    summarise(
      n_active_players = n(),
      nCrittersGame_actual = sum(nCritters),
      nRabbitsGame_actual = sum(nRabbits),
      mleGame_actual = nRabbitsGame_actual / nCrittersGame_actual,
      .groups = "drop"
    )

  entropy_actual <- active_players %>%
    group_by(gameID) %>%
    mutate(total_critters = sum(nCritters), p_i = nCritters / total_critters) %>%
    summarise(entropy_actual = -sum(p_i * log(p_i + 1e-10)), .groups = "drop")

  # Representativeness: the existing game-level column (mean |individual MLE -
  # network MLE| over the four assigned players)
  game_metrics_actual <- game_metrics_actual %>%
    left_join(entropy_actual, by = "gameID") %>%
    left_join(
      d.all %>% distinct(gameID, representation) %>% rename(representation_actual = representation),
      by = "gameID"
    )

  d.all <- d.all %>% left_join(game_metrics_actual, by = "gameID")

  # In RS games the majority was squirrels but participants report % rabbits,
  # so the network MLE is inverted for RS games
  d.all <- d.all %>%
    mutate(mleGame_aligned = ifelse(direction == "RS", 1 - mleGame_actual, mleGame_actual))

  # Absolute error from the aligned network MLE
  d.all <- d.all %>% mutate(error = abs(guess - mleGame_aligned * 100))

  # Slider pre-social baseline (idx_shifted = 0), kept for plotting
  d.slider_baseline <- d.all %>% filter(condition == "slider", idx_shifted == 0)

  # Analyses use rounds with social information only
  d.all <- d.all %>% filter(idx_shifted >= 1)

  # Median splits on each difficulty dimension (active-player statistics)
  d.all <- d.all %>%
    mutate(
      critters_easy = nCrittersGame_actual >= median(nCrittersGame_actual, na.rm = TRUE),
      entropy_easy = entropy_actual >= median(entropy_actual, na.rm = TRUE),
      rep_easy = representation_actual <= median(representation_actual, na.rm = TRUE),  # lower = easier
      difficulty_profile = paste0(
        ifelse(critters_easy, "E", "H"),
        ifelse(entropy_easy, "E", "H"),
        ifelse(rep_easy, "E", "H")
      ),
      n_hard = (!critters_easy) + (!entropy_easy) + (!rep_easy),
      critters_bin = factor(ifelse(critters_easy, "Many", "Few"), levels = c("Few", "Many")),
      entropy_bin = factor(ifelse(entropy_easy, "High", "Low"), levels = c("Low", "High")),
      rep_bin = factor(ifelse(rep_easy, "Representative", "Unrepresentative"),
                       levels = c("Representative", "Unrepresentative"))
    )

  d.slider_baseline <- d.slider_baseline %>%
    left_join(d.all %>% distinct(gameID, n_hard, critters_bin, entropy_bin, rep_bin), by = "gameID")

  # Effect coding: condition -0.5 = real-time messaging (interactive), +0.5 = slider.
  # Difficulty dimensions scaled to 0-1 (higher = harder) and mean-centered.
  d.all <- d.all %>%
    mutate(
      condition_c = ifelse(condition == "slider", 0.5, -0.5),
      idx_c = idx_shifted - mean(idx_shifted, na.rm = TRUE),
      critters_scaled = 1 - (nCrittersGame_actual - min(nCrittersGame_actual, na.rm = TRUE)) /
                            (max(nCrittersGame_actual, na.rm = TRUE) - min(nCrittersGame_actual, na.rm = TRUE)),
      entropy_scaled = 1 - (entropy_actual - min(entropy_actual, na.rm = TRUE)) /
                           (max(entropy_actual, na.rm = TRUE) - min(entropy_actual, na.rm = TRUE)),
      rep_scaled = (representation_actual - min(representation_actual, na.rm = TRUE)) /
                   (max(representation_actual, na.rm = TRUE) - min(representation_actual, na.rm = TRUE)),
      critters_c = critters_scaled - mean(critters_scaled, na.rm = TRUE),
      entropy_c = entropy_scaled - mean(entropy_scaled, na.rm = TRUE),
      rep_c = rep_scaled - mean(rep_scaled, na.rm = TRUE)
    )

  list(d.all = d.all, d.slider_baseline = d.slider_baseline, subset = subset)
}
