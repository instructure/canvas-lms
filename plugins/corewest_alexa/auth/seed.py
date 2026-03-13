"""
Seed script — creates the default admin user.

Run with:
    python -m auth.seed

The admin password is taken from the ``ADMIN_SEED_PASSWORD`` environment
variable.  If the variable is not set a cryptographically random password
is generated and printed once.  Store it securely — it cannot be recovered
after the script exits.
"""

import os
import secrets
import string
import sys
from pathlib import Path

# Ensure the plugin root is on the path when run directly
sys.path.insert(0, str(Path(__file__).parent.parent))

from auth.models import User  # noqa: E402
from auth.utils import validate_password_strength  # noqa: E402

DEFAULT_USERNAME = "admin"
DEFAULT_EMAIL = "admin@corewest.edu"
DEFAULT_ROLE = User.ROLE_ADMIN


def _generate_password(length: int = 16) -> str:
    """Generate a random password that satisfies the strength policy."""
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    while True:
        pwd = "".join(secrets.choice(alphabet) for _ in range(length))
        if validate_password_strength(pwd):
            return pwd


def seed() -> None:
    existing = User.get_by_username(DEFAULT_USERNAME)
    if existing:
        print(
            f"[seed] User '{DEFAULT_USERNAME}' already exists — skipping.",
            flush=True,
        )
        return

    password = os.environ.get("ADMIN_SEED_PASSWORD") or _generate_password()

    if not validate_password_strength(password):
        raise ValueError(
            "ADMIN_SEED_PASSWORD does not meet the strength requirements "
            "(min 8 characters, at least one digit)."
        )

    user = User.create(
        username=DEFAULT_USERNAME,
        email=DEFAULT_EMAIL,
        plain_password=password,
        role=DEFAULT_ROLE,
    )

    print("=" * 50)
    print("  Default admin user created")
    print("=" * 50)
    print(f"  Username : {user.username}")
    print(f"  Password : {password}")
    print(f"  Role     : {user.role}")
    print("=" * 50)
    print("  ⚠️  Change the password after first login!")
    print("=" * 50, flush=True)


if __name__ == "__main__":
    seed()
