---
name: panel-as-worker
description: Launch, monitor, and recover pane-based worker agents using rmux/tmux-style panels with durable prompt dispatch, pane captures, DONE sentinels, and read-only dashboards. Use when Codex needs to run sub-agents in terminal panes, coordinate panel-as-worker/rmux workflows, inspect crashed or missing tmux/rmux sessions, preserve worker output, or migrate pane-worker scripts into a project skill.
---

# Panel As Worker

Use this skill to treat an `rmux` pane as a durable worker: start a worker in a known worktree, paste a prompt, wait for a `DONE <role>` sentinel, and capture pane output into files that survive UI/session loss.

## Core Rules

- Use one worker session per task and per worktree.
- Require the worker prompt to include an exact final sentinel: `DONE <role>`.
- Keep prompt contracts in the project (for this repo: `agent-prompts/`) so they can evolve separately from the skill.
- Save captures under a lightweight run directory such as `agent-runs/`; do not rely on terminal scrollback.
- Do not use web-share or expose panes externally unless the user explicitly asks.
- Review worker diffs before merging or committing.

## Launch a Worker

From the project root:

```bash
skills/panel-as-worker/scripts/rmux_worker.sh \
  --session pg-task-001 \
  --role task-role \
  --prompt agent-prompts/task-role.md \
  --workdir /path/to/worktree \
  --wait
```

Outputs:

```text
agent-runs/<session>-latest.txt
agent-runs/<session>-final.txt
```

The script refuses to paste into a shell unless it detects the Claude Code UI. Override the worker command only when needed:

```bash
CLAUDE_CMD="claude --dangerously-skip-permissions" \
  skills/panel-as-worker/scripts/rmux_worker.sh ...
```

## Monitor Workers

Use the read-only dashboard:

```bash
skills/panel-as-worker/scripts/rmux_dashboard.sh --open
```

Then open:

```text
http://127.0.0.1:8765?refresh=2&lines=120
```

If localhost forwarding is awkward, bind all interfaces and use the host/WSL IP:

```bash
skills/panel-as-worker/scripts/rmux_dashboard.sh --host 0.0.0.0 --port 8765
```

## Recover After tmux/rmux Disappears

If a session vanishes or the user reports “no output”:

1. Check sessions: `tmux list-sessions || true`; `rmux list-sessions || true`.
2. Check processes: `ps -fu "$USER" | egrep 'python|train|eval|accelerate|torchrun|claude|kimi' | grep -v grep || true`.
3. Check GPU if relevant: `nvidia-smi`.
4. Locate durable outputs (`agent-runs/`, run logs, result JSONs) before assuming the task failed.
5. Record findings in the project ARA trace if the task is research-related.

For this repository, see `references/parameter-golf.md` for the server path map and experiment-forensics checklist.

## Scripts

- `scripts/rmux_worker.sh` — create rmux session, dispatch prompt, capture output, optionally wait for sentinel.
- `scripts/rmux_dashboard.sh` — stable dashboard entrypoint.
- `scripts/rmux_dashboard.py` — read-only HTTP dashboard implementation.

## Prompt Contract

A worker prompt should include:

```text
Role:
Goal:
Allowed files:
Forbidden actions:
Task:
Required final line:
DONE <role>
```

Keep prompts concise and explicit. If the worker may touch source code, include allowed paths and checks to run.
