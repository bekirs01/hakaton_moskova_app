#!/usr/bin/env bash
# Loads ./.env, starts MemeOps API on free port (Python Telegram API or Dart stub), then Flutter.
set -euo pipefail
cd "$(dirname "$0")"
if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  . ./.env
  set +a
fi

_api_port=3000
if [[ -n "${MEMEOPS_API_BASE:-}" ]] && [[ "${MEMEOPS_API_BASE}" =~ :([0-9]+)(/|$) ]]; then
  _api_port="${BASH_REMATCH[1]}"
fi

MEMEOPS_DEV_API_PID=""
cleanup() {
  if [[ -n "${MEMEOPS_DEV_API_PID}" ]] && kill -0 "${MEMEOPS_DEV_API_PID}" 2>/dev/null; then
    kill "${MEMEOPS_DEV_API_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

_port_busy() {
  command -v nc >/dev/null 2>&1 && nc -z 127.0.0.1 "${_api_port}" 2>/dev/null
}

if _port_busy; then
  echo "Port ${_api_port} already listening (using existing API)."
elif [[ "${MEMEOPS_USE_PYTHON_API:-}" == "1" ]]; then
  if [[ ! -d .venv-telegram ]]; then
    echo "MEMEOPS_USE_PYTHON_API=1: run first: python3 -m venv .venv-telegram && . .venv-telegram/bin/activate && pip install -r tool/requirements-telegram.txt" >&2
    exit 1
  fi
  echo "Starting telegram_insights_server (Python) on ${_api_port}..."
  # shellcheck source=/dev/null
  source .venv-telegram/bin/activate
  export TELEGRAM_INSIGHTS_PORT="${TELEGRAM_INSIGHTS_PORT:-${_api_port}}"
  python tool/telegram_insights_server.py &
  MEMEOPS_DEV_API_PID=$!
  if command -v nc >/dev/null 2>&1; then
    for _ in $(seq 1 40); do
      nc -z 127.0.0.1 "${_api_port}" 2>/dev/null && break
      sleep 0.15
    done
  else
    sleep 1
  fi
else
  echo "Starting MemeOps dev API stub (Dart) on ${_api_port}..."
  dart run tool/memeops_dev_server.dart --port "${_api_port}" &
  MEMEOPS_DEV_API_PID=$!
  if command -v nc >/dev/null 2>&1; then
    for _ in $(seq 1 40); do
      nc -z 127.0.0.1 "${_api_port}" 2>/dev/null && break
      sleep 0.15
    done
  else
    sleep 1
  fi
fi

flutter run \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}" \
  --dart-define=MEMEOPS_API_BASE="${MEMEOPS_API_BASE:-http://127.0.0.1:3000}" \
  --dart-define=MEMEOPS_USE_PYTHON_API="${MEMEOPS_USE_PYTHON_API:-}" \
  "$@"
