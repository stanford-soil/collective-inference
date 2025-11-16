library(conflicted)
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")
library(tidyverse)
library(here)
library(tidyboot)
library(ggthemes)
library(patchwork)

theme_set(theme_few())

# Load data
d.raw <- read_csv(here("data/exp1/PreregMergedGuesses.csv"), show_col_types = FALSE)

d.guesses <- d.raw %>%
  filter(!is.na(treatmentName)) %>%
  mutate(
    treatment = as.numeric(str_extract(treatmentName, "0\\.[37]")),
    error = abs(guess - mleEstimateGame)
  )

# Clean treatment names and extract condition
d.guesses <- d.guesses %>%
  mutate(
    treatmentName = case_when(
      treatmentName == "rerun-unidirectional- 0.7" ~ 'unidirectional-0.7',
      treatmentName == "rerun-unidirectional- 0.3" ~ 'unidirectional-0.3',
      treatmentName == "rerun-interactive-0.3" ~ 'interactive-0.3',
      treatmentName == "rerun-interactive- 0.7" ~ 'interactive-0.7',
      treatmentName == "rerun-slider- 0.3" ~ 'slider-0.3',
      treatmentName == "rerun-slider- 0.7" ~ 'slider-0.7',
      TRUE ~ treatmentName
    )
  ) %>%
  separate(treatmentName, into = c('condition', 'treatment_str'), sep = '-', remove = FALSE) %>%
  select(-treatment_str)

# Apply preregistered exclusion
participant_responses <- d.guesses %>%
  group_by(playerID) %>%
  summarise(total_rounds = n_distinct(idx), response_rate = total_rounds / 12)

exclude_prereg <- participant_responses %>% filter(response_rate < 0.80) %>% pull(playerID)
d.guesses <- d.guesses %>% filter(!(playerID %in% exclude_prereg))

# Reorder condition factor to match visual ordering (top to bottom in plot)
d.guesses <- d.guesses %>%
  mutate(condition = factor(condition, levels = c("slider", "unidirectional", "interactive")))

cat("Creating Figure 2 with polynomial smooths...\n")
cat("Sample: N =", n_distinct(d.guesses$playerID), "participants\n\n")

# EXPERIMENTAL DESIGN CONFIRMED (from client/src/components/Chat.jsx):
# - Slider condition round 1: NO social information (sliderFilter shows round-1 messages)
# - Other conditions round 1: INCLUDES social information from 'send' stage
# Therefore: Slider round 1 = empirical baseline for all conditions

# Slider condition: shift idx by -1 (round 1 is baseline, round 2 is first social update)
slider_data <- d.guesses %>%
  filter(condition == "slider") %>%
  mutate(idx = idx - 1) %>%  # Shift: round 1 -> 0, round 2 -> 1, etc.
  group_by(condition, idx) %>%
  tidyboot_mean(error, na.rm = TRUE)

# Use slider's round 0 (their actual round 1 data) as empirical baseline for all conditions
slider_baseline <- slider_data %>%
  filter(idx == 0) %>%
  select(empirical_stat, ci_lower, ci_upper) %>%
  summarise(
    empirical_stat = mean(empirical_stat),
    ci_lower = mean(ci_lower),
    ci_upper = mean(ci_upper)
  ) %>%
  mutate(idx = 0)

# For interactive and unidirectional: add slider's baseline + keep their actual data
# Assumption: All participants have similar pre-social judgment behavior
other_conditions_round0 <- tibble(
  condition = factor(c("interactive", "unidirectional"),
                     levels = c("slider", "unidirectional", "interactive")),
  idx = 0,
  empirical_stat = slider_baseline$empirical_stat,
  ci_lower = slider_baseline$ci_lower,
  ci_upper = slider_baseline$ci_upper
)

other_conditions_actual <- d.guesses %>%
  filter(condition != "slider") %>%
  group_by(condition, idx) %>%
  tidyboot_mean(error, na.rm = TRUE)

# Combine all data and add indicator for ribbons/smooths
error_with_baseline <- bind_rows(
  slider_data,
  other_conditions_round0,
  other_conditions_actual
) %>%
  mutate(
    show_ribbon = (condition == "slider") | (idx > 0),
    show_smooth = (condition == "slider") | (idx > 0)
  )

# Panel A: Error by condition with round 0 baseline
p_error <- ggplot(error_with_baseline, aes(x = idx, y = empirical_stat, color = condition, fill = condition)) +
    # Ribbon for all conditions (slider: rounds 0-11, others: rounds 1-12)
    geom_ribbon(data = filter(error_with_baseline, show_ribbon),
                aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, color = NA) +
    # Points for all rounds including round 0
    geom_point(size = 2) +
    # Dashed line from round 0 to round 1 (for interactive and unidirectional only)
    geom_line(data = filter(error_with_baseline, idx <= 1, condition != "slider"),
              linetype = "dashed", linewidth = 0.8) +
    # Polynomial smooths (slider: rounds 0-11, others: rounds 1-12)
    geom_smooth(data = filter(error_with_baseline, show_smooth),
                method = 'lm', formula = y ~ poly(x, 2), se = FALSE, linewidth = 1) +
    scale_color_manual(
      name = NULL,
      values = c("slider" = "#E69F00", "unidirectional" = "#56B4E9", "interactive" = "#009E73"),
      labels = c("Slider", "Unidirectional", "Interactive"),
      breaks = c("slider", "unidirectional", "interactive"),
      drop = FALSE
    ) +
    scale_fill_manual(
      name = NULL,
      values = c("slider" = "#E69F00", "unidirectional" = "#56B4E9", "interactive" = "#009E73"),
      labels = c("Slider", "Unidirectional", "Interactive"),
      breaks = c("slider", "unidirectional", "interactive"),
      drop = FALSE
    ) +
    scale_x_continuous(breaks = c(1, 4, 7, 10)) +
    labs(
      x = "Round",
      y = "Mean Absolute Error",
      tag = "A"
    ) +
    theme_few(base_size = 12) +
    theme(
      legend.position = c(0.85, 0.85),
      legend.title = element_blank(),
      legend.background = element_rect(fill = "white", color = NA),
      plot.tag = element_text(face = "bold", size = 18),
      axis.title = element_text(size = 16),
      axis.text = element_text(size = 14)
    )

# Calculate stabilization data (condition already factored from d.guesses)
d.stability <- d.guesses %>%
  arrange(playerID, idx) %>%
  group_by(playerID) %>%
  mutate(distToSelf = abs(guess - lag(guess))) %>%
  filter(!is.na(distToSelf))

# Panel B: Guess stabilization with polynomial smooth
p_stability <- d.stability %>%
  group_by(condition, idx) %>%
  tidyboot_mean(distToSelf, na.rm = TRUE) %>%
  ggplot(aes(x = idx, y = empirical_stat, color = condition, fill = condition)) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, color = NA) +
    geom_point(size = 2) +
    geom_smooth(method = 'lm', formula = y ~ poly(x, 2), se = FALSE, linewidth = 1) +
    scale_color_manual(
      name = NULL,
      values = c("slider" = "#E69F00", "unidirectional" = "#56B4E9", "interactive" = "#009E73"),
      labels = c("Slider", "Unidirectional", "Interactive"),
      breaks = c("slider", "unidirectional", "interactive"),
      drop = FALSE
    ) +
    scale_fill_manual(
      name = NULL,
      values = c("slider" = "#E69F00", "unidirectional" = "#56B4E9", "interactive" = "#009E73"),
      labels = c("Slider", "Unidirectional", "Interactive"),
      breaks = c("slider", "unidirectional", "interactive"),
      drop = FALSE
    ) +
    scale_x_continuous(breaks = c(1, 4, 7, 10)) +
    labs(
      x = "Round",
      y = "Change in Guess from Previous Round",
      tag = "B"
    ) +
    theme_few(base_size = 12) +
    theme(
      legend.position = "none",
      plot.tag = element_text(face = "bold", size = 18),
      axis.title = element_text(size = 16),
      axis.text = element_text(size = 14)
    )

# Combine panels (legend only in panel A, upper-right)
combined_fig <- p_error + p_stability

# Save combined figure
ggsave(here("figures/exp1_fig2.pdf"), combined_fig, width = 12, height = 5)

cat("✓ Saved figures/exp1_fig2.pdf\n")
cat("\n=== FIGURE 2 DESCRIPTION ===\n")
cat("Panel A: Error reduction with empirical baseline\n")
cat("  - Round 0: Slider participants' initial judgments (confirmed no social info)\n")
cat("  - All conditions start from this shared empirical baseline\n")
cat("  - Dashed line: Transition to first social learning round\n")
cat("  - Polynomial fit shows nonlinear convergence\n")
cat("  - Interactive converges fastest, slider slowest\n\n")
cat("Panel B: Judgment stabilization over time\n")
cat("  - Distance from previous guess decreases nonlinearly\n")
cat("  - All conditions show similar stabilization patterns\n\n")
cat("\n=== MANUSCRIPT CAPTION ===\n")
cat("\\emph{Experiment 1 results}. (A) Error decreases significantly over successive\n")
cat("rounds in all three conditions. Groups using interactive messaging performed\n")
cat("best (lowest error overall), groups using slider-only communication performed\n")
cat("worst (highest error overall), and groups using unidirectional messaging were\n")
cat("in between. Round 0 shows the empirical baseline from slider participants'\n")
cat("initial judgments made without social information; dashed lines connect to this\n")
cat("baseline for conditions that began with social information. Ribbons are 95\\% CIs;\n")
cat("smoothed curves show the fitted trends. (B) Participants in all three conditions\n")
cat("changed their reported beliefs less and less over the course of the study,\n")
cat("indicating convergence toward stable estimates.\n")
