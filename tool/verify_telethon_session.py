#!/usr/bin/env python3
"""
.env içindeki TELEGRAM_SESSION_STRING + API_ID/HASH ile Telethon yetkisini kontrol eder.
Çıkış kodu: 0 = yetkili, 1 = değil veya eksik yapılandırma.
"""
from __future__ import annotations

import asyncio
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from telethon import TelegramClient
from telethon.sessions import StringSession

ROOT = Path(__file__).resolve().parent.parent


def _session_raw() -> str:
    s = os.environ.get("TELEGRAM_SESSION_STRING", "").strip()
    if (s.startswith('"') and s.endswith('"')) or (s.startswith("'") and s.endswith("'")):
        s = s[1:-1]
    return s.strip()


async def _run() -> int:
    load_dotenv(ROOT / ".env")
    raw_id = os.environ.get("TELEGRAM_API_ID", "").strip()
    api_hash = os.environ.get("TELEGRAM_API_HASH", "").strip()
    sess = _session_raw()

    if not raw_id or not api_hash:
        print("Eksik: TELEGRAM_API_ID veya TELEGRAM_API_HASH (.env)")
        return 1
    if not sess:
        print("Eksik: TELEGRAM_SESSION_STRING (.env)")
        print("Çözüm: ./setup_telegram_session.sh — telefon + Telegram kodu gerekir.")
        return 1

    try:
        api_id = int(raw_id)
    except ValueError:
        print("TELEGRAM_API_ID sayı olmalı.")
        return 1

    client = TelegramClient(StringSession(sess), api_id, api_hash)
    try:
        await client.connect()
        ok = await client.is_user_authorized()
        if ok:
            me = await client.get_me()
            print(f"✓ Telethon yetkili: @{getattr(me, 'username', None) or me.id}")
            return 0
        print("✗ Oturum geçersiz veya bu API_ID/API_HASH çiftiyle uyumsuz.")
        print("  Telegram’da «Aktif oturumlar»dan eski oturumu kapatıp şunu çalıştır:")
        print("    ./setup_telegram_session.sh")
        return 1
    finally:
        await client.disconnect()


if __name__ == "__main__":
    sys.exit(asyncio.run(_run()))
