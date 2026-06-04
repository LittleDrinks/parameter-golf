# 2026-06-04 Server tmux/eval-crash investigation

## User report

- Server: `smYuHangLab2`.
- A worktree experiment was running in tmux/rmux.
- The tmux session later crashed/disappeared.
- User could not see expected logs/results through VS Code SSH in the server worktree.
- User remembered training likely completed, but eval may have crashed.
- Last observed training behavior: loss seemed to oscillate / jump repeatedly, raising concern that the run was not converging.

## Actions performed

- Installed ARA skills from `AmberLJC/Agent-Native-Research-Artifact` into local Codex skills:
  - `/home/q2635/.codex/skills/research-manager`
  - `/home/q2635/.codex/skills/rigor-reviewer`
  - `/home/q2635/.codex/skills/compiler`
- Created/switched local branch `ara-records` for research records.
- Performed read-only SSH inspection of `smYuHangLab2`; no server code was modified.

## Remote process/session status at 2026-06-04 18:28 CST

- `tmux list-sessions`: no sessions visible.
- `rmux list-sessions`: no sessions visible.
- User `zsm` had no active `parameter-golf` train/eval process.
- GPU was occupied by other user `wjh` processes, not by `zsm` parameter-golf jobs.

## Located run

Run root:

```text
/data/zsm/parameter-golf/runs/ocr16_seed1
```

Important files found:

```text
/data/zsm/parameter-golf/runs/ocr16_seed1/logs/prepare.log
/data/zsm/parameter-golf/runs/ocr16_seed1/logs/train.log
/data/zsm/parameter-golf/runs/ocr16_seed1/logs/merge.log
/data/zsm/parameter-golf/runs/ocr16_seed1/logs/eval.log
/data/zsm/parameter-golf/runs/ocr16_seed1/outputs/trainer_state.json
/data/zsm/parameter-golf/runs/ocr16_seed1/outputs/train_results.json
/data/zsm/parameter-golf/runs/ocr16_seed1/summary.csv
/data/zsm/parameter-golf/runs/ocr16_seed1/eval/outputs__merged/20260604_175118_results.json
```

## Confirmed result

From remote `summary.csv` and result JSON:

```text
run_id: ocr16_seed1
seed: 1
branch: exp/harness
commit: 101959c / 101959c882dd9d05be79668f80456da038c01c77
config: /data/zsm/parameter-golf/runs/ocr16_seed1/config.yaml
GPU: 0
completed_steps: 1024
train_runtime_seconds: 3011.4045
train_loss: 0.4656474234070629
eval_task: textvqa_val
exact_match: 0.7076800000000036
stderr: 0.006091340115678913
result_path: /data/zsm/parameter-golf/runs/ocr16_seed1/eval/outputs__merged/20260604_175118_results.json
eval_total_time_seconds: 1274.2231469119433
```

Eval did **not** crash. `eval.log` ended with aggregated result saving, submission file saving, and a normal lmms-eval table:

```text
textvqa_val exact_match 0.7077 ± 0.0061
```

Submission file:

```text
/data/zsm/parameter-golf/runs/ocr16_seed1/eval/submissions/textvqa_submission_2026-06-04-18-12-32.json
```

## Loss / convergence check

Evidence source:

```text
/data/zsm/parameter-golf/runs/ocr16_seed1/outputs/trainer_state.json
```

Summary:

```text
global_step: 1024
log_points_with_loss: 204
first10_avg_loss: 0.70053
last10_avg_loss: 0.43932
first20_avg_loss: 0.615985
last20_avg_loss: 0.424955
min_loss: 0.2152
max_loss: 1.0494
```

Window averages over 20 logged points showed early improvement then noisy plateau:

```text
step~5:    0.615985
step~105:  0.517440
step~205:  0.472495
step~305:  0.477555
step~405:  0.454485
step~505:  0.445795
step~605:  0.394310
step~705:  0.414920
step~805:  0.430490
step~905:  0.445810
step~1005: 0.431050
```

Interpretation: the loss is visibly noisy and has occasional spikes, but the aggregate trajectory does not look like hard divergence. It drops from ~0.62 early to ~0.42–0.45 late, then plateaus/oscillates. The final score is slightly below the recorded seed-1 baseline, so OCR16 is not evidence of improvement yet.

## Comparison to existing baseline ledger

Existing local `ara/evidence/results.csv` records:

```text
server_baseline_seed1 exact_match 0.7085800000000037
server_baseline_seed2 exact_match 0.7112000000000038
server_baseline_seed3 exact_match 0.7082400000000038
```

`ocr16_seed1` exact_match is `0.7076800000000036`, lower than baseline seed 1 by about `0.0009`, far smaller than eval stderr (`~0.0061`). Treat as no demonstrated improvement, not a decisive regression.

## Current status

- The tmux disappearance did not destroy run evidence.
- The run root is under `/data/zsm/parameter-golf/runs/ocr16_seed1`, not the older `/home/zsm/parameter-golf/results` path.
- Training completed, merge completed, eval completed.
- Local ARA ledger was updated with the confirmed `ocr16_seed1` result.

## Suggested next steps

1. Do not rerun `ocr16_seed1`; evidence exists and is complete enough.
2. If testing OCR tokens further, run at least seed 2 or an `ocr32`/prompt variant, but only after deciding whether OCR16's slight seed-1 drop is acceptable exploratory evidence.
3. Prefer `scripts/run_one.sh` for future runs because it preserved logs, config snapshot, commit, diff, train results, eval results, and summary.

## Additional path-map finding

Remote repository/worktree layout:

```text
/home/zsm/parameter-golf              main git worktree, branch main, commit 101959c
/home/zsm/pg-worktrees/pg-harness     git worktree, branch exp/harness, commit 101959c
/data/zsm/parameter-golf              artifact/storage root, not a git repository
/data/zsm/parameter-golf/runs         explicit run-root storage
/data/zsm/parameter-golf/outputs      older output storage
/home/zsm/parameter-golf/results      older baseline eval result storage
```

`/home/zsm/pg-worktrees/pg-harness` has symlinks:

```text
data    -> /data/zsm/parameter-golf/data/
outputs -> /data/zsm/parameter-golf/outputs/
```

It does **not** have a `runs` symlink. Therefore, if VS Code opens `/home/zsm/pg-worktrees/pg-harness`, the completed `ocr16_seed1` logs/results will not appear in the worktree unless the user manually browses to `/data/zsm/parameter-golf/runs/ocr16_seed1` or creates a symlink in the future.

Shell history only showed attaches to the tmux session:

```text
tmux a -t ocr16_seed1
```

No exact run-launch command was recovered from shell history. The run-root evidence indicates `RUN_ROOT` was explicitly set to `/data/zsm/parameter-golf/runs/ocr16_seed1` or the run was otherwise launched with that path.

The run's `git_diff.patch` captured the harness modifications active at run time, including:

- `eval_qwen.sh`: configurable `RESULTS_DIR`.
- `prepare_textvqa.py`: configurable `DATA_PATH`.
- `run_train.sh`: configurable `NUM_PROCESSES`.
- `train_textvqa_qwen3vl.py`: saving train metrics and trainer state.

This explains why this run preserved evidence even though the tmux session disappeared.
