"""CleaningPlan ORM model."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.task import PlanTask
    from app.models.user import User


class CleaningPlan(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """CleaningPlan entity representing an accepted or draft multi-day cleaning schedule."""

    __tablename__ = "cleaning_plans"
    __table_args__ = (
        CheckConstraint("status IN ('draft', 'active', 'archived')", name="chk_cleaning_plans_status"),
        CheckConstraint("plan_version >= 1", name="chk_cleaning_plans_version"),
        Index("idx_cleaning_plans_user_id", "user_id"),
        Index("idx_cleaning_plans_status", "status"),
        Index(
            "idx_cleaning_plans_user_active",
            "user_id",
            unique=True,
            postgresql_where=(mapped_column("status") == "active"),
        ),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    status: Mapped[str] = mapped_column(String, nullable=False, default="draft")
    plan_version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    accepted_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="cleaning_plans")
    tasks: Mapped[List["PlanTask"]] = relationship(
        "PlanTask",
        back_populates="plan",
        cascade="all, delete-orphan",
        order_by="PlanTask.order_index",
    )

    def __repr__(self) -> str:
        return f"<CleaningPlan id={self.id} status={self.status} version={self.plan_version}>"
