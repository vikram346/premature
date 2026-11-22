
import os
import re
import json
import asyncio
from urllib.parse import urlsplit

import httpx
from dotenv import load_dotenv

load_dotenv()

BASE_URL = os.getenv("PORNAPI_BASE_URL")
API_KEY = os.getenv("PORNAPI_API_KEY")

USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/131.0.0.0 Safari/537.36"
)


def get_headers():
    if not BASE_URL or not API_KEY:
        raise RuntimeError("API configuration missing from .env")

    return {
        "User-Agent": USER_AGENT,
        "X-VL-Key": API_KEY,
        "Accept": "application/json",
    }


async def fetch_videos(page=1, page_size=20, query=None):
    params = {
        "page": page,
        "per_page": page_size,
    }

    if query and query.strip():
        params["q"] = query.strip()

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(
            f"{BASE_URL}/videos",
            params=params,
            headers=get_headers(),
        )
        response.raise_for_status()
        return response.json()


async def fetch_video_details(video_id):
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(
            f"{BASE_URL}/videos/{video_id}",
            headers=get_headers(),
        )
        response.raise_for_status()
        return response.json()


async def is_stream_available(client, url, referer):
    """Check whether a small portion of the MP4 can be accessed."""

    if not url:
        return False

    headers = {
        "User-Agent": USER_AGENT,
        "Referer": referer,
        "Accept": "video/*, */*",
        "Range": "bytes=0-1023",
    }

    try:
        async with client.stream(
            "GET",
            url,
            headers=headers,
            timeout=15,
        ) as response:

            if response.status_code not in (200, 206):
                return False

            content_type = response.headers.get(
                "content-type", ""
            ).lower()

            if not (
                content_type.startswith("video/")
                or "octet-stream" in content_type
            ):
                return False

            # Confirm that the server actually sends some data.
            async for chunk in response.aiter_bytes():
                return bool(chunk)

            return False

    except (httpx.HTTPError, TimeoutError):
        return False


async def fetch_video_streams(video_id):
    if not BASE_URL:
        raise RuntimeError("PORNAPI_BASE_URL missing from .env")

    parsed_url = urlsplit(BASE_URL)
    origin = f"{parsed_url.scheme}://{parsed_url.netloc}"

    headers = {
        "User-Agent": USER_AGENT,
        "Referer": origin + "/",
        "Accept": "text/html",
    }

    async with httpx.AsyncClient(
        timeout=30,
        follow_redirects=True,
    ) as client:

        response = await client.get(
            f"{origin}/",
            params={"vl_embed": video_id},
            headers=headers,
        )
        response.raise_for_status()

        match = re.search(
            r"var\s+CFG\s*=\s*(\{.*?\});\s*\(function",
            response.text,
            re.DOTALL,
        )

        if not match:
            raise RuntimeError(
                "Could not find video stream configuration"
            )

        config = json.loads(match.group(1))
        provider_sources = config.get("sources", {})

        # Check all qualities concurrently.
        async def check_quality(quality, entries):
            if not entries:
                return None

            entry = entries[0]
            mp4_url = entry.get("d")
            hls_url = entry.get("u")

            available = await is_stream_available(
                client,
                mp4_url,
                origin + "/",
            )

            if not available:
                return None

            return quality, {
                "url": mp4_url,
                "hls_url": hls_url,
            }

        checks = await asyncio.gather(
            *[
                check_quality(quality, entries)
                for quality, entries in provider_sources.items()
            ]
        )

        playable_sources = {
            quality: source
            for result in checks
            if result is not None
            for quality, source in [result]
        }

        return {
            "id": video_id,
            "title": config.get("title", ""),
            "poster": config.get("poster", ""),
            "sources": playable_sources,
        }
