"""Auth API endpoints."""

from threading import Lock

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer

from .blacklist import blacklist_token, is_blacklisted
from .dependencies import require_authenticated
from .jwt_handler import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    create_access_token,
    create_refresh_token,
    verify_access_token,
    verify_refresh_token,
)
from .models import User, _store_lock, _load_users
from .rate_limiter import check_rate_limit, reset_attempts
from .schemas import (
    ChangePasswordRequest,
    LoginRequest,
    LoginResponse,
    RefreshRequest,
    RegisterRequest,
    UserResponse,
)
from .utils import validate_password_strength

router = APIRouter(prefix="/auth", tags=["auth"])

_oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)

# Serialises all registration attempts so the "first-user" check and
# creation happen atomically, eliminating the concurrent-registration race.
_register_lock = Lock()


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _to_response(user: User) -> UserResponse:
    return UserResponse(
        id=user.id,
        username=user.username,
        email=user.email,
        role=user.role,
        is_active=user.is_active,
        created_at=user.created_at,
        last_login=user.last_login,
    )


# ---------------------------------------------------------------------------
# POST /auth/login
# ---------------------------------------------------------------------------


@router.post("/login", response_model=LoginResponse)
async def login(
    credentials: LoginRequest,
    request: Request,
) -> LoginResponse:
    """Authenticate a user and return a JWT access token."""
    check_rate_limit(request)

    user = User.get_by_username(credentials.username)
    if user is None or not user.verify_password(credentials.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is disabled.",
        )

    reset_attempts(request)
    user.touch_last_login()

    token = create_access_token(
        user_id=user.id, username=user.username, role=user.role
    )
    refresh = create_refresh_token(
        user_id=user.id, username=user.username, role=user.role
    )
    return LoginResponse(
        access_token=token,
        refresh_token=refresh,
        token_type="bearer",
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        username=user.username,
        role=user.role,
    )


# ---------------------------------------------------------------------------
# POST /auth/register
# ---------------------------------------------------------------------------


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
async def register(
    body: RegisterRequest,
    token: str = Depends(_oauth2_scheme),
) -> UserResponse:
    """
    Register a new user.

    * If no users exist yet, the first registration is allowed without
      authentication and the new user automatically becomes ``admin``.
    * Subsequent registrations require an authenticated admin.

    The auth check and user creation are performed under a single lock to
    prevent concurrent first-user registrations from both passing the
    unauthenticated gate.
    """
    # Validate password strength before acquiring the lock (no I/O needed)
    if not validate_password_strength(body.password):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                "Password must be at least 8 characters and "
                "contain at least one digit."
            ),
        )

    with _register_lock:
        # Hold the store lock for the entire check-and-create sequence so
        # that no concurrent request can slip in between the emptiness check
        # and the actual write.
        with _store_lock:
            existing_users = _load_users()
            is_first_user = len(existing_users) == 0

            if not is_first_user:
                # Require a valid admin token for all subsequent registrations
                if not token:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Authentication required to register new users.",
                        headers={"WWW-Authenticate": "Bearer"},
                    )
                token_data = verify_access_token(token)
                if token_data is None:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Invalid or expired token.",
                    )
                if is_blacklisted(token):
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Token has been revoked.",
                    )
                # Look up the admin directly from the already-loaded list
                # to avoid re-acquiring _store_lock (deadlock prevention).
                admin_dict = next(
                    (d for d in existing_users if d["id"] == token_data.sub),
                    None,
                )
                if admin_dict is None or not admin_dict.get("is_active", True):
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="User not found or inactive.",
                    )
                if admin_dict.get("role") != User.ROLE_ADMIN:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Admin access required to register new users.",
                    )

            # Uniqueness checks inside the lock so they are consistent
            usernames = {d["username"].lower() for d in existing_users}
            emails = {d["email"].lower() for d in existing_users}

            if body.username.lower() in usernames:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Username already taken.",
                )
            if body.email.lower() in emails:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Email already registered.",
                )

            # First user is always admin regardless of requested role
            role = User.ROLE_ADMIN if is_first_user else body.role

            user = User.create_locked(
                username=body.username,
                email=body.email,
                plain_password=body.password,
                role=role,
            )

    return _to_response(user)


# ---------------------------------------------------------------------------
# POST /auth/refresh
# ---------------------------------------------------------------------------


@router.post("/refresh", response_model=LoginResponse)
async def refresh_token(body: RefreshRequest) -> LoginResponse:
    """Exchange a refresh token for a new access + refresh token pair (rotation)."""
    token_data = verify_refresh_token(body.refresh_token)
    if token_data is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token.",
        )

    user = User.get_by_id(token_data.sub)
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive.",
        )

    new_access = create_access_token(
        user_id=user.id, username=user.username, role=user.role
    )
    new_refresh = create_refresh_token(
        user_id=user.id, username=user.username, role=user.role
    )
    return LoginResponse(
        access_token=new_access,
        refresh_token=new_refresh,
        token_type="bearer",
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        username=user.username,
        role=user.role,
    )


# ---------------------------------------------------------------------------
# GET /auth/me
# ---------------------------------------------------------------------------


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(require_authenticated)) -> UserResponse:
    """Return the current user's profile."""
    return _to_response(current_user)


# ---------------------------------------------------------------------------
# POST /auth/logout
# ---------------------------------------------------------------------------


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    token: str = Depends(_oauth2_scheme),
    current_user: User = Depends(require_authenticated),
) -> None:
    """Invalidate the current access token."""
    if token:
        blacklist_token(token)


# ---------------------------------------------------------------------------
# PUT /auth/change-password
# ---------------------------------------------------------------------------


@router.put("/change-password", status_code=status.HTTP_204_NO_CONTENT)
async def change_password(
    body: ChangePasswordRequest,
    current_user: User = Depends(require_authenticated),
) -> None:
    """Change the authenticated user's password."""
    if not current_user.verify_password(body.current_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect.",
        )

    if not validate_password_strength(body.new_password):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                "New password must be at least 8 characters and "
                "contain at least one digit."
            ),
        )

    current_user.set_password(body.new_password)
    current_user.save()
