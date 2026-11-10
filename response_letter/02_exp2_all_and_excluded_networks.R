# Response letter: the Experiment 2 models on networks that the revised paper does
# not analyse.
#
#   ALL  every retained network, as in the original submission
#   RS   the excluded networks, whose slider messages were inverted
#
# The revised paper reports the same two models on the SR networks (exp2/01_models.R).
#
# Reads   data/derived/exp2_clean_data.csv
# Prints  the fixed effects of both models for each set of networks
source("../lib/common.R")
source("../lib/exp2_data.R")

for (networks in c("ALL", "RS")) {
  d <- load_exp2(networks)$data
  label <- paste0(networks, " networks (", n_distinct(d$gameID), ")")
  fit(error ~ condition_c * idx_c + (1 + idx_c | gameID/playerID), d,
      paste("Error over rounds by condition,", label))
  fit(difficulty_model, d, paste("Difficulty model,", label))
}
