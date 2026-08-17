"""Unit tests for SQLAlchemy models, table definitions, and relationships."""

import uuid
from datetime import date, datetime
from decimal import Decimal
import pytest
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from app.core.database import Base
from app.models import (
    CapturedImage,
    CleaningPlan,
    CleaningRequirement,
    ConfirmedItem,
    PlanTask,
    Room,
    ScanSession,
    TaskCompletion,
    User,
    UserStreak,
)


from sqlalchemy.ext.compiler import compiles
from sqlalchemy.dialects.postgresql import JSONB

@compiles(JSONB, "sqlite")
def compile_jsonb_sqlite(type_, compiler, **kw):
    return "JSON"


@pytest.fixture
def sqlite_engine():
    """Provides an in-memory SQLite engine for fast schema & mapping verification."""
    engine = create_engine("sqlite:///:memory:", echo=False)
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def db_session(sqlite_engine):
    """Provides a fresh database session for testing entity relationships."""
    with Session(bind=sqlite_engine) as session:
        yield session


def test_models_metadata_registered():
    """Verify that all 10 tables are registered in Base.metadata."""
    table_names = set(Base.metadata.tables.keys())
    expected_tables = {
        "users",
        "scan_sessions",
        "rooms",
        "captured_images",
        "confirmed_items",
        "cleaning_requirements",
        "cleaning_plans",
        "plan_tasks",
        "task_completions",
        "user_streaks",
    }
    assert expected_tables.issubset(table_names), f"Missing tables: {expected_tables - table_names}"


def test_user_creation_and_relations(db_session: Session):
    """Verify User creation and cascade relationships across the entire tree."""
    user = User(
        firebase_uid="firebase_test_uid_12345",
        display_name="Emma Watson",
        email="emma@example.com",
        timezone="America/New_York",
    )
    db_session.add(user)
    db_session.commit()

    assert user.id is not None
    assert user.firebase_uid == "firebase_test_uid_12345"

    # Add ScanSession
    session = ScanSession(
        user_id=user.id,
        status="in_progress",
        started_at=datetime.utcnow(),
    )
    db_session.add(session)

    # Add Room
    room = Room(
        user_id=user.id,
        scan_session_id=session.id,
        name="Living Room",
        room_type="living_room",
    )
    db_session.add(room)
    db_session.commit()

    # Add CapturedImage
    image = CapturedImage(
        room_id=room.id,
        user_id=user.id,
        scan_session_id=session.id,
        storage_path="scans/session_1/room_1/img_1.jpg",
        width=1920,
        height=1080,
        orientation_degrees=0,
        source_type="camera",
    )
    db_session.add(image)

    # Add ConfirmedItem
    item = ConfirmedItem(
        room_id=room.id,
        user_id=user.id,
        normalized_name="sofa_fabric",
        display_name="Fabric Sofa",
        category="furniture",
        material="fabric",
        provenance="ai_detected",
        confidence=Decimal("0.985"),
        is_confirmed=True,
    )
    db_session.add(item)
    db_session.commit()

    # Add CleaningRequirement
    req = CleaningRequirement(
        confirmed_item_id=item.id,
        user_id=user.id,
        action="vacuum",
        interval_days=7,
        estimated_minutes=15,
        priority="medium",
    )
    db_session.add(req)

    # Add CleaningPlan
    plan = CleaningPlan(
        user_id=user.id,
        status="active",
        plan_version=1,
        accepted_at=datetime.utcnow(),
    )
    db_session.add(plan)
    db_session.commit()

    # Add PlanTask
    task = PlanTask(
        plan_id=plan.id,
        user_id=user.id,
        confirmed_item_id=item.id,
        cleaning_requirement_id=req.id,
        title="Vacuum Fabric Sofa",
        scheduled_date=date(2026, 8, 17),
        estimated_minutes=15,
        status="pending",
        order_index=0,
    )
    db_session.add(task)
    db_session.commit()

    # Add TaskCompletion
    completion = TaskCompletion(
        plan_task_id=task.id,
        user_id=user.id,
        completion_status="completed",
        actual_duration_seconds=780,
        metadata_={"user_feedback": "pacing_accurate"},
    )
    db_session.add(completion)

    # Add UserStreak
    streak = UserStreak(
        user_id=user.id,
        current_streak=3,
        longest_streak=5,
        last_completed_date=date(2026, 8, 16),
        freeze_count=1,
    )
    db_session.add(streak)
    db_session.commit()

    # Query & Verify
    queried_user = db_session.execute(select(User).where(User.firebase_uid == "firebase_test_uid_12345")).scalar_one()
    assert len(queried_user.rooms) == 1
    assert queried_user.rooms[0].name == "Living Room"
    assert len(queried_user.confirmed_items) == 1
    assert queried_user.confirmed_items[0].display_name == "Fabric Sofa"
    assert len(queried_user.cleaning_plans) == 1
    assert len(queried_user.cleaning_plans[0].tasks) == 1
    assert queried_user.cleaning_plans[0].tasks[0].title == "Vacuum Fabric Sofa"
    assert len(queried_user.cleaning_plans[0].tasks[0].completions) == 1
    assert queried_user.cleaning_plans[0].tasks[0].completions[0].actual_duration_seconds == 780
    assert queried_user.streak.current_streak == 3
