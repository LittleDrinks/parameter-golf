# AGENTS.md

This repository is used for TextVQA / Qwen3-VL LoRA experiments. Treat source code and experiment records as separate concerns.

## Operating Model

- Local repository: keep lightweight research records in `ara/`, prompts in `agent-prompts/`, and workflow notes here.
- Recording branch intent: use a dedicated branch named `ara-records` for ARA notes and experiment ledgers when `.git/` is writable.
- Server (`smYuHangLab2`): keep heavyweight code runs, datasets, model outputs, logs, and evaluation artifacts on the server.
- Do not move large artifacts into git.
- Do not edit training/eval source code while doing experiment forensics unless the user explicitly asks.

## Current Access Notes

- SSH target: `smYuHangLab2` from local SSH config.
- Intended remote user from local config: `zsm`.
- Intended host/port from local config: `58.199.164.190:50002`.
- Current Codex sandbox blocks network/SSH escalation due an approval-service failure; server checks are pending.
- `.git/` in this local checkout is mounted read-only, so branch creation is currently blocked even though the worktree itself is writable.

## Experiment Forensics Checklist

When investigating a server experiment without changing code:

1. Identify sessions and processes:
   - `tmux list-sessions || true`
   - `rmux list-sessions || true`
   - `ps -fu "$USER" | egrep 'train_textvqa|lmms_eval|accelerate|torchrun|python|run_one|eval_qwen' | grep -v grep || true`
   - `nvidia-smi`
2. Locate worktrees and run roots:
   - `find ~ /data/zsm -maxdepth 4 -type d \( -name parameter-golf -o -name runs -o -name outputs -o -name results \) 2>/dev/null | sort`
   - `find /data/zsm ~/parameter-golf -maxdepth 6 -type f \( -name '*.log' -o -name '*results.json' -o -name 'trainer_state.json' -o -name 'train_results.json' \) 2>/dev/null | sort`
3. For each candidate run, capture:
   - run id / directory
   - seed
   - config path and config snapshot
   - git commit / diff snapshot if present
   - completed train steps
   - final loss / loss trend symptoms
   - merge status
   - eval command, result path, and crash traceback if eval failed
4. Archive only lightweight evidence locally:
   - update `ara/evidence/results.csv` for confirmed numeric results
   - add session notes under `ara/trace/sessions/`
   - keep raw logs on the server; local ARA should link to paths and include short excerpts only

## Known Results Ledger

See `ara/evidence/results.csv`. Existing recorded server baseline results:

- seed 1 exact_match ≈ 0.70858
- seed 2 exact_match ≈ 0.71120
- seed 3 exact_match ≈ 0.70824

## Resolved Incident

See `ara/trace/sessions/2026-06-04-server-tmux-eval-crash.md`: tmux/rmux disappeared, but the run evidence was found under `/data/zsm/parameter-golf/runs/ocr16_seed1`; training, merge, and eval all completed. The observed loss oscillation was noisy but not hard divergence by aggregate trainer-state statistics.

## 2026-06-04 Remote Finding

The missing tmux/rmux session did not imply lost results. The run was found at:

```text
/data/zsm/parameter-golf/runs/ocr16_seed1
```

`ocr16_seed1` completed prepare/train/merge/eval. Confirmed metric:

```text
textvqa_val exact_match = 0.7076800000000036 ± 0.006091340115678913
```

The eval result is at:

```text
/data/zsm/parameter-golf/runs/ocr16_seed1/eval/outputs__merged/20260604_175118_results.json
```

Training loss was noisy but not hard-divergent by `trainer_state.json`: first20 average ≈ 0.616, last20 average ≈ 0.425. Treat OCR16 seed 1 as no demonstrated improvement over the baseline, not as an eval failure.


## Project-Level Skills

Global ARA skills were initially installed under `/home/q2635/.codex/skills`:

```text
research-manager
rigor-reviewer
compiler
```

Project-level copies now live under this repository's `skills/` directory, along with the custom `panel-as-worker` skill:

```text
skills/research-manager
skills/rigor-reviewer
skills/compiler
skills/panel-as-worker
```

The active project-level Codex skill copies are also installed under:

```text
.codex/skills/research-manager
.codex/skills/rigor-reviewer
.codex/skills/compiler
.codex/skills/panel-as-worker
```

These are plain directory copies, not symlinks. Keep `skills/` as the versioned source of truth and refresh `.codex/skills/*` from `skills/*` when the project skills change.

Panel/rmux scripts were migrated from top-level `scripts/` into `skills/panel-as-worker/scripts/`. Keep `agent-prompts/` in the repo as prompt-contract source material for future skill improvements.

## Codex Orchestration Policy

Codex should act as the orchestrator, not as the default direct implementer.

- Use Codex to maintain ARA state, decide next research actions, inspect evidence, and coordinate workers.
- Delegate code-writing tasks to a pane worker through `panel-as-worker` unless the user explicitly asks Codex to edit directly.
- Delegate long-running experiment launch/monitoring to `panel-as-worker`; preserve logs and DONE sentinels.
- Use ARA flow for research control:
  1. record the question/hypothesis in `ara/logic/` or `ara/trace/exploration_tree.yaml`;
  2. define the smallest falsifying check;
  3. delegate implementation or run monitoring to a pane worker;
  4. collect durable evidence paths and metrics;
  5. update `ara/evidence/results.csv` and session trace;
  6. only then promote/revise claims.
- Do not mix experiment source-code changes into the ARA-record branch unless explicitly requested; keep research records lightweight.

## Remote Path Map

When opening the server in VS Code, distinguish git worktrees from artifact storage:

```text
/home/zsm/parameter-golf              main git worktree
/home/zsm/pg-worktrees/pg-harness     exp/harness git worktree
/data/zsm/parameter-golf              artifact storage, not git
/data/zsm/parameter-golf/runs         durable run logs/results
```

The harness worktree has `data` and `outputs` symlinks into `/data`, but no `runs` symlink. Look directly under `/data/zsm/parameter-golf/runs/<run_id>` for run logs.
