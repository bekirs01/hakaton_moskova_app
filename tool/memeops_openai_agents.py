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
import time
from typing import Any, List, Optional, Tuple

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
    # gpt-image-1-mini: daha düşük gecikme / maliyet; kalite için .env ile gpt-image-1 veya 1.5
    return os.environ.get("OPENAI_IMAGE_MODEL", "gpt-image-1-mini").strip() or "gpt-image-1-mini"


def _openai_image_quality() -> str:
    # low: en hızlı üretim (token sayısı düşük); final kalite için medium/high
    return os.environ.get("OPENAI_IMAGE_QUALITY", "low").strip() or "low"


def _openai_image_size() -> str:
    allowed = {"1024x1024", "1024x1536", "1536x1024", "auto"}
    v = os.environ.get("OPENAI_IMAGE_SIZE", "1024x1024").strip() or "1024x1024"
    return v if v in allowed else "1024x1024"


def openai_image_read_timeout_seconds() -> float:
    """Görsel üretim HTTP okuma üst sınırı (sn). Kısa değerlerde SDK sık 'Connection error.' döner."""
    raw = os.environ.get("OPENAI_IMAGE_READ_TIMEOUT", "").strip()
    if raw:
        try:
            return max(120.0, min(float(raw), 1200.0))
        except ValueError:
            pass
    return 900.0


def meme_image_job_max_wait_seconds() -> float:
    """OpenAI (10 dk) + b64 + Supabase Storage + REST — tek AsyncClient üst sınırı."""
    return openai_image_read_timeout_seconds() + 180.0


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

The image MUST match this exact situation / joke (same meaning and punchline idea). Use it as the single source of truth for what to draw:
{t}

Create ONE square meme that clearly illustrates the situation above (classic meme layout when it helps)."""


def _generate_meme_image_png_bytes_once(theme: str) -> Tuple[bytes, str]:
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key:
        raise RuntimeError("missing_openai_key")
    prompt = build_meme_image_user_prompt(theme)
    from openai import OpenAI

    read_sec = openai_image_read_timeout_seconds()
    client = OpenAI(
        api_key=key,
        timeout=httpx.Timeout(connect=120.0, read=read_sec, write=read_sec, pool=read_sec),
        max_retries=2,
    )
    model = _openai_image_model()
    gen_kwargs: dict[str, Any] = {
        "model": model,
        "prompt": prompt,
        "size": _openai_image_size(),
        "quality": _openai_image_quality(),
    }
    # GPT Image (gpt-image-*) API: response_format desteklenmiyor → 400 unknown_parameter.
    if model.startswith("dall-e"):
        gen_kwargs["response_format"] = "b64_json"
    if model.startswith("gpt-image"):
        mod = os.environ.get("OPENAI_IMAGE_MODERATION", "low").strip() or "low"
        if mod in ("low", "auto"):
            gen_kwargs["moderation"] = mod
    try:
        result = client.images.generate(**gen_kwargs)
    except Exception as e:
        raise RuntimeError(str(e)[:500]) from e

    if not result.data:
        raise RuntimeError("OpenAI returned no image entries")
    item = result.data[0]
    if item.b64_json:
        return base64.b64decode(item.b64_json), prompt
    if item.url:
        try:
            r = httpx.get(
                item.url,
                timeout=httpx.Timeout(min(read_sec, 300.0), connect=45.0),
            )
            r.raise_for_status()
            return r.content, prompt
        except Exception as e:
            raise RuntimeError(
                f"Image URL fetch failed (prefer b64 from API): {str(e)[:400]}"
            ) from e
    raise RuntimeError("OpenAI returned neither b64_json nor url")


def _transient_image_error(msg: str) -> bool:
    low = msg.lower()
    return any(
        x in low
        for x in (
            "connection",
            "timeout",
            "temporarily",
            "network",
            "503",
            "502",
            "429",
            "disconnect",
            "reset",
            "eof",
        )
    )


def generate_meme_image_png_bytes(theme: str) -> tuple[bytes, str]:
    """Returns PNG bytes and the prompt used. Raises RuntimeError on failure."""
    for attempt in range(3):
        try:
            return _generate_meme_image_png_bytes_once(theme)
        except RuntimeError as e:
            if attempt < 2 and _transient_image_error(str(e)):
                time.sleep(2.0 * (attempt + 1))
                continue
            raise
    raise RuntimeError("meme image: retry loop exhausted")


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
