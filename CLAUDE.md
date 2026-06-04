# CLAUDE.md

This repo is a small TextVQA/Qwen3-VL experiment project. Treat it as a constrained research codebase, not a general refactor target.

## Current Goal

Improve `textvqa_val` exact match while respecting the project constraints:

- Training must fit the stated time budget.
- Test-time latency/FLOPs should stay within the base-model budget.
- Final claims need evidence over seeds, not one-off terminal output.

The immediate engineering priority is harness work: make runs reproducible and collect evidence. Do not change model behavior unless the task explicitly says so.

## Repo Map

- `configs/vlm_textvqa_lora.yaml`: baseline training config.
- `prepare_textvqa.py`: prepares TextVQA prompts and cached dataset.
- `train_textvqa_qwen3vl.py`: LoRA training script.
- `merge_lora.py`: merges adapter into a standalone model.
- `run_prepare.sh`, `run_train.sh`, `run_merge_lora.sh`, `eval_qwen.sh`: public entrypoints.
- `lmms-eval/`: vendored evaluation dependency. Avoid editing unless the task explicitly targets eval internals.
- `ara/`: lightweight research memory and evidence ledger.
- `configs/experiments/`: config variants. Parameter-only experiments belong here, not in separate branches.
- `agent-prompts/`: reusable prompts/contracts for worker agents.

## Hard Rules

- Keep edits narrowly scoped to the assigned task.
- Do not touch `lmms-eval/` unless explicitly instructed.
- Do not start long training or full evaluation unless explicitly instructed.
- Do not overwrite or delete `outputs/`, `results/`, or `data/`.
- Do not commit large artifacts, model weights, prepared datasets, logs, or submissions.
- Preserve compatibility with the public entrypoints unless the task says otherwise.
- If a run result is mentioned, include the exact command, seed, config, commit, output path, and metric source.

## Worker Contract

When assigned a task, start by restating:

- Goal
- Allowed files
- Files you expect to inspect
- Whether training/eval is allowed

End with:

- Changed files
- Behavior changes, if any
- Checks run
- Risks or assumptions
- Suggested next step

If you need to modify files outside the allowed set, stop and ask.

## Harness Direction

Preferred first changes:

- Save training metrics from `trainer.train()` into the output directory.
- Support explicit `RUN_ID`, `OUTPUT_DIR`, `PREPARED_DATA_DIR`, and `RESULTS_DIR`.
- Add a collection script that extracts `exact_match`, training runtime, completed steps, commit, config, and result path.
- Keep real run artifacts under `/data/...` on the server; keep only lightweight summaries in git.

## Experiment Hygiene

- Use git branches or worktrees for conflicting code directions.
- Use YAML files under `configs/experiments/` for pure parameter variants.
- Record real results in `ara/evidence/results.csv`.
- Record decisions, failed ideas, and pivots in `ara/trace/`.
- Do not turn an unverified idea into a claim.
