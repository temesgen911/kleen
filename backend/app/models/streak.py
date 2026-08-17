"""UserStreak ORM model."""

import uuid
from datetime import date
from typing import TYPE_CHECKING, Optional
from sqlalchemy import CheckConstraint, Date, ForeignKey, Index, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.user import User


class UserStreak(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """UserStreak entity tracking consecutive completed days and streak milestones."""

    __tablename__ = "user_streaks"
    __table_args__ = (
        CheckConstraint("current_streak >= 0", name="chk_user_streaks_current"),
        CheckConstraint("longest_streak >= 0", name="chk_user_streaks_longest"),
        CheckConstraint("freeze_count >= 0", name="chk_user_streaks_freeze"),
        Index("idx_user_streaks_user_id", "user_id"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    current_streak: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    longest_streak: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    last_completed_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    freeze_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="streak")

    def __repr__(self) -> str:
        return f"<UserStreak user_id={self.user_id} current={self.current_streak} longest={self.longest_streak}>"
