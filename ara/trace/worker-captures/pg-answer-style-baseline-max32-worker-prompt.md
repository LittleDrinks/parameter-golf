Role:
answer-style-baseline-max32-worker

Goal:
Run one full TextVQA eval-only answer-style control: baseline seed3 merged model on `textvqa_val_ocr` with `--gen_kwargs max_new_tokens=32`. This tests whether increasing generation length lets the best aligned baseline approach OCR16.

Server:
Use `ssh smYuHangLab2`.

Allowed files:
- Reuse only if clean: `/home/zsm/pg-worktrees/answer_style_max32`
- Create a new run root: `/data/zsm/parameter-golf/runs/answer_style_baseline_seed3_max32_<timestamp>`
- Write local worker report: `agent-runs/answer-style-baseline-max32-worker-report.md`

Forbidden actions:
- Do not kill, signal, renice, or otherwise interfere with unrelated processes.
- Do not configure GitHub credentials on `smYuHangLab2`.
- Do not edit the ARA records branch.
- Do not launch training.
- Do not run more than one eval at a time.
- Do not retry in a loop after OOM, CUDA collision, or task failure; record the failure and stop.

Worktree requirement:
1. Use `/home/zsm/pg-worktrees/answer_style_max32` only if it is on branch `exp/answer-style-max32` and clean.
2. Verify the task YAML has `dataset_path: lmms-lab/textvqa`.
3. If the worktree is dirty, wrong branch, missing, or has the wrong dataset path, stop and report. Do not repair in this worker.

GPU rule:
- Default: launch only on `memory.used < 1000 MiB`.
- User-approved exception is allowed for this bounded eval: if no empty GPU is available, select one GPU only if repeated checks show near-idle `GPU-Util`, enough remaining memory for the eval, and current compute apps are recorded.
- Prefer GPU 1 if it remains near-idle and has about 30 GiB free. Do not use GPU 2 if remaining memory is materially below what the previous max32 eval needed. Avoid GPU 3 unless its utilization returns to near-idle across repeated checks.

Required preflight:
Run and record:
- `date`
- `nvidia-smi --query-gpu=index,memory.used,utilization.gpu,name --format=csv,noheader,nounits`
- `nvidia-smi --query-compute-apps=gpu_bus_id,pid,process_name,used_memory --format=csv,noheader,nounits`
- `ps -fu zsm`
- `git -C /home/zsm/pg-worktrees/answer_style_max32 status --short --branch`
- `git -C /home/zsm/pg-worktrees/answer_style_max32 rev-parse HEAD`
- `grep -n "dataset_path" /home/zsm/pg-worktrees/answer_style_max32/lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml`
- Confirm model path exists: `/data/zsm/parameter-golf/outputs/textvqa_qwen3vl_lora_seed3/merged`

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
  --model_args pretrained=/data/zsm/parameter-golf/outputs/textvqa_qwen3vl_lora_seed3/merged,attn_implementation=eager,device=cuda,max_pixels=200704,min_pixels=100352,use_cache=false,device_map=cuda \
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
- Monitor until completion, failure, or safety stop. Use a practical interval; do not spam logs.
- If a `*results.json` appears, extract:
  - result path
  - `textvqa_val_ocr` exact_match
  - stderr if present

Required final report:
Write `agent-runs/answer-style-baseline-max32-worker-report.md` with:
- selected GPU and exception rationale or default empty-GPU rationale
- existing GPU processes observed
- worktree path, branch, and commit
- run root
- command summary
- PID and process ownership
- status
- result path and metric if completed
- comparison against baseline seed3 max16 `0.7154200000000039` and OCR16 max16 `0.7262000000000036`
- blocker/failure if not completed

Required final line:
DONE answer-style-baseline-max32-worker
