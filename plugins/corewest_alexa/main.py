"""
Core West College AI LMS — Alexa Plugin
FastAPI application entry-point.
"""

import os
from pathlib import Path

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse

from auth.dependencies import require_authenticated, verify_api_key
from auth.routes import router as auth_router

app = FastAPI(
    title="Core West College — Alexa Plugin",
    version="1.0.0",
    description="Alexa integration API for the Core West College AI LMS.",
)

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.environ.get("CORS_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Auth router
# ---------------------------------------------------------------------------

app.include_router(auth_router)

# ---------------------------------------------------------------------------
# Login page (public)
# ---------------------------------------------------------------------------

_LOGIN_PAGE = Path(__file__).parent / "auth" / "login_page.html"


@app.get("/login", response_class=HTMLResponse, include_in_schema=False)
async def login_page() -> HTMLResponse:
    """Serve the standalone HTML login form."""
    return HTMLResponse(content=_LOGIN_PAGE.read_text(encoding="utf-8"))


# ---------------------------------------------------------------------------
# Public endpoints
# ---------------------------------------------------------------------------


@app.get("/alexa/health")
async def health() -> JSONResponse:
    """Health-check — no authentication required."""
    return JSONResponse({"status": "ok"})


@app.get("/alexa/query")
async def alexa_query(q: str = "") -> JSONResponse:
    """Public query endpoint — no authentication required."""
    return JSONResponse({"query": q, "response": "Query received."})


# ---------------------------------------------------------------------------
# Protected endpoints
# ---------------------------------------------------------------------------


@app.get("/alexa/dashboard")
async def alexa_dashboard(
    _user=Depends(require_authenticated),
) -> JSONResponse:
    """Dashboard — requires a valid JWT (any role)."""
    return JSONResponse(
        {
            "message": f"Welcome, {_user.username}!",
            "role": _user.role,
        }
    )


@app.post("/alexa/webhook")
async def alexa_webhook(
    payload: dict,
    _key: str = Depends(verify_api_key),
) -> JSONResponse:
    """Alexa webhook — requires a valid X-API-Key header."""
    return JSONResponse({"received": True, "payload": payload})
