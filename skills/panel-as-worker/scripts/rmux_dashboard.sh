#!/bin/bash
set -euo pipefail

HOST="${RMUX_DASHBOARD_HOST:-127.0.0.1}"
PORT="${RMUX_DASHBOARD_PORT:-8765}"

usage() {
  cat <<'USAGE'
Usage:
  rmux_dashboard.sh [--host HOST] [--port PORT] [--open]

Environment:
  RMUX_DASHBOARD_HOST  Default: 127.0.0.1
  RMUX_DASHBOARD_PORT  Default: 8765

Examples:
  skills/panel-as-worker/scripts/rmux_dashboard.sh
  skills/panel-as-worker/scripts/rmux_dashboard.sh --host 0.0.0.0 --port 8765
  skills/panel-as-worker/scripts/rmux_dashboard.sh --open
USAGE
}

ARGS=()
OPEN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="$2"
      shift 2
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --open)
      OPEN=1
      shift
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

if [[ "${OPEN}" -eq 1 ]]; then
  ARGS+=(--open)
fi

echo "[INFO] Starting rmux dashboard on http://${HOST}:${PORT}"
echo "[INFO] Keep this process running while you monitor workers."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "${SCRIPT_DIR}/rmux_dashboard.py" --host "${HOST}" --port "${PORT}" "${ARGS[@]}"
