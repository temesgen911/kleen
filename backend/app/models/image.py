"""CapturedImage ORM model."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional
from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.room import Room
    from app.models.scan_session import ScanSession
    from app.models.user import User


class CapturedImage(Base, UUIDPrimaryKeyMixin):
    """CapturedImage entity tracking object storage paths, resolutions, and orientation."""

    __tablename__ = "captured_images"
    __table_args__ = (
        CheckConstraint(
            "orientation_degrees IN (0, 90, 180, 270)",
            name="chk_captured_images_orientation",
        ),
        CheckConstraint(
            "source_type IN ('camera', 'gallery')",
            name="chk_captured_images_source_type",
        ),
        Index("idx_captured_images_room_id", "room_id"),
        Index("idx_captured_images_user_id", "user_id"),
        Index("idx_captured_images_scan_session_id", "scan_session_id"),
    )

    room_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("rooms.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    scan_session_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("scan_sessions.id", ondelete="SET NULL"),
        nullable=True,
    )
    storage_path: Mapped[str] = mapped_column(String, nullable=False)
    width: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    height: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    orientation_degrees: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    source_type: Mapped[str] = mapped_column(String, nullable=False, default="camera")
    captured_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=datetime.utcnow,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    room: Mapped["Room"] = relationship("Room", back_populates="captured_images")
    user: Mapped["User"] = relationship("User", back_populates="captured_images")
    scan_session: Mapped[Optional["ScanSession"]] = relationship(
        "ScanSession",
        back_populates="captured_images",
    )

    def __repr__(self) -> str:
        return f"<CapturedImage id={self.id} path={self.storage_path}>"
