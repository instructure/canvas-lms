"""In-memory rate limiter for brute-force protection."""

import os
import time
from collections import defaultdict
from threading import Lock

from fastapi import HTTPException, Request, status

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

MAX_ATTEMPTS: int = int(os.environ.get("RATE_LIMIT_MAX_ATTEMPTS", "5"))
WINDOW_SECONDS: int = int(os.environ.get("RATE_LIMIT_WINDOW_SECONDS", "60"))

# ---------------------------------------------------------------------------
# State (module-level, shared across requests in the same process)
# ---------------------------------------------------------------------------

_lock = Lock()
# { ip_address: [(timestamp, ...)] }
_attempts: dict[str, list[float]] = defaultdict(list)


def _get_client_ip(request: Request) -> str:
    """Return the best-effort client IP from the request."""
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    if request.client:
        return request.client.host
    return "unknown"


def check_rate_limit(request: Request) -> None:
    """
    Raise ``HTTP 429`` if the client IP has exceeded the allowed login
    attempts within the rolling time window.

    Call this at the start of the login endpoint.
    """
    ip = _get_client_ip(request)
    now = time.monotonic()
    cutoff = now - WINDOW_SECONDS

    with _lock:
        # Prune old timestamps
        _attempts[ip] = [t for t in _attempts[ip] if t > cutoff]

        if len(_attempts[ip]) >= MAX_ATTEMPTS:
            oldest = _attempts[ip][0]
            retry_after = int(WINDOW_SECONDS - (now - oldest)) + 1
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=(
                    f"Too many login attempts. "
                    f"Please wait {retry_after} seconds."
                ),
                headers={"Retry-After": str(retry_after)},
            )

        _attempts[ip].append(now)


def record_failed_attempt(request: Request) -> None:
    """
    Explicitly record a failed login attempt for the client IP.

    ``check_rate_limit`` already records one attempt per call; use this
    only if you need to record an additional penalty attempt.
    """
    ip = _get_client_ip(request)
    now = time.monotonic()
    with _lock:
        _attempts[ip].append(now)


def reset_attempts(request: Request) -> None:
    """Clear all recorded attempts for the client IP (e.g. on success)."""
    ip = _get_client_ip(request)
    with _lock:
        _attempts.pop(ip, None)
