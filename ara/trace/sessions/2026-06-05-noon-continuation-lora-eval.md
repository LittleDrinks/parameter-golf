# 2026-06-05 Noon Continuation: LoRA Eval Retry and GPU Exception

## Context

The user extended the running optimization loop hard stop to 2026-06-05 12:00 Asia/Shanghai and challenged the prior GPU scheduling rule because GPUs 2 and 3 showed persistent `GPU-Util = 0%` while holding about 18 GiB of memory. The user approved changing the rule from "only launch on memory-empty GPUs" to a controlled exception for idle-util GPUs with sufficient remaining memory.

## Rule Update

`AGENTS.md` now records:

- Default GPU launch rule remains `memory.used < 1000 MiB`.
- A user-approved exception may be used when a specific GPU has repeated near-idle utilization, enough remaining memory, and the run is bounded or explicitly approved.
- The exception run must record `nvidia-smi`, existing processes, selected GPU, command, PID, logs, result path, and rationale.
- Workers must not kill or interfere with unrelated processes; OOM/collision stops the attempt rather than retrying in a loop.
- Codex remains the orchestrator and delegates launch/monitoring to `panel-as-worker` after identifying a usable GPU.

## Orchestrator Correction

Before the user clarified worker-only execution, Codex directly launched two eval retry attempts:

- `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_retry_20260605_0935`
  - Stopped because it used the wrong `lmms_eval` import path from `/home/zsm/parameter-golf/lmms-eval`.
- `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_retry_20260605_0940`
  - Stopped after the user instructed Codex not to run directly and to delegate to a worker.

Both direct attempts are treated as failed/stopped evidence only. No metric from them is interpreted.

## Worker Delegation

Worker session:

- Session: `pg-lora-eval-retry-worker`
- Prompt: `ara/trace/worker-captures/pg-lora-eval-retry-worker-prompt.md`
- Final capture: `ara/trace/worker-captures/pg-lora-eval-retry-worker-final.txt`
- Report: `ara/trace/worker-captures/pg-lora-eval-retry-worker-report.md`

The worker selected GPU 2 under the user-approved exception:

- Launch-time GPU 2 state: `GPU-Util = 0%`, `memory.used = 17829 MiB`, about 30 GiB remaining.
- Existing GPU process on GPU 2: PID 2103741, non-`zsm` user, about 17794 MiB.
- The worker did not kill or signal unrelated processes.

## Result

Run root:

```text
/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_worker_retry_20260605_094237
```

Result file:

```text
/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_worker_retry_20260605_094237/eval/textvqa_qwen3vl_lora_lr2e5_seed1__merged/20260605_094300_results.json
```

Metric:

- Task: `textvqa_val_ocr`
- exact_match: `0.7148200000000041`
- stderr: `0.006025988385916861`

Interpretation:

- Best aligned baseline seed3: `0.7154200000000039`
- OCR16 aligned eval: `0.7262000000000036`
- `lora_lr2e5_seed1` does not beat the best aligned baseline and is far below OCR16; reject this single-seed learning-rate variant as an improvement direction unless a later LoRA-axis hypothesis supplies new evidence.

## ARA Updates

- Added `lora_lr2e5_seed1_eval_worker_retry` to `ara/evidence/results.csv`.
- Updated `exp-lora-lr2e5-seed1` in `ara/trace/exploration_tree.yaml` from `active` to `completed` with `completed_rejected` result status.
- Archived worker prompt, capture, and report under `ara/trace/worker-captures/`.
