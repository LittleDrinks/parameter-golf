Role:
ocr-win-curriculum-worker

Goal:
Test ARA gate `exp-ocr-win-curriculum`: use existing Stage 3 sample evidence to decide whether OCR-benefit and OCR-regression subsets can support a high-probability curriculum/reweighting experiment. Do not train.

Server:
Use `ssh smYuHangLab2`.

Allowed files:
- Create or reuse only if clean: `/home/zsm/pg-worktrees/ocr_win_curriculum`
- Create a run root: `/data/zsm/parameter-golf/runs/analysis_ocr_win_curriculum_<timestamp>`
- Read existing Stage 3 evidence under `/data/zsm/parameter-golf/runs/stage3_textvqa_val_ocr_sample_evidence`
- Read failure taxonomy under `/data/zsm/parameter-golf/runs/analysis_failure_taxonomy` if useful
- Write local worker report: `agent-runs/ocr-win-curriculum-worker-report.md`

Forbidden actions:
- Do not launch training or lmms_eval full evaluation.
- Do not use GPUs.
- Do not kill or signal processes.
- Do not configure GitHub credentials on `smYuHangLab2`.
- Do not edit the ARA records branch.
- Do not write datasets, checkpoints, or large artifacts into git.

Worktree requirement:
1. Ensure `/home/zsm/pg-worktrees/ocr_win_curriculum` is a dedicated git worktree.
2. Preferred branch: `exp/ocr-win-curriculum`
3. Preferred base commit: `101959c882dd9d05be79668f80456da038c01c77`
4. If the worktree exists, use it only if clean and on the right branch; otherwise stop and report.

Context:
- OCR16 aligned eval beats the best baseline seed3 aligned OCR eval by about +0.01078 exact_match.
- Stage 3 evidence path:
  `/data/zsm/parameter-golf/runs/stage3_textvqa_val_ocr_sample_evidence/samples_textvqa_val_ocr_ocr16_vs_baseline_seed2.jsonl`
- Stage 3 summary:
  OCR16 better 229, baseline seed2 better 149, tied 4622.
- Prior failure taxonomy found similar gold-in-OCR overlap for OCR16 wins and baseline wins, so naive question-relevant OCR selection is weakened.

Tasks:
1. Create the dedicated worktree if missing, without touching the main checkout.
2. Create run root and `commands.log`.
3. Inspect the Stage 3 JSONL schema and summary.
4. Define reproducible candidate subset labels using only available fields. Examples:
   - `ocr16_better`
   - `baseline_better`
   - `gold_answer_in_ocr`
   - `ocr16_pred_in_ocr`
   - `baseline_pred_in_ocr`
   - question length / OCR token count bins
   - answer normalization category if available
5. Compute counts and overlaps for candidate subsets. Include at least:
   - OCR16-better subset size
   - baseline-better guard subset size
   - tied subset size
   - fraction with gold answer in OCR
   - fraction where losing prediction appears in OCR
6. Decide whether a curriculum/reweighting training patch is justified by stable subset definitions.
7. If justified, write a patch plan only, not code:
   - where to add sample weights or sampler logic
   - how to keep train/eval prompt identical
   - proposed weights, e.g. mild 1.5x to 2x for OCR-benefit examples and guard eval on baseline-better set
   - acceptance criterion for a full training run
8. Write run-root evidence:
   - `commands.log`
   - `subset_summary.json`
   - `subset_examples.jsonl` with at most 50 examples
   - `patch_plan.md`
   - `status.json`

Required final report:
Write `agent-runs/ocr-win-curriculum-worker-report.md` with:
- worktree path, branch, commit
- run root
- evidence paths read
- subset definitions
- counts and strongest signals
- feasibility verdict
- patch plan summary or precise blocker
- recommendation: launch a full training worker, revise subset definitions, or drop this direction

Required final line:
DONE ocr-win-curriculum-worker
