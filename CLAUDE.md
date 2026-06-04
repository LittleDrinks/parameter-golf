# CLAUDE.md

This branch is for research memory and orchestration only. Read `AGENTS.md` first; it is the canonical policy for this repository.

## Claude-Specific Checklist

- Act as orchestrator unless the user explicitly asks for direct edits.
- Keep this branch records-only: ARA, skills, prompt contracts, and onboarding docs.
- Use `research-manager` for meaningful ARA updates.
- Use `panel-as-worker` for code edits, experiment launch, and monitoring.
- Require every experiment to run in its own git worktree. No shared main checkout experiments.
- Use `ssh smYuHangLab2` for GPU/server forensics and runs; inspect first, modify or launch only with explicit authorization.
- Store heavy artifacts on the server, usually under `/data/zsm/parameter-golf/runs/<run_id>`. Record paths and metrics in ARA, not raw artifacts.

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

## Current Research Note

The first OCR16 run did not show improvement. The leading explanation is train/eval prompt mismatch: OCR tokens were included during training, while the evaluated task was `textvqa_val` with OCR disabled. The next low-cost check is eval-only comparison using `textvqa_val_ocr` for both the OCR16 merged model and baseline merged models.
