# 2026-06-04 Project skills migration and OCR16 analysis

## Infra actions

- Confirmed the ARA skills requested earlier were installed globally under `/home/q2635/.codex/skills`:
  - `research-manager`
  - `rigor-reviewer`
  - `compiler`
- Copied those skills into project-level source folders under `skills/`.
- Created a new project skill `skills/panel-as-worker` using the skill-creator initializer.
- Migrated panel/rmux scripts from top-level `scripts/` into `skills/panel-as-worker/scripts/`:
  - `rmux_worker.sh`
  - `rmux_dashboard.sh`
  - `rmux_dashboard.py`
- Kept `agent-prompts/` as prompt-contract source material for future skill improvements.
- Validated all four project skills with `quick_validate.py`.

## Project-level skill path note

The canonical in-repo `.codex/skills` path is not writable in this session because `.codex/` is mounted read-only by the Codex harness. The repository-level skill source of truth is therefore:

```text
skills/
```

If a future environment supports writable `.codex/`, copy or symlink these skill folders into `.codex/skills`.

## OCR16 no-improvement analysis

Observed result:

```text
ocr16_seed1 exact_match = 0.7076800000000036
baseline seed1 exact_match = 0.7085800000000037
baseline mean over seeds 1-3 = 0.7093400000000037
baseline sample stdev = 0.001619753067600187
```

Delta:

```text
ocr16_seed1 - baseline_seed1 = -0.0009000000000000119
ocr16_seed1 - baseline_mean = -0.0016600000000001058
```

Primary diagnosis:

- `ocr16.yaml` trains with OCR tokens in the user prompt via `prepare_textvqa.py`:
  - `Reference OCR token: ...`
  - `Answer the question using a single word or phrase.`
- The run evaluated with `TASK=textvqa_val`, whose task config has `ocr: false` and qwen-specific prompt `post_prompt: " Answer:"`.
- `lmms-eval` already contains `textvqa_val_ocr`, with `ocr: true`, `ocr_max_tokens: 16`, and `max_new_tokens: 16`.
- Therefore `ocr16_seed1` likely trained on OCR-conditioned prompts but was evaluated on non-OCR prompts. This train/eval prompt mismatch can erase or reverse any benefit of OCR-token conditioning.

Secondary diagnoses:

- The difference is small relative to eval stderr (~0.0061) and baseline seed variability; it is not strong evidence of regression.
- OCR token ordering may include noisy or irrelevant tokens; the first 16 tokens are not necessarily question-relevant.
- TextVQA exact-match is sensitive to answer style. Training prompt uses a full sentence; qwen-specific eval for `textvqa_val` uses ` Answer:` unless OCR task is selected.
- 1024 steps over ~0.24 epoch may be too short for a new OCR-conditioned behavior to reliably emerge, especially if evaluation removes the OCR input.
- Loss is noisy but aggregate trend is downward; optimization failure is not the main explanation.

## Proposed low-cost next checks

1. Eval-only aligned check: run existing `ocr16_seed1` merged model on `TASK=textvqa_val_ocr` without retraining.
2. Fair baseline check: run baseline merged models on `TASK=textvqa_val_ocr` to see whether OCR in eval helps the base/baseline models without OCR training.
3. Prompt alignment check: make train prompt match the eval OCR task exactly, or make eval use the same post-prompt as training.
4. Answer-style check: compare `max_new_tokens=16` and explicit short-answer prompting across baseline and OCR variants.

## Candidate future directions

- Retrieval/filtering: include OCR tokens most relevant to the question rather than first N OCR tokens.
- OCR dropout: during OCR-token training, randomly drop OCR tokens some fraction of the time to avoid eval brittleness.
- Short-answer consistency: train and eval with the same post-prompt and generation length.
- Error analysis: inspect cases where baseline fails and OCR tokens contain the gold answer; prioritize variants based on recoverable examples.
- Conservative LoRA sweeps: try lower LR or constant schedule only after prompt/eval alignment is fixed.
