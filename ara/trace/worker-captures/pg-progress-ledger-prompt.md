Role:
progress-ledger

Goal:
Produce a concise, read-only progress ledger for the current parameter-golf ARA records.

Allowed files:
- ara/README.md
- ara/evidence/results.csv
- ara/logic/*.md
- ara/trace/exploration_tree.yaml
- ara/trace/sessions/*.md
- ara/trace/worker-captures/*.txt

Forbidden actions:
- Do not edit files.
- Do not access the GPU server.
- Do not launch, kill, or inspect remote train/eval processes.
- Do not run web searches.
- Do not create or modify git worktrees.

Task:
Read the allowed local ARA records and produce a short report with:
1. Current confirmed numeric results, grouped by baseline/OCR/eval-only.
2. Active hypotheses and their status.
3. Evidence gaps or reliability concerns.
4. Recommended next smallest falsifying checks, explicitly separating OCR from non-OCR ideas.

Keep the report concrete. Include exact run IDs, metrics, result paths, and unresolved caveats where present.

Required final line:
DONE progress-ledger
