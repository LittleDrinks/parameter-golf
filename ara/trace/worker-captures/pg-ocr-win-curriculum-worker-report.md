# ocr-win-curriculum-worker Report

## Worktree and Environment

| Field | Value |
|-------|-------|
| Worktree | `/home/zsm/pg-worktrees/ocr_win_curriculum` |
| Branch | `exp/ocr-win-curriculum` |
| Base commit | `101959c882dd9d05be79668f80456da038c01c77` |
| Run root | `/data/zsm/parameter-golf/runs/analysis_ocr_win_curriculum_20260605_114715` |
| Server | `smYuHangLab2` |
| GPU used | None (CPU-only analysis) |

## Evidence Paths Read

1. `/data/zsm/parameter-golf/runs/stage3_textvqa_val_ocr_sample_evidence/samples_textvqa_val_ocr_ocr16_vs_baseline_seed2.jsonl` (5000 lines)
2. `/data/zsm/parameter-golf/runs/stage3_textvqa_val_ocr_sample_evidence/summary.json`
3. `/data/zsm/parameter-golf/runs/analysis_failure_taxonomy/summary.json`

## Subset Definitions

| Label | Definition |
|-------|------------|
| `ocr16_better` | `delta > 0` (OCR16 exact_match > baseline exact_match) |
| `baseline_better` | `delta < 0` |
| `tied` | `delta == 0` |
| `gold_answer_in_ocr` | Any normalized gold answer substring matches any normalized OCR token (length >= 2) in `ocr_tokens_used` |
| `ocr16_pred_in_ocr` | Normalized OCR16 prediction matches any normalized OCR token |
| `baseline_pred_in_ocr` | Normalized baseline prediction matches any normalized OCR token |
| `question_prefix` | First word of question mapped to category (`what`, `how`, `how_many_much`, `where`, `who`, `when`, `which`, `why`, `other`) |
| `answer_length_bin` | Max word count across gold answers (`1_word`, `2_words`, `3_4_words`, `5_plus_words`) |
| `question_length_bin` | Character length of question (`short_lt30`, `medium_30_60`, `long_gt60`) |
| `ocr_token_count_bin` | Number of OCR tokens used (`few_lt5`, `medium_5_15`, `many_gt15`) |

## Counts and Strongest Signals

### Group Sizes

| Group | Count | Fraction |
|-------|-------|----------|
| OCR16 better | 229 | 4.58% |
| Baseline better | 149 | 2.98% |
| Tied | 4622 | 92.44% |

### Gold Answer in OCR

| Group | Count | Fraction |
|-------|-------|----------|
| OCR16 better | 176/229 | **76.86%** |
| Baseline better | 112/149 | **75.17%** |
| Tied | 3212/4622 | 69.49% |

**Critical finding**: Gold-in-OCR overlap is nearly identical between OCR16 wins and baseline wins (76.86% vs 75.17%, difference = 1.69 pp). This means `gold_answer_in_ocr` cannot reliably separate the two groups.

### Prediction in OCR

| Group | Metric | Count | Fraction |
|-------|--------|-------|----------|
| OCR16 better | ocr16_pred_in_ocr | 150/229 | **65.50%** |
| Baseline better | baseline_pred_in_ocr | 97/149 | **65.10%** |
| Baseline better | ocr16_pred_in_ocr (loser's pred) | 84/149 | 56.38% |

**Critical finding**: Prediction-in-OCR overlap is also nearly identical (65.50% vs 65.10%, difference = 0.40 pp).

### Strongest Discriminative Signals (OCR16 wins vs Baseline wins)

| Feature | Category | Odds Ratio | Interpretation |
|---------|----------|------------|----------------|
| `answer_length_bin` | `2_words` | **1.623** | OCR16 wins more often on 2-word answers |
| `question_prefix` | `other` | 1.520 | Slight OCR16 advantage on non-standard questions |
| `ocr_token_count_bin` | `few_lt5` | 1.244 | OCR16 wins slightly more with few OCR tokens |
| `question_length_bin` | `long_gt60` | 0.651 | OCR16 wins less on very long questions |
| `question_prefix` | `how_many_much` | 0.415 | OCR16 wins less on quantity questions |
| `question_prefix` | `why` | 0.130 | OCR16 wins much less on "why" (only 1 sample) |

All OR values are close to 1.0, indicating weak separation. The largest OR (1.623 for 2-word answers) is based on only 73 vs 29 samples and is not statistically reliable.

### Strongest Discriminative Signals (OCR16 wins vs Tied)

| Feature | Category | Odds Ratio | Interpretation |
|---------|----------|------------|----------------|
| `question_prefix` | `how` | **3.439** | OCR16 wins much more on "how" questions |
| `answer_length_bin` | `1_word` | 0.648 | OCR16 wins less on 1-word answers |

Note: The `how` signal is based on only 3 OCR16 wins vs 20 tied samples — under-powered.

## Feasibility Verdict

**BLOCKED** — No stable subset definition separates OCR-benefit from OCR-regression samples.

The two candidate features that would naively drive a curriculum (`gold_answer_in_ocr` and `prediction_in_ocr`) are present in nearly identical fractions of both wins and losses. Any reweighting based on these signals would simultaneously up-weight both the 229 OCR16-better samples and the 149 baseline-better samples, producing no net directional bias.

Additionally:
- The effect window is tiny: only 378/5000 (7.56%) samples show any difference.
- All other categorical signals (question prefix, answer length, question length, OCR token count) have weak effect sizes and are severely under-powered.
- The tied group (92.44%) dominates, meaning any curriculum signal would be applied to a massive background where it has no expected effect.

## Patch Plan Summary

A curriculum/reweighting patch is **not recommended**. For completeness, the hypothetical patch would be:

- **Where**: Add per-sample weight tensor in the training dataloader/collator, after batch construction.
- **Prompt parity**: Reweighting must only scale loss contributions; prompts and input text must remain identical to baseline.
- **Speculative weights**: 1.5x–2.0x for `gold_answer_in_ocr` samples, 1.0x otherwise.
- **Guard eval**: Track exact_match separately on the 149 baseline-better samples; reject if degraded.

However, because the target feature is present in ~76% of both wins and losses, this patch would re-weight ~3/4 of all training examples uniformly, diluting any signal. The risk of degrading overall performance outweighs the expected gain from a ~0.01 exact_match improvement.

**Unblock condition**: A new analysis must find a subset feature with:
- OR >= 3.0 separating OCR16 wins from baseline wins, with >= 20 samples per tail.
- Computability from training data without ground-truth answers (no data leakage).
- Subset size >= 5% of the training set for sufficient gradient signal.

## Recommendation

**DROP this direction.** Do not launch a full training worker for OCR win curriculum/reweighting.

Rationale:
1. No reproducible, stable subset label can distinguish OCR-benefit from OCR-regression examples.
2. Prior failure taxonomy already found similar gold-in-OCR overlap for both win types; this analysis confirms and extends that finding.
3. GPU time should be allocated to directions with clearer subset separability or stronger prior evidence (e.g., answer-style/prompt-template, OCR dropout, LoRA hyperparameter sweep).

## Run-Root Outputs

All artifacts written to `/data/zsm/parameter-golf/runs/analysis_ocr_win_curriculum_20260605_114715`:

- `commands.log` — command history
- `subset_summary.json` — full per-group statistics and cross-tabulations
- `subset_examples.jsonl` — 50 representative examples (25 OCR16 wins, 15 baseline wins, 10 tied)
- `patch_plan.md` — detailed patch plan with blocker rationale
- `status.json` — machine-readable verdict

---

DONE ocr-win-curriculum-worker
