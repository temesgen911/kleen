"""CleaningRequirement ORM model."""

import uuid
from typing import TYPE_CHECKING, Any, Dict, List
from sqlalchemy import CheckConstraint, ForeignKey, Index, Integer, String
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.item import ConfirmedItem
    from app.models.task import PlanTask
    from app.models.user import User


class CleaningRequirement(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """CleaningRequirement entity defining cadence, duration, priority, and method for items."""

    __tablename__ = "cleaning_requirements"
    __table_args__ = (
        CheckConstraint("interval_days >= 1", name="chk_cleaning_requirements_interval"),
        CheckConstraint("estimated_minutes >= 1", name="chk_cleaning_requirements_minutes"),
        CheckConstraint(
            "priority IN ('low', 'medium', 'high', 'critical')",
            name="chk_cleaning_requirements_priority",
        ),
        Index("idx_cleaning_requirements_confirmed_item_id", "confirmed_item_id"),
        Index("idx_cleaning_requirements_user_id", "user_id"),
        Index("idx_cleaning_requirements_priority", "priority"),
    )

    confirmed_item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("confirmed_items.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    action: Mapped[str] = mapped_column(String, nullable=False)
    interval_days: Mapped[int] = mapped_column(Integer, nullable=False, default=7)
    estimated_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=10)
    priority: Mapped[str] = mapped_column(String, nullable=False, default="medium")
    rule_metadata: Mapped[Dict[str, Any]] = mapped_column(
        JSONB,
        nullable=False,
        default=dict,
    )

    # Relationships
    confirmed_item: Mapped["ConfirmedItem"] = relationship(
        "ConfirmedItem",
        back_populates="cleaning_requirements",
    )
    user: Mapped["User"] = relationship("User", back_populates="cleaning_requirements")
    plan_tasks: Mapped[List["PlanTask"]] = relationship(
        "PlanTask",
        back_populates="cleaning_requirement",
    )

    def __repr__(self) -> str:
        return f"<CleaningRequirement id={self.id} action={self.action} interval={self.interval_days}d>"
