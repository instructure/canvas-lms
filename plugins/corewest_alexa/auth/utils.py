"""Password hashing utilities using bcrypt."""

import re

from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Hash a plain-text password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain-text password against a bcrypt hash."""
    return pwd_context.verify(plain_password, hashed_password)


def validate_password_strength(password: str) -> bool:
    """
    Validate password strength.

    Requirements:
    - Minimum 8 characters
    - At least one digit
    """
    if len(password) < 8:
        return False
    if not re.search(r"\d", password):
        return False
    return True
