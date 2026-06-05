# textvqa-ocr-geometry-worker Report

## Worktree
- **Path:** `/home/zsm/pg-worktrees/textvqa_ocr_geometry`
- **Branch:** `exp/textvqa-ocr-geometry`
- **Base Commit:** `101959c882dd9d05be79668f80456da038c01c77`
- **Status:** Clean, created fresh from main

## Run Root
- **Path:** `/data/zsm/parameter-golf/runs/analysis_textvqa_ocr_geometry_20260605_114218`
- **Evidence files:**
  - `commands.log` — command history
  - `source_inventory.json` — local and external source inventory
  - `schema_samples.json` — schema and sample excerpts per source
  - `join_plan.md` — detailed join strategy and next steps
  - `status.json` — machine-readable gate verdict

## Local Paths Searched
| Path | Finding |
|------|---------|
| `/data/zsm/hf_cache/datasets/lmms-lab___textvqa` | Found. Contains arrow shards with `ocr_tokens` (text only), no bounding boxes. |
| `/data/zsm/parameter-golf/data/prepared_textvqa_qwen3vl_seed{1,2,3}` | Found. Prepared training data in arrow format; same schema as HF cache — no OCR geometry. |
| `/home/zsm/parameter-golf/results/textvqa` | Found. Model merge outputs; no OCR geometry data. |
| `/storage/data/shiyd2023/datasets/textvqa` | **Not found.** |

## External URLs Tested and Outcomes
| URL | Status | Size | Downloaded | Has OCR Geometry |
|-----|--------|------|------------|------------------|
| `https://dl.fbaipublicfiles.com/textvqa/data/TextVQA_0.5.1_val.json` | 200 OK | 3.1 MB | Yes | **No** — questions, answers, image metadata only |
| `https://dl.fbaipublicfiles.com/textvqa/data/TextVQA_Rosetta_OCR_v0.2_val.json` | 200 OK | 9.8 MB | Yes | **Yes** — `ocr_info` with `bounding_box` per token |
| `https://dl.fbaipublicfiles.com/textvqa/data/TextVQA_Rosetta_OCR_v0.2_train.json` | 200 OK | 65.8 MB | No (time) | **Yes** (same schema inferred) |
| `https://dl.fbaipublicfiles.com/pythia/data/imdb/textvqa_0.5.tar.gz` | 200 OK | 28.0 MB | Yes | **Yes** — `.npy` entries contain `ocr_info` with `bounding_box` |

## Artifacts Downloaded
| File | Path | Size | SHA256 |
|------|------|------|--------|
| TextVQA_0.5.1_val.json | `/data/zsm/parameter-golf/external/textvqa/TextVQA_0.5.1_val.json` | 3.0 MB | `4ceb5aadc1a41719d0a3e4dfdf06838bcfee1db569a9a65ee67d31c99893081d` |
| TextVQA_Rosetta_OCR_v0.2_val.json | `/data/zsm/parameter-golf/external/textvqa/TextVQA_Rosetta_OCR_v0.2_val.json` | 9.4 MB | `5fe60362e43381e10b29bf25cc84bb0cebcabf155a32e7121208b51a5a02715c` |
| textvqa_0.5.tar.gz | `/data/zsm/parameter-golf/external/textvqa/textvqa_0.5.tar.gz` | 27 MB | `1f06a390bbc840310a6fcaa72776cc40` (md5 from header) |

## Schema / Key Findings

### 1. `lmms-lab___textvqa` HF Cache (Current Baseline)
- **Fields:** `image_id`, `question_id`, `question`, `answers`, `ocr_tokens`, `image_width`, `image_height`, ...
- **OCR:** `ocr_tokens` is a list of strings only. **No bounding boxes.**
- **Key:** `image_id` (string), `question_id` (int)
- **Val split:** 5,000 questions across 3,166 unique images

### 2. `TextVQA_Rosetta_OCR_v0.2_val.json` (Primary Geometry Source)
- **Top-level:** `data` array of objects
- **Per-image fields:** `image_id`, `ocr_tokens`, `ocr_info`
- **`ocr_info` schema:**
  ```json
  {
    "word": "string",
    "bounding_box": {
      "top_left_x": "float (normalized 0-1)",
      "top_left_y": "float (normalized 0-1)",
      "width": "float (normalized 0-1)",
      "height": "float (normalized 0-1)",
      "rotation": "float",
      "roll": "float",
      "pitch": "float",
      "yaw": "float"
    }
  }
  ```
- **Confidence scores:** Not present.
- **Val split:** 3,166 entries (one per image)

### 3. MMF/Pythia `.npy` imdb (Fallback Source)
- Contains same `ocr_tokens` + `ocr_info` structure
- Less convenient (numpy pickle, preprocessed records)

## Join Feasibility Verdict

**✅ JOIN FEASIBLE — 100% coverage verified**

- **Join key:** `image_id` (string)
- **Coverage:** All 3,166 unique val image_ids from HF cache are present in Rosetta OCR JSON
- **Sample verification:** 20/20 random HF validation rows matched Rosetta OCR by `image_id`
- **Cardinality:** Rosetta OCR is 1 entry per image; HF cache is 1 row per question. Join is `image_id` 1:N.
- **Coordinate system:** Boxes are normalized (0-1). Pixel coordinates can be recovered using `image_width` and `image_height` from HF cache.

## Recommendation

**PROCEED TO SIDECAR CONVERSION**

The OCR geometry blocker is resolved. A concrete source (`TextVQA_Rosetta_OCR_v0.2_{split}.json`) has been located, downloaded, and verified to contain token-level bounding boxes keyed by `image_id` with 100% coverage.

### Immediate Next Steps
1. Download `TextVQA_Rosetta_OCR_v0.2_train.json` (65.8MB) to complete the train split
2. Write a preprocessing script that:
   - Loads Rosetta OCR JSON into an `image_id -> ocr_info` dict
   - Iterates over the HF `lmms-lab___textvqa` dataset
   - Attaches `ocr_info` to each row via `image_id` lookup
   - Handles any `ocr_tokens` length mismatches with a text-alignment fallback
3. Produce a new prepared dataset under `/data/zsm/parameter-golf/data/prepared_textvqa_ocr_geometry_{config}/`
4. Verify: `len(ocr_tokens) == len(ocr_info)` for all rows; spot-check bounding box coordinates

### Risks
- `ocr_tokens` from Rosetta OCR may not perfectly align with HF `ocr_tokens` (different post-processing). Index-based alignment is the first attempt; text-matching fallback may be needed.
- No confidence scores are available to filter low-quality OCR detections.

---

DONE textvqa-ocr-geometry-worker
