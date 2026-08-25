"""FastAPI authentication dependencies and security injection."""

import logging
from typing import Annotated, Optional
from fastapi import Depends, HTTPException, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.firebase import (
    ExpiredTokenError,
    FirebaseTokenError,
    InvalidTokenError,
    verify_firebase_token,
)
from app.models.user import User
from app.services.user_service import get_or_create_user

logger = logging.getLogger(__name__)

# HTTPBearer scheme requiring Authorization: Bearer <token>
bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Annotated[Optional[HTTPAuthorizationCredentials], Security(bearer_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """FastAPI dependency that verifies the Firebase ID token in the Authorization header
    and returns the synchronized PostgreSQL User entity.
    
    Raises:
        HTTPException: 401 Unauthorized if token is missing, expired, or invalid.
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication credentials were not provided in Authorization header.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    if not token or not token.strip():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Bearer token is empty.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        token_payload = verify_firebase_token(token)
    except ExpiredTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase ID token has expired. Please refresh your token.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e
    except (InvalidTokenError, FirebaseTokenError) as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials: Token is invalid or malformed.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e
    except Exception as e:
        logger.error(f"Unexpected error in get_current_user: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e

    firebase_uid = token_payload.get("uid") or token_payload.get("user_id")
    if not firebase_uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token payload missing required 'uid' claim.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    email = token_payload.get("email")
    display_name = token_payload.get("name")

    # Synchronize with PostgreSQL users table
    user = await get_or_create_user(
        db=db,
        firebase_uid=firebase_uid,
        email=email,
        display_name=display_name,
    )

    return user


async def get_current_user_optional(
    credentials: Annotated[Optional[HTTPAuthorizationCredentials], Security(bearer_scheme)],
) -> Optional[dict]:
    """Optional authentication dependency for endpoints that accept both authenticated and guest users."""
    if credentials is None or not credentials.credentials:
        return None
    try:
        return verify_firebase_token(credentials.credentials)
    except Exception:
        return None

