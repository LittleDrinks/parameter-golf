Role:
seed3-ocr-eval

Goal:
Run exactly one serial GPU eval for baseline seed3 on `textvqa_val_ocr`, using the existing dedicated remote worktree/branch from the seed robustness loop.

Resource policy:
- `smYuHangLab2` is a shared GPU server.
- Run at most this one GPU eval. Do not start training, seed1, or any parallel GPU job.
- Use GPU2 only if live preflight shows:
  - no `zsm` `lmms_eval`, `train_textvqa`, `accelerate`, `torchrun`, `run_one`, `eval_qwen`, or `merge_lora` process,
  - GPU2 `memory.used < 1000 MiB`.
- If the preflight fails, do not launch. Write `status.json` with `status: aborted_gpu_conflict`, capture the conflict, and finish.
- Never kill unrelated processes.

Remote paths:
- Dedicated worktree: `/home/zsm/pg-worktrees/pg-seed-robustness-ocr`
- Branch: `exp/seed-robustness-ocr`
- Expected commit: `d659cbdf335a66f43e835dd2c3899ff76edeb5d6`
- Run root: `/data/zsm/parameter-golf/runs/eval_baseline_seed3_textvqa_val_ocr`
- Model: `/data/zsm/parameter-golf/outputs/textvqa_qwen3vl_lora_seed3/merged`
- Task: `textvqa_val_ocr`

Allowed actions:
- Verify the dedicated worktree is clean and at the expected branch/commit.
- Write lightweight metadata and logs under the run root.
- Launch and monitor exactly one `lmms_eval` process for seed3.

Forbidden actions:
- Do not run training.
- Do not start seed1 or seed2.
- Do not edit any git worktree.
- Do not push branches.
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
  --model_args pretrained=/data/zsm/parameter-golf/outputs/textvqa_qwen3vl_lora_seed3/merged,attn_implementation=eager,device=cuda,max_pixels=200704,min_pixels=100352,use_cache=false,device_map=cuda \
  --tasks textvqa_val_ocr \
  --batch_size 1 \
  --output_path /data/zsm/parameter-golf/runs/eval_baseline_seed3_textvqa_val_ocr/eval
```

Task:
1. Run read-only preflight (`ps`, `nvidia-smi`) and record it.
2. Verify branch/commit/worktree cleanliness.
3. Create run-root metadata and launch the eval.
4. Monitor until the Python eval process exits.
5. Locate the result JSON under the run root.
6. Extract `results.textvqa_val_ocr["exact_match,none"]` and stderr if available.
7. Update `status.json` to `completed` with branch, commit, run root, result path, exact_match, stderr, start/end time. If no result JSON appears, set `failed` with log tail and process status.
8. Print a concise final report with:
   - branch and commit,
   - run root,
   - result JSON,
   - exact_match/stderr or failure reason,
   - GPU/process safety notes.

Required final line:
DONE seed3-ocr-eval
