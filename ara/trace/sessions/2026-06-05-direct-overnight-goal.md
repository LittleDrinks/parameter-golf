# 2026-06-05 direct overnight goal

Use this document as the direct goal prompt after context is cleared.

## Goal

Continuously optimize `parameter-golf` TextVQA exact_match until `2026-06-05 08:00 Asia/Shanghai`, using worker delegation and shared-server-safe GPU scheduling. Do not voluntarily stop before the hard stop. At the hard stop, archive all worker panes/logs, commit records atomically, and output a report.

## Acceptance Criteria

By `2026-06-05 08:00 Asia/Shanghai`, produce a final report containing:

- Every attempted direction, including failed directions.
- For each full experiment: independent worktree, branch, commit, config, seed, run root, result path, metric, and matched eval task.
- At least one non-OCR direction attempted as a real proof-of-idea if GPU time becomes available.
- Review status for any changed training/eval/harness code.
- Archived rmux pane captures under `ara/trace/worker-captures/`.
- Atomic commits for records and experiment code/config changes.
- Remote push status. If server cannot push due to missing credentials, record it as expected and push from local/VS Code credentials or ask the user.

Proof-of-idea means:

```text
independent worktree + full training + matched eval + config/commit/result/run_root records
```

CPU-only gates are smoke tests only; they do not prove model quality.

## Hard Constraints

- `smYuHangLab2` is a shared public server.
- Default GPU concurrency: 1 job.
- Maximum GPU concurrency: 2 jobs.
- Poll `nvidia-smi`; launch only on GPUs with `memory.used < 1000 MiB`.
- Do not kill unrelated processes.
- Workers may only stop their own process by reading that run root's `pid.txt`.
- Do not configure GitHub credentials on `smYuHangLab2`.
- Preserve main Codex session budget. Delegate exploratory coding, review, environment setup, monitoring, and long loops to Claude/Kimi workers via `panel-as-worker`.
- Keep `ara-records-only` records-only. Do not add training code, checkpoints, datasets, raw logs, or results JSONs to this branch.

## Known State

Records branch:

```text
repo: /home/q2635/wsl-workspace/parameter-golf
branch: ara-records-only
latest pushed commit before this note: 8f9dd80 Record overnight planning constraints
```

Aligned OCR results:

```text
OCR16 seed1 textvqa_val_ocr    = 0.7262000000000036
baseline seed1 textvqa_val_ocr = 0.7134200000000036
baseline seed2 textvqa_val_ocr = 0.7133600000000039
baseline seed3 textvqa_val_ocr = 0.7154200000000039
```

Interpretation:

- OCR16 remains about `+0.01213` above baseline mean and `+0.01078` above best baseline under aligned OCR eval.
- This proves the aligned OCR eval effect is not explained away by baseline seed variance.
- It does not prove that all future effort should stay OCR-only. User explicitly requested multiple directions with real proof-of-idea.

Prior worker/result records:

```text
ara/trace/sessions/2026-06-04-ralph-loop-final-decision.md
ara/trace/sessions/2026-06-04-ralph-loop-worker-batch-1.md
ara/evidence/results.csv
ara/trace/exploration_tree.yaml
```

## Env Worker Status

Already launched:

```text
session: pg-local-env-worker
role: local-env-worker
worktree: /tmp/pg-worktrees/local-env-gate
branch: exp/local-env-gate
base: origin/main
commit: 101959c882dd9d05be79668f80456da038c01c77
prompt: agent-prompts/local-env-worker.md
latest capture: ara/trace/worker-captures/pg-local-env-worker-latest.txt
expected report: /tmp/pg-worktrees/local-env-gate/agent-runs/local-env-worker-report.md
```

Current observed state:

- The worker is running in rmux.
- It created `/tmp/pg-worktrees/local-env-gate/.venv`.
- It timed out once while upgrading `pip/setuptools/wheel`.
- It is currently installing CPU wheels:

```text
.venv/bin/pip install torch==2.5.1 torchvision==0.20.1 --index-url https://download.pytorch.org/whl/cpu -q
```

- No GPU, training, server job, push, or credential action has been observed.
- Before relying on local gates, inspect the worker report if it exists; otherwise capture the pane and decide whether to let it continue or mark local setup infeasible.

Useful checks:

```bash
rmux list-sessions
rmux capture-pane -p -t pg-local-env-worker:0.0 -S -300
find /tmp/pg-worktrees/local-env-gate -maxdepth 4 -type f -path '*/agent-runs/*' -print
sed -n '1,220p' /tmp/pg-worktrees/local-env-gate/agent-runs/local-env-worker-report.md
```

## Review Plan

Review is a mandatory phase before trusting changed training/eval code.

- Local `/review` can review uncommitted changes, branch diffs against a base branch, or recent-turn changes, and can use custom review instructions.
- GitHub Codex code review requires a PR, Codex Cloud/code-review enabled for the repo, and `@codex review` on the PR.
- Bare local/server worktrees cannot receive GitHub PR review directly.

Worker review queue:

```text
1. eval-harness-reviewer: inspect task YAMLs, dataset_path patches, eval scripts, result extraction, matched eval consistency.
2. train-pipeline-reviewer: inspect training configs, LoRA merge/eval path, run-root durability, pid ownership, and no cross-worker kill hazards.
```

Record reviewer findings in ARA before interpreting any metric from modified code.

## Experiment Queue

Start with the best available low-blocking work, but do not let all effort collapse back to OCR.

1. `local-env-worker`: finish or declare local CPU-only gate infeasible.
2. Review workers: eval harness and train pipeline.
3. Full training directions, each in its own worktree:
   - answer-style / prompt-template training or ablation,
   - OCR dropout or robustness,
   - LoRA hyperparameter small sweep.
4. If time remains:
   - second seed for the best candidate,
   - matched eval on the same task and model path,
   - compare against `OCR16 seed1 textvqa_val_ocr = 0.7262000000000036`.

## Server Launch Pattern

Use one worktree per experiment:

```bash
git worktree add /home/zsm/pg-worktrees/<experiment-id> -b exp/<experiment-id> <base-branch>
```

Heavy artifacts go under:

```text
/data/zsm/parameter-golf/runs/<run_id>
```

Each run root should contain at least:

```text
command.sh
env.txt
git_commit.txt
git_diff.patch
pid.txt
logs/
status.json
config snapshot
result path or summary
```

## Final Report Shape

At or after `2026-06-05 08:00 Asia/Shanghai`, report:

```text
1. Summary verdict: best metric, best branch/commit, and whether any direction beat OCR16 aligned eval.
2. Experiments completed: table with branch, commit, config, seed, run root, metric.
3. Experiments attempted but blocked: blocker, evidence path, next action.
4. Review results: findings fixed, findings unresolved.
5. Worker hygiene: archived panes, closed stale sessions, active processes if any.
6. Git status: local commits, pushed branches, branches needing user push.
```

Do not mark the goal complete before the hard stop unless the user explicitly changes the stop condition.
