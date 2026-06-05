# answer-style-max32-worker Report

## Selected GPU
- **GPU**: 2
- **Rationale**: User-approved exception. At launch time, no GPU had `memory.used < 1000 MiB`:
  - GPU 0: 47,950 MiB used (nearly full, excluded)
  - GPU 1: 17,855 MiB used
  - GPU 2: 17,829 MiB used, `GPU-Util=0%` in repeated checks
  - GPU 3: 17,837 MiB used, `GPU-Util=0%` in repeated checks
- GPU 2 was preferred per task instructions (near-idle, ~30 GB free VRAM out of 48 GB A6000).

## Existing GPU Processes Observed
At launch (2026-06-05 10:14 CST):
| GPU | PID | User | Process | Used Memory |
|-----|-----|------|---------|-------------|
| 0 | 514685 | wjh | python /home/wjh/project/wt | 47,950 MiB |
| 1 | 3774180 | wjh | python /home/wjh/project/wt | 17,855 MiB |
| 2 | 2103741 | wjh | python /home/wjh/project/wt | 17,829 MiB |
| 3 | 3828320 | wjh | python /home/wjh/project/wt | 17,837 MiB |

All compute processes belonged to user `wjh`; no zsm-owned processes were interfered with.

## Worktree
- **Path**: `/home/zsm/pg-worktrees/answer_style_max32`
- **Branch**: `exp/answer-style-max32`
- **Base commit**: `101959c882dd9d05be79668f80456da038c01c77`
- **HEAD after repair**: `93f7af7bf0df4eaeb2d5dc86d13dfa4c6833005f`
- **Task-YAML repair**: `lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml`
  - Changed `dataset_path` from `/storage/data/shiyd2023/datasets/textvqa` to `lmms-lab/textvqa`
  - Committed locally on server as `Repair textvqa_val_ocr dataset_path for server eval`

## Run Root
`/data/zsm/parameter-golf/runs/answer_style_ocr16_max32_20260605_101647`

Evidence files present:
- `command.sh`
- `env.txt`
- `git_commit.txt`
- `git_diff.patch`
- `pid.txt`
- `launcher_pid.txt`
- `logs/eval.stdout.log`
- `logs/eval.stderr.log`
- `status.json`
- `summary.csv`

## Command Summary
```bash
cd /home/zsm/pg-worktrees/answer_style_max32
source /home/zsm/parameter-golf/venv/bin/activate
export PYTHONPATH=/home/zsm/pg-worktrees/answer_style_max32/lmms-eval:${PYTHONPATH:-}
export CUDA_VISIBLE_DEVICES=2
export HF_HOME=/data/zsm/hf_cache
export HF_DATASETS_CACHE=/data/zsm/hf_cache/datasets
export HF_ENDPOINT=https://hf-mirror.com
python -m lmms_eval \
  --model qwen3_vl \
  --model_args pretrained=/data/zsm/parameter-golf/runs/ocr16_seed1/outputs/merged,attn_implementation=eager,device=cuda,max_pixels=200704,min_pixels=100352,use_cache=false,device_map=cuda \
  --tasks textvqa_val_ocr \
  --gen_kwargs max_new_tokens=32 \
  --batch_size 1 \
  --output_path <run_root>/eval
```

Key difference from baseline eval: `--gen_kwargs max_new_tokens=32` (baseline uses `max_new_tokens=16`).

## PID and Process Ownership
- **PID**: 4013475
- **Owner**: zsm
- **Launcher PID**: recorded in `launcher_pid.txt`
- **Status**: exited cleanly after completing all 5000 samples

## Status
**COMPLETED**

- Started: 2026-06-05 10:17:08 CST
- Finished: ~2026-06-05 10:33:00 CST
- Duration: ~16 minutes
- Postprocessing: 5000/5000 samples
- No OOM, no CUDA collision, no errors in stderr beyond expected warnings (`nframes` ignored, generation flags not valid).

## Result
- **Result file**: `/data/zsm/parameter-golf/runs/answer_style_ocr16_max32_20260605_101647/eval/outputs__merged/20260605_101712_results.json`
- **Metric**: `textvqa_val_ocr exact_match` = **0.7263800000000038**
- **Stderr**: 0.005937294789201627

## Comparison
| Config | exact_match |
|--------|-------------|
| OCR16 seed1 `max_new_tokens=16` (baseline aligned eval) | 0.72620 |
| OCR16 seed1 `max_new_tokens=32` (this run) | **0.72638** |

Difference: +0.00018 (effectively negligible). This suggests `max_new_tokens=16` does **not** truncate useful answers for this model/dataset combination.

## Blocker/Failure
None. Eval completed successfully.

---
DONE answer-style-max32-worker
