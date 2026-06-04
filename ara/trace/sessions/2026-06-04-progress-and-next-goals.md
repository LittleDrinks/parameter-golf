# 2026-06-04 Progress briefing and next goals

## Context

User asked for the current research progress and next-stage objectives.

This turn used only local ARA records:

```text
ara/logic/problem.md
ara/logic/hypotheses.md
ara/trace/exploration_tree.yaml
ara/evidence/results.csv
ara/trace/sessions/*.md
ara/trace/worker-captures/pg-progress-ledger-final.txt
ara/trace/worker-captures/pg-stage3-sample-evidence-repair-final.txt
```

No server inspection, code edits, GPU jobs, or new experiments were launched.

## Progress summary

The records branch is clean and remains on `ara-records-only`.

Confirmed numeric state:

```text
baseline seed1 textvqa_val      0.7085800000000037
baseline seed2 textvqa_val      0.7112000000000038
baseline seed3 textvqa_val      0.7082400000000038
ocr16_seed1 textvqa_val         0.7076800000000036
ocr16_seed1 textvqa_val_ocr     0.7262000000000036
baseline seed2 textvqa_val_ocr  0.7133600000000039
```

Current interpretation:

- Harness reliability gate passed after three hardened worker tasks with durable prompt/capture/run-root metadata and no cross-run interference.
- Original `ocr16_seed1` non-improvement is best explained by train/eval mismatch: OCR-conditioned training was evaluated with `textvqa_val`, whose OCR input is disabled.
- Aligned `textvqa_val_ocr` eval supports continuing OCR as one branch: OCR16 beats baseline seed2 by `+0.012840000000000036`.
- Stage 3 sample evidence is repaired and aggregate-consistent: 5000 samples, OCR16 better on 229, baseline seed2 better on 149, tied on 4622.
- OCR is no longer the sole mainline. The active portfolio now includes answer-style controls, data/instruction audit, visual-grounding failure taxonomy, seed robustness controls, and LoRA/training-policy search.

## Decisions

- Do not launch new training until cheap falsifying checks reduce ambiguity around prompt style, seed variance, and sample-level failure type.
- Treat OCR16 as promising but not sufficient evidence for a high-ceiling direction by itself.
- Next-stage work should prioritize eval-only and offline analysis tasks before new LoRA/OCR variants.

## Next goals

Primary next-stage objective:

```text
Determine whether the current OCR16 aligned gain is robust, mechanistic, and worth spending new training budget on.
```

Recommended ordered checks:

1. Answer-style/eval calibration on existing merged models.
2. Baseline seed1/seed3 aligned `textvqa_val_ocr` eval, or a cheaper subset if full eval capacity is constrained.
3. Failure taxonomy over the repaired 5000-sample artifact.
4. Offline audit for question-relevant OCR selection.
5. Only after gates 1-4: one small training variant, selected by the falsifying evidence.

Parallel non-OCR objective:

```text
Open a second path that can beat the OCR16 aligned score without relying on raw first-N OCR token prompting.
```

Candidate branches:

- answer-style/prompt controls,
- data or instruction-format augmentation audit,
- conservative LoRA/training-policy small sweep,
- visual-grounding/layout failure analysis.
