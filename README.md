# Parameter Golf TextVQA Submission

This submission fine-tunes `Qwen/Qwen3-VL-2B-Instruct` with LoRA on TextVQA and includes the dataset-provided OCR tokens in the normal single-pass prompt. The best reported variant also adds one fixed instruction prefix only when an example has at least 5 OCR tokens. The submitted method keeps the same base model class and evaluation path as the starter system: one VLM forward pass, no external OCR model at inference time, no reranking, and no validation/test-label routing.

## Result

Matched evaluation task: `textvqa_val_ocr_cond_pre_a_ge5`

| Seed | exact_match |
|---:|---:|
| 1 | `0.7288800000000036` |
| 2 | `0.7290800000000038` |
| 3 | `0.7289800000000037` |
| **Mean** | **`0.7289800000000038`** |

Mean accuracy is **72.8980%** over three seeds.

The underlying OCR16 checkpoint without the conditional prefix scored `0.727153333333337` mean over the same three seeds on `textvqa_val_ocr`. A nearby public OCR-token reference, `isolatedNO3/parameter-golf`, reports `72.647%` mean on an OCR8 variant. The numbers are close, but not a strict apples-to-apples comparison because this submission uses up to 16 OCR tokens and the matched conditional OCR task.

## Method

- Base model: `Qwen/Qwen3-VL-2B-Instruct`
- Adaptation: LoRA
- Train dataset: `lmms-lab/textvqa`, train split
- Eval dataset/task: `lmms-lab/textvqa`, validation split via `textvqa_val_ocr`
- Prompt change: append up to the first 16 dataset-provided OCR tokens to the question:

```text
Reference OCR token: token1, token2, ...
Answer the question using a single word or phrase.
```

For validation/inference through the default task, examples with at least 5 OCR tokens also receive this fixed prefix:

```text
Answer briefly using image text when possible.
```

The OCR tokens are already part of TextVQA metadata. The method does not run a second OCR system during evaluation.

## Files

- `configs/vlm_textvqa_lora.yaml`: OCR16 LoRA training configuration.
- `prepare_textvqa.py`: builds seed-specific prepared training data with OCR16 prompts.
- `train_textvqa_qwen3vl.py`: LoRA fine-tuning script.
- `merge_lora.py`: merges the LoRA adapter into the base model.
- `run_prepare.sh`: data preparation entrypoint.
- `run_train.sh`: training entrypoint.
- `run_merge_lora.sh`: merge entrypoint.
- `eval_qwen.sh`: matched TextVQA OCR evaluation entrypoint.
- `lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr_cond_pre_a_ge5.yaml`: default best evaluation task with the conditional OCR instruction prefix.
- `lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml`: OCR-enabled TextVQA validation task using `dataset_path: lmms-lab/textvqa`.

## Setup

```bash
pip install -r requirements.txt
cd lmms-eval
pip install -e .
cd ..
```

Recommended cache environment:

```bash
export HF_HOME=${HF_HOME:-$PWD/hf_cache}
export HF_DATASETS_CACHE=${HF_DATASETS_CACHE:-$HF_HOME/datasets}
```

On mirrors or shared servers, set `HF_ENDPOINT` as needed.

## Reproduce

### 1. Prepare Data

```bash
SEED=1 bash run_prepare.sh
```

The config defaults to:

```yaml
data_path: lmms-lab/textvqa
data_split: train
use_ocr_tokens: true
max_ocr_tokens: 16
```

Local parquet globs are still supported by setting `data_path` to a `*.parquet` pattern.

### 2. Train

```bash
SEED=1 bash run_train.sh
```

The default output for seed 1 is:

```text
outputs/textvqa_qwen3vl_lora_ocr16_seed1/final
```

For all three seeds:

```bash
for seed in 1 2 3; do
  SEED=$seed bash run_prepare.sh
  SEED=$seed bash run_train.sh
done
```

### 3. Merge

```bash
SEED=1 bash run_merge_lora.sh
```

The merged model for seed 1 is saved to:

```text
outputs/textvqa_qwen3vl_lora_ocr16_seed1/merged
```

### 4. Evaluate

```bash
CUDA_VISIBLE_DEVICES=0 MODEL_PATH=./outputs/textvqa_qwen3vl_lora_ocr16_seed1/merged bash eval_qwen.sh
```

`eval_qwen.sh` defaults to `TASK=textvqa_val_ocr_cond_pre_a_ge5`. To reproduce the raw OCR16 baseline, set `TASK=textvqa_val_ocr`.

For all seeds:

```bash
for seed in 1 2 3; do
  SEED=$seed bash run_merge_lora.sh
  CUDA_VISIBLE_DEVICES=0 MODEL_PATH=./outputs/textvqa_qwen3vl_lora_ocr16_seed${seed}/merged \
    bash eval_qwen.sh
done
```

## Training Budget

The default config keeps the starter budget:

```yaml
max_steps: 1024
max_train_seconds: 3600
per_device_train_batch_size: 1
gradient_accumulation_steps: 8
lora_r: 16
lora_alpha: 32
lora_dropout: 0.05
```

The evaluation uses the same single-pass image budget:

```bash
MAX_PIXELS=200704
MIN_PIXELS=100352
```

## Notes

- Final reporting should use the three-seed mean above, not a single seed.
- This submission intentionally avoids larger models, multi-pass image crops, external inference-time rerankers, and validation-answer priors because those would violate the intended test-time budget or leakage constraints.
- If a local environment already has the model and dataset cached, set `HF_HOME` and `HF_DATASETS_CACHE` to those cache locations before running the scripts.
