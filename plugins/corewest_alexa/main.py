"""
Core West Alexa API — FastAPI application entry point.

Endpoints:
  GET  /              — root / liveness probe
  GET  /alexa/health  — detailed health check
  GET  /alexa/query   — voice query (query param: type)
  GET  /alexa/dashboard — JSON dashboard data
  POST /alexa/webhook — Alexa skill webhook
"""

import logging
import sys

from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from data_aggregator import DataAggregator

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(
    title="Core West Alexa API",
    description=(
        "Voice briefing API that bridges the Core West Command Center "
        "with Amazon Alexa.  Powered by Canvas LMS data."
    ),
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

aggregator = DataAggregator()

SUPPORTED_TYPES = ["inspection", "teachers", "students", "today", "tasks", "incidents"]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _alexa_response(text: str, card_title: str = "Core West") -> dict:
    """Build a standard Alexa response payload."""
    return {
        "version": "1.0",
        "response": {
            "outputSpeech": {"type": "PlainText", "text": text},
            "card": {"type": "Simple", "title": card_title, "content": text},
            "shouldEndSession": True,
        },
    }


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.get("/")
def root():
    """Liveness probe — confirms the service is running."""
    return {"message": "Core West Alexa API is running"}


@app.get("/alexa/health")
def health():
    """Detailed health check."""
    return {
        "status": "ok",
        "canvas_api_url": settings.canvas_api_url,
        "use_mock_data": settings.use_mock_data,
        "debug": settings.debug,
    }


@app.get("/alexa/query")
def alexa_query(
    query_type: str = Query(
        ...,
        alias="type",
        description=(
            "Report type. One of: "
            + ", ".join(SUPPORTED_TYPES)
        ),
    ),
):
    """Return a voice-friendly summary for the requested *type*."""
    query_type = query_type.strip().lower()
    summary = aggregator.get_summary(query_type)
    if summary is None:
        return {
            "speech_text": "I could not understand the requested report type.",
            "card_title": "Core West Alexa Error",
            "card_text": (
                "Supported types are "
                + ", ".join(SUPPORTED_TYPES[:-1])
                + ", and "
                + SUPPORTED_TYPES[-1]
                + "."
            ),
            "status": "error",
        }
    return {
        "speech_text": summary,
        "card_title": "Core West Brief",
        "card_text": summary,
        "status": "success",
    }


@app.get("/alexa/dashboard")
def alexa_dashboard():
    """Return structured JSON data for the Core West command center dashboard."""
    try:
        data = aggregator.get_dashboard_data()
        return {"status": "success", "data": data}
    except Exception as exc:  # noqa: BLE001
        logger.error("Dashboard data fetch failed: %s", exc)
        raise HTTPException(status_code=502, detail="Failed to fetch dashboard data") from exc


@app.post("/alexa/webhook")
async def alexa_webhook(request: Request):
    """Handle incoming Alexa skill requests."""
    try:
        body = await request.json()
    except Exception as exc:  # noqa: BLE001
        logger.warning("Invalid JSON in webhook body: %s", exc)
        raise HTTPException(status_code=400, detail="Invalid JSON body") from exc

    request_type = body.get("request", {}).get("type")
    logger.debug("Alexa webhook request_type=%s", request_type)

    if request_type == "LaunchRequest":
        return _alexa_response(
            "Welcome to Core West. You can ask for today's brief, "
            "inspection summary, teacher summary, or student risk summary.",
            "Core West Welcome",
        )

    if request_type == "IntentRequest":
        intent_name = body.get("request", {}).get("intent", {}).get("name")
        logger.debug("IntentRequest intent_name=%s", intent_name)

        intent_map = {
            "TodayBriefIntent": ("today", "Core West Daily Brief"),
            "InspectionIntent": ("inspection", "Core West Inspection Brief"),
            "TeacherSummaryIntent": ("teachers", "Core West Teacher Brief"),
            "StudentRiskIntent": ("students", "Core West Student Risk Brief"),
            "TasksSummaryIntent": ("tasks", "Core West Tasks Brief"),
            "IncidentsSummaryIntent": ("incidents", "Core West Incidents Brief"),
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
