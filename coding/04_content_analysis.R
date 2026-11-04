# Experiment 2 message content and accuracy (Analysis 4): per network, the share of
# messages relaying social information (sn or sb) and the share reporting personal
# information (pn or pb), and their relation to final-round error,
# log(error + 1) ~ p_social + p_personal (also with any social code, and with counts
# by message type). Run with the original single-coder codes and with the final
# adjudicated codes. SR networks by default; SUBSET=ALL uses every network with chat.
# Inputs: data/derived/exp2_clean_data.csv (prep/), data/exp2/coded_messages.csv,
# exp2_message_codes_final.csv (03_merge_final.py). Output: printed. Run from coding/.
source("../lib/common.R")
source("../lib/exp2_data.R")
d.all <- load_exp2()$d.all

run <- function(msgs, label) {
  cat("\n=====", label, "=====\n")
  cat("All coded messages:", nrow(msgs), " in", n_distinct(msgs$gameID), "networks (SR and RS)\n")
  print(msgs %>% count(coding) %>% mutate(pct = round(n / sum(n) * 100, 1)) %>% arrange(desc(n)), n = 15)
  mc <- msgs %>% group_by(gameID) %>% summarise(total=n(),
     pn=sum(str_detect(coding,"pn"),na.rm=T), pb=sum(str_detect(coding,"pb"),na.rm=T),
     sn=sum(str_detect(coding,"sn"),na.rm=T), sb=sum(str_detect(coding,"sb"),na.rm=T),
     any_social=sum(str_detect(coding,"sn|sb"),na.rm=T), .groups="drop") %>%
     mutate(p_social=(sn+sb)/total, p_personal=(pn+pb)/total, p_any_social=any_social/total)
  ge <- d.all %>% group_by(gameID, condition) %>% filter(idx_shifted==max(idx_shifted,na.rm=TRUE)) %>% group_by(gameID) %>% summarise(avg_error=mean(error,na.rm=TRUE),.groups="drop")
  dd <- inner_join(mc, ge, by="gameID")
  m <- lm(log(avg_error+1) ~ p_social + p_personal, data=dd)
  m2 <- lm(log(avg_error+1) ~ p_any_social + p_personal, data=dd)
  m3 <- lm(log(avg_error+1) ~ pn + pb + sn + sb, data=dd)
  cat("Networks with error data:", nrow(dd), " with any relay:", sum(dd$any_social>0), sprintf("(%.0f%%)", 100*mean(dd$any_social>0)),
      " mean share social:", round(mean(dd$p_social), 3), "\n")
  cat("p_social:\n"); print(round(coef(summary(m))["p_social",],3))
  cat("any-social version:\n"); print(round(coef(summary(m2))["p_any_social",],3))
  cat("counts by message type:\n"); print(round(coef(summary(m3)),3))
}
cat("Networks:", load_exp2()$subset, "\n")
orig <- read_csv(EXP2_CODED_MSGS, show_col_types=FALSE)
run(orig, "original single-coder codes")
fin <- read_csv("exp2_message_codes_final.csv", show_col_types=FALSE) %>% rename(coding=code_final)
run(fin, "final adjudicated codes")
