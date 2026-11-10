# Experiment 2 analysis data, built from the clean data written by prep/02_exp2_clean.R.
# Source after lib/common.R.
#
#   exp2 <- load_exp2()          the analysed networks (slider version "SR", both conditions)
#   exp2$data                    one row per participant and round with social information
#   exp2$slider_baseline         the slider condition's first estimate (before any social information)
#
# load_exp2("RS") returns the excluded networks and load_exp2("ALL") every network.
# Networks with the "RS" slider version are excluded from the paper because their
# slider messages were inverted (see README, correction 2).

min_max <- function(x) (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
center  <- function(x) x - mean(x, na.rm = TRUE)

load_exp2 <- function(networks = "SR") {
  stopifnot(networks %in% c("SR", "RS", "ALL"))
  sr_games <- read_csv(EXP2_SR_GAMES, show_col_types = FALSE)$gameID

  d <- read_csv(EXP2_CLEAN, show_col_types = FALSE)
  if (networks == "SR") d <- d %>% filter(gameID %in% sr_games)
  if (networks == "RS") d <- d %>% filter(!(gameID %in% sr_games))

  # Condition and slider version from the treatment name (for example "SR_interactive").
  # In the slider condition the round-1 estimate is made before any social
  # information, so slider rounds are shifted down by one.
  d <- d %>% mutate(
    condition = ifelse(str_detect(treatmentName.x, "interactive"), "interactive", "slider"),
    direction = ifelse(str_detect(treatmentName.x, "^RS_"), "RS", "SR"),
    idx_shifted = if_else(condition == "slider", idx - 1, idx))

  # Network statistics over active participants (those with at least one estimate):
  # total sample size, proportion of rabbits, and entropy of the split of the
  # sample across participants.
  active <- d %>%
    filter(!is.na(guess)) %>%
    distinct(gameID, playerID, nCritters, nRabbits, nSquirrels)
  network_stats <- active %>%
    group_by(gameID) %>%
    mutate(share = nCritters / sum(nCritters)) %>%
    summarise(n_active_players = n(),
              nCrittersGame_actual = sum(nCritters),
              nRabbitsGame_actual = sum(nRabbits),
              mleGame_actual = nRabbitsGame_actual / nCrittersGame_actual,
              entropy_actual = -sum(share * log(share + 1e-10)),
              .groups = "drop")
  # Representativeness is the pre-assigned value in the clean data: the mean distance
  # between each assigned participant's sample proportion and the network's.
  # (One network has no active participant; all its statistics are missing.)
  network_stats <- network_stats %>%
    left_join(d %>% distinct(gameID, representation_actual = representation), by = "gameID")
  d <- d %>% left_join(network_stats, by = "gameID")

  # Error: distance of the estimate (0-100) from the network's proportion of rabbits.
  # RS estimates are proportions of squirrels, so the target is inverted for them.
  d <- d %>% mutate(
    mleGame_aligned = ifelse(direction == "RS", 1 - mleGame_actual, mleGame_actual),
    error = abs(guess - mleGame_aligned * 100))

  slider_baseline <- d %>% filter(condition == "slider", idx_shifted == 0)
  d <- d %>% filter(idx_shifted >= 1)

  # Median splits of each difficulty dimension (used for cell means and Figure 5).
  d <- d %>% mutate(
    critters_bin = factor(ifelse(nCrittersGame_actual >= median(nCrittersGame_actual, na.rm = TRUE), "Many", "Few"),
                          levels = c("Few", "Many")),
    entropy_bin = factor(ifelse(entropy_actual >= median(entropy_actual, na.rm = TRUE), "High", "Low"),
                         levels = c("Low", "High")),
    rep_bin = factor(ifelse(representation_actual <= median(representation_actual, na.rm = TRUE),
                            "Representative", "Unrepresentative"),
                     levels = c("Representative", "Unrepresentative")))

  # Model predictors. Condition is effect coded (-0.5 messaging, +0.5 slider). Each
  # difficulty dimension is scaled to 0-1 with higher = harder, then mean centered.
  d <- d %>% mutate(
    condition_c = ifelse(condition == "slider", 0.5, -0.5),
    idx_c = center(idx_shifted),
    critters_scaled = 1 - min_max(nCrittersGame_actual),   # fewer critters = harder
    entropy_scaled  = 1 - min_max(entropy_actual),         # more uneven split = harder
    rep_scaled      = min_max(representation_actual),      # less representative samples = harder
    critters_c = center(critters_scaled),
    entropy_c  = center(entropy_scaled),
    rep_c      = center(rep_scaled))

  list(data = d, slider_baseline = slider_baseline)
}

# The difficulty model of the main text: condition by each difficulty dimension,
# controlling for round and the pairwise interactions between dimensions.
difficulty_model <- error ~ idx_c +
  condition_c * critters_c + condition_c * entropy_c + condition_c * rep_c +
  critters_c * entropy_c + critters_c * rep_c + entropy_c * rep_c +
  (1 | gameID/playerID)
