"""
Data models for curriculum tracking, inspection readiness, and performance analytics.

Uses Pydantic v2 for validation and dataclass-style typing throughout.
All models are Python 3.11+ compatible.
"""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Subject
# ---------------------------------------------------------------------------


class Subject(BaseModel):
    """Represents a taught subject within the college."""

    id: str
    name: str  # e.g. "Mathematics", "English", "Science"
    department: str
    key_stage: str  # British: KS1-KS5 | American: Elementary/Middle/High
    teacher_id: str
    teacher_name: str


# ---------------------------------------------------------------------------
# Curriculum Standard
# ---------------------------------------------------------------------------


class CurriculumStandard(BaseModel):
    """A single standard or learning objective from any supported framework."""

    id: str
    code: str  # e.g. "CCSS.MATH.6.RP.1" or "NC.KS3.MA.1"
    description: str
    framework: str  # "ofsted" | "common_core" | "cognia" | "national_curriculum"
    subject: str
    grade_level: str
    strand: str  # e.g. "Number", "Algebra", "Reading"
    status: str = "not_covered"  # "covered" | "partially_covered" | "not_covered" | "planned"


# ---------------------------------------------------------------------------
# Teaching Observation
# ---------------------------------------------------------------------------


class TeachingObservation(BaseModel):
    """Record of a formal teaching observation using both British and American frameworks."""

    id: str
    teacher_id: str
    teacher_name: str
    subject: str
    date: str  # ISO 8601
    observer: str
    # British Ofsted 4-point scale: 1=Outstanding, 2=Good, 3=RI, 4=Inadequate
    ofsted_grade: int = Field(ge=1, le=4)
    # American Danielson Framework domain scores (1-4 each)
    danielson_domain_scores: dict[str, Any] = Field(default_factory=dict)
    strengths: list[str] = Field(default_factory=list)
    areas_for_improvement: list[str] = Field(default_factory=list)
    evidence_notes: str = ""


# ---------------------------------------------------------------------------
# Student Performance
# ---------------------------------------------------------------------------


class StudentPerformance(BaseModel):
    """Tracks academic performance for a single student across both frameworks."""

    student_id: str
    name: str
    year_group: str   # British: "Year 10"
    grade_level: str  # American: "Grade 10"
    subjects: dict[str, Any] = Field(default_factory=dict)
    attendance_rate: float = Field(ge=0.0, le=100.0)
    risk_level: str = "low"  # "high" | "medium" | "low"
    # British metrics
    progress_8_score: float = 0.0   # -1.0 to +1.0
    attainment_8_score: float = 0.0
    # American metrics
    gpa: float = Field(default=0.0, ge=0.0, le=4.0)
    state_assessment_proficiency: dict[str, Any] = Field(default_factory=dict)


# ---------------------------------------------------------------------------
# Inspection Evidence
# ---------------------------------------------------------------------------


class InspectionEvidence(BaseModel):
    """A piece of evidence submitted against an inspection criterion."""

    id: str
    criteria_id: str
    title: str
    description: str
    evidence_type: str  # "document" | "observation" | "data" | "policy" | "photo"
    file_path: str = ""
    uploaded_by: str
    uploaded_at: str  # ISO 8601
    tags: list[str] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Inspection Criteria
# ---------------------------------------------------------------------------


class InspectionCriteria(BaseModel):
    """A single judgement criterion from an inspection framework."""

    id: str
    framework: str  # "ofsted" | "cognia"
    category: str
    criterion: str
    description: str
    grade: str  # Self-assessment grade
    evidence_count: int = 0
    status: str = "in_progress"  # "ready" | "in_progress" | "needs_attention" | "critical"
    priority: str = "medium"    # "high" | "medium" | "low"


# ---------------------------------------------------------------------------
# Request / response helpers used by the API layer
# ---------------------------------------------------------------------------


class EvidenceUploadRequest(BaseModel):
    """Payload for POST /inspection/evidence."""

    criteria_id: str
    title: str
    description: str
    evidence_type: str
    uploaded_by: str
    tags: list[str] = Field(default_factory=list)
