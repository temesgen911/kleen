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
    firebase_uid: str = Field(..., serialization_alias="firebaseUid")
    display_name: Optional[str] = Field(None, serialization_alias="displayName")
    email: Optional[str] = None
    timezone: str = "UTC"

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


class UserCreate(UserBase):
    pass


class UserUpdate(BaseModel):
    display_name: Optional[str] = Field(None, serialization_alias="displayName")
    email: Optional[str] = None
    timezone: Optional[str] = None

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


class UserRead(UserBase):
    id: uuid.UUID
    created_at: datetime = Field(..., serialization_alias="createdAt")
    updated_at: datetime = Field(..., serialization_alias="updatedAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


# ---------------------------------------------------------------------------
# ScanSession Schemas
# ---------------------------------------------------------------------------

class ScanSessionBase(BaseModel):
    status: str = "in_progress"
    metadata: Dict[str, Any] = Field(default_factory=dict)

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


class ScanSessionCreate(BaseModel):
    metadata: Dict[str, Any] = Field(default_factory=dict)


class ScanSessionRead(ScanSessionBase):
    id: uuid.UUID
    user_id: uuid.UUID = Field(..., serialization_alias="userId")
    started_at: datetime = Field(..., serialization_alias="startedAt")
    completed_at: Optional[datetime] = Field(None, serialization_alias="completedAt")
    created_at: datetime = Field(..., serialization_alias="createdAt")
    updated_at: datetime = Field(..., serialization_alias="updatedAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


# ---------------------------------------------------------------------------
# Room Schemas
# ---------------------------------------------------------------------------

class RoomBase(BaseModel):
    name: str
    room_type: str = Field(..., serialization_alias="roomType")
    last_scanned_at: Optional[datetime] = Field(None, serialization_alias="lastScannedAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


class RoomCreate(RoomBase):
    scan_session_id: Optional[uuid.UUID] = Field(None, serialization_alias="scanSessionId")


class RoomRead(RoomBase):
    id: uuid.UUID
    user_id: uuid.UUID = Field(..., serialization_alias="userId")
    scan_session_id: Optional[uuid.UUID] = Field(None, serialization_alias="scanSessionId")
    created_at: datetime = Field(..., serialization_alias="createdAt")
    updated_at: datetime = Field(..., serialization_alias="updatedAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


# ---------------------------------------------------------------------------
# CapturedImage Schemas
# ---------------------------------------------------------------------------

class CapturedImageBase(BaseModel):
    storage_path: str = Field(..., serialization_alias="storagePath")
    width: Optional[int] = None
    height: Optional[int] = None
    orientation_degrees: int = Field(0, serialization_alias="orientationDegrees")
    source_type: str = Field("camera", serialization_alias="sourceType")
    captured_at: Optional[datetime] = Field(None, serialization_alias="capturedAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


class CapturedImageCreate(CapturedImageBase):
    room_id: uuid.UUID = Field(..., serialization_alias="roomId")
    scan_session_id: Optional[uuid.UUID] = Field(None, serialization_alias="scanSessionId")


class CapturedImageRead(CapturedImageBase):
    id: uuid.UUID
    room_id: uuid.UUID = Field(..., serialization_alias="roomId")
    user_id: uuid.UUID = Field(..., serialization_alias="userId")
    scan_session_id: Optional[uuid.UUID] = Field(None, serialization_alias="scanSessionId")
    captured_at: datetime = Field(..., serialization_alias="capturedAt")
    created_at: datetime = Field(..., serialization_alias="createdAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


# ---------------------------------------------------------------------------
# ConfirmedItem Schemas
# ---------------------------------------------------------------------------

class ConfirmedItemBase(BaseModel):
    normalized_name: str = Field(..., serialization_alias="normalizedName")
    display_name: str = Field(..., serialization_alias="displayName")
    category: str
    material: Optional[str] = None
    provenance: str = "ai_detected"
    confidence: Optional[Decimal] = None
    is_confirmed: bool = Field(True, serialization_alias="isConfirmed")
    source_metadata: Dict[str, Any] = Field(default_factory=dict, serialization_alias="sourceMetadata")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


class ConfirmedItemCreate(ConfirmedItemBase):
    room_id: uuid.UUID = Field(..., serialization_alias="roomId")


class ConfirmedItemRead(ConfirmedItemBase):
    id: uuid.UUID
    room_id: uuid.UUID = Field(..., serialization_alias="roomId")
    user_id: uuid.UUID = Field(..., serialization_alias="userId")
    created_at: datetime = Field(..., serialization_alias="createdAt")
    updated_at: datetime = Field(..., serialization_alias="updatedAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


# ---------------------------------------------------------------------------
# CleaningRequirement Schemas
# ---------------------------------------------------------------------------

class CleaningRequirementBase(BaseModel):
    action: str
    interval_days: int = Field(7, serialization_alias="intervalDays")
    estimated_minutes: int = Field(10, serialization_alias="estimatedMinutes")
    priority: str = "medium"
    rule_metadata: Dict[str, Any] = Field(default_factory=dict, serialization_alias="ruleMetadata")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


class CleaningRequirementCreate(CleaningRequirementBase):
    confirmed_item_id: uuid.UUID = Field(..., serialization_alias="confirmedItemId")


class CleaningRequirementRead(CleaningRequirementBase):
    id: uuid.UUID
    confirmed_item_id: uuid.UUID = Field(..., serialization_alias="confirmedItemId")
    user_id: uuid.UUID = Field(..., serialization_alias="userId")
    created_at: datetime = Field(..., serialization_alias="createdAt")
    updated_at: datetime = Field(..., serialization_alias="updatedAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


# ---------------------------------------------------------------------------
# CleaningPlan & PlanTask Schemas
# ---------------------------------------------------------------------------

class PlanTaskBase(BaseModel):
    title: str
    scheduled_date: date = Field(..., serialization_alias="scheduledDate")
    estimated_minutes: int = Field(10, serialization_alias="estimatedMinutes")
    status: str = "pending"
    order_index: int = Field(0, serialization_alias="orderIndex")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


class PlanTaskCreate(PlanTaskBase):
    confirmed_item_id: Optional[uuid.UUID] = Field(None, serialization_alias="confirmedItemId")
    cleaning_requirement_id: Optional[uuid.UUID] = Field(None, serialization_alias="cleaningRequirementId")


class PlanTaskRead(PlanTaskBase):
    id: uuid.UUID
    plan_id: uuid.UUID = Field(..., serialization_alias="planId")
    user_id: uuid.UUID = Field(..., serialization_alias="userId")
    confirmed_item_id: Optional[uuid.UUID] = Field(None, serialization_alias="confirmedItemId")
    cleaning_requirement_id: Optional[uuid.UUID] = Field(None, serialization_alias="cleaningRequirementId")
    created_at: datetime = Field(..., serialization_alias="createdAt")
    updated_at: datetime = Field(..., serialization_alias="updatedAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


class CleaningPlanBase(BaseModel):
    status: str = "draft"
    plan_version: int = Field(1, serialization_alias="planVersion")
    accepted_at: Optional[datetime] = Field(None, serialization_alias="acceptedAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


class CleaningPlanCreate(CleaningPlanBase):
    tasks: List[PlanTaskCreate] = Field(default_factory=list)


class CleaningPlanRead(CleaningPlanBase):
    id: uuid.UUID
    user_id: uuid.UUID = Field(..., serialization_alias="userId")
    created_at: datetime = Field(..., serialization_alias="createdAt")
    updated_at: datetime = Field(..., serialization_alias="updatedAt")
    tasks: List[PlanTaskRead] = Field(default_factory=list)

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


# ---------------------------------------------------------------------------
# TaskCompletion Schemas
# ---------------------------------------------------------------------------

class TaskCompletionBase(BaseModel):
    completion_status: str = Field("completed", serialization_alias="completionStatus")
    actual_duration_seconds: Optional[int] = Field(None, serialization_alias="actualDurationSeconds")
    metadata: Dict[str, Any] = Field(default_factory=dict)

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


class TaskCompletionCreate(TaskCompletionBase):
    plan_task_id: uuid.UUID = Field(..., serialization_alias="planTaskId")
    completed_at: Optional[datetime] = Field(None, serialization_alias="completedAt")


class TaskCompletionRead(TaskCompletionBase):
    id: uuid.UUID
    plan_task_id: uuid.UUID = Field(..., serialization_alias="planTaskId")
    user_id: uuid.UUID = Field(..., serialization_alias="userId")
    completed_at: datetime = Field(..., serialization_alias="completedAt")
    created_at: datetime = Field(..., serialization_alias="createdAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )


# ---------------------------------------------------------------------------
# UserStreak Schemas
# ---------------------------------------------------------------------------

class UserStreakRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID = Field(..., serialization_alias="userId")
    current_streak: int = Field(0, serialization_alias="currentStreak")
    longest_streak: int = Field(0, serialization_alias="longestStreak")
    last_completed_date: Optional[date] = Field(None, serialization_alias="lastCompletedDate")
    freeze_count: int = Field(0, serialization_alias="freezeCount")
    created_at: datetime = Field(..., serialization_alias="createdAt")
    updated_at: datetime = Field(..., serialization_alias="updatedAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
    )
