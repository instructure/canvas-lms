# Core West College AI LMS — Alexa Plugin

A FastAPI-based Alexa integration plugin for the Core West College AI LMS, with a
**self-contained security and authentication layer**.

---

## Quick Start

```bash
cd plugins/corewest_alexa

# 1. Install dependencies
pip install -r requirements.txt

# 2. Set environment variables (see below)
export JWT_SECRET_KEY="your-very-secret-key"
export ALEXA_API_KEY="your-alexa-api-key"

# 3. Create the first admin user
python -m auth.seed

# 4. Start the server
uvicorn main:app --reload
```

Open `http://localhost:8000/login` to access the login UI.

---

## Security & Authentication

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `JWT_SECRET_KEY` | `change-me-in-production` | **Required.** HS256 signing key for JWT tokens |
| `JWT_ALGORITHM` | `HS256` | JWT signing algorithm |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | `30` | Access token lifetime (minutes) |
| `JWT_REFRESH_TOKEN_EXPIRE_DAYS` | `7` | Refresh token lifetime (days) |
| `ALEXA_API_KEY` | *(unset)* | **Required.** API key for Alexa webhook requests |
| `RATE_LIMIT_MAX_ATTEMPTS` | `5` | Max login attempts per window |
| `RATE_LIMIT_WINDOW_SECONDS` | `60` | Rate-limit rolling window (seconds) |
| `CORS_ORIGINS` | `*` | Comma-separated allowed CORS origins |

> ⚠️ **Always set `JWT_SECRET_KEY` and `ALEXA_API_KEY` in production.**

---

### Creating the First Admin User

```bash
python -m auth.seed
```

Default credentials (change immediately after first login):

| Field | Value |
|---|---|
| Username | `admin` |
| Password | `CoreWest2024!` |
| Role | `admin` |

---

### Authentication Flow

```
Client                          API
  │                              │
  ├─── POST /auth/login ────────>│
  │    { username, password }    │
  │                              │── verify credentials
  │                              │── check rate limit
  │<── { access_token, ... } ───│
  │                              │
  ├─── GET /alexa/dashboard ────>│
  │    Authorization: Bearer ... │── verify JWT
  │<── { message, role } ───────│
  │                              │
  ├─── POST /alexa/webhook ─────>│
  │    X-API-Key: ...            │── verify API key
  │<── { received: true } ──────│
```

---

### Protected vs Public Endpoints

| Endpoint | Method | Auth required | Notes |
|---|---|---|---|
| `/alexa/health` | GET | ❌ None | Health check |
| `/alexa/query` | GET | ❌ None | Public query |
| `/login` | GET | ❌ None | HTML login page |
| `/auth/login` | POST | ❌ None | Returns JWT |
| `/auth/register` | POST | ✅ Admin JWT (except first user) | Register user |
| `/auth/refresh` | POST | ✅ Refresh token | Refresh access token |
| `/auth/me` | GET | ✅ Any JWT | Current user info |
| `/auth/logout` | POST | ✅ Any JWT | Blacklist token |
| `/auth/change-password` | PUT | ✅ Any JWT | Change password |
| `/alexa/dashboard` | GET | ✅ Any JWT | Dashboard (any role) |
| `/alexa/webhook` | POST | ✅ X-API-Key | Alexa webhook |

---

### User Roles

| Role | Dashboard | Webhook | Register users |
|---|---|---|---|
| `admin` | ✅ | ✅ | ✅ |
| `readonly` | ✅ | ❌ | ❌ |

---

## Directory Structure

```
plugins/corewest_alexa/
├── main.py                  # FastAPI application entry-point
├── requirements.txt         # Python dependencies
├── README.md
├── auth/
│   ├── __init__.py
│   ├── api_key.py           # X-API-Key validation for Alexa webhook
│   ├── blacklist.py         # In-memory JWT blacklist (logout)
│   ├── dependencies.py      # FastAPI route-protection dependencies
│   ├── jwt_handler.py       # JWT creation & verification (python-jose)
│   ├── login_page.html      # Standalone HTML/CSS/JS login form
│   ├── models.py            # User model with JSON file storage
│   ├── rate_limiter.py      # Brute-force protection (5 req/min/IP)
│   ├── routes.py            # /auth/* endpoints
│   ├── schemas.py           # Pydantic request/response models
│   ├── seed.py              # Create default admin user
│   └── utils.py             # bcrypt password hashing & validation
└── tests/
    └── test_auth.py         # pytest test suite
```

---

## Running Tests

```bash
cd plugins/corewest_alexa
pip install -r requirements.txt
pytest tests/ -v
```
