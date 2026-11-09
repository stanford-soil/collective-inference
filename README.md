# Collective inference depends on the communication channel

Data and analysis code for "Collective inference depends on the communication channel" (Zubak & Hawkins, revised 2026).

Every number and figure in the paper is produced by one of the scripts below, starting from the raw data in `data/`. What each script prints is saved in `results/`, so the results can be read without running anything.

## Running the analyses

```
bash run_all.sh
```

This runs every script in order (about 6 minutes) and rewrites `results/` and `figures/`. A single script can be run from its own folder once the scripts before it have run, for example `cd exp1 && Rscript 01_models.R`.

Requirements: R with tidyverse, lme4, lmerTest, emmeans, tidyboot, ggthemes, patchwork and jsonlite; Python 3 with pandas, numpy, scipy, statsmodels, scikit-learn and matplotlib. A UTF-8 locale is needed because each participant's sample is stored as a string of emoji (`run_all.sh` sets one).

## How the code is organised

Each script answers one question. It begins with a comment that states the question, the files it reads and what it writes, and it runs from top to bottom.

| Folder | Contents |
|---|---|
| `data/` | Raw exports of both experiments and the first author's coding of the Experiment 2 messages. `data/derived/` is rebuilt by `prep/` and is not committed. |
| `lib/` | The few things shared between scripts: file paths and condition names (`common.R`, `common.py`), and the functions that load the analysis data of each experiment (`exp1_data.R`, `exp2_data.R`). |
| `prep/` | From the raw exports to the clean data. |
| `exp1/`, `exp2/` | The analyses of each experiment. |
| `coding/` | The coding of the Experiment 2 chat messages and the analyses of message content. |
| `partner_schedule/` | Who sent to whom in each round, and the analyses that depend on it. |
| `models/` | The Belief and Evidence models. |
| `figures/` | One script per data figure. |
| `response_letter/` | Analyses of the original submission that the revised paper no longer reports. |
| `results/` | The printed output of every script, as `results/<folder>/<script>.txt`. |
| `experiments/`, `stimuli/` | The experiment code and the generation of the Experiment 2 game configurations. |

## Where each result comes from

### Experiment 1

| Result | Script |
|---|---|
| Sample and exclusions | `prep/01_exp1_clean.R` |
| Error over rounds; condition differences in the final round; adaptive weighting; stabilization | `exp1/01_models.R` |
| Other exclusion thresholds, complete networks, networks launched with four players (Appendix A) | `exp1/02_robustness.R` |
| Recruitment and attrition by condition (Appendix A) | `exp1/03_attrition.R` |
| Figures 2 and 3 | `figures/fig2_exp1_results.R`, `figures/fig3_adaptive_weighting.R` |

### Experiment 2

| Result | Script |
|---|---|
| Sample | `prep/02_exp2_clean.R`, `lib/exp2_data.R` |
| Error by condition; condition by difficulty (representativeness, sample size, entropy) | `exp2/01_models.R` |
| Response-rate exclusion; estimates of 0, 50 and 100 removed (Appendix C) | `exp2/02_robustness.R` |
| Pre-assigned difficulty statistics (Appendix C) | `exp2/03_preassigned_difficulty.R` |
| Recruitment and attrition by condition (Appendix A) | `exp2/04_attrition.R` |
| Comparison of the two slider versions (Appendix C) | `exp2/05_slider_version_check.py` |
| Figures 4 and 5 | `figures/fig4_exp2_design.R`, `figures/fig5_exp2_results.R` |

### Message content (Experiment 2 chat)

| Result | Script |
|---|---|
| Agreement between the two codings; final code of every message | `coding/01_final_codes.py` |
| Share of messages with each kind of content; relayed information and accuracy | `coding/02_content_analysis.R` |
| Automated detection of count reports, including Experiment 1 | `coding/03_count_reports_auto.py` |
| Over-counting in relayed counts | `coding/04_relayed_overcounting.py` |

`coding/codebook.md` is the codebook. `unique_texts.csv` lists every distinct message text and `second_coder_labels.csv` holds the second coding of each. `adjudication/` holds the rules (`RULES.md`), the disputed messages as shown to the adjudicator (`items.json`) and his decisions (`decisions.json`). `exp2_message_codes_final.csv` gives the first, second and final code of every message.

### Partner schedule (Appendix D)

| Result | Script |
|---|---|
| Who sent to whom in every round | `partner_schedule/01_build_partner_tables.py` |
| The logged recipient of every message agrees with the schedule | `partner_schedule/02_check_partner_schedule.py` |
| Estimates moved toward the sender's sample, not the recipient's | `partner_schedule/03_influence_test.py` |
| Mutual versus one-way rounds | `partner_schedule/04_mutual_vs_oneway.R` |
| Relaying within a round | `partner_schedule/05_same_round_relay.py` |
| Questions and answer-like replies in one-way rounds | `partner_schedule/06_question_answer_coherence.py` |
| First versus later encounters with a sender (response letter) | `partner_schedule/07_first_encounter.R` |

### Models

| Result | Script |
|---|---|
| Model fits, AIC comparison, timing variants (main text and Appendix B) | `models/01_fit.py` |
| Predictions for Experiment 2 (Figure 7) | `figures/fig7_model_predictions.py` |

### Superseded analyses (response letter)

| Result | Script |
|---|---|
| Experiment 1 models without the network random intercept | `response_letter/01_exp1_without_network_intercept.R` |
| Experiment 2 models on all networks and on the excluded networks | `response_letter/02_exp2_all_and_excluded_networks.R` |
| Models with the original timing | `models/01_fit.py` (timing `original`) |
| Message content with the first author's original coding | `coding/02_content_analysis.R` |

## Names used in the data

Conditions keep their original names in the data and code.

| In the data | In the paper |
|---|---|
| `slider` | slider (numerical estimates) |
| `unidirectional` | delayed messaging |
| `interactive` | real-time messaging (Experiment 1), chat (Experiment 2) |

Other names: `gameID` is a network, `playerID` a participant, `idx` the round, `guess` an estimate (0 to 100, percentage of rabbits) and `error` its absolute distance from the percentage of rabbits in the network's combined sample.

## Corrections made in the revision

1. **Partner assignment.** The experiments were designed to pair participants in every round. The rule in the experiment code (`experiments/server/src/callbacks.js`) instead produced mutual pairs only in rounds 1, 4, 7 and 10 in four-player networks. In the other rounds each participant sent to one network member and received from another. `partner_schedule/` reconstructs the schedule and checks it against the message logs.
2. **Slider messages in Experiment 2.** The direction of the slider was counterbalanced. In one version (`RS`) the slider measured the proportion of squirrels, but the message generated from it reported the value as a proportion of rabbits (`experiments/client/src/components/Opinion.jsx`), so recipients read the complement of the sender's estimate. All Experiment 2 analyses therefore use only the networks with the other version (`SR`), in both conditions. These 193 networks are listed in `lib/exp2_sr_games.csv`, and the restriction is applied where the data are loaded (`load_exp2()` in `lib/exp2_data.R`, `keep_sr()` in `lib/common.py`).
3. **Model timing.** In the messaging conditions the messages come before the estimate within a round, so an update is paired with the sender of the same round. The original code used the sender of the previous round. `models/01_fit.py` fits both.
