# Figure 5 (Experiment 2 results), analysed networks.
# (A) Mean absolute error by round with bootstrapped 95% CIs over observations; the
# slider's pre-social estimate is shown at round 0.
# (B) Final-round error (each condition's last round) by condition within the
# median-split bins of each difficulty dimension (lib/exp2_data.R), bins ordered
# [harder, easier]. 95% CIs are percentile bootstraps over networks (2000 resamples),
# so that participants in the same network are not treated as independent.
# Reads   data/derived/exp2_clean_data.csv
# Writes  figures/fig5_exp2_results.pdf

source("../lib/common.R")
suppressPackageStartupMessages({ library(ggthemes); library(patchwork) })
source("../lib/exp2_data.R")

# Percentile bootstrap of the mean over observations (same as tidyboot::tidyboot_mean with
# 1000 resamples, written out here to keep memory use low)
row_boot <- function(x, n_boot = 1000) {
  x <- x[!is.na(x)]
  b <- vapply(seq_len(n_boot), function(i) mean(x[sample.int(length(x), replace = TRUE)]), numeric(1))
  tibble(n = length(x), empirical_stat = mean(x),
         ci_lower = unname(quantile(b, 0.025)), ci_upper = unname(quantile(b, 0.975)))
}

exp2_conditions <- c("slider", "interactive")
color_scale <- scale_color_manual(name = NULL, values = condition_colors[exp2_conditions],
                                  labels = exp2_condition_labels, breaks = exp2_conditions)
fill_scale <- scale_fill_manual(name = NULL, values = condition_colors[exp2_conditions],
                                labels = exp2_condition_labels, breaks = exp2_conditions)

# Mean of `error` over participants with a percentile bootstrap that resamples networks
cluster_boot <- function(df, n_boot = 2000) {
  per_game <- df %>% group_by(gameID) %>% summarise(s = sum(error), n = n(), .groups = "drop")
  boots <- replicate(n_boot, {
    i <- sample.int(nrow(per_game), replace = TRUE)
    sum(per_game$s[i]) / sum(per_game$n[i])
  })
  tibble(empirical_stat = sum(per_game$s) / sum(per_game$n),
         ci_lower = unname(quantile(boots, 0.025)),
         ci_upper = unname(quantile(boots, 0.975)),
         n_networks = nrow(per_game), n_participants = sum(per_game$n))
}

set.seed(2026)
exp2 <- load_exp2()
d.all <- exp2$data %>% filter(!is.na(error))
d.slider_baseline <- exp2$slider_baseline %>% filter(!is.na(error))

cat("Networks by condition:\n"); print(count(distinct(d.all, gameID, condition), condition))

# ---- Panel A: error over rounds ----
error_by_round <- d.all %>%
  group_by(condition, idx_shifted) %>%
  reframe(row_boot(error)) %>%
  mutate(condition = factor(condition, levels = exp2_conditions))

slider_baseline_collapsed <- row_boot(d.slider_baseline$error) %>%
  mutate(condition = factor("slider", levels = exp2_conditions), idx_shifted = 0)

baseline_segments <- error_by_round %>%
  filter(idx_shifted == 1) %>%
  select(condition, empirical_stat) %>%
  mutate(baseline_y = slider_baseline_collapsed$empirical_stat, x_start = 0, x_end = 1)

p_a <- ggplot(error_by_round, aes(x = idx_shifted, y = empirical_stat, color = condition)) +
  geom_segment(data = baseline_segments,
               aes(x = x_start, xend = x_end, y = baseline_y, yend = empirical_stat, color = condition),
               linetype = "dashed", linewidth = 0.8) +
  geom_point(data = slider_baseline_collapsed, aes(x = idx_shifted, y = empirical_stat),
             size = 2, color = condition_colors[["slider"]]) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper, fill = condition), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  color_scale + fill_scale +
  scale_x_continuous(breaks = 0:8) +
  labs(x = "Round", y = "Mean Absolute Error", tag = "A") +
  theme_few() +
  theme(legend.position = c(0.60, 0.88),
        legend.background = element_blank(),
        legend.key.size = unit(0.4, "cm"),
        legend.text = element_text(size = 9),
        plot.tag = element_text(face = "bold"),
        aspect.ratio = 1)

# ---- Panel B: final-round error by difficulty bin ----
d.final <- d.all %>%
  group_by(condition) %>%
  filter(idx_shifted == max(idx_shifted)) %>%
  ungroup()

# Bin ranges (from the active-player statistics) for the tick labels
rng <- function(v, lo_digits) sprintf(paste0("%.", lo_digits, "f-%.", lo_digits, "f"), min(v), max(v))
bins <- d.all %>% distinct(gameID, nCrittersGame_actual, entropy_actual, representation_actual,
                           critters_bin, entropy_bin, rep_bin) %>% filter(!is.na(critters_bin))
lab_n   <- bins %>% group_by(critters_bin) %>% summarise(r = rng(nCrittersGame_actual, 0))
lab_ent <- bins %>% group_by(entropy_bin) %>% summarise(r = rng(entropy_actual, 2))
lab_rep <- bins %>% group_by(rep_bin) %>% summarise(r = rng(representation_actual, 2))
level_labels <- c(
  "Few"              = paste0("Fewer\n(", lab_n$r[lab_n$critters_bin == "Few"], ")"),
  "Many"             = paste0("More\n(", lab_n$r[lab_n$critters_bin == "Many"], ")"),
  "Low"              = paste0("Uneven\n(", lab_ent$r[lab_ent$entropy_bin == "Low"], ")"),
  "High"             = paste0("Even\n(", lab_ent$r[lab_ent$entropy_bin == "High"], ")"),
  "Unrepresentative" = paste0("Unrepresentative\n(", lab_rep$r[lab_rep$rep_bin == "Unrepresentative"], ")"),
  "Representative"   = paste0("Representative\n(", lab_rep$r[lab_rep$rep_bin == "Representative"], ")")
)

summarise_dim <- function(binvar, dim_name) {
  d.final %>%
    filter(!is.na(.data[[binvar]])) %>%
    mutate(level = as.character(.data[[binvar]])) %>%
    group_by(condition, level) %>%
    group_modify(~ cluster_boot(.x)) %>%
    ungroup() %>%
    mutate(dimension = dim_name)
}
summary_all <- bind_rows(
  summarise_dim("critters_bin", "Total sample size"),
  summarise_dim("entropy_bin", "Information distribution"),
  summarise_dim("rep_bin", "Representativeness")
) %>%
  mutate(
    dimension = factor(dimension, levels = c("Total sample size", "Information distribution", "Representativeness")),
    level = factor(level, levels = c("Few", "Many", "Low", "High", "Unrepresentative", "Representative")),
    condition = factor(condition, levels = exp2_conditions)
  )
cat("Final-round error by bin:\n")
print(summary_all %>% arrange(dimension, level, condition) %>%
        mutate(across(c(empirical_stat, ci_lower, ci_upper), ~ round(.x, 1))), n = Inf)

p_b <- ggplot(summary_all, aes(x = level, y = empirical_stat, color = condition, group = condition)) +
  geom_line(linewidth = 1, position = position_dodge(width = 0.15)) +
  geom_point(size = 2.5, position = position_dodge(width = 0.15)) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.15,
                position = position_dodge(width = 0.15)) +
  facet_wrap(~ dimension, scales = "free_x", nrow = 1) +
  scale_x_discrete(labels = level_labels) +
  color_scale +
  labs(x = NULL, y = "Final-Round Mean Absolute Error", tag = "B") +
  theme_few() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 8.5, lineheight = 0.9),
        strip.text = element_text(size = 10),
        plot.tag = element_text(face = "bold"))

fig5 <- (p_a | p_b) + plot_layout(widths = c(1, 1.8))
save_fig(fig5, "fig5_exp2_results", width = 11.5, height = 4)
