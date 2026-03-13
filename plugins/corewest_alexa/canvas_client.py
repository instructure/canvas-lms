"""
Canvas LMS API client for the Core West Alexa plugin.

Fetches live data from the Canvas REST API.  When the API is unavailable
(network error, missing token, etc.) the client falls back to static mock
data so the Alexa skill keeps functioning.
"""

import logging
from typing import Any, Dict, List, Optional

import requests

from config import settings

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Mock / fallback data (matches the original standalone Alexa API responses)
# ---------------------------------------------------------------------------
MOCK_DATA: Dict[str, Any] = {
    "courses": {"total_active": 12},
    "teachers": {
        "total": 24,
        "priority_followup": 3,
        "avg_quality_score": 3.1,
    },
    "students": {
        "total": 320,
        "high_risk": 11,
        "low_attendance": 18,
        "safeguarding_flags": 2,
    },
    "tasks": {
        "open": 5,
    },
    "incidents": {
        "unresolved": 2,
    },
    "inspection": {
        "readiness_percent": 78,
    },
}


class CanvasAPIError(Exception):
    """Raised when the Canvas API returns an unexpected response."""


class CanvasClient:
    """Thin wrapper around the Canvas LMS REST API."""

    def __init__(
        self,
        base_url: Optional[str] = None,
        token: Optional[str] = None,
    ) -> None:
        self.base_url = (base_url or settings.canvas_api_url).rstrip("/")
        self.token = token or settings.canvas_api_token
        self._session = requests.Session()
        if self.token:
            self._session.headers.update(
                {"Authorization": f"Bearer {self.token}"}
            )

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _get(self, path: str, params: Optional[Dict] = None) -> Any:
        url = f"{self.base_url}{path}"
        try:
            resp = self._session.get(url, params=params, timeout=10)
            resp.raise_for_status()
            return resp.json()
        except requests.RequestException as exc:
            raise CanvasAPIError(f"Canvas API request failed: {exc}") from exc

    # ------------------------------------------------------------------
    # Public API methods
    # ------------------------------------------------------------------

    def get_active_courses(self) -> Dict[str, Any]:
        """Return summary of active courses."""
        try:
            courses: List[Dict] = self._get(
                "/api/v1/courses",
                params={"enrollment_state": "active", "per_page": 100},
            )
            return {"total_active": len(courses)}
        except CanvasAPIError as exc:
            logger.warning("Falling back to mock courses data: %s", exc)
            return MOCK_DATA["courses"]

    def get_teachers(self) -> Dict[str, Any]:
        """Return teacher summary information."""
        try:
            teachers: List[Dict] = self._get(
                "/api/v1/accounts/1/users",
                params={"enrollment_type": "teacher", "per_page": 100},
            )
            return {
                "total": len(teachers),
                # Canvas does not expose these metrics directly;
                # derive from mock until a custom report endpoint exists.
                "priority_followup": MOCK_DATA["teachers"]["priority_followup"],
                "avg_quality_score": MOCK_DATA["teachers"]["avg_quality_score"],
            }
        except CanvasAPIError as exc:
            logger.warning("Falling back to mock teacher data: %s", exc)
            return MOCK_DATA["teachers"]

    def get_students(self) -> Dict[str, Any]:
        """Return student risk summary information."""
        try:
            students: List[Dict] = self._get(
                "/api/v1/accounts/1/users",
                params={"enrollment_type": "student", "per_page": 100},
            )
            return {
                "total": len(students),
                # Detailed risk metrics require custom analytics endpoints.
                "high_risk": MOCK_DATA["students"]["high_risk"],
                "low_attendance": MOCK_DATA["students"]["low_attendance"],
                "safeguarding_flags": MOCK_DATA["students"]["safeguarding_flags"],
            }
        except CanvasAPIError as exc:
            logger.warning("Falling back to mock student data: %s", exc)
            return MOCK_DATA["students"]

    def get_open_tasks(self) -> Dict[str, Any]:
        """Return count of open assignments / tasks."""
        try:
            assignments: List[Dict] = self._get(
                "/api/v1/accounts/1/assignments",
                params={"bucket": "ungraded", "per_page": 100},
            )
            return {"open": len(assignments)}
        except CanvasAPIError as exc:
            logger.warning("Falling back to mock task data: %s", exc)
            return MOCK_DATA["tasks"]

    def get_incidents(self) -> Dict[str, Any]:
        """Return unresolved incident count."""
        # Canvas LMS does not have a native incidents API.
        # Return mock data; replace with a real endpoint when available.
        logger.debug("Using mock incident data (no Canvas incidents API)")
        return MOCK_DATA["incidents"]

    def get_inspection_readiness(self) -> Dict[str, Any]:
        """Return inspection readiness metrics."""
        # Inspection readiness is a composite metric; use mock data until
        # a real analytics endpoint is available.
        logger.debug("Using mock inspection data")
        return MOCK_DATA["inspection"]

    def get_all(self) -> Dict[str, Any]:
        """Fetch all metrics in one call (for the dashboard endpoint)."""
        return {
            "courses": self.get_active_courses(),
            "teachers": self.get_teachers(),
            "students": self.get_students(),
            "tasks": self.get_open_tasks(),
            "incidents": self.get_incidents(),
            "inspection": self.get_inspection_readiness(),
        }
