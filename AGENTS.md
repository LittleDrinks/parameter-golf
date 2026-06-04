# AGENTS.md

This branch is the project record/orchestration branch for `parameter-golf`. It is intentionally separate from the code branch.

## Branch Purpose

`ara-records-only` is an orphan records branch. It should contain only:

```text
AGENTS.md
CLAUDE.md
ara/
skills/
.codex/skills/
agent-prompts/
```

Do not add training code, model code, datasets, logs, checkpoints, results JSONs, or vendored dependencies to this branch. Record paths, metrics, and short excerpts instead.

## Orchestrator Role

Codex is the orchestrator by default.

- Maintain ARA state and branch hygiene.
- Decide the next smallest falsifying check.
- Inspect evidence and summarize results.
- Delegate code-writing, experiment launch, and monitoring to `panel-as-worker` unless the user explicitly asks Codex to edit directly.
- Keep implementation work on separate code branches/worktrees. Every experiment must use its own git worktree to avoid source, config, and artifact contamination.
- Protect the main Codex session budget. Prefer Claude/Kimi workers for exploratory coding, long environment setup, review passes, and monitoring loops.


## Worktree Requirement

Every experiment must run from a dedicated git worktree. Do not reuse the main checkout or the ARA records branch for experiments.

Required pattern:

```bash
git worktree add /home/zsm/pg-worktrees/<experiment-id> -b <experiment-branch> <base-branch>
```

Rules:

- One experiment idea or run family per worktree.
- Keep code/config changes inside that experiment worktree and branch.
- Store heavy artifacts under `/data/zsm/parameter-golf/runs/<run_id>`, not inside the git tree.
- Record the worktree path, branch, commit, config, seed, and run root in ARA before interpreting results.
- If a worker needs to edit code, launch it with `panel-as-worker` using that experiment worktree as `--workdir`.
- A full proof-of-idea experiment requires: independent worktree, full training, matched eval, config, commit, run root, and numeric result recorded in ARA.
- CPU-only gates are smoke tests only. They may catch broken code/config, but they do not prove training ideas.

## Overnight Optimization Loop

When the user approves an overnight loop with a hard stop, do not voluntarily stop before the stated time unless the user interrupts, safety/resource constraints require pausing, or all workers are blocked and the block is recorded.

Current loop target:

```text
Hard stop: 2026-06-05 08:00 Asia/Shanghai
Goal: continuously seek TextVQA exact_match improvement through full train + matched eval experiments.
```

Loop rules:

- Keep looking for directions until the hard stop. If one idea fails, archive it and start the next plausible direction.
- Default to one GPU job. Use at most two GPU jobs at once.
- Poll `nvidia-smi`; launch only on GPUs with `memory.used < 1000 MiB`.
- `smYuHangLab2` is a shared public server. Do not kill unrelated processes. Workers may only stop their own run-root PID recorded in `pid.txt`.
- Run one experiment idea or run family per worktree and branch.
- Commit atomically after meaningful code/config/record changes.
- Archive worker panes and logs promptly under `ara/trace/worker-captures/`, then close stale rmux windows.
- At the hard stop, produce a report with branches, commits, configs, run roots, metrics, open blockers, and next recommended experiments.

Candidate directions should not all concentrate on OCR. Maintain a queue that includes non-OCR alternatives such as answer-style/prompt-template changes, OCR dropout or robustness, LoRA hyperparameter sweeps, and other code-review-derived fixes.

## Project Skills

Project skills live in two places:

```text
skills/          # versioned source of truth
.codex/skills/   # active copies for Codex discovery
```

Keep them in sync by copying directories from `skills/*` to `.codex/skills/*`; do not use symlinks.

### research-manager

Use at the end of meaningful research turns to update ARA. Record decisions, experiments, evidence paths, failed ideas, and claim status changes. Do not force premature conclusions.

Typical outputs:

```text
ara/trace/sessions/YYYY-MM-DD-*.md
ara/trace/exploration_tree.yaml
ara/evidence/results.csv
ara/logic/*.md
```

### panel-as-worker

Use for pane-based worker delegation and monitoring. This is the default path for code edits and long-running experiment work.

Key scripts:

```text
.codex/skills/panel-as-worker/scripts/rmux_worker.sh
.codex/skills/panel-as-worker/scripts/rmux_dashboard.sh
```

Prompt contracts are kept in:

```text
agent-prompts/
```

Workers must have a clear role, allowed files, forbidden actions, checks, and final `DONE <role>` sentinel.

## Review Workflow

Review is a required step before trusting new training/eval code.

- Use local Codex or Claude review flows for uncommitted worktree diffs, branch diffs, or recent-turn diffs. In Codex, `/review` supports local review against uncommitted changes or a base branch and can take custom review instructions.
- GitHub Codex code review is PR-based. It requires Codex Cloud/code-review to be enabled for the repository and is triggered with `@codex review` on a pull request.
- A bare local or server worktree cannot receive GitHub code review directly. To use the GitHub review path, push a branch from the credentialed local environment, open a PR, then trigger `@codex review`.
- Codex GitHub review should focus on serious P0/P1 issues. For broader research correctness, spawn dedicated reviewer workers and record their findings.
- Record review status in ARA before interpreting results from code that changed the harness, data path, training loop, merge logic, or eval config.

### rigor-reviewer

Use when auditing ARA quality: evidence relevance, falsifiability, scope calibration, argument coherence, exploration integrity, and methodology. This is for review, not day-to-day logging.

### compiler

Use when converting a larger body of source material into structured ARA. For this project, prefer incremental `research-manager` updates unless rebuilding the artifact from scratch.

## ARA Workflow

For each research step:

1. Record or update the question/hypothesis in `ara/logic/` or `ara/trace/exploration_tree.yaml`.
2. Define the smallest check that could falsify the idea.
3. Delegate implementation/run work through `panel-as-worker` when code or long execution is involved.
4. Collect durable evidence: command, branch/commit, config, seed, run root, result path, metric, and relevant log excerpts.
5. Update `ara/evidence/results.csv` for confirmed numeric results.
6. Add a session note under `ara/trace/sessions/`.
7. Promote or revise claims only when evidence supports it.

## Compute Resource

Primary compute is available through SSH alias:

```bash
ssh smYuHangLab2
```

Local SSH config currently maps this alias to user `zsm` on `58.199.164.190:50002` over IPv4. Use this server for GPU experiments, durable run artifacts, and experiment forensics.

Known server layout:

```text
/home/zsm/parameter-golf              main code worktree
/home/zsm/pg-worktrees/pg-harness     harness/code worktree used in prior runs
/data/zsm/parameter-golf              artifact storage root
/data/zsm/parameter-golf/runs/<id>    durable run logs/results
```

Default behavior is read-only inspection. Launch runs or edit server code only when the user explicitly asks, preferably by delegating to `panel-as-worker`.

Server credential policy:

- Do not configure GitHub credentials on `smYuHangLab2`.
- Server-side push failure is expected and acceptable.
- Commit experiment work on the server branch, then push from the local/VS Code credential environment or ask the user to push.

## Server Records

Heavy artifacts live on the server, not in this branch.

Known path pattern:

```text
/data/zsm/parameter-golf/runs/<run_id>
```

When investigating experiments, prefer read-only commands first:

```bash
tmux list-sessions || true
rmux list-sessions || true
ps -fu "$USER" | egrep 'train_textvqa|lmms_eval|accelerate|torchrun|python|run_one|eval_qwen|merge_lora' | grep -v grep || true
nvidia-smi
find /data/zsm/parameter-golf -maxdepth 6 -type f \( -name '*.log' -o -name '*results.json' -o -name 'trainer_state.json' -o -name 'train_results.json' -o -name 'summary.csv' \) 2>/dev/null | sort
```

Record only lightweight evidence locally.
