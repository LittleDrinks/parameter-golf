Role:
answer-style-max32-worker

Goal:
Run one full TextVQA eval-only answer-style control: OCR16 merged model on `textvqa_val_ocr` with `--gen_kwargs max_new_tokens=32`. This tests whether the current `max_new_tokens=16` setting truncates useful answers.

Server:
Use `ssh smYuHangLab2`.

Allowed files:
- Create or reuse only if clean: `/home/zsm/pg-worktrees/answer_style_max32`
- Create a new run root: `/data/zsm/parameter-golf/runs/answer_style_ocr16_max32_<timestamp>`
- Write local worker report: `agent-runs/answer-style-max32-worker-report.md`

Forbidden actions:
- Do not kill, signal, renice, or otherwise interfere with unrelated processes.
- Do not configure GitHub credentials on `smYuHangLab2`.
- Do not edit the ARA records branch.
- Do not launch training.
- Do not run more than one eval at a time.
- Do not retry in a loop after OOM, CUDA collision, or task failure; record the failure and stop.

Worktree requirement:
1. On the server, ensure `/home/zsm/pg-worktrees/answer_style_max32` is a dedicated git worktree for this eval family.
2. Preferred setup:
   - source repo: `/home/zsm/parameter-golf`
   - worktree path: `/home/zsm/pg-worktrees/answer_style_max32`
   - branch: `exp/answer-style-max32`
   - base commit: `101959c882dd9d05be79668f80456da038c01c77`
3. If the worktree already exists, verify it is on `exp/answer-style-max32` and clean before using it. If it is dirty or wrong, stop and report.
4. Verify and, if needed, patch only this worktree's `lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml` so `dataset_path: lmms-lab/textvqa`.
5. Commit any worktree task-YAML repair locally on the server branch. Do not push from the server.

GPU rule:
- Default: launch only on `memory.used < 1000 MiB`.
- User-approved exception is allowed for this bounded eval: if no empty GPU is available, select one GPU only if repeated checks show near-idle `GPU-Util`, enough remaining memory for the eval, and current compute apps are recorded.
- Prefer GPU 2 or GPU 3 only if they are still near-idle. If neither is acceptable, stop and report.

Required preflight:
Run and record:
- `date`
- `nvidia-smi --query-gpu=index,memory.used,utilization.gpu,name --format=csv,noheader,nounits`
- `nvidia-smi --query-compute-apps=gpu_bus_id,pid,process_name,used_memory --format=csv,noheader,nounits`
- `ps -fu zsm`
- `git -C /home/zsm/pg-worktrees/answer_style_max32 status --short --branch`
- `git -C /home/zsm/pg-worktrees/answer_style_max32 rev-parse HEAD`
- `grep -n "dataset_path" /home/zsm/pg-worktrees/answer_style_max32/lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml`

Eval command:
Use the selected GPU and this command shape:

```bash
cd /home/zsm/pg-worktrees/answer_style_max32
source /home/zsm/parameter-golf/venv/bin/activate
export PYTHONPATH=/home/zsm/pg-worktrees/answer_style_max32/lmms-eval:${PYTHONPATH:-}
export CUDA_VISIBLE_DEVICES=<selected_gpu>
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

Run-root evidence:
In the run root, save:
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

Monitoring:
- Monitor every 30 seconds until completion, failure, or safety stop.
- If a `*results.json` appears, extract:
  - result path
  - `textvqa_val_ocr` exact_match
  - stderr if present

Required final report:
Write `agent-runs/answer-style-max32-worker-report.md` with:
- selected GPU and exception rationale or default empty-GPU rationale
- existing GPU processes observed
- worktree path, branch, commit, and any local task-YAML repair commit
- retry/run root
- command summary
- PID and process ownership
- status
- result path and metric if completed
- blocker/failure if not completed

Required final line:
DONE answer-style-max32-worker
