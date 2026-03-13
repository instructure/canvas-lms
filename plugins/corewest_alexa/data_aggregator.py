"""
Data aggregator for the Core West Alexa plugin.

Converts raw Canvas API data into voice-friendly summary strings suitable
for Alexa responses (e.g. "78 percent" instead of "78%").
"""

import logging
from typing import Any, Dict

from canvas_client import CanvasClient

logger = logging.getLogger(__name__)


def _num(value: Any) -> str:
    """Format a number as a spoken word string."""
    return str(int(value))


def _score(value: Any) -> str:
    """Format a float score for speech (e.g. 3.1 -> '3 point 1')."""
    parts = str(float(value)).split(".")
    if len(parts) == 2 and parts[1] != "0":
        return f"{parts[0]} point {parts[1]}"
    return parts[0]


class DataAggregator:
    """Aggregates Canvas LMS data and produces Alexa-friendly summaries."""

    def __init__(self, client: CanvasClient | None = None) -> None:
        self.client = client or CanvasClient()

    # ------------------------------------------------------------------
    # Individual summary builders
    # ------------------------------------------------------------------

    def inspection_summary(self) -> str:
        inspection = self.client.get_inspection_readiness()
        tasks = self.client.get_open_tasks()
        incidents = self.client.get_incidents()
        readiness = _num(inspection["readiness_percent"])
        open_tasks = _num(tasks["open"])
        unresolved = _num(incidents["unresolved"])
        return (
            f"Inspection readiness is {readiness} percent. "
            f"There are {open_tasks} open tasks and {unresolved} unresolved incidents."
        )

    def teachers_summary(self) -> str:
        data = self.client.get_teachers()
        total = _num(data["total"])
        priority = _num(data["priority_followup"])
        score = _score(data["avg_quality_score"])
        return (
            f"There are {total} teachers. "
            f"{priority} teachers require priority follow up. "
            f"Average quality score is {score}."
        )

    def students_summary(self) -> str:
        data = self.client.get_students()
        high_risk = _num(data["high_risk"])
        low_att = _num(data["low_attendance"])
        safe = _num(data["safeguarding_flags"])
        return (
            f"There are {high_risk} high risk students, "
            f"{low_att} low attendance cases, "
            f"and {safe} safeguarding flags."
        )

    def today_summary(self) -> str:
        inspection = self.client.get_inspection_readiness()
        tasks = self.client.get_open_tasks()
        teachers = self.client.get_teachers()
        students = self.client.get_students()
        readiness = _num(inspection["readiness_percent"])
        open_tasks = _num(tasks["open"])
        priority = _num(teachers["priority_followup"])
        high_risk = _num(students["high_risk"])
        return (
            f"Today, inspection readiness is {readiness} percent. "
            f"There are {open_tasks} open tasks. "
            f"{priority} teachers need priority follow up, "
            f"and {high_risk} students are considered high risk."
        )

    def tasks_summary(self) -> str:
        data = self.client.get_open_tasks()
        open_tasks = _num(data["open"])
        return f"There are {open_tasks} open tasks requiring follow up."

    def incidents_summary(self) -> str:
        data = self.client.get_incidents()
        unresolved = _num(data["unresolved"])
        return (
            f"There are {unresolved} unresolved incidents "
            f"requiring leadership attention."
        )

    # ------------------------------------------------------------------
    # Dispatcher
    # ------------------------------------------------------------------

    def get_summary(self, query_type: str) -> str | None:
        """Return a voice-friendly summary for *query_type*, or None if unknown."""
        mapping = {
            "inspection": self.inspection_summary,
            "teachers": self.teachers_summary,
            "students": self.students_summary,
            "today": self.today_summary,
            "tasks": self.tasks_summary,
            "incidents": self.incidents_summary,
        }
        handler = mapping.get(query_type.strip().lower())
        if handler is None:
            return None
        try:
            return handler()
        except Exception as exc:  # noqa: BLE001
            logger.error("Error building summary for %r: %s", query_type, exc)
            raise

    def get_dashboard_data(self) -> Dict[str, Any]:
        """Return a structured dict suitable for a dashboard JSON response."""
        return self.client.get_all()
