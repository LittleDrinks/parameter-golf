# 2026-06-05 Answer-Style Control: OCR16 max_new_tokens=32

## Context

After `lora_lr2e5_seed1` failed to beat the aligned baseline, the loop moved to a non-OCR, eval-only control from the answer-style audit: test whether `textvqa_val_ocr`'s default `max_new_tokens=16` truncates useful answers for the OCR16 model.

## Delegation

Codex acted as orchestrator and delegated execution to `panel-as-worker`.

- Worker session: `pg-answer-style-max32-worker`
- Prompt: `ara/trace/worker-captures/pg-answer-style-max32-worker-prompt.md`
- Final capture: `ara/trace/worker-captures/pg-answer-style-max32-worker-final.txt`
- Report: `ara/trace/worker-captures/pg-answer-style-max32-worker-report.md`

The worker created a dedicated server worktree:

```text
/home/zsm/pg-worktrees/answer_style_max32
```

Branch and commit:

```text
exp/answer-style-max32
93f7af7bf0df4eaeb2d5dc86d13dfa4c6833005f
```

The only code/config repair was the known server eval task fix:

```text
lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml
dataset_path: lmms-lab/textvqa
```

## GPU Exception

No GPU had `memory.used < 1000 MiB`. The worker used the user-approved bounded-eval exception:

- GPU 2 had existing memory use but repeated `GPU-Util=0%`.
- About 30 GiB VRAM remained at launch.
- Existing GPU processes belonged to another user and were not killed or signaled.
- The eval completed without OOM or CUDA collision.

## Run

Run root:

```text
/data/zsm/parameter-golf/runs/answer_style_ocr16_max32_20260605_101647
```

Command difference from OCR16 aligned eval:

```text
--gen_kwargs max_new_tokens=32
```

Result file:

```text
/data/zsm/parameter-golf/runs/answer_style_ocr16_max32_20260605_101647/eval/outputs__merged/20260605_101712_results.json
```

Metric:

- Task: `textvqa_val_ocr`
- exact_match: `0.7263800000000038`
- stderr: `0.005937294789201627`

## Interpretation

Prior OCR16 aligned eval with the default `max_new_tokens=16`:

```text
0.7262000000000036
```

Delta:

```text
+0.00018000000000029103
```

This is negligible relative to the eval standard error. The `max_new_tokens=16` setting is not a material truncation bottleneck for OCR16 on `textvqa_val_ocr`. Future answer-style controls should focus on prompt/system controls or baseline controls, not simply increasing generation length.

## ARA Updates

- Added `answer_style_ocr16_max32` to `ara/evidence/results.csv`.
- Added the completed control under `exp-answer-style-controls` in `ara/trace/exploration_tree.yaml`.
- Archived worker prompt, capture, and report under `ara/trace/worker-captures/`.
