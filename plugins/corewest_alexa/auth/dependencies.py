"""FastAPI dependencies for route protection."""

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from .blacklist import is_blacklisted
from .jwt_handler import verify_access_token
from .models import User
from .schemas import TokenData

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)

# Re-export for convenience
from .api_key import verify_api_key  # noqa: F401, E402


def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    """
    Extract and validate a JWT bearer token from the ``Authorization``
    header.  Returns the corresponding ``User`` object.

    Raises ``HTTP 401`` on failure.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if not token:
        raise credentials_exception

    # Reject tokens that have been explicitly revoked (logout)
    if is_blacklisted(token):
        raise credentials_exception

    token_data: TokenData | None = verify_access_token(token)
    if token_data is None:
        raise credentials_exception

    user = User.get_by_id(token_data.sub)
    if user is None or not user.is_active:
        raise credentials_exception

    return user


def require_authenticated(user: User = Depends(get_current_user)) -> User:
    """Ensure the request carries a valid JWT for any role."""
    return user


def require_admin(user: User = Depends(get_current_user)) -> User:
    """Ensure the authenticated user has the ``admin`` role."""
    if user.role != User.ROLE_ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required.",
        )
    return user
