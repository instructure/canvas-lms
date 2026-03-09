"""API key validation for Alexa webhook requests."""

import os

from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader

_ALEXA_API_KEY: str = os.environ.get("ALEXA_API_KEY", "")

_api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def verify_api_key(api_key: str = Security(_api_key_header)) -> str:
    """
    FastAPI dependency that validates the ``X-API-Key`` header.

    Raises ``HTTP 401`` if the key is missing or invalid.
    """
    if not _ALEXA_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="ALEXA_API_KEY environment variable is not set.",
        )
    if not api_key or api_key != _ALEXA_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API key.",
            headers={"WWW-Authenticate": "ApiKey"},
        )
    return api_key
