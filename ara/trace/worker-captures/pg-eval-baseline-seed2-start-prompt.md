# Baseline Seed2 OCR Eval Starter

Role:
eval-baseline-seed2-start

Goal:
Start only the baseline seed2 `textvqa_val_ocr` eval after `ocr16_seed1` aligned OCR eval completed, and leave durable startup evidence.

Environment block:
- Remote host: `smYuHangLab2`
- Remote worktree: `/home/zsm/pg-worktrees/pg-eval-baseline-ocr`
- Remote branch: `exp/eval-baseline-ocr`
- Run root: `/data/zsm/parameter-golf/runs/eval_baseline_seed2_textvqa_val_ocr`
- Python: `/home/zsm/parameter-golf/venv/bin/python`
- PYTHONPATH: `/home/zsm/pg-worktrees/pg-eval-baseline-ocr/lmms-eval`
- HF_HOME: `/data/zsm/hf_cache`
- HF_DATASETS_CACHE: `/data/zsm/hf_cache/datasets`
- HF_ENDPOINT: `https://hf-mirror.com`
- GPU: `CUDA_VISIBLE_DEVICES=2`
- Model: `/data/zsm/parameter-golf/outputs/textvqa_qwen3vl_lora_seed2/merged`
- Task: `textvqa_val_ocr`

Allowed actions:
- Read remote process, GPU, worktree, and run-root state.
- Verify `ocr16_seed1` aligned OCR eval is completed before starting seed2.
- Verify the worktree task config patch uses `dataset_path: lmms-lab/textvqa`.
- Create or overwrite only files under the assigned run root.
- Start one background eval process for baseline seed2.
- Capture startup evidence: PID, first log lines, GPU occupancy, command, env, git commit, git diff, status.

Forbidden actions:
- Do not run training.
- Do not start seed1 or seed3 baseline OCR evals.
- Do not use GPU 0, 1, or 3.
- Do not edit `/home/zsm/parameter-golf` or `/home/zsm/pg-worktrees/pg-harness`.
- Do not edit files outside `/home/zsm/pg-worktrees/pg-eval-baseline-ocr` and the assigned run root.
- Do not kill any process unless its PID is already written in `/data/zsm/parameter-golf/runs/eval_baseline_seed2_textvqa_val_ocr/pid.txt`.
- If any other PID appears to block GPU2, report it and stop without killing it.

Task:
1. Print worktree path, branch, commit, `git status --short`, and the `textvqa_val_ocr.yaml` dataset path.
2. Confirm `/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/status.json` has `"status": "completed"` and a result JSON.
3. Confirm GPU2 has no active compute process from the completed OCR16 eval PID.
4. Create the assigned run root with `logs/`.
5. Write:
   - `command.sh`
   - `env.txt`
   - `git_commit.txt`
   - `git_diff.patch`
   - `status.json` with status `starting`
6. Launch baseline seed2 OCR eval in the background with:

```bash
CUDA_VISIBLE_DEVICES=2 \
HF_HOME=/data/zsm/hf_cache \
HF_DATASETS_CACHE=/data/zsm/hf_cache/datasets \
HF_ENDPOINT=https://hf-mirror.com \
PYTHONPATH=/home/zsm/pg-worktrees/pg-eval-baseline-ocr/lmms-eval \
/home/zsm/parameter-golf/venv/bin/python -m lmms_eval \
  --model qwen3_vl \
  --model_args pretrained=/data/zsm/parameter-golf/outputs/textvqa_qwen3vl_lora_seed2/merged,attn_implementation=eager,device=cuda,max_pixels=200704,min_pixels=100352,use_cache=false,device_map=cuda \
  --tasks textvqa_val_ocr \
  --batch_size 1 \
  --output_path /data/zsm/parameter-golf/runs/eval_baseline_seed2_textvqa_val_ocr/eval
```

7. Write `pid.txt` at run-root top level and inside `logs/pid.txt`.
8. After 10-15 seconds, verify the PID is alive, log first lines exist, and GPU2 shows the PID.
9. Update `status.json` to `running` with PID, command, worktree, branch, commit, task, model, GPU, and process rule.

Required final line:
DONE eval-baseline-seed2-start

When done, print:
DONE eval-baseline-seed2-start
Remote worktree:
Branch/commit:
Run root:
PID:
GPU check:
First log lines:
Status JSON:
Problems/risks:
