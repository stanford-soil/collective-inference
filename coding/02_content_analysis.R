# Experiment 2, messaging condition: what the messages contained, and whether relaying others'
# information was related to accuracy.
#
# For each coding (final codes, and the first author's original coding) and each set
# of networks (the analysed networks, and all coded networks) this prints
#   - the share of messages with each kind of content,
#   - the number of networks in which anyone relayed others' information, and
#   - a regression across networks of log(final-round error + 1) on the share of
#     messages relaying others' information (p_social), controlling for the share
#     reporting own information (p_personal).
#
# Codes: pn own counts, pb own belief, sn others' counts, sb others' or the group's
# belief, q question, o other. A message can have several codes.
#
# Reads   exp2_message_codes_final.csv (01_final_codes.py), data/exp2/coded_messages.csv,
#         data/derived/exp2_clean_data.csv
source("../lib/common.R")
source("../lib/exp2_data.R")

final_codes  <- read_csv("exp2_message_codes_final.csv", show_col_types = FALSE) %>% rename(code = code_final)
first_coding <- read_csv(EXP2_CODED_MSGS, show_col_types = FALSE) %>% rename(code = coding)

analyse_content <- function(messages, networks, label) {
  # Mean final-round error of each network
  final_error <- load_exp2(networks)$data %>%
    group_by(gameID) %>%
    filter(idx_shifted == max(idx_shifted, na.rm = TRUE)) %>%
    summarise(final_error = mean(error, na.rm = TRUE))
  messages <- messages %>% filter(gameID %in% final_error$gameID)

  cat("\n==== ", label, ": ", nrow(messages), " messages in ", n_distinct(messages$gameID), " networks ====\n", sep = "")
  cat("Share of messages containing\n")
  cat("  own counts (pn):               ", round(mean(str_detect(messages$code, "pn"), na.rm = TRUE), 3), "\n")
  cat("  own counts and nothing else:   ", round(mean(messages$code == "pn", na.rm = TRUE), 3), "\n")
  cat("  own belief (pb):               ", round(mean(str_detect(messages$code, "pb"), na.rm = TRUE), 3), "\n")
  cat("  others' information (sn or sb):", round(mean(str_detect(messages$code, "sn|sb"), na.rm = TRUE), 3), "\n")
  cat("  a question (q):                ", round(mean(str_detect(messages$code, "q"), na.rm = TRUE), 3), "\n")

  # Per network: how many messages of each kind
  per_network <- messages %>%
    group_by(gameID) %>%
    summarise(total = n(),
              pn = sum(str_detect(code, "pn"), na.rm = TRUE), pb = sum(str_detect(code, "pb"), na.rm = TRUE),
              sn = sum(str_detect(code, "sn"), na.rm = TRUE), sb = sum(str_detect(code, "sb"), na.rm = TRUE),
              any_social = sum(str_detect(code, "sn|sb"), na.rm = TRUE)) %>%
    mutate(p_social = (sn + sb) / total, p_personal = (pn + pb) / total) %>%
    inner_join(final_error, by = "gameID")
  cat("Networks in which others' information was relayed:", sum(per_network$any_social > 0), "of", nrow(per_network), "\n")
  cat("log(final-round error + 1) ~ p_social + p_personal:\n")
  print(round(coef(summary(lm(log(final_error + 1) ~ p_social + p_personal, data = per_network))), 3))
}

analyse_content(final_codes,  "SR",  "Final codes, analysed networks")
analyse_content(final_codes,  "ALL", "Final codes, all coded networks")
analyse_content(first_coding, "SR",  "First author's original coding, analysed networks")
analyse_content(first_coding, "ALL", "First author's original coding, all coded networks")
