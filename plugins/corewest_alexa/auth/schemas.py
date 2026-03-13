"""Pydantic schemas for auth request/response models."""

from typing import Optional

from pydantic import BaseModel, EmailStr, field_validator


class LoginRequest(BaseModel):
    username: str
    password: str


class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds
    username: str
    role: str


class RegisterRequest(BaseModel):
    username: str
    email: EmailStr
    password: str
    role: str = "readonly"

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        if v not in {"admin", "readonly"}:
            raise ValueError("role must be 'admin' or 'readonly'")
        return v


class UserResponse(BaseModel):
    id: str
    username: str
    email: str
    role: str
    is_active: bool
    created_at: str
    last_login: Optional[str] = None


class TokenData(BaseModel):
    """Decoded JWT payload."""

    sub: str        # User ID
    username: str
    role: str
    exp: Optional[int] = None


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


class RefreshRequest(BaseModel):
    refresh_token: str
