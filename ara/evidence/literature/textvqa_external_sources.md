# External Literature Notes: TextVQA Directions

Purpose: lightweight ARA evidence for external sources used to prioritize the next experiment queue. This file stores pointers and project-specific implications, not full paper text.

## Sources

| id | source | URL | project-relevant takeaway |
|---|---|---|---|
| LIT-TEXTVQA-LORRA | Singh et al., "Towards VQA Models That Can Read" / TextVQA + LoRRA | https://arxiv.org/abs/1904.08920 | TextVQA is explicitly about reading text in images; OCR tokens and copy/read mechanisms are central, so OCR-conditioned improvements are plausible but should be evaluated on OCR-enabled tasks. |
| LIT-M4C | Hu et al., "Iterative Answer Prediction with Pointer-Augmented Multimodal Transformers for TextVQA" / M4C | https://arxiv.org/abs/1911.06258 | Strong TextVQA systems model OCR tokens jointly with question/image context and use pointer/copy-style answer production; plain token concatenation is a weak approximation. |
| LIT-TAP | Yang et al., "TAP: Text-Aware Pre-training for Text-VQA and Text-Caption" | https://arxiv.org/abs/2012.04638 | Text-aware pretraining and OCR-aware objectives indicate higher-ceiling gains come from making image text a structured training signal, not only increasing generation length. |
| LIT-LATR | Biten et al., "LaTr: Layout-Aware Transformer for Scene-Text VQA" | https://arxiv.org/abs/2112.12494 | Layout-aware modeling is a credible direction for scene-text VQA; preserving spatial relationships between OCR tokens is likely more useful than first-N OCR token inclusion alone. |

## Current Project Implications

1. `max_new_tokens` is a low-probability direction after the OCR16 max32 control showed only `+0.00018` exact_match over max16.
2. The strongest next hypothesis is not "more OCR tokens" but "better OCR representation": include token layout/order/salience so the model can bind question terms to image text.
3. The current OCR16 win remains real against seed1-3 baselines, but sample evidence warns against naive OCR selection: OCR16 and baseline wins have similar gold-in-OCR overlap.
4. A high-probability path should combine:
   - layout-aware OCR serialization,
   - sample evidence / curriculum that emphasizes OCR-resolved failures,
   - robustness against OCR over-reliance via dropout or negative examples,
   - LoRA changes only after the data/prompt signal is sharpened.

## Proposed Experiment Queue

| priority | experiment | smallest falsifying check |
|---|---|---|
| P1 | OCR layout serialization feasibility | Verify cached TextVQA examples expose OCR boxes/order; build a small prompt sample showing serialized text+layout without launching training. |
| P2 | Layout-serialized OCR training | Full train + matched eval if feasibility passes; require `textvqa_val_ocr` > OCR16 by at least `+0.003`. |
| P3 | OCR-win curriculum/reweighting | Use Stage 3 sample evidence to define OCR-benefit and OCR-regression subsets; reject if subset definitions cannot be reproduced from durable artifacts. |
| P4 | OCR dropout robustness | Train with stochastic OCR token dropout only after the layout/curriculum data path is verified; require preserving OCR eval while improving non-OCR eval. |
| P5 | LoRA target/rank sweep | Only after data/prompt path is stable; prior LR-only change failed, so target modules/rank/dropout are more plausible than another LR-only run. |
