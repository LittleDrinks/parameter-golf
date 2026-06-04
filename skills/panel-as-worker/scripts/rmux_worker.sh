#!/bin/bash
set -euo pipefail

SESSION=""
ROLE=""
PROMPT=""
WORKDIR="${PWD}"
WAIT=0
ATTACH=0
CLAUDE_CMD="${CLAUDE_CMD:-}"
CAPTURE_LINES="${CAPTURE_LINES:-320}"
RUN_DIR="${RUN_DIR:-agent-runs}"

usage() {
  cat <<'USAGE'
Usage:
  rmux_worker.sh --session NAME --role ROLE --prompt FILE [options]

Options:
  --workdir DIR       Worker working directory. Default: current directory.
  --wait              Wait for "DONE ROLE" and save final capture.
  --attach            Attach after dispatching the prompt.
  --claude-cmd CMD    Command used to start worker. Default: claude --dangerously-skip-permissions.

Outputs:
  agent-runs/<session>-latest.txt
  agent-runs/<session>-final.txt

Example:
  skills/panel-as-worker/scripts/rmux_worker.sh \
    --session pg-ocr-min-001 \
    --role ocr-min \
    --prompt agent-runs/ocr-min-worker-prompt.md \
    --wait
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session)
      SESSION="$2"
      shift 2
      ;;
    --role)
      ROLE="$2"
      shift 2
      ;;
    --prompt)
      PROMPT="$2"
      shift 2
      ;;
    --workdir)
      WORKDIR="$2"
      shift 2
      ;;
    --wait)
      WAIT=1
      shift
      ;;
    --attach)
      ATTACH=1
      shift
      ;;
    --claude-cmd)
      CLAUDE_CMD="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${SESSION}" || -z "${ROLE}" || -z "${PROMPT}" ]]; then
  echo "[ERROR] --session, --role, and --prompt are required" >&2
  usage >&2
  exit 2
fi

if [[ ! -f "${PROMPT}" ]]; then
  echo "[ERROR] Prompt file not found: ${PROMPT}" >&2
  exit 1
fi

if [[ ! -d "${WORKDIR}" ]]; then
  echo "[ERROR] Workdir not found: ${WORKDIR}" >&2
  exit 1
fi

if [[ -z "${CLAUDE_CMD}" ]]; then
  if [[ -x "${HOME}/.local/bin/claude" ]]; then
    CLAUDE_CMD="${HOME}/.local/bin/claude --dangerously-skip-permissions"
  else
    CLAUDE_CMD="claude --dangerously-skip-permissions"
  fi
fi

mkdir -p "${RUN_DIR}"
LATEST="${RUN_DIR}/${SESSION}-latest.txt"
FINAL="${RUN_DIR}/${SESSION}-final.txt"
SENTINEL="DONE ${ROLE}"

if rmux has-session -t "${SESSION}" 2>/dev/null; then
  echo "[ERROR] rmux session already exists: ${SESSION}" >&2
  echo "[INFO] Attach with: rmux attach -t ${SESSION}" >&2
  exit 1
fi

echo "[INFO] Creating rmux session: ${SESSION}"
rmux new-session -d -s "${SESSION}" -n main -c "${WORKDIR}" "${CLAUDE_CMD}; exec ${SHELL:-/bin/bash}"

echo "[INFO] Waiting for Claude UI"
for _ in $(seq 1 60); do
  rmux capture-pane -p -t "${SESSION}:0.0" -S -80 > "${LATEST}"
  if grep -q "Claude Code" "${LATEST}" && grep -q "bypass permissions" "${LATEST}"; then
    break
  fi
  sleep 1
done

rmux capture-pane -p -t "${SESSION}:0.0" -S -120 > "${LATEST}"
if ! grep -q "Claude Code" "${LATEST}"; then
  echo "[ERROR] Claude UI was not detected; refusing to paste prompt into shell" >&2
  echo "[INFO] Latest capture: ${LATEST}" >&2
  exit 1
fi

echo "[INFO] Dispatching prompt: ${PROMPT}"
rmux load-buffer "${PROMPT}"
rmux paste-buffer -t "${SESSION}:0.0"
rmux send-keys -t "${SESSION}:0.0" Enter

sleep 1
rmux capture-pane -p -t "${SESSION}:0.0" -S "-${CAPTURE_LINES}" > "${LATEST}"
INITIAL_COUNT=$(grep -F -c "${SENTINEL}" "${LATEST}" || true)
echo "[INFO] Initial sentinel count for '${SENTINEL}': ${INITIAL_COUNT}"

if [[ "${WAIT}" -eq 1 ]]; then
  echo "[INFO] Waiting for worker sentinel: ${SENTINEL}"
  while true; do
    rmux capture-pane -p -t "${SESSION}:0.0" -S "-${CAPTURE_LINES}" > "${LATEST}"
    count=$(grep -F -c "${SENTINEL}" "${LATEST}" || true)
    if [[ "${count}" -gt "${INITIAL_COUNT}" ]]; then
      rmux capture-pane -p -t "${SESSION}:0.0" -S "-${CAPTURE_LINES}" > "${FINAL}"
      echo "[INFO] DONE observed. Final capture: ${FINAL}"
      break
    fi
    sleep 5
  done
else
  echo "[INFO] Prompt dispatched. Latest capture: ${LATEST}"
fi

if [[ "${ATTACH}" -eq 1 ]]; then
  exec rmux attach -t "${SESSION}"
fi
