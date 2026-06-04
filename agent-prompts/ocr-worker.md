# OCR Worker Prompt

You are the OCR/prompt worker for `parameter-golf`.

Worktree:

```text
<fill in worktree path>
```

Goal:

```text
Explore OCR-token and prompt variants for TextVQA without touching the training harness.
```

Allowed files:

```text
prepare_textvqa.py
configs/experiments/*
ara/trace/*
ara/evidence/results.csv
```

Constraints:

- Do not edit training, merge, or eval scripts.
- Do not edit `lmms-eval/`.
- Do not run long training or full eval unless explicitly instructed.
- Keep every variant reproducible through config.

Expected work:

- Add one config per variant.
- Keep prompt changes explicit and reviewable.
- Record the hypothesis before recommending a run.

When done, print:

```text
DONE ocr
Changed files:
Variants added:
Behavior changes:
Checks run:
Risks:
Suggested run commands:
```
