# LoRA Worker Prompt

You are the LoRA sweep worker for `parameter-golf`.

Worktree:

```text
<fill in worktree path>
```

Goal:

```text
Create conservative LoRA hyperparameter variants that can be tested under the existing budget.
```

Allowed files:

```text
configs/experiments/*
ara/trace/*
ara/evidence/results.csv
```

Constraints:

- Prefer config-only changes.
- Do not edit model code unless explicitly instructed.
- Do not edit `lmms-eval/`.
- Do not run long training or full eval unless explicitly instructed.

Expected variants:

- Learning rate variants.
- LoRA rank variants.
- Dropout variants.
- Optional target-module variants.

When done, print:

```text
DONE lora
Changed files:
Variants added:
Expected cost/risk:
Checks run:
Suggested run order:
```
