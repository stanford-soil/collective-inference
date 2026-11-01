suppressMessages(source("prep.R"))
m1 <- lmer(error ~ condition_c * idx_c + (1 + idx_c | gameID/playerID), data = d.all)
m3 <- lmer(error ~ idx_c + condition_c*critters_c + condition_c*entropy_c + condition_c*rep_c + critters_c*entropy_c + critters_c*rep_c + entropy_c*rep_c + (1 | gameID/playerID), data = d.all)
s <- Sys.getenv("SUBSET"); if (s=="") s <- "ALL"
cat("\n##### SUBSET:", s, " games:", n_distinct(d.all$gameID), " by condition:", paste(capture.output(print(table(distinct(d.all,gameID,condition)$condition))),collapse=" "), "\n")
k <- c("idx_c","condition_c","condition_c:idx_c"); print(round(coef(summary(m1))[k,],3))
k3 <- c("rep_c","critters_c","entropy_c","condition_c:rep_c","condition_c:critters_c","condition_c:entropy_c","entropy_c:rep_c"); print(round(coef(summary(m3))[k3,],3))
fin <- d.all %>% group_by(gameID) %>% filter(idx_shifted==max(idx_shifted)) %>% ungroup() %>% mutate(rh=rep_scaled>median(rep_scaled,na.rm=TRUE)) %>% group_by(condition, rh) %>% summarise(m=round(mean(error,na.rm=TRUE),1),.groups="drop"); print(as.data.frame(fin))
if (s=="ALL") { d.all$dir_c <- ifelse(d.all$direction=="RS",0.5,-0.5)
  m4 <- lmer(error ~ condition_c*dir_c + condition_c*idx_c + (1 + idx_c | gameID/playerID), data=d.all)
  cat("\nFull sample with direction:\n"); print(round(coef(summary(m4))[c("condition_c","dir_c","condition_c:dir_c"),],3)) }
