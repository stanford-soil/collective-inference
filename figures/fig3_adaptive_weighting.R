# Figure 3 (Experiment 1 adaptive weighting): mean belief revision by own sample size
# (<= 5, 6-8, >= 9 critters) and previous-round social discrepancy (median split),
# with bootstrapped 95% CIs. Prints the cell means and the high-minus-low discrepancy
# differences for small and large samples.
# Input: data/derived/exp1_clean_data.csv. Output: figures/fig3_adaptive_weighting.pdf.
# Run from figures/. Construction from the original Experiment 1 notebook (Analysis 4).
source("../lib/common.R")
source("../lib/exp1_data.R")
suppressPackageStartupMessages({ library(tidyboot); library(ggthemes) })
set.seed(2026)

d.revisions <- load_exp1()$d.revisions

d.plot <- d.revisions %>%
  mutate(
    sample_size_cat = case_when(
      sample_size <= 5 ~ "Small sample\n(≤5 critters)",
      sample_size <= 8 ~ "Medium sample\n(6-8 critters)",
      TRUE ~ "Large sample\n(≥9 critters)"
    ),
    sample_size_cat = factor(sample_size_cat,
                             levels = c("Small sample\n(≤5 critters)",
                                        "Medium sample\n(6-8 critters)",
                                        "Large sample\n(≥9 critters)")),
    discrepancy_cat = case_when(
      prior_social_discrepancy <= median(prior_social_discrepancy, na.rm = TRUE) ~ "Low discrepancy",
      TRUE ~ "High discrepancy"
    ),
    discrepancy_cat = factor(discrepancy_cat, levels = c("Low discrepancy", "High discrepancy"))
  )

d.summary <- d.plot %>%
  group_by(sample_size_cat, discrepancy_cat) %>%
  tidyboot_mean(belief_revision, na.rm = TRUE)

p_adaptive <- ggplot(d.summary, aes(x = sample_size_cat, y = empirical_stat, fill = discrepancy_cat)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75, alpha = 0.9) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                position = position_dodge(width = 0.8), width = 0.25, linewidth = 0.6) +
  scale_fill_manual(
    name = "Social Discrepancy",
    values = c("Low discrepancy" = "#0072B2", "High discrepancy" = "#D55E00"),
    labels = c("Low (similar to others)", "High (divergent from others)")
  ) +
  scale_y_continuous(limits = c(0, 14), breaks = seq(0, 14, 2), expand = c(0, 0)) +
  labs(x = "Sample Size", y = "Mean Belief Revision\n(absolute change in estimate)") +
  theme_few(base_size = 14) +
  theme(
    legend.position = "bottom",
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 11),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10)),
    panel.grid.major.y = element_line(color = "gray90"),
    legend.box = "vertical",
    legend.margin = margin(t = 10)
  )
save_fig(p_adaptive, "fig3_adaptive_weighting", width = 10, height = 6)

cat("\nMean belief revision by group:\n"); print(d.summary)
small <- d.summary %>% filter(sample_size_cat == "Small sample\n(≤5 critters)")
large <- d.summary %>% filter(sample_size_cat == "Large sample\n(≥9 critters)")
cat("Small sample: High vs. Low discrepancy difference =",
    round(small$empirical_stat[2] - small$empirical_stat[1], 2), "points\n")
cat("Large sample: High vs. Low discrepancy difference =",
    round(large$empirical_stat[2] - large$empirical_stat[1], 2), "points\n")
