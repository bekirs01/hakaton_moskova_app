"""
Server-side channel analysis from Telethon message batches.
No Flutter / no secrets in client. Optional OPENAI_API_KEY for image understanding + idea wording.
"""

from __future__ import annotations

import base64
import json
import os
import re
from collections import Counter
from typing import Any, List, Optional

# --- text helpers ---

def _tokens(blob: str) -> list[str]:
    return [
        w.lower()
        for w in re.findall(r"[^\W\d_]+", blob, flags=re.UNICODE)
        if len(w) >= 3
    ]


_TR_STOP = frozenset(
    "bir bu şu o da de mi için veya ile çok daha en gibi kadar sonra olan var ve "
    "ileti güncelle paylaş kanal birkaç göre görecek".split()
)
_EN_STOP = frozenset(
    "the and for are but not you all can her was one our out day get use man new now way may "
    "any how its who web org com www http https".split()
)


ARCHETYPE_LEX = {
    "news / current events": (
        "breaking update official report government election war crisis "
        "minister president vote sanction border"
    ).split(),
    "tech / product": (
        "software code github api app launch startup ai model server "
        "developer programming bug feature update release"
    ).split(),
    "humor / memes": (
        "lol meme joke funny haha cringe based ironic satire shitpost "
        "reaction mood same energy"
    ).split(),
    "community / chat": (
        "join discussion chat thanks welcome everyone reminder rules "
        "group channel members poll question"
    ).split(),
    "promotional / brand": (
        "sale discount offer subscribe link bio promo sponsor affiliate "
        "shop buy price order delivery"
    ).split(),
    "educational / explainer": (
        "how why what learn tutorial guide explain step tip resource "
        "thread notes summary"
    ).split(),
}


def _infer_tone_profile(blob: str) -> str:
    b = blob.lower()
    scores: dict[str, int] = {}
    for label, words in ARCHETYPE_LEX.items():
        scores[label] = sum(1 for w in words if w in b)
    best = max(scores.values()) if scores else 0
    if best < 3:
        if len(blob) > 4000:
            return "editorial / long-form (mixed)"
        return "general / mixed voice"
    top = [k for k, v in scores.items() if v == best]
    return top[0] if len(top) == 1 else f"{top[0]} + {top[1]}"


def classify_post_row(
    text: Optional[str], has_photo: bool, has_video: bool, is_fwd: bool
) -> str:
    t = (text or "").strip()
    if is_fwd:
        return "forward / reshare"
    if has_video and not t:
        return "video-only post"
    if has_photo and not t:
        return "image-only post"
    if re.search(r"https?://", t):
        return "link / URL share"
    if len(t) > 280:
        return "long text post"
    if len(t) > 0:
        return "short text post"
    if has_photo:
        return "photo post"
    return "other"


def _recent_highlights(texts: list[str], k: int = 5) -> list[str]:
    out: list[str] = []
    for raw in texts[:80]:
        one = raw.strip().replace("\n", " ")
        if not one:
            continue
        if len(one) > 160:
            one = one[:157] + "…"
        out.append(one)
        if len(out) >= k:
            break
    return out


def _hour_bucket(hour: int) -> str:
    start = (hour // 3) * 3
    end = (start + 3) % 24
    return f"{start:02d}:00-{end:02d}:00"


def _activity_windows(message_meta: list[dict[str, Any]]) -> list[str]:
    buckets = Counter()
    for meta in message_meta:
        hour = meta.get("hour")
        if isinstance(hour, int):
            buckets[_hour_bucket(hour)] += 1
    out: list[str] = []
    for bucket, count in buckets.most_common(3):
        out.append(f"{bucket} spike ({count} posts in sample)")
    return out


def _clip_snippet(text: str, limit: int = 72) -> str:
    one = re.sub(r"\s+", " ", (text or "").strip())
    if not one:
        return "media-first post"
    if len(one) > limit:
        return one[: limit - 1] + "…"
    return one


def _top_posts(message_meta: list[dict[str, Any]]) -> list[str]:
    ranked = sorted(
        message_meta,
        key=lambda x: (
            int(x.get("reactions") or 0),
            int(x.get("views") or 0),
        ),
        reverse=True,
    )
    out: list[str] = []
    for meta in ranked[:4]:
        stamp = meta.get("date_label") or "--"
        views = int(meta.get("views") or 0)
        reactions = int(meta.get("reactions") or 0)
        out.append(
            f"{stamp} • {views} views • {reactions} reactions • {_clip_snippet(str(meta.get('text') or ''))}"
        )
    return out


def _engagement_insights(
    message_meta: list[dict[str, Any]], photo_n: int, video_n: int
) -> list[str]:
    if not message_meta:
        return ["Engagement stats need a live message sample."]
    rated = [m for m in message_meta if int(m.get("views") or 0) > 0]
    avg_rate = 0.0
    if rated:
        avg_rate = sum((int(m.get("reactions") or 0) / max(int(m.get("views") or 1), 1)) for m in rated) / len(rated)

    photo_scores = [int(m.get("reactions") or 0) + int(m.get("views") or 0) * 0.01 for m in message_meta if m.get("has_photo")]
    video_scores = [int(m.get("reactions") or 0) + int(m.get("views") or 0) * 0.01 for m in message_meta if m.get("has_video")]
    text_scores = [
        int(m.get("reactions") or 0) + int(m.get("views") or 0) * 0.01
        for m in message_meta
        if not m.get("has_photo") and not m.get("has_video")
    ]

    format_scores = {
        "photo posts": (sum(photo_scores) / len(photo_scores)) if photo_scores else 0.0,
        "video posts": (sum(video_scores) / len(video_scores)) if video_scores else 0.0,
        "text-only posts": (sum(text_scores) / len(text_scores)) if text_scores else 0.0,
    }
    best_format = max(format_scores, key=format_scores.get)

    out = [
        f"Best performing format in this sample: {best_format}.",
        f"Average reaction-to-view ratio: {avg_rate * 100:.2f}%.",
    ]
    if video_n and format_scores["video posts"] >= format_scores["photo posts"]:
        out.append("Video posts are carrying at least as much response as photos.")
    elif photo_n:
        out.append("Static visuals still dominate the strongest response pockets.")
    return out


def _vision_openai(image_bytes_list: list[bytes]) -> list[str]:
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key or not image_bytes_list:
        return []
    try:
        from openai import OpenAI

        client = OpenAI(api_key=key)
        content: list[dict[str, Any]] = [
            {
                "type": "text",
                "text": (
                    "In one short English sentence each, describe what this Telegram channel image "
                    "is probably about (topic, setting, UI screenshot vs photo vs meme). "
                    "Be concrete. No preamble."
                ),
            }
        ]
        for raw in image_bytes_list[:4]:
            b64 = base64.standard_b64encode(raw).decode("ascii")
            content.append(
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{b64}",
                        "detail": "low",
                    },
                }
            )
        r = client.chat.completions.create(
            model=os.environ.get("OPENAI_VISION_MODEL", "gpt-4o-mini"),
            messages=[{"role": "user", "content": content}],
            max_tokens=400,
        )
        txt = (r.choices[0].message.content or "").strip()
        lines = [ln.strip("- •\t ") for ln in txt.split("\n") if ln.strip()]
        return lines[: len(image_bytes_list)]
    except Exception:
        return []


def _ideas_openai(insights: dict[str, Any]) -> Optional[List[str]]:
    """Legacy line-based parser (fallback)."""
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key:
        return None
    try:
        from openai import OpenAI

        client = OpenAI(api_key=key)
        payload = json.dumps(insights, ensure_ascii=False)[:12000]
        r = client.chat.completions.create(
            model=os.environ.get("OPENAI_TEXT_MODEL", "gpt-4o-mini"),
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You generate exactly 8 short meme idea one-liners for creators. "
                        "Language: match the channel (often English or Turkish). "
                        "Each line: one idea only, no numbering prefix, viral-friendly, "
                        "grounded in the JSON channel analysis."
                    ),
                },
                {"role": "user", "content": payload},
            ],
            max_tokens=700,
        )
        txt = (r.choices[0].message.content or "").strip()
        lines = []
        for ln in txt.split("\n"):
            ln = re.sub(r"^\d+[\).\s]+", "", ln.strip())
            if ln:
                lines.append(ln)
        if len(lines) >= 5:
            return lines[:10]
    except Exception:
        pass
    return None


def _ideas_rule_based(insights: dict[str, Any]) -> list[str]:
    themes = insights.get("recurringThemes") or []
    angles = insights.get("memeableAngles") or []
    topic = insights.get("mainTopic") or "this channel"
    mi = insights.get("mediaInsights") or []
    media_hint = mi[0] if mi else "the channel’s visuals"
    t0 = themes[0] if themes else "the main topic"
    t1 = themes[1] if len(themes) > 1 else "a side theme"
    a0 = angles[0] if angles else "a running joke"
    return [
        f"When {topic.split('.')[0][:80]} hits the timeline — reaction meme from audience POV.",
        f"Contrast post: expectations vs reality around “{t0}”.",
        f"Screenshot energy: exaggerate the most {t1}-adjacent complaint in the comments.",
        f"Play on {a0.lower()} as a 3-panel escalation meme.",
        f"Visual gag tying {media_hint.lower()[:100]} to an everyday frustration.",
    ]


def build_meme_variants(insights: dict[str, Any]) -> list[dict[str, Any]]:
    from memeops_openai_agents import llm_telegram_meme_lines

    ideas = llm_telegram_meme_lines(insights, n_min=7, n_max=10)
    if not ideas:
        oai = _ideas_openai(insights)
        ideas = oai if oai and len(oai) >= 5 else _ideas_rule_based(insights)
    ideas = ideas[:10]
    out: list[dict[str, Any]] = []
    for i, line in enumerate(ideas):
        out.append(
            {
                "id": f"local-mv-{i}",
                "brief_title": line[:200],
                "suggested_caption_ru": None,
                "memotype_idea": line,
            }
        )
    while len(out) < 5:
        out.append(
            {
                "id": f"local-mv-{len(out)}",
                "brief_title": f"Angle {len(out)+1} on {insights.get('channelTitle', 'channel')}",
                "suggested_caption_ru": None,
                "memotype_idea": "Spin a relatable joke from recurring themes.",
            }
        )
    return out[:10]


def analyze_channel_batch(
    channel_url: str,
    channel_title: str,
    texts: list[str],
    captions: list[str],
    message_meta: list[dict[str, Any]],
    post_types: list[str],
    photo_n: int,
    video_n: int,
    doc_n: int,
    image_bytes_for_vision: list[bytes],
) -> dict[str, Any]:
    blob = " ".join(texts + captions).strip()
    words = [w for w in _tokens(blob) if w not in _EN_STOP and w not in _TR_STOP]
    top = [w for w, _ in Counter(words).most_common(12)]
    hashtags = re.findall(r"#[\w\u0400-\u04FF]+", blob)
    tag_themes = [h.strip("#").lower() for h in hashtags[:8]]

    themes = list(dict.fromkeys(tag_themes + top))[:12]

    if not themes and not blob:
        themes = ["(no text in sample — media-only or empty channel window)"]

    tone_profile = _infer_tone_profile(blob)
    exclam = blob.count("!") + blob.count("?")
    tone_mood = "Measured"
    if exclam > len(texts) * 0.35 and texts:
        tone_mood = "Punchy / reactive"
    elif len(blob) > 6000:
        tone_mood = "Dense / essay-like cadence"

    tone = f"{tone_mood}; channel feels {tone_profile}"

    vision_lines = _vision_openai(image_bytes_for_vision)
    media_insights: list[str] = []
    if photo_n:
        media_insights.append(f"{photo_n} posts with photos in the sample.")
    if video_n:
        media_insights.append(f"{video_n} video posts.")
    if doc_n:
        media_insights.append(f"{doc_n} file/document attachments.")
    cap_nonempty = [c for c in captions if c.strip()]
    if cap_nonempty:
        media_insights.append(
            f"Image captions sampled: {cap_nonempty[0][:120]}{'…' if len(cap_nonempty[0]) > 120 else ''}"
        )
    if vision_lines:
        media_insights.extend(f"Image signal: {ln}" for ln in vision_lines[:4])
    elif photo_n and not vision_lines:
        media_insights.append(
            "Photos present; add OPENAI_API_KEY in .env for automatic image-topic hints."
        )

    pt = Counter(post_types)
    post_type_summary = [f"{k} ({v})" for k, v in pt.most_common(6)]

    text_count = sum(1 for t in texts if (t or "").strip())

    media_types: list[str] = []
    if text_count:
        media_types.append(f"text-heavy ({text_count} posts)")
    if photo_n:
        media_types.append("photos")
    if video_n:
        media_types.append("videos")
    if doc_n:
        media_types.append("documents/files")
    if not media_types:
        media_types.append("unknown / empty window")

    if top[:4]:
        main = (
            f"“{channel_title}” centers on: {', '.join(top[:4])}. "
            f"Overall voice: {tone_profile}."
        )
    elif tag_themes:
        main = (
            f"“{channel_title}” is tag-driven around: {', '.join(tag_themes[:4])}. "
            f"Style: {tone_profile}."
        )
    else:
        main = (
            f"“{channel_title}” — limited text in the fetched window; "
            f"leaning on media ({', '.join(media_types)}). "
            f"Try increasing fetch or ensure the channel is public."
        )

    highlights = _recent_highlights(texts, 5)
    activity_windows = _activity_windows(message_meta)
    top_posts = _top_posts(message_meta)
    engagement_insights = _engagement_insights(message_meta, photo_n, video_n)
    angles = [
        f"Meme the tension between “{tone_profile.split('/')[0].strip()}” posts and audience fatigue",
        "Before/after: calm announcement vs chaotic comments",
        f"Running joke on keyword “{top[0]}”" if top else "Running joke on the channel’s recurring format",
        "Reaction meme: ‘POV: you just saw this in the feed’",
        "Contrast official tone vs how subscribers would paraphrase it",
    ]

    return {
        "channelUrl": channel_url,
        "channelTitle": channel_title,
        "mainTopic": main,
        "recurringThemes": themes[:12],
        "tone": tone,
        "toneProfile": tone_profile,
        "mediaTypes": media_types,
        "mediaInsights": media_insights[:10],
        "postTypes": post_type_summary,
        "activityWindows": activity_windows,
        "topPosts": top_posts,
        "engagementInsights": engagement_insights,
        "sampleSize": len(message_meta),
        "recentHighlights": highlights,
        "memeableAngles": angles[:8],
        "analysisSource": "telethon_live",
    }
