"""
FastAPI router for curriculum monitoring and inspection readiness endpoints.

All /curriculum/* and /inspection/* routes are intended to be JWT-protected
when the auth plugin is available. If the auth dependency cannot be imported
(e.g. during standalone testing without the auth plugin), the router degrades
gracefully and these routes are exposed without authentication.

Python 3.11+ compatible.
"""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query

from .curriculum_monitor import CurriculumMonitor
from .inspection_readiness import InspectionReadinessEngine
from .models import EvidenceUploadRequest
from .performance_tracker import PerformanceTracker
from .standards_framework import (
    get_all_frameworks,
    get_framework,
    map_ofsted_to_cognia,
)

# ---------------------------------------------------------------------------
# Try to import auth dependency; fall back gracefully if auth module not yet
# available (e.g. during standalone testing without the auth plugin).
# ---------------------------------------------------------------------------
try:
    from auth.dependencies import require_authenticated  # type: ignore[import-not-found]
    _AUTH_AVAILABLE = True
except ImportError:  # pragma: no cover
    _AUTH_AVAILABLE = False
    require_authenticated = None  # type: ignore[assignment]


def _get_auth_dependency() -> list[Any]:
    """Return a list of FastAPI dependencies based on auth availability."""
    if _AUTH_AVAILABLE and require_authenticated is not None:
        return [Depends(require_authenticated)]
    return []


# ---------------------------------------------------------------------------
# Singletons
# ---------------------------------------------------------------------------

_monitor = CurriculumMonitor()
_readiness = InspectionReadinessEngine()
_tracker = PerformanceTracker()

# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------

curriculum_router = APIRouter(
    prefix="/curriculum",
    tags=["Curriculum"],
    dependencies=_get_auth_dependency(),
)

inspection_router = APIRouter(
    prefix="/inspection",
    tags=["Inspection Readiness"],
    dependencies=_get_auth_dependency(),
)


# ===========================================================================
# Curriculum — Standards
# ===========================================================================


@curriculum_router.get("/standards", summary="List all standards frameworks")
def list_standards() -> dict[str, Any]:
    """Return metadata about all available educational standards frameworks."""
    return {"frameworks": get_all_frameworks()}


@curriculum_router.get("/standards/compare", summary="Compare British vs American standards")
def compare_standards() -> dict[str, Any]:
    """Return a side-by-side comparison of British and American educational standards."""
    return {
        "british": {
            "ofsted": get_framework("ofsted"),
            "national_curriculum": get_framework("national_curriculum"),
        },
        "american": {
            "cognia": get_framework("cognia"),
            "common_core": get_framework("common_core"),
            "danielson": get_framework("danielson"),
        },
        "grade_mapping": {
            "ofsted_1_outstanding": map_ofsted_to_cognia(1),
            "ofsted_2_good": map_ofsted_to_cognia(2),
            "ofsted_3_requires_improvement": map_ofsted_to_cognia(3),
            "ofsted_4_inadequate": map_ofsted_to_cognia(4),
        },
    }


@curriculum_router.get("/standards/{framework}", summary="Get specific framework details")
def get_standards_framework(framework: str) -> dict[str, Any]:
    """Return full details of a specific educational standards framework."""
    try:
        data = get_framework(framework)
        return {"framework": framework, "data": data}
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


# ===========================================================================
# Curriculum — Coverage
# ===========================================================================


@curriculum_router.get("/coverage", summary="Overall curriculum coverage")
def curriculum_coverage(
    framework: str = Query("all", description="Filter by framework"),
) -> dict[str, Any]:
    """Return curriculum coverage percentages across all subjects."""
    return {
        "framework": framework,
        "coverage": _monitor.get_coverage_summary(framework=framework),
    }


@curriculum_router.get("/coverage/{subject}", summary="Coverage for a specific subject")
def subject_coverage(
    subject: str,
    framework: str = Query("all", description="Filter by framework"),
) -> dict[str, Any]:
    """Return curriculum coverage for a single subject."""
    summary = _monitor.get_coverage_summary(subject=subject, framework=framework)
    if not summary:
        raise HTTPException(status_code=404, detail=f"Subject '{subject}' not found.")
    return {"subject": subject, "framework": framework, "coverage": summary}


@curriculum_router.get("/gaps", summary="Gap analysis across all subjects")
def curriculum_gaps(
    framework: str = Query(None, description="Filter by framework"),
) -> dict[str, Any]:
    """Return curriculum gaps — standards not yet fully covered."""
    gaps = _monitor.identify_gaps(framework=framework)
    return {
        "total_gaps": len(gaps),
        "gaps": [g.model_dump() for g in gaps],
    }


@curriculum_router.get("/gaps/{subject}", summary="Gaps for a specific subject")
def subject_gaps(
    subject: str,
    framework: str = Query(None, description="Filter by framework"),
) -> dict[str, Any]:
    """Return curriculum gaps for a single subject."""
    gaps = _monitor.identify_gaps(subject=subject, framework=framework)
    return {
        "subject": subject,
        "total_gaps": len(gaps),
        "gaps": [g.model_dump() for g in gaps],
    }


# ===========================================================================
# Curriculum — Performance
# ===========================================================================


@curriculum_router.get("/performance", summary="School-wide performance summary")
def school_performance() -> dict[str, Any]:
    """Return the school-wide academic performance summary."""
    return _tracker.get_school_summary()


@curriculum_router.get("/performance/subjects", summary="Performance per subject")
def subject_performance(
    subject: str = Query(None, description="Specific subject name"),
) -> dict[str, Any]:
    """Return performance data per subject."""
    return _tracker.get_subject_performance(subject=subject)


@curriculum_router.get("/performance/teachers", summary="Performance per teacher")
def teacher_performance(
    teacher_id: str = Query(None, description="Specific teacher ID"),
) -> dict[str, Any]:
    """Return teaching quality metrics."""
    result = _tracker.get_teacher_performance(teacher_id=teacher_id)
    if isinstance(result, list):
        return {"teachers": result}
    return result


@curriculum_router.get("/performance/students/at-risk", summary="At-risk students")
def at_risk_students() -> dict[str, Any]:
    """Return at-risk student analysis across multiple factors."""
    return _tracker.get_student_risk_analysis()


@curriculum_router.get("/performance/cohorts", summary="Cohort analysis")
def cohort_analysis(
    year_group: str = Query(None, description="British year group, e.g. 'Year 10'"),
    grade_level: str = Query(None, description="American grade level, e.g. 'Grade 9'"),
) -> dict[str, Any]:
    """Return cohort-level analysis, optionally filtered."""
    result = _tracker.get_cohort_analysis(
        year_group=year_group, grade_level=grade_level
    )
    if isinstance(result, list):
        return {"cohorts": result}
    return result


@curriculum_router.get("/performance/compare", summary="British vs American metrics comparison")
def performance_compare() -> dict[str, Any]:
    """Return side-by-side comparison of British and American performance metrics."""
    return _tracker.compare_standards()


# ===========================================================================
# Curriculum — Voice
# ===========================================================================


@curriculum_router.get("/voice/{query_type}", summary="Voice-friendly curriculum summaries")
def curriculum_voice(query_type: str) -> dict[str, str]:
    """Return a voice-optimised curriculum summary for Alexa."""
    text = _monitor.get_voice_summary(query_type)
    return {"speech_text": text, "query_type": query_type}


# ===========================================================================
# Inspection — Readiness
# ===========================================================================


@inspection_router.get("/readiness", summary="Overall readiness score & breakdown")
def overall_readiness(
    framework: str = Query("ofsted", description="'ofsted' or 'cognia'"),
) -> dict[str, Any]:
    """Return overall inspection readiness score with per-area breakdown."""
    return _readiness.calculate_overall_readiness(framework=framework)


@inspection_router.get("/readiness/{framework}", summary="Readiness for specific framework")
def framework_readiness(framework: str) -> dict[str, Any]:
    """Return readiness score for a specific inspection framework."""
    if framework.lower() not in ("ofsted", "cognia"):
        raise HTTPException(
            status_code=400,
            detail="Framework must be 'ofsted' or 'cognia'.",
        )
    return _readiness.calculate_overall_readiness(framework=framework)


@inspection_router.get("/checklist", summary="Full inspection checklist")
def full_checklist(
    framework: str = Query("ofsted", description="'ofsted' or 'cognia'"),
) -> dict[str, Any]:
    """Return the full inspection preparation checklist."""
    criteria = _readiness.get_checklist(framework=framework)
    return {
        "framework": framework,
        "total": len(criteria),
        "checklist": [c.model_dump() for c in criteria],
    }


@inspection_router.get("/checklist/{framework}", summary="Framework-specific checklist")
def framework_checklist(framework: str) -> dict[str, Any]:
    """Return the checklist for a specific inspection framework."""
    if framework.lower() not in ("ofsted", "cognia"):
        raise HTTPException(
            status_code=400,
            detail="Framework must be 'ofsted' or 'cognia'.",
        )
    criteria = _readiness.get_checklist(framework=framework)
    return {
        "framework": framework,
        "total": len(criteria),
        "checklist": [c.model_dump() for c in criteria],
    }


@inspection_router.get("/priorities", summary="Priority actions list")
def priority_actions(
    framework: str = Query("ofsted", description="'ofsted' or 'cognia'"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of actions to return"),
) -> dict[str, Any]:
    """Return top priority actions sorted by urgency."""
    actions = _readiness.get_priority_actions(framework=framework, limit=limit)
    return {"framework": framework, "count": len(actions), "actions": actions}


@inspection_router.get("/evidence", summary="Evidence tracker")
def evidence_tracker(
    area: str = Query(None, description="Filter by inspection area/category"),
) -> dict[str, Any]:
    """Return evidence tracking status for each criterion."""
    tracker = _readiness.get_evidence_tracker(area=area)
    complete = sum(1 for v in tracker.values() if v["evidence_status"] == "complete")
    partial = sum(1 for v in tracker.values() if v["evidence_status"] == "partial")
    missing = sum(1 for v in tracker.values() if v["evidence_status"] == "missing")
    return {
        "summary": {
            "total_criteria": len(tracker),
            "complete": complete,
            "partial": partial,
            "missing": missing,
        },
        "evidence": tracker,
    }


@inspection_router.get("/evidence/{criteria_id}", summary="Evidence for specific criteria")
def criteria_evidence(criteria_id: str) -> dict[str, Any]:
    """Return evidence for a specific inspection criterion."""
    tracker = _readiness.get_evidence_tracker()
    if criteria_id not in tracker:
        raise HTTPException(
            status_code=404,
            detail=f"Criterion '{criteria_id}' not found.",
        )
    return {"criteria_id": criteria_id, **tracker[criteria_id]}


@inspection_router.post("/evidence", summary="Upload/register evidence", status_code=201)
def upload_evidence(payload: EvidenceUploadRequest) -> dict[str, Any]:
    """Register a new piece of evidence against an inspection criterion."""
    try:
        evidence = _readiness.add_evidence(
            {
                "criteria_id": payload.criteria_id,
                "title": payload.title,
                "description": payload.description,
                "evidence_type": payload.evidence_type,
                "uploaded_by": payload.uploaded_by,
                "tags": payload.tags,
            }
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return {"status": "created", "evidence": evidence.model_dump()}


@inspection_router.get("/self-evaluation", summary="Self-Evaluation Form summary")
def self_evaluation(
    framework: str = Query("ofsted", description="'ofsted' or 'cognia'"),
) -> dict[str, Any]:
    """Generate a Self-Evaluation Form (SEF) summary."""
    return _readiness.generate_self_evaluation(framework=framework)


@inspection_router.get("/report", summary="Full inspection readiness report")
def inspection_report(
    framework: str = Query("ofsted", description="'ofsted' or 'cognia'"),
) -> dict[str, Any]:
    """Return a full inspection readiness report in JSON."""
    return {
        "readiness": _readiness.calculate_overall_readiness(framework=framework),
        "checklist": [
            c.model_dump() for c in _readiness.get_checklist(framework=framework)
        ],
        "priority_actions": _readiness.get_priority_actions(framework=framework),
        "self_evaluation": _readiness.generate_self_evaluation(framework=framework),
        "evidence_summary": {
            k: {
                "evidence_status": v["evidence_status"],
                "evidence_count": v["evidence_count"],
            }
            for k, v in _readiness.get_evidence_tracker().items()
        },
        "performance_snapshot": _tracker.get_school_summary(),
        "curriculum_coverage": _monitor.get_coverage_summary(),
    }


@inspection_router.get("/trend", summary="Readiness score trend data")
def readiness_trend(
    days: int = Query(90, ge=7, le=365, description="Number of days of trend data"),
) -> dict[str, Any]:
    """Return readiness score trend data for charting."""
    trend = _readiness.get_readiness_trend(days=days)
    return {"days": days, "data_points": len(trend), "trend": trend}


@inspection_router.get("/voice", summary="Voice-friendly inspection readiness")
def inspection_voice() -> dict[str, str]:
    """Return a voice-optimised inspection readiness summary for Alexa."""
    text = _readiness.get_voice_summary()
    return {"speech_text": text}
