Revised figures for "Collective inference depends on the communication channel" (2026 revision)
==============================================================================================

Each figure is saved as a PDF and as a 300 dpi PNG. The scripts can be run from any folder:

  Rscript revision/figures/fig2_exp1_results.R
  Rscript revision/figures/fig4_exp2_design.R
  Rscript revision/figures/fig5_exp2_results.R
  LC_ALL=C.UTF-8 python3 revision/figures/fig7_predict.py

Inputs: analysis/exp1/exp1_clean_data.csv, analysis/exp2/exp2_clean_data.csv,
models/fit_results.csv (corrected timing). The Exp 2 R scripts load the data through
revision/exp2_sr_primary/prep.R (SUBSET=SR for SR games, unset for all games).

Condition labels: interactive = "Real-time messaging", unidirectional = "Delayed messaging",
slider = "Slider (numerical estimates)". Colors: slider #E69F00, delayed messaging #56B4E9,
real-time messaging #009E73 (Exp 1 palette from analysis/exp1/exp1_main_analysis.qmd).
common.R holds the shared labels, palette, save function and the Exp 2 loader.

Files
-----

fig2_exp1_results.pdf / .png   (script: fig2_exp1_results.R)
  Figure 2, Experiment 1 results, all three conditions. (A) Mean absolute error by round with
  95% bootstrapped CIs and quadratic fits; the slider's pre-social first estimate is shown at
  round 0 and joined to round 1 of the message conditions by dashed lines. (B) Mean change in
  estimate from the previous round. Same construction as the qmd; only the labels changed.

fig4_exp2_design.pdf / .png   (script: fig4_exp2_design.R)
  Figure 4, Experiment 2 design (replaces the cartoon). Every Exp 2 network (all 378 networks
  with responses, SR and RS) placed in the three-dimensional difficulty space, as three pairwise
  projections: (A) total sample size vs. information distribution (entropy), (B) total sample
  size vs. representativeness, (C) entropy vs. representativeness. Statistics are computed over
  active participants, as in the analysis (nCrittersGame_actual, entropy_actual,
  representation_actual). Point area is the number of networks of that condition at that point
  of the projection; color is condition. Axes: total sample size in critters (5-40),
  entropy in nats (0 to ln 4 = 1.39), representativeness as the mean absolute difference
  between each player's sample proportion and the network proportion (0-0.62; 0 = every
  player's sample matches the network).

fig5_exp2_results_SR.pdf / .png   (script: fig5_exp2_results.R)
  Figure 5, Experiment 2 results on SR games (primary analysis; 93 slider and 99 real-time
  messaging networks). (A) Mean absolute error by round with 95% bootstrapped CIs, slider
  pre-social baseline at round 0 (as in the qmd). (B) Final-round mean absolute error (last
  round of each condition) by condition within median-split bins of each difficulty dimension,
  in the order of Figure 4: total sample size, information distribution, representativeness.
  Bins are ordered harder then easier, and tick labels give the range of each bin. Error bars
  are 95% percentile bootstrap CIs that resample networks (2000 resamples).

figS_exp2_results_full_sample.pdf / .png   (script: fig5_exp2_results.R)
  Supplementary figure: the same figure as Figure 5 on the full sample (SR and RS games;
  199 slider and 179 real-time messaging networks). Median splits are computed within this
  sample. Labelled "full sample (SR and RS games)" in the figure title.

fig7_model_predictions.pdf / .png   (script: fig7_predict.py)
  Figure 7, model predictions for Experiment 2: predicted final error of the Evidence model
  (real-time messaging) and the Belief model (slider) for unrepresentative and representative
  networks, with 95% bootstrapped CIs over games. Parameters from models/fit_results.csv
  (corrected timing). fig7_predict.py is a copy of models/predict.py with only these changes:
  repository-relative input paths, output to this folder, revised legend labels, palette
  colors, and the legend moved below the axes. The simulation, the games (all Exp 2 games),
  the design-level representativeness median split and the seed are unchanged.
