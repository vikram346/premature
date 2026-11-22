
import httpx
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import Response

router = APIRouter(prefix="/images", tags=["Images"])


@router.get("/proxy")
async def proxy_image(url: str = Query(...)):
    if not url.startswith("https://pornapi.sbs/"):
        raise HTTPException(status_code=400, detail=f"Rejected URL: {url}")

    try:
        async with httpx.AsyncClient(
            timeout=20,
            follow_redirects=True,
        ) as client:
            response = await client.get(
                url,
                headers={
                    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/131.0.0.0 Safari/537.36",
                    "Referer": "https://pornapi.sbs/",
                },
            )

            response.raise_for_status()

            content_type = response.headers.get("content-type", "image/jpeg")

            if not content_type.startswith("image/"):
                raise HTTPException(
                    status_code=502,
                    detail=f"Not an image: {content_type}",
                )

            return Response(
                content=response.content,
                media_type=content_type,
                headers={"Cache-Control": "public, max-age=3600"},
            )

    except httpx.HTTPStatusError as e:
        raise HTTPException(
            status_code=502,
            detail=f"Image server returned {e.response.status_code}",
        )
    except httpx.RequestError as e:
        raise HTTPException(status_code=502, detail=str(e))
