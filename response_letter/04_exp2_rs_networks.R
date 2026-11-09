# Response letter: the main Experiment 2 models (exp2/01_models.R) refitted on the
# RS networks that the revised paper excludes (their slider messages were
# inverted), to show that their error was higher in both conditions.
# Usage (from response_letter/): SUBSET=RS Rscript 04_exp2_rs_networks.R
#   (SUBSET=SR reproduces the reported models; SUBSET=ALL uses all networks).
# Input: data/derived/exp2_clean_data.csv. Output: printed.
source("../lib/common.R"); source("../lib/exp2_data.R")
if (Sys.getenv("SUBSET") == "") Sys.setenv(SUBSET = "RS")
d.all <- load_exp2()$d.all
m1 <- lmer(error ~ condition_c * idx_c + (1 + idx_c | gameID/playerID), data = d.all, control = ctrl)
m3 <- lmer(error ~ idx_c + condition_c*critters_c + condition_c*entropy_c + condition_c*rep_c + critters_c*entropy_c + critters_c*rep_c + entropy_c*rep_c + (1 | gameID/playerID), data = d.all, control = ctrl)
s <- exp2_subset()
cat("\n##### SUBSET:", s, " games:", n_distinct(d.all$gameID), " by condition:", paste(capture.output(print(table(distinct(d.all,gameID,condition)$condition))),collapse=" "), "\n")
k <- c("idx_c","condition_c","condition_c:idx_c"); print(round(coef(summary(m1))[k,],3))
k3 <- c("rep_c","critters_c","entropy_c","condition_c:rep_c","condition_c:critters_c","condition_c:entropy_c","entropy_c:rep_c"); print(round(coef(summary(m3))[k3,],3))
fin <- d.all %>% group_by(gameID) %>% filter(idx_shifted==max(idx_shifted)) %>% ungroup() %>% mutate(rh=rep_scaled>median(rep_scaled,na.rm=TRUE)) %>% group_by(condition, rh) %>% summarise(m=round(mean(error,na.rm=TRUE),1),.groups="drop"); print(as.data.frame(fin))
