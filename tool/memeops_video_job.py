"""
OpenAI Sora 2 video job: image brief → animated mp4 → Supabase Storage + meme_asset_versions.

Tek bir HTTP isteği açıkken tüm iş (Sora create + polling + download + storage upload + DB insert)
tamamlanır; Flutter tek çağrıda `{fileUrl}` alır.
"""

from __future__ import annotations

import asyncio
import os
import uuid
from datetime import datetime, timezone
from typing import Any

import httpx

from memeops_profession_supabase import _sb_headers

_ALLOWED_SECONDS = {"4", "8", "12"}
_ALLOWED_SIZES_SORA2 = {"1280x720", "720x1280"}


def _auth_headers_raw(jwt: str) -> dict[str, str]:
    url = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
    anon = os.environ.get("SUPABASE_ANON_KEY", "").strip()
    if not url or not anon:
        raise RuntimeError("missing_supabase_env")
    return {
        "apikey": anon,
        "Authorization": f"Bearer {jwt}",
    }


def _openai_video_model() -> str:
    v = os.environ.get("OPENAI_VIDEO_MODEL", "sora-2").strip() or "sora-2"
    return v


def _openai_video_size() -> str:
    v = os.environ.get("OPENAI_VIDEO_SIZE", "720x1280").strip() or "720x1280"
    return v if v in _ALLOWED_SIZES_SORA2 else "720x1280"


def _max_wait_seconds() -> float:
    raw = os.environ.get("OPENAI_VIDEO_READ_TIMEOUT", "").strip()
    if raw:
        try:
            return max(180.0, min(float(raw), 1800.0))
        except ValueError:
            pass
    return 900.0


def _normalize_seconds(secs: str | int | None) -> str:
    s = str(secs or "4").strip()
    return s if s in _ALLOWED_SECONDS else "4"


def _prompt_for_video(brief: dict[str, Any]) -> str:
    line = (
        (brief.get("memotype_idea") or "").strip()
        or (brief.get("brief_title") or "").strip()
        or (brief.get("suggested_caption_ru") or "").strip()
    )
    return (
        "Short, punchy meme video clip. Keep the humor clear. "
        "Camera: subtle motion (slight push-in or static). "
        "Lighting: simple, readable. "
        f"Scene / joke: {line}"
    )


async def _generate_video_bytes(prompt: str, seconds: str, size: str, image_url: str | None) -> bytes:
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key:
        raise RuntimeError("missing_openai_key")

    model = _openai_video_model()
    timeout_total = _max_wait_seconds()
    openai_timeout = httpx.Timeout(connect=60.0, read=timeout_total, write=timeout_total, pool=timeout_total)

    def _sync() -> bytes:
        from openai import OpenAI

        client = OpenAI(api_key=key, timeout=openai_timeout, max_retries=1)
        create_kwargs: dict[str, Any] = {
            "model": model,
            "prompt": prompt,
            "seconds": seconds,
            "size": size,
        }
        ref_bytes: bytes | None = None
        if image_url:
            try:
                r = httpx.get(image_url, timeout=httpx.Timeout(connect=30.0, read=120.0, write=120.0, pool=120.0))
                r.raise_for_status()
                ref_bytes = r.content
            except Exception:
                ref_bytes = None

        if ref_bytes is not None:
            try:
                job = client.videos.create(
                    **create_kwargs,
                    input_reference=("reference.png", ref_bytes, "image/png"),
                )
            except TypeError:
                # SDK eski; input_reference yoksa referanssız dene
                job = client.videos.create(**create_kwargs)
        else:
            job = client.videos.create(**create_kwargs)

        import time as _time

        started = _time.time()
        while True:
            status = getattr(job, "status", None) or ""
            if status == "completed":
                break
            if status == "failed":
                err = getattr(job, "error", None)
                msg = getattr(err, "message", None) or "Sora video failed"
                raise RuntimeError(str(msg)[:400])
            if _time.time() - started > timeout_total:
                raise RuntimeError(f"sora_timeout_after_{int(timeout_total)}s")
            _time.sleep(4.0)
            job = client.videos.retrieve(job.id)

        try:
            content = client.videos.download_content(job.id)
        except TypeError:
            content = client.videos.download_content(video_id=job.id)
        data = getattr(content, "read", None)
        if callable(data):
            return content.read()
        if hasattr(content, "content"):
            return content.content
        if isinstance(content, (bytes, bytearray)):
            return bytes(content)
        raise RuntimeError("sora_download_unexpected_response")

    return await asyncio.to_thread(_sync)


async def run_meme_video_job(jwt: str, meme_brief_id: str, seconds: str | int | None) -> dict[str, Any]:
    url = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
    if not url:
        raise RuntimeError("missing_supabase_env")
    h = _sb_headers(jwt)
    auth_bin = _auth_headers_raw(jwt)
    secs = _normalize_seconds(seconds)
    size = _openai_video_size()
    job_timeout = _max_wait_seconds() + 120.0

    async with httpx.AsyncClient(
        timeout=httpx.Timeout(
            connect=120.0,
            read=job_timeout,
            write=job_timeout,
            pool=job_timeout,
        )
    ) as client:
        br = await client.get(
            f"{url}/rest/v1/meme_briefs?id=eq.{meme_brief_id}"
            "&select=id,workspace_id,profession_id,brief_title,memotype_idea,suggested_caption_ru",
            headers=h,
        )
        if br.status_code >= 400:
            raise RuntimeError(br.text)
        rows = br.json()
        if not rows:
            raise RuntimeError("brief_not_found")
        b = rows[0]
        workspace_id = b["workspace_id"]
        prof_id = b.get("profession_id")

        ar = await client.get(
            f"{url}/rest/v1/meme_assets?meme_brief_id=eq.{meme_brief_id}&select=id",
            headers=h,
        )
        if ar.status_code >= 400:
            raise RuntimeError(ar.text)
        existing = ar.json()
        image_url = None
        asset_id = existing[0]["id"] if existing else None
        if asset_id:
            vr = await client.get(
                f"{url}/rest/v1/meme_asset_versions?asset_id=eq.{asset_id}"
                "&select=version_number,file_url&order=version_number.desc&limit=1",
                headers=h,
            )
            if vr.status_code < 400:
                vrows = vr.json()
                if vrows:
                    image_url = vrows[0].get("file_url")

        prompt = _prompt_for_video(b)
        mp4 = await _generate_video_bytes(prompt, secs, size, image_url)
        object_path = f"{workspace_id}/{meme_brief_id}/video-{secs}s-{uuid.uuid4().hex}.mp4"
        up = await client.post(
            f"{url}/storage/v1/object/meme-assets/{object_path}",
            headers={
                **auth_bin,
                "Content-Type": "video/mp4",
                "x-upsert": "true",
            },
            content=mp4,
        )
        if up.status_code >= 400:
            raise RuntimeError(up.text)

        public_base = f"{url}/storage/v1/object/public/meme-assets"
        file_url = f"{public_base}/{object_path}"

        if asset_id:
            vr = await client.get(
                f"{url}/rest/v1/meme_asset_versions?asset_id=eq.{asset_id}"
                "&select=version_number&order=version_number.desc&limit=1",
                headers=h,
            )
            if vr.status_code >= 400:
                raise RuntimeError(vr.text)
            vrows = vr.json()
            next_v = (vrows[0]["version_number"] + 1) if vrows else 1
        else:
            cr = await client.post(
                f"{url}/rest/v1/meme_assets",
                headers=h,
                json={
                    "workspace_id": workspace_id,
                    "meme_brief_id": meme_brief_id,
                },
            )
            if cr.status_code >= 400:
                raise RuntimeError(cr.text)
            crow = cr.json()
            asset_row = crow[0] if isinstance(crow, list) else crow
            asset_id = asset_row["id"]
            next_v = 1

        job_ins = await client.post(
            f"{url}/rest/v1/ai_generation_jobs",
            headers=h,
            json={
                "workspace_id": workspace_id,
                "job_type": "video",
                "status": "processing",
                "meme_brief_id": meme_brief_id,
                "profession_id": prof_id,
                "provider": "openai_sora",
                "is_mock": False,
                "params": {
                    "model": _openai_video_model(),
                    "seconds": secs,
                    "size": size,
                },
            },
        )
        if job_ins.status_code >= 400:
            raise RuntimeError(job_ins.text)
        jrow = job_ins.json()
        job_row = jrow[0] if isinstance(jrow, list) else jrow
        job_id = job_row["id"]

        ver = await client.post(
            f"{url}/rest/v1/meme_asset_versions",
            headers=h,
            json={
                "asset_id": asset_id,
                "version_number": next_v,
                "file_url": file_url,
                "storage_path": object_path,
                "source_meme_brief_id": meme_brief_id,
                "provider": "openai_sora",
                "prompt_used": prompt[:4000],
                "review_status": "needs_review",
                "is_mock": False,
            },
        )
        if ver.status_code >= 400:
            raise RuntimeError(ver.text)
        vdata = ver.json()
        vrow = vdata[0] if isinstance(vdata, list) else vdata
        version_id = vrow["id"]

        done_at = datetime.now(timezone.utc).isoformat()
        patch = await client.patch(
            f"{url}/rest/v1/ai_generation_jobs?id=eq.{job_id}",
            headers=h,
            json={"status": "completed", "completed_at": done_at},
        )
        if patch.status_code >= 400:
            raise RuntimeError(patch.text)

        out_ins = await client.post(
            f"{url}/rest/v1/ai_generation_outputs",
            headers=h,
            json={
                "job_id": job_id,
                "output_kind": "video",
                "image_url": None,
                "storage_path": object_path,
            },
        )
        if out_ins.status_code >= 400:
            raise RuntimeError(out_ins.text)

        return {
            "jobId": str(job_id),
            "fileUrl": file_url,
            "assetVersionId": str(version_id),
            "seconds": secs,
        }
