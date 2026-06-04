Role:
seed-robustness-preflight

Goal:
Prepare the OCR seed robustness direction without consuming GPU. Validate model/result paths and produce serial launch commands for baseline seed1 and seed3 aligned `textvqa_val_ocr` evals.

Resource policy:
- smYuHangLab2 is a shared GPU server.
- This task is CPU/read-only except for writing one lightweight preflight note under `/data/zsm/parameter-golf/runs/analysis_seed_robustness_preflight`.
- Do not start lmms-eval or any model-loading process.
- Do not kill processes.

Allowed remote read-only paths:
- `/home/zsm/parameter-golf`
- `/home/zsm/pg-worktrees`
- `/data/zsm/parameter-golf`

Allowed remote write path:
- `/data/zsm/parameter-golf/runs/analysis_seed_robustness_preflight`

Forbidden actions:
- Do not run training or eval.
- Do not use GPU/CUDA.
- Do not edit git worktrees.
- Do not create or delete worktrees.
- Do not push branches.

Task:
1. Read current GPU/process state only to confirm no accidental `zsm` eval/training jobs are running.
2. Locate baseline seed1 and seed3 merged model paths.
3. Locate the isolated OCR eval worktree/config that patched `textvqa_val_ocr.yaml` to `dataset_path: lmms-lab/textvqa`.
4. Check whether seed1/seed3 aligned OCR eval result JSONs already exist anywhere under `/data/zsm/parameter-golf` or `/home/zsm/parameter-golf/results`.
5. Write serial launch plans for seed1 and seed3:
   - worktree branch to use or create,
   - run root,
   - command,
   - env vars,
   - pid/log/status files,
   - preflight GPU check,
   - stop condition if GPU is occupied.
6. Write `/data/zsm/parameter-golf/runs/analysis_seed_robustness_preflight/seed_robustness_preflight.md` and `status.json`.

Required final line:
DONE seed-robustness-preflight
