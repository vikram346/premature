
from fastapi import APIRouter, HTTPException, Query, Path
import httpx

from app.services.adultembed import (
    fetch_videos,
    search_videos,
    fetch_video_details,
    fetch_embed_url,
)

router = APIRouter(
    prefix="/videos",
    tags=["Videos"],
)


# Browse videos
@router.get("/")
async def get_videos(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
):
    try:
        return await fetch_videos(
            page=page,
            page_size=page_size,
        )

    except httpx.HTTPError as error:
        raise HTTPException(
            status_code=502,
            detail=f"External API request failed: {error}",
        )


# Search videos
@router.get("/search")
async def search_video_catalogue(
    q: str = Query(min_length=1),
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=20, ge=1, le=100),
):
    try:
        return await search_videos(
            query=q,
            page=page,
            per_page=per_page,
        )

    except httpx.HTTPError as error:
        raise HTTPException(
            status_code=502,
            detail=f"External API search failed: {error}",
        )


# Get video details
@router.get("/{video_id}")
async def get_video_details(
    video_id: int = Path(ge=1),
):
    try:
        return await fetch_video_details(
            video_id=video_id,
        )

    except httpx.HTTPStatusError as error:
        if error.response.status_code == 404:
            raise HTTPException(
                status_code=404,
                detail="Video not found or no longer playable",
            )

        raise HTTPException(
            status_code=502,
            detail="External API request failed",
        )

    except httpx.HTTPError:
        raise HTTPException(
            status_code=502,
            detail="Could not connect to external API",
        )


# Get signed video embed URL
@router.post("/{video_id}/embed")
async def get_video_embed(
    video_id: int = Path(ge=1),
):
    try:
        return await fetch_embed_url(video_id)

    except httpx.HTTPStatusError as error:
        if error.response.status_code == 404:
            raise HTTPException(
                status_code=404,
                detail="Video is no longer playable",
            )

        raise HTTPException(
            status_code=502,
            detail="External API request failed",
        )

    except httpx.HTTPError:
        raise HTTPException(
            status_code=502,
            detail="Could not connect to external API",
        )
