# Figure 4 (Experiment 2 design): the analysed networks in the three-dimensional
# difficulty space (total sample size, entropy, representativeness), shown as three
# pairwise projections. Point area is the number of networks. The statistics are
# those used in the analysis (lib/exp2_data.R).
# Reads   data/derived/exp2_clean_data.csv
# Writes  figures/fig4_exp2_design.pdf

source("../lib/common.R")
suppressPackageStartupMessages({ library(ggthemes); library(patchwork) })
source("../lib/exp2_data.R")

games <- load_exp2()$data %>%
  distinct(gameID, condition, direction, nCrittersGame_actual, entropy_actual, representation_actual) %>%
  filter(!is.na(nCrittersGame_actual)) %>%
  mutate(condition = factor(condition, levels = c("slider", "interactive")),
         # round so that numerically identical configurations are counted together
         across(c(entropy_actual, representation_actual), ~ round(.x, 4)))

cat("Games plotted:", nrow(games), "\n")
print(count(games, condition, direction))
cat("Ranges:\n"); print(reframe(games, across(c(nCrittersGame_actual, entropy_actual, representation_actual), range)))

dims <- list(
  n   = list(var = "nCrittersGame_actual",
             lab = "Total sample size\n(critters seen by active players)",
             lim = c(5, 40), br = seq(5, 40, 5)),
  ent = list(var = "entropy_actual",
             lab = "Information distribution\n(entropy across players, nats)",
             lim = c(0, log(4)), br = c(0, 0.25, 0.5, 0.75, 1, log(4))),
  rep = list(var = "representation_actual",
             lab = "Representativeness\n(mean |individual - network proportion|)",
             lim = c(0, 0.62), br = seq(0, 0.6, 0.1))
)
ent_labels <- function(x) ifelse(abs(x - log(4)) < 1e-6, "1.39", sprintf("%.2f", x))
max_networks <- max(count(games, condition, nCrittersGame_actual, entropy_actual)$n,
                    count(games, condition, nCrittersGame_actual, representation_actual)$n,
                    count(games, condition, entropy_actual, representation_actual)$n)
cat("Max networks per plotted point:", max_networks, "\n")

panel <- function(dx, dy, tag) {
  pts <- games %>%
    transmute(condition, x = !!sym(dx$var), y = !!sym(dy$var)) %>%
    count(condition, x, y, name = "networks")
  sx <- if (dx$var == "entropy_actual") scale_x_continuous(limits = dx$lim, breaks = dx$br, labels = ent_labels, expand = expansion(mult = 0.03))
        else scale_x_continuous(limits = dx$lim, breaks = dx$br, expand = expansion(mult = 0.03))
  sy <- if (dy$var == "entropy_actual") scale_y_continuous(limits = dy$lim, breaks = dy$br, labels = ent_labels, expand = expansion(mult = 0.03))
        else scale_y_continuous(limits = dy$lim, breaks = dy$br, expand = expansion(mult = 0.03))
  ggplot(pts, aes(x = x, y = y, color = condition, size = networks)) +
    geom_point(alpha = 0.6, stroke = 0) +
    sx + sy +
    scale_color_manual(name = NULL, values = condition_colors[c("slider", "interactive")],
                       labels = exp2_condition_labels) +
    scale_size_area(name = "Networks", max_size = 5, limits = c(1, max_networks), breaks = c(1, 3, 5, 7)) +
    labs(x = dx$lab, y = dy$lab, tag = tag) +
    theme_few(base_size = 11) +
    theme(aspect.ratio = 1,
          plot.tag = element_text(face = "bold", size = 14),
          axis.title = element_text(size = 10.5))
}

fig4 <- (panel(dims$n, dims$ent, "A") | panel(dims$n, dims$rep, "B") | panel(dims$ent, dims$rep, "C")) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom", legend.box = "horizontal") &
  guides(color = guide_legend(order = 1, override.aes = list(size = 3, alpha = 1)),
         size = guide_legend(order = 2))

save_fig(fig4, "fig4_exp2_design", width = 11, height = 4.6)
