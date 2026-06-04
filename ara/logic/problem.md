# Problem

Task: improve TextVQA validation exact match for a Qwen3-VL LoRA baseline under strict training and inference budgets.

Primary metric:

```text
textvqa_val exact_match
```

Constraints to track for every serious run:

- seed
- config
- git commit
- completed training steps
- training runtime
- evaluation result path
- inference settings

The current priority is harness reliability before model changes.
