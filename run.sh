#!/bin/bash
set -e
export CUDA_VISIBLE_DEVICES=0
export HF_HOME=/data/zsm/hf_cache
export HF_ENDPOINT=https://hf-mirror.com
cd ~/parameter-golf
source venv/bin/activate

for seed in 1 2 3; do
    echo "========== SEED $seed START =========="
    SEED=$seed bash run_prepare.sh || { echo "prepare failed"; exit 1; }
    SEED=$seed bash run_train.sh || { echo "train failed"; exit 1; }
    SEED=$seed bash run_merge_lora.sh || { echo "merge failed"; exit 1; }
    CUDA_VISIBLE_DEVICES=0 MODEL_PATH=./outputs/textvqa_qwen3vl_lora_seed${seed}/merged bash eval_qwen.sh || { echo "eval
    failed"; exit 1; }
    echo "========== SEED $seed DONE =========="
done

echo "ALL SEEDS COMPLETE"