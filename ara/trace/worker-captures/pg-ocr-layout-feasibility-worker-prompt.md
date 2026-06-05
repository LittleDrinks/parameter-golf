Role:
ocr-layout-feasibility-worker

Goal:
Test feasibility of the next active ARA gate `exp-ocr-layout-serialization-feasibility`: determine whether cached TextVQA data exposes usable OCR token boxes/order and produce a concrete shared train/eval serialization plan. Do not train.

Server:
Use `ssh smYuHangLab2`.

Allowed files:
- Create or reuse only if clean: `/home/zsm/pg-worktrees/ocr_layout_feasibility`
- Create a run root: `/data/zsm/parameter-golf/runs/analysis_ocr_layout_feasibility_<timestamp>`
- Write local worker report: `agent-runs/ocr-layout-feasibility-worker-report.md`

Forbidden actions:
- Do not launch training or lmms_eval full evaluation.
- Do not use GPUs.
- Do not kill or signal processes.
- Do not configure GitHub credentials on `smYuHangLab2`.
- Do not edit the ARA records branch.
- Do not write datasets, checkpoints, or large artifacts into git.

Worktree requirement:
1. Ensure `/home/zsm/pg-worktrees/ocr_layout_feasibility` is a dedicated git worktree.
2. Preferred branch: `exp/ocr-layout-feasibility`
3. Preferred base commit: `101959c882dd9d05be79668f80456da038c01c77`
4. If the worktree exists, use it only if clean and on the right branch; otherwise stop and report.

Tasks:
1. Inspect current code paths:
   - `/home/zsm/pg-worktrees/ocr_layout_feasibility/prepare_textvqa.py`
   - `/home/zsm/pg-worktrees/ocr_layout_feasibility/lmms-eval/lmms_eval/tasks/textvqa/utils.py`
   - relevant TextVQA task YAMLs.
2. Inspect cached TextVQA validation/train data schemas without downloading new data if possible:
   - Hugging Face cache under `/data/zsm/hf_cache`
   - existing prepared data/output directories under `/data/zsm/parameter-golf` and `/home/zsm/parameter-golf`
3. Determine whether examples expose:
   - OCR token text
   - OCR token order
   - OCR bounding boxes or equivalent geometry
   - image dimensions if needed for normalization
4. If usable fields exist, create a small script under the run root (not git) that writes:
   - `field_inventory.json`
   - `serialization_preview.jsonl` with 20 records containing question, answers, raw OCR tokens, raw boxes if present, and proposed serialized OCR string.
   - `serialization_preview.md` with 5 readable examples.
5. If fields do not exist, write a precise blocker report identifying the closest available fields and what would be needed.
6. Produce a patch plan for a shared helper that both train and eval can use. Include exact target files and pseudocode, but do not implement training/eval code unless it is a small read-only prototype script under the run root.

Serialization idea to evaluate:
- Coarse grid bins are enough for the first attempt, e.g. normalize boxes into `x0..x7`, `y0..y7`.
- Example shape:
  `Reference OCR tokens with layout: [top-left] sale; [center] 50%; [bottom-right] off`
  or
  `<ocr x=1 y=0> sale; <ocr x=4 y=3> 50%; <ocr x=6 y=7> off`
- Keep the text short enough for max_ocr_tokens=16.

Required run-root evidence:
- `commands.log`
- `field_inventory.json`
- `serialization_preview.jsonl` if feasible
- `serialization_preview.md` if feasible
- `patch_plan.md`
- `status.json`

Required final report:
Write `agent-runs/ocr-layout-feasibility-worker-report.md` with:
- worktree path, branch, commit
- run root
- inspected data/code paths
- field inventory summary
- feasibility verdict
- sample preview paths
- patch plan summary
- blockers if any
- recommendation: proceed to implementation/training or stop

Required final line:
DONE ocr-layout-feasibility-worker
