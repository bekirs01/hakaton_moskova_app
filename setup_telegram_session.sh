#!/usr/bin/env bash
# Bir kez çalıştır: Telefon/kod gir → .env içine TELEGRAM_SESSION_STRING yazar.
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "Önce .env oluştur (ör. cp env.sample .env)" >&2
  exit 1
fi

if [[ ! -d .venv-telegram ]]; then
  python3 -m venv .venv-telegram
fi
# shellcheck source=/dev/null
source .venv-telegram/bin/activate
pip install -q -r tool/requirements-telegram.txt

exec python3 tool/telethon_create_string_session.py
