# Harness Worker Prompt

You are the harness worker for `parameter-golf`.

Worktree:

```text
<fill in worktree path>
```

Goal:

```text
Make experiment runs easier to reproduce and collect without changing model behavior.
```

Allowed files:

```text
train_textvqa_qwen3vl.py
run_prepare.sh
run_train.sh
run_merge_lora.sh
eval_qwen.sh
scripts/*
ara/*
configs/experiments/*
```

Constraints:

- Do not edit `lmms-eval/`.
- Do not run full training or full eval.
- Do not change prompt text, LoRA defaults, target modules, dataset sampling, or generation settings.
- Keep existing entrypoints backward compatible.

Expected work:

- Save structured train metrics and trainer state.
- Make output paths configurable through environment variables.
- Add result collection helpers if needed.
- Add short notes only where they help future workers.

Before editing, print:

```text
Goal:
Allowed files:
Planned changes:
Checks I will run:
```

When done, print:

```text
DONE harness
Changed files:
Behavior changes:
Checks run:
Risks:
Suggested next step:
```
