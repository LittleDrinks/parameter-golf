# 2026-06-04 Ralph-loop acceptance goal

## Context

User asked Codex to set a next-stage acceptance metric before starting a ralph loop.

## Goal

Complete one research loop that turns the current OCR-centered uncertainty into an organized, pushed branch set with enough evidence to choose the next training run.

## Acceptance metric

The loop is accepted only if all of the following are true:

1. At least four directions are explored in parallel through worker prompts or equivalent archived tasks:
   - answer-style/eval calibration,
   - OCR seed robustness or subset eval,
   - sample-level failure taxonomy,
   - one non-OCR branch such as LoRA policy or data/instruction audit.
2. Every rmux/panel worker window is archived to `ara/trace/worker-captures/` with prompt, latest or final capture, run root, and final sentinel; completed or stale panes are closed after archival.
3. Development blockers are flattened into explicit outcomes:
   - fixed with commit,
   - converted to a smaller falsifying check,
   - or recorded as a blocking dependency with owner/path/evidence.
4. Cloud/server worktrees touched by the loop are cleanly organized:
   - each experiment has its own worktree and branch,
   - heavy artifacts stay under `/data/zsm/parameter-golf/runs/<run_id>`,
   - branch names and commits are recorded in ARA,
   - branches are pushed to the remote repository.
5. Atomic commits exist for each completed unit:
   - local ARA planning/ledger updates,
   - worker prompt/archive updates,
   - each code/config branch change,
   - final summary/decision update.
6. The final ARA state contains:
   - updated `ara/evidence/results.csv` for numeric results,
   - updated `ara/trace/exploration_tree.yaml` statuses,
   - one final session note with accepted/rejected directions and the next chosen training candidate.

## Stop condition

Do not spend new training budget until eval-only and offline checks show that a candidate has a plausible path to at least `+0.003` exact-match improvement over the current best aligned result:

```text
eval_ocr16_seed1_textvqa_val_ocr = 0.7262000000000036
```

If no candidate passes the cheap gates, the accepted loop outcome is a documented pivot rather than a training launch.
