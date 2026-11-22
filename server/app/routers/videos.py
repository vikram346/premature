
from fastapi import APIRouter, HTTPException, Query
import httpx

from app.services.video_api import (
    fetch_videos,
    fetch_video_details,
    fetch_video_streams,
)

router = APIRouter(prefix="/videos", tags=["Videos"])


def handle_error(error):
    if isinstance(error, httpx.HTTPStatusError):
        return HTTPException(
            status_code=error.response.status_code,
            detail="Video API request failed",
        )

    if isinstance(error, httpx.RequestError):
        return HTTPException(
            status_code=502,
            detail="Unable to connect to video API",
        )

    return HTTPException(
        status_code=500,
        detail=str(error),
    )


@router.get("/")
async def get_videos(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    q: str | None = Query(default=None, max_length=100),
):
    try:
        return await fetch_videos(
            page=page,
            page_size=page_size,
            query=q,
        )
    except (httpx.HTTPStatusError, httpx.RequestError, RuntimeError) as e:
        raise handle_error(e)


@router.get("/{video_id}/streams")
async def get_video_streams(video_id: int):
    try:
        data = await fetch_video_streams(video_id)

        if not data["sources"]:
            raise HTTPException(
                status_code=404,
                detail="This video is currently unavailable.",
            )

        return data

    except (httpx.HTTPStatusError, httpx.RequestError, RuntimeError) as e:
        raise handle_error(e)


@router.get("/{video_id}")
async def get_video_details(video_id: int):
    try:
        return await fetch_video_details(video_id)
    except (httpx.HTTPStatusError, httpx.RequestError, RuntimeError) as e:
        raise handle_error(e)
