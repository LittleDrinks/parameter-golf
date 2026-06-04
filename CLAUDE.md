# CLAUDE.md

This branch is for research memory and orchestration only. Read `AGENTS.md` first; it is the canonical policy for this repository.

## Claude-Specific Checklist

- Act as orchestrator unless the user explicitly asks for direct edits.
- Keep this branch records-only: ARA, skills, prompt contracts, and onboarding docs.
- Use `research-manager` for meaningful ARA updates.
- Use `panel-as-worker` for code edits, experiment launch, and monitoring.
- Prefer worker delegation for exploratory coding, environment setup, review, and long loops to preserve the main Codex 5h session budget.
- Require every experiment to run in its own git worktree. No shared main checkout experiments.
- Use `ssh smYuHangLab2` for GPU/server forensics and runs; inspect first, modify or launch only with explicit authorization.
- Store heavy artifacts on the server, usually under `/data/zsm/parameter-golf/runs/<run_id>`. Record paths and metrics in ARA, not raw artifacts.
- Treat lack of GitHub credentials on `smYuHangLab2` as correct. Commit on server branches, then push from the local/VS Code credential environment or ask the user.
- Before trusting changed training/eval code, run a review step: local `/review` or reviewer worker for worktree diffs; GitHub `@codex review` only after a PR exists and code review is enabled.
- CPU-only gates are allowed for smoke testing, but only full train + matched eval can prove a training idea.

## Shared GPU Policy

- Default to one GPU job.
- Use at most two GPU jobs at once.
- Poll for GPUs with `memory.used < 1000 MiB` before launch.
- Do not kill unrelated processes on the shared server.
- Workers may only stop their own process by reading the PID from that run root's `pid.txt`.
- Archive pane captures and run logs before closing stale rmux windows.

## Minimal Worker Pattern

Create or reuse a prompt from `agent-prompts/`, then launch against the experiment worktree:

```bash
.codex/skills/panel-as-worker/scripts/rmux_worker.sh \
  --session <session> \
  --role <role> \
  --prompt <prompt-file> \
  --workdir <experiment-worktree> \
  --wait
```

Worker prompts must include allowed files, forbidden actions, checks, and final `DONE <role>`. Review worker output and diffs before updating ARA claims.

## Current Research State

Aligned OCR eval has been completed:

```text
OCR16 seed1 textvqa_val_ocr    = 0.7262000000000036
baseline seed1 textvqa_val_ocr = 0.7134200000000036
baseline seed2 textvqa_val_ocr = 0.7133600000000039
baseline seed3 textvqa_val_ocr = 0.7154200000000039
```

OCR16 remains about `+0.01213` over the baseline mean and `+0.01078` over the best baseline in aligned OCR eval. However, this is still not enough proof for new training directions beyond OCR; future overnight work should actively explore multiple non-OCR directions with full training and matched eval.

Approved planning assumptions for the next overnight loop:

```text
Hard stop: 2026-06-05 08:00 Asia/Shanghai
Do not voluntarily stop before the hard stop.
Default GPU concurrency: 1
Maximum GPU concurrency: 2
Launch condition: memory.used < 1000 MiB
```

Initial queue:

```text
1. local-env-worker: CPU-only local environment/data-cache setup and smoke gate.
2. reviewer workers: review eval harness and train pipeline changes before trusting results.
3. full training directions: answer-style/prompt-template, OCR dropout or robustness, LoRA hyperparameter sweep.
4. follow-up: second seed or matched eval for the best candidate if time remains.
```
