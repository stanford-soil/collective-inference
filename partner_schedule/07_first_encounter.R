# Do participants give more weight to a sender they are hearing from for the first
# time than to a sender they have heard from before? (Reviewer 2, point 3)
#
# For every participant and every round in which they received information:
#   update = estimate after receiving - estimate before receiving
#   dist   = sender's information     - estimate before receiving
# The slope of update on dist is the weight given to the sender's information
# (0 = ignored, 1 = adopted). The model lets this weight differ between first and
# later encounters with the same sender, and change linearly over rounds:
#   update ~ dist * first + dist * round_c + random effects
#     dist          weight on a later encounter, at the mean round
#     dist:first    extra weight on a first encounter
#     dist:round_c  change in weight per round
#
# Timing. Slider: the estimate in round t+1 follows the estimate the sender
# submitted in round t. Messaging: messages precede the estimate within a round, so
# the estimate in round t follows the round-t sender's messages. The sender's
# information is taken to be (a) the sender's previous estimate, or (b) for the
# messaging conditions also the proportion of rabbits in the sender's own sample.
#
# Reads   data/derived/exp1_clean_data.csv, exp2_clean_data.csv,
#         data/exp1/PreregMergedGuesses.csv, data/derived/exp1_partners.csv, exp2_partners.csv
# Prints  the weights and coefficients for every condition and specification
source("../lib/common.R")

# ---- Data --------------------------------------------------------------------------
# Experiment 1. Focal participants are the analysed sample; a sender's estimates and
# sample are used even if the sender was excluded for a low response rate.
exp1_all <- read_csv(EXP1_MERGED, show_col_types = FALSE) %>%
  filter(!is.na(treatmentName)) %>%
  distinct(gameID, playerID, idx, .keep_all = TRUE)
exp1_focal     <- read_csv(EXP1_CLEAN, show_col_types = FALSE) %>%
  select(gameID, playerID, condition, round = idx, guess)
exp1_estimates <- exp1_all %>% select(gameID, playerID, round = idx, guess)
exp1_samples   <- exp1_all %>% distinct(gameID, playerID, sample_proportion = mleEstimateIndiv)
exp1_schedule  <- read_csv(EXP1_PARTNERS, show_col_types = FALSE)

# Experiment 2, analysed networks.
sr_games <- read_csv(EXP2_SR_GAMES, show_col_types = FALSE)$gameID
exp2_all <- read_csv(EXP2_CLEAN, show_col_types = FALSE) %>%
  filter(gameID %in% sr_games) %>%
  mutate(condition = ifelse(str_detect(treatmentName.x, "slider"), "slider", "interactive"))
exp2_focal     <- exp2_all %>% filter(!is.na(guess)) %>%
  select(gameID, playerID, condition, round = idx, guess)
exp2_estimates <- exp2_focal %>% select(gameID, playerID, round, guess)
exp2_samples   <- exp2_all %>% distinct(gameID, playerID, sample_proportion = 100 * mleEstimate)
exp2_schedule  <- read_csv(EXP2_PARTNERS, show_col_types = FALSE) %>% filter(gameID %in% exp2_all$gameID)

# ---- One row per occasion on which a participant received information ----------------
build_transitions <- function(focal, estimates, samples, schedule) {
  # first:     the participant has not received from this sender in an earlier round
  # first_any: no earlier contact in either direction (received from or sent to)
  schedule <- schedule %>%
    arrange(gameID, playerID, round) %>%
    group_by(gameID, playerID, partnerID) %>%
    mutate(first = as.integer(row_number() == 1)) %>%
    group_by(gameID, playerID) %>%
    mutate(first_any = sapply(seq_along(round), function(i) {
      earlier_contacts <- c(partnerID[seq_len(i - 1)], recipientID[seq_len(i - 1)])
      as.integer(!(partnerID[i] %in% earlier_contacts))
    })) %>%
    ungroup() %>%
    select(gameID, playerID, round, partnerID, first, first_any, reciprocal)

  own <- focal %>% select(gameID, playerID, round, guess)
  schedule %>%
    inner_join(focal %>% distinct(gameID, playerID, condition), by = c("gameID", "playerID")) %>%
    mutate(slider = condition == "slider",
           before_round = ifelse(slider, round, round - 1),
           after_round  = ifelse(slider, round + 1, round),
           sender_round = ifelse(slider, round, round - 1)) %>%
    left_join(own %>% rename(before_round = round, before = guess), by = c("gameID", "playerID", "before_round")) %>%
    left_join(own %>% rename(after_round = round, after = guess), by = c("gameID", "playerID", "after_round")) %>%
    left_join(estimates %>% rename(partnerID = playerID, sender_round = round, sender_guess = guess),
              by = c("gameID", "partnerID", "sender_round")) %>%
    left_join(samples %>% rename(partnerID = playerID), by = c("gameID", "partnerID")) %>%
    filter(!is.na(before), !is.na(after)) %>%
    mutate(update = after - before,
           dist_estimate = sender_guess - before,
           dist_sample = sample_proportion - before,
           t = after_round)
}

exp1 <- build_transitions(exp1_focal, exp1_estimates, exp1_samples, exp1_schedule)
exp2 <- build_transitions(exp2_focal, exp2_estimates, exp2_samples, exp2_schedule)

# ---- Model ---------------------------------------------------------------------------
# Random intercepts for participant and network, plus a random slope of dist by
# participant when that model converges without a singular fit.
fit_weights <- function(d, extra_terms = "") {
  fixed <- paste("update ~ dist * first + dist * round_c", extra_terms)
  with_slope <- tryCatch(
    suppressMessages(suppressWarnings(
      lmer(as.formula(paste(fixed, "+ (1 + dist | playerID) + (1 | gameID)")), data = d))),
    error = function(e) NULL)
  slope_ok <- !is.null(with_slope) && !isSingular(with_slope) &&
    length(with_slope@optinfo$conv$lme4$messages) == 0
  if (slope_ok) return(list(model = with_slope, random = "(1 + dist | participant) + (1 | network)"))
  list(model = suppressMessages(lmer(as.formula(paste(fixed, "+ (1 | playerID) + (1 | gameID)")), data = d)),
       random = "(1 | participant) + (1 | network)")
}

# Specifications. The first is the one reported in the response letter; the others
# show how far the estimates depend on the specification.
specifications <- list(
  "primary"                      = list(first = "first",     extra = "",                  drop_first_transition = FALSE),
  "first = no earlier contact"   = list(first = "first_any", extra = "",                  drop_first_transition = FALSE),
  "+ dist x mutual round"        = list(first = "first",     extra = "+ dist * recip",    drop_first_transition = FALSE),
  "+ dist x round squared"       = list(first = "first",     extra = "+ dist * round_c2", drop_first_transition = FALSE),
  "without the first transition" = list(first = "first",     extra = "",                  drop_first_transition = TRUE))

run_condition <- function(transitions, experiment, condition_name) {
  information <- c(dist_estimate = "sender's previous estimate")
  if (condition_name != "slider") information <- c(information, dist_sample = "sender's sample proportion")

  for (info in names(information)) {
    for (spec_name in names(specifications)) {
      spec <- specifications[[spec_name]]
      d <- transitions %>%
        filter(condition == condition_name, !is.na(.data[[info]])) %>%
        mutate(dist = .data[[info]], first = .data[[spec$first]], recip = as.integer(reciprocal))
      if (spec$drop_first_transition) d <- d %>% filter(t > 2)
      d <- d %>% mutate(round_c = t - mean(t), round_c2 = round_c^2)

      fitted <- fit_weights(d, spec$extra)
      coefs <- coef(summary(fitted$model))
      b <- fixef(fitted$model)
      V <- as.matrix(vcov(fitted$model))
      se_first <- sqrt(V["dist", "dist"] + V["dist:first", "dist:first"] + 2 * V["dist", "dist:first"])

      cat(sprintf("\n=== %s | %s | information: %s | %s ===\n",
                  experiment, condition_labels[[condition_name]], information[[info]], spec_name))
      cat(sprintf("%d transitions (%d first, %d later); %d participants; %d networks; random effects: %s\n",
                  nrow(d), sum(d$first == 1), sum(d$first == 0),
                  n_distinct(d$playerID), n_distinct(d$gameID), fitted$random))
      print(round(coefs[grepl("dist", rownames(coefs)), ], 4))
      cat(sprintf("Weight at the mean round: first encounter %.3f (SE %.3f), later %.3f (SE %.3f)\n",
                  b["dist"] + b["dist:first"], se_first, b["dist"], sqrt(V["dist", "dist"])))
    }
  }
}

for (condition_name in c("slider", "unidirectional", "interactive")) run_condition(exp1, "Experiment 1", condition_name)
for (condition_name in c("slider", "interactive")) run_condition(exp2, "Experiment 2", condition_name)

# ---- Does the first-encounter effect differ by condition? (Experiment 1) ----------------
pooled <- exp1 %>%
  filter(!is.na(dist_estimate)) %>%
  mutate(dist = dist_estimate, round_c = t - mean(t),
         condition = factor(condition, levels = condition_breaks))
pooled_model <- lmer(update ~ dist * first * condition + dist * round_c * condition +
                       (1 | playerID) + (1 | gameID), data = pooled)
cat("\n=== Experiment 1, all conditions: dist x first x condition (slider = reference) ===\n")
coefs <- coef(summary(pooled_model))
print(round(coefs[grepl("dist:first", rownames(coefs)), ], 4))
cat("\nF test of dist x first x condition:\n")
print(anova(pooled_model)["dist:first:condition", ])

# First encounters and early rounds coincide: where the first encounters fall.
cat("\nExperiment 1 transitions by number of players at launch and first encounter:\n")
print(exp1 %>%
        left_join(exp1_schedule %>% distinct(gameID, nPlayers), by = "gameID") %>%
        count(condition, nPlayers, first) %>%
        pivot_wider(names_from = first, values_from = n, names_prefix = "first_"))
