"""User model with JSON file-based storage."""

import json
import tempfile
import uuid
from datetime import datetime, timezone
from pathlib import Path
from threading import Lock
from typing import Optional

from .utils import hash_password, verify_password

# Path to the JSON user store (relative to this file)
_USERS_FILE = Path(__file__).parent / "users.json"

# Protects all read/write access to _USERS_FILE within this process
_store_lock = Lock()


def _load_users() -> list[dict]:
    """Load users from the JSON store (must be called under _store_lock)."""
    if not _USERS_FILE.exists():
        return []
    try:
        with _USERS_FILE.open("r", encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError as exc:
        raise RuntimeError(
            f"User store '{_USERS_FILE}' is corrupted: {exc}"
        ) from exc


def _save_users(users: list[dict]) -> None:
    """Atomically persist users to the JSON store (must be called under _store_lock)."""
    parent = _USERS_FILE.parent
    parent.mkdir(parents=True, exist_ok=True)
    # Write to a temp file in the same directory then rename for atomicity
    with tempfile.NamedTemporaryFile(
        "w",
        dir=parent,
        delete=False,
        encoding="utf-8",
        suffix=".tmp",
    ) as tmp:
        json.dump(users, tmp, indent=2, default=str)
        tmp_path = Path(tmp.name)
    tmp_path.replace(_USERS_FILE)


class User:
    """Represents an authenticated user."""

    ROLE_ADMIN = "admin"
    ROLE_READONLY = "readonly"
    VALID_ROLES = {ROLE_ADMIN, ROLE_READONLY}

    def __init__(
        self,
        id: str,
        username: str,
        email: str,
        hashed_password: str,
        role: str = ROLE_READONLY,
        is_active: bool = True,
        created_at: Optional[str] = None,
        last_login: Optional[str] = None,
    ) -> None:
        self.id = id
        self.username = username
        self.email = email
        self.hashed_password = hashed_password
        self.role = role
        self.is_active = is_active
        self.created_at = created_at or datetime.now(timezone.utc).isoformat()
        self.last_login = last_login

    # ------------------------------------------------------------------
    # Password helpers
    # ------------------------------------------------------------------

    def verify_password(self, plain_password: str) -> bool:
        """Return True if *plain_password* matches the stored hash."""
        return verify_password(plain_password, self.hashed_password)

    def set_password(self, plain_password: str) -> None:
        """Hash and store a new password."""
        self.hashed_password = hash_password(plain_password)

    # ------------------------------------------------------------------
    # Serialisation
    # ------------------------------------------------------------------

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email,
            "hashed_password": self.hashed_password,
            "role": self.role,
            "is_active": self.is_active,
            "created_at": self.created_at,
            "last_login": self.last_login,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "User":
        return cls(
            id=data["id"],
            username=data["username"],
            email=data["email"],
            hashed_password=data["hashed_password"],
            role=data.get("role", cls.ROLE_READONLY),
            is_active=data.get("is_active", True),
            created_at=data.get("created_at"),
            last_login=data.get("last_login"),
        )

    # ------------------------------------------------------------------
    # Data-access layer
    # ------------------------------------------------------------------

    @classmethod
    def get_all(cls) -> list["User"]:
        with _store_lock:
            return [cls.from_dict(d) for d in _load_users()]

    @classmethod
    def get_by_id(cls, user_id: str) -> Optional["User"]:
        with _store_lock:
            for d in _load_users():
                if d["id"] == user_id:
                    return cls.from_dict(d)
        return None

    @classmethod
    def get_by_username(cls, username: str) -> Optional["User"]:
        with _store_lock:
            for d in _load_users():
                if d["username"].lower() == username.lower():
                    return cls.from_dict(d)
        return None

    @classmethod
    def get_by_email(cls, email: str) -> Optional["User"]:
        with _store_lock:
            for d in _load_users():
                if d["email"].lower() == email.lower():
                    return cls.from_dict(d)
        return None

    def save(self) -> None:
        """Insert or update this user in the JSON store."""
        with _store_lock:
            users = _load_users()
            for i, d in enumerate(users):
                if d["id"] == self.id:
                    users[i] = self.to_dict()
                    _save_users(users)
                    return
            # New user
            users.append(self.to_dict())
            _save_users(users)

    def delete(self) -> None:
        """Remove this user from the JSON store."""
        with _store_lock:
            users = [d for d in _load_users() if d["id"] != self.id]
            _save_users(users)

    def touch_last_login(self) -> None:
        """Update last_login timestamp and persist."""
        self.last_login = datetime.now(timezone.utc).isoformat()
        self.save()

    # ------------------------------------------------------------------
    # Factory
    # ------------------------------------------------------------------

    @classmethod
    def create(
        cls,
        username: str,
        email: str,
        plain_password: str,
        role: str = ROLE_READONLY,
    ) -> "User":
        """Create, persist and return a new User."""
        user = cls(
            id=str(uuid.uuid4()),
            username=username,
            email=email,
            hashed_password=hash_password(plain_password),
            role=role,
        )
        user.save()
        return user

    @classmethod
    def create_locked(
        cls,
        username: str,
        email: str,
        plain_password: str,
        role: str = ROLE_READONLY,
    ) -> "User":
        """
        Create, persist and return a new User **while already holding
        _store_lock**.  Use this inside ``with _store_lock`` blocks to
        avoid a double-acquire deadlock.
        """
        user = cls(
            id=str(uuid.uuid4()),
            username=username,
            email=email,
            hashed_password=hash_password(plain_password),
            role=role,
        )
        users = _load_users()
        users.append(user.to_dict())
        _save_users(users)
        return user
