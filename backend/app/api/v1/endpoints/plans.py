"""Cleaning Plan & Task Scheduling endpoints."""

from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Body
from pydantic import BaseModel, Field

from app.services.plan_scheduler_service import PlanSchedulerService

router = APIRouter(prefix="/plans", tags=["Cleaning Plans"])


class ItemInputSchema(BaseModel):
    id: Optional[str] = None
    name: str
    room_name: str = Field(default="General", alias="roomName")
    category: str = "other"
    cleaning_action: str = Field(default="Clean", alias="cleaningAction")
    frequency: str = "weekly"
    dirty_level: int = Field(default=1, alias="dirtyLevel")
    estimated_minutes: int = Field(default=5, alias="estimatedMinutes")
    priority: str = "medium"

    class Config:
        populate_by_name = True


class GeneratePlanRequestSchema(BaseModel):
    items: List[ItemInputSchema]
    target_weeks: int = Field(default=4, ge=1, le=12, alias="targetWeeks")
    start_date: Optional[str] = Field(default=None, alias="startDate")
    user_pacing_factor: float = Field(default=1.0, ge=0.5, le=2.0, alias="userPacingFactor")

    class Config:
        populate_by_name = True


class RescheduleMissedRequestSchema(BaseModel):
    tasks: List[Dict[str, Any]]
    missed_day_indices: List[int] = Field(..., alias="missedDayIndices")
    user_pacing_factor: float = Field(default=1.0, ge=0.5, le=2.0, alias="userPacingFactor")

    class Config:
        populate_by_name = True


@router.post("/generate", response_model=Dict[str, Any])
async def generate_cleaning_plan(payload: GeneratePlanRequestSchema = Body(...)):
    """Generates an intelligent multi-week cleaning plan with load balancing and Gemini AI support."""
    scheduler = PlanSchedulerService()
    items_dict = [item.model_dump() for item in payload.items]
    plan = await scheduler.generate_plan(
        items=items_dict,
        target_weeks=payload.target_weeks,
        user_pacing_factor=payload.user_pacing_factor,
    )
    return plan


@router.post("/reschedule-missed", response_model=Dict[str, Any])
async def reschedule_missed_days(payload: RescheduleMissedRequestSchema = Body(...)):
    """Recalculates and redistributes tasks from missed days across remaining available days."""
    scheduler = PlanSchedulerService()
    rescheduled = await scheduler.reschedule_missed_days(
        tasks=payload.tasks,
        missed_day_indices=payload.missed_day_indices,
        user_pacing_factor=payload.user_pacing_factor,
    )
    return rescheduled
