"""User ORM model."""

from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import Index, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.cleaning_requirement import CleaningRequirement
    from app.models.completion import TaskCompletion
    from app.models.image import CapturedImage
    from app.models.item import ConfirmedItem
    from app.models.plan import CleaningPlan
    from app.models.room import Room
    from app.models.scan_session import ScanSession
    from app.models.streak import UserStreak
    from app.models.task import PlanTask


class User(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """User entity linked to Firebase Authentication via firebase_uid."""

    __tablename__ = "users"

    firebase_uid: Mapped[str] = mapped_column(
        String,
        unique=True,
        nullable=False,
        index=True,
    )
    display_name: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    email: Mapped[Optional[str]] = mapped_column(String, nullable=True, index=True)
    timezone: Mapped[str] = mapped_column(String, nullable=False, default="UTC")

    # Relationships
    scan_sessions: Mapped[List["ScanSession"]] = relationship(
        "ScanSession",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    rooms: Mapped[List["Room"]] = relationship(
        "Room",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    captured_images: Mapped[List["CapturedImage"]] = relationship(
        "CapturedImage",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    confirmed_items: Mapped[List["ConfirmedItem"]] = relationship(
        "ConfirmedItem",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    cleaning_requirements: Mapped[List["CleaningRequirement"]] = relationship(
        "CleaningRequirement",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    cleaning_plans: Mapped[List["CleaningPlan"]] = relationship(
        "CleaningPlan",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    plan_tasks: Mapped[List["PlanTask"]] = relationship(
        "PlanTask",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    task_completions: Mapped[List["TaskCompletion"]] = relationship(
        "TaskCompletion",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    streak: Mapped[Optional["UserStreak"]] = relationship(
        "UserStreak",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} firebase_uid={self.firebase_uid}>"
