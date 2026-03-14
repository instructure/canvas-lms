"""
Core West Unified API — Application Entry Point
Mounts the LMS theme routes, static files, and the Alexa Voice API endpoints.
"""

from __future__ import annotations

import logging
import sys
from pathlib import Path

from fastapi import Depends, FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import settings
from data_aggregator import DataAggregator
from theme_routes import router as theme_router

# ---------------------------------------------------------------------------
# Curriculum & Inspection routers
# ---------------------------------------------------------------------------
from curriculum.routes import curriculum_router, inspection_router  # noqa: E402
from curriculum.curriculum_monitor import CurriculumMonitor          # noqa: E402
from curriculum.inspection_readiness import InspectionReadinessEngine  # noqa: E402
from curriculum.performance_tracker import PerformanceTracker          # noqa: E402

_monitor = CurriculumMonitor()
_readiness = InspectionReadinessEngine()
_performance = PerformanceTracker()

_logger = logging.getLogger(__name__)

# Minimal fallback API key validator used when the auth module is unavailable.
_FALLBACK_API_KEY = os.environ.get("ALEXA_API_KEY", "")


async def _fallback_verify_api_key(request: Request) -> None:
    """Require a valid API key header when the auth module is absent."""
    if not _FALLBACK_API_KEY:
        # No key configured — log a warning; allow in dev/test only.
        _logger.warning(
            "ALEXA_API_KEY is not set: /alexa/webhook is unauthenticated. "
            "Set ALEXA_API_KEY in production to protect this endpoint."
        )
        return
    api_key = request.headers.get("X-API-Key", "")
    if api_key != _FALLBACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing API key.")

# ---------------------------------------------------------------------------
# App Initialization & Middleware
# ---------------------------------------------------------------------------

app = FastAPI(
    title="Core West College Unified API",
    description=(
        "AI-powered learning management system and Voice briefing API "
        "that bridges the Core West Command Center with Amazon Alexa."
    ),
)

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------

_cors_origins_raw = os.environ.get("CORS_ORIGINS", "").strip()
if _cors_origins_raw:
    _allowed_origins = [o.strip() for o in _cors_origins_raw.split(",") if o.strip()]
else:
    _allowed_origins = ["*"]

# Credentialed requests are incompatible with the wildcard origin.
_allow_credentials = "*" not in _allowed_origins

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins,
    allow_credentials=_allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)

STATIC_DIR = Path(__file__).parent / "static"

# ---------------------------------------------------------------------------
# LMS Theme & Static Mounts
# ---------------------------------------------------------------------------
# Mount static files
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

# Include theme routes
app.include_router(theme_router)

# ---------------------------------------------------------------------------
# Alexa Setup & Helpers
# ---------------------------------------------------------------------------
aggregator = DataAggregator()

SUPPORTED_TYPES = ["inspection", "teachers", "students", "today", "tasks", "incidents"]

_LOGIN_PAGE = Path(__file__).parent / "auth" / "login_page.html"
_DASHBOARD_PAGE = Path(__file__).parent / "curriculum" / "templates" / "inspection_dashboard.html"


@app.get("/login", response_class=HTMLResponse, include_in_schema=False)
async def login_page() -> HTMLResponse:
    """Serve the standalone HTML login form."""
    if _LOGIN_PAGE.exists():
        return HTMLResponse(content=_LOGIN_PAGE.read_text(encoding="utf-8"))
    return HTMLResponse(content="<h1>Login page not available</h1>", status_code=404)


# ---------------------------------------------------------------------------
# Inspection dashboard (HTML)
# ---------------------------------------------------------------------------


@app.get("/inspection-dashboard", response_class=HTMLResponse, tags=["Inspection Readiness"])
async def inspection_dashboard() -> HTMLResponse:
    """Serve the visual inspection readiness dashboard."""
    if _DASHBOARD_PAGE.exists():
        return HTMLResponse(content=_DASHBOARD_PAGE.read_text(encoding="utf-8"))
    return HTMLResponse(content="<h1>Dashboard not found</h1>", status_code=404)

# ---------------------------------------------------------------------------
# Public endpoints
# ---------------------------------------------------------------------------


@app.get("/")
def root():
    """Liveness probe — confirms the service is running."""
    return {"message": "Core West Unified API is running"}


@app.get("/health")
async def health():
    """Basic health check for the overall service."""
    return {"status": "ok", "service": "Core West College Unified API"}


@app.get("/alexa/health")
def alexa_health():
    """Detailed health check specifically for Alexa/Canvas integrations."""
    return {
        "status": "ok",
        "auth_available": _AUTH_AVAILABLE,
        "modules": ["alexa", "curriculum", "inspection"],
    })


# ---------------------------------------------------------------------------
# Alexa voice query (public)
# Extended to support curriculum and inspection query types
# ---------------------------------------------------------------------------

SUPPORTED_TYPES = [
    "inspection",
    "teachers",
    "students",
    "today",
    "tasks",
    "incidents",
    # Curriculum extension types:
    "curriculum",
    "subjects",
    "gaps",
    "at_risk",
]


@app.get("/alexa/query")
async def alexa_query(
    q: str = "",
    query_kind: str = Query("today", alias="type"),
) -> JSONResponse:
    """Voice query endpoint — supports curriculum and inspection query types."""
    query_type = (q or query_kind).strip().lower()

    speech_text: str

    if query_type in ("curriculum", "subjects", "gaps"):
        speech_text = _monitor.get_voice_summary(query_type)
    elif query_type == "inspection":
        speech_text = _readiness.get_voice_summary()
    elif query_type in ("teachers", "at_risk"):
        speech_text = _performance.get_voice_summary(query_type)
    else:
        speech_text = f"Query type '{query_type}' received."

    return JSONResponse({
        "speech_text": speech_text,
        "card_title": "Core West Brief",
        "card_text": speech_text,
        "query_type": query_type,
        "status": "success",
    })


# ---------------------------------------------------------------------------
# Protected Alexa endpoints
# ---------------------------------------------------------------------------


@app.get("/alexa/dashboard")
async def alexa_dashboard(
    _user=Depends(require_authenticated) if _AUTH_AVAILABLE and require_authenticated else None,
) -> JSONResponse:
    """Dashboard — returns key metrics summary."""
    summary = {
        "inspection_readiness": _readiness.calculate_overall_readiness("ofsted"),
        "curriculum_coverage": _monitor.get_coverage_summary(),
    }
    if _AUTH_AVAILABLE and _user:
        summary["welcome"] = f"Welcome, {_user.username}!"  # type: ignore[union-attr]
    return JSONResponse({"status": "success", "data": summary})


@app.post("/alexa/webhook")
async def alexa_webhook(
    payload: dict,
    _key=Depends(verify_api_key) if _AUTH_AVAILABLE and verify_api_key else Depends(_fallback_verify_api_key),
) -> JSONResponse:
    """Alexa webhook — handles skill intents including curriculum and inspection."""
    request_type = payload.get("request", {}).get("type", "")
    intent_name = payload.get("request", {}).get("intent", {}).get("name", "")

    if request_type == "LaunchRequest":
        speech = (
            "Welcome to Core West. You can ask for today's brief, "
            "inspection readiness, curriculum coverage, subject performance, "
            "curriculum gaps, or student risk summary."
        )
        return JSONResponse({"speech_text": speech, "received": True})

    if request_type == "IntentRequest":
        intent_map = {
            "TodayBriefIntent":          ("today",      _monitor.get_voice_summary),
            "InspectionIntent":          ("inspection", _readiness.get_voice_summary),
            "InspectionReadinessIntent": ("inspection", _readiness.get_voice_summary),
            "CurriculumCoverageIntent":  ("coverage",   _monitor.get_voice_summary),
            "SubjectPerformanceIntent":  ("subjects",   _monitor.get_voice_summary),
            "CurriculumGapsIntent":      ("gaps",       _monitor.get_voice_summary),
            "TeacherSummaryIntent":      ("teachers",   _performance.get_voice_summary),
            "StudentRiskIntent":         ("at_risk",    _performance.get_voice_summary),
        }

        if intent_name in intent_map:
            query_type, card_title = intent_map[intent_name]
            text = aggregator.get_summary(query_type)
            return _alexa_response(text, card_title)

    return _alexa_response(
        "Sorry, I didn't understand that request.", "Core West Error"
    )

# ---------------------------------------------------------------------------
# Dev entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
    )
