# 2026-06-05 Literature Digest and OCR Layout Feasibility Dispatch

## User Direction

The user judged the `max_new_tokens=32` signal weak and asked to:

1. Update the exploration tree first.
2. Digest external literature into ARA.
3. Then dispatch worker tasks.

## ARA Literature Handling

The current lightweight ARA uses:

- `logic/` for current hypotheses and criteria.
- `trace/` for session notes and decisions.
- `evidence/` for result tables and pointers to raw artifacts.

The compiler skill's fuller schema supports `related_work.md` and source evidence tables. For this lightweight project artifact, external sources were archived as a compact evidence file:

```text
ara/evidence/literature/textvqa_external_sources.md
```

This records source URLs and project-specific implications without vendoring papers or long excerpts.

## External Sources Added

- TextVQA / LoRRA: `https://arxiv.org/abs/1904.08920`
- M4C: `https://arxiv.org/abs/1911.06258`
- TAP: `https://arxiv.org/abs/2012.04638`
- LaTr: `https://arxiv.org/abs/2112.12494`

Project interpretation:

- OCR-conditioned reading remains the strongest positive signal.
- Plain first-N OCR token concatenation is likely a weak approximation of stronger OCR-token / pointer / layout-aware methods.
- Generation length is a weak path after OCR16 `max_new_tokens=32` improved only `+0.00018` exact_match.
- Higher-probability next work should test layout-aware OCR serialization and OCR-benefit curriculum before more LoRA or max-token sweeps.

## Exploration Tree Update

`ara/trace/exploration_tree.yaml` was updated and YAML-validated:

- Added `literature_basis` under `q-portfolio-001`.
- Marked `exp-answer-style-controls` as `weakened` for the max-token subdirection.
- Added active gate `exp-ocr-layout-serialization-feasibility`.
- Added planned follow-ups:
  - `exp-ocr-layout-serialized-training`
  - `exp-ocr-win-curriculum`

Commit:

```text
0c12965 Update exploration tree with TextVQA literature
```

## Worker Dispatch

Created prompt:

```text
agent-prompts/ocr-layout-feasibility-worker.md
```

Dispatched worker:

```text
pg-ocr-layout-feasibility-worker
```

Worker goal:

- Create/reuse dedicated server worktree `/home/zsm/pg-worktrees/ocr_layout_feasibility`.
- Inspect cached TextVQA fields for OCR tokens, order, boxes, and image dimensions.
- Produce field inventory, 20-record serialization preview, and patch plan.
- Do not train, do not use GPUs.

## Open Monitoring Blocker

After dispatch, attempts to run further escalated `ssh` / `rmux capture` monitoring were rejected by the tool approval layer due a Codex usage limit until 12:27. No workaround was attempted.

Pending once monitoring is available:

- Check whether baseline seed3 `max_new_tokens=32` eval completed.
- Capture and archive `pg-ocr-layout-feasibility-worker` output.
- Update `ara/evidence/results.csv` if the baseline max32 eval produced a metric.
- Update exploration tree with the feasibility verdict.
- Commit and push pending prompt/session/worker artifacts.
