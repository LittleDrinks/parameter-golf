# Parameter Golf panel-worker reference

## Local project layout

- `agent-prompts/`: prompt contracts retained for future improvement.
- `skills/panel-as-worker/scripts/`: reusable rmux worker/dashboard scripts.
- `agent-runs/`: local pane captures, not large experiment outputs.
- `ara/`: lightweight research records.

## Server path map

- `/home/zsm/parameter-golf`: main git worktree.
- `/home/zsm/pg-worktrees/pg-harness`: `exp/harness` worktree.
- `/data/zsm/parameter-golf`: artifact storage root, not a git repo.
- `/data/zsm/parameter-golf/runs/<run_id>`: durable logs/results.

The harness worktree has `data` and `outputs` symlinks into `/data`, but no `runs` symlink. Look directly under `/data/zsm/parameter-golf/runs` for run logs.

## Read-only remote forensics checklist

```bash
tmux list-sessions || true
rmux list-sessions || true
ps -fu "$USER" | egrep 'train_textvqa|lmms_eval|accelerate|torchrun|python|run_one|eval_qwen|merge_lora' | grep -v grep || true
nvidia-smi
find ~ /data/zsm -maxdepth 4 -type d \( -name parameter-golf -o -name runs -o -name outputs -o -name results -o -name agent-runs \) 2>/dev/null | sort
find /data/zsm/parameter-golf /home/zsm/parameter-golf -maxdepth 7 -type f \
  \( -name '*.log' -o -name '*results.json' -o -name 'trainer_state.json' -o -name 'train_results.json' -o -name 'summary.csv' -o -name 'git_commit.txt' -o -name 'git_diff.patch' \) \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort -r | head -200
```

## Known recovered run

`ocr16_seed1` was recovered under `/data/zsm/parameter-golf/runs/ocr16_seed1`; train, merge, and eval completed. Exact match was `0.7076800000000036`.
