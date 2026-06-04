# Stage 3 Sample Evidence Worker

Role:
stage3-sample-evidence

Goal:
Create a durable per-sample evidence artifact for `textvqa_val_ocr` using completed OCR16 and baseline seed2 submissions plus TextVQA validation data.

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
- OCR16 submission: `/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/eval/submissions/textvqa_submission_2026-06-04-19-52-28.json`
- Baseline seed2 submission: `/data/zsm/parameter-golf/runs/eval_baseline_seed2_textvqa_val_ocr/eval/submissions/textvqa_submission_2026-06-04-20-16-54.json`
- Output JSONL: `/data/zsm/parameter-golf/runs/stage3_textvqa_val_ocr_sample_evidence/samples_textvqa_val_ocr_ocr16_vs_baseline_seed2.jsonl`

Allowed actions:
- Read the remote worktree, task config, completed result JSONs, completed submission JSONs, and TextVQA validation dataset.
- Create or overwrite files only under the assigned run root.
- Write a short Python helper under the assigned run root if useful.
- Write durable metadata files: `command.sh`, `env.txt`, `git_commit.txt`, `git_diff.patch`, `pid.txt`, `logs/*.log`, `status.json`.

Forbidden actions:
- Do not run training or eval.
- Do not use GPU or CUDA.
- Do not edit `/home/zsm/parameter-golf`, `/home/zsm/pg-worktrees/pg-harness`, or the eval worktree.
- Do not write heavy artifacts into any git tree.
- Do not kill any process. If there is process contention, report it only.

Task:
1. Verify the OCR16 and baseline seed2 result JSONs exist and both are completed.
2. Create the assigned run root with `logs/`.
3. Write metadata files before running the helper:
   - `command.sh`
   - `env.txt`
   - `git_commit.txt`
   - `git_diff.patch`
   - `pid.txt`
   - `status.json` with status `running`
4. Build a JSONL artifact with at least these fields per record:
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
5. Reconstruct the prompt using the same TextVQA OCR task behavior:
   - question capitalized
   - `Reference OCR token: ...` with the first 16 OCR tokens
   - the task post prompt from `textvqa_val_ocr.yaml`
6. Save all 5000 validation examples if feasible. If dataset access fails, save a smaller artifact only if it still includes the required fields and explain the limitation.
7. Write a `summary.json` with counts:
   - total samples
   - OCR16 better / baseline better / tied counts
   - OCR16 exact-match mean
   - baseline seed2 exact-match mean
   - output JSONL path
8. Update `status.json` to `completed` with artifact paths, counts, and any problems.

Required final line:
DONE stage3-sample-evidence

When done, print:
DONE stage3-sample-evidence
Run root:
Output JSONL:
Summary JSON:
Total samples:
OCR16 better:
Baseline better:
Tied:
Problems/risks:
