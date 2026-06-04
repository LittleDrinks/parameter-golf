# 2026-06-05 overnight execution

## Turn: 00:07-00:21 Asia/Shanghai

Objective source: `ara/trace/sessions/2026-06-05-direct-overnight-goal.md`.

Actions:

- Rehydrated hard-stop goal: continue TextVQA exact_match optimization until `2026-06-05 08:00 Asia/Shanghai`, with worker delegation, shared-server-safe GPU scheduling, and final hard-stop report.
- Inspected local records branch state: `ara-records-only` at `02a6782b67e4253dd328e9c7715ad6e6b625d347`; no dirty files before this turn's record updates.
- Inspected local worker state:
  - `rmux list-sessions` showed `pg-local-env-worker`.
  - Captured local worker pane.
  - Worker had created `/tmp/pg-worktrees/local-env-gate/.venv` and installed CPU dependencies.
  - Worker completed import/config smoke checks.
  - Orchestrator interrupted full model load after it began downloading large Qwen weights, preserving the CPU-only bounded-gate constraint.
  - Worker wrote `agent-runs/local-env-worker-report.md` and ended with `DONE local-env-worker`.
  - Archived pane/report to:
    - `ara/trace/worker-captures/pg-local-env-worker-final.txt`
    - `ara/trace/worker-captures/pg-local-env-worker-report.md`
- Inspected shared server state via read-only SSH:
  - `nvidia-smi` at 00:09 showed GPU2 free (`memory.used=29 MiB`), while GPUs 0/1/3 were occupied.
  - `ps -fu zsm` showed no active training/eval process before launch.
- Launched non-OCR proof-of-idea LoRA run because GPU time was available and the goal requires at least one non-OCR real proof-of-idea if possible:
  - run_id: `lora_lr2e5_seed1`
  - worktree: `/home/zsm/pg-worktrees/lora_lr2e5_seed1`
  - branch: `exp/lora-lr2e5-seed1`
  - commit: `910bba64a914f6e9389e6dd9ed585c689de79e8c`
  - config source: `/home/zsm/pg-worktrees/lora_lr2e5_seed1/configs/experiments/lora_lr2e5.yaml`
  - run-root config snapshot: `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/config.yaml`
  - change: baseline LoRA config with `learning_rate: 0.00002`; `use_ocr_tokens: false` unchanged.
  - seed: `1`
  - GPU: `2`
  - run root: `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1`
  - matched eval target after train/merge: `textvqa_val_ocr`
  - durable files present/planned: `command.sh`, `env.txt`, `git_commit.txt`, `git_diff.patch`, `pid.txt`, `launcher_pid.txt`, `logs/*`, `status.json`, `summary.csv`, eval copy under `eval/`.
- Verified launch:
  - `status.json`: `{"status":"running","stage":"train","time":"2026-06-05T00:14:53+08:00"}`
  - `pid.txt` and `launcher_pid.txt`: `243821`
  - `ps -fu zsm`: launcher `243821`, `run_train.sh`, `accelerate`, and `train_textvqa_qwen3vl.py` running.
  - GPU2 memory rose to about `7479 MiB`.
  - training progress reached at least `113/1024` steps by the latest tail around 00:20.

Interpretation:

- Local CPU environment is useful for static/import/config checks only. Full training/eval gates remain server-side because local data symlinks are absent, Qwen3-VL weights are not cached, and train/eval scripts assume CUDA/FP16.
- The overnight loop is now satisfying the non-OCR proof-of-idea requirement in progress: independent worktree, branch, config commit, full train, and matched eval pipeline are running. No metric is available yet.
- Do not promote any LoRA claim until the full train+merge+matched eval completes and the exact_match result is recorded.

Next:

- Continue polling `lora_lr2e5_seed1`.
- If it completes successfully, parse/copy result JSON, update `ara/evidence/results.csv`, update `exploration_tree.yaml`, archive logs/captures, and decide whether to start a second run or a prompt/control eval.
- If it fails, record the failure evidence and launch the next plausible direction while respecting GPU concurrency.

## Turn: 02:24-02:31 Asia/Shanghai

Actions:

- Resumed read-only server inspection after the escalation retry window reopened.
- Verified `lora_lr2e5_seed1` reached `status=completed` at `2026-06-05T01:07:02+08:00`, but `result_path` was empty.
- Inspected logs and artifacts:
  - train completed and produced final adapter under `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/outputs/textvqa_qwen3vl_lora_lr2e5_seed1/final`.
  - merge completed and produced merged model under `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/outputs/textvqa_qwen3vl_lora_lr2e5_seed1/merged`.
  - first eval attempt wrote `logs/eval.stdout.log` and `logs/eval.stderr.log` but no results JSON.
  - eval failed before model evaluation because `textvqa_val_ocr.yaml` still used `dataset_path: /storage/data/shiyd2023/datasets/textvqa`.
- Applied the same eval dataset-path repair used by prior aligned OCR eval branches:
  - worktree: `/home/zsm/pg-worktrees/lora_lr2e5_seed1`
  - file: `lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml`
  - change: `dataset_path: lmms-lab/textvqa`
  - commit: `9b2b51d` (`Patch TextVQA OCR eval dataset path`)
  - run-root evidence:
    - `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_harness_commit.txt`
    - `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_harness_diff.patch`
- Checked GPUs at 02:25: no GPU had `memory.used < 1000 MiB`; matched eval rerun deferred.
- Reviewed the LoRA training config patch:
  - commit: `910bba64a914f6e9389e6dd9ed585c689de79e8c`
  - scope: config-only file `configs/experiments/lora_lr2e5.yaml`
  - intended change: `learning_rate: 0.00002`
  - path changes: prepared data and outputs moved under `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1`
  - unchanged controls: `use_ocr_tokens: false`, `max_train_samples: 40960`, `max_steps: 1024`, LoRA rank/alpha/dropout/target modules, pixel bounds, sequence length
  - review finding: no P0/P1 issue in the config patch; metric still requires repaired matched eval before interpretation.
  - train evidence: `train_runtime=3053.8071`, `completed_steps=1024`, `train_loss=0.467629817314446`.

Interpretation:

- This run is not yet a completed proof-of-idea because the matched eval metric is missing.
- Training and merge artifacts are reusable; only the matched eval step needs rerun on a free GPU.
- The eval harness patch was locally reviewed as a one-line dataset_path repair matching prior aligned OCR eval worktrees. Do not interpret a LoRA metric until rerun succeeds.

Next:

- Poll GPU availability.
- When any GPU has `memory.used < 1000 MiB`, rerun only matched eval for `lora_lr2e5_seed1` using the repaired `textvqa_val_ocr` task and merged model path.
- After eval, record exact_match in `ara/evidence/results.csv`, update the exploration tree, and choose the next direction.
