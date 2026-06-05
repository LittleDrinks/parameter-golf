# ocr-layout-feasibility-worker Report

## Worktree
- **Path:** `/home/zsm/pg-worktrees/ocr_layout_feasibility`
- **Branch:** `exp/ocr-layout-feasibility`
- **Commit:** `101959c882dd9d05be79668f80456da038c01c77`
- **Status:** Clean, dedicated worktree

## Run Root
- **Path:** `/data/zsm/parameter-golf/runs/analysis_ocr_layout_feasibility_20260605_112829`
- **Evidence files:**
  - `commands.log`
  - `field_inventory.json`
  - `serialization_preview.jsonl`
  - `serialization_preview.md`
  - `patch_plan.md`
  - `status.json`

## Inspected Code Paths
1. `/home/zsm/pg-worktrees/ocr_layout_feasibility/prepare_textvqa.py`
   - Loads `ocr_tokens` from dataset as `List[str]`
   - Builds question with flat `Reference OCR token: tok1, tok2, ...`
   - No layout or geometry handling
2. `/home/zsm/pg-worktrees/ocr_layout_feasibility/lmms-eval/lmms_eval/tasks/textvqa/utils.py`
   - `textvqa_doc_to_text` also accesses `doc["ocr_tokens"]` as flat list
   - No bounding box access
3. TextVQA YAMLs:
   - `_default_template_textvqa.yaml`: `dataset_path: lmms-lab/textvqa`
   - `textvqa_val_ocr.yaml`: Adds `ocr: true`, `ocr_max_tokens: 16`
   - `textvqa_val.yaml`: Default eval without OCR

## Inspected Data Paths
- **HF cache:** `/data/zsm/hf_cache/datasets/lmms-lab___textvqa/default/0.0.0/9c0699cd19768ac5ab97568f6b3cbac4c0062884`
- **Prepared data:** `/data/zsm/parameter-golf/data/textvqa_train.parquet`
- **Original dataset path:** `/storage/data/shiyd2023/datasets/textvqa` — **NOT FOUND**

## Field Inventory Summary
| Field | Type | Available | Notes |
|-------|------|-----------|-------|
| `ocr_tokens` | `List[str]` | ✅ Yes | Flat strings, no geometry |
| `ocr_bounding_boxes` | — | ❌ **NO** | Stripped in lmms-lab version |
| `ocr_confidence` | — | ❌ **NO** | Not present |
| `image_width` | `int32` | ✅ Yes | Available for normalization if boxes existed |
| `image_height` | `int32` | ✅ Yes | Available for normalization if boxes existed |
| `question` | `str` | ✅ Yes | Standard |
| `answers` | `List[str]` | ✅ Yes | 10 answers per question |
| `question_id` | `int32` | ✅ Yes | Unique identifier |
| `image_id` | `str` | ✅ Yes | Unique identifier |
| `image` | `Image` | ✅ Yes | JPEG bytes |

### OCR Token Distribution (validation split, n=5000)
- Min: 0 tokens (115 examples)
- Max: 95 tokens
- Most common: 2–5 tokens
- Examples with >16 tokens: **1,291** (~25.8%)

## Feasibility Verdict

### ❌ BLOCKED

**Reason:** The cached `lmms-lab/textvqa` dataset does not expose OCR bounding boxes, confidence scores, or any spatial metadata. The `ocr_tokens` field is a flat list of strings with no documented spatial ordering. Without box coordinates, no layout-aware serialization is possible.

### Closest Available Fields
- `ocr_tokens`: List of OCR text strings (present, but geometry-free)
- `image_width` / `image_height`: Image dimensions (present, but useless without boxes)
- `ocr_info`: Present in the original `facebook/textvqa` dataset, but stripped in the `lmms-lab` processed version used by this codebase.

### What Would Be Needed
1. **Option A (recommended):** Switch to the original `facebook/textvqa` dataset, which includes `ocr_info` with `word` and `bounding_box` fields per token. This requires network access to download/cache the dataset on the server.
2. **Option B:** Pre-compute OCR with an external engine (EasyOCR, PaddleOCR) over all 39,336 images and store boxes in a new Parquet file. CPU-heavy and may drift from original Rosetta OCR.
3. **Option C:** Use list index as a weak spatial proxy. Not recommended — list order is not documented as spatial and would likely add noise.

## Sample Preview Paths
- Run-root JSONL: `/data/zsm/parameter-golf/runs/analysis_ocr_layout_feasibility_20260605_112829/serialization_preview.jsonl`
- Run-root Markdown: `/data/zsm/parameter-golf/runs/analysis_ocr_layout_feasibility_20260605_112829/serialization_preview.md`

The previews show 20 records with raw OCR tokens and **hypothetical** layout serialization using mock bounding boxes. They demonstrate what the serialization would look like if real boxes were available.

## Patch Plan Summary
If bounding boxes become available, the shared helper would:
1. Normalize box coordinates to `[0,1]` using `image_width` and `image_height`
2. Compute center point of each box
3. Bin centers into an 8×8 grid (`x0..x7`, `y0..y7`)
4. Serialize as: `<ocr x=1 y=0> sale; <ocr x=4 y=3> 50%; <ocr x=6 y=7> off`
5. Cap at `max_ocr_tokens=16`
6. Share the helper between `prepare_textvqa.py` (train) and `lmms-eval/.../utils.py` (eval)

Full pseudocode and integration points are in `patch_plan.md`.

### Risk Note
Layout tags add ~10 chars per token. With 16 tokens, the prompt grows by ~160 tokens. For context-limited models, a compact tag format (e.g., `[1,0]sale`) should be considered.

## Blockers
1. **Primary:** `ocr_bounding_boxes` missing from cached `lmms-lab/textvqa` dataset.
2. **Secondary:** Server has no outbound network access to download `facebook/textvqa`.
3. **Tertiary:** 25.8% of validation examples have >16 OCR tokens, so truncation is already a concern; adding layout tags exacerbates prompt length pressure.

## Recommendation

### STOP — Do not proceed to implementation/training on this direction.

The `exp-ocr-layout-serialization-feasibility` gate is **not passable** with the current cached dataset. Before any layout-aware OCR training can begin, the team must:

1. Decide whether to source bounding boxes from the original `facebook/textvqa` dataset (requires network access or pre-downloading on a machine with internet) or to re-OCR all images with an engine that produces boxes.
2. Once bounding box data is available, re-run a lightweight feasibility check to confirm the serialization format and token budget are viable.
3. Only then should implementation and full training be scheduled.

Until bounding box data is secured, this direction should be deprioritized in favor of directions that do not require additional data fields.

---

DONE ocr-layout-feasibility-worker
