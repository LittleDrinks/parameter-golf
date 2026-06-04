# 2026-06-04 Ralph-loop worker batch 1

## Context

Continued the active ralph-loop goal:

```text
Complete the next parameter-golf research loop with parallel worker exploration, archived rmux evidence, resolved development blockers, atomic commits, and remote experiment worktrees pushed as organized GitHub branches.
```

User cautioned that `smYuHangLab2` is a shared GPU server, so the loop should not parallelize GPU work aggressively.

## Resource policy

Decision: parallelize CPU-only/offline analysis, but serialize GPU eval/training.

GPU launch rule for this loop:

```text
Before any GPU task: check zsm processes and nvidia-smi.
Run at most one zsm GPU eval/training task at a time.
Prefer GPU2 only when memory.used < 1000 MiB and no competing user need is visible.
```

No GPU tasks were launched in this batch.

## Cleanup

Old local rmux worker panes were archived and closed:

```text
pg-eval-baseline-ocr
pg-eval-ocr16
pg-ocr-analysis
pg-stage3-sample-evidence
pg-stage3-sample-evidence-repair
```

Archive files:

```text
ara/trace/worker-captures/pg-eval-baseline-ocr-stale-archive-20260604_213822.txt
ara/trace/worker-captures/pg-eval-ocr16-stale-archive-20260604_213822.txt
ara/trace/worker-captures/pg-ocr-analysis-stale-archive-20260604_213822.txt
ara/trace/worker-captures/pg-stage3-sample-evidence-stale-archive-20260604_213822.txt
ara/trace/worker-captures/pg-stage3-sample-evidence-repair-stale-archive-20260604_213822.txt
```

After worker batch completion, all new worker panes were also final-captured and closed. `rmux list-sessions` reported no server.

## Parallel worker batch

Four CPU-only workers were dispatched through `panel-as-worker`:

```text
pg-answer-style-audit
pg-seed-robustness-preflight
pg-failure-taxonomy
pg-data-audit
```

Prompt/capture evidence is under:

```text
ara/trace/worker-captures/
```

Final closed captures:

```text
ara/trace/worker-captures/pg-answer-style-audit-closed-20260604_220003.txt
ara/trace/worker-captures/pg-seed-robustness-preflight-closed-20260604_220003.txt
ara/trace/worker-captures/pg-failure-taxonomy-closed-20260604_220003.txt
ara/trace/worker-captures/pg-data-audit-closed-20260604_220003.txt
```

## Results

### Answer-style audit

Remote artifact:

```text
/data/zsm/parameter-golf/runs/analysis_answer_style_audit/answer_style_audit.md
/data/zsm/parameter-golf/runs/analysis_answer_style_audit/status.json
```

Findings:

- `max_new_tokens` is the smallest zero-code eval-only control, via `--gen_kwargs`.
- `post_prompt`, `pre_prompt`, and `ocr_max_tokens` require a custom task YAML plus `--include_path`.
- `until` token changes and `--apply_chat_template` should be dropped as control variables.
- Every matrix row still requires serial GPU eval.
- Next smallest proposed GPU check: OCR16 `textvqa_val_ocr` with `max_new_tokens=32`.

### Seed robustness preflight

Remote artifact:

```text
/data/zsm/parameter-golf/runs/analysis_seed_robustness_preflight/seed_robustness_preflight.md
/data/zsm/parameter-golf/runs/analysis_seed_robustness_preflight/status.json
```

Findings:

- Baseline seed1 and seed3 merged model paths exist.
- Aligned `textvqa_val_ocr` result JSONs for seed1/seed3 are missing.
- GPU eval plan is serial: seed1 first, seed3 after completion.
- Start only if GPU2 is free and no `zsm` eval/training job is active.

### Failure taxonomy

Remote artifact:

```text
/data/zsm/parameter-golf/runs/analysis_failure_taxonomy/failure_taxonomy.md
/data/zsm/parameter-golf/runs/analysis_failure_taxonomy/summary.json
```

Findings:

- OCR16 better: 229.
- Baseline seed2 better: 149.
- Tied: 4622.
- OCR16-win gold-in-OCR fraction: 0.8079.
- Baseline-win gold-in-OCR fraction: 0.7987.
- In baseline wins, OCR16's wrong prediction was present in OCR tokens in 0.5235 of cases.

Interpretation: this weakens question-relevant OCR selection as the immediate next training bet; answer-style and seed robustness checks should precede OCR-selection training.

Caveat: worker wrote `summary.json` and `failure_taxonomy.md` but not `status.json`.

### Data audit

Remote artifact:

```text
/data/zsm/parameter-golf/runs/analysis_data_audit/data_audit.md
/data/zsm/parameter-golf/runs/analysis_data_audit/status.json
```

Findings:

- Locally available data is effectively TextVQA: HF cache, train parquet, and prepared TextVQA datasets.
- DocVQA, ST-VQA, TextOCR, OCR-VQA, OCRBench, and external instruction data are unavailable locally or require network/download work.
- Recommended smallest non-OCR data check is a prompt-template ablation on existing TextVQA rather than adding a new dataset.

## Blockers flattened

- Shared GPU contention: converted to a serial GPU policy.
- Old rmux panes: archived and closed.
- `textvqa_val_ocr.yaml` hardcoded `/storage` path: known config blocker; current eval worktree patch remains required.
- Missing seed1/seed3 aligned OCR evals: converted to serial launch plan.
- Failure taxonomy missing `status.json`: record caveat; normalize in a later artifact hygiene pass if needed.
- Worker shell/heredoc quoting issues: observed in data-audit and answer-style; workers recovered and wrote verified artifacts.

## Next actions

1. Commit this worker batch's prompts, captures, and ARA updates.
2. Push the local ARA branch.
3. If GPU2 is still free, launch only one serial GPU eval next:
   - either baseline seed1 `textvqa_val_ocr` for robustness,
   - or OCR16 `max_new_tokens=32` for answer-style calibration.
4. Organize/push remote code worktree branches after deciding whether the next action is eval config-only or code/config change.

## Server credential policy

User clarified that `smYuHangLab2` is a public/shared server and should not have GitHub credentials. Remote experiment worktrees should still be committed locally on the server branch, but a failed `git push` from the server is expected and should not be treated as an infrastructure bug. Push can be done manually by the user from the VS Code credential environment, or Codex should report the branch/commit for manual publication.

## Seed1 OCR eval follow-up

After the CPU-only worker batch, one serial GPU eval was launched because GPU2 was free and no `zsm` train/eval process was active.

Run:

```text
run_id: eval_baseline_seed1_textvqa_val_ocr
worktree: /home/zsm/pg-worktrees/pg-seed-robustness-ocr
branch: exp/seed-robustness-ocr
commit: d659cbdf335a66f43e835dd2c3899ff76edeb5d6
base_commit: 101959c882dd9d05be79668f80456da038c01c77
task: textvqa_val_ocr
model: /data/zsm/parameter-golf/outputs/textvqa_qwen3vl_lora_seed1/merged
run_root: /data/zsm/parameter-golf/runs/eval_baseline_seed1_textvqa_val_ocr
result_json: /data/zsm/parameter-golf/runs/eval_baseline_seed1_textvqa_val_ocr/eval/textvqa_qwen3vl_lora_seed1__merged/20260604_221119_results.json
exact_match: 0.7134200000000036
stderr: 0.006032748920011863
```

Safety:

- One GPU job only.
- No training.
- No seed3 launch.
- No unrelated process kill.
- GPU2 used approximately 4.6 GiB for PID `2771710`.

Interpretation:

Baseline seed1 and seed2 aligned OCR evals are effectively tied:

```text
seed1 textvqa_val_ocr = 0.7134200000000036
seed2 textvqa_val_ocr = 0.7133600000000039
```

OCR16 remains ahead of the best observed aligned baseline by:

```text
0.7262000000000036 - 0.7134200000000036 = 0.012780000000000035
```

Remaining seed robustness gap: baseline seed3 aligned OCR eval is still missing.
