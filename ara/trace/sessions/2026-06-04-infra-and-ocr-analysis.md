# 2026-06-04 Project skills migration and OCR16 analysis

## Infra actions

- Confirmed the ARA skills requested earlier were installed globally under `/home/q2635/.codex/skills`:
  - `research-manager`
  - `rigor-reviewer`
  - `compiler`
- Copied those skills into project-level source folders under `skills/`.
- Created a new project skill `skills/panel-as-worker` using the skill-creator initializer.
- Migrated panel/rmux scripts from top-level `scripts/` into `skills/panel-as-worker/scripts/`:
  - `rmux_worker.sh`
  - `rmux_dashboard.sh`
  - `rmux_dashboard.py`
- Kept `agent-prompts/` as prompt-contract source material for future skill improvements.
- Validated all four project skills with `quick_validate.py`.

## Project-level skill path note

The canonical in-repo `.codex/skills` path is not writable in this session because `.codex/` is mounted read-only by the Codex harness. The repository-level skill source of truth is therefore:

```text
skills/
```

If a future environment supports writable `.codex/`, copy or symlink these skill folders into `.codex/skills`.

## OCR16 no-improvement analysis

Observed result:

```text
ocr16_seed1 exact_match = 0.7076800000000036
baseline seed1 exact_match = 0.7085800000000037
baseline mean over seeds 1-3 = 0.7093400000000037
baseline sample stdev = 0.001619753067600187
```

Delta:

```text
ocr16_seed1 - baseline_seed1 = -0.0009000000000000119
ocr16_seed1 - baseline_mean = -0.0016600000000001058
```

Primary diagnosis:

- `ocr16.yaml` trains with OCR tokens in the user prompt via `prepare_textvqa.py`:
  - `Reference OCR token: ...`
  - `Answer the question using a single word or phrase.`
- The run evaluated with `TASK=textvqa_val`, whose task config has `ocr: false` and qwen-specific prompt `post_prompt: " Answer:"`.
- `lmms-eval` already contains `textvqa_val_ocr`, with `ocr: true`, `ocr_max_tokens: 16`, and `max_new_tokens: 16`.
- Therefore `ocr16_seed1` likely trained on OCR-conditioned prompts but was evaluated on non-OCR prompts. This train/eval prompt mismatch can erase or reverse any benefit of OCR-token conditioning.

Secondary diagnoses:

- The difference is small relative to eval stderr (~0.0061) and baseline seed variability; it is not strong evidence of regression.
- OCR token ordering may include noisy or irrelevant tokens; the first 16 tokens are not necessarily question-relevant.
- TextVQA exact-match is sensitive to answer style. Training prompt uses a full sentence; qwen-specific eval for `textvqa_val` uses ` Answer:` unless OCR task is selected.
- 1024 steps over ~0.24 epoch may be too short for a new OCR-conditioned behavior to reliably emerge, especially if evaluation removes the OCR input.
- Loss is noisy but aggregate trend is downward; optimization failure is not the main explanation.

## Proposed low-cost next checks

1. Eval-only aligned check: run existing `ocr16_seed1` merged model on `TASK=textvqa_val_ocr` without retraining.
2. Fair baseline check: run baseline merged models on `TASK=textvqa_val_ocr` to see whether OCR in eval helps the base/baseline models without OCR training.
3. Prompt alignment check: make train prompt match the eval OCR task exactly, or make eval use the same post-prompt as training.
4. Answer-style check: compare `max_new_tokens=16` and explicit short-answer prompting across baseline and OCR variants.

## Candidate future directions

- Retrieval/filtering: include OCR tokens most relevant to the question rather than first N OCR tokens.
- OCR dropout: during OCR-token training, randomly drop OCR tokens some fraction of the time to avoid eval brittleness.
- Short-answer consistency: train and eval with the same post-prompt and generation length.
- Error analysis: inspect cases where baseline fails and OCR tokens contain the gold answer; prioritize variants based on recoverable examples.
- Conservative LoRA sweeps: try lower LR or constant schedule only after prompt/eval alignment is fixed.

## 2026-06-04 evening orchestration update

User asked to continue organizing metric optimization and report/plan. Local records branch was clean before this turn. Read-only server inspection found no active `zsm` train/eval/tmux/rmux sessions. GPU snapshot: GPU2 was nearly free, GPU0 had moderate memory use, GPU1/GPU3 were occupied. No new result files beyond `ocr16_seed1` were found under `/data/zsm/parameter-golf/runs`.

Planning decision: prioritize eval-only and analysis-only checks before further training. Exploration tree was extended with:

- `exp-ocr-recoverable-errors`: estimate recoverable validation failures by comparing baseline predictions, OCR tokens, and gold answers.
- `exp-answer-style-alignment`: isolate exact-match effects from prompt wording / generation limits on existing merged models.
- `exp-lora-small-sweep`: deferred until prompt/eval alignment is reliable.

No new numeric result was added to `ara/evidence/results.csv`.

## 2026-06-04 worker dispatch for OCR alignment

User asked to dispatch workers in parallel for metric optimization research.

Workers launched through rmux/panel workflow:

- `pg-eval-ocr16` / role `eval-ocr16`: created remote worktree `/home/zsm/pg-worktrees/pg-eval-ocr16-ocr` on branch `exp/eval-ocr16-ocr` at commit `101959c`. It patched only the isolated worktree copy of `lmms-eval/lmms_eval/tasks/textvqa/textvqa_val_ocr.yaml`, changing `dataset_path` from `/storage/data/shiyd2023/datasets/textvqa` to `lmms-lab/textvqa`. Current eval command uses `/home/zsm/parameter-golf/venv/bin/python -m lmms_eval`, `PYTHONPATH=/home/zsm/pg-worktrees/pg-eval-ocr16-ocr/lmms-eval`, `CUDA_VISIBLE_DEVICES=2`, model `/data/zsm/parameter-golf/runs/ocr16_seed1/outputs/merged`, task `textvqa_val_ocr`, output root `/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr`. At 2026-06-04 19:36 CST the eval was running as PID `167160`; no result JSON yet.
- `pg-eval-baseline-ocr` / role `eval-baseline-ocr`: created remote worktree `/home/zsm/pg-worktrees/pg-eval-baseline-ocr` on branch `exp/eval-baseline-ocr` at commit `101959c`. It also patched the isolated `textvqa_val_ocr.yaml` dataset path, but no baseline eval completed. It was stopped and marked pending to avoid GPU2 contention while `ocr16` eval runs.
- `pg-ocr-analysis` / role `ocr-analysis`: created remote worktree `/home/zsm/pg-worktrees/pg-ocr-analysis` on branch `exp/ocr-analysis` at commit `101959c`; completed analysis note at `/data/zsm/parameter-golf/runs/analysis_ocr_recoverable/ocr_analysis_note_2026-06-04.md`.

Important findings from the analysis worker:

- `ocr16_seed1` was trained with `use_ocr_tokens: true`, `max_ocr_tokens: 16`, but its completed score `0.7076800000000036` came from `textvqa_val`, whose eval config has `ocr: false`.
- `textvqa_val_ocr.yaml` has a server-breaking hardcoded `dataset_path: /storage/data/shiyd2023/datasets/textvqa`; that path does not exist. Isolated worktree patch to `lmms-lab/textvqa` is required for OCR eval.
- Existing result JSONs contain aggregate metrics only; submission files contain predictions but no gold answers. Recoverable-failure analysis is unavailable until TextVQA validation gold answers/OCR tokens are cached or eval stores sample-level data.
- Best recorded baseline is seed2 at `0.7112000000000038`; fair OCR comparison should use baseline seed2, not only seed1.

Operational issue:

- A baseline eval worker briefly interfered with the OCR16 eval process while trying to clear GPU2. The orchestrator stopped baseline GPU actions and restarted the OCR16 eval once. Future eval workers should not kill existing `zsm` lmms-eval processes unless their PID/run_id is explicitly assigned.

## 2026-06-04 staged metric plan and worker orchestration review

User requested a hard-metric staged plan suitable for a ralph-loop goal and a review of prior worker logs. Read-only inspection at 2026-06-04 19:45 CST showed `exp-ocr16-eval-ocr` still running as PID `167160`, with no `*results.json` yet and log progress around 68% of 5000 validation samples.

Worker-log findings:

- Local `agent-runs/` contained no durable captures, while rmux sessions still had scrollback. This means previous worker reasoning was recoverable only opportunistically from panes, not from a durable record.
- The workers were launched without `--wait`, so the current `rmux_worker.sh` did not produce guaranteed `latest/final` capture files.
- Baseline OCR eval worker killed or attempted to clear processes not exclusively owned by its assigned run. This caused direct interference with the OCR16 eval.
- Workers rediscovered known environment facts: correct Python is `/home/zsm/parameter-golf/venv/bin/python`, worktree-local `lmms-eval` needs `PYTHONPATH`, OCR task config has a bad hardcoded dataset path, and artifacts belong under `/data/zsm/parameter-golf/runs/<run_id>`.
- A local task-name variant (`textvqa_val_ocr_local`) was attempted but not registered as expected; the reliable patch is changing only `dataset_path` in the existing `textvqa_val_ocr.yaml` inside an isolated worktree.

Process decision for next loop:

- First optimize orchestration reliability before launching more model variants.
- Require every worker prompt to include server path map, environment variables, assigned worktree, run root, allowed GPU, PID ownership policy, forbidden actions, preflight checks, and final sentinel.
- Require every remote run root to contain `command.sh`, `env.txt`, `git_commit.txt`, `git_diff.patch`, `pid.txt`, `logs/*.log`, `status.json`, and final result pointer if available.
- Workers may kill only PIDs written to their own run root `pid.txt`; otherwise they must report contention and stop.
- Orchestrator polling policy: 10-15s until startup/PID/log verified, 60s during first 5 minutes, 3-5 minutes for stable eval, 5-10 minutes for long training; avoid long blocking sleeps when a short status check or background monitor is enough.

Proposed staged acceptance gates:

- Stage 0 orchestration reliability: 3 consecutive worker tasks have durable prompt/capture/run-root records and zero cross-run process interference.
- Stage 1 eval alignment: `ocr16_seed1` and best baseline seed2 both complete `textvqa_val_ocr` with matching task config, commit, command, and result JSONs.
- Stage 2 decision gate: OCR direction continues only if aligned OCR eval beats baseline seed2 or produces a predeclared positive delta; otherwise pivot to prompt/style or LoRA controls.
- Stage 3 sample evidence: per-sample prediction, gold answer, OCR token, and prompt snapshot logging exists for at least one eval path before interpreting failure modes.
- Stage 4 new variants: launch training only after Stage 1-3 gates pass; candidate directions are prompt alignment, question-relevant OCR selection, OCR dropout, and conservative LoRA sweeps.

## 2026-06-04 Stage 1 OCR eval completion and baseline seed2 launch

Read-only remote inspection at 2026-06-04 19:49-19:52 CST found the aligned OCR eval still running as PID `167160`, then completing cleanly at 2026-06-04 19:52 CST. The remote run root was backfilled with reconstruction metadata before completion:

```text
/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/command.sh
/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/env.txt
/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/git_commit.txt
/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/git_diff.patch
/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/pid.txt
/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/logs/eval.log
/data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/status.json
```

Completed OCR16 aligned result:

```text
run_id: eval_ocr16_seed1_textvqa_val_ocr
worktree: /home/zsm/pg-worktrees/pg-eval-ocr16-ocr
branch: exp/eval-ocr16-ocr
commit: 101959c882dd9d05be79668f80456da038c01c77
task: textvqa_val_ocr
model: /data/zsm/parameter-golf/runs/ocr16_seed1/outputs/merged
result_json: /data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/eval/outputs__merged/20260604_193246_results.json
submission_json: /data/zsm/parameter-golf/runs/eval_ocr16_seed1_textvqa_val_ocr/eval/submissions/textvqa_submission_2026-06-04-19-52-28.json
exact_match: 0.7262000000000036
stderr: 0.005938970135743878
```

The result was added to `ara/evidence/results.csv`. This is not yet a Stage 2 continuation decision because the best baseline seed2 must complete the same `textvqa_val_ocr` task first.

Baseline seed2 was then started only after OCR16 completed and GPU2 was verified free of the OCR16 PID. A hardened starter worker prompt was saved at:

```text
ara/trace/worker-captures/pg-eval-baseline-seed2-start-prompt.md
```

The worker ran through `rmux_worker.sh --wait`; durable captures were saved under:

```text
ara/trace/worker-captures/pg-eval-baseline-seed2-start-latest.txt
ara/trace/worker-captures/pg-eval-baseline-seed2-start-final.txt
ara/trace/worker-captures/pg-eval-baseline-seed2-start-postfinal-capture.txt
```

The starter worker first hit a shell-quoting failure before launching any process; read-only checks confirmed no run-root PID and no GPU2 process from that failed attempt. The worker then launched baseline seed2 successfully. The run root is:

```text
/data/zsm/parameter-golf/runs/eval_baseline_seed2_textvqa_val_ocr
```

Baseline seed2 startup evidence at 2026-06-04 19:59 CST:

```text
worktree: /home/zsm/pg-worktrees/pg-eval-baseline-ocr
branch: exp/eval-baseline-ocr
commit: 101959c882dd9d05be79668f80456da038c01c77
task: textvqa_val_ocr
model: /data/zsm/parameter-golf/outputs/textvqa_qwen3vl_lora_seed2/merged
run root files: command.sh, env.txt, git_commit.txt, git_diff.patch, pid.txt, launcher_pid.txt, logs/stdout.log, logs/stderr.log, logs/pid.txt, status.json
python PID: 1259059
launcher PID: 1259057
GPU: CUDA_VISIBLE_DEVICES=2, bus 00000000:9C:00.0, 4622 MiB used by PID 1259059
status: running
```

`pid.txt` was repaired to record the actual Python `lmms_eval` GPU process PID `1259059`; `launcher_pid.txt` and `status.json` preserve the parent bash launcher PID `1259057`. This keeps the hardened process rule enforceable: a worker may kill only the PID in its own run root `pid.txt`; other PIDs must be reported only.

At 2026-06-04 19:59 CST, baseline seed2 was running and had reached roughly 13% of 5000 TextVQA validation samples. No baseline seed2 result JSON existed yet, so no baseline OCR result row was added to `ara/evidence/results.csv`.

## 2026-06-04 Stage 1-4 gate closure and Stage 3 repair

Baseline seed2 aligned OCR eval completed:

```text
run_id: eval_baseline_seed2_textvqa_val_ocr
worktree: /home/zsm/pg-worktrees/pg-eval-baseline-ocr
branch: exp/eval-baseline-ocr
commit: 101959c882dd9d05be79668f80456da038c01c77
task: textvqa_val_ocr
model: /data/zsm/parameter-golf/outputs/textvqa_qwen3vl_lora_seed2/merged
result_json: /data/zsm/parameter-golf/runs/eval_baseline_seed2_textvqa_val_ocr/eval/textvqa_qwen3vl_lora_seed2__merged/20260604_195729_results.json
submission_json: /data/zsm/parameter-golf/runs/eval_baseline_seed2_textvqa_val_ocr/eval/submissions/textvqa_submission_2026-06-04-20-16-54.json
exact_match: 0.7133600000000039
stderr: 0.00602570858180051
```

The result was added to `ara/evidence/results.csv`. Stage 1 eval alignment is complete: OCR16 and baseline seed2 were evaluated on `textvqa_val_ocr` at the same commit family with isolated dataset-path patches and durable command/env/git/pid/log/status metadata.

Stage 2 decision: continue the OCR direction. OCR16 aligned eval score `0.7262000000000036` exceeds baseline seed2 aligned eval score `0.7133600000000039`; delta is `+0.012840000000000036`, above the predeclared minimum positive delta `+0.001`.

Stage 3 sample evidence was built, then repaired after verification found two fidelity issues:

- Initial artifact prompt snapshots used space-joined OCR tokens, while `lmms_eval/tasks/textvqa/utils.py` uses `', '.join(ocr_tokens)`.
- Initial per-sample scores used boolean normalized matches, while lmms-eval TextVQA exact match is fractional accuracy through `EvalAIAnswerProcessor` and the other-answer matching rule.

Repair worker `pg-stage3-sample-evidence-repair` rebuilt the artifact from cached TextVQA validation Arrow files under `/data/zsm/hf_cache/datasets/lmms-lab___textvqa`. It did not use GPU, launch eval/training, edit worktrees, or kill processes.

Repaired Stage 3 artifact:

```text
run_root: /data/zsm/parameter-golf/runs/stage3_textvqa_val_ocr_sample_evidence
jsonl: /data/zsm/parameter-golf/runs/stage3_textvqa_val_ocr_sample_evidence/samples_textvqa_val_ocr_ocr16_vs_baseline_seed2.jsonl
summary: /data/zsm/parameter-golf/runs/stage3_textvqa_val_ocr_sample_evidence/summary.json
records: 5000
ocr16_better: 229
baseline_seed2_better: 149
tied: 4622
ocr16_exact_match_mean: 0.7262000000000036
baseline_seed2_exact_match_mean: 0.7133600000000039
prompt_snapshot_check: comma-separated OCR tokens; no prompt mismatches found in independent verification
score_check: fractional per-sample TextVQA scores; means match lmms-eval result JSON aggregates to floating precision
```

Stage 0 reliability audit passed for the three consecutive hardened worker tasks after the earlier interference incident:

```text
pg-eval-baseline-seed2-start
pg-stage3-sample-evidence
pg-stage3-sample-evidence-repair
```

Each has a local prompt and final capture under `ara/trace/worker-captures/`. The assigned run roots contain command/env/git/pid/log/status metadata. No cross-run process kill or GPU contention occurred during these three tasks. The baseline worker's first shell-quoting failure launched no process; the successful run's `pid.txt` was repaired to the Python GPU process PID.

Stage 4 planning is now recorded without launching new training. Candidate variants have falsifying checks and minimum acceptable deltas:

- prompt alignment variant: require prompt reproduction first; training delta threshold `+0.003` over current OCR16 aligned eval.
- question-relevant OCR selection: require offline sample audit showing net OCR-dependent opportunity and no large loss of current OCR16 wins; training delta threshold `+0.003`.
- OCR dropout: require short-run/ablation evidence that OCR eval is not degraded by more than `0.001` and non-OCR eval improves; acceptable gain is `+0.002` on OCR eval or baseline recovery on non-OCR eval while keeping OCR advantage.
- answer-style eval-only control: stop or pivot if prompt-only baseline reaches within `0.001` of OCR16 aligned eval.
