"""ScanSession ORM model."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Any, Dict, List, Optional
from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, String
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.image import CapturedImage
    from app.models.room import Room
    from app.models.user import User


class ScanSession(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """ScanSession entity representing an active or completed multi-room scanning workflow."""

    __tablename__ = "scan_sessions"
    __table_args__ = (
        CheckConstraint(
            "status IN ('in_progress', 'analyzed', 'confirmed', 'discarded', 'archived')",
            name="chk_scan_sessions_status",
        ),
        Index("idx_scan_sessions_user_id", "user_id"),
        Index("idx_scan_sessions_status", "status"),
        Index("idx_scan_sessions_started_at", "started_at"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    status: Mapped[str] = mapped_column(
        String,
        nullable=False,
        default="in_progress",
    )
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=datetime.utcnow,
    )
    completed_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    metadata_: Mapped[Dict[str, Any]] = mapped_column(
        "metadata",
        JSONB,
        nullable=False,
        default=dict,
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="scan_sessions")
    rooms: Mapped[List["Room"]] = relationship(
        "Room",
        back_populates="scan_session",
    )
    captured_images: Mapped[List["CapturedImage"]] = relationship(
        "CapturedImage",
        back_populates="scan_session",
    )

    def __repr__(self) -> str:
        return f"<ScanSession id={self.id} status={self.status}>"
