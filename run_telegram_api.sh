#!/usr/bin/env bash
# Local Telethon API for Flutter (same HTTP contract as MemeOps). Loads .env from repo root.
set -euo pipefail
cd "$(dirname "$0")"

if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  . ./.env
  set +a
fi

export TELEGRAM_INSIGHTS_PORT="${TELEGRAM_INSIGHTS_PORT:-3000}"

if [[ ! -d .venv-telegram ]]; then
  python3 -m venv .venv-telegram
fi
# shellcheck source=/dev/null
source .venv-telegram/bin/activate
pip install -q -r tool/requirements-telegram.txt

echo "Starting telegram_insights_server on http://127.0.0.1:${TELEGRAM_INSIGHTS_PORT}"
echo "Flutter MEMEOPS_API_BASE should be http://127.0.0.1:${TELEGRAM_INSIGHTS_PORT}"
exec python tool/telegram_insights_server.py
