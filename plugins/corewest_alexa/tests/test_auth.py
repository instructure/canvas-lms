"""
Auth system tests for the corewest_alexa plugin.

Run with:
    cd plugins/corewest_alexa
    pytest tests/test_auth.py -v
"""

import os
import sys

# Ensure the plugin root is on sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

# Use a temporary users file so tests don't pollute the real store
import tempfile
import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def isolated_users_file(tmp_path, monkeypatch):
    """Point the user store at a fresh temp file for every test."""
    import auth.models as models_module

    temp_file = tmp_path / "users.json"
    monkeypatch.setattr(models_module, "_USERS_FILE", temp_file)
    yield temp_file


@pytest.fixture(autouse=True)
def reset_rate_limiter():
    """Clear rate-limiter state between tests."""
    import auth.rate_limiter as rl

    rl._attempts.clear()
    yield
    rl._attempts.clear()


@pytest.fixture(autouse=True)
def reset_blacklist():
    """Clear token blacklist between tests."""
    import auth.blacklist as bl

    bl._blacklisted.clear()
    yield
    bl._blacklisted.clear()


@pytest.fixture()
def client():
    from main import app

    return TestClient(app, raise_server_exceptions=False)


@pytest.fixture()
def admin_user():
    from auth.models import User

    return User.create(
        username="admin",
        email="admin@test.edu",
        plain_password="Admin1234!",
        role=User.ROLE_ADMIN,
    )


@pytest.fixture()
def readonly_user():
    from auth.models import User

    return User.create(
        username="reader",
        email="reader@test.edu",
        plain_password="Reader123!",
        role=User.ROLE_READONLY,
    )


def _login(client, username, password):
    return client.post(
        "/auth/login", json={"username": username, "password": password}
    )


def _auth_header(token):
    return {"Authorization": f"Bearer {token}"}


# ---------------------------------------------------------------------------
# Password hashing
# ---------------------------------------------------------------------------


class TestPasswordUtils:
    def test_hash_and_verify(self):
        from auth.utils import hash_password, verify_password

        h = hash_password("Secret99!")
        assert verify_password("Secret99!", h)
        assert not verify_password("wrong", h)

    def test_strength_pass(self):
        from auth.utils import validate_password_strength

        assert validate_password_strength("Abcdefg1")

    def test_strength_fail_too_short(self):
        from auth.utils import validate_password_strength

        assert not validate_password_strength("Ab1")

    def test_strength_fail_no_digit(self):
        from auth.utils import validate_password_strength

        assert not validate_password_strength("Abcdefgh")


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------


class TestLogin:
    def test_login_valid(self, client, admin_user):
        r = _login(client, "admin", "Admin1234!")
        assert r.status_code == 200
        data = r.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        assert data["username"] == "admin"
        assert data["role"] == "admin"

    def test_login_wrong_password(self, client, admin_user):
        r = _login(client, "admin", "wrongpassword")
        assert r.status_code == 401

    def test_login_unknown_user(self, client):
        r = _login(client, "ghost", "somepass")
        assert r.status_code == 401

    def test_login_inactive_user(self, client, admin_user):
        admin_user.is_active = False
        admin_user.save()
        r = _login(client, "admin", "Admin1234!")
        assert r.status_code == 403


# ---------------------------------------------------------------------------
# Register
# ---------------------------------------------------------------------------


class TestRegister:
    def test_first_user_becomes_admin_no_auth(self, client):
        """First registration is allowed without a token."""
        r = client.post(
            "/auth/register",
            json={
                "username": "first",
                "email": "first@test.edu",
                "password": "First1234!",
                "role": "readonly",
            },
        )
        assert r.status_code == 201
        assert r.json()["role"] == "admin"  # auto-promoted

    def test_register_requires_admin_after_first(self, client, admin_user):
        token = _login(client, "admin", "Admin1234!").json()["access_token"]
        r = client.post(
            "/auth/register",
            headers=_auth_header(token),
            json={
                "username": "newuser",
                "email": "new@test.edu",
                "password": "NewPass99!",
                "role": "readonly",
            },
        )
        assert r.status_code == 201

    def test_register_rejected_without_admin_token(self, client, admin_user):
        r = client.post(
            "/auth/register",
            json={
                "username": "hack",
                "email": "hack@test.edu",
                "password": "Hack1234!",
                "role": "admin",
            },
        )
        assert r.status_code == 401

    def test_register_weak_password(self, client):
        r = client.post(
            "/auth/register",
            json={
                "username": "weak",
                "email": "weak@test.edu",
                "password": "short",
                "role": "readonly",
            },
        )
        assert r.status_code == 422

    def test_register_duplicate_username(self, client, admin_user):
        token = _login(client, "admin", "Admin1234!").json()["access_token"]
        r = client.post(
            "/auth/register",
            headers=_auth_header(token),
            json={
                "username": "admin",
                "email": "other@test.edu",
                "password": "Other1234!",
                "role": "readonly",
            },
        )
        assert r.status_code == 409


# ---------------------------------------------------------------------------
# Protected endpoints
# ---------------------------------------------------------------------------


class TestProtectedEndpoints:
    def test_get_me_without_token(self, client, admin_user):
        r = client.get("/auth/me")
        assert r.status_code == 401

    def test_get_me_with_valid_token(self, client, admin_user):
        token = _login(client, "admin", "Admin1234!").json()["access_token"]
        r = client.get("/auth/me", headers=_auth_header(token))
        assert r.status_code == 200
        assert r.json()["username"] == "admin"

    def test_dashboard_requires_auth(self, client, admin_user):
        r = client.get("/alexa/dashboard")
        assert r.status_code == 401

    def test_dashboard_with_valid_token(self, client, admin_user):
        token = _login(client, "admin", "Admin1234!").json()["access_token"]
        r = client.get("/alexa/dashboard", headers=_auth_header(token))
        assert r.status_code == 200


# ---------------------------------------------------------------------------
# Logout / blacklist
# ---------------------------------------------------------------------------


class TestLogout:
    def test_logout_invalidates_token(self, client, admin_user):
        token = _login(client, "admin", "Admin1234!").json()["access_token"]
        client.post("/auth/logout", headers=_auth_header(token))
        from auth.blacklist import is_blacklisted

        assert is_blacklisted(token)

    def test_revoked_token_rejected_by_protected_endpoint(self, client, admin_user):
        token = _login(client, "admin", "Admin1234!").json()["access_token"]
        client.post("/auth/logout", headers=_auth_header(token))
        # The blacklisted token must now be rejected on every protected endpoint
        r = client.get("/auth/me", headers=_auth_header(token))
        assert r.status_code == 401

    def test_revoked_token_rejected_by_dashboard(self, client, admin_user):
        token = _login(client, "admin", "Admin1234!").json()["access_token"]
        client.post("/auth/logout", headers=_auth_header(token))
        r = client.get("/alexa/dashboard", headers=_auth_header(token))
        assert r.status_code == 401


# ---------------------------------------------------------------------------
# Refresh token
# ---------------------------------------------------------------------------


class TestRefreshToken:
    def test_login_returns_refresh_token(self, client, admin_user):
        data = _login(client, "admin", "Admin1234!").json()
        assert "refresh_token" in data
        assert data["refresh_token"]

    def test_refresh_issues_new_access_token(self, client, admin_user):
        login_data = _login(client, "admin", "Admin1234!").json()
        r = client.post(
            "/auth/refresh",
            json={"refresh_token": login_data["refresh_token"]},
        )
        assert r.status_code == 200
        data = r.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"
        assert data["username"] == "admin"

    def test_refresh_new_access_token_is_usable(self, client, admin_user):
        login_data = _login(client, "admin", "Admin1234!").json()
        new_data = client.post(
            "/auth/refresh",
            json={"refresh_token": login_data["refresh_token"]},
        ).json()
        r = client.get("/auth/me", headers=_auth_header(new_data["access_token"]))
        assert r.status_code == 200
        assert r.json()["username"] == "admin"

    def test_refresh_with_invalid_token(self, client, admin_user):
        r = client.post(
            "/auth/refresh",
            json={"refresh_token": "not.a.valid.token"},
        )
        assert r.status_code == 401

    def test_refresh_with_access_token_rejected(self, client, admin_user):
        """An access token must not be accepted as a refresh token."""
        access_token = _login(client, "admin", "Admin1234!").json()["access_token"]
        r = client.post(
            "/auth/refresh",
            json={"refresh_token": access_token},
        )
        assert r.status_code == 401


# ---------------------------------------------------------------------------
# Change password
# ---------------------------------------------------------------------------


class TestChangePassword:
    def test_change_password_success(self, client, admin_user):
        token = _login(client, "admin", "Admin1234!").json()["access_token"]
        r = client.put(
            "/auth/change-password",
            headers=_auth_header(token),
            json={"current_password": "Admin1234!", "new_password": "NewPass99!"},
        )
        assert r.status_code == 204
        # Can log in with new password
        assert _login(client, "admin", "NewPass99!").status_code == 200
        # Old password rejected
        assert _login(client, "admin", "Admin1234!").status_code == 401

    def test_change_password_wrong_current(self, client, admin_user):
        token = _login(client, "admin", "Admin1234!").json()["access_token"]
        r = client.put(
            "/auth/change-password",
            headers=_auth_header(token),
            json={"current_password": "WrongPass1!", "new_password": "NewPass99!"},
        )
        assert r.status_code == 400

    def test_change_password_weak_new(self, client, admin_user):
        token = _login(client, "admin", "Admin1234!").json()["access_token"]
        r = client.put(
            "/auth/change-password",
            headers=_auth_header(token),
            json={"current_password": "Admin1234!", "new_password": "weak"},
        )
        assert r.status_code == 422

    def test_change_password_requires_auth(self, client, admin_user):
        r = client.put(
            "/auth/change-password",
            json={"current_password": "Admin1234!", "new_password": "NewPass99!"},
        )
        assert r.status_code == 401


# ---------------------------------------------------------------------------
# Rate limiting
# ---------------------------------------------------------------------------


class TestRateLimiting:
    def test_rate_limit_exceeded(self, client, admin_user, monkeypatch):
        import auth.rate_limiter as rl

        monkeypatch.setattr(rl, "MAX_ATTEMPTS", 3)
        # Exceed the limit
        for _ in range(3):
            _login(client, "admin", "wrongpass")
        r = _login(client, "admin", "wrongpass")
        assert r.status_code == 429


# ---------------------------------------------------------------------------
# API key
# ---------------------------------------------------------------------------


class TestApiKey:
    def test_webhook_missing_key(self, client, monkeypatch):
        monkeypatch.setenv("ALEXA_API_KEY", "secret-key")
        import auth.api_key as ak

        monkeypatch.setattr(ak, "_ALEXA_API_KEY", "secret-key")
        r = client.post("/alexa/webhook", json={"intent": "test"})
        assert r.status_code == 401

    def test_webhook_valid_key(self, client, monkeypatch):
        import auth.api_key as ak

        monkeypatch.setattr(ak, "_ALEXA_API_KEY", "secret-key")
        r = client.post(
            "/alexa/webhook",
            json={"intent": "test"},
            headers={"X-API-Key": "secret-key"},
        )
        assert r.status_code == 200

    def test_webhook_invalid_key(self, client, monkeypatch):
        import auth.api_key as ak

        monkeypatch.setattr(ak, "_ALEXA_API_KEY", "secret-key")
        r = client.post(
            "/alexa/webhook",
            json={"intent": "test"},
            headers={"X-API-Key": "wrong-key"},
        )
        assert r.status_code == 401


# ---------------------------------------------------------------------------
# Public endpoints
# ---------------------------------------------------------------------------


class TestPublicEndpoints:
    def test_health(self, client):
        r = client.get("/alexa/health")
        assert r.status_code == 200

    def test_query(self, client):
        r = client.get("/alexa/query", params={"q": "hello"})
        assert r.status_code == 200

    def test_login_page(self, client):
        r = client.get("/login")
        assert r.status_code == 200
        assert "Core West College" in r.text

    def test_dashboard_html_page_served(self, client):
        r = client.get("/alexa/dashboard.html")
        assert r.status_code == 200
        assert "Core West College" in r.text
