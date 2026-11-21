
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import videos
from fastapi import Query, HTTPException
from fastapi.responses import Response
from urllib.parse import urlparse
import httpx
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="StreamBox API",
    description="Backend for StreamBox",
    version="1.0.0",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5000",
        "http://127.0.0.1:5000",
        "http://10.185.51.132:5000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/images/proxy")
async def proxy_image(url: str = Query(...)):
    parsed_url = urlparse(url)

    # Only allow HTTPS images from imgds.net
    if (
        parsed_url.scheme != "https"
        or parsed_url.hostname != "imgds.net"
        or parsed_url.port not in (None, 443)
        or parsed_url.username is not None
        or parsed_url.password is not None
    ):
        raise HTTPException(
            status_code=400,
            detail="Invalid image URL",
        )

    try:
        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.get(
                url,
                follow_redirects=False,
            )

            response.raise_for_status()

        content_type = response.headers.get("content-type", "")

        if not content_type.startswith("image/"):
            raise HTTPException(
                status_code=400,
                detail="URL did not return an image",
            )

        if len(response.content) > 8 * 1024 * 1024:
            raise HTTPException(
                status_code=413,
                detail="Image is too large",
            )

        return Response(
            content=response.content,
            media_type=content_type,
            headers={"Cache-Control": "public, max-age=3600"},
        )

    except httpx.HTTPStatusError:
        raise HTTPException(
            status_code=502,
            detail="Thumbnail server returned an error",
        )

    except httpx.HTTPError:
        raise HTTPException(
            status_code=502,
            detail="Could not fetch thumbnail",
        )

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(videos.router)


@app.get("/")
def root():
    return {"message": "StreamBox API is running"}
