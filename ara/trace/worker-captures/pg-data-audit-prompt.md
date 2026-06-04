Role:
data-audit

Goal:
Explore a non-OCR branch by auditing available TextVQA-like data or instruction sources without training. CPU-only.

Resource policy:
- smYuHangLab2 is a shared GPU server.
- This task must not use GPU/CUDA.
- Do not kill processes.

Allowed remote read-only paths:
- `/data/zsm`
- `/home/zsm/parameter-golf`
- `/home/zsm/pg-worktrees`

Allowed remote write path:
- `/data/zsm/parameter-golf/runs/analysis_data_audit`

Forbidden actions:
- Do not run training or eval.
- Do not download datasets from the internet.
- Do not edit git worktrees.
- Do not push branches.
- Do not delete files.

Task:
1. Inventory locally cached datasets or prepared files that may support TextVQA-like short-answer training, especially TextVQA, ST-VQA, TextCaps, TextOCR, OCR-VQA, or existing prepared prompt data.
2. For each candidate, record:
   - path,
   - approximate size/count if cheap to inspect,
   - fields available,
   - whether answers are short and exact-match compatible,
   - whether OCR tokens/layout fields exist,
   - conversion blockers.
3. Identify one smallest non-OCR data/instruction augmentation check that could be run later without contaminating existing runs.
4. Write `/data/zsm/parameter-golf/runs/analysis_data_audit/data_audit.md` and `status.json`.

Required final line:
DONE data-audit
