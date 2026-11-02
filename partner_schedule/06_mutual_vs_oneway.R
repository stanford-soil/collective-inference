suppressMessages({library(lme4);library(lmerTest)})
for (f in c("exp1_d.csv","exp2_d.csv")) {
  d <- read.csv(f); d$round <- factor(d$idx)
  # Exp 2: analyse only SR games (RS slider messages were inverted); sr_games.csv lists them
  if (f=="exp2_d.csv") d <- d[d$gameID %in% read.csv("../exp2_sr_primary/sr_games.csv")$gameID,]
  d$condition <- relevel(factor(d$condition), ref="slider")
  # round fixed effects absorb the round-specific change shared by all conditions;
  # condition:recip tests whether reciprocal rounds differ for message conditions relative to slider
  d$int_recip <- as.integer(d$condition=="interactive" & d$recip==1)
  d$uni_recip <- as.integer(d$condition=="unidirectional" & d$recip==1)
  form <- if (f=="exp1_d.csv") d_err ~ round + condition + int_recip + uni_recip + (1|gameID) + (1|playerID) else d_err ~ round + condition + int_recip + (1|gameID) + (1|playerID)
  m <- lmer(form, data=d)
  cat("\n=====",f,"n =",nrow(d),"\n")
  print(round(coef(summary(m))[grep("recip|condition",rownames(coef(summary(m)))),],4))
}
