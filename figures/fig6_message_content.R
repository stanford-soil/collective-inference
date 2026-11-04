# Figure 6 (Experiment 2 message content): (A) final-round error of real-time messaging
# networks grouped by the share of messages relaying social information (0%, 1-10%,
# > 10%), with bootstrapped 95% CIs; (B) example messages.
# As in the original Experiment 2 notebook, the share uses the original single-coder
# codes (data/exp2/coded_messages.csv); the networks are the SR networks.
# Input: data/derived/exp2_clean_data.csv, data/exp2/coded_messages.csv.
# Output: figures/fig6_message_content.pdf. Run from figures/.
source("../lib/common.R")
source("../lib/exp2_data.R")
suppressPackageStartupMessages({ library(tidyboot); library(ggthemes); library(patchwork) })
set.seed(2026)

d.all <- load_exp2()$d.all
d.messages <- read_csv(EXP2_CODED_MSGS, show_col_types = FALSE)

message_counts <- d.messages %>%
  group_by(gameID) %>%
  summarise(total_messages = n(),
            pn_count = sum(str_detect(coding, "pn"), na.rm = TRUE),
            pb_count = sum(str_detect(coding, "pb"), na.rm = TRUE),
            sn_count = sum(str_detect(coding, "sn"), na.rm = TRUE),
            sb_count = sum(str_detect(coding, "sb"), na.rm = TRUE),
            .groups = "drop") %>%
  mutate(p_social = (sn_count + sb_count) / total_messages)

game_error <- d.all %>%
  group_by(gameID, condition) %>%
  filter(idx_shifted == max(idx_shifted, na.rm = TRUE)) %>%
  group_by(gameID) %>%
  summarise(avg_error = mean(error, na.rm = TRUE), .groups = "drop")

d.message_analysis <- message_counts %>%
  inner_join(game_error, by = "gameID") %>%
  mutate(social_level = factor(case_when(p_social == 0 ~ "0%",
                                         p_social <= 0.10 ~ "1–10%",
                                         p_social > 0.10 ~ ">10%"),
                               levels = c("0%", "1–10%", ">10%")))
cat("Networks:", nrow(d.message_analysis), "\n")

social_summary <- d.message_analysis %>%
  filter(!is.na(social_level)) %>%
  group_by(social_level) %>%
  tidyboot_mean(avg_error, na.rm = TRUE)
print(social_summary)

fig6_a <- ggplot(social_summary, aes(x = social_level, y = empirical_stat)) +
  geom_col(fill = "#0072B2", alpha = 0.7, width = 0.6) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.2) +
  labs(x = "% Messages Relaying Social Information", y = "Final Round Error", tag = "A") +
  theme_few() +
  theme(axis.text.x = element_text(size = 12)) +
  coord_cartesian(ylim = c(0, 25))

examples <- tibble(
  Category = c("Personal\nNumeric", "Personal\nNumeric", "Social\nNumeric", "Social\nNumeric"),
  Example = c("\"4 rabbits, 2 squirrels\"",
              "\"I saw more rabbits\"",
              "\"My neighbor saw 11 rabbits\nand 1 squirrel\"",
              "\"I have gathered 22 rabbits\nfrom everyone\""),
  Type = c("Personal", "Personal", "Social", "Social")
)
fig6_b <- ggplot(examples, aes(x = 1, y = rev(seq_along(Example)))) +
  geom_label(aes(label = Example, fill = Type), hjust = 0, size = 3, label.padding = unit(0.4, "lines")) +
  scale_fill_manual(values = c("Personal" = "gray85", "Social" = "#0072B2"), guide = "none") +
  scale_x_continuous(limits = c(0.9, 3)) +
  labs(tag = "B") +
  theme_void() +
  theme(plot.tag = element_text(size = 14, face = "bold"))

save_fig(fig6_a + fig6_b + plot_layout(widths = c(1.2, 1)), "fig6_message_content", width = 9, height = 4)
