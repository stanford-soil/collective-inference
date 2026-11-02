# Figure 2 (Experiment 1 results): (A) mean absolute error by round, (B) change in
# estimate from the previous round, by condition, with the revised condition labels.
# Construction follows the original Experiment 1 notebook (Analysis 2 panel A,
# Analysis 5 panel B). Input: data/derived/exp1_clean_data.csv.
# Output: figures/fig2_exp1_results.pdf. Run from figures/.

source("../lib/common.R")
suppressPackageStartupMessages({ library(ggthemes); library(patchwork) })
suppressPackageStartupMessages(library(tidyboot))
set.seed(2026)

d.guesses <- read_csv(EXP1_CLEAN, show_col_types = FALSE) %>%
  mutate(condition = factor(condition, levels = condition_breaks)) %>%
  arrange(playerID, idx)

d.shifted <- d.guesses %>%
  mutate(idx_shifted = if_else(condition == "slider", idx - 1, idx))

# ---- Panel A: error over rounds (slider round 1 = pre-social baseline, shown at round 0) ----
slider_data <- d.guesses %>%
  filter(condition == "slider") %>%
  mutate(idx = idx - 1) %>%
  group_by(condition, idx) %>%
  tidyboot_mean(error, na.rm = TRUE)

slider_baseline <- slider_data %>%
  filter(idx == 0) %>%
  ungroup() %>%
  summarise(empirical_stat = mean(empirical_stat),
            ci_lower = mean(ci_lower),
            ci_upper = mean(ci_upper)) %>%
  mutate(idx = 0)

other_conditions_round0 <- tibble(
  condition = factor(c("interactive", "unidirectional"), levels = condition_breaks),
  idx = 0,
  empirical_stat = slider_baseline$empirical_stat,
  ci_lower = slider_baseline$ci_lower,
  ci_upper = slider_baseline$ci_upper
)

other_conditions_actual <- d.guesses %>%
  filter(condition != "slider") %>%
  group_by(condition, idx) %>%
  tidyboot_mean(error, na.rm = TRUE)

error_with_baseline <- bind_rows(slider_data, other_conditions_round0, other_conditions_actual) %>%
  mutate(condition = factor(condition, levels = condition_breaks),
         show_ribbon = (condition == "slider") | (idx > 0),
         show_smooth = (condition == "slider") | (idx > 0))

color_scale <- scale_color_manual(name = NULL, values = condition_colors, labels = condition_labels,
                                  breaks = condition_breaks, drop = FALSE)
fill_scale  <- scale_fill_manual(name = NULL, values = condition_colors, labels = condition_labels,
                                 breaks = condition_breaks, drop = FALSE)

p_error <- ggplot(error_with_baseline, aes(x = idx, y = empirical_stat, color = condition, fill = condition)) +
  geom_ribbon(data = filter(error_with_baseline, show_ribbon),
              aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, color = NA) +
  geom_point(size = 2) +
  geom_line(data = filter(error_with_baseline, idx <= 1, condition != "slider"),
            linetype = "dashed", linewidth = 0.8) +
  geom_smooth(data = filter(error_with_baseline, show_smooth),
              method = "lm", formula = y ~ poly(x, 2), se = FALSE, linewidth = 1) +
  color_scale + fill_scale +
  scale_x_continuous(breaks = c(1, 4, 7, 10)) +
  labs(x = "Round", y = "Mean Absolute Error", tag = "A") +
  theme_few(base_size = 12) +
  theme(
    legend.position = c(0.70, 0.86),
    legend.title = element_blank(),
    legend.text = element_text(size = 12),
    legend.background = element_rect(fill = "white", color = NA),
    plot.tag = element_text(face = "bold", size = 18),
    axis.title = element_text(size = 16),
    axis.text = element_text(size = 14)
  )

# ---- Panel B: change in estimate from the previous round ----
d.stabilization <- d.shifted %>%
  filter(idx_shifted >= 1) %>%
  arrange(playerID, idx_shifted) %>%
  group_by(playerID) %>%
  mutate(abs_change = abs(guess - lag(guess))) %>%
  ungroup() %>%
  filter(!is.na(abs_change))

p_stability <- d.stabilization %>%
  group_by(condition, idx_shifted) %>%
  tidyboot_mean(abs_change, na.rm = TRUE) %>%
  ggplot(aes(x = idx_shifted, y = empirical_stat, color = condition, fill = condition)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, color = NA) +
  geom_point(size = 2) +
  geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = FALSE, linewidth = 1) +
  color_scale + fill_scale +
  scale_x_continuous(breaks = c(2, 5, 8, 11)) +
  labs(x = "Round", y = "Change in Guess from Previous Round", tag = "B") +
  theme_few(base_size = 12) +
  theme(
    legend.position = "none",
    plot.tag = element_text(face = "bold", size = 18),
    axis.title = element_text(size = 16),
    axis.text = element_text(size = 14)
  )

save_fig(p_error + p_stability, "fig2_exp1_results", width = 12, height = 5)
