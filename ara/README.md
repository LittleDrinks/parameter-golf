# Lightweight ARA

This is a small local adaptation of the Agent-Native Research Artifact idea.

Use it to separate:

- `logic/`: hypotheses and criteria.
- `trace/`: session notes, decisions, failed ideas, and pivots.
- `evidence/`: result tables and pointers to raw run artifacts.

Only evidence-backed claims should be promoted into summaries or README updates.

## External Materials

Store external papers, dataset cards, docs, and web pages as lightweight evidence:

- Put curated notes under `ara/evidence/literature/` or `ara/evidence/external/`.
- Record source title, URL, access date, short project-specific takeaway, and which exploration node it informs.
- Do not vendor full papers, large HTML dumps, datasets, or screenshots into this records branch.
- If full external artifacts are needed, store them outside git under `/data/zsm/parameter-golf/external/` or another durable artifact root, then record only paths and checksums here.
- Exploration-tree nodes should cite the evidence note, not duplicate long excerpts.
