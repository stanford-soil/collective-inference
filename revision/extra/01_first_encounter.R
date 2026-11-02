# Reviewer 2, point 3: do participants weight a sender's information more on
# the first encounter with that sender than on later encounters?
#
# Run from this folder:  Rscript 01_first_encounter.R
#
# For every focal player and every round in which they received information,
# we compute
#   update = (focal estimate after receiving) - (focal estimate before)
#   dist   = (sender's information)            - (focal estimate before)
# The slope of update on dist is the weight given to the sender's information
# (0 = ignored, 1 = adopted). We let this slope differ between first and later
# encounters with the same sender, and also let it change linearly with round.
#
# Timing (see revision/README.md and models/fit.py):
#   slider:   transition t -> t+1, sender = who the player received from in
#             round t, sender information = sender's round-t estimate.
#   messages: transition t-1 -> t, sender = who the player received from in
#             round t (chat precedes the round-t estimate). Two codings of the
#             sender's information: (a) sender's round-(t-1) estimate;
#             (b) sender's private-sample MLE.
# first = 1 if the focal player has not received from this sender in any
# earlier round (from the per-round partner tables).
#
# Exp 1: focal players are those in analysis/exp1/exp1_clean_data.csv (>= 80%
# response); sender estimates and samples come from all responders in
# data/exp1/PreregMergedGuesses.csv. Exp 2: SR games only.

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(stringr)
  library(lme4); library(lmerTest)
})
REPO <- "../.."
sink_file <- "01_first_encounter_output.txt"
zz <- file(sink_file, open = "wt"); sink(zz, split = TRUE)

# ---------------------------------------------------------------- Exp 1 data
e.clean <- read_csv(file.path(REPO, "analysis/exp1/exp1_clean_data.csv"), show_col_types = FALSE)
e.raw   <- read_csv(file.path(REPO, "data/exp1/PreregMergedGuesses.csv"), show_col_types = FALSE) %>%
  filter(!is.na(treatmentName)) %>%
  distinct(gameID, playerID, idx, .keep_all = TRUE)
p1 <- read_csv(file.path(REPO, "revision/partner_schedule/exp1_partners.csv"), show_col_types = FALSE)

focal1 <- e.clean %>% select(gameID, playerID, condition, round = idx, guess)
allg1  <- e.raw %>% select(gameID, playerID, round = idx, guess)
samp1  <- e.raw %>% distinct(gameID, playerID, mle = mleEstimateIndiv)

# ---------------------------------------------------------------- Exp 2 data
x <- read_csv(file.path(REPO, "analysis/exp2/exp2_clean_data.csv"), show_col_types = FALSE) %>%
  filter(str_starts(treatmentName.x, "SR_")) %>%
  mutate(condition = ifelse(str_detect(treatmentName.x, "slider"), "slider", "interactive"))
p2 <- read_csv(file.path(REPO, "revision/partner_schedule/exp2_partners_playerround.csv"), show_col_types = FALSE) %>%
  filter(gameID %in% x$gameID)

# SR games: the slider measures the rabbit share, so no conversion is needed.
focal2 <- x %>% filter(!is.na(guess)) %>% select(gameID, playerID, condition, round = idx, guess)
allg2  <- focal2 %>% select(gameID, playerID, round, guess)
samp2  <- x %>% distinct(gameID, playerID, mle = 100 * mleEstimate)

# ---------------------------------------------------------- build transitions
build <- function(focal, allg, samp, partners) {
  partners <- partners %>%
    arrange(gameID, playerID, round) %>%
    group_by(gameID, playerID, partnerID) %>%
    mutate(first = as.integer(row_number() == 1)) %>%
    ungroup() %>%
    group_by(gameID, playerID) %>%
    # any earlier contact in either direction (received from or sent to)
    mutate(first_any = sapply(seq_along(round), function(i)
      as.integer(!(partnerID[i] %in% c(partnerID[seq_len(i - 1)], recipientID[seq_len(i - 1)]))))) %>%
    ungroup() %>%
    select(gameID, playerID, round, partnerID, first, first_any, reciprocal)

  own <- focal %>% select(gameID, playerID, round, guess)
  sender_est <- allg %>% rename(partnerID = playerID, sender_round = round, sender_guess = guess)

  f <- focal %>% distinct(gameID, playerID, condition)
  grid <- partners %>% inner_join(f, by = c("gameID", "playerID")) %>%
    mutate(slider = condition == "slider",
           before_round = ifelse(slider, round, round - 1),   # focal estimate before receiving
           after_round  = ifelse(slider, round + 1, round),   # focal estimate after receiving
           sender_round = ifelse(slider, round, round - 1))   # sender estimate used as proxy
  grid %>%
    left_join(own %>% rename(before_round = round, before = guess), by = c("gameID", "playerID", "before_round")) %>%
    left_join(own %>% rename(after_round = round, after = guess),   by = c("gameID", "playerID", "after_round")) %>%
    left_join(sender_est, by = c("gameID", "partnerID", "sender_round")) %>%
    left_join(samp %>% rename(partnerID = playerID, sender_mle = mle), by = c("gameID", "partnerID")) %>%
    filter(!is.na(before), !is.na(after)) %>%
    mutate(update = after - before,
           dist_est = sender_guess - before,
           dist_mle = sender_mle - before,
           t = after_round)
}

T1 <- build(focal1, allg1, samp1, p1)
T2 <- build(focal2, allg2, samp2, p2)
write_csv(T1, "01_exp1_transitions.csv"); write_csv(T2, "01_exp2_transitions.csv")

# ------------------------------------------------------------------- models
# update ~ dist * first + dist * round_c, random intercepts for player and
# network; random slope of dist by player when it converges without a
# singular fit. Separate model per condition and information coding.
fit_one <- function(d, distvar, extra = "") {
  d <- d %>% filter(!is.na(.data[[distvar]])) %>%
    mutate(dist = .data[[distvar]], round_c = t - mean(t), round_c2 = round_c^2,
           recip = as.integer(reciprocal))
  fx <- paste("update ~ dist * first + dist * round_c", extra)
  f_slope <- as.formula(paste(fx, "+ (1 + dist | playerID) + (1 | gameID)"))
  f_int   <- as.formula(paste(fx, "+ (1 | playerID) + (1 | gameID)"))
  m <- tryCatch(suppressMessages(suppressWarnings(lmer(f_slope, data = d))), error = function(e) NULL)
  re <- "(1 + dist | player) + (1 | network)"
  if (is.null(m) || isSingular(m) || length(m@optinfo$conv$lme4$messages) > 0) {
    m <- suppressMessages(lmer(f_int, data = d)); re <- "(1 | player) + (1 | network)"
  }
  list(m = m, d = d, re = re)
}

tidy_terms <- function(fit) {
  cf <- coef(summary(fit$m))
  tibble(term = rownames(cf), b = cf[, "Estimate"], se = cf[, "Std. Error"],
         df = cf[, "df"], t = cf[, "t value"], p = cf[, "Pr(>|t|)"])
}

# weight on first vs later encounter at the mean round, from the fitted model
weights_at_mean <- function(fit) {
  b <- fixef(fit$m); V <- as.matrix(vcov(fit$m))
  later <- b["dist"]; first <- b["dist"] + b["dist:first"]
  se_first <- sqrt(V["dist", "dist"] + V["dist:first", "dist:first"] + 2 * V["dist", "dist:first"])
  c(w_later = unname(later), se_later = sqrt(V["dist", "dist"]),
    w_first = unname(first), se_first = se_first)
}

# Specifications:
#   primary   : first = first time receiving from this sender
#   any_contact: first = no earlier contact in either direction (received from or sent to)
#   +recip    : primary + dist:recip (mutual rounds 1, 4, 7, 10 may be weighted differently)
#   +round2   : primary + dist:round_c^2 (non-linear change in weight over rounds)
#   drop_t2   : primary, excluding the earliest transition (new estimate in round 2)
specs <- list(
  primary     = list(fdef = "first",     extra = "",                       drop2 = FALSE),
  any_contact = list(fdef = "first_any", extra = "",                       drop2 = FALSE),
  plus_recip  = list(fdef = "first",     extra = "+ dist * recip",         drop2 = FALSE),
  plus_round2 = list(fdef = "first",     extra = "+ dist * round_c2",      drop2 = FALSE),
  drop_t2     = list(fdef = "first",     extra = "",                       drop2 = TRUE))

run_set <- function(T, expname, conds) {
  out <- list()
  for (cn in conds) {
    codings <- if (cn == "slider") c(dist_est = "sender's transmitted estimate (round t)")
               else c(dist_est = "sender's previous-round estimate", dist_mle = "sender's private-sample MLE")
    for (v in names(codings)) {
      for (sp in names(specs)) {
        S <- specs[[sp]]
        d <- T %>% filter(condition == cn) %>% mutate(first = .data[[S$fdef]])
        if (S$drop2) d <- d %>% filter(t > 2)
        fit <- fit_one(d, v, S$extra)
        tt <- tidy_terms(fit); w <- weights_at_mean(fit)
        cat(sprintf("\n=== %s | %s | info: %s | spec: %s ===\n", expname, cn, codings[[v]], sp))
        cat(sprintf("N transitions = %d (first = %d, later = %d); players = %d; networks = %d; RE: %s\n",
                    nrow(fit$d), sum(fit$d$first == 1), sum(fit$d$first == 0),
                    n_distinct(fit$d$playerID), n_distinct(fit$d$gameID), fit$re))
        tf <- table(fit$d$t[fit$d$first == 1])
        cat(sprintf("Round of new estimate for first encounters: %s\n", paste(names(tf), tf, sep = ":", collapse = " ")))
        print(as.data.frame(tt %>% filter(grepl("dist", term)) %>% mutate(across(where(is.numeric), ~ round(.x, 4)))), row.names = FALSE)
        cat(sprintf("Weight at mean round: later = %.3f (SE %.3f), first = %.3f (SE %.3f)\n",
                    w["w_later"], w["se_later"], w["w_first"], w["se_first"]))
        out[[length(out) + 1]] <- tt %>% mutate(exp = expname, condition = cn, info = v, spec = sp,
                                                n = nrow(fit$d), n_first = sum(fit$d$first == 1),
                                                n_players = n_distinct(fit$d$playerID),
                                                n_networks = n_distinct(fit$d$gameID), re = fit$re,
                                                w_later = w["w_later"], w_first = w["w_first"])
      }
    }
  }
  bind_rows(out)
}

cat("##### Analysis 1: first vs later encounters with a sender\n")
cat("Model: update ~ dist * first + dist * round_c (+ random effects)\n")
cat("  dist        = weight on the sender's information on a later encounter (at mean round)\n")
cat("  dist:first  = extra weight on a first encounter (positive = more weight when first)\n")
cat("  dist:round_c = change in weight per round\n")

r1 <- run_set(T1, "Exp1", c("slider", "unidirectional", "interactive"))
r2 <- run_set(T2, "Exp2_SR", c("slider", "interactive"))
res <- bind_rows(r1, r2)
write_csv(res, "01_first_encounter_coefs.csv")

# Pooled Exp 1 test: does the first-encounter effect differ by condition?
# (primary coding: estimate proxy, first = first time received from)
d.p <- T1 %>% filter(!is.na(dist_est)) %>%
  mutate(dist = dist_est, round_c = t - mean(t),
         condition = factor(condition, levels = c("slider", "unidirectional", "interactive")))
mp <- lmer(update ~ dist * first * condition + dist * round_c * condition + (1 | playerID) + (1 | gameID), data = d.p)
cat("\n=== Exp1 pooled: dist*first*condition (+ dist*round_c*condition), slider = reference ===\n")
cf <- coef(summary(mp)); print(round(cf[grepl("dist:first", rownames(cf)), ], 4))
cat("\nType III F test for dist:first:condition:\n"); print(anova(mp)["dist:first:condition", ])

# Network-size check (Exp 1): the first-encounter indicator is separated from
# round only by differences in network size. Report the counts.
cat("\nExp1 transitions by network size (from partner table) and first:\n")
print(T1 %>% left_join(p1 %>% distinct(gameID, nPlayers), by = "gameID") %>%
        count(condition, nPlayers, first) %>% pivot_wider(names_from = first, values_from = n, names_prefix = "first_"))
sink(); close(zz)
