#!/usr/bin/env bash
# Bir kez (veya oturum bozulunca): Telefon + Telegram kodu → .env içine TELEGRAM_SESSION_STRING yazar.
# Bu adım etkileşimlidir; otomatik tamamlanamaz.
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

echo "→ Telegram girişi başlıyor (kod telefona gelir)."
python3 tool/telethon_create_string_session.py

echo ""
echo "→ Oturum doğrulanıyor..."
python3 tool/verify_telethon_session.py || exit 1
echo "→ Tamam. Şimdi: ./run_telegram_api.sh"
