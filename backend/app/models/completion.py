"""TaskCompletion ORM model."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Any, Dict, Optional
from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.task import PlanTask
    from app.models.user import User


class TaskCompletion(Base, UUIDPrimaryKeyMixin):
    """TaskCompletion entity logging completed tasks, durations, and session feedback."""

    __tablename__ = "task_completions"
    __table_args__ = (
        CheckConstraint(
            "completion_status IN ('completed', 'partial', 'skipped')",
            name="chk_task_completions_status",
        ),
        CheckConstraint(
            "actual_duration_seconds IS NULL OR actual_duration_seconds >= 0",
            name="chk_task_completions_duration",
        ),
        Index("idx_task_completions_plan_task_id", "plan_task_id"),
        Index("idx_task_completions_user_id", "user_id"),
        Index("idx_task_completions_completed_at", "completed_at"),
    )

    plan_task_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("plan_tasks.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    completed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=datetime.utcnow,
    )
    completion_status: Mapped[str] = mapped_column(
        String,
        nullable=False,
        default="completed",
    )
    actual_duration_seconds: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True,
    )
    metadata_: Mapped[Dict[str, Any]] = mapped_column(
        "metadata",
        JSONB,
        nullable=False,
        default=dict,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    plan_task: Mapped["PlanTask"] = relationship("PlanTask", back_populates="completions")
    user: Mapped["User"] = relationship("User", back_populates="task_completions")

    def __repr__(self) -> str:
        return f"<TaskCompletion id={self.id} task_id={self.plan_task_id} status={self.completion_status}>"
