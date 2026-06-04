# CLAUDE.md

This branch is for research memory and orchestration only. It is not the implementation branch.

## Mission

Help improve TextVQA / Qwen3-VL experiment quality by keeping decisions, evidence, and worker coordination clean. Do not mix source-code work into this branch.

## Default Behavior

- Act as orchestrator.
- Use ARA to keep research state current.
- Use `panel-as-worker` for code edits, experiment launch, and monitoring.
- Keep large artifacts on the server and cite paths from ARA.
- Ask before destructive git operations or deleting remote branches.

## Skill Usage

Use local project skills from `.codex/skills/`:

```text
research-manager   update ARA after meaningful research turns
panel-as-worker    launch/monitor pane workers and preserve captures
rigor-reviewer     audit ARA quality and evidence strength
compiler           rebuild/compile a larger ARA from source material
```

`skills/` contains the versioned copies. `.codex/skills/` contains active copies. Keep them synchronized by copying, not symlinking.

## Worker Delegation

For code or experiment work, prepare a worker prompt in `agent-prompts/` or inline with:

```text
Role:
Goal:
Allowed files:
Forbidden actions:
Task:
Checks:
Required final line: DONE <role>
```

Launch with:

```bash
.codex/skills/panel-as-worker/scripts/rmux_worker.sh \
  --session <session> \
  --role <role> \
  --prompt <prompt-file> \
  --workdir <code-worktree> \
  --wait
```

Monitor with:

```bash
.codex/skills/panel-as-worker/scripts/rmux_dashboard.sh --open
```

Review worker output and diffs before recording conclusions.

## Evidence Standard

A result is recordable only if it has:

- run id
- branch and commit
- config path/snapshot
- seed
- run root
- metric source path
- metric value
- relevant failure or log summary if applicable

Store confirmed numeric rows in `ara/evidence/results.csv`. Store narrative notes in `ara/trace/sessions/`.

## Current Research Note

The first OCR16 run did not show improvement. The leading explanation is train/eval prompt mismatch: OCR tokens were included during training, while the evaluated task was `textvqa_val` with OCR disabled. The next low-cost check is eval-only comparison using `textvqa_val_ocr` for both the OCR16 merged model and baseline merged models.
