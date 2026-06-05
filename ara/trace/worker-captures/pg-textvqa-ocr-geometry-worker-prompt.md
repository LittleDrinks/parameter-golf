Role:
textvqa-ocr-geometry-worker

Goal:
Test ARA gate `exp-textvqa-ocr-geometry-acquisition`: locate and verify a concrete TextVQA OCR geometry artifact containing OCR token text plus bounding boxes, then produce a join plan back to the current `lmms-lab/textvqa` examples. Do not train.

Server:
Use `ssh smYuHangLab2`.

Allowed files:
- Create or reuse only if clean: `/home/zsm/pg-worktrees/textvqa_ocr_geometry`
- Create a run root: `/data/zsm/parameter-golf/runs/analysis_textvqa_ocr_geometry_<timestamp>`
- Store external downloaded artifacts, if any, under `/data/zsm/parameter-golf/external/textvqa/`
- Write local worker report: `agent-runs/textvqa-ocr-geometry-worker-report.md`

Forbidden actions:
- Do not launch training or lmms_eval full evaluation.
- Do not use GPUs.
- Do not kill or signal processes.
- Do not configure GitHub credentials on `smYuHangLab2`.
- Do not edit the ARA records branch.
- Do not write datasets, checkpoints, or large artifacts into git.
- Do not repeatedly retry large downloads. If network fails, record the exact failure and pivot to local cache/search.

Worktree requirement:
1. Ensure `/home/zsm/pg-worktrees/textvqa_ocr_geometry` is a dedicated git worktree.
2. Preferred branch: `exp/textvqa-ocr-geometry`
3. Preferred base commit: `101959c882dd9d05be79668f80456da038c01c77`
4. If the worktree exists, use it only if clean and on the right branch; otherwise stop and report.

Context:
- `lmms-lab/textvqa` cache has `ocr_tokens` only, no boxes.
- Literature notes live locally in ARA at `ara/evidence/external/textvqa_ocr_geometry_sources.md`.
- Candidate external sources include:
  - TextVQA site: `https://textvqa.org/dataset/`
  - FBA annotations: `https://dl.fbaipublicfiles.com/textvqa/data/TextVQA_0.5.1_val.json`
  - MMF/Pythia imdb: `https://dl.fbaipublicfiles.com/pythia/data/imdb/textvqa_0.5.tar.gz`

Tasks:
1. Create the dedicated worktree if missing, without touching the main checkout.
2. Create run root and `commands.log`.
3. Inventory local cache and prior data for OCR geometry:
   - `/data/zsm/hf_cache`
   - `/data/zsm/parameter-golf`
   - `/home/zsm/parameter-golf`
   - `/storage/data/shiyd2023/datasets/textvqa` if present
4. Test direct access to the candidate external URLs with bounded commands:
   - Prefer `curl -I` or a small ranged request first.
   - If a small JSON can be downloaded safely, store it under `/data/zsm/parameter-golf/external/textvqa/` and compute sha256.
   - If a tarball is large, do not fully download unless size is reasonable and time permits before 12:00 Asia/Shanghai; otherwise record URL, headers, and likely contents.
5. Inspect schemas/keys of any local or downloaded artifact. Determine whether it includes:
   - OCR token text
   - OCR bounding boxes or equivalent polygons
   - confidence scores, if present
   - join keys: `image_id`, `question_id`, filename, or split/index
6. Compare join keys with 20 examples from cached `lmms-lab/textvqa` validation data.
7. Write run-root evidence:
   - `commands.log`
   - `source_inventory.json`
   - `schema_samples.json`
   - `join_plan.md`
   - `status.json`
8. If no geometry source can be verified, write the precise blocker and the next best route.

Required final report:
Write `agent-runs/textvqa-ocr-geometry-worker-report.md` with:
- worktree path, branch, commit
- run root
- local paths searched
- external URLs tested and outcomes
- artifacts downloaded, paths, sizes, sha256
- schema/key findings
- join feasibility verdict
- recommendation: proceed to sidecar conversion, retry with user-provided download, or pivot away from layout

Required final line:
DONE textvqa-ocr-geometry-worker
