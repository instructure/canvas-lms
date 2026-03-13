"""
Unit tests for the Core West Alexa API endpoints (main.py).
"""

import sys
import os

# Ensure the plugin root is on the path so imports work without installation.
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock, patch

from main import app

client = TestClient(app)


# ---------------------------------------------------------------------------
# Root / health
# ---------------------------------------------------------------------------

def test_root():
    resp = client.get("/")
    assert resp.status_code == 200
    assert resp.json()["message"] == "Core West Alexa API is running"


def test_health():
    resp = client.get("/alexa/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert "canvas_api_url" in data


# ---------------------------------------------------------------------------
# /alexa/query
# ---------------------------------------------------------------------------

VALID_TYPES = ["inspection", "teachers", "students", "today", "tasks", "incidents"]


@pytest.mark.parametrize("query_type", VALID_TYPES)
def test_query_valid_types(query_type):
    resp = client.get(f"/alexa/query?type={query_type}")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "success"
    assert data["speech_text"]
    assert data["card_title"] == "Core West Brief"


def test_query_invalid_type():
    resp = client.get("/alexa/query?type=unknown")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "error"
    assert "could not understand" in data["speech_text"].lower()


def test_query_missing_type():
    resp = client.get("/alexa/query")
    assert resp.status_code == 422  # FastAPI validation error


def test_query_case_insensitive():
    resp = client.get("/alexa/query?type=INSPECTION")
    assert resp.status_code == 200
    assert resp.json()["status"] == "success"


# ---------------------------------------------------------------------------
# /alexa/dashboard
# ---------------------------------------------------------------------------

def test_dashboard():
    resp = client.get("/alexa/dashboard")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "success"
    assert "data" in data
    dashboard = data["data"]
    for key in ("teachers", "students", "tasks", "incidents", "inspection"):
        assert key in dashboard


# ---------------------------------------------------------------------------
# /alexa/webhook — LaunchRequest
# ---------------------------------------------------------------------------

def test_webhook_launch_request():
    payload = {"request": {"type": "LaunchRequest"}}
    resp = client.post("/alexa/webhook", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert body["version"] == "1.0"
    assert "Welcome to Core West" in body["response"]["outputSpeech"]["text"]
    assert body["response"]["shouldEndSession"] is True


# ---------------------------------------------------------------------------
# /alexa/webhook — IntentRequest
# ---------------------------------------------------------------------------

INTENT_CASES = [
    ("TodayBriefIntent", "Core West Daily Brief"),
    ("InspectionIntent", "Core West Inspection Brief"),
    ("TeacherSummaryIntent", "Core West Teacher Brief"),
    ("StudentRiskIntent", "Core West Student Risk Brief"),
    ("TasksSummaryIntent", "Core West Tasks Brief"),
    ("IncidentsSummaryIntent", "Core West Incidents Brief"),
]


@pytest.mark.parametrize("intent_name,expected_card_title", INTENT_CASES)
def test_webhook_intent_requests(intent_name, expected_card_title):
    payload = {
        "request": {
            "type": "IntentRequest",
            "intent": {"name": intent_name},
        }
    }
    resp = client.post("/alexa/webhook", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert body["response"]["card"]["title"] == expected_card_title
    assert body["response"]["outputSpeech"]["text"]


def test_webhook_unknown_intent():
    payload = {
        "request": {
            "type": "IntentRequest",
            "intent": {"name": "UnknownIntent"},
        }
    }
    resp = client.post("/alexa/webhook", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert "didn't understand" in body["response"]["outputSpeech"]["text"].lower()


def test_webhook_invalid_json():
    resp = client.post(
        "/alexa/webhook",
        content=b"not-json",
        headers={"Content-Type": "application/json"},
    )
    assert resp.status_code == 400
