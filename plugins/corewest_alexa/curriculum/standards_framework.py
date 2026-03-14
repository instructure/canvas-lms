"""
Educational standards frameworks for curriculum monitoring and inspection readiness.

Covers:
- British Standards: Ofsted Education Inspection Framework (EIF), National Curriculum
- American Standards: Common Core State Standards (CCSS), Cognia/AdvancED,
  Danielson Framework for Teaching

Python 3.11+ compatible.
"""

from __future__ import annotations

from typing import Any

# ---------------------------------------------------------------------------
# British Standards — Ofsted Education Inspection Framework (EIF)
# ---------------------------------------------------------------------------

OFSTED_JUDGEMENT_AREAS: dict[str, Any] = {
    "quality_of_education": {
        "title": "Quality of Education",
        "descriptors": {
            1: (
                "Outstanding - Curriculum is coherently planned and sequenced. "
                "Teachers have strong subject knowledge. "
                "Pupils achieve exceptionally well."
            ),
            2: (
                "Good - Curriculum is ambitious and designed to give all pupils "
                "the knowledge and cultural capital they need. Teaching is effective."
            ),
            3: (
                "Requires Improvement - Curriculum does not meet the needs of all "
                "pupils. Teaching requires improvement in some areas."
            ),
            4: (
                "Inadequate - Curriculum is poorly planned. Teaching does not "
                "enable pupils to learn effectively."
            ),
        },
        "sub_criteria": [
            "Intent - Curriculum design and coverage",
            "Implementation - Teaching quality and assessment",
            "Impact - Student outcomes and achievement",
        ],
        "weight": 0.40,
    },
    "behaviour_and_attitudes": {
        "title": "Behaviour and Attitudes",
        "descriptors": {
            1: "Outstanding - Pupils' behaviour and attitudes are exceptional.",
            2: "Good - Pupils' attitudes to their education are positive.",
            3: "Requires Improvement - Behaviour and attitudes require improvement.",
            4: "Inadequate - Pupils' behaviour and attitudes are inadequate.",
        },
        "sub_criteria": [
            "Behaviour management",
            "Attendance and punctuality",
            "Attitudes to learning",
            "Bullying prevention",
        ],
        "weight": 0.20,
    },
    "personal_development": {
        "title": "Personal Development",
        "descriptors": {
            1: "Outstanding - The school's provision for personal development is exceptional.",
            2: "Good - The school provides well for personal development.",
            3: "Requires Improvement - Personal development provision requires improvement.",
            4: "Inadequate - Personal development provision is inadequate.",
        },
        "sub_criteria": [
            "SMSC (Spiritual, Moral, Social, Cultural) development",
            "Character education",
            "Careers education and guidance",
            "Fundamental British values",
            "Physical and mental health education",
        ],
        "weight": 0.20,
    },
    "leadership_and_management": {
        "title": "Leadership and Management",
        "descriptors": {
            1: "Outstanding - Leaders are exceptional and set ambitious vision.",
            2: "Good - Leaders have a clear and ambitious vision for the school.",
            3: "Requires Improvement - Leadership requires improvement in some areas.",
            4: "Inadequate - Leadership is ineffective.",
        },
        "sub_criteria": [
            "Vision and strategy",
            "Staff development and wellbeing",
            "Governance",
            "Safeguarding",
            "Financial management",
        ],
        "weight": 0.20,
    },
    "safeguarding": {
        "title": "Safeguarding",
        "descriptors": {
            "effective": (
                "Safeguarding arrangements are effective. "
                "The school has a strong safeguarding culture."
            ),
            "not_effective": "Safeguarding arrangements are not effective.",
        },
        "sub_criteria": [
            "DBS checks and single central record",
            "Staff training (Keeping Children Safe in Education)",
            "Referral procedures",
            "Online safety",
            "Site security",
        ],
        "weight": 0.0,  # Binary pass/fail, not averaged
    },
}

# ---------------------------------------------------------------------------
# British National Curriculum Key Stages
# ---------------------------------------------------------------------------

NATIONAL_CURRICULUM_KEY_STAGES: dict[str, Any] = {
    "EYFS": {"age_range": "3-5", "year_groups": ["Reception"]},
    "KS1": {"age_range": "5-7", "year_groups": ["Year 1", "Year 2"]},
    "KS2": {
        "age_range": "7-11",
        "year_groups": ["Year 3", "Year 4", "Year 5", "Year 6"],
    },
    "KS3": {
        "age_range": "11-14",
        "year_groups": ["Year 7", "Year 8", "Year 9"],
    },
    "KS4": {"age_range": "14-16", "year_groups": ["Year 10", "Year 11"]},
    "KS5": {"age_range": "16-18", "year_groups": ["Year 12", "Year 13"]},
}

# ---------------------------------------------------------------------------
# American Standards — Cognia / AdvancED
# ---------------------------------------------------------------------------

COGNIA_STANDARDS: dict[str, Any] = {
    "culture_of_learning": {
        "title": "Culture of Learning",
        "standard": (
            "The institution commits to a culture of learning that ensures "
            "all learners have equitable opportunities."
        ),
        "indicators": [
            "Leadership capacity",
            "Professional learning culture",
            "Learning community relationships",
        ],
    },
    "leadership_for_learning": {
        "title": "Leadership for Learning",
        "standard": (
            "The institution has leaders who are advocates for the "
            "institution's vision and improvement efforts."
        ),
        "indicators": [
            "Strategic leadership",
            "Instructional leadership",
            "Organizational leadership",
        ],
    },
    "engagement_of_learning": {
        "title": "Engagement of Learning",
        "standard": (
            "The institution provides quality learning experiences "
            "that engage learners."
        ),
        "indicators": [
            "Learner engagement",
            "Effective instruction",
            "Assessment practices",
        ],
    },
    "growth_in_learning": {
        "title": "Growth in Learning",
        "standard": (
            "The institution demonstrates evidence of growth in learning outcomes."
        ),
        "indicators": [
            "Achievement levels",
            "Growth patterns",
            "Graduation/completion rates",
        ],
    },
}

# ---------------------------------------------------------------------------
# American Standards — Common Core State Standards (CCSS)
# ---------------------------------------------------------------------------

COMMON_CORE_SUBJECTS: dict[str, Any] = {
    "ela": {
        "title": "English Language Arts",
        "strands": [
            "Reading Literature",
            "Reading Informational Text",
            "Writing",
            "Speaking and Listening",
            "Language",
        ],
        "grade_levels": ["K", "1", "2", "3", "4", "5", "6", "7", "8", "9-10", "11-12"],
    },
    "math": {
        "title": "Mathematics",
        "strands": [
            "Operations & Algebraic Thinking",
            "Number & Operations",
            "Measurement & Data",
            "Geometry",
            "Ratios & Proportions",
            "Statistics & Probability",
        ],
        "grade_levels": ["K", "1", "2", "3", "4", "5", "6", "7", "8", "High School"],
    },
}

# ---------------------------------------------------------------------------
# American Standards — Danielson Framework for Teaching
# ---------------------------------------------------------------------------

DANIELSON_FRAMEWORK: dict[str, Any] = {
    "domain_1": {
        "title": "Planning and Preparation",
        "components": [
            "1a: Demonstrating Knowledge of Content and Pedagogy",
            "1b: Demonstrating Knowledge of Students",
            "1c: Setting Instructional Outcomes",
            "1d: Demonstrating Knowledge of Resources",
            "1e: Designing Coherent Instruction",
            "1f: Designing Student Assessments",
        ],
        "levels": ["Unsatisfactory", "Basic", "Proficient", "Distinguished"],
    },
    "domain_2": {
        "title": "The Classroom Environment",
        "components": [
            "2a: Creating an Environment of Respect and Rapport",
            "2b: Establishing a Culture for Learning",
            "2c: Managing Classroom Procedures",
            "2d: Managing Student Behavior",
            "2e: Organizing Physical Space",
        ],
        "levels": ["Unsatisfactory", "Basic", "Proficient", "Distinguished"],
    },
    "domain_3": {
        "title": "Instruction",
        "components": [
            "3a: Communicating with Students",
            "3b: Using Questioning and Discussion Techniques",
            "3c: Engaging Students in Learning",
            "3d: Using Assessment in Instruction",
            "3e: Demonstrating Flexibility and Responsiveness",
        ],
        "levels": ["Unsatisfactory", "Basic", "Proficient", "Distinguished"],
    },
    "domain_4": {
        "title": "Professional Responsibilities",
        "components": [
            "4a: Reflecting on Teaching",
            "4b: Maintaining Accurate Records",
            "4c: Communicating with Families",
            "4d: Participating in a Professional Community",
            "4e: Growing and Developing Professionally",
            "4f: Showing Professionalism",
        ],
        "levels": ["Unsatisfactory", "Basic", "Proficient", "Distinguished"],
    },
}

# ---------------------------------------------------------------------------
# Grade mappings between British and American systems
# ---------------------------------------------------------------------------

# Ofsted grade (int 1-4) → Cognia equivalent label
_OFSTED_TO_COGNIA: dict[int, str] = {
    1: "Exemplary",
    2: "Proficient",
    3: "Developing",
    4: "Not Met",
}

# Cognia label → closest Ofsted grade
_COGNIA_TO_OFSTED: dict[str, int] = {
    "Exemplary": 1,
    "Proficient": 2,
    "Developing": 3,
    "Not Met": 4,
}

# ---------------------------------------------------------------------------
# Curriculum standards by subject (sample data for each subject/framework)
# ---------------------------------------------------------------------------

_SUBJECT_STANDARDS: dict[str, list[dict[str, str]]] = {
    "Mathematics": [
        {
            "code": "NC.KS3.MA.1",
            "description": "Work with integers and rational numbers",
            "framework": "national_curriculum",
            "strand": "Number",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS3.MA.2",
            "description": "Use algebraic notation and expressions",
            "framework": "national_curriculum",
            "strand": "Algebra",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS3.MA.3",
            "description": "Apply geometric reasoning to shapes",
            "framework": "national_curriculum",
            "strand": "Geometry",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS4.MA.1",
            "description": "Solve quadratic equations",
            "framework": "national_curriculum",
            "strand": "Algebra",
            "grade_level": "KS4",
        },
        {
            "code": "NC.KS4.MA.2",
            "description": "Calculate probability of combined events",
            "framework": "national_curriculum",
            "strand": "Statistics & Probability",
            "grade_level": "KS4",
        },
        {
            "code": "CCSS.MATH.7.RP.1",
            "description": "Compute unit rates associated with ratios of fractions",
            "framework": "common_core",
            "strand": "Ratios & Proportions",
            "grade_level": "Grade 7",
        },
        {
            "code": "CCSS.MATH.8.EE.1",
            "description": "Know and apply properties of integer exponents",
            "framework": "common_core",
            "strand": "Number & Operations",
            "grade_level": "Grade 8",
        },
        {
            "code": "CCSS.MATH.HS.A.1",
            "description": "Interpret the structure of algebraic expressions",
            "framework": "common_core",
            "strand": "Algebra",
            "grade_level": "High School",
        },
    ],
    "English": [
        {
            "code": "NC.KS3.EN.1",
            "description": "Read and understand complex literary texts",
            "framework": "national_curriculum",
            "strand": "Reading Literature",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS3.EN.2",
            "description": "Write clearly and coherently for different purposes",
            "framework": "national_curriculum",
            "strand": "Writing",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS4.EN.1",
            "description": "Analyse language, form, and structure of literary texts",
            "framework": "national_curriculum",
            "strand": "Reading Literature",
            "grade_level": "KS4",
        },
        {
            "code": "CCSS.ELA.7.RL.1",
            "description": "Cite several pieces of textual evidence to support analysis",
            "framework": "common_core",
            "strand": "Reading Literature",
            "grade_level": "Grade 7",
        },
        {
            "code": "CCSS.ELA.8.W.1",
            "description": "Write arguments to support claims with clear reasons",
            "framework": "common_core",
            "strand": "Writing",
            "grade_level": "Grade 8",
        },
    ],
    "Science": [
        {
            "code": "NC.KS3.SC.1",
            "description": "Understand cell structure and function in living organisms",
            "framework": "national_curriculum",
            "strand": "Biology",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS3.SC.2",
            "description": "Understand forces and motion",
            "framework": "national_curriculum",
            "strand": "Physics",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS4.SC.1",
            "description": "Understand DNA, inheritance, and genetics",
            "framework": "national_curriculum",
            "strand": "Biology",
            "grade_level": "KS4",
        },
        {
            "code": "NC.KS4.SC.2",
            "description": "Understand atomic structure and periodic table",
            "framework": "national_curriculum",
            "strand": "Chemistry",
            "grade_level": "KS4",
        },
        {
            "code": "NGSS.MS.LS1.1",
            "description": "Conduct investigations about the functioning of cells",
            "framework": "cognia",
            "strand": "Life Science",
            "grade_level": "Grade 7",
        },
    ],
    "History": [
        {
            "code": "NC.KS3.HI.1",
            "description": "Understand Medieval Britain 1066-1509",
            "framework": "national_curriculum",
            "strand": "British History",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS3.HI.2",
            "description": "Study the development of Church, state, and society 1509-1745",
            "framework": "national_curriculum",
            "strand": "British History",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS4.HI.1",
            "description": "Understand causes and consequences of World War One",
            "framework": "national_curriculum",
            "strand": "World History",
            "grade_level": "KS4",
        },
    ],
    "Geography": [
        {
            "code": "NC.KS3.GE.1",
            "description": "Understand physical geography including plate tectonics",
            "framework": "national_curriculum",
            "strand": "Physical Geography",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS4.GE.1",
            "description": "Understand urbanisation and economic development",
            "framework": "national_curriculum",
            "strand": "Human Geography",
            "grade_level": "KS4",
        },
    ],
    "Modern Foreign Languages": [
        {
            "code": "NC.KS3.ML.1",
            "description": "Communicate in the target language on familiar topics",
            "framework": "national_curriculum",
            "strand": "Speaking",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS4.ML.1",
            "description": "Understand authentic written and spoken texts",
            "framework": "national_curriculum",
            "strand": "Reading & Listening",
            "grade_level": "KS4",
        },
    ],
    "Art": [
        {
            "code": "NC.KS3.AR.1",
            "description": "Produce creative work exploring different media",
            "framework": "national_curriculum",
            "strand": "Creating",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS4.AR.1",
            "description": "Analyse and evaluate art, craft and design",
            "framework": "national_curriculum",
            "strand": "Evaluating",
            "grade_level": "KS4",
        },
    ],
    "Music": [
        {
            "code": "NC.KS3.MU.1",
            "description": "Perform, listen to, review and evaluate music",
            "framework": "national_curriculum",
            "strand": "Performing",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS3.MU.2",
            "description": "Learn to sing and use their voices in solo and ensemble",
            "framework": "national_curriculum",
            "strand": "Performing",
            "grade_level": "KS3",
        },
    ],
    "PE": [
        {
            "code": "NC.KS3.PE.1",
            "description": "Use running, jumping, throwing and catching in isolation and combination",
            "framework": "national_curriculum",
            "strand": "Physical Skills",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS4.PE.1",
            "description": "Evaluate performance and develop plans to improve",
            "framework": "national_curriculum",
            "strand": "Evaluating",
            "grade_level": "KS4",
        },
    ],
    "Computing": [
        {
            "code": "NC.KS3.CO.1",
            "description": "Design, use and evaluate computational abstractions",
            "framework": "national_curriculum",
            "strand": "Computer Science",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS4.CO.1",
            "description": "Understand and apply the fundamental principles of computer science",
            "framework": "national_curriculum",
            "strand": "Computer Science",
            "grade_level": "KS4",
        },
    ],
    "PSHE": [
        {
            "code": "NC.KS3.PS.1",
            "description": "Understand health and wellbeing including mental health",
            "framework": "national_curriculum",
            "strand": "Health & Wellbeing",
            "grade_level": "KS3",
        },
        {
            "code": "NC.KS4.PS.1",
            "description": "Understand relationships and sex education",
            "framework": "national_curriculum",
            "strand": "Relationships & RSE",
            "grade_level": "KS4",
        },
    ],
}


# ---------------------------------------------------------------------------
# Public API functions
# ---------------------------------------------------------------------------


def get_framework(framework_name: str) -> dict[str, Any]:
    """Return the full data for the requested standards framework.

    Supported names: ``ofsted``, ``cognia``, ``common_core``, ``danielson``,
    ``national_curriculum``.
    """
    mapping: dict[str, Any] = {
        "ofsted": OFSTED_JUDGEMENT_AREAS,
        "cognia": COGNIA_STANDARDS,
        "common_core": COMMON_CORE_SUBJECTS,
        "danielson": DANIELSON_FRAMEWORK,
        "national_curriculum": NATIONAL_CURRICULUM_KEY_STAGES,
    }
    key = framework_name.lower().strip()
    if key not in mapping:
        raise ValueError(
            f"Unknown framework '{framework_name}'. "
            f"Choose from: {', '.join(mapping)}"
        )
    return mapping[key]


def get_grade_descriptors(framework: str, area: str) -> dict[str, Any]:
    """Return the grade descriptors for a specific judgement area.

    Args:
        framework: ``"ofsted"`` or ``"cognia"`` (Cognia uses indicator lists).
        area: The key of the judgement area within the framework.
    """
    if framework.lower() == "ofsted":
        if area not in OFSTED_JUDGEMENT_AREAS:
            raise ValueError(f"Unknown Ofsted area: '{area}'")
        return OFSTED_JUDGEMENT_AREAS[area]["descriptors"]
    if framework.lower() == "cognia":
        if area not in COGNIA_STANDARDS:
            raise ValueError(f"Unknown Cognia standard: '{area}'")
        return {"standard": COGNIA_STANDARDS[area]["standard"]}
    raise ValueError(f"Framework '{framework}' does not have grade descriptors.")


def map_ofsted_to_cognia(ofsted_grade: int) -> str:
    """Convert an Ofsted numeric grade (1–4) to a Cognia performance label."""
    if ofsted_grade not in _OFSTED_TO_COGNIA:
        raise ValueError(f"Invalid Ofsted grade: {ofsted_grade}. Must be 1-4.")
    return _OFSTED_TO_COGNIA[ofsted_grade]


def map_cognia_to_ofsted(cognia_level: str) -> int:
    """Convert a Cognia performance label to the closest Ofsted numeric grade."""
    if cognia_level not in _COGNIA_TO_OFSTED:
        raise ValueError(
            f"Unknown Cognia level: '{cognia_level}'. "
            f"Choose from: {', '.join(_COGNIA_TO_OFSTED)}"
        )
    return _COGNIA_TO_OFSTED[cognia_level]


def get_all_frameworks() -> list[dict[str, str]]:
    """Return metadata about all available frameworks."""
    return [
        {
            "id": "ofsted",
            "name": "Ofsted Education Inspection Framework (EIF)",
            "country": "United Kingdom",
            "type": "inspection",
        },
        {
            "id": "national_curriculum",
            "name": "National Curriculum (England)",
            "country": "United Kingdom",
            "type": "curriculum",
        },
        {
            "id": "cognia",
            "name": "Cognia / AdvancED Accreditation Standards",
            "country": "United States",
            "type": "accreditation",
        },
        {
            "id": "common_core",
            "name": "Common Core State Standards (CCSS)",
            "country": "United States",
            "type": "curriculum",
        },
        {
            "id": "danielson",
            "name": "Danielson Framework for Teaching",
            "country": "United States",
            "type": "teacher_evaluation",
        },
    ]


def get_curriculum_standards(
    subject: str,
    framework: str | None = None,
    key_stage_or_grade: str | None = None,
) -> list[dict[str, str]]:
    """Return relevant curriculum standards for a subject, optionally filtered.

    Args:
        subject: Subject name, e.g. ``"Mathematics"``.
        framework: Optional framework filter, e.g. ``"common_core"``.
        key_stage_or_grade: Optional key stage or grade, e.g. ``"KS3"`` / ``"Grade 7"``.
    """
    standards = _SUBJECT_STANDARDS.get(subject, [])

    if framework:
        fw = framework.lower()
        standards = [s for s in standards if s.get("framework", "").lower() == fw]

    if key_stage_or_grade:
        ksg = key_stage_or_grade.strip()
        standards = [s for s in standards if s.get("grade_level", "") == ksg]

    return standards
