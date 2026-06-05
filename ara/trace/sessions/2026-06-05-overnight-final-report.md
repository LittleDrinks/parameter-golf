# 2026-06-05 overnight final report

Hard stop: `2026-06-05 08:00 Asia/Shanghai`

Report generated: `2026-06-05 08:02 Asia/Shanghai`

## 1. Summary verdict

- Best confirmed metric remains OCR16 aligned eval:
  - run: `eval_ocr16_seed1_textvqa_val_ocr`
  - branch: `exp/eval-ocr16-ocr`
  - commit: `101959c882dd9d05be79668f80456da038c01c77`
  - task: `textvqa_val_ocr`
  - exact_match: `0.7262000000000036`
  - result path: `/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/eval/outputs__merged/20260604_193246_results.json`
- Baseline aligned OCR eval remained below OCR16:
  - seed1: `0.7134200000000036`
  - seed2: `0.7133600000000039`
  - seed3: `0.7154200000000039`
  - best baseline aligned OCR: `0.7154200000000039`
  - OCR16 delta vs best baseline: `+0.010780000000000012`
- No new direction beat OCR16 before the hard stop.
- A non-OCR proof-of-idea was attempted with a full train and merge, but matched eval could not complete because all GPUs stayed above the `<1000 MiB` launch threshold after the eval repair.

## 2. Experiments completed

| run_id | direction | branch | commit | config | seed | run root | matched eval | metric |
|---|---|---|---|---|---:|---|---|---:|
| `eval_ocr16_seed1_textvqa_val_ocr` | OCR aligned eval | `exp/eval-ocr16-ocr` | `101959c882dd9d05be79668f80456da038c01c77` | `/home/zsm/pg-worktrees/pg-eval-ocr16-ocr/lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml` | 1 | `/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr` | `textvqa_val_ocr` | `0.7262000000000036` |
| `eval_baseline_seed1_textvqa_val_ocr` | baseline aligned eval | `exp/seed-robustness-ocr` | `d659cbdf335a66f43e835dd2c3899ff76edeb5d6` | `/home/zsm/pg-worktrees/pg-seed-robustness-ocr/lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml` | 1 | `/data/zsm/parameter-golf/runs/eval_baseline_seed1_textvqa_val_ocr` | `textvqa_val_ocr` | `0.7134200000000036` |
| `eval_baseline_seed2_textvqa_val_ocr` | baseline aligned eval | `exp/eval-baseline-ocr` | `101959c882dd9d05be79668f80456da038c01c77` | `/home/zsm/pg-worktrees/pg-eval-baseline-ocr/lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml` | 2 | `/data/zsm/parameter-golf/runs/eval_baseline_seed2_textvqa_val_ocr` | `textvqa_val_ocr` | `0.7133600000000039` |
| `eval_baseline_seed3_textvqa_val_ocr` | baseline aligned eval | `exp/seed-robustness-ocr` | `d659cbdf335a66f43e835dd2c3899ff76edeb5d6` | `/home/zsm/pg-worktrees/pg-seed-robustness-ocr/lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml` | 3 | `/data/zsm/parameter-golf/runs/eval_baseline_seed3_textvqa_val_ocr` | `textvqa_val_ocr` | `0.7154200000000039` |

## 3. Experiments attempted but blocked

| run_id | direction | branch | commits | config | seed | run root | status |
|---|---|---|---|---|---:|---|---|
| `lora_lr2e5_seed1` | non-OCR LoRA LR sweep | `exp/lora-lr2e5-seed1` | train config `910bba64a914f6e9389e6dd9ed585c689de79e8c`; eval repair `9b2b51d` | `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/config.yaml` | 1 | `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1` | full train and merge completed; first eval failed due stale dataset path; eval task repaired; rerun blocked by shared GPU contention |

Details for `lora_lr2e5_seed1`:

- Worktree: `/home/zsm/pg-worktrees/lora_lr2e5_seed1`
- Training change: baseline config copy with `learning_rate: 0.00002`; `use_ocr_tokens: false` unchanged.
- Training evidence:
  - `completed_steps: 1024`
  - `train_runtime_seconds: 3053.8071`
  - `train_loss: 0.467629817314446`
  - final adapter: `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/outputs/textvqa_qwen3vl_lora_lr2e5_seed1/final`
  - merged model: `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/outputs/textvqa_qwen3vl_lora_lr2e5_seed1/merged`
- First eval attempt:
  - task: `textvqa_val_ocr`
  - logs: `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/logs/eval.stdout.log`, `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/logs/eval.stderr.log`
  - failure: `FileNotFoundError` for `/storage/data/shiyd2023/datasets/textvqa`
  - no result JSON produced
- Repair:
  - file: `/home/zsm/pg-worktrees/lora_lr2e5_seed1/lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml`
  - change: `dataset_path: lmms-lab/textvqa`
  - evidence: `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_harness_commit.txt`, `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_harness_diff.patch`
- Final blocker:
  - From 02:25 through 08:02, repeated `nvidia-smi` polls found no GPU with `memory.used < 1000 MiB`.
  - Final 08:02 GPU memory: GPU0 `18718 MiB`, GPU1 `48349 MiB`, GPU2 `17903 MiB`, GPU3 `18723 MiB`.
  - Final `ps -fu zsm` showed no active `zsm` train/eval jobs.

## 4. Review results

- `lora_lr2e5_seed1` training config patch: local orchestrator review completed.
  - Scope was config-only: run-root paths plus `learning_rate: 0.00002`.
  - Unchanged controls: prompt/OCR setting, sample count, max steps, LoRA target modules, dropout, rank, pixel bounds, and eval generation.
  - No P0/P1 finding in the config patch.
- `lora_lr2e5_seed1` eval harness patch: local orchestrator review completed.
  - Scope was one-line `dataset_path` repair to `lmms-lab/textvqa`.
  - Same repair as prior aligned OCR eval branches.
  - No LoRA metric was interpreted because matched eval did not rerun successfully.

## 5. Worker hygiene

- Local env worker:
  - session: `pg-local-env-worker`
  - worktree: `/tmp/pg-worktrees/local-env-gate`
  - report: `ara/trace/worker-captures/pg-local-env-worker-report.md`
  - final pane capture: `ara/trace/worker-captures/pg-local-env-worker-final.txt`
  - outcome: CPU-only import/config gate passed; full local model load was stopped because it began downloading large Qwen weights.
- Server processes at hard stop:
  - no active `zsm` train/eval/merge processes.
  - no worker-owned process requires cleanup.

## 6. Git and push status

- Records branch local commits created:
  - `446bed8` `Record overnight LoRA launch`
  - `8a13024` `Record LoRA eval repair`
  - `70b5a56` `Record LoRA config review`
- Records branch status before final report commit: ahead of `origin/ara-records-only` by 3.
- Server experiment branch:
  - branch: `exp/lora-lr2e5-seed1`
  - commits: `910bba64a914f6e9389e6dd9ed585c689de79e8c`, `9b2b51d`
  - server-side push not attempted by design; server has no GitHub credentials.
- Remote push status after this final report still needs to be recorded by the final commit/push step.

## 7. Next recommended experiments

1. Rerun only the repaired matched eval for `lora_lr2e5_seed1` when any GPU has `memory.used < 1000 MiB`:
   - worktree: `/home/zsm/pg-worktrees/lora_lr2e5_seed1`
   - model: `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/outputs/textvqa_qwen3vl_lora_lr2e5_seed1/merged`
   - task: `textvqa_val_ocr`
2. If `lora_lr2e5_seed1` is below baseline aligned OCR, archive it as a LoRA LR dead end and try a different non-OCR axis only if GPU time remains.
3. If `lora_lr2e5_seed1` beats best baseline aligned OCR but not OCR16, consider a second seed before claiming a non-OCR improvement.
4. Do not start a new OCR-only training direction until the queued non-OCR matched eval is resolved.
