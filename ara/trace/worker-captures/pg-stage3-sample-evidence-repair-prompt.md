# Stage 3 Sample Evidence Repair Worker

Role:
stage3-sample-evidence-repair

Goal:
Repair the existing Stage 3 per-sample evidence artifact so prompt snapshots match the actual `textvqa_val_ocr` task prompt and per-sample scores match lmms-eval TextVQA scoring semantics.

Environment block:
- Remote host: `smYuHangLab2`
- Remote worktree: `/home/zsm/pg-worktrees/pg-eval-baseline-ocr`
- Remote branch: `exp/eval-baseline-ocr`
- Run root: `/data/zsm/parameter-golf/runs/stage3_textvqa_val_ocr_sample_evidence`
- Python: `/home/zsm/parameter-golf/venv/bin/python`
- PYTHONPATH: `/home/zsm/pg-worktrees/pg-eval-baseline-ocr/lmms-eval`
- HF_HOME: `/data/zsm/hf_cache`
- HF_DATASETS_CACHE: `/data/zsm/hf_cache/datasets`
- HF_ENDPOINT: `https://hf-mirror.com`
- GPU: none; do not use CUDA
- Dataset: `lmms-lab/textvqa`, split `validation`
- OCR task config: `/home/zsm/pg-worktrees/pg-eval-baseline-ocr/lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml`
- TextVQA utils: `/home/zsm/pg-worktrees/pg-eval-baseline-ocr/lmms-eval/lmms_eval/tasks/textvqa/utils.py`
- OCR16 result JSON: `/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/eval/outputs__merged/20260604_193246_results.json`
- Baseline seed2 result JSON: `/data/zsm/parameter-golf/runs/eval_baseline_seed2_textvqa_val_ocr/eval/textvqa_qwen3vl_lora_seed2__merged/20260604_195729_results.json`
- OCR16 submission: `/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/eval/submissions/textvqa_submission_2026-06-04-19-52-28.json`
- Baseline seed2 submission: `/data/zsm/parameter-golf/runs/eval_baseline_seed2_textvqa_val_ocr/eval/submissions/textvqa_submission_2026-06-04-20-16-54.json`
- Output JSONL: `/data/zsm/parameter-golf/runs/stage3_textvqa_val_ocr_sample_evidence/samples_textvqa_val_ocr_ocr16_vs_baseline_seed2.jsonl`

Allowed actions:
- Read the remote worktree, task config, TextVQA utils, completed result JSONs, completed submission JSONs, and TextVQA validation dataset.
- Create or overwrite files only under the assigned run root.
- Write a short Python helper under the assigned run root if useful.
- Back up the current JSONL/summary/status under the assigned run root before overwriting.
- Write durable metadata files: `command.sh`, `env.txt`, `git_commit.txt`, `git_diff.patch`, `pid.txt`, `logs/*.log`, `status.json`.

Forbidden actions:
- Do not run training or eval.
- Do not use GPU or CUDA.
- Do not edit `/home/zsm/parameter-golf`, `/home/zsm/pg-worktrees/pg-harness`, or any remote git worktree.
- Do not write artifacts into any git tree.
- Do not kill any process. If there is process contention, report it only.

Task:
1. Verify both result JSONs exist and report these lmms-eval aggregates:
   - OCR16 `results.textvqa_val_ocr["exact_match,none"]`
   - baseline seed2 `results.textvqa_val_ocr["exact_match,none"]`
2. Verify current prompt behavior from `utils.py`:
   - `doc["question"].capitalize()`
   - OCR reference line: `Reference OCR token: {', '.join(ocr_tokens)}`
   - first 16 OCR tokens from the task config
   - task post prompt from `textvqa_val_ocr.yaml`
3. Rebuild the 5000-record JSONL at the output path. Required fields per record:
   - `question_id`
   - `question`
   - `gold_answers`
   - `ocr_tokens`
   - `ocr_tokens_used`
   - `prompt_snapshot`
   - `ocr16_prediction`
   - `baseline_seed2_prediction`
   - `ocr16_exact_match`
   - `baseline_seed2_exact_match`
   - `delta`
4. Use lmms-eval TextVQA scoring semantics for `ocr16_exact_match`, `baseline_seed2_exact_match`, and `delta`, not boolean normalized string equality:
   - import `EvalAIAnswerProcessor` from `lmms_eval.tasks._task_utils.vqa_eval_metric`
   - process each prediction with the processor
   - process each gold answer with the processor
   - for each gold answer index, count matching processed answers among the other 9 gold answers
   - per-answer accuracy is `min(1, count / 3)`
   - per-sample score is the mean over all gold answer indices
5. `prompt_snapshot` must exactly reconstruct the task prompt with comma-separated OCR tokens, for example:
   - `What is the brand of this camera?\nReference OCR token: DAKOTA, DIGITAL, Single-Use, Camera, Pire, digitat\nAnswer the question using a single word or phrase.`
6. Add optional compatibility fields if useful, such as `ocr16_boolean_match` and `baseline_seed2_boolean_match`, but do not replace the required fields.
7. Write `summary.json` with:
   - total samples
   - OCR16 better / baseline better / tied counts using fractional TextVQA scores
   - OCR16 exact-match mean
   - baseline seed2 exact-match mean
   - expected OCR16 aggregate from result JSON
   - expected baseline aggregate from result JSON
   - absolute mean differences versus result JSONs
   - output JSONL path
   - problems
8. Update `status.json` to `completed` only if:
   - there are 5000 records
   - prompt snapshots use comma-separated OCR tokens
   - summary means match result JSON aggregates within `1e-12`
   - otherwise set status to `completed_with_caveat` or `failed` and explain.

Required final line:
DONE stage3-sample-evidence-repair

When done, print:
DONE stage3-sample-evidence-repair
Run root:
Output JSONL:
Summary JSON:
Total samples:
OCR16 better:
Baseline better:
Tied:
OCR16 mean:
Baseline mean:
Aggregate match:
Problems/risks:
