"""Room ORM model."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import DateTime, ForeignKey, Index, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.image import CapturedImage
    from app.models.item import ConfirmedItem
    from app.models.scan_session import ScanSession
    from app.models.user import User


class Room(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Room entity belonging to a user and holding captured images and confirmed items."""

    __tablename__ = "rooms"
    __table_args__ = (
        Index("idx_rooms_user_id", "user_id"),
        Index("idx_rooms_scan_session_id", "scan_session_id"),
        Index("idx_rooms_room_type", "room_type"),
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
    name: Mapped[str] = mapped_column(String, nullable=False)
    room_type: Mapped[str] = mapped_column(String, nullable=False)
    last_scanned_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="rooms")
    scan_session: Mapped[Optional["ScanSession"]] = relationship(
        "ScanSession",
        back_populates="rooms",
    )
    captured_images: Mapped[List["CapturedImage"]] = relationship(
        "CapturedImage",
        back_populates="room",
        cascade="all, delete-orphan",
    )
    confirmed_items: Mapped[List["ConfirmedItem"]] = relationship(
        "ConfirmedItem",
        back_populates="room",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<Room id={self.id} name={self.name} room_type={self.room_type}>"
