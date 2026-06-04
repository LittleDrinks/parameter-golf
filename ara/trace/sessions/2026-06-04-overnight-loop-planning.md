# 2026-06-04 overnight loop planning

## User constraints recorded

- Do not voluntarily stop before `2026-06-05 08:00 Asia/Shanghai` once the overnight loop is approved.
- Keep seeking optimization directions until the hard stop; if one direction fails, archive it and try another.
- Preserve main Codex session budget by delegating exploratory work to Claude/Kimi workers.
- Start the local environment worker now.
- Default GPU usage is one card; maximum concurrent GPU jobs is two cards.
- Launch GPU work only when `memory.used < 1000 MiB`.
- `smYuHangLab2` is a shared public server. Do not kill unrelated processes; workers should only stop their own run-root PID.
- Lack of GitHub credentials on `smYuHangLab2` is correct. Commit on server branches; push from local/VS Code credentials or ask the user.

## Codex review notes

Official Codex manual was refreshed at:

```text
/tmp/openai-docs-cache/codex-manual.md
```

Relevant findings:

- Local Codex `/review` can review uncommitted changes, branch diffs against a base branch, or recent-turn changes, and can use custom review instructions.
- Codex app review pane reflects git state, including user changes and Codex changes.
- GitHub Codex code review is a PR integration. It requires Codex Cloud/code-review setup and is triggered by `@codex review` on a pull request.
- A bare local/server worktree cannot receive GitHub PR review directly. To use GitHub review, create/push a branch and open a PR.
- Auto-review for sandbox approvals is separate from code review; it reviews boundary-crossing approval requests and can consume additional Codex usage.
- The manual documents Code Review as a separate analytics/product surface, but local `/review` is part of local Codex usage. Do not assume a configured goal bypasses rate limits.

## Env worker launched

```text
session: pg-local-env-worker
role: local-env-worker
worktree: /tmp/pg-worktrees/local-env-gate
branch: exp/local-env-gate
base: origin/main
commit: 101959c882dd9d05be79668f80456da038c01c77
prompt: agent-prompts/local-env-worker.md
capture: ara/trace/worker-captures/pg-local-env-worker-latest.txt
```

Worker scope:

- CPU-only local dependency/data-cache setup.
- No GPU, no training, no server job launch, no push.
- Report expected at `/tmp/pg-worktrees/local-env-gate/agent-runs/local-env-worker-report.md`.

## Planned overnight queue

1. Review phase: eval harness reviewer and train pipeline reviewer.
2. Local gate: env worker reports whether CPU-only smoke tests are practical.
3. Full training directions: answer-style/prompt-template, OCR dropout or robustness, LoRA hyperparameter sweep.
4. If time remains: second seed or matched eval for the best candidate.

## Status

No overnight goal has been set in Codex yet. This note records the plan and durable rules for user review.
