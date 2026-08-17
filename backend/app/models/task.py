"""PlanTask ORM model."""

import uuid
from datetime import date
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import CheckConstraint, Date, ForeignKey, Index, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.cleaning_requirement import CleaningRequirement
    from app.models.completion import TaskCompletion
    from app.models.item import ConfirmedItem
    from app.models.plan import CleaningPlan
    from app.models.user import User


class PlanTask(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """PlanTask entity representing an individual task assigned to a specific calendar date."""

    __tablename__ = "plan_tasks"
    __table_args__ = (
        CheckConstraint("estimated_minutes >= 1", name="chk_plan_tasks_minutes"),
        CheckConstraint(
            "status IN ('pending', 'completed', 'skipped', 'rescheduled')",
            name="chk_plan_tasks_status",
        ),
        Index("idx_plan_tasks_plan_id", "plan_id"),
        Index("idx_plan_tasks_user_id", "user_id"),
        Index("idx_plan_tasks_scheduled_date", "scheduled_date"),
        Index("idx_plan_tasks_status", "status"),
        Index("idx_plan_tasks_user_date", "user_id", "scheduled_date"),
    )

    plan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cleaning_plans.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    confirmed_item_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("confirmed_items.id", ondelete="SET NULL"),
        nullable=True,
    )
    cleaning_requirement_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cleaning_requirements.id", ondelete="SET NULL"),
        nullable=True,
    )
    title: Mapped[str] = mapped_column(String, nullable=False)
    scheduled_date: Mapped[date] = mapped_column(Date, nullable=False)
    estimated_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=10)
    status: Mapped[str] = mapped_column(String, nullable=False, default="pending")
    order_index: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    # Relationships
    plan: Mapped["CleaningPlan"] = relationship("CleaningPlan", back_populates="tasks")
    user: Mapped["User"] = relationship("User", back_populates="plan_tasks")
    confirmed_item: Mapped[Optional["ConfirmedItem"]] = relationship(
        "ConfirmedItem",
        back_populates="plan_tasks",
    )
    cleaning_requirement: Mapped[Optional["CleaningRequirement"]] = relationship(
        "CleaningRequirement",
        back_populates="plan_tasks",
    )
    completions: Mapped[List["TaskCompletion"]] = relationship(
        "TaskCompletion",
        back_populates="plan_task",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<PlanTask id={self.id} title={self.title} date={self.scheduled_date} status={self.status}>"
