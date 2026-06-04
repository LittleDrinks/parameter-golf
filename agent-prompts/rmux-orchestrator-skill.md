# rmux Orchestrator Skill

For Codex managing Claude/Kimi workers in `parameter-golf` via rmux in WSL.

---

## 1. What rmux is good for in this workflow

rmux is a tmux-compatible terminal multiplexer with first-class **web sharing**. In this project it replaces manual tmux coordination with programmable session control + optional remote visibility.

Specific wins:

- **Pane-as-worker dispatch**: Codex creates one rmux session per worker, sends task commands via `send-keys`, and harvests output via `capture-pane`—no SSH, no background jobs, no polling log files.
- **Web-share for long runs**: Training runs that take hours can be shared with a spectator URL so the operator (Codex) or a human reviewer can watch live without blocking a local terminal.
- **Socket isolation**: Each WSL user gets a private rmux socket (`$RMUX` → `/tmp/rmux-1000/default,…`). Sessions are local-only unless explicitly web-shared.
- **Tmux muscle memory**: All standard tmux subcommands work (`new-session`, `split-window`, `send-keys`, `capture-pane`, `list-panes`, `kill-session`, etc.). Scripts written for tmux port almost verbatim.

What it is **not**:
- Not a remote compute scheduler (workers still run on this WSL host).
- Not a git worktree manager (Codex still creates worktrees with `git worktree add`).

---

## 2. Minimal command cookbook

### Session lifecycle

```bash
# Create a detached session for a worker, starting in its worktree
rmux new-session -d -s "pg-<worker>-<run_id>" -c "/home/q2635/wsl-workspace/parameter-golf.wt.<run_id>"

# Check if session exists (exit 0 = yes)
rmux has-session -t "pg-<worker>-<run_id>" 2>/dev/null

# List all sessions with window counts
rmux list-sessions -F '#{session_name} #{session_windows} #{session_attached}'

# Kill a session and all its panes/windows
rmux kill-session -t "pg-<worker>-<run_id>"
```

### Pane control (task dispatch + result harvest)

```bash
# Send a command to a pane and press Enter
rmux send-keys -t "pg-harness-01:0.0" "export RUN_ID=01 && bash run_train.sh" C-m

# Send Ctrl+C to interrupt a running pane
rmux send-keys -t "pg-harness-01:0.0" C-c

# Capture the last N lines of pane output
rmux capture-pane -t "pg-harness-01:0.0" -p -S -100 > /tmp/pg-harness-01.log

# Check if a pane is still running a command
rmux list-panes -t "pg-harness-01" -F '#{pane_index} #{pane_current_command} #{pane_pid}'
```

### Web sharing (for long training/eval runs)

```bash
# Share the current session with operator + spectator URLs + PINs
rmux web-share -t "pg-harness-01"
# Output:
#   spectator https://share.rmux.io/#t=...
#   operator URL emitted on stderr
#   operator pin ######
#   spectator pin ######

# Share read-only (spectator only), no PIN, 4-hour TTL
rmux web-share -t "pg-harness-01" --spectator-only --no-pin --ttl 14400

# List active shares for a session
rmux web-share -l

# Revoke a share
rmux web-share stop <share-id>
```

### Useful flags

| Flag | Meaning |
|------|---------|
| `-d` | Create session detached (do not attach client) |
| `-c <dir>` | Start directory for the session/window |
| `-s <name>` | Session name |
| `-n <name>` | Window name |
| `-t <target>` | Target: `session:window.pane` |
| `-F '<fmt>'` | Format string for list output |
| `-S <n>` | Capture from line N (negative = from end) |
| `-p` | Print capture to stdout |

---

## 3. Pane/session naming convention

Format: `pg-<role>-<run_id>`

- `pg` — project slug for `parameter-golf`.
- `<role>` — worker role: `harness`, `lora`, `ocr`, `eval`, `baseline`.
- `<run_id>` — short identifier: `01`, `02a`, `lr-sweep-03`, etc.

Examples:
- `pg-harness-01` — harness worker on run 01
- `pg-lora-rank-04` — LoRA sweep worker testing rank variants
- `pg-eval-baseline` — eval-only session for baseline model

Window/pane targets inside a session:
- Single-pane sessions: target is `pg-harness-01:0.0` (window 0, pane 0).
- Multi-pane sessions: use `pg-harness-01:1.0` for window 1, pane 0.

Avoid tmux’s auto-renamed windows by setting a fixed name on creation:
```bash
rmux new-session -d -s "pg-harness-01" -n "main" -c "<worktree>"
```

---

## 4. Worker prompt contract

When Codex dispatches a worker into an rmux pane, prepend these shell exports so the worker knows its context:

```bash
export PG_RUN_ID="<run_id>"
export PG_ROLE="<role>"
export PG_WORKTREE="<absolute-path-to-worktree>"
export PG_OUTPUT_DIR="/data/parameter-golf/outputs/${PG_RUN_ID}"
export PG_RESULTS_DIR="/data/parameter-golf/results"
export PG_PREPARED_DATA_DIR="/data/parameter-golf/prepared"
cd "$PG_WORKTREE"
```

The worker should treat the pane as its terminal. It should:
1. Print the **Worker Contract** header (Goal, Allowed files, Planned changes, Checks).
2. Do the work within `$PG_WORKTREE`.
3. Print the **Worker Contract** footer (DONE, Changed files, Behavior changes, Checks run, Risks, Suggested next step).
4. Exit cleanly (or leave the pane idle if waiting for a run to finish).

Codex harvests output by running:
```bash
rmux capture-pane -t "pg-<role>-<run_id>:0.0" -p -S -200
```
and parsing for the `DONE <role>` sentinel.

---

## 5. Safety rules for multi-agent coding

1. **One worktree per worker, one session per worktree.** Never let two workers share a worktree. Never let two workers share a session if they might write the same files.
2. **No `git commit` or `git push` from workers unless the task explicitly says so.** Workers read code, edit files, and run checks. Codex reviews and commits.
3. **Workers must not delete or overwrite `outputs/`, `results/`, or `data/` in the main repo.** They should only write to `$PG_OUTPUT_DIR` or their worktree.
4. **Workers must not start long training or full eval unless explicitly instructed.** If a worker needs to test-run training, cap it at a few steps with `--max_steps`.
5. **Codex must `kill-session` when a worker is done.** Do not leave stale sessions and web shares running. Before killing, capture the final pane output to a log file under `ara/trace/`.
6. **Web shares default to PIN-protected.** If sharing a session for a long run, record the share ID and the operator/spectator pins in `ara/trace/rmux-shares.md` so the team can audit access.
7. **Workers must not edit `lmms-eval/` or the main branch unless explicitly instructed.**

---

## 6. A first-session recipe for parameter-golf

Scenario: Codex wants to run a harness-worker experiment in an isolated worktree while keeping the main branch clean.

```bash
# --- Step 1: Create worktree from main ---
RUN_ID="exp-01"
WT_PATH="/home/q2635/wsl-workspace/parameter-golf.wt.${RUN_ID}"
git worktree add "$WT_PATH" main

# --- Step 2: Create detached rmux session ---
SESSION="pg-harness-${RUN_ID}"
rmux new-session -d -s "$SESSION" -n "main" -c "$WT_PATH"

# --- Step 3: Dispatch worker ---
rmux send-keys -t "${SESSION}:0.0" "export PG_RUN_ID=${RUN_ID}" C-m
rmux send-keys -t "${SESSION}:0.0" "export PG_ROLE=harness" C-m
rmux send-keys -t "${SESSION}:0.0" "export PG_WORKTREE=${WT_PATH}" C-m
rmux send-keys -t "${SESSION}:0.0" "export PG_OUTPUT_DIR=/data/parameter-golf/outputs/${RUN_ID}" C-m
rmux send-keys -t "${SESSION}:0.0" "cd ${WT_PATH} && claude" C-m

# --- Step 4: (Optional) Web-share for monitoring ---
rmux web-share -t "$SESSION" --spectator-only --ttl 14400
# Record share ID + URL in ara/trace/rmux-shares.md

# --- Step 5: Harvest results ---
sleep 30
rmux capture-pane -t "${SESSION}:0.0" -p -S -200 > "ara/trace/${RUN_ID}-harness.log"

# --- Step 6: Cleanup ---
rmux kill-session -t "$SESSION"
git worktree remove "$WT_PATH"
```

**For a quick check** (no web share, short-lived):
```bash
rmux new-session -d -s "pg-check-$(date +%s)" -c "$PWD"
rmux send-keys -t "pg-check-*:0.0" "python -c 'print(\"sanity ok\")'" C-m
rmux capture-pane -t "pg-check-*:0.0" -p
rmux kill-session -t "pg-check-*"
```

---

## 7. Open questions / limitations

1. **Web-share stability on WSL**: WSL network bridging can be flaky. If `share.rmux.io` is unreachable, web-share falls back to localhost-only. For remote access, test `--tunnel-provider tailscale-funnel` or `localhost-run`.
2. **Pane output size**: `capture-pane` is limited to scrollback (default 2000 lines). For workers that produce megabytes of logs, redirect stdout/stderr to a file inside `$PG_OUTPUT_DIR` and only tail the last 50 lines to the pane.
3. **Worker pane detection**: `pane_current_command` shows `claude` or `python`, not the high-level task. Codex should rely on the `DONE <role>` sentinel and session names, not process names.
4. **Concurrent session limit**: Unconfirmed, but rmux inherits tmux’s large session/pane limits. For practical parameter-golf use, stay under ~20 concurrent sessions to keep the WSL host responsive.
5. **No built-in queue**: rmux is not a job queue. If Codex wants to run 10 LoRA variants, it must either run them sequentially in one session or spawn 10 sessions and track them manually. Consider wrapping in a small bash loop or a Python dispatcher script under `scripts/`.
6. **Web-share audit trail**: rmux does not log who connected to a share. If security matters, prefer `--operator-only` or `--spectator-only` and rotate shares frequently.

---

## Quick reference card

```text
Create  : rmux new-session -d -s pg-<role>-<id> -c <worktree>
Send    : rmux send-keys -t pg-<role>-<id>:0.0 "<cmd>" C-m
Capture : rmux capture-pane -t pg-<role>-<id>:0.0 -p -S -200
Share   : rmux web-share -t pg-<role>-<id> --spectator-only --ttl 14400
List    : rmux list-sessions -F '#{session_name} #{session_attached}'
Kill    : rmux kill-session -t pg-<role>-<id>
```
