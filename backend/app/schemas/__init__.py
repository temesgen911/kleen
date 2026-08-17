"""Pydantic V2 schemas for Cleaning AI data validation and API transfer objects."""

import uuid
from datetime import date, datetime
from typing import Any, Dict, List, Optional
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------------------------
# User Schemas
# ---------------------------------------------------------------------------

class UserBase(BaseModel):
    firebase_uid: str
    display_name: Optional[str] = None
    email: Optional[str] = None
    timezone: str = "UTC"


class UserCreate(UserBase):
    pass


class UserUpdate(BaseModel):
    display_name: Optional[str] = None
    email: Optional[str] = None
    timezone: Optional[str] = None


class UserRead(UserBase):
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# ScanSession Schemas
# ---------------------------------------------------------------------------

class ScanSessionBase(BaseModel):
    status: str = "in_progress"
    metadata: Dict[str, Any] = Field(default_factory=dict)


class ScanSessionCreate(BaseModel):
    metadata: Dict[str, Any] = Field(default_factory=dict)


class ScanSessionRead(ScanSessionBase):
    id: uuid.UUID
    user_id: uuid.UUID
    started_at: datetime
    completed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Room Schemas
# ---------------------------------------------------------------------------

class RoomBase(BaseModel):
    name: str
    room_type: str
    last_scanned_at: Optional[datetime] = None


class RoomCreate(RoomBase):
    scan_session_id: Optional[uuid.UUID] = None


class RoomRead(RoomBase):
    id: uuid.UUID
    user_id: uuid.UUID
    scan_session_id: Optional[uuid.UUID] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# CapturedImage Schemas
# ---------------------------------------------------------------------------

class CapturedImageBase(BaseModel):
    storage_path: str
    width: Optional[int] = None
    height: Optional[int] = None
    orientation_degrees: int = 0
    source_type: str = "camera"
    captured_at: Optional[datetime] = None


class CapturedImageCreate(CapturedImageBase):
    room_id: uuid.UUID
    scan_session_id: Optional[uuid.UUID] = None


class CapturedImageRead(CapturedImageBase):
    id: uuid.UUID
    room_id: uuid.UUID
    user_id: uuid.UUID
    scan_session_id: Optional[uuid.UUID] = None
    captured_at: datetime
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# ConfirmedItem Schemas
# ---------------------------------------------------------------------------

class ConfirmedItemBase(BaseModel):
    normalized_name: str
    display_name: str
    category: str
    material: Optional[str] = None
    provenance: str = "ai_detected"
    confidence: Optional[Decimal] = None
    is_confirmed: bool = True
    source_metadata: Dict[str, Any] = Field(default_factory=dict)


class ConfirmedItemCreate(ConfirmedItemBase):
    room_id: uuid.UUID


class ConfirmedItemRead(ConfirmedItemBase):
    id: uuid.UUID
    room_id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# CleaningRequirement Schemas
# ---------------------------------------------------------------------------

class CleaningRequirementBase(BaseModel):
    action: str
    interval_days: int = 7
    estimated_minutes: int = 10
    priority: str = "medium"
    rule_metadata: Dict[str, Any] = Field(default_factory=dict)


class CleaningRequirementCreate(CleaningRequirementBase):
    confirmed_item_id: uuid.UUID


class CleaningRequirementRead(CleaningRequirementBase):
    id: uuid.UUID
    confirmed_item_id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# CleaningPlan & PlanTask Schemas
# ---------------------------------------------------------------------------

class PlanTaskBase(BaseModel):
    title: str
    scheduled_date: date
    estimated_minutes: int = 10
    status: str = "pending"
    order_index: int = 0


class PlanTaskCreate(PlanTaskBase):
    confirmed_item_id: Optional[uuid.UUID] = None
    cleaning_requirement_id: Optional[uuid.UUID] = None


class PlanTaskRead(PlanTaskBase):
    id: uuid.UUID
    plan_id: uuid.UUID
    user_id: uuid.UUID
    confirmed_item_id: Optional[uuid.UUID] = None
    cleaning_requirement_id: Optional[uuid.UUID] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CleaningPlanBase(BaseModel):
    status: str = "draft"
    plan_version: int = 1
    accepted_at: Optional[datetime] = None


class CleaningPlanCreate(CleaningPlanBase):
    tasks: List[PlanTaskCreate] = Field(default_factory=list)


class CleaningPlanRead(CleaningPlanBase):
    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    updated_at: datetime
    tasks: List[PlanTaskRead] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# TaskCompletion Schemas
# ---------------------------------------------------------------------------

class TaskCompletionBase(BaseModel):
    completion_status: str = "completed"
    actual_duration_seconds: Optional[int] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)


class TaskCompletionCreate(TaskCompletionBase):
    plan_task_id: uuid.UUID
    completed_at: Optional[datetime] = None


class TaskCompletionRead(TaskCompletionBase):
    id: uuid.UUID
    plan_task_id: uuid.UUID
    user_id: uuid.UUID
    completed_at: datetime
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# UserStreak Schemas
# ---------------------------------------------------------------------------

class UserStreakRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    current_streak: int = 0
    longest_streak: int = 0
    last_completed_date: Optional[date] = None
    freeze_count: int = 0
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
