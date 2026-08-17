"""User profile and identity endpoints."""

from typing import Annotated
from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.models.user import User
from app.schemas import UserRead

router = APIRouter()


@router.get(
    "/me",
    response_model=UserRead,
    summary="Get current user profile",
    description="Returns the synchronized PostgreSQL user record for the authenticated Firebase user.",
)
async def get_current_user_profile(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """Returns the authenticated user's profile."""
    return current_user


@router.get(
    "/users/me",
    response_model=UserRead,
    include_in_schema=False,
)
async def get_current_user_profile_alias(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """Alias for /me endpoint."""
    return current_user
