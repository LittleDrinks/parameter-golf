# External Source Notes: TextVQA OCR Geometry

Purpose: lightweight evidence for locating OCR token geometry needed by `exp-ocr-layout-serialization-feasibility`. Store source pointers and project-specific implications only; do not vendor source JSONs or images into this records branch.

Access date: 2026-06-05

## Sources

| id | source | URL | project-relevant takeaway |
|---|---|---|---|
| EXT-TEXTVQA-SITE | TextVQA dataset page | https://textvqa.org/dataset/ | The site states that v0.5.1 keeps updated Rosetta OCR tokens in a separate JSON file; this is the most likely source for `ocr_info`/bounding boxes missing from the current `lmms-lab/textvqa` cache. |
| EXT-HF-FACEBOOK-TEXTVQA | Hugging Face `facebook/textvqa` dataset card | https://huggingface.co/datasets/facebook/textvqa | The HF card exposes TextVQA examples and image metadata, but the listed fields do not include OCR geometry; its loader downloads `TextVQA_0.5.1_{split}.json` annotations and images. |
| EXT-HF-FACEBOOK-TEXTVQA-SCRIPT | Hugging Face `facebook/textvqa` loader script | https://huggingface.co/datasets/facebook/textvqa/blob/main/textvqa.py | The loader's feature schema includes question, answers, image dimensions, and image classes but no `ocr_info`; using this loader alone probably will not recover boxes. |
| EXT-FBA-ANNOTATION-URLS | TextVQA public annotation URLs referenced by HF loader | https://dl.fbaipublicfiles.com/textvqa/data/TextVQA_0.5.1_val.json | Annotation JSONs are small enough to mirror outside git, but may not include the separated OCR JSON; workers should test direct local download and inspect keys before any training work. |
| EXT-MMF-PYTHIA-IMDB | MMF/Pythia TextVQA imdb package | https://dl.fbaipublicfiles.com/pythia/data/imdb/textvqa_0.5.tar.gz | Old MMF artifacts may contain preprocessed TextVQA records with OCR fields; this is a plausible fallback if the current TextVQA site OCR JSON URL is hard to locate. |

## Current Interpretation

1. The immediate layout-serialization implementation is blocked by local cache schema, not by the model or prompt helper.
2. `facebook/textvqa` through the public HF loader is unlikely to solve the blocker by itself because the loader schema omits OCR geometry.
3. The highest-probability unblock is to locate and cache the TextVQA v0.5.1 separated OCR JSON or MMF/Pythia imdb records outside git, then rerun the field inventory gate.
4. Until a worker verifies a concrete file with token text plus boxes keyed by `image_id` or `question_id`, layout-aware training should remain blocked.

## Storage Policy

If a worker downloads OCR JSONs, tarballs, or metadata, store them under:

```text
/data/zsm/parameter-golf/external/textvqa/
```

Record only file paths, sizes, SHA256 checksums, source URLs, and schema excerpts in ARA.
