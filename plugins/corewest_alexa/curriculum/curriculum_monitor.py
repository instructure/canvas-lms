"""
Curriculum monitoring engine — tracks coverage and identifies gaps.

Provides realistic mock data for all core subjects and returns
coverage statistics, gap analyses, and department overviews.

Python 3.11+ compatible.
"""

from __future__ import annotations

from typing import Any

from .models import CurriculumStandard

# ---------------------------------------------------------------------------
# Mock standards data
# (In production this would be loaded from the Canvas LMS database.)
# ---------------------------------------------------------------------------

_MOCK_STANDARDS: list[dict[str, Any]] = [
    # Mathematics ─ National Curriculum
    {"id": "MA-NC-001", "subject": "Mathematics", "framework": "national_curriculum",
     "code": "NC.KS3.MA.1", "description": "Work with integers and rational numbers",
     "grade_level": "KS3", "strand": "Number", "status": "covered"},
    {"id": "MA-NC-002", "subject": "Mathematics", "framework": "national_curriculum",
     "code": "NC.KS3.MA.2", "description": "Use algebraic notation and expressions",
     "grade_level": "KS3", "strand": "Algebra", "status": "covered"},
    {"id": "MA-NC-003", "subject": "Mathematics", "framework": "national_curriculum",
     "code": "NC.KS3.MA.3", "description": "Apply geometric reasoning to shapes",
     "grade_level": "KS3", "strand": "Geometry", "status": "partially_covered"},
    {"id": "MA-NC-004", "subject": "Mathematics", "framework": "national_curriculum",
     "code": "NC.KS3.MA.4", "description": "Collect, analyse and interpret statistics",
     "grade_level": "KS3", "strand": "Statistics", "status": "covered"},
    {"id": "MA-NC-005", "subject": "Mathematics", "framework": "national_curriculum",
     "code": "NC.KS3.MA.5", "description": "Calculate probabilities",
     "grade_level": "KS3", "strand": "Statistics", "status": "not_covered"},
    {"id": "MA-NC-006", "subject": "Mathematics", "framework": "national_curriculum",
     "code": "NC.KS4.MA.1", "description": "Solve quadratic equations",
     "grade_level": "KS4", "strand": "Algebra", "status": "covered"},
    {"id": "MA-NC-007", "subject": "Mathematics", "framework": "national_curriculum",
     "code": "NC.KS4.MA.2", "description": "Calculate probability of combined events",
     "grade_level": "KS4", "strand": "Statistics", "status": "partially_covered"},
    {"id": "MA-NC-008", "subject": "Mathematics", "framework": "national_curriculum",
     "code": "NC.KS4.MA.3", "description": "Apply trigonometry to right-angled triangles",
     "grade_level": "KS4", "strand": "Geometry", "status": "covered"},
    {"id": "MA-NC-009", "subject": "Mathematics", "framework": "national_curriculum",
     "code": "NC.KS4.MA.4", "description": "Use vectors to describe translations",
     "grade_level": "KS4", "strand": "Geometry", "status": "planned"},
    # Mathematics ─ Common Core
    {"id": "MA-CC-001", "subject": "Mathematics", "framework": "common_core",
     "code": "CCSS.MATH.7.RP.1", "description": "Compute unit rates associated with ratios",
     "grade_level": "Grade 7", "strand": "Ratios & Proportions", "status": "covered"},
    {"id": "MA-CC-002", "subject": "Mathematics", "framework": "common_core",
     "code": "CCSS.MATH.8.EE.1", "description": "Know and apply properties of integer exponents",
     "grade_level": "Grade 8", "strand": "Number & Operations", "status": "covered"},
    {"id": "MA-CC-003", "subject": "Mathematics", "framework": "common_core",
     "code": "CCSS.MATH.HS.A.1", "description": "Interpret the structure of algebraic expressions",
     "grade_level": "High School", "strand": "Algebra", "status": "partially_covered"},
    # English ─ National Curriculum
    {"id": "EN-NC-001", "subject": "English", "framework": "national_curriculum",
     "code": "NC.KS3.EN.1", "description": "Read and understand complex literary texts",
     "grade_level": "KS3", "strand": "Reading Literature", "status": "covered"},
    {"id": "EN-NC-002", "subject": "English", "framework": "national_curriculum",
     "code": "NC.KS3.EN.2", "description": "Write clearly and coherently for different purposes",
     "grade_level": "KS3", "strand": "Writing", "status": "covered"},
    {"id": "EN-NC-003", "subject": "English", "framework": "national_curriculum",
     "code": "NC.KS3.EN.3", "description": "Develop vocabulary and language skills",
     "grade_level": "KS3", "strand": "Language", "status": "covered"},
    {"id": "EN-NC-004", "subject": "English", "framework": "national_curriculum",
     "code": "NC.KS3.EN.4", "description": "Speak confidently and effectively",
     "grade_level": "KS3", "strand": "Speaking & Listening", "status": "partially_covered"},
    {"id": "EN-NC-005", "subject": "English", "framework": "national_curriculum",
     "code": "NC.KS4.EN.1", "description": "Analyse language, form, and structure of texts",
     "grade_level": "KS4", "strand": "Reading Literature", "status": "covered"},
    {"id": "EN-NC-006", "subject": "English", "framework": "national_curriculum",
     "code": "NC.KS4.EN.2", "description": "Write for a range of purposes and audiences",
     "grade_level": "KS4", "strand": "Writing", "status": "covered"},
    {"id": "EN-NC-007", "subject": "English", "framework": "national_curriculum",
     "code": "NC.KS4.EN.3", "description": "Understand Spoken Language and Debate",
     "grade_level": "KS4", "strand": "Speaking & Listening", "status": "not_covered"},
    # English ─ Common Core
    {"id": "EN-CC-001", "subject": "English", "framework": "common_core",
     "code": "CCSS.ELA.7.RL.1", "description": "Cite several pieces of textual evidence",
     "grade_level": "Grade 7", "strand": "Reading Literature", "status": "covered"},
    {"id": "EN-CC-002", "subject": "English", "framework": "common_core",
     "code": "CCSS.ELA.8.W.1", "description": "Write arguments to support claims",
     "grade_level": "Grade 8", "strand": "Writing", "status": "covered"},
    {"id": "EN-CC-003", "subject": "English", "framework": "common_core",
     "code": "CCSS.ELA.9.RI.1", "description": "Cite strong textual evidence for informational text",
     "grade_level": "Grade 9", "strand": "Reading Informational Text", "status": "partially_covered"},
    # Science ─ National Curriculum
    {"id": "SC-NC-001", "subject": "Science", "framework": "national_curriculum",
     "code": "NC.KS3.SC.1", "description": "Understand cell structure and function",
     "grade_level": "KS3", "strand": "Biology", "status": "covered"},
    {"id": "SC-NC-002", "subject": "Science", "framework": "national_curriculum",
     "code": "NC.KS3.SC.2", "description": "Understand forces and motion",
     "grade_level": "KS3", "strand": "Physics", "status": "covered"},
    {"id": "SC-NC-003", "subject": "Science", "framework": "national_curriculum",
     "code": "NC.KS3.SC.3", "description": "Understand particle model of matter",
     "grade_level": "KS3", "strand": "Chemistry", "status": "partially_covered"},
    {"id": "SC-NC-004", "subject": "Science", "framework": "national_curriculum",
     "code": "NC.KS4.SC.1", "description": "Understand DNA, inheritance, and genetics",
     "grade_level": "KS4", "strand": "Biology", "status": "covered"},
    {"id": "SC-NC-005", "subject": "Science", "framework": "national_curriculum",
     "code": "NC.KS4.SC.2", "description": "Understand atomic structure and periodic table",
     "grade_level": "KS4", "strand": "Chemistry", "status": "covered"},
    {"id": "SC-NC-006", "subject": "Science", "framework": "national_curriculum",
     "code": "NC.KS4.SC.3", "description": "Understand energy transfers and transformations",
     "grade_level": "KS4", "strand": "Physics", "status": "not_covered"},
    {"id": "SC-NC-007", "subject": "Science", "framework": "national_curriculum",
     "code": "NC.KS4.SC.4", "description": "Understand space physics",
     "grade_level": "KS4", "strand": "Physics", "status": "planned"},
    # History
    {"id": "HI-NC-001", "subject": "History", "framework": "national_curriculum",
     "code": "NC.KS3.HI.1", "description": "Understand Medieval Britain 1066-1509",
     "grade_level": "KS3", "strand": "British History", "status": "covered"},
    {"id": "HI-NC-002", "subject": "History", "framework": "national_curriculum",
     "code": "NC.KS3.HI.2", "description": "Church, state, and society 1509-1745",
     "grade_level": "KS3", "strand": "British History", "status": "covered"},
    {"id": "HI-NC-003", "subject": "History", "framework": "national_curriculum",
     "code": "NC.KS3.HI.3", "description": "Challenges for Britain, Europe and wider world 1901-present",
     "grade_level": "KS3", "strand": "World History", "status": "partially_covered"},
    {"id": "HI-NC-004", "subject": "History", "framework": "national_curriculum",
     "code": "NC.KS4.HI.1", "description": "Causes and consequences of World War One",
     "grade_level": "KS4", "strand": "World History", "status": "covered"},
    {"id": "HI-NC-005", "subject": "History", "framework": "national_curriculum",
     "code": "NC.KS4.HI.2", "description": "The Holocaust and World War Two",
     "grade_level": "KS4", "strand": "World History", "status": "covered"},
    # Geography
    {"id": "GE-NC-001", "subject": "Geography", "framework": "national_curriculum",
     "code": "NC.KS3.GE.1", "description": "Understand physical geography including tectonics",
     "grade_level": "KS3", "strand": "Physical Geography", "status": "covered"},
    {"id": "GE-NC-002", "subject": "Geography", "framework": "national_curriculum",
     "code": "NC.KS3.GE.2", "description": "Understand human geography and urbanisation",
     "grade_level": "KS3", "strand": "Human Geography", "status": "partially_covered"},
    {"id": "GE-NC-003", "subject": "Geography", "framework": "national_curriculum",
     "code": "NC.KS4.GE.1", "description": "Understand coastal landscapes",
     "grade_level": "KS4", "strand": "Physical Geography", "status": "covered"},
    {"id": "GE-NC-004", "subject": "Geography", "framework": "national_curriculum",
     "code": "NC.KS4.GE.2", "description": "Understand global development inequalities",
     "grade_level": "KS4", "strand": "Human Geography", "status": "not_covered"},
    # Modern Foreign Languages
    {"id": "ML-NC-001", "subject": "Modern Foreign Languages", "framework": "national_curriculum",
     "code": "NC.KS3.ML.1", "description": "Communicate on familiar topics in target language",
     "grade_level": "KS3", "strand": "Speaking", "status": "covered"},
    {"id": "ML-NC-002", "subject": "Modern Foreign Languages", "framework": "national_curriculum",
     "code": "NC.KS3.ML.2", "description": "Read and understand written texts",
     "grade_level": "KS3", "strand": "Reading", "status": "covered"},
    {"id": "ML-NC-003", "subject": "Modern Foreign Languages", "framework": "national_curriculum",
     "code": "NC.KS4.ML.1", "description": "Understand authentic texts and media",
     "grade_level": "KS4", "strand": "Reading & Listening", "status": "partially_covered"},
    {"id": "ML-NC-004", "subject": "Modern Foreign Languages", "framework": "national_curriculum",
     "code": "NC.KS4.ML.2", "description": "Write extended pieces using accurate grammar",
     "grade_level": "KS4", "strand": "Writing", "status": "not_covered"},
    # Art
    {"id": "AR-NC-001", "subject": "Art", "framework": "national_curriculum",
     "code": "NC.KS3.AR.1", "description": "Produce creative work exploring different media",
     "grade_level": "KS3", "strand": "Creating", "status": "covered"},
    {"id": "AR-NC-002", "subject": "Art", "framework": "national_curriculum",
     "code": "NC.KS3.AR.2", "description": "Become proficient in drawing, painting, sculpture",
     "grade_level": "KS3", "strand": "Techniques", "status": "covered"},
    {"id": "AR-NC-003", "subject": "Art", "framework": "national_curriculum",
     "code": "NC.KS4.AR.1", "description": "Analyse and evaluate art, craft and design",
     "grade_level": "KS4", "strand": "Evaluating", "status": "covered"},
    # Music
    {"id": "MU-NC-001", "subject": "Music", "framework": "national_curriculum",
     "code": "NC.KS3.MU.1", "description": "Perform, listen to, review and evaluate music",
     "grade_level": "KS3", "strand": "Performing", "status": "covered"},
    {"id": "MU-NC-002", "subject": "Music", "framework": "national_curriculum",
     "code": "NC.KS3.MU.2", "description": "Learn to sing and use voices in ensemble",
     "grade_level": "KS3", "strand": "Performing", "status": "covered"},
    {"id": "MU-NC-003", "subject": "Music", "framework": "national_curriculum",
     "code": "NC.KS3.MU.3", "description": "Improvise and compose music",
     "grade_level": "KS3", "strand": "Composing", "status": "partially_covered"},
    # PE
    {"id": "PE-NC-001", "subject": "PE", "framework": "national_curriculum",
     "code": "NC.KS3.PE.1", "description": "Use running, jumping, throwing and catching",
     "grade_level": "KS3", "strand": "Physical Skills", "status": "covered"},
    {"id": "PE-NC-002", "subject": "PE", "framework": "national_curriculum",
     "code": "NC.KS3.PE.2", "description": "Develop competence to excel in broad sports",
     "grade_level": "KS3", "strand": "Sport", "status": "covered"},
    {"id": "PE-NC-003", "subject": "PE", "framework": "national_curriculum",
     "code": "NC.KS4.PE.1", "description": "Evaluate performance and develop plans to improve",
     "grade_level": "KS4", "strand": "Evaluating", "status": "covered"},
    # Computing
    {"id": "CO-NC-001", "subject": "Computing", "framework": "national_curriculum",
     "code": "NC.KS3.CO.1", "description": "Design, use and evaluate computational abstractions",
     "grade_level": "KS3", "strand": "Computer Science", "status": "covered"},
    {"id": "CO-NC-002", "subject": "Computing", "framework": "national_curriculum",
     "code": "NC.KS3.CO.2", "description": "Understand the components of computer systems",
     "grade_level": "KS3", "strand": "Systems", "status": "partially_covered"},
    {"id": "CO-NC-003", "subject": "Computing", "framework": "national_curriculum",
     "code": "NC.KS4.CO.1", "description": "Apply fundamental principles of computer science",
     "grade_level": "KS4", "strand": "Computer Science", "status": "covered"},
    {"id": "CO-NC-004", "subject": "Computing", "framework": "national_curriculum",
     "code": "NC.KS4.CO.2", "description": "Understand cybersecurity threats and defences",
     "grade_level": "KS4", "strand": "Cybersecurity", "status": "not_covered"},
    # PSHE
    {"id": "PS-NC-001", "subject": "PSHE", "framework": "national_curriculum",
     "code": "NC.KS3.PS.1", "description": "Understand health and wellbeing including mental health",
     "grade_level": "KS3", "strand": "Health & Wellbeing", "status": "covered"},
    {"id": "PS-NC-002", "subject": "PSHE", "framework": "national_curriculum",
     "code": "NC.KS3.PS.2", "description": "Understand relationships and healthy boundaries",
     "grade_level": "KS3", "strand": "Relationships", "status": "covered"},
    {"id": "PS-NC-003", "subject": "PSHE", "framework": "national_curriculum",
     "code": "NC.KS4.PS.1", "description": "Understand relationships and sex education (RSE)",
     "grade_level": "KS4", "strand": "Relationships & RSE", "status": "covered"},
    {"id": "PS-NC-004", "subject": "PSHE", "framework": "national_curriculum",
     "code": "NC.KS4.PS.2", "description": "Understand financial literacy and careers",
     "grade_level": "KS4", "strand": "Careers & Finance", "status": "partially_covered"},
]

# Department grouping
_SUBJECT_DEPARTMENTS: dict[str, str] = {
    "Mathematics": "STEM",
    "Science": "STEM",
    "Computing": "STEM",
    "English": "Humanities",
    "History": "Humanities",
    "Geography": "Humanities",
    "Modern Foreign Languages": "Languages",
    "Art": "Creative Arts",
    "Music": "Creative Arts",
    "PE": "Physical Education",
    "PSHE": "Personal Development",
}

# Mock teaching quality scores per subject (0-100)
_TEACHING_QUALITY: dict[str, float] = {
    "Mathematics": 78.0,
    "English": 82.0,
    "Science": 74.0,
    "History": 85.0,
    "Geography": 79.0,
    "Modern Foreign Languages": 71.0,
    "Art": 88.0,
    "Music": 90.0,
    "PE": 86.0,
    "Computing": 72.0,
    "PSHE": 80.0,
}

# Mock student outcomes per subject (pass rate %)
_STUDENT_OUTCOMES: dict[str, float] = {
    "Mathematics": 68.0,
    "English": 74.0,
    "Science": 70.0,
    "History": 78.0,
    "Geography": 73.0,
    "Modern Foreign Languages": 65.0,
    "Art": 85.0,
    "Music": 88.0,
    "PE": 92.0,
    "Computing": 67.0,
    "PSHE": 81.0,
}


# ---------------------------------------------------------------------------
# CurriculumMonitor
# ---------------------------------------------------------------------------


class CurriculumMonitor:
    """Monitors curriculum coverage and identifies gaps across all subjects."""

    def __init__(self) -> None:
        self._standards: list[dict[str, Any]] = _MOCK_STANDARDS

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _filter(
        self,
        subject: str | None = None,
        framework: str | None = None,
    ) -> list[dict[str, Any]]:
        """Return standards matching the given filters."""
        results = self._standards
        if subject:
            results = [s for s in results if s["subject"] == subject]
        if framework and framework != "all":
            results = [s for s in results if s["framework"] == framework]
        return results

    def _coverage_stats(self, standards: list[dict[str, Any]]) -> dict[str, Any]:
        """Compute coverage statistics for a list of standards."""
        total = len(standards)
        if total == 0:
            return {
                "total_standards": 0,
                "covered": 0,
                "partially_covered": 0,
                "not_covered": 0,
                "planned": 0,
                "coverage_pct": 0.0,
            }
        covered = sum(1 for s in standards if s["status"] == "covered")
        partial = sum(1 for s in standards if s["status"] == "partially_covered")
        not_cov = sum(1 for s in standards if s["status"] == "not_covered")
        planned = sum(1 for s in standards if s["status"] == "planned")
        # Partial counts as 0.5 towards coverage
        coverage_pct = round(((covered + 0.5 * partial) / total) * 100, 1)
        return {
            "total_standards": total,
            "covered": covered,
            "partially_covered": partial,
            "not_covered": not_cov,
            "planned": planned,
            "coverage_pct": coverage_pct,
        }

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def get_coverage_summary(
        self,
        subject: str | None = None,
        framework: str = "all",
    ) -> dict[str, Any]:
        """Return curriculum coverage percentages per subject (or for one subject)."""
        if subject:
            standards = self._filter(subject=subject, framework=framework)
            return {subject: self._coverage_stats(standards)}

        subjects = list({s["subject"] for s in self._standards})
        summary: dict[str, Any] = {}
        for subj in sorted(subjects):
            standards = self._filter(subject=subj, framework=framework)
            summary[subj] = self._coverage_stats(standards)
        return summary

    def identify_gaps(
        self,
        subject: str | None = None,
        framework: str | None = None,
    ) -> list[CurriculumStandard]:
        """Identify curriculum gaps — standards that are not fully covered."""
        standards = self._filter(subject=subject, framework=framework)
        gap_statuses = {"not_covered", "partially_covered", "planned"}
        return [
            CurriculumStandard(**{k: v for k, v in s.items()})
            for s in standards
            if s["status"] in gap_statuses
        ]

    def get_subject_health(self, subject: str) -> dict[str, Any]:
        """Return overall health score 0–100 for a subject.

        Combines curriculum coverage, teaching quality, and student outcomes.
        """
        standards = self._filter(subject=subject)
        coverage = self._coverage_stats(standards)
        coverage_score = coverage["coverage_pct"]
        teaching_score = _TEACHING_QUALITY.get(subject, 70.0)
        outcomes_score = _STUDENT_OUTCOMES.get(subject, 70.0)

        overall = round(
            0.40 * coverage_score + 0.35 * teaching_score + 0.25 * outcomes_score,
            1,
        )
        return {
            "subject": subject,
            "overall_health": overall,
            "coverage_score": coverage_score,
            "teaching_quality_score": teaching_score,
            "student_outcomes_score": outcomes_score,
            "standards_summary": coverage,
        }

    def get_department_overview(self) -> dict[str, Any]:
        """Return summary aggregated per department."""
        departments: dict[str, list[str]] = {}
        for subj, dept in _SUBJECT_DEPARTMENTS.items():
            departments.setdefault(dept, []).append(subj)

        overview: dict[str, Any] = {}
        for dept, subjects in departments.items():
            all_standards: list[dict[str, Any]] = []
            teaching_scores: list[float] = []
            outcome_scores: list[float] = []
            for subj in subjects:
                all_standards.extend(self._filter(subject=subj))
                teaching_scores.append(_TEACHING_QUALITY.get(subj, 70.0))
                outcome_scores.append(_STUDENT_OUTCOMES.get(subj, 70.0))

            stats = self._coverage_stats(all_standards)
            overview[dept] = {
                "subjects": subjects,
                "avg_coverage_pct": stats["coverage_pct"],
                "avg_teaching_quality": round(
                    sum(teaching_scores) / len(teaching_scores), 1
                ) if teaching_scores else 0.0,
                "avg_student_outcomes": round(
                    sum(outcome_scores) / len(outcome_scores), 1
                ) if outcome_scores else 0.0,
                "standards_summary": stats,
            }
        return overview

    def generate_coverage_report(self, framework: str = "ofsted") -> dict[str, Any]:
        """Generate a detailed curriculum coverage report."""
        all_standards = self._filter(framework=framework if framework != "ofsted" else None)
        overall = self._coverage_stats(all_standards)

        subject_breakdowns: dict[str, Any] = {}
        for subj in sorted({s["subject"] for s in all_standards}):
            subj_standards = self._filter(
                subject=subj,
                framework=framework if framework != "ofsted" else None,
            )
            subject_breakdowns[subj] = {
                "health": self.get_subject_health(subj),
                "coverage": self._coverage_stats(subj_standards),
                "gaps": [
                    {"code": s["code"], "description": s["description"],
                     "status": s["status"]}
                    for s in subj_standards
                    if s["status"] != "covered"
                ],
            }

        return {
            "framework": framework,
            "generated_at": "2026-03-09T08:34:00Z",
            "overall_coverage": overall,
            "subject_breakdowns": subject_breakdowns,
            "department_overview": self.get_department_overview(),
        }

    def get_voice_summary(self, query_type: str = "overview") -> str:
        """Return a voice-friendly curriculum summary for Alexa."""
        query_type = query_type.lower().strip()

        if query_type == "gaps":
            gaps = self.identify_gaps()
            gap_subjects = list({g.subject for g in gaps})
            count = len(gaps)
            subjects_str = ", ".join(gap_subjects[:3])
            return (
                f"Curriculum gap analysis shows {count} standards not fully covered. "
                f"Key subjects with gaps include {subjects_str}. "
                "Please review the inspection dashboard for details."
            )

        if query_type in ("subjects", "coverage"):
            summary = self.get_coverage_summary()
            low_coverage = [
                f"{subj} at {data['coverage_pct']}%"
                for subj, data in summary.items()
                if data["coverage_pct"] < 75
            ]
            if low_coverage:
                return (
                    "Curriculum coverage summary: "
                    + "; ".join(low_coverage[:3])
                    + " need attention. "
                    "Overall curriculum health is satisfactory. "
                    "Review the dashboard for full details."
                )
            return (
                "Curriculum coverage is strong across all subjects. "
                "Most subjects are above 75% coverage. "
                "Continue monitoring for any emerging gaps."
            )

        # Default overview
        all_stats = self._coverage_stats(self._standards)
        return (
            f"Curriculum overview: {all_stats['total_standards']} standards tracked. "
            f"{all_stats['covered']} fully covered, "
            f"{all_stats['partially_covered']} partially covered, "
            f"{all_stats['not_covered']} not yet covered. "
            f"Overall coverage is {all_stats['coverage_pct']}%."
        )
