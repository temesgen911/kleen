"""Unit & Integration tests for PlanSchedulerService & Plan Endpoints."""

import pytest
from datetime import date
from fastapi.testclient import TestClient

from app.main import app
from app.services.plan_scheduler_service import PlanSchedulerService, TaskFrequency

client = TestClient(app)


def test_task_frequency_parsing():
    assert TaskFrequency.parse("daily") == TaskFrequency.DAILY
    assert TaskFrequency.parse("2 times a week") == TaskFrequency.TWICE_WEEKLY
    assert TaskFrequency.parse("weekly") == TaskFrequency.WEEKLY
    assert TaskFrequency.parse("Bi-Weekly (Every 2 wks)") == TaskFrequency.BI_WEEKLY
    assert TaskFrequency.parse("2x a month") == TaskFrequency.TWICE_MONTHLY
    assert TaskFrequency.parse("Monthly") == TaskFrequency.MONTHLY
    assert TaskFrequency.parse("Quarterly") == TaskFrequency.QUARTERLY


@pytest.mark.asyncio
async def test_plan_scheduler_rule_engine():
    scheduler = PlanSchedulerService(gemini_api_key=None)
    items = [
        {"id": "1", "name": "Sofa", "roomName": "Living Room", "cleaningAction": "Vacuum", "frequency": "bi_weekly", "estimatedMinutes": 10},
        {"id": "2", "name": "Coffee Table", "roomName": "Living Room", "cleaningAction": "Wipe", "frequency": "weekly", "estimatedMinutes": 3},
        {"id": "3", "name": "Curtains", "roomName": "Bedroom", "cleaningAction": "Dust", "frequency": "monthly", "estimatedMinutes": 15},
    ]
    plan = await scheduler.generate_plan(items=items, target_weeks=4)
    assert plan["status"] == "success"
    assert plan["generation_method"] == "rule_engine"
    assert plan["total_tasks"] > 0

    # Verify bi_weekly item is not in every single week 4 times
    bi_weekly_tasks = [t for t in plan["tasks"] if t["item_id"] == "1"]
    assert len(bi_weekly_tasks) == 2  # Scheduled 2 times across 4 weeks!


@pytest.mark.asyncio
async def test_reschedule_missed_days():
    scheduler = PlanSchedulerService(gemini_api_key=None)
    tasks = [
        {"id": "t1", "item_id": "1", "title": "Clean Desk", "scheduled_day_index": 1, "status": "pending", "estimated_minutes": 10},
        {"id": "t2", "item_id": "2", "title": "Mop Floor", "scheduled_day_index": 2, "status": "pending", "estimated_minutes": 15},
    ]
    rescheduled = await scheduler.reschedule_missed_days(
        tasks=tasks,
        missed_day_indices=[1],  # Missed Tuesday
    )
    assert rescheduled["status"] == "success"
    t1 = next(t for t in rescheduled["tasks"] if t["id"] == "t1")
    assert t1["scheduled_day_index"] != 1
    assert t1["status"] == "rescheduled"


def test_api_generate_plan_endpoint():
    payload = {
        "items": [
            {
                "id": "item_1",
                "name": "TV Stand",
                "roomName": "Living Room",
                "category": "furniture",
                "cleaningAction": "Dust",
                "frequency": "2x a month",
                "estimatedMinutes": 5
            }
        ],
        "targetWeeks": 4
    }
    response = client.post("/api/v1/plans/generate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert "tasks" in data
