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
