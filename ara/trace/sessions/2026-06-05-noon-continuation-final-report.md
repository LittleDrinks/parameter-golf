# 2026-06-05 Noon Continuation Final Report

Hard stop: `2026-06-05 12:00 Asia/Shanghai`

Report generated: `2026-06-05 11:55 Asia/Shanghai`

## Summary Verdict

- Best confirmed metric remains OCR16 aligned eval:
  - `textvqa_val_ocr exact_match = 0.7262000000000036`
  - run root: `/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr`
- Generation length controls are closed as low value:
  - OCR16 max32: `0.7263800000000038`, only `+0.00018` over max16
  - baseline seed3 max32: `0.715660000000004`, only `+0.00024` over max16 and still `-0.01054` below OCR16 max16
- LoRA LR 2e-5 seed1 completed and was rejected:
  - matched `textvqa_val_ocr exact_match = 0.7148200000000041`
  - below best aligned baseline seed3 `0.7154200000000039`
- OCR layout representation remains the highest-probability next path, but now the next concrete step is sidecar conversion, not training.
- OCR-win curriculum/reweighting should be dropped for now because subset signals are not separable.

## New Worker Results

### `pg-ocr-layout-feasibility-worker`

- Worktree: `/home/zsm/pg-worktrees/ocr_layout_feasibility`
- Branch: `exp/ocr-layout-feasibility`
- Commit: `101959c882dd9d05be79668f80456da038c01c77`
- Run root: `/data/zsm/parameter-golf/runs/analysis_ocr_layout_feasibility_20260605_112829`
- Verdict: blocked on current cache
- Key finding: cached `lmms-lab/textvqa` exposes flat `ocr_tokens`, image dimensions, and answers, but no OCR bounding boxes, confidence, or spatial metadata.
- Archived:
  - `ara/trace/worker-captures/pg-ocr-layout-feasibility-worker-final.txt`
  - `ara/trace/worker-captures/pg-ocr-layout-feasibility-worker-report.md`

### `pg-textvqa-ocr-geometry-worker`

- Worktree: `/home/zsm/pg-worktrees/textvqa_ocr_geometry`
- Branch: `exp/textvqa-ocr-geometry`
- Commit: `101959c882dd9d05be79668f80456da038c01c77`
- Run root: `/data/zsm/parameter-golf/runs/analysis_textvqa_ocr_geometry_20260605_114218`
- Verdict: `SOURCE_VERIFIED`
- Primary source:
  - `/data/zsm/parameter-golf/external/textvqa/TextVQA_Rosetta_OCR_v0.2_val.json`
  - URL: `https://dl.fbaipublicfiles.com/textvqa/data/TextVQA_Rosetta_OCR_v0.2_val.json`
  - SHA256: `5fe60362e43381e10b29bf25cc84bb0cebcabf155a32e7121208b51a5a02715c`
  - size: `9830753` bytes
- Schema: `image_id`, `ocr_tokens`, `ocr_info`; each `ocr_info` has `word` and `bounding_box` with normalized coordinates.
- Join: `image_id`; validation coverage `3166/3166` unique images; 20/20 HF validation rows matched.
- Recommendation: proceed to sidecar conversion.
- Archived:
  - `ara/trace/worker-captures/pg-textvqa-ocr-geometry-worker-final.txt`
  - `ara/trace/worker-captures/pg-textvqa-ocr-geometry-worker-report.md`

### `pg-ocr-win-curriculum-worker`

- Worktree: `/home/zsm/pg-worktrees/ocr_win_curriculum`
- Branch: `exp/ocr-win-curriculum`
- Commit: `101959c882dd9d05be79668f80456da038c01c77`
- Run root: `/data/zsm/parameter-golf/runs/analysis_ocr_win_curriculum_20260605_114715`
- Verdict: blocked/drop
- Counts:
  - OCR16 better: `229`
  - baseline better: `149`
  - tied: `4622`
- Critical signal check:
  - gold answer in OCR: OCR16 wins `76.86%`, baseline wins `75.17%`
  - prediction in OCR: OCR16 wins `65.50%`, baseline wins `65.10%`
- Interpretation: available subset labels do not separate OCR-benefit from OCR-regression samples; reweighting would up-weight wins and losses together.
- Recommendation: do not launch curriculum/reweighting training.
- Archived:
  - `ara/trace/worker-captures/pg-ocr-win-curriculum-worker-final.txt`
  - `ara/trace/worker-captures/pg-ocr-win-curriculum-worker-report.md`

## Exploration Tree Updates

Updated `ara/trace/exploration_tree.yaml`:

- `exp-ocr-layout-serialization-feasibility`: `blocked` for current `lmms-lab/textvqa` cache.
- `exp-textvqa-ocr-geometry-acquisition`: `completed`, source verified.
- Added `exp-ocr-geometry-sidecar-conversion`: planned next engineering gate.
- `exp-ocr-layout-serialized-training`: remains blocked until sidecar conversion and real-box serialization preview pass.
- `exp-ocr-win-curriculum`: `blocked`, recommendation `drop`.

## Recommended Next Steps

1. Dispatch a sidecar conversion worker:
   - download `/data/zsm/parameter-golf/external/textvqa/TextVQA_Rosetta_OCR_v0.2_train.json`
   - join Rosetta OCR geometry to current examples by `image_id`
   - write sidecar/prepared data under `/data/zsm/parameter-golf/data/`
   - verify train/val coverage and token-to-box alignment
2. Rerun layout feasibility using real boxes:
   - produce 20-sample serialization preview from real boxes
   - choose compact tags to avoid prompt bloat
3. Only after sidecar and preview pass, dispatch layout-serialized train + matched eval:
   - acceptance threshold: at least `+0.003` over OCR16 aligned eval
4. Do not spend GPU on OCR-win curriculum/reweighting unless a new non-leaky feature strongly separates wins from losses.

## Resource Status

- No new GPU training/eval was launched during the final pre-noon window.
- All work after 11:30 was CPU-only data/schema analysis or ARA record work.
- `smYuHangLab2` shared-process policy was respected; no unrelated process was killed or signaled.
