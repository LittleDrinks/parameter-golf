# LoRA Eval Retry Worker Report

**Role:** `lora-eval-retry-worker`
**Server:** `smYuHangLab2`
**Timestamp:** 2026-06-05 09:42 CST to 2026-06-05 10:03 CST

---

## Selected GPU and Exception Rationale

- **Selected GPU:** `2`
- **Rationale:** At launch time (09:42 CST), GPU 2 showed `GPU-Util = 0%` and `memory.used = 17829 MiB` (~30 GB remaining on NVIDIA RTX A6000). This GPU was clearly idle despite having some resident memory. Under the user-approved GPU scheduling exception, GPU 2 was preferred because its utilization was near-idle and remaining memory was plausibly sufficient for a single-batch eval.

## Existing GPU Processes Observed

At 09:42 CST:

| GPU | PID | Process | Used Memory (MiB) | Utilization |
|-----|-----|---------|-------------------|-------------|
| 0 | 514685 | python | 47900 | 0% |
| 1 | 1441238 | python | 48314 | 100% |
| 2 | 2103741 | python | 17794 | 0% |
| 3 | 3828320 | python | 17802 | 0% |

The `ps -fu zsm` output did not list these python PIDs, indicating they belong to another user. No unrelated zsm-owned GPU processes were present.

## Retry Root

```
/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_worker_retry_20260605_094237
```

## Command Summary

```bash
cd /home/zsm/pg-worktrees/lora_lr2e5_seed1
source /home/zsm/parameter-golf/venv/bin/activate
export PYTHONPATH=/home/zsm/pg-worktrees/lora_lr2e5_seed1/lmms-eval:${PYTHONPATH:-}
export CUDA_VISIBLE_DEVICES=2
export HF_HOME=/data/zsm/hf_cache
export HF_DATASETS_CACHE=/data/zsm/hf_cache/datasets
export HF_ENDPOINT=https://hf-mirror.com
python -m lmms_eval \
  --model qwen3_vl \
  --model_args pretrained=/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/outputs/textvqa_qwen3vl_lora_lr2e5_seed1/merged,attn_implementation=eager,device=cuda,max_pixels=200704,min_pixels=100352,use_cache=false,device_map=cuda \
  --tasks textvqa_val_ocr \
  --batch_size 1 \
  --output_path /data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_worker_retry_20260605_094237/eval
```

## Git Verification

- **Branch:** `exp/lora-lr2e5-seed1`
- **Commit:** `9b2b51d6289cd78f10ccb26da25a146134b31bdb` (matches required)
- **Dataset path in worktree YAML:** `lmms-lab/textvqa` (line 3)

## PID and Process Ownership

- **Eval PID:** `2066518`
- **Launcher PID:** recorded in `launcher_pid.txt`
- **Owner:** `zsm`
- **Exit status:** completed normally (no OOM, no collision, no kill)

## `lmms_eval` Path Verification

`PYTHONPATH` was explicitly set to `/home/zsm/pg-worktrees/lora_lr2e5_seed1/lmms-eval`, ensuring the worktree's repaired `lmms-eval` was used rather than `/home/zsm/parameter-golf/lmms-eval`.

## Status

**COMPLETED**

## Result Path and Metric

- **Result file:**
  ```
  /data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_worker_retry_20260605_094237/eval/textvqa_qwen3vl_lora_lr2e5_seed1__merged/20260605_094300_results.json
  ```
- **Metric:** `textvqa_val_ocr` `exact_match` = **0.7148200000000041**
- **Stderr:** 0.006025988385916861

## Stderr Review

No errors, exceptions, OOM, or CUDA failures were found in `eval.stderr.log`. Warnings about ignored keyword arguments (`nframes`, `temperature`, `top_p`, `top_k`) are expected and non-blocking.

## Output Files in Retry Root

| File | Status |
|------|--------|
| `command.sh` | present |
| `env.txt` | present |
| `git_commit.txt` | present |
| `git_diff.patch` | present |
| `pid.txt` | present |
| `launcher_pid.txt` | present |
| `logs/eval.stdout.log` | present |
| `logs/eval.stderr.log` | present |
| `status.json` | present |
| `summary.csv` | present |

---

DONE lora-eval-retry-worker
