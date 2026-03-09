"""
Token blacklist (in-memory).

Tokens are added here on logout.  The set is keyed by the raw token
string; a proper production system would store just the ``jti`` claim.
"""

from threading import Lock

_lock = Lock()
_blacklisted: set[str] = set()


def blacklist_token(token: str) -> None:
    """Add *token* to the in-memory blacklist."""
    with _lock:
        _blacklisted.add(token)


def is_blacklisted(token: str) -> bool:
    """Return ``True`` if *token* has been blacklisted."""
    with _lock:
        return token in _blacklisted
