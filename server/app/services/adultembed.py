
import httpx

BASE_URL = "https://adultembed.com/api"


async def fetch_videos(page: int = 1, page_size: int = 20):
    url = f"{BASE_URL}/database/browse/"

    params = {
        "page": page,
        "page_size": page_size,
    }

    headers = {
        "X-Site-URL": "http://localhost:8000"
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.get(
            url,
            params=params,
            headers=headers,
        )

        response.raise_for_status()
        data = response.json()

    videos = []

    for item in data.get("results", []):
        videos.append({
            "id": item.get("id"),
            "title": item.get("title") or "Untitled",
            "thumbnail": item.get("thumbnail") or "",
            "duration": str(item.get("duration") or "Unknown"),
            "views": str(item.get("view_count") or 0),
            "description": item.get("description") or "",
        })

    return {
        "count": data.get("count", 0),
        "next": data.get("next"),
        "previous": data.get("previous"),
        "results": videos,
    }



async def search_videos(
    query: str,
    page: int = 1,
    per_page: int = 20,
):
    url = "https://adultembed.com/api/v1/search"

    params = {
        "query": query,
        "page": page,
        "per_page": per_page,
        "quality": "complete",
        "sort": "newest",
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.get(url, params=params)
        response.raise_for_status()
        data = response.json()

    videos = []

    for item in data.get("results", []):
        videos.append({
            "id": item.get("id"),
            "title": item.get("title") or "Untitled",
            "thumbnail": item.get("thumbnail") or "",
            "duration": str(item.get("duration") or "Unknown"),
            "views": str(item.get("view_count") or 0),
            "description": item.get("description") or "",
        })

    return {
        "count": data.get("count", 0),
        "next": data.get("next"),
        "previous": data.get("previous"),
        "results": videos,
    }
