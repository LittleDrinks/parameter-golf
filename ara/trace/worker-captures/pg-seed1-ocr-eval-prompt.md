Role:
seed1-ocr-eval

Goal:
Run exactly one serial GPU eval for baseline seed1 on `textvqa_val_ocr`, using a dedicated remote worktree/branch and durable run-root metadata.

Resource policy:
- `smYuHangLab2` is a shared GPU server.
- Run at most this one GPU eval. Do not start seed3, training, or any parallel GPU job.
- Use GPU2 only if live preflight shows:
  - no `zsm` `lmms_eval`, `train_textvqa`, `accelerate`, `torchrun`, `run_one`, `eval_qwen`, or `merge_lora` process,
  - GPU2 `memory.used < 1000 MiB`.
- If the preflight fails, do not launch. Write `status.json` with `status: aborted_gpu_conflict`, capture the conflict, and finish.
- Never kill any process except a PID written by this worker to this run root, and only if cleaning up its own failed launcher.

Remote paths:
- Main repo: `/home/zsm/parameter-golf`
- Dedicated worktree: `/home/zsm/pg-worktrees/pg-seed-robustness-ocr`
- Branch: `exp/seed-robustness-ocr`
- Base commit: `101959c882dd9d05be79668f80456da038c01c77`
- Run root: `/data/zsm/parameter-golf/runs/eval_baseline_seed1_textvqa_val_ocr`
- Model: `/data/zsm/parameter-golf/outputs/textvqa_qwen3vl_lora_seed1/merged`
- Task: `textvqa_val_ocr`

Allowed actions:
- Create the dedicated remote worktree if it does not already exist.
- Patch only `/home/zsm/pg-worktrees/pg-seed-robustness-ocr/lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml` so `dataset_path: lmms-lab/textvqa`.
- Commit that patch on branch `exp/seed-robustness-ocr` if not already committed.
- Push `exp/seed-robustness-ocr` to `origin`.
- Write lightweight metadata and logs under the run root.
- Launch and monitor exactly one `lmms_eval` process for seed1.

Forbidden actions:
- Do not run training.
- Do not start seed3.
- Do not edit `/home/zsm/parameter-golf` main worktree.
- Do not write artifacts into any git tree except the one config patch/commit in the dedicated worktree.
- Do not delete old run directories.
- Do not kill unrelated processes.

Required run-root files before launch:
- `command.sh`
- `env.txt`
- `git_commit.txt`
- `git_diff.patch`
- `status.json`
- `logs/eval.log`

Eval command:
```bash
#!/usr/bin/env bash
set -euo pipefail
export CUDA_VISIBLE_DEVICES=2
export HF_HOME=/data/zsm/hf_cache
export HF_DATASETS_CACHE=/data/zsm/hf_cache/datasets
export HF_ENDPOINT=https://hf-mirror.com
export PYTHONPATH=/home/zsm/pg-worktrees/pg-seed-robustness-ocr/lmms-eval
cd /home/zsm/pg-worktrees/pg-seed-robustness-ocr
exec /home/zsm/parameter-golf/venv/bin/python -m lmms_eval \
  --model qwen3_vl \
  --model_args pretrained=/data/zsm/parameter-golf/outputs/textvqa_qwen3vl_lora_seed1/merged,attn_implementation=eager,device=cuda,max_pixels=200704,min_pixels=100352,use_cache=false,device_map=cuda \
  --tasks textvqa_val_ocr \
  --batch_size 1 \
  --output_path /data/zsm/parameter-golf/runs/eval_baseline_seed1_textvqa_val_ocr/eval
```

Task:
1. Run read-only preflight (`ps`, `nvidia-smi`) and record it.
2. Create or verify the dedicated worktree/branch.
3. Apply/commit/push the dataset path patch.
4. Create run-root metadata and launch the eval.
5. Monitor until the Python eval process exits.
6. Locate the result JSON under the run root.
7. Extract `results.textvqa_val_ocr["exact_match,none"]` and stderr if available.
8. Update `status.json` to `completed` with branch, commit, run root, result path, exact_match, stderr, start/end time. If no result JSON appears, set `failed` with log tail and process status.
9. Print a concise final report with:
   - branch and commit,
   - whether branch was pushed,
   - run root,
   - result JSON,
   - exact_match/stderr or failure reason,
   - GPU/process safety notes.

Required final line:
DONE seed1-ocr-eval
