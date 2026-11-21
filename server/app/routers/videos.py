
from fastapi import APIRouter, HTTPException, Query
import httpx
from app.services.adultembed import fetch_videos, search_videos

from app.services.adultembed import fetch_videos

router = APIRouter(
    prefix="/videos",
    tags=["Videos"],
)


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
