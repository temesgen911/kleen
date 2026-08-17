"""Initial PostgreSQL schema for Cleaning AI

Revision ID: 0001_initial_schema
Revises: 
Create Date: 2026-08-17 11:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Extensions
    op.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"')
    op.execute('CREATE EXTENSION IF NOT EXISTS "pgcrypto"')

    # 1. users
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('firebase_uid', sa.String(), nullable=False),
        sa.Column('display_name', sa.String(), nullable=True),
        sa.Column('email', sa.String(), nullable=True),
        sa.Column('timezone', sa.String(), server_default='UTC', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('firebase_uid')
    )
    op.create_index('idx_users_firebase_uid', 'users', ['firebase_uid'])
    op.create_index('idx_users_email', 'users', ['email'])

    # 2. scan_sessions
    op.create_table(
        'scan_sessions',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('status', sa.String(), server_default='in_progress', nullable=False),
        sa.Column('started_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('metadata', postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.CheckConstraint("status IN ('in_progress', 'analyzed', 'confirmed', 'discarded', 'archived')", name='chk_scan_sessions_status')
    )
    op.create_index('idx_scan_sessions_user_id', 'scan_sessions', ['user_id'])
    op.create_index('idx_scan_sessions_status', 'scan_sessions', ['status'])
    op.create_index('idx_scan_sessions_started_at', 'scan_sessions', ['started_at'])

    # 3. rooms
    op.create_table(
        'rooms',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('scan_session_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('room_type', sa.String(), nullable=False),
        sa.Column('last_scanned_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['scan_session_id'], ['scan_sessions.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_rooms_user_id', 'rooms', ['user_id'])
    op.create_index('idx_rooms_scan_session_id', 'rooms', ['scan_session_id'])
    op.create_index('idx_rooms_room_type', 'rooms', ['room_type'])

    # 4. captured_images
    op.create_table(
        'captured_images',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('room_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('scan_session_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('storage_path', sa.String(), nullable=False),
        sa.Column('width', sa.Integer(), nullable=True),
        sa.Column('height', sa.Integer(), nullable=True),
        sa.Column('orientation_degrees', sa.Integer(), server_default='0', nullable=False),
        sa.Column('source_type', sa.String(), server_default='camera', nullable=False),
        sa.Column('captured_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['room_id'], ['rooms.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['scan_session_id'], ['scan_sessions.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
        sa.CheckConstraint("orientation_degrees IN (0, 90, 180, 270)", name='chk_captured_images_orientation'),
        sa.CheckConstraint("source_type IN ('camera', 'gallery')", name='chk_captured_images_source_type')
    )
    op.create_index('idx_captured_images_room_id', 'captured_images', ['room_id'])
    op.create_index('idx_captured_images_user_id', 'captured_images', ['user_id'])
    op.create_index('idx_captured_images_scan_session_id', 'captured_images', ['scan_session_id'])

    # 5. confirmed_items
    op.create_table(
        'confirmed_items',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('room_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('normalized_name', sa.String(), nullable=False),
        sa.Column('display_name', sa.String(), nullable=False),
        sa.Column('category', sa.String(), nullable=False),
        sa.Column('material', sa.String(), nullable=True),
        sa.Column('provenance', sa.String(), server_default='ai_detected', nullable=False),
        sa.Column('confidence', sa.Numeric(precision=4, scale=3), nullable=True),
        sa.Column('is_confirmed', sa.Boolean(), server_default='true', nullable=False),
        sa.Column('source_metadata', postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['room_id'], ['rooms.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.CheckConstraint("category IN ('furniture', 'appliance', 'surface', 'fixture', 'electronics', 'textiles', 'general')", name='chk_confirmed_items_category'),
        sa.CheckConstraint("provenance IN ('ai_detected', 'manual_added', 'user_modified')", name='chk_confirmed_items_provenance'),
        sa.CheckConstraint("confidence IS NULL OR (confidence >= 0.000 AND confidence <= 1.000)", name='chk_confirmed_items_confidence')
    )
    op.create_index('idx_confirmed_items_room_id', 'confirmed_items', ['room_id'])
    op.create_index('idx_confirmed_items_user_id', 'confirmed_items', ['user_id'])
    op.create_index('idx_confirmed_items_category', 'confirmed_items', ['category'])
    op.create_index('idx_confirmed_items_is_confirmed', 'confirmed_items', ['is_confirmed'])

    # 6. cleaning_requirements
    op.create_table(
        'cleaning_requirements',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('confirmed_item_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('action', sa.String(), nullable=False),
        sa.Column('interval_days', sa.Integer(), server_default='7', nullable=False),
        sa.Column('estimated_minutes', sa.Integer(), server_default='10', nullable=False),
        sa.Column('priority', sa.String(), server_default='medium', nullable=False),
        sa.Column('rule_metadata', postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['confirmed_item_id'], ['confirmed_items.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.CheckConstraint("interval_days >= 1", name='chk_cleaning_requirements_interval'),
        sa.CheckConstraint("estimated_minutes >= 1", name='chk_cleaning_requirements_minutes'),
        sa.CheckConstraint("priority IN ('low', 'medium', 'high', 'critical')", name='chk_cleaning_requirements_priority')
    )
    op.create_index('idx_cleaning_requirements_confirmed_item_id', 'cleaning_requirements', ['confirmed_item_id'])
    op.create_index('idx_cleaning_requirements_user_id', 'cleaning_requirements', ['user_id'])
    op.create_index('idx_cleaning_requirements_priority', 'cleaning_requirements', ['priority'])

    # 7. cleaning_plans
    op.create_table(
        'cleaning_plans',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('status', sa.String(), server_default='draft', nullable=False),
        sa.Column('plan_version', sa.Integer(), server_default='1', nullable=False),
        sa.Column('accepted_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.CheckConstraint("status IN ('draft', 'active', 'archived')", name='chk_cleaning_plans_status'),
        sa.CheckConstraint("plan_version >= 1", name='chk_cleaning_plans_version')
    )
    op.create_index('idx_cleaning_plans_user_id', 'cleaning_plans', ['user_id'])
    op.create_index('idx_cleaning_plans_status', 'cleaning_plans', ['status'])
    op.create_index(
        'idx_cleaning_plans_user_active',
        'cleaning_plans',
        ['user_id'],
        unique=True,
        postgresql_where=sa.text("status = 'active'")
    )

    # 8. plan_tasks
    op.create_table(
        'plan_tasks',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('plan_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('confirmed_item_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('cleaning_requirement_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('scheduled_date', sa.Date(), nullable=False),
        sa.Column('estimated_minutes', sa.Integer(), server_default='10', nullable=False),
        sa.Column('status', sa.String(), server_default='pending', nullable=False),
        sa.Column('order_index', sa.Integer(), server_default='0', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['plan_id'], ['cleaning_plans.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['confirmed_item_id'], ['confirmed_items.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['cleaning_requirement_id'], ['cleaning_requirements.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
        sa.CheckConstraint("estimated_minutes >= 1", name='chk_plan_tasks_minutes'),
        sa.CheckConstraint("status IN ('pending', 'completed', 'skipped', 'rescheduled')", name='chk_plan_tasks_status')
    )
    op.create_index('idx_plan_tasks_plan_id', 'plan_tasks', ['plan_id'])
    op.create_index('idx_plan_tasks_user_id', 'plan_tasks', ['user_id'])
    op.create_index('idx_plan_tasks_scheduled_date', 'plan_tasks', ['scheduled_date'])
    op.create_index('idx_plan_tasks_status', 'plan_tasks', ['status'])
    op.create_index('idx_plan_tasks_user_date', 'plan_tasks', ['user_id', 'scheduled_date'])

    # 9. task_completions
    op.create_table(
        'task_completions',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('plan_task_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('completed_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('completion_status', sa.String(), server_default='completed', nullable=False),
        sa.Column('actual_duration_seconds', sa.Integer(), nullable=True),
        sa.Column('metadata', postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['plan_task_id'], ['plan_tasks.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.CheckConstraint("completion_status IN ('completed', 'partial', 'skipped')", name='chk_task_completions_status'),
        sa.CheckConstraint("actual_duration_seconds IS NULL OR actual_duration_seconds >= 0", name='chk_task_completions_duration')
    )
    op.create_index('idx_task_completions_plan_task_id', 'task_completions', ['plan_task_id'])
    op.create_index('idx_task_completions_user_id', 'task_completions', ['user_id'])
    op.create_index('idx_task_completions_completed_at', 'task_completions', ['completed_at'])

    # 10. user_streaks
    op.create_table(
        'user_streaks',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('current_streak', sa.Integer(), server_default='0', nullable=False),
        sa.Column('longest_streak', sa.Integer(), server_default='0', nullable=False),
        sa.Column('last_completed_date', sa.Date(), nullable=True),
        sa.Column('freeze_count', sa.Integer(), server_default='0', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id'),
        sa.CheckConstraint('current_streak >= 0', name='chk_user_streaks_current'),
        sa.CheckConstraint('longest_streak >= 0', name='chk_user_streaks_longest'),
        sa.CheckConstraint('freeze_count >= 0', name='chk_user_streaks_freeze')
    )
    op.create_index('idx_user_streaks_user_id', 'user_streaks', ['user_id'])


def downgrade() -> None:
    op.drop_table('user_streaks')
    op.drop_table('task_completions')
    op.drop_table('plan_tasks')
    op.drop_table('cleaning_plans')
    op.drop_table('cleaning_requirements')
    op.drop_table('confirmed_items')
    op.drop_table('captured_images')
    op.drop_table('rooms')
    op.drop_table('scan_sessions')
    op.drop_table('users')
