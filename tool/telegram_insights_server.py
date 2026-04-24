#!/usr/bin/env python3
"""
Local MemeOps Telegram API: real channel fetch + structured summary + 5 meme variants.
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
from contextlib import asynccontextmanager
from datetime import timezone
from pathlib import Path
from typing import Any, Optional

from dotenv import load_dotenv
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict, Field
from telethon import TelegramClient
from telethon.errors import RPCError
from telethon.sessions import StringSession
from telethon.tl.functions.channels import GetFullChannelRequest
from telethon.tl.types import (
    PeerChannel,
    ReactionCustomEmoji,
    ReactionEmoji,
)

_TOOL = Path(__file__).resolve().parent
if str(_TOOL) not in sys.path:
    sys.path.insert(0, str(_TOOL))

from memeops_image_job import run_meme_image_job  # noqa: E402
from memeops_video_job import run_meme_video_job  # noqa: E402
from memeops_profession_supabase import (  # noqa: E402
    create_profession_row,
    insert_five_briefs,
    persist_telegram_channel_briefs,
)
from telegram_channel_analyzer import (  # noqa: E402
    analyze_channel_batch,
    build_meme_variants,
    classify_post_row,
)

load_dotenv()

_client: Optional[TelegramClient] = None


def _parse_channel_handle(url: str) -> str:
    from urllib.parse import urlparse

    s = url.strip()
    if s.startswith("@"):
        return s[1:].split("/")[0].split("?")[0]
    if "://" not in s:
        s = "https://" + s
    u = urlparse(s)
    host = (u.netloc or "").lower()
    parts = [p for p in u.path.strip("/").split("/") if p]
    if "t.me" in host or host == "telegram.me":
        if not parts:
            raise ValueError("Channel username missing in URL")
        if parts[0] == "s" and len(parts) > 1:
            return parts[1].replace("@", "").split("?")[0]
        if parts[0] in ("joinchat", "c", "+") or parts[0].startswith("+"):
            raise ValueError("Private / invite links need a public @username for this MVP")
        return parts[0].replace("@", "").split("?")[0]
    raise ValueError("Use a t.me or @username link")


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _client
    api_id = os.environ.get("TELEGRAM_API_ID", "").strip()
    api_hash = os.environ.get("TELEGRAM_API_HASH", "").strip()
    session_s = os.environ.get("TELEGRAM_SESSION_STRING", "").strip()
    if (session_s.startswith('"') and session_s.endswith('"')) or (
        session_s.startswith("'") and session_s.endswith("'")
    ):
        session_s = session_s[1:-1].strip()
    if api_id and api_hash and session_s:
        _client = TelegramClient(StringSession(session_s), int(api_id), api_hash)
        await _client.connect()
        ok = await _client.is_user_authorized()
        print(
            "telegram_insights_server: Telethon "
            + (
                "connected."
                if ok
                else (
                    "not authorized — .env oturumu bu API_ID ile eşleşmiyor veya süresi doldu. "
                    "Çalıştır: ./setup_telegram_session.sh (telefon + kod gerekir), sonra API’yi yeniden başlat."
                )
            )
        )
    else:
        print(
            "telegram_insights_server: missing TELEGRAM_* — configure .env "
            "for live analysis."
        )
    yield
    if _client is not None:
        await _client.disconnect()
        _client = None


app = FastAPI(title="MemeOps Telegram (local)", lifespan=lifespan)


class ChannelInsightsBody(BaseModel):
    channelUrl: str


class MemeVariantsBody(BaseModel):
    insights: dict[str, Any]


class ChannelPostStatsBody(BaseModel):
    """Tüm kanalda tek gönderi: sohbet kimliği veya @kullanıcıadı, mesaj id."""

    model_config = ConfigDict(populate_by_name=True)

    channel: str
    message_id: int = Field(..., alias="messageId")
    # Mobil kayıttan (-100…); kanal/peer eşleştirmesini güçlendirir, 404'ü azaltır.
    chat_id: Optional[str] = Field(None, alias="chatId")


class ProfessionCreateBody(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    title: str
    description: Optional[str] = None
    future_context: Optional[str] = Field(None, alias="futureContext")


class BriefGenerateBody(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    profession_id: str = Field(..., alias="professionId")


class ImageJobBody(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    meme_brief_id: str = Field(..., alias="memeBriefId")


class VideoJobBody(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    meme_brief_id: str = Field(..., alias="memeBriefId")
    seconds: str = Field("4", alias="seconds")


class PersistVariantsBody(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    channel_url: str = Field(..., alias="channelUrl")
    insights: dict[str, Any]


def _auth_jwt(request: Request) -> Optional[str]:
    h = request.headers.get("authorization") or request.headers.get("Authorization")
    if not h or not h.lower().startswith("bearer "):
        return None
    return h[7:].strip()


def _reaction_total(msg: Any) -> int:
    reactions = getattr(msg, "reactions", None)
    results = getattr(reactions, "results", None)
    if not results:
        return 0
    total = 0
    for item in results:
        total += int(getattr(item, "count", 0) or 0)
    return total


def _candidates_for_channel(channel: str, chat_id: Optional[str]) -> list[Any]:
    """
    Aynı gönderi için farklı sohbet tanımlarını dene: @kullanici, -100…, .env kanalı, PeerChannel.
    """
    out: list[Any] = []
    seen: set[str] = set()

    def add_s(x: str) -> None:
        t = (x or "").strip()
        if t and t not in seen:
            seen.add(t)
            out.append(t)

    add_s(channel)
    add_s(os.environ.get("TELEGRAM_PUBLISH_CHANNEL", "").strip())
    if chat_id:
        c = chat_id.strip()
        add_s(c)
        if c.startswith("-100") and len(c) > 4:
            try:
                internal = int(c[4:])
                if internal > 0:
                    out.append(PeerChannel(channel_id=internal))
            except ValueError:
                pass
    return out


def _reaction_breakdown(msg: Any) -> list[dict[str, Any]]:
    """Emoji / custom emoji reaksiyon listesi; mobil analiz ekranı için."""
    out: list[dict[str, Any]] = []
    reactions = getattr(msg, "reactions", None)
    results = getattr(reactions, "results", None) if reactions else None
    if not results:
        return out
    for item in results:
        count = int(getattr(item, "count", 0) or 0)
        if count <= 0:
            continue
        re = getattr(item, "reaction", None)
        if re is None:
            continue
        if isinstance(re, ReactionEmoji):
            label = str(re.emoticon or "")
            kind = "emoji"
        elif isinstance(re, ReactionCustomEmoji):
            label = f"custom:{int(re.document_id)}"
            kind = "custom_emoji"
        else:
            label = re.__class__.__name__
            kind = "other"
        out.append({"label": label, "count": count, "kind": kind})
    return out


@app.post("/api/v1/professions")
async def create_profession_api(request: Request, body: ProfessionCreateBody):
    jwt = _auth_jwt(request)
    if not jwt:
        return JSONResponse(
            status_code=401,
            content={"error": {"code": "unauthorized", "message": "Sign in in the app first."}},
        )
    try:
        row = await create_profession_row(
            jwt, body.title, body.description, body.future_context
        )
    except RuntimeError as e:
        msg = str(e)
        if msg == "missing_supabase_env":
            return JSONResponse(
                status_code=503,
                content={
                    "error": {
                        "code": "config",
                        "message": "Add SUPABASE_URL and SUPABASE_ANON_KEY to .env for the local API.",
                    }
                },
            )
        return JSONResponse(
            status_code=502,
            content={"error": {"code": "supabase", "message": msg[:500]}},
        )
    return {"data": {"id": row["id"]}}


@app.post("/api/v1/ai/briefs/generate")
async def generate_briefs_api(request: Request, body: BriefGenerateBody):
    jwt = _auth_jwt(request)
    if not jwt:
        return JSONResponse(
            status_code=401,
            content={"error": {"code": "unauthorized", "message": "Sign in in the app first."}},
        )
    try:
        job_id, brief_ids = await insert_five_briefs(jwt, body.profession_id)
    except RuntimeError as e:
        msg = str(e)
        if msg == "missing_supabase_env":
            return JSONResponse(
                status_code=503,
                content={
                    "error": {
                        "code": "config",
                        "message": "Add SUPABASE_URL and SUPABASE_ANON_KEY to .env for the local API.",
                    }
                },
            )
        return JSONResponse(
            status_code=502,
            content={"error": {"code": "supabase", "message": msg[:500]}},
        )
    return {"data": {"jobId": job_id, "briefIds": brief_ids}}


@app.post("/api/v1/ai/jobs/image")
async def image_job_api(request: Request, body: ImageJobBody):
    jwt = _auth_jwt(request)
    if not jwt:
        return JSONResponse(
            status_code=401,
            content={"error": {"code": "unauthorized", "message": "Sign in in the app first."}},
        )
    try:
        data = await run_meme_image_job(jwt, body.meme_brief_id)
    except RuntimeError as e:
        msg = str(e)
        if msg == "missing_supabase_env":
            return JSONResponse(
                status_code=503,
                content={
                    "error": {
                        "code": "config",
                        "message": "Add SUPABASE_URL and SUPABASE_ANON_KEY to .env for the local API.",
                    }
                },
            )
        if msg == "missing_openai_key":
            return JSONResponse(
                status_code=503,
                content={
                    "error": {
                        "code": "openai_required",
                        "message": "Add OPENAI_API_KEY to .env for meme image generation.",
                    }
                },
            )
        return JSONResponse(
            status_code=502,
            content={"error": {"code": "image_job", "message": msg[:500]}},
        )
    return {"data": data}


@app.post("/api/v1/ai/jobs/video")
async def video_job_api(request: Request, body: VideoJobBody):
    jwt = _auth_jwt(request)
    if not jwt:
        return JSONResponse(
            status_code=401,
            content={"error": {"code": "unauthorized", "message": "Sign in in the app first."}},
        )
    try:
        data = await run_meme_video_job(jwt, body.meme_brief_id, body.seconds)
    except RuntimeError as e:
        msg = str(e)
        if msg == "missing_supabase_env":
            return JSONResponse(
                status_code=503,
                content={
                    "error": {
                        "code": "config",
                        "message": "Add SUPABASE_URL and SUPABASE_ANON_KEY to .env for the local API.",
                    }
                },
            )
        if msg == "missing_openai_key":
            return JSONResponse(
                status_code=503,
                content={
                    "error": {
                        "code": "openai_required",
                        "message": "Add OPENAI_API_KEY to .env for Sora video generation.",
                    }
                },
            )
        return JSONResponse(
            status_code=502,
            content={"error": {"code": "video_job", "message": msg[:500]}},
        )
    except Exception as e:
        return JSONResponse(
            status_code=502,
            content={"error": {"code": "video_job", "message": str(e)[:500] or "Video job failed."}},
        )
    return {"data": data}


@app.post("/api/v1/telegram/persist-variants")
async def persist_variants_api(request: Request, body: PersistVariantsBody):
    jwt = _auth_jwt(request)
    if not jwt:
        return JSONResponse(
            status_code=401,
            content={"error": {"code": "unauthorized", "message": "Sign in in the app first."}},
        )
    src = body.insights.get("analysisSource")
    if src != "telethon_live":
        return JSONResponse(
            status_code=400,
            content={
                "error": {
                    "code": "invalid_insights",
                    "message": "Need live Telethon analysis first (not stub).",
                }
            },
        )
    variants = await asyncio.to_thread(build_meme_variants, body.insights)
    lines = [
        (v.get("memotype_idea") or v.get("brief_title") or "").strip()
        for v in variants
    ]
    lines = [x for x in lines if x]
    if len(lines) < 5:
        return JSONResponse(
            status_code=422,
            content={
                "error": {
                    "code": "few_ideas",
                    "message": "Not enough meme lines — set OPENAI_API_KEY for richer ideas.",
                }
            },
        )
    try:
        data = await persist_telegram_channel_briefs(
            jwt, body.channel_url, body.insights, lines
        )
    except RuntimeError as e:
        msg = str(e)
        if msg == "missing_supabase_env":
            return JSONResponse(
                status_code=503,
                content={
                    "error": {
                        "code": "config",
                        "message": "Add SUPABASE_URL and SUPABASE_ANON_KEY to .env for the local API.",
                    }
                },
            )
        return JSONResponse(
            status_code=502,
            content={"error": {"code": "supabase", "message": msg[:500]}},
        )
    return {"data": data}


@app.get("/health")
async def health():
    ok = _client is not None and await _client.is_user_authorized()
    has_oai = bool(os.environ.get("OPENAI_API_KEY", "").strip())
    return {"ok": True, "telegram": ok, "stub": False, "openai": has_oai}


@app.post("/api/v1/telegram/meme-variants")
async def meme_variants(body: MemeVariantsBody):
    src = body.insights.get("analysisSource")
    if src != "telethon_live":
        return JSONResponse(
            status_code=400,
            content={
                "error": {
                    "code": "invalid_insights",
                    "message": "Run channel analysis first (live Telethon). Stubs cannot generate grounded variants.",
                }
            },
        )
    variants = await asyncio.to_thread(build_meme_variants, body.insights)
    return {"data": {"variants": variants}}


@app.post("/api/v1/telegram/channel-insights")
async def channel_insights(body: ChannelInsightsBody):
    if _client is None or not await _client.is_user_authorized():
        return JSONResponse(
            status_code=503,
            content={
                "error": {
                    "code": "telegram_not_configured",
                    "message": (
                        "Telegram not configured. Add TELEGRAM_API_ID, TELEGRAM_API_HASH, "
                        "TELEGRAM_SESSION_STRING to .env and run ./run_telegram_api.sh"
                    ),
                }
            },
        )

    try:
        handle = _parse_channel_handle(body.channelUrl)
    except ValueError as e:
        return JSONResponse(
            status_code=400,
            content={"error": {"code": "bad_channel_url", "message": str(e)}},
        )

    try:
        entity = await _client.get_entity(handle)
    except RPCError as e:
        return JSONResponse(
            status_code=502,
            content={
                "error": {
                    "code": "telegram_rpc",
                    "message": f"Telegram error: {e.__class__.__name__}",
                }
            },
        )
    except Exception as e:
        return JSONResponse(
            status_code=502,
            content={
                "error": {
                    "code": "telegram_entity",
                    "message": f"Could not open channel: {e}",
                }
            },
        )

    title = getattr(entity, "title", None) or handle

    texts: list[str] = []
    captions: list[str] = []
    message_meta: list[dict[str, Any]] = []
    post_types: list[str] = []
    photo_n = video_n = doc_n = 0
    image_bytes: list[bytes] = []

    try:
        async for msg in _client.iter_messages(entity, limit=150):
            is_fwd = msg.forward is not None
            t = (msg.text or "").strip()
            has_p = bool(msg.photo)
            has_v = bool(msg.video)
            post_types.append(classify_post_row(t if t else None, has_p, has_v, is_fwd))

            if t:
                texts.append(msg.text or "")
            if msg.photo and t:
                captions.append(t)

            dt = getattr(msg, "date", None)
            if dt is not None:
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                dt_local = dt.astimezone()
                message_meta.append(
                    {
                        "text": t,
                        "views": int(getattr(msg, "views", 0) or 0),
                        "reactions": _reaction_total(msg),
                        "forwards": int(getattr(msg, "forwards", 0) or 0),
                        "has_photo": has_p,
                        "has_video": has_v,
                        "hour": dt_local.hour,
                        "date_label": dt_local.strftime("%d.%m %H:%M"),
                    }
                )

            if msg.photo:
                photo_n += 1
                if len(image_bytes) < 5:
                    try:
                        b = await _client.download_media(msg.photo, file=bytes)
                        if isinstance(b, bytes) and 0 < len(b) < 2_500_000:
                            image_bytes.append(b)
                    except Exception:
                        pass
            if msg.video:
                video_n += 1
            if msg.document and not (msg.photo or msg.video):
                doc_n += 1
    except RPCError as e:
        return JSONResponse(
            status_code=502,
            content={
                "error": {
                    "code": "telegram_fetch",
                    "message": f"Could not read messages: {e.__class__.__name__}",
                }
            },
        )

    if not texts and photo_n == 0 and video_n == 0:
        return JSONResponse(
            status_code=422,
            content={
                "error": {
                    "code": "no_content",
                    "message": "No messages found in this window — channel may be empty or inaccessible.",
                }
            },
        )

    data = analyze_channel_batch(
        body.channelUrl,
        title,
        texts,
        captions,
        message_meta,
        post_types,
        photo_n,
        video_n,
        doc_n,
        image_bytes,
    )
    return {"data": data}


@app.post("/api/v1/telegram/channel-post-stats")
async def channel_post_stats(body: ChannelPostStatsBody):
    """
    Kullanıcı Telethon oturumu ile bir kanal gönderisinin görüntülenme + reaksiyon sayımlarını okur.
    Bot API (sendPhoto yanıtı) çoğunlukla views döndürmediği için mobil bu uçu kullanır.
    """
    if _client is None or not await _client.is_user_authorized():
        return JSONResponse(
            status_code=503,
            content={
                "error": {
                    "code": "telegram_not_configured",
                    "message": (
                        "Need TELEGRAM_API_ID, TELEGRAM_API_HASH, "
                        "TELEGRAM_SESSION_STRING in .env and run ./run_telegram_api.sh"
                    ),
                }
            },
        )
    ch = (body.channel or "").strip()
    if not ch and not (body.chat_id or "").strip():
        return JSONResponse(
            status_code=400,
            content={
                "error": {
                    "code": "bad_request",
                    "message": "channel or chatId is required",
                }
            },
        )
    if int(body.message_id) <= 0:
        return JSONResponse(
            status_code=400,
            content={
                "error": {
                    "code": "bad_request",
                    "message": "messageId must be a positive post id in the channel",
                },
            },
        )
    cands = _candidates_for_channel(ch, body.chat_id)
    if not cands:
        cands = [ch] if ch else []
    msg = None
    entity = None
    last_en: Optional[str] = None
    last_ft: Optional[str] = None
    mid = int(body.message_id)
    for c in cands:
        try:
            entity = await _client.get_entity(c)
        except Exception as e:
            last_en = str(e)[:200]
            continue
        try:
            rows = await _client.get_messages(entity, ids=mid)
        except RPCError as e:
            last_ft = e.__class__.__name__
            continue
        if isinstance(rows, list):
            m = rows[0] if rows else None
        else:
            m = rows
        if m and getattr(m, "id", None):
            msg = m
            break
    if not msg or not getattr(msg, "id", None):
        hint = ""
        if last_en or last_ft:
            hint = f" (last_entity={last_en!r} fetch={last_ft!r})"
        return JSONResponse(
            status_code=404,
            content={
                "error": {
                    "code": "not_found",
                    "message": "Message not in history or not accessible to this account"
                    + hint,
                }
            },
        )
    assert entity is not None
    views = int(getattr(msg, "views", 0) or 0)
    forwards = int(getattr(msg, "forwards", 0) or 0)
    reactions = _reaction_breakdown(msg)
    rpl = getattr(msg, "replies", None)
    reply_count = 0
    if rpl is not None:
        reply_count = int(getattr(rpl, "replies", 0) or 0)
    md = getattr(msg, "date", None)
    message_date_iso: Optional[str] = None
    if md is not None:
        if md.tzinfo is None:
            md = md.replace(tzinfo=timezone.utc)
        else:
            md = md.astimezone(timezone.utc)
        message_date_iso = md.isoformat()
    member_count: Optional[int] = None
    try:
        full = await _client(
            GetFullChannelRequest(channel=await _client.get_input_entity(entity))
        )
        mc = int(
            getattr(getattr(full, "full_chat", None), "participants_count", 0) or 0
        )
        member_count = mc if mc > 0 else None
    except Exception:
        member_count = None
    return {
        "data": {
            "views": views,
            "forwards": forwards,
            "reactions": reactions,
            "replies": reply_count,
            "messageDate": message_date_iso,
            "channelMemberCount": member_count,
        }
    }


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("TELEGRAM_INSIGHTS_PORT", "3000"))
    uvicorn.run(app, host="127.0.0.1", port=port)
