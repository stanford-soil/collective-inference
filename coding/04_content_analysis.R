if (Sys.getenv("SUBSET")=="") Sys.setenv(SUBSET="SR")  # analysed networks; set SUBSET=ALL for all chat games
suppressMessages(source("../exp2_sr_primary/prep.R"))
run <- function(msgs, label) {
  mc <- msgs %>% group_by(gameID) %>% summarise(total=n(),
     pn=sum(str_detect(coding,"pn"),na.rm=T), pb=sum(str_detect(coding,"pb"),na.rm=T),
     sn=sum(str_detect(coding,"sn"),na.rm=T), sb=sum(str_detect(coding,"sb"),na.rm=T),
     any_social=sum(str_detect(coding,"sn|sb"),na.rm=T), .groups="drop") %>%
     mutate(p_social=(sn+sb)/total, p_personal=(pn+pb)/total, p_any_social=any_social/total)
  ge <- d.all %>% group_by(gameID, condition) %>% filter(idx_shifted==max(idx_shifted,na.rm=TRUE)) %>% group_by(gameID) %>% summarise(avg_error=mean(error,na.rm=TRUE),.groups="drop")
  dd <- inner_join(mc, ge, by="gameID")
  m <- lm(log(avg_error+1) ~ p_social + p_personal, data=dd)
  m2 <- lm(log(avg_error+1) ~ p_any_social + p_personal, data=dd)
  cat("\n=====",label," games:",nrow(dd)," games with any relay:",sum(dd$any_social>0),sprintf("(%.0f%%)",100*mean(dd$any_social>0)),"\n")
  print(round(coef(summary(m))["p_social",],3)); cat("any-social version:\n"); print(round(coef(summary(m2))["p_any_social",],3))
}
orig <- read_csv("../../data/exp2/coded_messages.csv", show_col_types=FALSE)
run(orig, "original single-coder codes")
fin <- read_csv("exp2_message_codes_final.csv", show_col_types=FALSE) %>% rename(coding=code_final)
run(fin, "final adjudicated codes")
