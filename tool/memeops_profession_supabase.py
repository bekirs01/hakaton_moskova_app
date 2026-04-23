"""
Local MemeOps API: create profession + 5 meme_briefs via Supabase REST (user JWT).
Same contract as Next.js routes used by the Flutter app.
"""

from __future__ import annotations

import asyncio
import base64
import json
import os
import uuid
from typing import Any, Optional

import httpx

from memeops_openai_agents import llm_profession_situations


def _jwt_sub(token: str) -> Optional[str]:
    try:
        parts = token.split(".")
        if len(parts) != 3:
            return None
        pad = -len(parts[1]) % 4
        payload = parts[1] + ("=" * pad)
        raw = base64.urlsafe_b64decode(payload.encode("ascii"))
        data = json.loads(raw.decode("utf-8"))
        sub = data.get("sub")
        return str(sub) if sub else None
    except Exception:
        return None


async def _ensure_workspace_id(
    client: httpx.AsyncClient, url: str, h: dict[str, str], jwt: str
) -> str:
    wr = await client.get(
        f"{url}/rest/v1/workspace_members?select=workspace_id&limit=1",
        headers=h,
    )
    if wr.status_code >= 400:
        raise RuntimeError(wr.text)
    rows = wr.json()
    if rows:
        return str(rows[0]["workspace_id"])
    sub = _jwt_sub(jwt)
    if not sub:
        raise RuntimeError("invalid_jwt")
    for attempt in range(8):
        slug = f"w-{attempt}-{sub[:8]}-{uuid.uuid4().hex[:10]}"
        ws = await client.post(
            f"{url}/rest/v1/workspaces",
            headers=h,
            json={"name": "Workspace", "slug": slug, "created_by": sub},
        )
        if ws.status_code == 409:
            continue
        if ws.status_code >= 400:
            raise RuntimeError(ws.text)
        data = ws.json()
        row = data[0] if isinstance(data, list) else data
        wid = row["id"]
        mb = await client.post(
            f"{url}/rest/v1/workspace_members",
            headers=h,
            json={"workspace_id": wid, "user_id": sub, "role": "admin"},
        )
        if mb.status_code >= 400:
            raise RuntimeError(mb.text)
        return str(wid)
    raise RuntimeError("workspace_slug_conflict")


def _sb_headers(jwt: str) -> dict[str, str]:
    url = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
    anon = os.environ.get("SUPABASE_ANON_KEY", "").strip()
    if not url or not anon:
        raise RuntimeError("missing_supabase_env")
    return {
        "apikey": anon,
        "Authorization": f"Bearer {jwt}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }


def five_brief_lines(profession_title: str) -> list[str]:
    t = (profession_title or "").strip() or "тема"
    return [
        f"Мем-контраст: ожидание vs реальность в «{t}»",
        f"Реакция аудитории на пост/новость про «{t}»",
        f"Ирония над типичным спором в нише «{t}»",
        f"До/после: момент осознания про «{t}»",
        f"Внутренний жаргон / отсылка к «{t}» для своих",
    ]


def _situation_lines_for_profession(title: str) -> list[str]:
    """If OPENAI_API_KEY is set, LLM is mandatory — no silent template fallback."""
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if key:
        llm = llm_profession_situations(title)
        if llm and len(llm) >= 5:
            return llm
        raise RuntimeError(
            "openai_situations_failed: OpenAI returned no lines — check key, quota, "
            "network, OPENAI_TEXT_MODEL, or JSON parse errors in API logs."
        )
    return five_brief_lines(title)


async def insert_brief_ideas_for_profession(
    jwt: str, profession_id: str, ideas: list[str]
) -> tuple[str, list[str]]:
    """Persists 5–10 meme_brief rows; returns (job_label, brief_ids)."""
    url = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
    h = _sb_headers(jwt)
    ideas = [x.strip() for x in ideas if (x or "").strip()]
    if len(ideas) < 5:
        raise RuntimeError("not_enough_ideas")
    ideas = ideas[:10]
    async with httpx.AsyncClient(timeout=120.0) as client:
        gr = await client.get(
            f"{url}/rest/v1/professions?id=eq.{profession_id}&select=workspace_id,title",
            headers=h,
        )
        if gr.status_code >= 400:
            raise RuntimeError(gr.text)
        grows = gr.json()
        if not grows:
            raise RuntimeError("profession_not_found")
        wid = grows[0]["workspace_id"]
        brief_ids: list[str] = []
        for i, idea in enumerate(ideas):
            br = await client.post(
                f"{url}/rest/v1/meme_briefs",
                headers=h,
                json={
                    "workspace_id": wid,
                    "profession_id": profession_id,
                    "brief_title": idea[:200],
                    "memotype_idea": idea,
                    "suggested_caption_ru": idea[:900],
                    "internal_rank": i + 1,
                    "is_mock": False,
                },
            )
            if br.status_code >= 400:
                raise RuntimeError(br.text)
            row = br.json()
            if isinstance(row, list):
                row = row[0]
            brief_ids.append(row["id"])
        return "local-brief-batch", brief_ids


async def persist_telegram_channel_briefs(
    jwt: str,
    channel_url: str,
    insights: dict[str, Any],
    idea_lines: list[str],
) -> dict[str, Any]:
    """Creates profession from channel + inserts briefs; returns profession_id + brief rows."""
    title = (insights.get("channelTitle") or "Telegram channel").strip()
    desc = (insights.get("mainTopic") or "")[:2000]
    row = await create_profession_row(
        jwt,
        title,
        desc,
        f"Telegram: {channel_url.strip()[:500]}",
    )
    pid = row["id"]
    _, ids = await insert_brief_ideas_for_profession(jwt, pid, idea_lines)
    briefs: list[dict[str, Any]] = []
    for i, bid in enumerate(ids):
        line = idea_lines[i]
        briefs.append(
            {
                "id": bid,
                "brief_title": line[:200],
                "suggested_caption_ru": line[:900],
                "memotype_idea": line,
            }
        )
    return {"professionId": pid, "briefs": briefs}


async def create_profession_row(
    jwt: str,
    title: str,
    description: Optional[str],
    future_context: Optional[str],
) -> dict[str, Any]:
    url = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
    h = _sb_headers(jwt)
    async with httpx.AsyncClient(timeout=60.0) as client:
        wid = await _ensure_workspace_id(client, url, h, jwt)
        pr = await client.post(
            f"{url}/rest/v1/professions",
            headers=h,
            json={
                "workspace_id": wid,
                "title": title,
                "description": description,
                "future_context": future_context,
            },
        )
        if pr.status_code >= 400:
            raise RuntimeError(pr.text)
        data = pr.json()
        return data[0] if isinstance(data, list) else data


async def insert_five_briefs(jwt: str, profession_id: str) -> tuple[str, list[str]]:
    url = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
    h = _sb_headers(jwt)
    async with httpx.AsyncClient(timeout=90.0) as client:
        gr = await client.get(
            f"{url}/rest/v1/professions?id=eq.{profession_id}&select=workspace_id,title",
            headers=h,
        )
        if gr.status_code >= 400:
            raise RuntimeError(gr.text)
        grows = gr.json()
        if not grows:
            raise RuntimeError("profession_not_found")
        title = grows[0].get("title") or "channel"
    ideas = await asyncio.to_thread(_situation_lines_for_profession, str(title))
    return await insert_brief_ideas_for_profession(jwt, profession_id, ideas)
