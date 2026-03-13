# Core West College — Alexa Plugin

A self-contained FastAPI plugin for the Core West College AI LMS.  
Provides voice-enabled briefings via Amazon Alexa and a comprehensive **Curriculum Monitoring & Inspection Readiness** module.

---

## Quick Start

```bash
cd plugins/corewest_alexa
pip install -r requirements.txt
uvicorn main:app --reload --port 8080
```

Open `http://localhost:8080/inspection-dashboard` in your browser to view the dashboard.

---

## Directory Structure

```
plugins/corewest_alexa/
├── main.py                          # FastAPI app entry-point
├── requirements.txt                 # Python dependencies
├── README.md                        # This file
├── auth/                            # JWT authentication module
│   ├── __init__.py
│   ├── dependencies.py              # FastAPI auth dependencies
│   ├── jwt_handler.py               # JWT creation / verification
│   ├── models.py, schemas.py, etc.
│   └── login_page.html              # Standalone login UI
└── curriculum/                      # Curriculum monitoring module
    ├── __init__.py
    ├── models.py                    # Pydantic data models
    ├── standards_framework.py       # Ofsted / Cognia / Common Core / Danielson
    ├── curriculum_monitor.py        # Coverage monitoring & gap analysis
    ├── inspection_readiness.py      # Inspection scoring & checklists
    ├── performance_tracker.py       # Academic performance analytics
    ├── routes.py                    # FastAPI endpoints
    ├── templates/
    │   └── inspection_dashboard.html  # Self-contained visual dashboard
    └── tests/
        ├── __init__.py
        ├── test_standards.py         # Standards framework tests
        └── test_inspection.py        # Inspection & monitoring tests
```

---

## Curriculum Monitoring & Inspection Readiness

### Overview

The curriculum module tracks educational standards coverage and prepares the college for external inspections. It supports both **British (Ofsted)** and **American (Cognia/Common Core)** frameworks, enabling international benchmarking and dual-system reporting.

### Supported Standards Frameworks

| Framework | Country | Type |
|---|---|---|
| **Ofsted Education Inspection Framework (EIF)** | 🇬🇧 UK | Inspection |
| **National Curriculum (England)** — EYFS, KS1–KS5 | 🇬🇧 UK | Curriculum |
| **Cognia / AdvancED Accreditation Standards** | 🇺🇸 USA | Accreditation |
| **Common Core State Standards (CCSS)** — ELA & Math | 🇺🇸 USA | Curriculum |
| **Danielson Framework for Teaching** — 4 Domains | 🇺🇸 USA | Teacher Evaluation |

### British ↔ American Grade Mapping

| Ofsted Grade | Ofsted Label | Cognia Equivalent |
|---|---|---|
| 1 | Outstanding | Exemplary |
| 2 | Good | Proficient |
| 3 | Requires Improvement | Developing |
| 4 | Inadequate | Not Met |

---

## API Endpoints

Curriculum and inspection endpoints require a valid JWT (Bearer token) when the auth module is installed; if the auth module is not available, these routes are exposed as public endpoints.

### Authentication

| Method | Path | Description |
|---|---|---|
| `POST` | `/auth/login` | Obtain JWT access token |
| `POST` | `/auth/refresh` | Refresh JWT token |
| `GET` | `/login` | Login page (HTML) |

### Curriculum Standards

| Method | Path | Description |
|---|---|---|
| `GET` | `/curriculum/standards` | List all standards frameworks |
| `GET` | `/curriculum/standards/{framework}` | Get specific framework details |
| `GET` | `/curriculum/standards/compare` | Compare British vs American standards |

### Curriculum Coverage

| Method | Path | Description |
|---|---|---|
| `GET` | `/curriculum/coverage` | Overall curriculum coverage |
| `GET` | `/curriculum/coverage/{subject}` | Coverage for specific subject |
| `GET` | `/curriculum/gaps` | Gap analysis (all subjects) |
| `GET` | `/curriculum/gaps/{subject}` | Gaps for specific subject |

### Academic Performance

| Method | Path | Description |
|---|---|---|
| `GET` | `/curriculum/performance` | School-wide performance summary |
| `GET` | `/curriculum/performance/subjects` | Performance per subject |
| `GET` | `/curriculum/performance/teachers` | Performance per teacher |
| `GET` | `/curriculum/performance/students/at-risk` | At-risk students |
| `GET` | `/curriculum/performance/cohorts` | Cohort analysis |
| `GET` | `/curriculum/performance/compare` | British vs American metrics comparison |

### Inspection Readiness

| Method | Path | Description |
|---|---|---|
| `GET` | `/inspection/readiness` | Overall readiness score & breakdown |
| `GET` | `/inspection/readiness/{framework}` | Readiness for specific framework |
| `GET` | `/inspection/checklist` | Full inspection checklist |
| `GET` | `/inspection/checklist/{framework}` | Framework-specific checklist |
| `GET` | `/inspection/priorities` | Priority actions list |
| `GET` | `/inspection/evidence` | Evidence tracker |
| `GET` | `/inspection/evidence/{criteria_id}` | Evidence for specific criterion |
| `POST` | `/inspection/evidence` | Upload/register evidence |
| `GET` | `/inspection/self-evaluation` | Self-Evaluation Form (SEF) summary |
| `GET` | `/inspection/report` | Full inspection readiness report |
| `GET` | `/inspection/trend` | Readiness score trend data |

### Voice / Alexa

| Method | Path | Description |
|---|---|---|
| `GET` | `/curriculum/voice/{query_type}` | Voice-optimised curriculum summaries |
| `GET` | `/inspection/voice` | Voice-optimised inspection readiness |
| `GET` | `/alexa/query?type={type}` | General voice query |
| `POST` | `/alexa/webhook` | Alexa skill webhook (requires API key) |

---

## Inspection Preparation Workflow

1. **Self-Assessment** — Run `GET /inspection/self-evaluation` to generate a draft SEF document
2. **Gap Analysis** — Run `GET /inspection/priorities` to identify the top actions required
3. **Evidence Gathering** — Upload evidence via `POST /inspection/evidence` against each criterion
4. **Track Progress** — Monitor the readiness score via `GET /inspection/readiness` and `GET /inspection/trend`
5. **Dashboard Review** — Open `/inspection-dashboard` for a visual overview

---

## Dashboard

Open `http://localhost:8080/inspection-dashboard` to access the visual inspection readiness dashboard.

Features:
- **Overall Readiness Gauge** — animated circular gauge showing current readiness %
- **Framework Tabs** — toggle between Ofsted and Cognia views
- **Judgment Area Cards** — colour-coded (green=Outstanding, blue=Good, amber=Requires Improvement, red=Inadequate)
- **Curriculum Coverage Chart** — bar chart showing coverage % per subject
- **Priority Actions Panel** — numbered list of top actions
- **Evidence Status Tracker** — visual badges (complete / partial / missing)
- **Performance Snapshot** — key metrics at a glance
- **90-Day Readiness Trend** — sparkline chart
- **Standards Comparison** — British vs American side-by-side table

The dashboard is **fully self-contained** (single HTML file, no build tools required).  
It uses `fetch()` to load live data from the API endpoints.

---

## Voice Query Examples (Alexa)

The following intents are supported in the Alexa skill webhook:

```
"Alexa, ask Core West for the inspection readiness brief"
→ Intent: InspectionReadinessIntent

"Alexa, ask Core West about curriculum coverage"
→ Intent: CurriculumCoverageIntent

"Alexa, ask Core West for subject performance"
→ Intent: SubjectPerformanceIntent

"Alexa, ask Core West about curriculum gaps"
→ Intent: CurriculumGapsIntent

"Alexa, ask Core West for the student risk summary"
→ Intent: StudentRiskIntent

"Alexa, ask Core West for today's brief"
→ Intent: TodayBriefIntent
```

---

## Architecture

```
Amazon Alexa
     │
     ▼
POST /alexa/webhook ──► intent_map ──► CurriculumMonitor.get_voice_summary()
                                  └──► InspectionReadinessEngine.get_voice_summary()

Browser
     │
     ▼
GET /inspection-dashboard ──► templates/inspection_dashboard.html
          │                          │
          │                          ▼
          │                  fetch('/inspection/readiness')
          │                  fetch('/curriculum/coverage')
          │                  fetch('/curriculum/performance')
          │                  fetch('/inspection/priorities')
          │                  fetch('/inspection/evidence')
          │                  fetch('/inspection/trend')

Canvas LMS / Admin
     │
     ▼
GET /curriculum/* ──► CurriculumMonitor ──► Mock Data (→ Canvas DB in production)
GET /inspection/* ──► InspectionReadinessEngine ──► Mock Data
GET /curriculum/performance/* ──► PerformanceTracker ──► Mock Data
```

In production, replace the mock data in `curriculum_monitor.py`, `inspection_readiness.py`, and `performance_tracker.py` with real database queries via the Canvas LMS API (see `canvas_client.py`).

---

## Running Tests

```bash
cd plugins/corewest_alexa
pip install -r requirements.txt
pytest curriculum/tests/ -v
```

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `JWT_SECRET_KEY` | `change-me-in-production` | JWT signing key |
| `JWT_ALGORITHM` | `HS256` | JWT algorithm |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | `30` | Access token lifetime |
| `CORS_ORIGINS` | `*` | Comma-separated CORS origins |

> ⚠️ Always set `JWT_SECRET_KEY` to a strong secret in production.
