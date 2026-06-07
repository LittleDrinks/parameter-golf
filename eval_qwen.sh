#!/bin/bash
export HF_HOME=/data/zsm/hf_cache
export HF_DATASETS_CACHE=/data/zsm/hf_cache/datasets
export HF_ENDPOINT=https://hf-mirror.com
set -euo pipefail

export SEED=${SEED:-1}
export MODEL_PATH=${MODEL_PATH:-Qwen/Qwen3-VL-2B-Instruct}
export MAX_PIXELS=${MAX_PIXELS:-200704}
export MIN_PIXELS=${MIN_PIXELS:-100352}
export USE_CACHE=${USE_CACHE:-false}
export TASK=${TASK:-textvqa_val_ocr}
export HF_HOME=${HF_HOME:-${PWD}/hf_cache}
export HF_DATASETS_CACHE=${HF_DATASETS_CACHE:-${HF_HOME}/datasets}

python -c "import torch; print('CUDA available:', torch.cuda.is_available()); [print(f'  GPU {i}: {torch.cuda.get_device_name(i)}') for i in range(torch.cuda.device_count())]"

python -m lmms_eval \
    --model qwen3_vl \
    --model_args pretrained=${MODEL_PATH},attn_implementation=eager,device=cuda,max_pixels=${MAX_PIXELS},min_pixels=${MIN_PIXELS},use_cache=${USE_CACHE},device_map=cuda \
    --tasks "${TASK}" \
    --batch_size 1 \
    --output_path ./results/textvqa
