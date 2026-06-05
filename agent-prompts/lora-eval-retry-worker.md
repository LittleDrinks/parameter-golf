# LoRA Eval Retry Worker Prompt

Role:
`lora-eval-retry-worker`

Goal:
Run the repaired matched eval for `lora_lr2e5_seed1` on `smYuHangLab2`, using the user-approved GPU scheduling exception.

Context:

- Codex is the orchestrator. Do not change ARA records directly.
- The prior direct retry attempts were stopped:
  - `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_retry_20260605_0935`
  - `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_retry_20260605_0940`
- The eval must use the experiment worktree's repaired `lmms-eval`, not `/home/zsm/parameter-golf/lmms-eval`.
- Worktree: `/home/zsm/pg-worktrees/lora_lr2e5_seed1`
- Branch: `exp/lora-lr2e5-seed1`
- Required commit: `9b2b51d6289cd78f10ccb26da25a146134b31bdb`
- Model path: `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/outputs/textvqa_qwen3vl_lora_lr2e5_seed1/merged`
- Task: `textvqa_val_ocr`
- Run root parent: `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1`

Allowed actions:

- Use `ssh smYuHangLab2` for server-side inspection and this eval run.
- Read `nvidia-smi`, `ps`, git status, existing run-root files, and eval logs.
- Launch exactly one repaired eval retry if the selected GPU is still acceptable under the user-approved exception:
  - prefer GPU 2 if its `GPU-Util` is near idle and remaining memory is still plausibly sufficient;
  - otherwise use another GPU only if it is clearly better under the same exception.
- Write only under a new retry run root:
  - `/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/eval_worker_retry_<timestamp>`
- Write a concise local worker report under:
  - `agent-runs/lora-eval-retry-worker-report.md`

Forbidden actions:

- Do not kill or signal unrelated processes.
- Do not configure GitHub credentials on `smYuHangLab2`.
- Do not edit the ARA records branch.
- Do not change training code, model code, datasets, or checkpoints.
- Do not launch training.
- Do not run more than one eval at a time.
- Do not retry in a loop after OOM or collision; record failure and stop.

Required run details:

1. Confirm:
   - `date`
   - `nvidia-smi --query-gpu=index,memory.used,utilization.gpu,name --format=csv,noheader,nounits`
   - `nvidia-smi --query-compute-apps=gpu_bus_id,pid,process_name,used_memory --format=csv,noheader,nounits`
   - `ps -fu zsm`
   - `git -C /home/zsm/pg-worktrees/lora_lr2e5_seed1 status --short --branch`
   - `git -C /home/zsm/pg-worktrees/lora_lr2e5_seed1 rev-parse HEAD`
   - `grep -n "dataset_path" /home/zsm/pg-worktrees/lora_lr2e5_seed1/lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml`
2. Launch with:
   - `cd /home/zsm/pg-worktrees/lora_lr2e5_seed1`
   - `source /home/zsm/parameter-golf/venv/bin/activate`
   - `export PYTHONPATH=/home/zsm/pg-worktrees/lora_lr2e5_seed1/lmms-eval:${PYTHONPATH:-}`
   - `export CUDA_VISIBLE_DEVICES=<selected_gpu>`
   - `export HF_HOME=/data/zsm/hf_cache`
   - `export HF_DATASETS_CACHE=/data/zsm/hf_cache/datasets`
   - `export HF_ENDPOINT=https://hf-mirror.com`
   - `python -m lmms_eval --model qwen3_vl --model_args pretrained=/data/zsm/parameter-golf/runs/lora_lr2e5_seed1/outputs/textvqa_qwen3vl_lora_lr2e5_seed1/merged,attn_implementation=eager,device=cuda,max_pixels=200704,min_pixels=100352,use_cache=false,device_map=cuda --tasks textvqa_val_ocr --batch_size 1 --output_path <retry_root>/eval`
3. In the retry root, save:
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
4. Verify `lmms_eval` resolves to the worktree path:
   - expected prefix: `/home/zsm/pg-worktrees/lora_lr2e5_seed1/lmms-eval/`
5. Monitor until completion, failure, or until the worker must stop for safety.
6. If a `*results.json` appears, extract and report:
   - result path
   - `textvqa_val_ocr` exact_match
   - stderr if present

Required final report:

Write `agent-runs/lora-eval-retry-worker-report.md` with:

- selected GPU and exception rationale
- existing GPU processes observed
- retry root
- command summary
- PID and process ownership
- status
- result path and metric if completed
- blocker/failure if not completed

Required final line:
`DONE lora-eval-retry-worker`
