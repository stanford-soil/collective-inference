# Experiment 2: the difficulty model with each network's pre-assigned statistics
# (Reviewer 3, point 4; Appendix C).
#
# In the main analysis, total sample size and entropy are computed over the
# participants who entered at least one estimate, so they could depend on who
# dropped out. Here all three difficulty statistics are those of the game
# configuration the network was assigned before the session.
#
# The pre-assigned statistics come from the generated configuration files, matched
# through the column designatedGame. Three analysed networks have designatedGame = 0
# (a configuration listed with five players and played with four); for them we use
# the statistics that prep/02_exp2_clean.R computed from all four assigned participants.
#
# Reads   data/derived/exp2_clean_data.csv,
#         stimuli/exp2_combined_generation/generated_files_used/*.json
# Prints  the fixed effects of the difficulty model with pre-assigned statistics
source("../lib/common.R")
source("../lib/exp2_data.R")
suppressPackageStartupMessages(library(jsonlite))

d <- load_exp2()$data

# ---- Pre-assigned statistics of each configuration ---------------------------------------
config_dir <- repo_path("stimuli", "exp2_combined_generation", "generated_files_used")
configurations <- bind_rows(fromJSON(file.path(config_dir, "games_dontoverwrite.json")),
                            fromJSON(file.path(config_dir, "games_2_dontoverwrite.json"))) %>%
  transmute(designatedGame = as.numeric(gameID),
            config_critters = as.numeric(totalCritters),
            config_entropy = as.numeric(entropy),
            config_representation = as.numeric(representation)) %>%
  distinct(designatedGame, .keep_all = TRUE)

networks <- d %>%
  distinct(gameID, designatedGame, nCrittersGame, entropy, representation,
           nCrittersGame_actual, entropy_actual) %>%
  mutate(across(c(designatedGame, nCrittersGame, entropy, representation), as.numeric)) %>%
  left_join(configurations, by = "designatedGame") %>%
  mutate(critters_pre = coalesce(config_critters, nCrittersGame),
         entropy_pre = coalesce(config_entropy, entropy),
         representation_pre = coalesce(config_representation, representation))

with_data <- networks %>% filter(!is.na(nCrittersGame_actual))
cat("Networks with data:", nrow(with_data), "\n")
cat("Networks whose statistic over active participants differs from the pre-assigned one:\n")
cat("  total sample size:", sum(with_data$nCrittersGame_actual != with_data$critters_pre),
    "| entropy:", sum(abs(with_data$entropy_actual - with_data$entropy_pre) > 1e-3), "\n")

# ---- Refit with the pre-assigned statistics -----------------------------------------------
# Same scaling and centering as lib/exp2_data.R. The one network without any
# estimate contributes no data and is left out of the scaling, as in the main analysis.
d_pre <- d %>%
  left_join(with_data %>% select(gameID, critters_pre, entropy_pre, representation_pre), by = "gameID") %>%
  mutate(critters_c = center(1 - min_max(critters_pre)),
         entropy_c = center(1 - min_max(entropy_pre)),
         rep_c = center(min_max(representation_pre)))

fit(difficulty_model, d,     "Difficulty model, statistics over active participants (main analysis)")
fit(difficulty_model, d_pre, "Difficulty model, pre-assigned statistics")
