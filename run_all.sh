#!/usr/bin/env bash
# Runs the whole analysis pipeline in order, from the raw data in data/ to the
# results, tables and figures. Each script runs from its own folder; its printed
# output is saved to logs/<folder>__<script>.log.
#
# Usage (from the repository root):  bash run_all.sh
#   SKIP_FIT=1 bash run_all.sh   skips models/01_fit.py (the slowest step) and uses
#                                the committed models/fit_results.csv
# Requires R (tidyverse, lme4, lmerTest, emmeans, broom.mixed, tidyboot, ggthemes,
# patchwork, jsonlite) and Python 3 (pandas, numpy, scipy, statsmodels, scikit-learn,
# matplotlib). Runs under a UTF-8 locale (critter counts are parsed from emoji).
set -euo pipefail
export LC_ALL=C.UTF-8
ROOT="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$ROOT/logs" "$ROOT/data/derived"

run() {  # run <folder> <script> [env assignments...]
  local dir="$1" script="$2"; shift 2
  local log="$ROOT/logs/${dir}__${script%.*}${SUBSET_TAG:-}.log"
  echo "[$(date +%H:%M:%S)] $dir/$script $*"
  case "$script" in
    *.R)  (cd "$ROOT/$dir" && env "$@" Rscript "$script") > "$log" 2>&1 ;;
    *.py) (cd "$ROOT/$dir" && env "$@" python3 "$script") > "$log" 2>&1 ;;
  esac || { echo "FAILED: $dir/$script (see $log)"; exit 1; }
}

# 1. Data preparation (clean data in data/derived/)
run prep 01_exp1_merge_raw.R
run prep 02_exp1_clean.R
run prep 03_exp2_clean.R

# 2. Partner schedule (needed by models/ and the first-encounter analysis)
run partner_schedule 01_load_raw_logs.py
run partner_schedule 02_build_partner_tables.py
run partner_schedule 03_check_partner_schedule.py
run partner_schedule 04_influence_test.py
run partner_schedule 05_prep_mutual_vs_oneway.py
run partner_schedule 06_mutual_vs_oneway.R
run partner_schedule 07_relay.py
run partner_schedule 08_coherence.py
run partner_schedule 09_first_encounter.R

# 3. Experiment 1
run exp1 01_models.R
run exp1 02_robustness.R
run exp1 03_attrition.R

# 4. Experiment 2 (SR networks)
run exp2 01_models.R
run exp2 02_difficulty_profiles.R
run exp2 03_robustness.R
run exp2 04_fixed_preassignment.R
run exp2 05_attrition.R

# 5. Message coding and content analysis
run coding 01_agreement.py
run coding 02_apply_rules.py
run coding 03_merge_final.py
run coding 04_content_analysis.R
SUBSET_TAG=_ALL run coding 04_content_analysis.R SUBSET=ALL
run coding 05_count_reports_auto.py
run coding 06_relayed_overcounting.py

# 6. Models of Experiment 1 updating
if [ "${SKIP_FIT:-0}" != "1" ]; then run models 01_fit.py; fi
run models 02_timing_variants.py

# 7. Figures
run figures fig2_exp1_results.R
run figures fig3_adaptive_weighting.R
run figures fig4_exp2_design.R
run figures fig5_exp2_results.R
run figures fig6_message_content.R
run figures fig7_model_predictions.py

# 8. Response letter (superseded and comparison analyses)
run response_letter 01_exp1_old_vs_new.R
run response_letter 02_exp1_format_tables.R
run response_letter 03_exp1_m5_round2_contrast.R
SUBSET_TAG=_RS run response_letter 04_exp2_rs_networks.R SUBSET=RS

echo "[$(date +%H:%M:%S)] Done. Logs in logs/."
