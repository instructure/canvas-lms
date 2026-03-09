"""
Tests for inspection readiness, curriculum monitoring, and performance tracking.

Covers:
- InspectionReadinessEngine
- CurriculumMonitor
- PerformanceTracker
"""

import pytest

from curriculum.curriculum_monitor import CurriculumMonitor
from curriculum.inspection_readiness import InspectionReadinessEngine
from curriculum.models import InspectionCriteria, InspectionEvidence
from curriculum.performance_tracker import PerformanceTracker


# ---------------------------------------------------------------------------
# InspectionReadinessEngine
# ---------------------------------------------------------------------------


class TestInspectionReadiness:

    @pytest.fixture
    def engine(self):
        return InspectionReadinessEngine()

    def test_overall_readiness_returns_dict(self, engine):
        result = engine.calculate_overall_readiness("ofsted")
        assert isinstance(result, dict)

    def test_overall_score_between_0_and_100(self, engine):
        result = engine.calculate_overall_readiness("ofsted")
        assert 0.0 <= result["overall_score"] <= 100.0

    def test_cognia_score_between_0_and_100(self, engine):
        result = engine.calculate_overall_readiness("cognia")
        assert 0.0 <= result["overall_score"] <= 100.0

    def test_overall_score_is_realistic(self, engine):
        """Score should be between 50 and 90 for realistic mock data."""
        result = engine.calculate_overall_readiness("ofsted")
        assert 50 <= result["overall_score"] <= 90, (
            f"Score {result['overall_score']} outside realistic range"
        )

    def test_overall_grade_is_string(self, engine):
        result = engine.calculate_overall_readiness("ofsted")
        assert isinstance(result["overall_grade"], str)
        assert len(result["overall_grade"]) > 0

    def test_areas_dict_present(self, engine):
        result = engine.calculate_overall_readiness("ofsted")
        assert "areas" in result
        assert isinstance(result["areas"], dict)

    def test_ofsted_areas_present(self, engine):
        result = engine.calculate_overall_readiness("ofsted")
        areas = result["areas"]
        assert len(areas) > 0
        for area_key, area_data in areas.items():
            assert "score" in area_data
            assert "grade" in area_data
            assert 0.0 <= area_data["score"] <= 100.0

    def test_safeguarding_flag_present(self, engine):
        result = engine.calculate_overall_readiness("ofsted")
        assert "safeguarding_effective" in result
        assert isinstance(result["safeguarding_effective"], bool)

    def test_ready_for_inspection_flag_present(self, engine):
        result = engine.calculate_overall_readiness("ofsted")
        assert "ready_for_inspection" in result

    def test_generated_at_present(self, engine):
        result = engine.calculate_overall_readiness("ofsted")
        assert "generated_at" in result

    # Checklist generation

    def test_ofsted_checklist_returns_list(self, engine):
        checklist = engine.get_checklist("ofsted")
        assert isinstance(checklist, list)
        assert len(checklist) > 0

    def test_cognia_checklist_returns_list(self, engine):
        checklist = engine.get_checklist("cognia")
        assert isinstance(checklist, list)
        assert len(checklist) > 0

    def test_checklist_items_are_inspection_criteria(self, engine):
        checklist = engine.get_checklist("ofsted")
        for item in checklist:
            assert isinstance(item, InspectionCriteria)

    def test_checklist_items_have_required_fields(self, engine):
        checklist = engine.get_checklist("ofsted")
        for item in checklist:
            assert item.id
            assert item.framework in ("ofsted", "cognia")
            assert item.criterion
            assert item.status in ("ready", "in_progress", "needs_attention", "critical")
            assert item.priority in ("high", "medium", "low")

    # Priority actions

    def test_priority_actions_returns_list(self, engine):
        actions = engine.get_priority_actions("ofsted")
        assert isinstance(actions, list)

    def test_priority_actions_sorted_by_urgency(self, engine):
        actions = engine.get_priority_actions("ofsted")
        priority_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
        for i in range(len(actions) - 1):
            curr_priority = priority_order.get(actions[i]["priority"], 99)
            next_priority = priority_order.get(actions[i+1]["priority"], 99)
            assert curr_priority <= next_priority, (
                f"Actions not sorted: {actions[i]['priority']} before {actions[i+1]['priority']}"
            )

    def test_priority_actions_limit_respected(self, engine):
        actions = engine.get_priority_actions("ofsted", limit=3)
        assert len(actions) <= 3

    def test_priority_actions_have_action_field(self, engine):
        actions = engine.get_priority_actions("ofsted")
        for action in actions:
            assert "action" in action
            assert len(action["action"]) > 0

    # Evidence tracker

    def test_evidence_tracker_returns_dict(self, engine):
        tracker = engine.get_evidence_tracker()
        assert isinstance(tracker, dict)
        assert len(tracker) > 0

    def test_evidence_tracker_statuses_valid(self, engine):
        tracker = engine.get_evidence_tracker()
        valid_statuses = {"complete", "partial", "missing"}
        for cid, data in tracker.items():
            assert data["evidence_status"] in valid_statuses, (
                f"Invalid status '{data['evidence_status']}' for criterion {cid}"
            )

    def test_evidence_tracker_area_filter(self, engine):
        tracker = engine.get_evidence_tracker(area="quality_of_education")
        for cid, data in tracker.items():
            assert data.get("category") == "quality_of_education" or "category" not in data

    # Self-evaluation

    def test_self_evaluation_returns_dict(self, engine):
        sef = engine.generate_self_evaluation("ofsted")
        assert isinstance(sef, dict)

    def test_self_evaluation_has_sections(self, engine):
        sef = engine.generate_self_evaluation("ofsted")
        assert "sections" in sef
        assert len(sef["sections"]) > 0

    def test_self_evaluation_overall_grade_present(self, engine):
        sef = engine.generate_self_evaluation("ofsted")
        assert "overall_grade" in sef

    def test_self_evaluation_has_key_strengths(self, engine):
        sef = engine.generate_self_evaluation("ofsted")
        assert "key_strengths" in sef
        assert len(sef["key_strengths"]) > 0

    # Trend

    def test_readiness_trend_returns_list(self, engine):
        trend = engine.get_readiness_trend(days=90)
        assert isinstance(trend, list)
        assert len(trend) > 0

    def test_readiness_trend_scores_in_range(self, engine):
        trend = engine.get_readiness_trend(days=90)
        for point in trend:
            assert 0 <= point["score"] <= 100

    def test_readiness_trend_has_dates(self, engine):
        trend = engine.get_readiness_trend(days=90)
        for point in trend:
            assert "date" in point
            assert len(point["date"]) == 10  # YYYY-MM-DD

    # Add evidence

    def test_add_evidence_returns_inspection_evidence(self, engine):
        evidence = engine.add_evidence({
            "criteria_id": "OE-QE-001",
            "title": "Test Evidence",
            "description": "A test evidence item",
            "evidence_type": "document",
            "uploaded_by": "Test User",
            "tags": ["test"],
        })
        assert isinstance(evidence, InspectionEvidence)
        assert evidence.title == "Test Evidence"

    def test_add_evidence_increments_count(self, engine):
        tracker_before = engine.get_evidence_tracker(area="quality_of_education")
        count_before = tracker_before.get("OE-QE-001", {}).get("evidence_count", 0)
        engine.add_evidence({
            "criteria_id": "OE-QE-001",
            "title": "New Evidence",
            "description": "Test",
            "evidence_type": "data",
            "uploaded_by": "Tester",
            "tags": [],
        })
        tracker_after = engine.get_evidence_tracker(area="quality_of_education")
        count_after = tracker_after.get("OE-QE-001", {}).get("evidence_count", 0)
        assert count_after == count_before + 1

    # Voice summary

    def test_voice_summary_returns_string(self, engine):
        summary = engine.get_voice_summary()
        assert isinstance(summary, str)
        assert len(summary) > 0

    def test_voice_summary_mentions_score(self, engine):
        summary = engine.get_voice_summary()
        assert "%" in summary


# ---------------------------------------------------------------------------
# CurriculumMonitor
# ---------------------------------------------------------------------------


class TestCurriculumMonitor:

    @pytest.fixture
    def monitor(self):
        return CurriculumMonitor()

    def test_coverage_summary_returns_dict(self, monitor):
        summary = monitor.get_coverage_summary()
        assert isinstance(summary, dict)

    def test_coverage_summary_has_all_subjects(self, monitor):
        summary = monitor.get_coverage_summary()
        expected_subjects = {
            "Mathematics", "English", "Science", "History",
            "Geography", "Modern Foreign Languages",
            "Art", "Music", "PE", "Computing", "PSHE",
        }
        assert expected_subjects.issubset(summary.keys())

    def test_coverage_pct_between_0_and_100(self, monitor):
        summary = monitor.get_coverage_summary()
        for subj, data in summary.items():
            assert 0.0 <= data["coverage_pct"] <= 100.0, (
                f"Coverage pct out of range for {subj}: {data['coverage_pct']}"
            )

    def test_coverage_summary_single_subject(self, monitor):
        summary = monitor.get_coverage_summary(subject="Mathematics")
        assert "Mathematics" in summary
        assert len(summary) == 1

    def test_coverage_stats_totals_correct(self, monitor):
        summary = monitor.get_coverage_summary(subject="English")
        data = summary["English"]
        total = data["covered"] + data["partially_covered"] + data["not_covered"] + data["planned"]
        assert total == data["total_standards"]

    def test_gap_analysis_returns_list(self, monitor):
        gaps = monitor.identify_gaps()
        assert isinstance(gaps, list)

    def test_gap_analysis_excludes_covered_standards(self, monitor):
        gaps = monitor.identify_gaps()
        for gap in gaps:
            assert gap.status != "covered"

    def test_gap_analysis_subject_filter(self, monitor):
        gaps = monitor.identify_gaps(subject="Science")
        for gap in gaps:
            assert gap.subject == "Science"

    def test_gap_analysis_framework_filter(self, monitor):
        gaps = monitor.identify_gaps(framework="common_core")
        for gap in gaps:
            assert gap.framework == "common_core"

    def test_subject_health_returns_dict(self, monitor):
        health = monitor.get_subject_health("Mathematics")
        assert isinstance(health, dict)

    def test_subject_health_overall_in_range(self, monitor):
        health = monitor.get_subject_health("Mathematics")
        assert 0 <= health["overall_health"] <= 100

    def test_subject_health_has_required_keys(self, monitor):
        health = monitor.get_subject_health("English")
        required_keys = {
            "subject", "overall_health", "coverage_score",
            "teaching_quality_score", "student_outcomes_score",
        }
        assert required_keys.issubset(health.keys())

    def test_department_overview_returns_dict(self, monitor):
        overview = monitor.get_department_overview()
        assert isinstance(overview, dict)
        assert len(overview) > 0

    def test_department_overview_has_stem(self, monitor):
        overview = monitor.get_department_overview()
        assert "STEM" in overview

    def test_coverage_report_returns_dict(self, monitor):
        report = monitor.generate_coverage_report()
        assert isinstance(report, dict)

    def test_coverage_report_has_subject_breakdowns(self, monitor):
        report = monitor.generate_coverage_report()
        assert "subject_breakdowns" in report
        assert len(report["subject_breakdowns"]) > 0

    def test_voice_summary_returns_string(self, monitor):
        for query_type in ("overview", "gaps", "coverage"):
            summary = monitor.get_voice_summary(query_type)
            assert isinstance(summary, str)
            assert len(summary) > 0


# ---------------------------------------------------------------------------
# PerformanceTracker
# ---------------------------------------------------------------------------


class TestPerformanceTracker:

    @pytest.fixture
    def tracker(self):
        return PerformanceTracker()

    def test_school_summary_returns_dict(self, tracker):
        summary = tracker.get_school_summary()
        assert isinstance(summary, dict)

    def test_school_summary_has_required_fields(self, tracker):
        summary = tracker.get_school_summary()
        required = {
            "total_students", "total_teachers", "avg_attendance_pct",
            "avg_gpa", "avg_progress_8", "at_risk_summary",
        }
        assert required.issubset(summary.keys())

    def test_total_students_positive(self, tracker):
        summary = tracker.get_school_summary()
        assert summary["total_students"] > 0

    def test_total_teachers_at_least_30(self, tracker):
        summary = tracker.get_school_summary()
        assert summary["total_teachers"] >= 30

    def test_avg_attendance_in_range(self, tracker):
        summary = tracker.get_school_summary()
        assert 0 <= summary["avg_attendance_pct"] <= 100

    def test_subject_performance_returns_dict(self, tracker):
        result = tracker.get_subject_performance()
        assert isinstance(result, dict)

    def test_subject_performance_has_all_subjects(self, tracker):
        result = tracker.get_subject_performance()
        assert "Mathematics" in result
        assert "English" in result

    def test_subject_performance_single_subject(self, tracker):
        result = tracker.get_subject_performance("Mathematics")
        assert "Mathematics" in result

    def test_subject_pass_rates_in_range(self, tracker):
        result = tracker.get_subject_performance()
        for subj, data in result.items():
            assert 0 <= data["overall_pass_rate"] <= 100

    def test_teacher_performance_returns_list(self, tracker):
        result = tracker.get_teacher_performance()
        assert isinstance(result, list)
        assert len(result) >= 30

    def test_teacher_performance_has_grade_labels(self, tracker):
        teachers = tracker.get_teacher_performance()
        for t in teachers:
            assert "ofsted_grade_label" in t
            assert "danielson_level" in t

    def test_teacher_performance_single_teacher(self, tracker):
        result = tracker.get_teacher_performance(teacher_id="T001")
        assert isinstance(result, dict)
        assert result.get("id") == "T001"

    def test_student_risk_analysis_returns_dict(self, tracker):
        result = tracker.get_student_risk_analysis()
        assert isinstance(result, dict)

    def test_student_risk_has_at_risk_students(self, tracker):
        result = tracker.get_student_risk_analysis()
        assert "at_risk_students" in result
        assert len(result["at_risk_students"]) >= 15

    def test_student_risk_has_high_medium_low(self, tracker):
        result = tracker.get_student_risk_analysis()
        levels = result.get("by_risk_level", {})
        assert "high" in levels
        assert "medium" in levels
        assert "low" in levels

    def test_cohort_analysis_returns_all_cohorts(self, tracker):
        result = tracker.get_cohort_analysis()
        assert isinstance(result, list)
        assert len(result) >= 7  # Year 7-13

    def test_cohort_analysis_year_filter(self, tracker):
        result = tracker.get_cohort_analysis(year_group="Year 10")
        assert isinstance(result, dict)
        assert result.get("year_group") == "Year 10"

    def test_progress_metrics_british(self, tracker):
        result = tracker.get_progress_metrics("british")
        assert result["framework"] == "British"
        assert "metrics" in result
        for m in result["metrics"]:
            assert "progress_8_score" in m
            assert "attainment_8_score" in m

    def test_progress_metrics_american(self, tracker):
        result = tracker.get_progress_metrics("american")
        assert result["framework"] == "American"
        for m in result["metrics"]:
            assert "avg_gpa" in m
            assert "growth_percentile" in m

    def test_compare_standards_returns_dict(self, tracker):
        result = tracker.compare_standards()
        assert isinstance(result, dict)
        assert "british_benchmarks" in result
        assert "american_benchmarks" in result
        assert "subject_comparison" in result

    def test_compare_standards_has_school_vs_national(self, tracker):
        result = tracker.compare_standards()
        brit = result["british_benchmarks"]
        assert "school_progress_8" in brit
        assert "progress_8_vs_national" in brit

    def test_voice_summary_returns_string(self, tracker):
        for query_type in ("overview", "at_risk", "teachers"):
            summary = tracker.get_voice_summary(query_type)
            assert isinstance(summary, str)
            assert len(summary) > 0
