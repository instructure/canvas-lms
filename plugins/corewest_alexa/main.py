"""
Core West College AI LMS — Plugin Entry Point
Mounts the theme routes, static files, and authentication.
"""
from pathlib import Path
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import RedirectResponse

from theme_routes import router as theme_router

STATIC_DIR = Path(__file__).parent / "static"

app = FastAPI(
    title="Core West College AI LMS",
    description="AI-powered learning management system for Core West College",
    version="1.0.0",
)

# Mount static files
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

# Include theme routes
app.include_router(theme_router)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "Core West College AI LMS"}
