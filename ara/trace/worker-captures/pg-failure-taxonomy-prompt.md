Role:
failure-taxonomy

Goal:
Analyze the repaired 5000-sample OCR16 vs baseline seed2 artifact to classify where OCR16 wins/losses appear to come from. CPU-only; no eval/training.

Resource policy:
- smYuHangLab2 is a shared GPU server.
- This task must not use GPU/CUDA.
- Do not kill processes.

Allowed remote read-only files:
- `/data/zsm/parameter-golf/runs/stage3_textvqa_val_ocr_sample_evidence/samples_textvqa_val_ocr_ocr16_vs_baseline_seed2.jsonl`
- `/data/zsm/parameter-golf/runs/stage3_textvqa_val_ocr_sample_evidence/summary.json`

Allowed remote write path:
- `/data/zsm/parameter-golf/runs/analysis_failure_taxonomy`

Forbidden actions:
- Do not run training or eval.
- Do not edit git worktrees.
- Do not push branches.
- Do not delete files.

Task:
1. Read the JSONL and compute lightweight aggregate categories:
   - OCR16 better / baseline better / tied,
   - whether processed gold answer text appears in `ocr_tokens_used`,
   - whether OCR16 prediction appears in OCR tokens,
   - whether baseline prediction appears in OCR tokens,
   - simple question prefixes/types (`what`, `where`, `how many`, `who`, etc.),
   - answer length buckets.
2. Sample up to 20 OCR16 wins and 20 baseline wins into the note with question, gold, OCR tokens used, predictions, and score delta.
3. Estimate whether question-relevant OCR selection is plausibly worth training:
   - support it if OCR16 wins are concentrated in OCR-token/gold overlap cases,
   - weaken it if wins look answer-style dominated or if baseline losses are not OCR-token recoverable.
4. Write machine-readable `summary.json` and readable `failure_taxonomy.md` under `/data/zsm/parameter-golf/runs/analysis_failure_taxonomy`.
5. Include blockers and next smallest falsifying check.

Required final line:
DONE failure-taxonomy
