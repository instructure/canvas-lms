"""
Unit tests for data_aggregator.py.
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from unittest.mock import MagicMock

from data_aggregator import DataAggregator, _num, _score
from canvas_client import MOCK_DATA


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def test_num_integer():
    assert _num(78) == "78"


def test_num_float():
    assert _num(78.9) == "78"


def test_score_with_decimal():
    assert _score(3.1) == "3 point 1"


def test_score_whole_number():
    assert _score(3.0) == "3"


# ---------------------------------------------------------------------------
# Aggregator with mock Canvas client
# ---------------------------------------------------------------------------

def make_aggregator() -> DataAggregator:
    """Return a DataAggregator backed by a mock client that returns MOCK_DATA."""
    mock_client = MagicMock()
    mock_client.get_inspection_readiness.return_value = MOCK_DATA["inspection"]
    mock_client.get_open_tasks.return_value = MOCK_DATA["tasks"]
    mock_client.get_incidents.return_value = MOCK_DATA["incidents"]
    mock_client.get_teachers.return_value = MOCK_DATA["teachers"]
    mock_client.get_students.return_value = MOCK_DATA["students"]
    mock_client.get_active_courses.return_value = MOCK_DATA["courses"]
    mock_client.get_all.return_value = MOCK_DATA
    return DataAggregator(client=mock_client)


def test_inspection_summary():
    agg = make_aggregator()
    result = agg.inspection_summary()
    assert "78 percent" in result
    assert "5 open tasks" in result
    assert "2 unresolved incidents" in result


def test_teachers_summary():
    agg = make_aggregator()
    result = agg.teachers_summary()
    assert "24 teachers" in result
    assert "3 teachers require priority follow up" in result
    assert "3 point 1" in result


def test_students_summary():
    agg = make_aggregator()
    result = agg.students_summary()
    assert "11 high risk students" in result
    assert "18 low attendance cases" in result
    assert "2 safeguarding flags" in result


def test_today_summary():
    agg = make_aggregator()
    result = agg.today_summary()
    assert "78 percent" in result
    assert "5 open tasks" in result
    assert "3 teachers" in result
    assert "11 students" in result


def test_tasks_summary():
    agg = make_aggregator()
    result = agg.tasks_summary()
    assert "5 open tasks" in result


def test_incidents_summary():
    agg = make_aggregator()
    result = agg.incidents_summary()
    assert "2 unresolved incidents" in result


# ---------------------------------------------------------------------------
# Dispatcher
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("query_type", [
    "inspection", "teachers", "students", "today", "tasks", "incidents",
])
def test_get_summary_valid(query_type):
    agg = make_aggregator()
    result = agg.get_summary(query_type)
    assert result is not None
    assert isinstance(result, str)
    assert len(result) > 0


def test_get_summary_case_insensitive():
    agg = make_aggregator()
    assert agg.get_summary("INSPECTION") == agg.get_summary("inspection")


def test_get_summary_unknown_returns_none():
    agg = make_aggregator()
    assert agg.get_summary("unknown") is None


def test_get_dashboard_data():
    agg = make_aggregator()
    data = agg.get_dashboard_data()
    assert isinstance(data, dict)
    assert "teachers" in data
    assert "students" in data


# ---------------------------------------------------------------------------
# Match original hardcoded responses exactly
# ---------------------------------------------------------------------------

def test_inspection_matches_original():
    agg = make_aggregator()
    expected = (
        "Inspection readiness is 78 percent. "
        "There are 5 open tasks and 2 unresolved incidents."
    )
    assert agg.inspection_summary() == expected


def test_teachers_matches_original():
    agg = make_aggregator()
    expected = (
        "There are 24 teachers. "
        "3 teachers require priority follow up. "
        "Average quality score is 3 point 1."
    )
    assert agg.teachers_summary() == expected


def test_students_matches_original():
    agg = make_aggregator()
    expected = (
        "There are 11 high risk students, "
        "18 low attendance cases, "
        "and 2 safeguarding flags."
    )
    assert agg.students_summary() == expected


def test_today_matches_original():
    agg = make_aggregator()
    expected = (
        "Today, inspection readiness is 78 percent. "
        "There are 5 open tasks. "
        "3 teachers need priority follow up, "
        "and 11 students are considered high risk."
    )
    assert agg.today_summary() == expected


def test_tasks_matches_original():
    agg = make_aggregator()
    assert agg.tasks_summary() == "There are 5 open tasks requiring follow up."


def test_incidents_matches_original():
    agg = make_aggregator()
    assert agg.incidents_summary() == (
        "There are 2 unresolved incidents requiring leadership attention."
    )
