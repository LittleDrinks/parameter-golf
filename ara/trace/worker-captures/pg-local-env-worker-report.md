# Local Environment Worker Report

## Worktree Info
- **Path:** `/tmp/pg-worktrees/local-env-gate`
- **Branch:** `exp/local-env-gate`
- **Commit:** `101959c` (add run all baseline script)

## Environment Setup

### Commands Attempted
```bash
# 1. Create isolated venv inside worktree
python3 -m venv .venv

# 2. Upgrade build tools
.venv/bin/pip install --upgrade pip setuptools wheel

# 3. Install CPU-only PyTorch (avoiding CUDA wheels)
.venv/bin/pip install torch==2.5.1 torchvision==0.20.1 \
    --index-url https://download.pytorch.org/whl/cpu

# 4. Install core ML dependencies
.venv/bin/pip install transformers==4.57.1 accelerate==1.7.0 peft==0.15.2 \
    datasets==3.6.0 Pillow==11.0.0 PyYAML==6.0.2 qwen-vl-utils==0.0.14 tqdm==4.67.1

# 5. Install lmms-eval locally
(cd lmms-eval && ../.venv/bin/pip install -e .)
```

### Python Version
- System Python: `3.12.3` (requirements.txt mentions 3.13.5, but 3.12 works)
- Virtualenv: `.venv/` inside worktree

## Dataset / Cache Status

| Resource | Status | Detail |
|----------|--------|--------|
| `data/` symlink | **Broken** | Points to `/data/zsm/parameter-golf/data/` which does not exist on this host |
| `outputs/` symlink | **Broken** | Points to `/data/zsm/parameter-golf/outputs/` which does not exist |
| Local HF Hub cache | Present (~17 GB) | `~/.cache/huggingface/hub/` exists with various models, **no Qwen3-VL** cached |
| Local HF Datasets cache | Present (~164 MB) | `~/.cache/huggingface/datasets/` exists, **no TextVQA** cached |
| TextVQA parquet | **Missing** | Config references `/data/zsm/parameter-golf/data/textvqa_train.parquet` |

## Smoke Test Results

All tests run with `.venv/bin/python`.

1. **Core imports:** PASS
   - `torch==2.5.1+cpu`, `transformers==4.57.1`, `peft==0.15.2`, `datasets==3.6.0`, `yaml`, `PIL` all import cleanly.
   - `torch.cuda.is_available()` -> `False` (expected for CPU-only).

2. **lmms-eval import:** PASS
   - `import lmms_eval` succeeds.
   - `from lmms_eval.tasks._task_utils.vqa_eval_metric import EvalAIAnswerProcessor` succeeds and produces normalized output.

3. **Config parsing:** PASS
   - `configs/vlm_textvqa_lora.yaml` loads correctly; all expected keys present.

4. **Processor metadata load:** PASS
   - `AutoProcessor.from_pretrained('Qwen/Qwen3-VL-2B-Instruct', ...)` succeeds.
   - Tokenizer vocab size confirmed: `151643`.
   - This required downloading tokenizer/processor files from Hugging Face (~small metadata).

5. **Full model weights load:** **STOPPED / INFEASIBLE**
   - Loading `AutoModelForVision2Seq` with `device_map='cpu'` begins downloading the full ~4 GB `Qwen3-VL-2B-Instruct` weights.
   - This was explicitly aborted because the task forbids pulling huge model checkpoints for a CPU-only smoke test.

## Blockers

1. **Data path missing:** The `data/` symlink points to a server path (`/data/zsm/parameter-golf/data/`) not available locally. `prepare_textvqa.py` cannot run without either:
   - Restoring the symlink target, or
   - Changing `data_path` in config to a local/HF source (e.g., `lmms-lab/textvqa`).

2. **Model weights not cached:** No local copy of `Qwen/Qwen3-VL-2B-Instruct`. CPU-only download of ~4 GB is possible but wasteful for a smoke test.

3. **Training inherently requires GPU/CUDA:**
   - `train_textvqa_qwen3vl.py` hard-codes `torch_dtype=torch.float16`, `fp16=True`, `AutoModelForVision2Seq` training.
   - `eval_qwen.sh` hard-codes `device=cuda` and `device_map=cuda`.
   - A CPU-only run of training or evaluation is **not practical** (would be extremely slow and may fail on FP16-on-CPU issues).

4. **Evaluation via lmms-eval requires CUDA:** The `qwen3_vl` model wrapper in lmms-eval assumes CUDA devices.

## Next Recommended Action

The local environment is **sufficient for static analysis, config editing, and lightweight import checks**, but **cannot serve as a full training/evaluation gate**.

Recommended server-side gate or skip condition:

- **Skip local training/eval** on this CPU-only worker.
- **Use the local environment only for:**
  - Syntax / import validation (done).
  - Config YAML correctness.
  - `prepare_textvqa.py` logic review.
- **Run the actual smoke test (prepare + train + eval) on `smYuHangLab2` or another GPU host** where:
  - `/data/zsm/parameter-golf/data/` is mounted.
  - `CUDA` is available.
  - The shared `venv` at `~/parameter-golf/venv/` (referenced in `run.sh`) is already set up.

If a local CPU-only gate must be enforced, the minimum viable test is:
```bash
python -c "import torch, transformers, peft, datasets, lmms_eval; \
           from lmms_eval.tasks._task_utils.vqa_eval_metric import EvalAIAnswerProcessor; \
           print('imports OK')"
```
which **already passes** in the `.venv` created above.

---
DONE local-env-worker
