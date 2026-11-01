# Task 1: refit every Exp 1 mixed model with an added network (gameID) random intercept.
# Task 3: complete-network robustness of the main condition model.
source("00_prep_exp1.R")
options(width = 200)

# Fit a model, capturing warnings/messages, singularity, and gameID variance
fit <- function(formula, data, label) {
  w <- character(0)
  m <- withCallingHandlers(
    lmer(formula, data = data, control = ctrl),
    warning = function(cond) { w <<- c(w, conditionMessage(cond)); invokeRestart("muffleWarning") },
    message = function(cond) { w <<- c(w, conditionMessage(cond)); invokeRestart("muffleMessage") })
  conv_msgs <- m@optinfo$conv$lme4$messages
  vc <- as.data.frame(VarCorr(m))
  list(model = m, label = label, warnings = unique(c(w, conv_msgs)),
       singular = isSingular(m), vc = vc, nobs = nobs(m),
       ngroups = ngrps(m))
}

tab <- function(f) {
  s <- coef(summary(f$model))
  tibble(model = f$label, term = rownames(s), b = s[, "Estimate"], se = s[, "Std. Error"],
         df = s[, "df"], t = s[, "t value"], p = s[, "Pr(>|t|)"])
}

report <- function(f) {
  cat("\n==== ", f$label, " ====\n", sep = "")
  cat("nobs:", f$nobs, " groups:", paste(names(f$ngroups), f$ngroups, collapse = ", "), "\n")
  cat("singular:", f$singular, "\n")
  cat("warnings/convergence messages:", if (length(f$warnings)) paste(f$warnings, collapse = " | ") else "none", "\n")
  print(f$vc[, c("grp", "var1", "var2", "vcov", "sdcor")])
  print(coef(summary(f$model)))
}

models <- list()

# --- M1: convergence (error over rounds, quadratic)
models$M1_old <- fit(error ~ idx_c + I(idx_c^2) + (1 + idx_c | playerID), d.guesses, "M1 convergence | old")
models$M1_new <- fit(error ~ idx_c + I(idx_c^2) + (1 + idx_c | playerID) + (1 | gameID), d.guesses, "M1 convergence | +network")

# --- M2: error ~ idx * condition (Analysis 2 in qmd)
models$M2_old <- fit(error ~ idx * condition + (1 + idx | playerID), d.guesses, "M2 error x condition | old")
models$M2_new <- fit(error ~ idx * condition + (1 + idx | playerID) + (1 | gameID), d.guesses, "M2 error x condition | +network")

# --- M3: condition at final round (main condition model)
f3_old <- error ~ poly(idx_final_centered, 2) * condition_interactive + (1 + idx_final_centered | playerID)
f3_new <- update(f3_old, . ~ . + (1 | gameID))
models$M3_old <- fit(f3_old, d.shifted, "M3 condition@final | old")
models$M3_new <- fit(f3_new, d.shifted, "M3 condition@final | +network")
# omnibus test of the condition x time interaction (old and new)
lin3_old <- lmer(update(f3_old, . ~ . - poly(idx_final_centered, 2):condition_interactive), data = d.shifted, control = ctrl, REML = FALSE)
lin3_oldF <- lmer(f3_old, data = d.shifted, control = ctrl, REML = FALSE)
lin3_new <- lmer(update(f3_new, . ~ . - poly(idx_final_centered, 2):condition_interactive), data = d.shifted, control = ctrl, REML = FALSE)
lin3_newF <- lmer(f3_new, data = d.shifted, control = ctrl, REML = FALSE)
cat("\n==== M3 LRT: condition x time interaction (4 df) ====\nOLD:\n"); print(anova(lin3_old, lin3_oldF))
cat("NEW (+network):\n"); print(anova(lin3_new, lin3_newF))
cat("\nLRT for network random intercept in M3 (REML fits, refit=FALSE):\n")
print(anova(models$M3_old$model, models$M3_new$model, refit = FALSE))

# --- M4: adaptive weighting (as in qmd)
f4_old <- belief_revision ~ scale(sample_size) * scale(prior_social_discrepancy) + scale(idx) + (1 + scale(idx) | playerID)
models$M4_old <- fit(f4_old, d.revisions, "M4 adaptive weighting | old")
models$M4_new <- fit(update(f4_old, . ~ . + (1 | gameID)), d.revisions, "M4 adaptive weighting | +network")

# --- M4b: adaptive weighting follow-up with condition interactions.
# NOTE: this model is NOT in the repo (current qmd or git history). Reconstructed as the full
# three-way interaction with condition (slider reference, the factor's default level order).
f4b_old <- belief_revision ~ scale(sample_size) * scale(prior_social_discrepancy) * condition + scale(idx) + (1 + scale(idx) | playerID)
models$M4b_old <- fit(f4b_old, d.revisions, "M4b adaptive x condition (RECONSTRUCTED) | old")
models$M4b_new <- fit(update(f4b_old, . ~ . + (1 | gameID)), d.revisions, "M4b adaptive x condition (RECONSTRUCTED) | +network")

# --- M5: belief revision / stabilization
f5_old <- abs_change ~ idx_shifted * condition + (1 + idx_shifted | playerID)
models$M5_old <- fit(f5_old, d.stabilization, "M5 belief revision | old")
models$M5_new <- fit(update(f5_old, . ~ . + (1 | gameID)), d.stabilization, "M5 belief revision | +network")

for (f in models) report(f)

coefs <- bind_rows(lapply(models, tab))
write_csv(coefs, "exp1_coefs_old_vs_new.csv")
diag <- bind_rows(lapply(models, function(f) tibble(
  model = f$label, nobs = f$nobs,
  n_player = unname(f$ngroups["playerID"]), n_game = unname(if ("gameID" %in% names(f$ngroups)) f$ngroups["gameID"] else NA),
  singular = f$singular, warnings = paste(f$warnings, collapse = " | "),
  var_game = { v <- f$vc$vcov[f$vc$grp == "gameID"]; if (length(v)) v else NA_real_ })))
write_csv(diag, "exp1_model_diagnostics.csv")
print(diag, width = 200)

# --- Appendix: exclusion thresholds, old vs new
thresholds <- c(0, 0.5, 0.8, 1.0); labs <- c("None", "50%", "80% (prereg)", "100%")
rob <- list()
for (i in seq_along(thresholds)) {
  ex <- response_rates %>% filter(response_rate < thresholds[i]) %>% pull(playerID)
  d.sub <- if (thresholds[i] == 0) d.pre.clean else d.pre.clean %>% filter(!(playerID %in% ex))
  d.sub <- make_shifted(d.sub)
  for (v in c("old", "new")) {
    ff <- if (v == "old") f3_old else f3_new
    f <- fit(ff, d.sub, paste("Thresh", labs[i], v))
    s <- coef(summary(f$model))
    rob[[length(rob) + 1]] <- tibble(threshold = labs[i], version = v,
      N = n_distinct(d.sub$playerID), networks = n_distinct(d.sub$gameID),
      slider_b = s["condition_interactiveslider", "Estimate"], slider_t = s["condition_interactiveslider", "t value"],
      slider_df = s["condition_interactiveslider", "df"], slider_p = s["condition_interactiveslider", "Pr(>|t|)"],
      unidir_b = s["condition_interactiveunidirectional", "Estimate"], unidir_t = s["condition_interactiveunidirectional", "t value"],
      unidir_df = s["condition_interactiveunidirectional", "df"], unidir_p = s["condition_interactiveunidirectional", "Pr(>|t|)"],
      singular = f$singular, warnings = paste(f$warnings, collapse = " | "))
  }
}
rob <- bind_rows(rob)
write_csv(rob, "exp1_threshold_robustness.csv")
cat("\n==== Exclusion-threshold robustness ====\n"); print(as.data.frame(rob))

# --- Task 3: complete-network robustness
ret <- d.guesses %>% distinct(gameID, playerID) %>% count(gameID, name = "n_ret")
complete4 <- ret %>% filter(n_ret == 4) %>% pull(gameID)
complete4plus <- ret %>% filter(n_ret >= 4) %>% pull(gameID)
cr <- list()
for (def in c("exactly4", "atleast4")) {
  g <- if (def == "exactly4") complete4 else complete4plus
  dd <- d.shifted %>% filter(gameID %in% g)
  cat("\n==== Complete networks (", def, ") ====\n", sep = "")
  print(dd %>% distinct(gameID, playerID, condition) %>% group_by(condition) %>%
          summarise(networks = n_distinct(gameID), participants = n_distinct(playerID)))
  for (v in c("old", "new")) {
    f <- fit(if (v == "old") f3_old else f3_new, dd, paste("Complete", def, v))
    report(f)
    s <- coef(summary(f$model))
    cr[[length(cr) + 1]] <- tibble(definition = def, version = v,
      N = n_distinct(dd$playerID), networks = n_distinct(dd$gameID), term = rownames(s),
      b = s[, "Estimate"], se = s[, "Std. Error"], df = s[, "df"], t = s[, "t value"], p = s[, "Pr(>|t|)"],
      singular = f$singular, warnings = paste(f$warnings, collapse = " | "))
  }
  # also LRT for the interaction in the complete-network new model
  full <- lmer(f3_new, data = dd, control = ctrl, REML = FALSE)
  red <- lmer(update(f3_new, . ~ . - poly(idx_final_centered, 2):condition_interactive), data = dd, control = ctrl, REML = FALSE)
  cat("LRT condition x time (complete, +network):\n"); print(anova(red, full))
  # final-round means
  print(dd %>% filter(idx_final_centered == 0) %>% group_by(condition) %>%
          summarise(mean_error = mean(error), sd = sd(error), n = n()))
}
write_csv(bind_rows(cr), "exp1_complete_network_robustness.csv")
