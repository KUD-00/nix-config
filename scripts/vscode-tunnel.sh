#!/usr/bin/env bash
set -euo pipefail

NAME=${VSCODE_TUNNEL_NAME:-Lain}
LOG_LEVEL=${VSCODE_TUNNEL_LOG:-info}
BIN=${VSCODE_TUNNEL_BIN:-}
EXTRA_ARGS=${VSCODE_TUNNEL_ARGS:-}
CLEAN=${VSCODE_TUNNEL_CLEAN:-true}
ACTION=${1:-start}

if [[ -z "$BIN" ]]; then
  BIN=$(command -v code-tunnel || true)
fi

if [[ -z "$BIN" ]]; then
  BIN=$(command -v code || true)
fi

if [[ -z "$BIN" ]]; then
  echo "code-tunnel or code not found. Set VSCODE_TUNNEL_BIN to the CLI path." >&2
  exit 1
fi

IFS=' ' read -r -a extra <<< "$EXTRA_ARGS"

cleanup_existing() {
  echo "Stopping existing tunnel processes (if any)..."
  "$BIN" tunnel kill >/dev/null 2>&1 || true
  "$BIN" service stop >/dev/null 2>&1 || true
  pkill -f "code-tunnel.*tunnel" >/dev/null 2>&1 || true
}

start_tunnel() {
  cmd=("$BIN" tunnel --accept-server-license-terms --log "$LOG_LEVEL" --name "$NAME")
  cmd+=("${extra[@]}")
  echo "Starting VS Code tunnel named '$NAME' (log level: $LOG_LEVEL)..."
  exec "${cmd[@]}"
}

case "$ACTION" in
  start)
    if [[ "$CLEAN" == "true" ]]; then
      cleanup_existing
    fi
    start_tunnel
    ;;
  restart)
    cleanup_existing
    start_tunnel
    ;;
  kill|stop)
    echo "Stopping tunnel..."
    exec "$BIN" tunnel kill
    ;;
  status)
    exec "$BIN" tunnel status
    ;;
  *)
    echo "Usage: $0 [start|restart|kill|status]" >&2
    exit 1
    ;;
esac
