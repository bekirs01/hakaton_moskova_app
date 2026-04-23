"""
Create meme image via OpenAI, upload to Supabase Storage, insert asset rows (user JWT).
"""

from __future__ import annotations

import asyncio
import os
import uuid
from datetime import datetime, timezone
from typing import Any

import httpx

from memeops_openai_agents import (
    generate_meme_image_png_bytes,
    meme_image_job_max_wait_seconds,
)
from memeops_profession_supabase import _sb_headers


def _auth_headers_raw(jwt: str) -> dict[str, str]:
    url = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
    anon = os.environ.get("SUPABASE_ANON_KEY", "").strip()
    if not url or not anon:
        raise RuntimeError("missing_supabase_env")
    return {
        "apikey": anon,
        "Authorization": f"Bearer {jwt}",
    }


async def run_meme_image_job(jwt: str, meme_brief_id: str) -> dict[str, Any]:
    url = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
    h = _sb_headers(jwt)
    auth_bin = _auth_headers_raw(jwt)

    job_timeout = meme_image_job_max_wait_seconds()
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
        theme = (
            (b.get("memotype_idea") or "").strip()
            or (b.get("brief_title") or "").strip()
            or (b.get("suggested_caption_ru") or "").strip()
        )
        if not theme:
            raise RuntimeError("brief_empty_theme")

        png, prompt_used = await asyncio.to_thread(
            generate_meme_image_png_bytes, theme
        )
        object_path = f"{workspace_id}/{meme_brief_id}/{uuid.uuid4().hex}.png"
        up = await client.post(
            f"{url}/storage/v1/object/meme-assets/{object_path}",
            headers={
                **auth_bin,
                "Content-Type": "image/png",
                "x-upsert": "true",
            },
            content=png,
        )
        if up.status_code >= 400:
            raise RuntimeError(up.text)

        public_base = f"{url}/storage/v1/object/public/meme-assets"
        file_url = f"{public_base}/{object_path}"

        ar = await client.get(
            f"{url}/rest/v1/meme_assets?meme_brief_id=eq.{meme_brief_id}&select=id",
            headers=h,
        )
        if ar.status_code >= 400:
            raise RuntimeError(ar.text)
        existing = ar.json()
        if existing:
            asset_id = existing[0]["id"]
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

        prof_id = b.get("profession_id")
        job_ins = await client.post(
            f"{url}/rest/v1/ai_generation_jobs",
            headers=h,
            json={
                "workspace_id": workspace_id,
                "job_type": "image",
                "status": "processing",
                "meme_brief_id": meme_brief_id,
                "profession_id": prof_id,
                "provider": "openai",
                "is_mock": False,
                "params": {"model": os.environ.get("OPENAI_IMAGE_MODEL", "gpt-image-1")},
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
                "provider": "openai",
                "prompt_used": prompt_used[:4000],
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
                "output_kind": "image",
                "image_url": file_url,
                "storage_path": object_path,
            },
        )
        if out_ins.status_code >= 400:
            raise RuntimeError(out_ins.text)

        return {
            "jobId": str(job_id),
            "fileUrl": file_url,
            "assetVersionId": str(version_id),
        }
