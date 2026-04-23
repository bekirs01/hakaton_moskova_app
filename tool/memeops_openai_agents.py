"""
OpenAI helpers for local MemeOps API (secrets only in server .env).

Agent 1: short funny / meme-worthy situations from a profession name.
Agent 2: single meme image (classic top/bottom text style in prompt).
"""

from __future__ import annotations

import base64
import json
import os
import re
from typing import Any, List, Optional

import httpx

_PROFESSION_SYSTEM = """You are a comedy writer for internet memes.

Given a profession (may be fictional or real), output EXACTLY one JSON array of strings.
Requirements:
- 7 to 10 items (inclusive).
- Each item: one short situation or punchline (1–2 sentences max) that is funny, meme-friendly,
  and specific to that profession (tools, clients, absurd daily moments).
- Mix languages if the profession name suggests it; default to Russian if unsure.
- No numbering, no markdown, no keys — ONLY a JSON array like ["line1", "line2", ...].
"""


_MEME_IMAGE_SYSTEM = """You are a professional internet meme image generator.

Rules:
1) Use a recognizable classic meme format when it fits (Drake, distracted boyfriend, doge, wojak, this is fine, etc.)
2) The image must be understandable without extra explanation.
3) Short, punchy vibe — classic TOP text + BOTTOM text layout when appropriate.
4) Viral, slightly exaggerated, not hateful or NSFW.
"""


def _openai_text_model() -> str:
    return os.environ.get("OPENAI_TEXT_MODEL", "gpt-4o-mini").strip() or "gpt-4o-mini"


def _openai_image_model() -> str:
    return os.environ.get("OPENAI_IMAGE_MODEL", "gpt-image-1").strip() or "gpt-image-1"


def llm_profession_situations(profession_title: str) -> Optional[List[str]]:
    """Returns 7–10 lines, or None if no key / failure."""
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key:
        return None
    title = (profession_title or "").strip() or "профессия"
    try:
        from openai import OpenAI

        client = OpenAI(api_key=key)
        r = client.chat.completions.create(
            model=_openai_text_model(),
            messages=[
                {"role": "system", "content": _PROFESSION_SYSTEM},
                {
                    "role": "user",
                    "content": f'Profession / role (free text): "{title}"\nReturn only the JSON array.',
                },
            ],
            max_tokens=900,
            temperature=0.9,
        )
        raw = (r.choices[0].message.content or "").strip()
        raw = re.sub(r"^```(?:json)?\s*", "", raw, flags=re.I)
        raw = re.sub(r"\s*```\s*$", "", raw)
        data = json.loads(raw)
        if not isinstance(data, list):
            return None
        out: list[str] = []
        for x in data:
            if isinstance(x, str):
                s = x.strip()
                if s and s not in out:
                    out.append(s)
        if len(out) < 5:
            return None
        return out[:10]
    except Exception:
        return None


def build_meme_image_user_prompt(theme: str) -> str:
    t = (theme or "").strip()
    return f"""{_MEME_IMAGE_SYSTEM}

Meme theme / situation (from previous agent):
{t}

Create ONE square meme image that captures this."""


def generate_meme_image_png_bytes(theme: str) -> tuple[bytes, str]:
    """Returns PNG bytes and the prompt used. Raises RuntimeError on failure."""
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key:
        raise RuntimeError("missing_openai_key")
    prompt = build_meme_image_user_prompt(theme)
    from openai import OpenAI

    # SDK default httpx timeouts are short; ~10s generation still needs headroom for TLS/TTFB.
    # "Connection error." from the SDK is usually a dropped idle socket / transient network, not "need 10 min".
    client = OpenAI(
        api_key=key,
        timeout=httpx.Timeout(90.0, connect=20.0),
        max_retries=2,
    )
    try:
        # b64_json: ikinci bir URL indirme adımı yok; "Connection error" / CDN kopmaları azalır.
        result = client.images.generate(
            model=_openai_image_model(),
            prompt=prompt,
            size="1024x1024",
            response_format="b64_json",
            quality=os.environ.get("OPENAI_IMAGE_QUALITY", "medium").strip() or "medium",
        )
    except Exception as e:
        raise RuntimeError(str(e)[:500]) from e

    if not result.data:
        raise RuntimeError("OpenAI returned no image entries")
    item = result.data[0]
    if item.b64_json:
        return base64.b64decode(item.b64_json), prompt
    if item.url:
        try:
            r = httpx.get(item.url, timeout=httpx.Timeout(60.0, connect=15.0))
            r.raise_for_status()
            return r.content, prompt
        except Exception as e:
            raise RuntimeError(
                f"Image URL fetch failed (prefer b64 from API): {str(e)[:400]}"
            ) from e
    raise RuntimeError("OpenAI returned neither b64_json nor url")


def llm_telegram_meme_lines(
    insights: dict[str, Any], n_min: int = 7, n_max: int = 10
) -> Optional[List[str]]:
    """Richer meme lines from channel insights JSON."""
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key:
        return None
    try:
        from openai import OpenAI

        client = OpenAI(api_key=key)
        payload = json.dumps(insights, ensure_ascii=False)[:14000]
        r = client.chat.completions.create(
            model=_openai_text_model(),
            messages=[
                {
                    "role": "system",
                    "content": (
                        f"You output EXACTLY one JSON array of {n_min} to {n_max} strings. "
                        "Each string: one short, funny, meme-ready one-liner grounded in the channel analysis JSON. "
                        "Match the channel language when obvious. "
                        "No markdown, only the JSON array."
                    ),
                },
                {"role": "user", "content": payload},
            ],
            max_tokens=900,
            temperature=0.85,
        )
        raw = (r.choices[0].message.content or "").strip()
        raw = re.sub(r"^```(?:json)?\s*", "", raw, flags=re.I)
        raw = re.sub(r"\s*```\s*$", "", raw)
        data = json.loads(raw)
        if not isinstance(data, list):
            return None
        out: list[str] = []
        for x in data:
            if isinstance(x, str):
                s = re.sub(r"^\d+[\).\s]+", "", x.strip())
                if s and s not in out:
                    out.append(s)
        if len(out) < n_min:
            return None
        return out[:n_max]
    except Exception:
        return None
