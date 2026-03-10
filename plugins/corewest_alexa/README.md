# Core West Alexa Plugin

A lightweight FastAPI service that bridges the **Core West Command Center**
with **Amazon Alexa**.  It reads live data from the Canvas LMS REST API and
exposes Alexa-friendly voice summaries, a dashboard endpoint, and a webhook
handler for Alexa skill requests.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Amazon Alexa Device                        │
└────────────────────────┬─────────────────────────────────────┘
                         │  HTTPS (Alexa Skill webhook)
                         ▼
┌──────────────────────────────────────────────────────────────┐
│              Core West Alexa API  (FastAPI / Python)          │
│                                                               │
│   GET  /                  — liveness probe                    │
│   GET  /alexa/health      — health check                      │
│   GET  /alexa/query       — voice query by type               │
│   GET  /alexa/dashboard   — JSON dashboard data               │
│   POST /alexa/webhook     — Alexa skill webhook               │
│                                                               │
│   ┌─────────────────┐   ┌──────────────────────────────┐     │
│   │ data_aggregator │──▶│      canvas_client.py         │     │
│   │  (summaries)    │   │  (Canvas LMS REST API calls)  │     │
│   └─────────────────┘   └──────────────┬───────────────┘     │
└──────────────────────────────────────────────────────────────┘
                                         │  REST API
                                         ▼
                           ┌─────────────────────────┐
                           │   Canvas LMS (Rails)     │
                           │   /api/v1/…              │
                           └─────────────────────────┘
```

---

## Directory Structure

```
plugins/corewest_alexa/
├── README.md                   ← this file
├── requirements.txt            ← Python dependencies
├── main.py                     ← FastAPI application
├── canvas_client.py            ← Canvas LMS API client
├── config.py                   ← Environment-based configuration
├── data_aggregator.py          ← Voice-friendly data summaries
├── Dockerfile                  ← Container for the service
├── docker-compose.yml          ← Run alongside Canvas LMS
├── tests/
│   ├── __init__.py
│   ├── test_main.py            ← API endpoint tests
│   └── test_data_aggregator.py ← Data aggregation tests
└── alexa_skill/
    └── interaction_model.json  ← Alexa skill interaction model
```

---

## Quick Start

### 1. Install Dependencies

```bash
cd plugins/corewest_alexa
pip install -r requirements.txt
```

### 2. Configure Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CANVAS_API_URL` | `http://localhost:3000` | Base URL of the Canvas LMS instance |
| `CANVAS_API_TOKEN` | *(empty)* | Canvas API bearer token |
| `CACHE_TTL_SECONDS` | `300` | How long to cache Canvas responses |
| `DEBUG` | `false` | Enable debug logging and auto-reload |
| `HOST` | `0.0.0.0` | Bind address |
| `PORT` | `8000` | Bind port |
| `ALLOWED_ORIGINS` | `*` | Comma-separated CORS allowed origins |
| `USE_MOCK_DATA` | `true` | Use hardcoded mock data (no Canvas required) |

Copy the example and edit as needed:

```bash
cp .env.example .env   # create your own .env file
```

### 3. Run the Service

```bash
uvicorn main:app --reload
# or
python main.py
```

### 4. Run with Docker

```bash
docker compose up --build
```

---

## API Endpoints

### `GET /`
Liveness probe.

```json
{"message": "Core West Alexa API is running"}
```

### `GET /alexa/health`
Detailed health check.

```json
{"status": "ok", "canvas_api_url": "http://localhost:3000", "use_mock_data": true, "debug": false}
```

### `GET /alexa/query?type=<type>`
Returns a voice-friendly summary for the given type.

**Supported types:** `inspection`, `teachers`, `students`, `today`, `tasks`, `incidents`

```bash
curl "http://localhost:8000/alexa/query?type=today"
```

```json
{
  "speech_text": "Today, inspection readiness is 78 percent. There are 5 open tasks...",
  "card_title": "Core West Brief",
  "card_text": "...",
  "status": "success"
}
```

### `GET /alexa/dashboard`
Returns structured JSON for a command center dashboard.

```json
{
  "status": "success",
  "data": {
    "courses": {"total_active": 12},
    "teachers": {"total": 24, "priority_followup": 3, "avg_quality_score": 3.1},
    "students": {"total": 320, "high_risk": 11, "low_attendance": 18, "safeguarding_flags": 2},
    "tasks": {"open": 5},
    "incidents": {"unresolved": 2},
    "inspection": {"readiness_percent": 78}
  }
}
```

### `POST /alexa/webhook`
Handles Alexa skill requests.  Expects a standard Alexa request JSON body.

**Supported intents:**
- `TodayBriefIntent` — daily summary
- `InspectionIntent` — inspection readiness
- `TeacherSummaryIntent` — teacher metrics
- `StudentRiskIntent` — at-risk student summary
- `TasksSummaryIntent` — open tasks
- `IncidentsSummaryIntent` — unresolved incidents

---

## Example Alexa Queries

> "Alexa, ask Core West for today's brief."

> "Alexa, ask Core West for the inspection summary."

> "Alexa, ask Core West how many students are at risk."

> "Alexa, ask Core West about open tasks."

---

## Alexa Skill Setup

1. Log in to the [Alexa Developer Console](https://developer.amazon.com/alexa/console/ask).
2. Create a new custom skill with invocation name **"core west"**.
3. Import `alexa_skill/interaction_model.json` as the interaction model.
4. Set the endpoint to your deployed service URL: `https://<your-domain>/alexa/webhook`.
5. Build and test the skill.

---

## Running Tests

```bash
cd plugins/corewest_alexa
pip install -r requirements.txt
pytest tests/ -v
```

---

## Graceful Degradation

When the Canvas API is unreachable (missing token, network error, etc.) the
`canvas_client.py` falls back to static mock data so the Alexa skill
continues to respond.  Set `USE_MOCK_DATA=true` to always use mock data
during development.

---

## Integration with Canvas LMS Docker Setup

Add the following snippet to the root `docker-compose.yml` (or keep it as a
standalone service using `plugins/corewest_alexa/docker-compose.yml`):

```yaml
alexa-api:
  build:
    context: ./plugins/corewest_alexa
  ports:
    - "8000:8000"
  environment:
    - CANVAS_API_URL=http://web:3000
    - CANVAS_API_TOKEN=${CANVAS_API_TOKEN}
  depends_on:
    - web
```
