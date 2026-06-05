# answer-style-baseline-max32-worker Report

## GPU Selection

- **Selected GPU:** 1
- **Rationale:** User-approved exception. No GPU had `memory.used < 1000 MiB`. GPU 1 was checked three times over about 15 seconds and remained at 0% utilization with about 30 GiB free (17.3 to 17.9 GiB used on a 48 GiB A6000), satisfying the near-idle + sufficient-memory condition. The prompt explicitly prefers GPU 1 under these circumstances.

## Existing GPU Processes Observed

| GPU | PID | Process | Used Memory (MiB) | Utilization |
|-----|-----|---------|-------------------|-------------|
| 0 | 514685 | python | 48,618 | 95% to 0% |
| 1 | 3774180 | python | 17,270 to 17,868 | 0% (stable) |
| 2 | 2103741 | python | 32,016 | 0% to 99% to 0% |
| 3 | 3828320 | python | 31,652 to 48,098 | 98% to 100% |

No unrelated zsm processes posed a conflict.

## Worktree Verification

- **Path:** `/home/zsm/pg-worktrees/answer_style_max32`
- **Branch:** `exp/answer-style-max32`
- **Commit:** `93f7af7bf0df4eaeb2d5dc86d13dfa4c6833005f`
- **Dataset path in YAML:** `lmms-lab/textvqa` (line 3) verified
- **Clean/dirty:** Clean working tree (no short-status output)

## Run Root

`/data/zsm/parameter-golf/runs/answer_style_baseline_seed3_max32_20260605_110052`

## Command Summary

```bash
cd /home/zsm/pg-worktrees/answer_style_max32
source /home/zsm/parameter-golf/venv/bin/activate
export PYTHONPATH=/home/zsm/pg-worktrees/answer_style_max32/lmms-eval
export CUDA_VISIBLE_DEVICES=1
export HF_HOME=/data/zsm/hf_cache
export HF_DATASETS_CACHE=/data/zsm/hf_cache/datasets
export HF_ENDPOINT=https://hf-mirror.com
python -m lmms_eval \
  --model qwen3_vl \
  --model_args pretrained=/data/zsm/parameter-golf/outputs/textvqa_qwen3vl_lora_seed3/merged,attn_implementation=eager,device=cuda,max_pixels=200704,min_pixels=100352,use_cache=false,device_map=cuda \
  --tasks textvqa_val_ocr \
  --gen_kwargs max_new_tokens=32 \
  --batch_size 1 \
  --output_path <run_root>/eval
```

## PID and Process Ownership

- **Eval PID:** 2383657 (owned by zsm)
- **Launcher PID:** 2316123 (owned by zsm)

## Status

**COMPLETED** - process exited cleanly after full 5000-sample evaluation and postprocessing.

## Result

- **Result path:** `/data/zsm/parameter-golf/runs/answer_style_baseline_seed3_max32_20260605_110052/eval/textvqa_qwen3vl_lora_seed3__merged/20260605_110101_results.json`
- **textvqa_val_ocr exact_match:** `0.715660000000004`
- **exact_match_stderr:** `0.0060149970006463105`
- **Samples:** 5000
- **Total eval time:** ~1299 seconds (~21.6 minutes)

## Comparison

| Run | max_new_tokens | exact_match | Notes |
|-----|---------------|-------------|-------|
| baseline seed3 (reference) | 16 | 0.7154200000000039 | Aligned eval baseline |
| **This run** | **32** | **0.715660000000004** | Negligible +0.00024 change |
| OCR16 (reference) | 16 | 0.7262000000000036 | Still ~+0.01054 ahead |

**Interpretation:** Increasing `max_new_tokens` from 16 to 32 for the baseline seed3 merged model produced no meaningful improvement on `textvqa_val_ocr`. The score moved by only +0.00024, well within noise. The gap to OCR16 (`0.7262`) remains essentially unchanged at ~0.0105. This suggests that generation length is not the limiting factor for the baseline model on this task.

## Blockers / Failures

None. No OOM, CUDA collision, or task failures occurred. Stderr contained only benign warnings (`nframes` keyword ignored, generation flags not valid).

## Run-Root Evidence Checklist

- [x] `command.sh`
- [x] `env.txt`
- [x] `git_commit.txt`
- [x] `git_diff.patch`
- [x] `pid.txt`
- [x] `launcher_pid.txt`
- [x] `logs/eval.stdout.log`
- [x] `logs/eval.stderr.log`
- [x] `status.json`
- [x] `summary.csv`

---

DONE answer-style-baseline-max32-worker
