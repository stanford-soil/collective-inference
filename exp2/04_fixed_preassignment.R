# Reviewer 3, point 4 ("fixed pre-assignment"): refit Exp 2 model3_full on SR
# games with each game's PRE-ASSIGNED configuration statistics (as generated,
# from all four assigned players' samples) instead of the statistics
# recomputed from active participants.
#
# Input: data/derived/exp2_clean_data.csv (prep/), stimulus configuration files.
# Output: 04_fixed_preassignment_output.txt, 04_fixed_preassignment_coefs.csv.
# Run from exp2/.
#
# Source of the pre-assigned statistics: the generated game configurations in
# stimuli/exp2_combined_generation/generated_files_used/games_dontoverwrite.json
# and games_2_dontoverwrite.json (fields totalCritters, entropy,
# representation), matched to played games via the clean-data column
# designatedGame. Three SR games have designatedGame = 0 (configuration 10120,
# whose file entry lists five players with one duplicated, and which was played
# with four). For these, the clean-data game-level columns nCrittersGame,
# entropy and representation are used; these are computed in
# prep/03_exp2_clean.R from the samples of all four players
# assigned to the game, whether or not they responded.

source("../lib/common.R")
source("../lib/exp2_data.R")
suppressPackageStartupMessages({ library(jsonlite) })
zz <- file("04_fixed_preassignment_output.txt", open = "wt"); sink(zz, split = TRUE)

# Analysis data for the SR networks (lib/exp2_data.R)
d.all <- load_exp2("SR")$d.all

gen_dir <- repo_path("stimuli", "exp2_combined_generation", "generated_files_used")
cfg <- bind_rows(fromJSON(file.path(gen_dir, "games_dontoverwrite.json")),
                 fromJSON(file.path(gen_dir, "games_2_dontoverwrite.json"))) %>%
  transmute(designatedGame = as.numeric(gameID), cfg_critters = as.numeric(totalCritters),
            cfg_entropy = as.numeric(entropy), cfg_rep = as.numeric(representation)) %>%
  distinct(designatedGame, .keep_all = TRUE)

games <- d.all %>%
  distinct(gameID, condition, designatedGame, n_active_players,
           nCrittersGame, entropy, representation,
           nCrittersGame_actual, entropy_actual, representation_actual) %>%
  mutate(across(c(nCrittersGame, entropy, representation, designatedGame), as.numeric)) %>%
  left_join(cfg, by = "designatedGame") %>%
  mutate(source = ifelse(is.na(cfg_critters), "clean-data columns (designatedGame = 0)", "stimulus config file"),
         critters_pre = coalesce(cfg_critters, nCrittersGame),
         entropy_pre  = coalesce(cfg_entropy, entropy),
         rep_pre      = coalesce(cfg_rep, representation))

cat("##### Analysis 2: pre-assigned vs active-participant game statistics (SR games)\n\n")
cat("Games:", nrow(games), "\n"); print(table(games$condition, games$n_active_players, useNA = "ifany",
                                             dnn = c("condition", "active players")))
cat("\nSource of pre-assigned statistics:\n"); print(table(games$source))
m <- games %>% filter(!is.na(cfg_critters))
cat(sprintf("\nAgreement of config file with clean-data columns (%d matched games): max |diff| critters = %g, entropy = %g, representation = %g\n",
            nrow(m), max(abs(m$cfg_critters - m$nCrittersGame)), max(abs(m$cfg_entropy - m$entropy)),
            max(abs(m$cfg_rep - m$representation))))
g2 <- games %>% filter(!is.na(nCrittersGame_actual))
cat(sprintf("\nGames whose active-participant statistic differs from the pre-assigned one (of %d games with >= 1 active player):\n", nrow(g2)))
cat(sprintf("  critters: %d; entropy: %d; representation: %d\n",
            sum(g2$nCrittersGame_actual != g2$critters_pre),
            sum(abs(g2$entropy_actual - g2$entropy_pre) > 1e-3),
            sum(abs(g2$representation_actual - g2$rep_pre) > 1e-3)))
cat("  (lib/exp2_data.R takes representation_actual from the existing clean-data column 'representation',\n   so representativeness is the pre-assigned value in both versions.)\n")
cat(sprintf("  Correlation active vs pre-assigned: critters r = %.4f, entropy r = %.4f\n",
            cor(g2$nCrittersGame_actual, g2$critters_pre), cor(g2$entropy_actual, g2$entropy_pre)))

# Build pre-assigned predictors with the same scaling and centering as lib/exp2_data.R.
# Centering uses the same rows as the active version (rows of games with at
# least one active participant; the one game with none contributes no data).
d.pre <- d.all %>%
  left_join(games %>% select(gameID, critters_pre, entropy_pre, rep_pre), by = "gameID") %>%
  mutate(keep = !is.na(nCrittersGame_actual),
         critters_pre = ifelse(keep, critters_pre, NA),
         entropy_pre  = ifelse(keep, entropy_pre, NA),
         rep_pre      = ifelse(keep, rep_pre, NA)) %>%
  mutate(
    critters_scaled = 1 - (critters_pre - min(critters_pre, na.rm = TRUE)) /
                          (max(critters_pre, na.rm = TRUE) - min(critters_pre, na.rm = TRUE)),
    entropy_scaled  = 1 - (entropy_pre - min(entropy_pre, na.rm = TRUE)) /
                          (max(entropy_pre, na.rm = TRUE) - min(entropy_pre, na.rm = TRUE)),
    rep_scaled      = (rep_pre - min(rep_pre, na.rm = TRUE)) /
                      (max(rep_pre, na.rm = TRUE) - min(rep_pre, na.rm = TRUE)),
    critters_c = critters_scaled - mean(critters_scaled, na.rm = TRUE),
    entropy_c  = entropy_scaled - mean(entropy_scaled, na.rm = TRUE),
    rep_c      = rep_scaled - mean(rep_scaled, na.rm = TRUE))

f3 <- error ~ idx_c + condition_c*critters_c + condition_c*entropy_c + condition_c*rep_c +
  critters_c*entropy_c + critters_c*rep_c + entropy_c*rep_c + (1 | gameID/playerID)
m.act <- lmer(f3, data = d.all, control = ctrl)
m.pre <- lmer(f3, data = d.pre, control = ctrl)

tab <- function(m, lab) {
  cf <- coef(summary(m))
  tibble(version = lab, term = rownames(cf), b = cf[, "Estimate"], se = cf[, "Std. Error"],
         df = cf[, "df"], t = cf[, "t value"], p = cf[, "Pr(>|t|)"])
}
res <- bind_rows(tab(m.act, "active"), tab(m.pre, "preassigned"))
write_csv(res, "04_fixed_preassignment_coefs.csv")

cat(sprintf("\nObservations used: active = %d, pre-assigned = %d; games = %d; players = %d\n",
            nobs(m.act), nobs(m.pre), n_distinct(model.frame(m.pre)$gameID),
            unname(ngrps(m.pre)["playerID:gameID"])))
cat("\nAll fixed effects, side by side:\n")
wide <- res %>% mutate(s = sprintf("b=%7.3f t(%6.1f)=%6.2f p=%.4f", b, df, t, p)) %>%
  select(version, term, s) %>% pivot_wider(names_from = version, values_from = s)
for (i in seq_len(nrow(wide))) cat(sprintf("%-24s active: %s | pre-assigned: %s\n", wide$term[i], wide$active[i], wide$preassigned[i]))
cat("\nCondition interactions:\n")
print(as.data.frame(res %>% filter(grepl("^condition_c", term)) %>%
                      mutate(across(where(is.numeric), ~ round(.x, 4)))), row.names = FALSE)
sink(); close(zz)
