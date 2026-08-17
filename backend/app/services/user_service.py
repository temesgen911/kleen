"""User synchronization and profile management service."""

import logging
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.streak import UserStreak
from app.models.user import User

logger = logging.getLogger(__name__)


async def get_or_create_user(
    db: AsyncSession,
    firebase_uid: str,
    email: Optional[str] = None,
    display_name: Optional[str] = None,
) -> User:
    """Find existing user by firebase_uid or create a new user and streak record.
    
    Firebase Authentication is the sole external identity authority.
    PostgreSQL stores the persistent user profile and relational associations.
    """
    stmt = select(User).where(User.firebase_uid == firebase_uid)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if user is not None:
        # User already exists - optionally update email/displayName if changed
        updated = False
        if email and user.email != email:
            user.email = email
            updated = True
        if display_name and user.display_name != display_name:
            user.display_name = display_name
            updated = True
        
        if updated:
            await db.commit()
            await db.refresh(user)
            logger.info(f"Updated profile for existing user {user.id} (firebase_uid={firebase_uid})")
            
        return user

    # First-time login: Create new local user row in PostgreSQL
    logger.info(f"Creating new user record for firebase_uid={firebase_uid}")
    new_user = User(
        firebase_uid=firebase_uid,
        email=email,
        display_name=display_name,
        timezone="UTC",
    )
    db.add(new_user)
    await db.flush()  # Flush to generate new_user.id for streak foreign key

    # Initialize associated streak record
    initial_streak = UserStreak(
        user_id=new_user.id,
        current_streak=0,
        longest_streak=0,
        freeze_count=0,
    )
    db.add(initial_streak)
    await db.commit()
    await db.refresh(new_user)

    logger.info(f"Successfully created user {new_user.id} and initial streak record.")
    return new_user
