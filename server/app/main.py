
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import videos, image

app = FastAPI(
    title="StreamBox API",
    description="Backend for StreamBox",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(videos.router)
app.include_router(image.router)


@app.get("/")
def root():
    return {"message": "StreamBox API is running"}
