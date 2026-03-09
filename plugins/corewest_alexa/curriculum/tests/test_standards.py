"""
Tests for the educational standards framework module.

Covers Ofsted EIF, Cognia, Common Core, Danielson Framework,
National Curriculum key stages, and grade mapping utilities.
"""

import pytest

from curriculum.standards_framework import (
    COGNIA_STANDARDS,
    COMMON_CORE_SUBJECTS,
    DANIELSON_FRAMEWORK,
    NATIONAL_CURRICULUM_KEY_STAGES,
    OFSTED_JUDGEMENT_AREAS,
    get_all_frameworks,
    get_curriculum_standards,
    get_framework,
    get_grade_descriptors,
    map_cognia_to_ofsted,
    map_ofsted_to_cognia,
)


# ---------------------------------------------------------------------------
# Ofsted EIF
# ---------------------------------------------------------------------------


class TestOfstedFramework:
    def test_judgement_areas_exist(self):
        assert OFSTED_JUDGEMENT_AREAS, "Ofsted judgment areas should not be empty"

    def test_required_judgment_areas(self):
        required = {
            "quality_of_education",
            "behaviour_and_attitudes",
            "personal_development",
            "leadership_and_management",
            "safeguarding",
        }
        assert required.issubset(OFSTED_JUDGEMENT_AREAS.keys())

    def test_quality_of_education_descriptors(self):
        area = OFSTED_JUDGEMENT_AREAS["quality_of_education"]
        assert "descriptors" in area
        descriptors = area["descriptors"]
        # Grades 1-4 must all be present
        for grade in (1, 2, 3, 4):
            assert grade in descriptors
            assert len(descriptors[grade]) > 0

    def test_safeguarding_binary_descriptors(self):
        area = OFSTED_JUDGEMENT_AREAS["safeguarding"]
        descriptors = area["descriptors"]
        assert "effective" in descriptors
        assert "not_effective" in descriptors

    def test_all_areas_have_sub_criteria(self):
        for area_name, area in OFSTED_JUDGEMENT_AREAS.items():
            assert "sub_criteria" in area, f"{area_name} missing sub_criteria"
            assert len(area["sub_criteria"]) > 0

    def test_all_areas_have_title(self):
        for area_name, area in OFSTED_JUDGEMENT_AREAS.items():
            assert "title" in area, f"{area_name} missing title"


# ---------------------------------------------------------------------------
# National Curriculum Key Stages
# ---------------------------------------------------------------------------


class TestNationalCurriculum:
    def test_all_key_stages_present(self):
        expected = {"EYFS", "KS1", "KS2", "KS3", "KS4", "KS5"}
        assert expected.issubset(NATIONAL_CURRICULUM_KEY_STAGES.keys())

    def test_key_stage_structure(self):
        for ks_name, ks in NATIONAL_CURRICULUM_KEY_STAGES.items():
            assert "age_range" in ks, f"{ks_name} missing age_range"
            assert "year_groups" in ks, f"{ks_name} missing year_groups"
            assert len(ks["year_groups"]) > 0

    def test_ks3_year_groups(self):
        ks3 = NATIONAL_CURRICULUM_KEY_STAGES["KS3"]
        assert "Year 7" in ks3["year_groups"]
        assert "Year 8" in ks3["year_groups"]
        assert "Year 9" in ks3["year_groups"]

    def test_ks4_age_range(self):
        ks4 = NATIONAL_CURRICULUM_KEY_STAGES["KS4"]
        assert ks4["age_range"] == "14-16"


# ---------------------------------------------------------------------------
# Cognia Standards
# ---------------------------------------------------------------------------


class TestCogniaStandards:
    def test_cognia_standards_not_empty(self):
        assert COGNIA_STANDARDS, "Cognia standards should not be empty"

    def test_required_cognia_domains(self):
        required = {
            "culture_of_learning",
            "leadership_for_learning",
            "engagement_of_learning",
            "growth_in_learning",
        }
        assert required.issubset(COGNIA_STANDARDS.keys())

    def test_each_domain_has_title_standard_indicators(self):
        for domain_name, domain in COGNIA_STANDARDS.items():
            assert "title" in domain, f"{domain_name} missing title"
            assert "standard" in domain, f"{domain_name} missing standard"
            assert "indicators" in domain, f"{domain_name} missing indicators"
            assert len(domain["indicators"]) > 0


# ---------------------------------------------------------------------------
# Common Core State Standards
# ---------------------------------------------------------------------------


class TestCommonCore:
    def test_ela_and_math_present(self):
        assert "ela" in COMMON_CORE_SUBJECTS
        assert "math" in COMMON_CORE_SUBJECTS

    def test_ela_strands(self):
        ela = COMMON_CORE_SUBJECTS["ela"]
        assert "Reading Literature" in ela["strands"]
        assert "Writing" in ela["strands"]

    def test_math_strands(self):
        math = COMMON_CORE_SUBJECTS["math"]
        assert "Algebra" in " ".join(math["strands"]) or any("Algebra" in s for s in math["strands"])

    def test_grade_levels_present(self):
        for subject, data in COMMON_CORE_SUBJECTS.items():
            assert "grade_levels" in data
            assert len(data["grade_levels"]) > 0


# ---------------------------------------------------------------------------
# Danielson Framework
# ---------------------------------------------------------------------------


class TestDanisonFramework:
    def test_four_domains_present(self):
        for domain in ("domain_1", "domain_2", "domain_3", "domain_4"):
            assert domain in DANIELSON_FRAMEWORK, f"{domain} missing from Danielson framework"

    def test_each_domain_has_components(self):
        for domain_name, domain in DANIELSON_FRAMEWORK.items():
            assert "components" in domain, f"{domain_name} missing components"
            assert len(domain["components"]) > 0

    def test_levels_include_four_ratings(self):
        for domain_name, domain in DANIELSON_FRAMEWORK.items():
            levels = domain.get("levels", [])
            assert "Unsatisfactory" in levels
            assert "Distinguished" in levels

    def test_domain_1_title(self):
        assert "Planning" in DANIELSON_FRAMEWORK["domain_1"]["title"]

    def test_domain_3_is_instruction(self):
        assert "Instruction" in DANIELSON_FRAMEWORK["domain_3"]["title"]


# ---------------------------------------------------------------------------
# Grade mapping functions
# ---------------------------------------------------------------------------


class TestGradeMappings:
    def test_ofsted_1_maps_to_exemplary(self):
        assert map_ofsted_to_cognia(1) == "Exemplary"

    def test_ofsted_2_maps_to_proficient(self):
        assert map_ofsted_to_cognia(2) == "Proficient"

    def test_ofsted_3_maps_to_developing(self):
        assert map_ofsted_to_cognia(3) == "Developing"

    def test_ofsted_4_maps_to_not_met(self):
        assert map_ofsted_to_cognia(4) == "Not Met"

    def test_cognia_exemplary_maps_to_1(self):
        assert map_cognia_to_ofsted("Exemplary") == 1

    def test_cognia_proficient_maps_to_2(self):
        assert map_cognia_to_ofsted("Proficient") == 2

    def test_cognia_developing_maps_to_3(self):
        assert map_cognia_to_ofsted("Developing") == 3

    def test_cognia_not_met_maps_to_4(self):
        assert map_cognia_to_ofsted("Not Met") == 4

    def test_invalid_ofsted_grade_raises(self):
        with pytest.raises(ValueError):
            map_ofsted_to_cognia(5)

    def test_invalid_cognia_level_raises(self):
        with pytest.raises(ValueError):
            map_cognia_to_ofsted("Unknown Level")

    def test_round_trip_ofsted_to_cognia_to_ofsted(self):
        for grade in (1, 2, 3, 4):
            cognia = map_ofsted_to_cognia(grade)
            ofsted = map_cognia_to_ofsted(cognia)
            assert ofsted == grade, f"Round-trip failed for grade {grade}"


# ---------------------------------------------------------------------------
# get_framework()
# ---------------------------------------------------------------------------


class TestGetFramework:
    def test_get_ofsted(self):
        fw = get_framework("ofsted")
        assert fw is OFSTED_JUDGEMENT_AREAS

    def test_get_cognia(self):
        fw = get_framework("cognia")
        assert fw is COGNIA_STANDARDS

    def test_get_common_core(self):
        fw = get_framework("common_core")
        assert fw is COMMON_CORE_SUBJECTS

    def test_get_danielson(self):
        fw = get_framework("danielson")
        assert fw is DANIELSON_FRAMEWORK

    def test_get_national_curriculum(self):
        fw = get_framework("national_curriculum")
        assert fw is NATIONAL_CURRICULUM_KEY_STAGES

    def test_unknown_framework_raises(self):
        with pytest.raises(ValueError):
            get_framework("invalid_framework")


# ---------------------------------------------------------------------------
# get_grade_descriptors()
# ---------------------------------------------------------------------------


class TestGetGradeDescriptors:
    def test_ofsted_quality_of_education_descriptors(self):
        desc = get_grade_descriptors("ofsted", "quality_of_education")
        assert 1 in desc
        assert 4 in desc

    def test_cognia_culture_of_learning_descriptor(self):
        desc = get_grade_descriptors("cognia", "culture_of_learning")
        assert "standard" in desc

    def test_invalid_ofsted_area_raises(self):
        with pytest.raises(ValueError):
            get_grade_descriptors("ofsted", "nonexistent_area")

    def test_unsupported_framework_raises(self):
        with pytest.raises(ValueError):
            get_grade_descriptors("danielson", "domain_1")


# ---------------------------------------------------------------------------
# get_all_frameworks()
# ---------------------------------------------------------------------------


class TestGetAllFrameworks:
    def test_returns_list(self):
        frameworks = get_all_frameworks()
        assert isinstance(frameworks, list)
        assert len(frameworks) >= 5

    def test_each_entry_has_required_keys(self):
        for fw in get_all_frameworks():
            assert "id" in fw
            assert "name" in fw
            assert "country" in fw
            assert "type" in fw

    def test_includes_ofsted_and_cognia(self):
        ids = {fw["id"] for fw in get_all_frameworks()}
        assert "ofsted" in ids
        assert "cognia" in ids


# ---------------------------------------------------------------------------
# get_curriculum_standards()
# ---------------------------------------------------------------------------


class TestGetCurriculumStandards:
    def test_returns_list(self):
        standards = get_curriculum_standards("Mathematics")
        assert isinstance(standards, list)

    def test_mathematics_has_standards(self):
        standards = get_curriculum_standards("Mathematics")
        assert len(standards) > 0

    def test_filter_by_framework(self):
        nc_standards = get_curriculum_standards("Mathematics", framework="national_curriculum")
        for s in nc_standards:
            assert s["framework"] == "national_curriculum"

    def test_filter_by_grade_level(self):
        standards = get_curriculum_standards("Mathematics", key_stage_or_grade="KS3")
        for s in standards:
            assert s["grade_level"] == "KS3"

    def test_unknown_subject_returns_empty(self):
        standards = get_curriculum_standards("Underwater Basket Weaving")
        assert standards == []

    def test_combined_filter(self):
        standards = get_curriculum_standards(
            "English", framework="common_core", key_stage_or_grade="Grade 7"
        )
        for s in standards:
            assert s["framework"] == "common_core"
            assert s["grade_level"] == "Grade 7"
