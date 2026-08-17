"""ConfirmedItem ORM model."""

import uuid
from typing import TYPE_CHECKING, Any, Dict, List, Optional
from decimal import Decimal
from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Index, Numeric, String
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.cleaning_requirement import CleaningRequirement
    from app.models.room import Room
    from app.models.task import PlanTask
    from app.models.user import User


class ConfirmedItem(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """ConfirmedItem entity representing cleanable objects detected in rooms or added manually."""

    __tablename__ = "confirmed_items"
    __table_args__ = (
        CheckConstraint(
            "category IN ('furniture', 'appliance', 'surface', 'fixture', 'electronics', 'textiles', 'general')",
            name="chk_confirmed_items_category",
        ),
        CheckConstraint(
            "provenance IN ('ai_detected', 'manual_added', 'user_modified')",
            name="chk_confirmed_items_provenance",
        ),
        CheckConstraint(
            "confidence IS NULL OR (confidence >= 0.000 AND confidence <= 1.000)",
            name="chk_confirmed_items_confidence",
        ),
        Index("idx_confirmed_items_room_id", "room_id"),
        Index("idx_confirmed_items_user_id", "user_id"),
        Index("idx_confirmed_items_category", "category"),
        Index("idx_confirmed_items_is_confirmed", "is_confirmed"),
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
    normalized_name: Mapped[str] = mapped_column(String, nullable=False)
    display_name: Mapped[str] = mapped_column(String, nullable=False)
    category: Mapped[str] = mapped_column(String, nullable=False)
    material: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    provenance: Mapped[str] = mapped_column(String, nullable=False, default="ai_detected")
    confidence: Mapped[Optional[Decimal]] = mapped_column(Numeric(4, 3), nullable=True)
    is_confirmed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    source_metadata: Mapped[Dict[str, Any]] = mapped_column(
        JSONB,
        nullable=False,
        default=dict,
    )

    # Relationships
    room: Mapped["Room"] = relationship("Room", back_populates="confirmed_items")
    user: Mapped["User"] = relationship("User", back_populates="confirmed_items")
    cleaning_requirements: Mapped[List["CleaningRequirement"]] = relationship(
        "CleaningRequirement",
        back_populates="confirmed_item",
        cascade="all, delete-orphan",
    )
    plan_tasks: Mapped[List["PlanTask"]] = relationship(
        "PlanTask",
        back_populates="confirmed_item",
    )

    def __repr__(self) -> str:
        return f"<ConfirmedItem id={self.id} display_name={self.display_name}>"
