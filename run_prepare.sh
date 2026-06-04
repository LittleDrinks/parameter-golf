#!/bin/bash
export HF_HOME=/data/zsm/hf_cache
export HF_DATASETS_CACHE=/data/zsm/hf_cache/datasets
export HF_ENDPOINT=https://hf-mirror.com
mkdir -p $HF_HOME

set -euo pipefail

export CONFIG=${CONFIG:-configs/vlm_textvqa_lora.yaml}
export SEED=${SEED:-1}

python prepare_textvqa.py --config "${CONFIG}"
