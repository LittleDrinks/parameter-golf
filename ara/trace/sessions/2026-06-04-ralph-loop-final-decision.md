# 2026-06-04 Ralph-loop final decision

## Scope

This note closes the current ralph-loop research batch:

```text
parallel worker exploration, archived rmux evidence, resolved development blockers, atomic commits, and organized remote worktree branches
```

## Evidence completed

Parallel CPU-only worker directions:

```text
answer-style/eval calibration  -> /data/zsm/parameter-golf/runs/analysis_answer_style_audit
seed robustness preflight      -> /data/zsm/parameter-golf/runs/analysis_seed_robustness_preflight
failure taxonomy               -> /data/zsm/parameter-golf/runs/analysis_failure_taxonomy
data audit                     -> /data/zsm/parameter-golf/runs/analysis_data_audit
```

Serial GPU evals:

```text
baseline seed1 textvqa_val_ocr -> 0.7134200000000036
baseline seed2 textvqa_val_ocr -> 0.7133600000000039
baseline seed3 textvqa_val_ocr -> 0.7154200000000039
OCR16 seed1 textvqa_val_ocr    -> 0.7262000000000036
```

Baseline aligned OCR summary:

```text
mean(seed1,seed2,seed3) = 0.7140666666666705
best baseline           = 0.7154200000000039
OCR16 delta vs mean     = 0.012133333333333103
OCR16 delta vs best     = 0.010780000000000012
```

## Accepted findings

1. OCR16's aligned-eval gain is not explained away by baseline seed variance across seeds 1-3.
2. Raw first-N OCR prompting remains useful, but the failure taxonomy weakens question-relevant OCR selection as the immediate next training bet.
3. The most actionable cheap control is answer-style eval, especially `max_new_tokens=32`, because it requires no code change and can test truncation/style effects.
4. New external data is not currently a strong immediate branch because TextVQA is the only fully local TextVQA-like source; DocVQA/ST-VQA/TextOCR/OCR-VQA/OCRBench are not locally available without cache/download work.

## Rejected or deferred directions

```text
question-relevant OCR selection training
```

Deferred. OCR16 wins and baseline wins have nearly identical gold-in-OCR overlap, and many OCR16 losses contain the wrong OCR16 prediction in OCR tokens.

```text
new external data augmentation
```

Deferred. Not enough local cached data sources are available to run a clean short-answer-compatible audit without new download/cache work.

```text
new full training run now
```

Rejected for this loop. No candidate has yet passed a cheap gate suggesting `+0.003` over current OCR16 aligned eval.

## Next candidate

Next action, before training:

```text
Run OCR16 textvqa_val_ocr with max_new_tokens=32.
```

Reason:

- zero source change,
- single serial GPU eval,
- directly tests whether answer truncation/style is suppressing OCR16,
- if it fails to improve, prompt length is deprioritized.

Provisional next training candidate after that gate:

```text
short-run OCR-conditioned prompt/style ablation on existing TextVQA only
```

Launch only if eval-only answer-style controls indicate a plausible path to at least `+0.003` over:

```text
eval_ocr16_seed1_textvqa_val_ocr = 0.7262000000000036
```

## Branch and commit state

ARA records branch:

```text
branch: ara-records-only
latest local/GitHub commit before this note: bc9d247 Record seed3 aligned OCR eval
```

Experiment branch:

```text
branch: exp/seed-robustness-ocr
commit: d659cbdf335a66f43e835dd2c3899ff76edeb5d6
remote worktree: /home/zsm/pg-worktrees/pg-seed-robustness-ocr
GitHub push: completed from local credential environment
```

Existing server experiment branches also pushed from the local credential environment:

```text
origin/exp/eval-baseline-ocr
origin/exp/eval-ocr16-ocr
origin/exp/harness
origin/exp/ocr-analysis
origin/exp/seed-robustness-ocr
```

Public server credential policy:

```text
Do not configure GitHub credentials on smYuHangLab2.
If a server-side push fails, treat it as expected; commit locally on the server and push from a credentialed local/VS Code environment or ask the user.
```

## Final hygiene

- Local rmux sessions were closed.
- No `zsm` train/eval GPU process remained after seed3.
- GPU2 returned to idle.
- Heavy artifacts remained under `/data/zsm/parameter-golf/runs/<run_id>`.
