# Hypotheses

## Harness

Reliable run records will reduce wasted experiments and make small score changes interpretable.

## OCR Tokens

TextVQA often depends on image text, so controlled OCR-token prompting may improve exact match without increasing inference cost substantially.

## Answer Style

Short-answer prompt wording may affect exact-match scoring. Variants should avoid adding verbose generation.

## LoRA Hyperparameters

The baseline LoRA settings are conservative. Rank, learning rate, dropout, and target modules may shift accuracy under the same inference cost.

## Training Data

Sampling and prepared prompt strategy may affect accuracy more than larger model changes under the time budget.
## OCR16 Result Status

The first OCR16 run did not demonstrate improvement: `ocr16_seed1` scored `0.7076800000000036` exact match versus baseline seed1 `0.7085800000000037` and baseline mean `0.7093400000000037`. Current best explanation is train/eval mismatch: OCR tokens were included during training, but the run evaluated `textvqa_val` with `ocr: false`; `lmms-eval` has a separate `textvqa_val_ocr` task that was not used.

Next falsification check: evaluate the existing OCR16 merged model with `TASK=textvqa_val_ocr`, and evaluate baseline models with the same OCR eval task for a fair comparison.
