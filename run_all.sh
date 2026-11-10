#!/usr/bin/env bash
# Runs every analysis in order, from the raw data to the results and figures.
# Each script runs from its own folder; what it prints is saved in results/.
#
#   bash run_all.sh        (from the repository root; about 6 minutes)
#
# The critter counts are parsed from emoji, so the scripts need a UTF-8 locale.
set -euo pipefail
export LC_ALL=C.UTF-8
cd "$(dirname "$0")"

scripts=(
  # 1. Data preparation
  prep/01_exp1_clean.R
  prep/02_exp2_clean.R
  prep/03_message_logs.py

  # 2. Who sent to whom in each round, and the analyses that depend on it
  partner_schedule/01_build_partner_tables.py
  partner_schedule/02_check_partner_schedule.py
  partner_schedule/03_influence_test.py
  partner_schedule/04_mutual_vs_oneway.R
  partner_schedule/05_same_round_relay.py
  partner_schedule/06_question_answer_coherence.py
  partner_schedule/07_first_encounter.R

  # 3. Experiment 1
  exp1/01_models.R
  exp1/02_robustness.R
  exp1/03_attrition.R

  # 4. Experiment 2
  exp2/01_models.R
  exp2/02_robustness.R
  exp2/03_preassigned_difficulty.R
  exp2/04_attrition.R
  exp2/05_slider_version_check.py

  # 5. Message coding and content (Experiment 2 chat)
  coding/01_final_codes.py
  coding/02_content_analysis.R
  coding/03_count_reports_auto.py
  coding/04_relayed_overcounting.py

  # 6. Belief and Evidence models
  models/01_fit.py

  # 7. Figures
  figures/fig2_exp1_results.R
  figures/fig3_adaptive_weighting.R
  figures/fig4_exp2_design.R
  figures/fig5_exp2_results.R
  figures/fig7_model_predictions.py

  # 8. Superseded analyses cited in the response to reviewers
  response_letter/01_exp1_without_network_intercept.R
  response_letter/02_exp2_all_and_excluded_networks.R
  response_letter/03_exp1_round_by_round_target.R
)

for script in "${scripts[@]}"; do
  folder=$(dirname "$script")
  file=$(basename "$script")
  output="$PWD/results/$folder/${file%.*}.txt"
  mkdir -p "$(dirname "$output")"
  echo "[$(date +%H:%M:%S)] $script"
  case "$file" in
    *.R)  (cd "$folder" && Rscript "$file") > "$output" 2>&1 ;;
    *.py) (cd "$folder" && python3 "$file") > "$output" 2>&1 ;;
  esac || { echo "FAILED: $script (see $output)"; exit 1; }
done
echo "Done. Printed results are in results/."
