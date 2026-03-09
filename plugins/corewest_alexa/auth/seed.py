"""
Seed script — creates the default admin user.

Run with:
    python -m auth.seed
"""

import sys
from pathlib import Path

# Ensure the plugin root is on the path when run directly
sys.path.insert(0, str(Path(__file__).parent.parent))

from auth.models import User  # noqa: E402
from auth.utils import validate_password_strength  # noqa: E402

DEFAULT_USERNAME = "admin"
DEFAULT_EMAIL = "admin@corewest.edu"
DEFAULT_PASSWORD = "CoreWest2024!"
DEFAULT_ROLE = User.ROLE_ADMIN


def seed() -> None:
    existing = User.get_by_username(DEFAULT_USERNAME)
    if existing:
        print(
            f"[seed] User '{DEFAULT_USERNAME}' already exists — skipping.",
            flush=True,
        )
        return

    if not validate_password_strength(DEFAULT_PASSWORD):
        raise ValueError(
            f"Default password '{DEFAULT_PASSWORD}' does not meet strength requirements."
        )

    user = User.create(
        username=DEFAULT_USERNAME,
        email=DEFAULT_EMAIL,
        plain_password=DEFAULT_PASSWORD,
        role=DEFAULT_ROLE,
    )

    print("=" * 50)
    print("  Default admin user created")
    print("=" * 50)
    print(f"  Username : {user.username}")
    print(f"  Password : {DEFAULT_PASSWORD}")
    print(f"  Role     : {user.role}")
    print("=" * 50)
    print("  ⚠️  Change the password after first login!")
    print("=" * 50, flush=True)


if __name__ == "__main__":
    seed()
