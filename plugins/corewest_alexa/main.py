"""
Core West College AI LMS — Alexa Plugin
FastAPI application entry-point.

Integrates:
- Auth routes (JWT login, registration)
- Alexa voice endpoints (query, webhook, dashboard)
- Curriculum monitoring endpoints (/curriculum/*)
- Inspection readiness endpoints (/inspection/*)
- Inspection dashboard UI (/inspection-dashboard)
"""

from __future__ import annotations

import logging
import os
from pathlib import Path

from fastapi import Depends, FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse

# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
try:
    from auth.dependencies import require_authenticated, verify_api_key  # type: ignore[import-not-found]
    from auth.routes import router as auth_router  # type: ignore[import-not-found]
    _AUTH_AVAILABLE = True
except ImportError:  # pragma: no cover
    _AUTH_AVAILABLE = False
    require_authenticated = None  # type: ignore[assignment]
    verify_api_key = None         # type: ignore[assignment]
    auth_router = None            # type: ignore[assignment]

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
# App
# ---------------------------------------------------------------------------

app = FastAPI(
    title="Core West College — Alexa Plugin",
    version="2.0.0",
    description=(
        "Alexa integration API for the Core West College AI LMS. "
        "Includes curriculum monitoring and inspection readiness modules."
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

# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------

if _AUTH_AVAILABLE and auth_router is not None:
    app.include_router(auth_router)

app.include_router(curriculum_router)
app.include_router(inspection_router)

# ---------------------------------------------------------------------------
# Login page (public)
# ---------------------------------------------------------------------------

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
async def root() -> JSONResponse:
    """Root liveness probe."""
    return JSONResponse({"message": "Core West College Alexa API is running", "version": "2.0.0"})


@app.get("/alexa/health")
async def health() -> JSONResponse:
    """Health-check — no authentication required."""
    return JSONResponse({
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
            query_kind, handler = intent_map[intent_name]
            try:
                # Handlers that take no args (e.g. get_voice_summary on InspectionEngine)
                try:
                    speech = handler()  # type: ignore[call-arg]
                except TypeError:
                    speech = handler(query_kind)  # type: ignore[call-arg]
            except (AttributeError, ValueError) as exc:
                _logger.error("Voice handler error for %s: %s", intent_name, exc)
                speech = f"I was unable to retrieve the {query_kind} summary."
            return JSONResponse({"speech_text": speech, "intent": intent_name, "received": True})

    # Fallback for unrecognised requests — do not echo full payload to avoid leaking data.
    request_id = payload.get("request", {}).get("requestId")
    return JSONResponse({
        "speech_text": "Sorry, I did not understand that request.",
        "received": True,
        "request_type": request_type or None,
        "intent": intent_name or None,
        "request_id": request_id,
    })
