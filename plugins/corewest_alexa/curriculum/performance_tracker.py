"""
Academic performance tracker — tracks teacher and student performance data,
cohort analyses, and progress metrics for both British and American frameworks.

Python 3.11+ compatible.
"""

from __future__ import annotations

from typing import Any

# ---------------------------------------------------------------------------
# Mock Data
# ---------------------------------------------------------------------------

# 30+ teachers with observation grades
_TEACHERS: list[dict[str, Any]] = [
    {"id": "T001", "name": "Ms A. Robinson", "subject": "Mathematics",
     "ofsted_grade": 2, "danielson_avg": 3.1, "cpd_hours": 18, "observations": 3},
    {"id": "T002", "name": "Mr B. Clarke", "subject": "Mathematics",
     "ofsted_grade": 3, "danielson_avg": 2.4, "cpd_hours": 10, "observations": 2},
    {"id": "T003", "name": "Ms C. Patel", "subject": "English",
     "ofsted_grade": 1, "danielson_avg": 3.8, "cpd_hours": 24, "observations": 4},
    {"id": "T004", "name": "Mr D. Okafor", "subject": "English",
     "ofsted_grade": 2, "danielson_avg": 3.2, "cpd_hours": 16, "observations": 3},
    {"id": "T005", "name": "Dr E. Nguyen", "subject": "Science",
     "ofsted_grade": 2, "danielson_avg": 3.0, "cpd_hours": 20, "observations": 3},
    {"id": "T006", "name": "Ms F. Ahmed", "subject": "Science",
     "ofsted_grade": 3, "danielson_avg": 2.5, "cpd_hours": 8, "observations": 2},
    {"id": "T007", "name": "Mr G. Turner", "subject": "History",
     "ofsted_grade": 1, "danielson_avg": 3.7, "cpd_hours": 22, "observations": 4},
    {"id": "T008", "name": "Ms H. Brown", "subject": "Geography",
     "ofsted_grade": 2, "danielson_avg": 3.0, "cpd_hours": 15, "observations": 3},
    {"id": "T009", "name": "Mr I. Williams", "subject": "Modern Foreign Languages",
     "ofsted_grade": 3, "danielson_avg": 2.3, "cpd_hours": 9, "observations": 2},
    {"id": "T010", "name": "Ms J. Santos", "subject": "Modern Foreign Languages",
     "ofsted_grade": 2, "danielson_avg": 2.9, "cpd_hours": 14, "observations": 3},
    {"id": "T011", "name": "Mr K. Adeyemi", "subject": "Art",
     "ofsted_grade": 1, "danielson_avg": 3.9, "cpd_hours": 26, "observations": 3},
    {"id": "T012", "name": "Ms L. Fischer", "subject": "Music",
     "ofsted_grade": 1, "danielson_avg": 3.8, "cpd_hours": 28, "observations": 3},
    {"id": "T013", "name": "Mr M. Jones", "subject": "PE",
     "ofsted_grade": 2, "danielson_avg": 3.1, "cpd_hours": 17, "observations": 3},
    {"id": "T014", "name": "Ms N. Kim", "subject": "PE",
     "ofsted_grade": 2, "danielson_avg": 3.0, "cpd_hours": 12, "observations": 2},
    {"id": "T015", "name": "Mr O. Mensah", "subject": "Computing",
     "ofsted_grade": 2, "danielson_avg": 2.8, "cpd_hours": 20, "observations": 3},
    {"id": "T016", "name": "Ms P. Davies", "subject": "Computing",
     "ofsted_grade": 3, "danielson_avg": 2.2, "cpd_hours": 7, "observations": 2},
    {"id": "T017", "name": "Mr Q. Hassan", "subject": "PSHE",
     "ofsted_grade": 2, "danielson_avg": 3.0, "cpd_hours": 16, "observations": 3},
    {"id": "T018", "name": "Ms R. Johnson", "subject": "Mathematics",
     "ofsted_grade": 2, "danielson_avg": 2.9, "cpd_hours": 14, "observations": 3},
    {"id": "T019", "name": "Mr S. Malik", "subject": "English",
     "ofsted_grade": 3, "danielson_avg": 2.6, "cpd_hours": 11, "observations": 2},
    {"id": "T020", "name": "Ms T. O'Brien", "subject": "Science",
     "ofsted_grade": 2, "danielson_avg": 3.1, "cpd_hours": 18, "observations": 3},
    {"id": "T021", "name": "Mr U. Petrov", "subject": "History",
     "ofsted_grade": 2, "danielson_avg": 2.9, "cpd_hours": 13, "observations": 2},
    {"id": "T022", "name": "Ms V. Rashid", "subject": "Geography",
     "ofsted_grade": 1, "danielson_avg": 3.6, "cpd_hours": 24, "observations": 4},
    {"id": "T023", "name": "Mr W. Schmidt", "subject": "Modern Foreign Languages",
     "ofsted_grade": 2, "danielson_avg": 3.0, "cpd_hours": 16, "observations": 3},
    {"id": "T024", "name": "Ms X. Thompson", "subject": "Art",
     "ofsted_grade": 2, "danielson_avg": 3.2, "cpd_hours": 20, "observations": 3},
    {"id": "T025", "name": "Mr Y. Eze", "subject": "Music",
     "ofsted_grade": 2, "danielson_avg": 3.0, "cpd_hours": 18, "observations": 3},
    {"id": "T026", "name": "Ms Z. Chen", "subject": "Computing",
     "ofsted_grade": 2, "danielson_avg": 3.3, "cpd_hours": 22, "observations": 3},
    {"id": "T027", "name": "Mr A. Osei", "subject": "PSHE",
     "ofsted_grade": 2, "danielson_avg": 2.8, "cpd_hours": 14, "observations": 2},
    {"id": "T028", "name": "Ms B. Yamamoto", "subject": "Science",
     "ofsted_grade": 2, "danielson_avg": 3.2, "cpd_hours": 19, "observations": 3},
    {"id": "T029", "name": "Mr C. Diallo", "subject": "Mathematics",
     "ofsted_grade": 1, "danielson_avg": 3.7, "cpd_hours": 25, "observations": 4},
    {"id": "T030", "name": "Ms D. Kowalski", "subject": "English",
     "ofsted_grade": 2, "danielson_avg": 3.1, "cpd_hours": 17, "observations": 3},
]

# Year group cohort performance data
_COHORT_DATA: list[dict[str, Any]] = [
    {
        "year_group": "Year 7",
        "grade_level": "Grade 6",
        "student_count": 180,
        "avg_attendance": 94.2,
        "avg_gpa": 3.1,
        "progress_8_score": 0.15,
        "attainment_8_score": 48.5,
        "subjects": {
            "Mathematics": {"pass_rate": 78, "avg_grade": "B-"},
            "English": {"pass_rate": 82, "avg_grade": "B"},
            "Science": {"pass_rate": 75, "avg_grade": "C+"},
        },
        "at_risk_count": 18,
    },
    {
        "year_group": "Year 8",
        "grade_level": "Grade 7",
        "student_count": 175,
        "avg_attendance": 93.8,
        "avg_gpa": 3.0,
        "progress_8_score": 0.08,
        "attainment_8_score": 47.2,
        "subjects": {
            "Mathematics": {"pass_rate": 74, "avg_grade": "C+"},
            "English": {"pass_rate": 80, "avg_grade": "B-"},
            "Science": {"pass_rate": 72, "avg_grade": "C+"},
        },
        "at_risk_count": 22,
    },
    {
        "year_group": "Year 9",
        "grade_level": "Grade 8",
        "student_count": 172,
        "avg_attendance": 92.5,
        "avg_gpa": 2.9,
        "progress_8_score": -0.05,
        "attainment_8_score": 46.8,
        "subjects": {
            "Mathematics": {"pass_rate": 70, "avg_grade": "C+"},
            "English": {"pass_rate": 77, "avg_grade": "B-"},
            "Science": {"pass_rate": 68, "avg_grade": "C"},
        },
        "at_risk_count": 28,
    },
    {
        "year_group": "Year 10",
        "grade_level": "Grade 9",
        "student_count": 168,
        "avg_attendance": 91.8,
        "avg_gpa": 2.8,
        "progress_8_score": -0.10,
        "attainment_8_score": 45.5,
        "subjects": {
            "Mathematics": {"pass_rate": 68, "avg_grade": "C"},
            "English": {"pass_rate": 75, "avg_grade": "C+"},
            "Science": {"pass_rate": 70, "avg_grade": "C"},
        },
        "at_risk_count": 31,
    },
    {
        "year_group": "Year 11",
        "grade_level": "Grade 10",
        "student_count": 165,
        "avg_attendance": 91.2,
        "avg_gpa": 2.7,
        "progress_8_score": -0.12,
        "attainment_8_score": 44.8,
        "subjects": {
            "Mathematics": {"pass_rate": 65, "avg_grade": "C"},
            "English": {"pass_rate": 72, "avg_grade": "C+"},
            "Science": {"pass_rate": 67, "avg_grade": "C"},
        },
        "at_risk_count": 35,
    },
    {
        "year_group": "Year 12",
        "grade_level": "Grade 11",
        "student_count": 98,
        "avg_attendance": 93.5,
        "avg_gpa": 3.2,
        "progress_8_score": 0.20,
        "attainment_8_score": 52.0,
        "subjects": {
            "Mathematics": {"pass_rate": 80, "avg_grade": "B"},
            "English": {"pass_rate": 85, "avg_grade": "B"},
            "Science": {"pass_rate": 78, "avg_grade": "B-"},
        },
        "at_risk_count": 8,
    },
    {
        "year_group": "Year 13",
        "grade_level": "Grade 12",
        "student_count": 92,
        "avg_attendance": 94.1,
        "avg_gpa": 3.3,
        "progress_8_score": 0.25,
        "attainment_8_score": 54.5,
        "subjects": {
            "Mathematics": {"pass_rate": 82, "avg_grade": "B"},
            "English": {"pass_rate": 86, "avg_grade": "B+"},
            "Science": {"pass_rate": 80, "avg_grade": "B"},
        },
        "at_risk_count": 7,
    },
]

# At-risk students (anonymised)
_AT_RISK_STUDENTS: list[dict[str, Any]] = [
    {"student_id": "S001", "name": "Student A", "year_group": "Year 11",
     "risk_level": "high", "risk_factors": ["attendance <85%", "failing Mathematics", "failing English"],
     "attendance_rate": 81.2, "gpa": 1.5, "progress_8_score": -0.8},
    {"student_id": "S002", "name": "Student B", "year_group": "Year 10",
     "risk_level": "high", "risk_factors": ["attendance <85%", "3 subjects below pass"],
     "attendance_rate": 83.5, "gpa": 1.7, "progress_8_score": -0.7},
    {"student_id": "S003", "name": "Student C", "year_group": "Year 9",
     "risk_level": "high", "risk_factors": ["behaviour incidents", "declining grades"],
     "attendance_rate": 88.0, "gpa": 1.9, "progress_8_score": -0.6},
    {"student_id": "S004", "name": "Student D", "year_group": "Year 11",
     "risk_level": "high", "risk_factors": ["SEND", "attendance <85%"],
     "attendance_rate": 80.1, "gpa": 1.4, "progress_8_score": -0.9},
    {"student_id": "S005", "name": "Student E", "year_group": "Year 10",
     "risk_level": "medium", "risk_factors": ["attendance 85-90%", "Mathematics below average"],
     "attendance_rate": 87.3, "gpa": 2.1, "progress_8_score": -0.3},
    {"student_id": "S006", "name": "Student F", "year_group": "Year 8",
     "risk_level": "medium", "risk_factors": ["EAL support needed", "literacy gaps"],
     "attendance_rate": 90.2, "gpa": 2.2, "progress_8_score": -0.2},
    {"student_id": "S007", "name": "Student G", "year_group": "Year 9",
     "risk_level": "medium", "risk_factors": ["pupil premium", "inconsistent attendance"],
     "attendance_rate": 88.5, "gpa": 2.0, "progress_8_score": -0.4},
    {"student_id": "S008", "name": "Student H", "year_group": "Year 11",
     "risk_level": "high", "risk_factors": ["looked after child", "attendance <85%"],
     "attendance_rate": 79.8, "gpa": 1.6, "progress_8_score": -1.0},
    {"student_id": "S009", "name": "Student I", "year_group": "Year 7",
     "risk_level": "medium", "risk_factors": ["recently joined", "language barrier"],
     "attendance_rate": 89.0, "gpa": 2.3, "progress_8_score": -0.1},
    {"student_id": "S010", "name": "Student J", "year_group": "Year 10",
     "risk_level": "high", "risk_factors": ["mental health", "attendance <85%"],
     "attendance_rate": 84.2, "gpa": 1.8, "progress_8_score": -0.5},
    {"student_id": "S011", "name": "Student K", "year_group": "Year 8",
     "risk_level": "medium", "risk_factors": ["numeracy difficulties", "behaviour concerns"],
     "attendance_rate": 90.5, "gpa": 2.0, "progress_8_score": -0.3},
    {"student_id": "S012", "name": "Student L", "year_group": "Year 9",
     "risk_level": "medium", "risk_factors": ["attendance 85-90%", "predicted to underachieve"],
     "attendance_rate": 86.3, "gpa": 2.1, "progress_8_score": -0.2},
    {"student_id": "S013", "name": "Student M", "year_group": "Year 11",
     "risk_level": "high", "risk_factors": ["exam anxiety", "attendance <85%", "pupil premium"],
     "attendance_rate": 82.1, "gpa": 1.9, "progress_8_score": -0.6},
    {"student_id": "S014", "name": "Student N", "year_group": "Year 10",
     "risk_level": "medium", "risk_factors": ["literacy gaps", "EAL"],
     "attendance_rate": 91.0, "gpa": 2.4, "progress_8_score": -0.2},
    {"student_id": "S015", "name": "Student O", "year_group": "Year 7",
     "risk_level": "low", "risk_factors": ["new to school", "settling in period"],
     "attendance_rate": 92.0, "gpa": 2.6, "progress_8_score": 0.0},
    {"student_id": "S016", "name": "Student P", "year_group": "Year 12",
     "risk_level": "medium", "risk_factors": ["A-Level difficulty spike", "attendance concerns"],
     "attendance_rate": 88.0, "gpa": 2.5, "progress_8_score": -0.1},
    {"student_id": "S017", "name": "Student Q", "year_group": "Year 8",
     "risk_level": "high", "risk_factors": ["SEND", "behaviour", "attendance <85%"],
     "attendance_rate": 83.0, "gpa": 1.5, "progress_8_score": -0.8},
    {"student_id": "S018", "name": "Student R", "year_group": "Year 9",
     "risk_level": "medium", "risk_factors": ["social difficulties", "peer relationship issues"],
     "attendance_rate": 90.0, "gpa": 2.2, "progress_8_score": -0.3},
]

# Subject pass rates (all year groups combined)
_SUBJECT_PASS_RATES: dict[str, dict[str, Any]] = {
    "Mathematics": {
        "overall_pass_rate": 68.0,
        "grade_distribution": {"A*-A": 8, "B": 18, "C": 28, "D": 24, "E/F/G": 22},
        "national_comparison": -3.5,
    },
    "English": {
        "overall_pass_rate": 74.0,
        "grade_distribution": {"A*-A": 12, "B": 22, "C": 30, "D": 20, "E/F/G": 16},
        "national_comparison": 1.2,
    },
    "Science": {
        "overall_pass_rate": 70.0,
        "grade_distribution": {"A*-A": 10, "B": 20, "C": 30, "D": 22, "E/F/G": 18},
        "national_comparison": -1.5,
    },
    "History": {
        "overall_pass_rate": 78.0,
        "grade_distribution": {"A*-A": 15, "B": 28, "C": 27, "D": 18, "E/F/G": 12},
        "national_comparison": 2.8,
    },
    "Geography": {
        "overall_pass_rate": 73.0,
        "grade_distribution": {"A*-A": 11, "B": 22, "C": 28, "D": 22, "E/F/G": 17},
        "national_comparison": 0.5,
    },
    "Modern Foreign Languages": {
        "overall_pass_rate": 65.0,
        "grade_distribution": {"A*-A": 8, "B": 17, "C": 27, "D": 26, "E/F/G": 22},
        "national_comparison": -4.2,
    },
    "Art": {
        "overall_pass_rate": 85.0,
        "grade_distribution": {"A*-A": 22, "B": 30, "C": 28, "D": 14, "E/F/G": 6},
        "national_comparison": 5.0,
    },
    "Music": {
        "overall_pass_rate": 88.0,
        "grade_distribution": {"A*-A": 25, "B": 32, "C": 24, "D": 12, "E/F/G": 7},
        "national_comparison": 6.2,
    },
    "PE": {
        "overall_pass_rate": 92.0,
        "grade_distribution": {"A*-A": 30, "B": 35, "C": 24, "D": 9, "E/F/G": 2},
        "national_comparison": 7.5,
    },
    "Computing": {
        "overall_pass_rate": 67.0,
        "grade_distribution": {"A*-A": 9, "B": 16, "C": 29, "D": 24, "E/F/G": 22},
        "national_comparison": -5.0,
    },
    "PSHE": {
        "overall_pass_rate": 81.0,
        "grade_distribution": {"A*-A": 18, "B": 28, "C": 26, "D": 18, "E/F/G": 10},
        "national_comparison": 3.0,
    },
}


# ---------------------------------------------------------------------------
# PerformanceTracker
# ---------------------------------------------------------------------------


class PerformanceTracker:
    """Tracks and analyses academic performance data."""

    def __init__(self) -> None:
        self._teachers: list[dict[str, Any]] = _TEACHERS
        self._cohorts: list[dict[str, Any]] = _COHORT_DATA
        self._at_risk: list[dict[str, Any]] = _AT_RISK_STUDENTS
        self._subject_data: dict[str, dict[str, Any]] = _SUBJECT_PASS_RATES

    # ------------------------------------------------------------------
    # School-wide summary
    # ------------------------------------------------------------------

    def get_school_summary(self) -> dict[str, Any]:
        """Return school-wide performance summary."""
        total_students = sum(c["student_count"] for c in self._cohorts)
        avg_attendance = round(
            sum(c["avg_attendance"] * c["student_count"] for c in self._cohorts)
            / total_students,
            1,
        )
        avg_gpa = round(
            sum(c["avg_gpa"] * c["student_count"] for c in self._cohorts) / total_students,
            2,
        )
        avg_p8 = round(
            sum(c["progress_8_score"] * c["student_count"] for c in self._cohorts)
            / total_students,
            2,
        )
        high_risk = sum(1 for s in self._at_risk if s["risk_level"] == "high")
        medium_risk = sum(1 for s in self._at_risk if s["risk_level"] == "medium")
        low_risk = sum(1 for s in self._at_risk if s["risk_level"] == "low")

        return {
            "total_students": total_students,
            "total_teachers": len(self._teachers),
            "avg_attendance_pct": avg_attendance,
            "avg_gpa": avg_gpa,
            "avg_progress_8": avg_p8,
            "at_risk_summary": {
                "total": len(self._at_risk),
                "high": high_risk,
                "medium": medium_risk,
                "low": low_risk,
            },
            "outstanding_teachers": sum(
                1 for t in self._teachers if t["ofsted_grade"] == 1
            ),
            "requiring_improvement_teachers": sum(
                1 for t in self._teachers if t["ofsted_grade"] == 3
            ),
        }

    # ------------------------------------------------------------------
    # Subject performance
    # ------------------------------------------------------------------

    def get_subject_performance(self, subject: str | None = None) -> dict[str, Any]:
        """Return performance data per subject."""
        if subject:
            data = self._subject_data.get(subject)
            if data is None:
                return {}
            return {subject: data}
        return dict(self._subject_data)

    # ------------------------------------------------------------------
    # Teacher performance
    # ------------------------------------------------------------------

    def get_teacher_performance(
        self, teacher_id: str | None = None
    ) -> list[dict[str, Any]] | dict[str, Any]:
        """Return teaching quality metrics."""
        if teacher_id:
            teacher = next(
                (t for t in self._teachers if t["id"] == teacher_id), None
            )
            if teacher is None:
                return {}
            return self._enrich_teacher(teacher)

        return [self._enrich_teacher(t) for t in self._teachers]

    def _enrich_teacher(self, teacher: dict[str, Any]) -> dict[str, Any]:
        """Add derived fields to a teacher record."""
        grade_labels = {1: "Outstanding", 2: "Good", 3: "Requires Improvement", 4: "Inadequate"}
        return {
            **teacher,
            "ofsted_grade_label": grade_labels.get(teacher["ofsted_grade"], "Unknown"),
            "danielson_level": self._danielson_level(teacher["danielson_avg"]),
            "cpd_status": "on_track" if teacher["cpd_hours"] >= 15 else "behind",
        }

    @staticmethod
    def _danielson_level(score: float) -> str:
        if score >= 3.5:
            return "Distinguished"
        if score >= 2.5:
            return "Proficient"
        if score >= 1.5:
            return "Basic"
        return "Unsatisfactory"

    # ------------------------------------------------------------------
    # Student risk
    # ------------------------------------------------------------------

    def get_student_risk_analysis(self) -> dict[str, Any]:
        """Identify at-risk students and summarise by risk factor."""
        risk_factor_counts: dict[str, int] = {}
        for student in self._at_risk:
            for factor in student.get("risk_factors", []):
                risk_factor_counts[factor] = risk_factor_counts.get(factor, 0) + 1

        top_factors = sorted(
            risk_factor_counts.items(), key=lambda x: x[1], reverse=True
        )[:5]

        return {
            "at_risk_students": self._at_risk,
            "total_at_risk": len(self._at_risk),
            "by_risk_level": {
                "high": [s for s in self._at_risk if s["risk_level"] == "high"],
                "medium": [s for s in self._at_risk if s["risk_level"] == "medium"],
                "low": [s for s in self._at_risk if s["risk_level"] == "low"],
            },
            "by_year_group": self._group_by(self._at_risk, "year_group"),
            "top_risk_factors": [
                {"factor": f, "count": c} for f, c in top_factors
            ],
        }

    @staticmethod
    def _group_by(items: list[dict[str, Any]], key: str) -> dict[str, int]:
        groups: dict[str, int] = {}
        for item in items:
            groups[item.get(key, "Unknown")] = groups.get(item.get(key, "Unknown"), 0) + 1
        return groups

    # ------------------------------------------------------------------
    # Cohort analysis
    # ------------------------------------------------------------------

    def get_cohort_analysis(
        self,
        year_group: str | None = None,
        grade_level: str | None = None,
    ) -> list[dict[str, Any]] | dict[str, Any]:
        """Return cohort-level analysis."""
        if year_group:
            cohort = next(
                (c for c in self._cohorts if c["year_group"] == year_group), None
            )
            return cohort or {}
        if grade_level:
            cohort = next(
                (c for c in self._cohorts if c["grade_level"] == grade_level), None
            )
            return cohort or {}
        return self._cohorts

    # ------------------------------------------------------------------
    # Progress metrics
    # ------------------------------------------------------------------

    def get_progress_metrics(self, framework: str = "british") -> dict[str, Any]:
        """Return progress metrics in the requested framework."""
        if framework.lower() == "american":
            return {
                "framework": "American",
                "metrics": [
                    {
                        "year_group": c["year_group"],
                        "grade_level": c["grade_level"],
                        "avg_gpa": c["avg_gpa"],
                        "growth_percentile": self._p8_to_growth_percentile(
                            c["progress_8_score"]
                        ),
                        "value_added": round(c["progress_8_score"] * 10, 1),
                    }
                    for c in self._cohorts
                ],
                "national_benchmarks": {
                    "avg_gpa": 3.0,
                    "avg_growth_percentile": 50,
                },
            }

        # British (default)
        return {
            "framework": "British",
            "metrics": [
                {
                    "year_group": c["year_group"],
                    "progress_8_score": c["progress_8_score"],
                    "attainment_8_score": c["attainment_8_score"],
                    "progress_8_grade": self._p8_grade(c["progress_8_score"]),
                }
                for c in self._cohorts
            ],
            "national_benchmarks": {
                "avg_progress_8": 0.0,
                "avg_attainment_8": 46.3,
            },
        }

    @staticmethod
    def _p8_grade(score: float) -> str:
        if score >= 0.5:
            return "Well above average"
        if score >= 0.25:
            return "Above average"
        if score >= -0.25:
            return "Average"
        if score >= -0.5:
            return "Below average"
        return "Well below average"

    @staticmethod
    def _p8_to_growth_percentile(p8_score: float) -> int:
        """Approximate conversion of Progress 8 to growth percentile."""
        # P8 of 0.0 ≈ 50th percentile; each 0.1 ≈ ~5 percentile points
        return max(1, min(99, int(50 + p8_score * 50)))

    # ------------------------------------------------------------------
    # Standards comparison
    # ------------------------------------------------------------------

    def compare_standards(self) -> dict[str, Any]:
        """Compare performance against British AND American benchmarks."""
        school_summary = self.get_school_summary()
        return {
            "british_benchmarks": {
                "progress_8_national_avg": 0.0,
                "school_progress_8": school_summary["avg_progress_8"],
                "progress_8_vs_national": round(school_summary["avg_progress_8"] - 0.0, 2),
                "attainment_8_national_avg": 46.3,
                "school_attainment_8": round(
                    sum(c["attainment_8_score"] for c in self._cohorts) / len(self._cohorts),
                    1,
                ),
                "attendance_national_avg": 94.0,
                "school_attendance": school_summary["avg_attendance_pct"],
            },
            "american_benchmarks": {
                "gpa_national_avg": 3.0,
                "school_gpa": school_summary["avg_gpa"],
                "gpa_vs_national": round(school_summary["avg_gpa"] - 3.0, 2),
                "growth_percentile_target": 50,
                "school_growth_percentile": self._p8_to_growth_percentile(
                    school_summary["avg_progress_8"]
                ),
            },
            "subject_comparison": {
                subj: {
                    "school_pass_rate": data["overall_pass_rate"],
                    "vs_national": data["national_comparison"],
                    "status": (
                        "above_national"
                        if data["national_comparison"] >= 0
                        else "below_national"
                    ),
                }
                for subj, data in self._subject_data.items()
            },
        }

    # ------------------------------------------------------------------
    # Voice summary
    # ------------------------------------------------------------------

    def get_voice_summary(self, query_type: str = "overview") -> str:
        """Return a voice-friendly performance summary for Alexa."""
        query_type = query_type.lower().strip()

        if query_type == "at_risk":
            risk = self.get_student_risk_analysis()
            high = len(risk["by_risk_level"]["high"])
            medium = len(risk["by_risk_level"]["medium"])
            return (
                f"Student risk analysis: {high} students are high risk, "
                f"{medium} are medium risk. "
                "Key factors include attendance below 85% and underachievement in core subjects. "
                "Immediate intervention is recommended for high risk students."
            )

        if query_type == "teachers":
            outstanding = sum(1 for t in self._teachers if t["ofsted_grade"] == 1)
            improving = sum(1 for t in self._teachers if t["ofsted_grade"] == 3)
            total = len(self._teachers)
            return (
                f"Teacher performance summary: {outstanding} of {total} teachers rated Outstanding. "
                f"{improving} require improvement. "
                "CPD programmes are in place. Review the dashboard for individual details."
            )

        # Default
        summary = self.get_school_summary()
        return (
            f"Performance overview: {summary['total_students']} students enrolled. "
            f"Average attendance is {summary['avg_attendance_pct']}%. "
            f"Progress 8 score is {summary['avg_progress_8']}, which is "
            f"{'above' if summary['avg_progress_8'] >= 0 else 'below'} national average. "
            f"{summary['at_risk_summary']['high']} students are high risk. "
            "Review the inspection dashboard for full details."
        )
