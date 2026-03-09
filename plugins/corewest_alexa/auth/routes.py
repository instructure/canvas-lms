"""Auth API endpoints."""

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer

from .blacklist import blacklist_token, is_blacklisted
from .dependencies import require_authenticated
from .jwt_handler import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    create_access_token,
    verify_access_token,
    verify_refresh_token,
)
from .models import User
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


# ---------------------------------------------------------------------------
# Internal helpers (defined first so they can be used as Depends below)
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


def _maybe_admin(
    token: str = Depends(_oauth2_scheme),
) -> "User | None":
    """
    Return the current admin user, **or** ``None`` if no users exist yet
    (to allow the very first registration without authentication).
    """
    if not User.get_all():
        return None  # first-user bootstrap — no auth required

    # From here on we require a valid admin token
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

    user = User.get_by_id(token_data.sub)
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive.",
        )

    if user.role != User.ROLE_ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required to register new users.",
        )

    return user


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
    return LoginResponse(
        access_token=token,
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
    current_user: User = Depends(_maybe_admin),
) -> UserResponse:
    """
    Register a new user.

    * If no users exist yet, the first registration is allowed without
      authentication and the new user automatically becomes ``admin``.
    * Subsequent registrations require an authenticated admin.
    """
    # Validate password strength
    if not validate_password_strength(body.password):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                "Password must be at least 8 characters and "
                "contain at least one digit."
            ),
        )

    if User.get_by_username(body.username):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username already taken.",
        )
    if User.get_by_email(body.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered.",
        )

    role = body.role
    if not User.get_all():
        # First user always becomes admin
        role = User.ROLE_ADMIN

    user = User.create(
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
    """Exchange a refresh token for a new access token."""
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

    new_token = create_access_token(
        user_id=user.id, username=user.username, role=user.role
    )
    return LoginResponse(
        access_token=new_token,
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
