"""
Inspection readiness engine — calculates scores, generates checklists,
and tracks evidence for Ofsted (British) and Cognia (American) inspections.

Python 3.11+ compatible.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone
from typing import Any

from .models import InspectionCriteria, InspectionEvidence

# ---------------------------------------------------------------------------
# Mock inspection data
# ---------------------------------------------------------------------------

_OFSTED_CRITERIA: list[dict[str, Any]] = [
    # Quality of Education
    {
        "id": "OE-QE-001",
        "framework": "ofsted",
        "category": "quality_of_education",
        "criterion": "Curriculum Intent",
        "description": "Curriculum is ambitious and sequenced appropriately for all pupils",
        "grade": "Good",
        "evidence_count": 8,
        "status": "ready",
        "priority": "medium",
    },
    {
        "id": "OE-QE-002",
        "framework": "ofsted",
        "category": "quality_of_education",
        "criterion": "Curriculum Implementation",
        "description": "Teaching enables pupils to acquire and remember knowledge",
        "grade": "Requires Improvement",
        "evidence_count": 4,
        "status": "needs_attention",
        "priority": "high",
    },
    {
        "id": "OE-QE-003",
        "framework": "ofsted",
        "category": "quality_of_education",
        "criterion": "Curriculum Impact",
        "description": "Pupils achieve well in national assessments and examinations",
        "grade": "Good",
        "evidence_count": 12,
        "status": "ready",
        "priority": "medium",
    },
    {
        "id": "OE-QE-004",
        "framework": "ofsted",
        "category": "quality_of_education",
        "criterion": "Assessment Practice",
        "description": "Assessment is used effectively to identify and address gaps",
        "grade": "Requires Improvement",
        "evidence_count": 3,
        "status": "needs_attention",
        "priority": "high",
    },
    # Behaviour and Attitudes
    {
        "id": "OE-BA-001",
        "framework": "ofsted",
        "category": "behaviour_and_attitudes",
        "criterion": "Behaviour Management",
        "description": "Behaviour across the school is good; rare instances are managed effectively",
        "grade": "Good",
        "evidence_count": 7,
        "status": "ready",
        "priority": "medium",
    },
    {
        "id": "OE-BA-002",
        "framework": "ofsted",
        "category": "behaviour_and_attitudes",
        "criterion": "Attendance and Punctuality",
        "description": "Overall attendance is above national average; persistent absence is addressed",
        "grade": "Requires Improvement",
        "evidence_count": 5,
        "status": "needs_attention",
        "priority": "high",
    },
    {
        "id": "OE-BA-003",
        "framework": "ofsted",
        "category": "behaviour_and_attitudes",
        "criterion": "Attitudes to Learning",
        "description": "Pupils are engaged and motivated in lessons",
        "grade": "Good",
        "evidence_count": 6,
        "status": "ready",
        "priority": "medium",
    },
    # Personal Development
    {
        "id": "OE-PD-001",
        "framework": "ofsted",
        "category": "personal_development",
        "criterion": "SMSC Development",
        "description": "Spiritual, moral, social and cultural development is embedded across curriculum",
        "grade": "Good",
        "evidence_count": 9,
        "status": "ready",
        "priority": "medium",
    },
    {
        "id": "OE-PD-002",
        "framework": "ofsted",
        "category": "personal_development",
        "criterion": "Careers Education",
        "description": "Careers education meets statutory requirements (Baker Clause)",
        "grade": "Requires Improvement",
        "evidence_count": 2,
        "status": "critical",
        "priority": "high",
    },
    {
        "id": "OE-PD-003",
        "framework": "ofsted",
        "category": "personal_development",
        "criterion": "Fundamental British Values",
        "description": "British values are promoted consistently across the school",
        "grade": "Good",
        "evidence_count": 5,
        "status": "ready",
        "priority": "medium",
    },
    # Leadership and Management
    {
        "id": "OE-LM-001",
        "framework": "ofsted",
        "category": "leadership_and_management",
        "criterion": "Strategic Vision",
        "description": "Leaders have clear, ambitious vision that is shared with all stakeholders",
        "grade": "Good",
        "evidence_count": 8,
        "status": "ready",
        "priority": "medium",
    },
    {
        "id": "OE-LM-002",
        "framework": "ofsted",
        "category": "leadership_and_management",
        "criterion": "Staff Development",
        "description": "CPD is targeted and effective; staff wellbeing is prioritised",
        "grade": "Good",
        "evidence_count": 7,
        "status": "ready",
        "priority": "medium",
    },
    {
        "id": "OE-LM-003",
        "framework": "ofsted",
        "category": "leadership_and_management",
        "criterion": "Governance",
        "description": "Governors provide effective challenge and support to the leadership",
        "grade": "Requires Improvement",
        "evidence_count": 3,
        "status": "needs_attention",
        "priority": "high",
    },
    # Safeguarding
    {
        "id": "OE-SG-001",
        "framework": "ofsted",
        "category": "safeguarding",
        "criterion": "Single Central Record",
        "description": "SCR is complete, accurate and regularly reviewed",
        "grade": "Effective",
        "evidence_count": 10,
        "status": "ready",
        "priority": "high",
    },
    {
        "id": "OE-SG-002",
        "framework": "ofsted",
        "category": "safeguarding",
        "criterion": "Staff Safeguarding Training",
        "description": "All staff trained on Keeping Children Safe in Education",
        "grade": "Effective",
        "evidence_count": 8,
        "status": "ready",
        "priority": "high",
    },
    {
        "id": "OE-SG-003",
        "framework": "ofsted",
        "category": "safeguarding",
        "criterion": "Online Safety",
        "description": "Online safety is taught and monitored effectively",
        "grade": "Requires Attention",
        "evidence_count": 2,
        "status": "needs_attention",
        "priority": "high",
    },
]

_COGNIA_CRITERIA: list[dict[str, Any]] = [
    {
        "id": "CG-CL-001",
        "framework": "cognia",
        "category": "culture_of_learning",
        "criterion": "Leadership Capacity",
        "description": "Leaders build capacity throughout the organization",
        "grade": "Proficient",
        "evidence_count": 9,
        "status": "ready",
        "priority": "medium",
    },
    {
        "id": "CG-CL-002",
        "framework": "cognia",
        "category": "culture_of_learning",
        "criterion": "Professional Learning Culture",
        "description": "A culture of professional learning is established and sustained",
        "grade": "Developing",
        "evidence_count": 4,
        "status": "needs_attention",
        "priority": "high",
    },
    {
        "id": "CG-LL-001",
        "framework": "cognia",
        "category": "leadership_for_learning",
        "criterion": "Strategic Leadership",
        "description": "Leaders develop and implement strategic plans for improvement",
        "grade": "Proficient",
        "evidence_count": 7,
        "status": "ready",
        "priority": "medium",
    },
    {
        "id": "CG-LL-002",
        "framework": "cognia",
        "category": "leadership_for_learning",
        "criterion": "Instructional Leadership",
        "description": "Leaders prioritize and monitor effective instruction",
        "grade": "Developing",
        "evidence_count": 3,
        "status": "needs_attention",
        "priority": "high",
    },
    {
        "id": "CG-EL-001",
        "framework": "cognia",
        "category": "engagement_of_learning",
        "criterion": "Learner Engagement",
        "description": "Learners are actively engaged in meaningful learning experiences",
        "grade": "Proficient",
        "evidence_count": 8,
        "status": "ready",
        "priority": "medium",
    },
    {
        "id": "CG-EL-002",
        "framework": "cognia",
        "category": "engagement_of_learning",
        "criterion": "Effective Instruction",
        "description": "Instruction is research-based and differentiated for all learners",
        "grade": "Developing",
        "evidence_count": 5,
        "status": "needs_attention",
        "priority": "high",
    },
    {
        "id": "CG-EL-003",
        "framework": "cognia",
        "category": "engagement_of_learning",
        "criterion": "Assessment Practices",
        "description": "Assessment data is used to drive instructional decisions",
        "grade": "Proficient",
        "evidence_count": 6,
        "status": "ready",
        "priority": "medium",
    },
    {
        "id": "CG-GL-001",
        "framework": "cognia",
        "category": "growth_in_learning",
        "criterion": "Achievement Levels",
        "description": "Learner achievement meets or exceeds established benchmarks",
        "grade": "Developing",
        "evidence_count": 7,
        "status": "needs_attention",
        "priority": "high",
    },
    {
        "id": "CG-GL-002",
        "framework": "cognia",
        "category": "growth_in_learning",
        "criterion": "Growth Patterns",
        "description": "Evidence demonstrates year-over-year growth in learning",
        "grade": "Proficient",
        "evidence_count": 8,
        "status": "ready",
        "priority": "medium",
    },
]

# Grade → numeric score mapping
_OFSTED_GRADE_SCORES: dict[str, float] = {
    "Outstanding": 100.0,
    "Good": 75.0,
    "Requires Improvement": 50.0,
    "Inadequate": 25.0,
    "Effective": 80.0,
    "Requires Attention": 45.0,
}

_COGNIA_GRADE_SCORES: dict[str, float] = {
    "Exemplary": 100.0,
    "Proficient": 75.0,
    "Developing": 50.0,
    "Not Met": 25.0,
}

# Weights for Ofsted judgment areas
_OFSTED_AREA_WEIGHTS: dict[str, float] = {
    "quality_of_education": 0.40,
    "behaviour_and_attitudes": 0.20,
    "personal_development": 0.20,
    "leadership_and_management": 0.20,
}

# Mock evidence items
_MOCK_EVIDENCE: list[dict[str, Any]] = [
    {
        "id": "EV-001",
        "criteria_id": "OE-QE-001",
        "title": "Curriculum Intent Document 2025-26",
        "description": "Whole-school curriculum intent statement approved by governors",
        "evidence_type": "document",
        "file_path": "/evidence/curriculum_intent_2025.pdf",
        "uploaded_by": "Principal",
        "uploaded_at": "2026-01-15T10:00:00Z",
        "tags": ["curriculum", "intent", "governance"],
    },
    {
        "id": "EV-002",
        "criteria_id": "OE-QE-001",
        "title": "Curriculum Maps — All Subjects 2025-26",
        "description": "Detailed curriculum maps showing sequencing for all year groups",
        "evidence_type": "document",
        "file_path": "/evidence/curriculum_maps_2025.pdf",
        "uploaded_by": "Curriculum Lead",
        "uploaded_at": "2026-01-20T14:30:00Z",
        "tags": ["curriculum", "mapping", "sequencing"],
    },
    {
        "id": "EV-003",
        "criteria_id": "OE-BA-002",
        "title": "Attendance Data — Autumn Term 2025",
        "description": "Attendance analysis showing 91.2% overall, 4.8% persistent absence",
        "evidence_type": "data",
        "file_path": "/evidence/attendance_autumn_2025.xlsx",
        "uploaded_by": "Data Manager",
        "uploaded_at": "2026-01-10T09:00:00Z",
        "tags": ["attendance", "data", "persistent absence"],
    },
    {
        "id": "EV-004",
        "criteria_id": "OE-SG-001",
        "title": "Single Central Record — March 2026",
        "description": "Complete SCR with all DBS checks, qualifications and references verified",
        "evidence_type": "document",
        "file_path": "/evidence/scr_march_2026.pdf",
        "uploaded_by": "HR Manager",
        "uploaded_at": "2026-03-01T08:00:00Z",
        "tags": ["safeguarding", "SCR", "DBS"],
    },
    {
        "id": "EV-005",
        "criteria_id": "OE-LM-001",
        "title": "School Development Plan 2025-27",
        "description": "Three-year strategic plan with measurable targets",
        "evidence_type": "document",
        "file_path": "/evidence/sdp_2025_27.pdf",
        "uploaded_by": "Principal",
        "uploaded_at": "2025-09-01T09:00:00Z",
        "tags": ["strategy", "leadership", "planning"],
    },
]


def _generate_trend_data(days: int = 90) -> list[dict[str, Any]]:
    """Generate mock readiness trend data for the requested number of days."""
    now = datetime.now(timezone.utc)
    data_points: list[dict[str, Any]] = []
    # Start at 62%, end at ~75% — realistic upward trend with minor variation
    base = 62.0
    increment = (75.0 - base) / days
    for i in range(0, days + 1, 7):  # weekly data points
        score = round(base + i * increment + ((-1) ** i) * 0.5, 1)
        data_points.append(
            {
                "date": (now - timedelta(days=days - i)).strftime("%Y-%m-%d"),
                "score": min(score, 100.0),
            }
        )
    return data_points


# ---------------------------------------------------------------------------
# InspectionReadinessEngine
# ---------------------------------------------------------------------------


class InspectionReadinessEngine:
    """Calculates inspection readiness and generates preparation checklists."""

    def __init__(self) -> None:
        self._ofsted_criteria: list[dict[str, Any]] = _OFSTED_CRITERIA
        self._cognia_criteria: list[dict[str, Any]] = _COGNIA_CRITERIA
        self._evidence: list[dict[str, Any]] = list(_MOCK_EVIDENCE)
        # Pre-computed combined criteria list used for evidence validation lookups.
        self._all_criteria: list[dict[str, Any]] = (
            self._ofsted_criteria + self._cognia_criteria
        )

    def _get_criteria(self, framework: str) -> list[dict[str, Any]]:
        if framework.lower() == "cognia":
            return self._cognia_criteria
        return self._ofsted_criteria

    def _criteria_score(self, criterion: dict[str, Any], framework: str) -> float:
        """Convert a grade string to a numeric score (0-100)."""
        grade = criterion.get("grade", "")
        if framework.lower() == "cognia":
            return _COGNIA_GRADE_SCORES.get(grade, 50.0)
        return _OFSTED_GRADE_SCORES.get(grade, 50.0)

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def calculate_overall_readiness(self, framework: str = "ofsted") -> dict[str, Any]:
        """Return overall readiness score 0–100 with per-area breakdown."""
        criteria = self._get_criteria(framework)

        if framework.lower() == "cognia":
            # Group by category, equal weight
            categories: dict[str, list[dict[str, Any]]] = {}
            for c in criteria:
                categories.setdefault(c["category"], []).append(c)

            area_scores: dict[str, Any] = {}
            total_score = 0.0
            for cat, items in categories.items():
                avg = round(
                    sum(self._criteria_score(i, framework) for i in items) / len(items),
                    1,
                )
                status = "ready" if avg >= 70 else "needs_attention"
                area_scores[cat] = {
                    "score": avg,
                    "grade": self._score_to_grade(avg, framework),
                    "status": status,
                    "criteria_count": len(items),
                }
                total_score += avg
            overall = round(total_score / len(area_scores), 1) if area_scores else 0.0
        else:
            # Ofsted — weighted areas
            area_scores = {}
            weighted_total = 0.0
            for area, weight in _OFSTED_AREA_WEIGHTS.items():
                area_criteria = [c for c in criteria if c["category"] == area]
                if not area_criteria:
                    continue
                avg = round(
                    sum(self._criteria_score(c, framework) for c in area_criteria)
                    / len(area_criteria),
                    1,
                )
                status = "ready" if avg >= 70 else ("needs_attention" if avg >= 45 else "critical")
                area_scores[area] = {
                    "score": avg,
                    "grade": self._score_to_grade(avg, framework),
                    "status": status,
                    "criteria_count": len(area_criteria),
                }
                weighted_total += avg * weight
            overall = round(weighted_total, 1)

        # Check safeguarding separately
        safeguarding_items = [c for c in criteria if c.get("category") == "safeguarding"]
        safeguarding_ok = all(
            c.get("status") in ("ready", "in_progress") for c in safeguarding_items
        )

        return {
            "framework": framework,
            "overall_score": overall,
            "overall_grade": self._score_to_grade(overall, framework),
            "areas": area_scores,
            "safeguarding_effective": safeguarding_ok,
            "ready_for_inspection": overall >= 65 and safeguarding_ok,
            "generated_at": datetime.now(timezone.utc)
            .replace(microsecond=0)
            .isoformat()
            .replace("+00:00", "Z"),
        }

    def _score_to_grade(self, score: float, framework: str) -> str:
        """Convert a numeric score to a grade label."""
        if framework.lower() == "cognia":
            if score >= 85:
                return "Exemplary"
            if score >= 65:
                return "Proficient"
            if score >= 45:
                return "Developing"
            return "Not Met"
        # Ofsted
        if score >= 85:
            return "Outstanding"
        if score >= 65:
            return "Good"
        if score >= 45:
            return "Requires Improvement"
        return "Inadequate"

    def get_checklist(self, framework: str = "ofsted") -> list[InspectionCriteria]:
        """Return the full inspection preparation checklist."""
        criteria = self._get_criteria(framework)
        return [InspectionCriteria(**c) for c in criteria]

    def get_priority_actions(
        self,
        framework: str = "ofsted",
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """Return top priority actions sorted by urgency (critical → high → medium → low)."""
        criteria = self._get_criteria(framework)
        priority_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}

        action_items = [
            c
            for c in criteria
            if c.get("status") in ("critical", "needs_attention", "in_progress")
        ]
        action_items.sort(
            key=lambda x: (
                priority_order.get(x.get("priority", "low"), 3),
                x.get("evidence_count", 0),
            )
        )

        return [
            {
                "id": item["id"],
                "framework": item["framework"],
                "category": item["category"],
                "criterion": item["criterion"],
                "description": item["description"],
                "status": item["status"],
                "priority": item["priority"],
                "evidence_count": item["evidence_count"],
                "action": f"Gather additional evidence for: {item['criterion']}",
            }
            for item in action_items[:limit]
        ]

    def get_evidence_tracker(
        self, area: str | None = None
    ) -> dict[str, Any]:
        """Return evidence tracking for each criterion."""
        criteria = self._all_criteria
        if area:
            criteria = [c for c in criteria if c.get("category") == area]

        tracker: dict[str, Any] = {}
        for criterion in criteria:
            cid = criterion["id"]
            evidence_items = [e for e in self._evidence if e["criteria_id"] == cid]
            evidence_count = criterion.get("evidence_count", len(evidence_items))

            if evidence_count >= 6:
                evidence_status = "complete"
            elif evidence_count >= 3:
                evidence_status = "partial"
            else:
                evidence_status = "missing"

            tracker[cid] = {
                "criterion": criterion["criterion"],
                "framework": criterion["framework"],
                "category": criterion["category"],
                "grade": criterion["grade"],
                "evidence_count": evidence_count,
                "evidence_status": evidence_status,
                "evidence_items": [
                    {
                        "id": e["id"],
                        "title": e["title"],
                        "type": e["evidence_type"],
                        "uploaded_at": e["uploaded_at"],
                    }
                    for e in evidence_items
                ],
            }
        return tracker

    def generate_self_evaluation(self, framework: str = "ofsted") -> dict[str, Any]:
        """Generate a Self-Evaluation Form (SEF) summary."""
        readiness = self.calculate_overall_readiness(framework)
        criteria = self._get_criteria(framework)

        sections: dict[str, Any] = {}
        categories = list({c["category"] for c in criteria})
        for cat in sorted(categories):
            cat_criteria = [c for c in criteria if c["category"] == cat]
            strengths = [
                c["criterion"]
                for c in cat_criteria
                if c.get("status") == "ready"
            ]
            improvements = [
                c["criterion"]
                for c in cat_criteria
                if c.get("status") in ("needs_attention", "critical")
            ]
            grade_scores = [self._criteria_score(c, framework) for c in cat_criteria]
            avg_score = round(sum(grade_scores) / len(grade_scores), 1) if grade_scores else 0.0
            sections[cat] = {
                "self_assessment_grade": self._score_to_grade(avg_score, framework),
                "strengths": strengths,
                "areas_for_improvement": improvements,
                "criteria_count": len(cat_criteria),
            }

        return {
            "framework": framework,
            "institution": "Core West College",
            "generated_at": datetime.now(timezone.utc)
            .replace(microsecond=0)
            .isoformat()
            .replace("+00:00", "Z"),
            "overall_grade": readiness["overall_grade"],
            "overall_score": readiness["overall_score"],
            "sections": sections,
            "key_strengths": [
                "Strong curriculum intent and sequencing",
                "Effective safeguarding culture with complete SCR",
                "High staff wellbeing and CPD participation",
                "Good pupil behaviour and positive attitudes to learning",
            ],
            "development_priorities": [
                "Improve consistency of assessment practice across departments",
                "Raise attendance rate to exceed national average",
                "Strengthen governance challenge and support mechanisms",
                "Enhance careers education provision to meet statutory requirements",
            ],
        }

    def get_readiness_trend(self, days: int = 90) -> list[dict[str, Any]]:
        """Return readiness score trend data over time."""
        return _generate_trend_data(days)

    def add_evidence(self, evidence_data: dict[str, Any]) -> InspectionEvidence:
        """Register a new piece of evidence against a criterion.

        Raises:
            ValueError: If ``criteria_id`` does not match any known criterion.
        """
        criteria_id = evidence_data.get("criteria_id", "")
        matching = [c for c in self._all_criteria if c["id"] == criteria_id]
        if not matching:
            raise ValueError(
                f"Unknown criteria_id '{criteria_id}'. "
                "Evidence must be linked to an existing inspection criterion."
            )

        new_evidence = {
            "id": str(uuid.uuid4()),
            "uploaded_at": datetime.now(timezone.utc).isoformat(),
            **evidence_data,
        }
        self._evidence.append(new_evidence)

        # Update evidence count on matching criterion
        for criterion in matching:
            criterion["evidence_count"] = criterion.get("evidence_count", 0) + 1

        return InspectionEvidence(**new_evidence)

    def get_voice_summary(self) -> str:
        """Return a voice-friendly inspection readiness summary for Alexa."""
        readiness = self.calculate_overall_readiness("ofsted")
        score = readiness["overall_score"]
        grade = readiness["overall_grade"]
        critical_items = sum(
            1
            for area in readiness["areas"].values()
            if area.get("status") == "critical"
        )
        safeguarding = "effective" if readiness["safeguarding_effective"] else "requires attention"

        response = (
            f"Inspection readiness score is {score}%, rated as {grade}. "
            f"Safeguarding is {safeguarding}. "
        )
        if critical_items:
            response += (
                f"There are {critical_items} critical areas requiring immediate attention. "
            )
        else:
            response += "No critical areas identified. "
        response += "Review the inspection dashboard for the full action plan."
        return response
