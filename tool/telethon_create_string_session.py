#!/usr/bin/env python3
"""
Bir kez Telegram girişi — TELEGRAM_SESSION_STRING değerini proje .env dosyasına yazar.

Önkoşul: .env içinde TELEGRAM_API_ID ve TELEGRAM_API_HASH (run_dev / run_telegram_api ile aynı dosya).

Kullanım (repo kökünden):
  ./setup_telegram_session.sh
  # veya: python3 tool/telethon_create_string_session.py
"""

from __future__ import annotations

import asyncio
import os
import re
from pathlib import Path

from dotenv import load_dotenv
from telethon import TelegramClient
from telethon.sessions import StringSession

ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = ROOT / ".env"


def _upsert_session_in_dotenv(session: str) -> None:
    key = "TELEGRAM_SESSION_STRING"
    safe = session.replace("\\", "\\\\").replace('"', '\\"')
    line = f'{key}="{safe}"\n'
    text = ENV_FILE.read_text(encoding="utf-8") if ENV_FILE.exists() else ""
    pat = re.compile(rf"^{re.escape(key)}=.*$", re.MULTILINE)
    if pat.search(text):
        text = pat.sub(line.strip(), text)
    else:
        text = text.rstrip() + "\n" + line
    ENV_FILE.write_text(text, encoding="utf-8")


async def main() -> None:
    load_dotenv(ENV_FILE)

    raw_id = os.environ.get("TELEGRAM_API_ID", "").strip()
    api_hash = os.environ.get("TELEGRAM_API_HASH", "").strip()
    if raw_id:
        api_id = int(raw_id)
    else:
        api_id = int(input("Telegram API ID (my.telegram.org): ").strip())
    if not api_hash:
        api_hash = input("Telegram API Hash: ").strip()

    client = TelegramClient(StringSession(), api_id, api_hash)
    await client.start()
    if not await client.is_user_authorized():
        print("Giriş başarısız.")
        return

    sess = client.session.save()
    _upsert_session_in_dotenv(sess)
    print(
        "\n✓ TELEGRAM_SESSION_STRING .env dosyasına yazıldı.\n"
        "  Kontrol: .env içinde TELEGRAM_SESSION_STRING=... dolu mu bak.\n"
        "  Sonra: ./run_telegram_api.sh ve Flutter.\n"
    )


if __name__ == "__main__":
    asyncio.run(main())
