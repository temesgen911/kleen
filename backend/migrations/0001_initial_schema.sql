-- =============================================================================
-- Migration: 0001_initial_schema.sql
-- Description: Initial PostgreSQL Schema for Cleaning AI on Supabase
-- Author: Cleaning AI Backend
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- Shared Utility Functions & Triggers
-- =============================================================================

-- Automatic updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 1. USERS TABLE
-- Firebase Authentication is the single external source of truth.
-- firebase_uid is the immutable external identity key.
-- =============================================================================

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid TEXT UNIQUE NOT NULL,
    display_name TEXT,
    email TEXT,
    timezone TEXT NOT NULL DEFAULT 'UTC',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users (firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 2. SCAN SESSIONS TABLE
-- Represents high-level room scan capture & analysis workflows.
-- =============================================================================

CREATE TABLE IF NOT EXISTS scan_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'analyzed', 'confirmed', 'discarded', 'archived')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scan_sessions_user_id ON scan_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_scan_sessions_status ON scan_sessions (status);
CREATE INDEX IF NOT EXISTS idx_scan_sessions_started_at ON scan_sessions (started_at DESC);

DROP TRIGGER IF EXISTS trg_scan_sessions_updated_at ON scan_sessions;
CREATE TRIGGER trg_scan_sessions_updated_at
    BEFORE UPDATE ON scan_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 3. ROOMS TABLE
-- Persistent rooms owned by a user, optionally linked to their origin scan session.
-- =============================================================================

CREATE TABLE IF NOT EXISTS rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scan_session_id UUID REFERENCES scan_sessions(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    room_type TEXT NOT NULL,
    last_scanned_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rooms_user_id ON rooms (user_id);
CREATE INDEX IF NOT EXISTS idx_rooms_scan_session_id ON rooms (scan_session_id);
CREATE INDEX IF NOT EXISTS idx_rooms_room_type ON rooms (room_type);

DROP TRIGGER IF EXISTS trg_rooms_updated_at ON rooms;
CREATE TRIGGER trg_rooms_updated_at
    BEFORE UPDATE ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 4. CAPTURED IMAGES TABLE
-- Metadata for normalized room photos stored in object storage (Supabase Storage / S3).
-- Raw binary photo bytes are NEVER stored in PostgreSQL.
-- =============================================================================

CREATE TABLE IF NOT EXISTS captured_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scan_session_id UUID REFERENCES scan_sessions(id) ON DELETE SET NULL,
    storage_path TEXT NOT NULL,
    width INTEGER,
    height INTEGER,
    orientation_degrees INTEGER NOT NULL DEFAULT 0 CHECK (orientation_degrees IN (0, 90, 180, 270)),
    source_type TEXT NOT NULL DEFAULT 'camera' CHECK (source_type IN ('camera', 'gallery')),
    captured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_captured_images_room_id ON captured_images (room_id);
CREATE INDEX IF NOT EXISTS idx_captured_images_user_id ON captured_images (user_id);
CREATE INDEX IF NOT EXISTS idx_captured_images_scan_session_id ON captured_images (scan_session_id);

-- =============================================================================
-- 5. CONFIRMED ITEMS TABLE
-- Cleanable items detected by AI or added/modified by the user.
-- =============================================================================

CREATE TABLE IF NOT EXISTS confirmed_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    normalized_name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('furniture', 'appliance', 'surface', 'fixture', 'electronics', 'textiles', 'general')),
    material TEXT,
    provenance TEXT NOT NULL DEFAULT 'ai_detected' CHECK (provenance IN ('ai_detected', 'manual_added', 'user_modified')),
    confidence NUMERIC(4, 3) CHECK (confidence IS NULL OR (confidence >= 0.000 AND confidence <= 1.000)),
    is_confirmed BOOLEAN NOT NULL DEFAULT true,
    source_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_confirmed_items_room_id ON confirmed_items (room_id);
CREATE INDEX IF NOT EXISTS idx_confirmed_items_user_id ON confirmed_items (user_id);
CREATE INDEX IF NOT EXISTS idx_confirmed_items_category ON confirmed_items (category);
CREATE INDEX IF NOT EXISTS idx_confirmed_items_is_confirmed ON confirmed_items (is_confirmed);

DROP TRIGGER IF EXISTS trg_confirmed_items_updated_at ON confirmed_items;
CREATE TRIGGER trg_confirmed_items_updated_at
    BEFORE UPDATE ON confirmed_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 6. CLEANING REQUIREMENTS TABLE
-- Cleaning cadence rules, duration estimates, and priorities for confirmed items.
-- =============================================================================

CREATE TABLE IF NOT EXISTS cleaning_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    confirmed_item_id UUID NOT NULL REFERENCES confirmed_items(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    interval_days INTEGER NOT NULL DEFAULT 7 CHECK (interval_days >= 1),
    estimated_minutes INTEGER NOT NULL DEFAULT 10 CHECK (estimated_minutes >= 1),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    rule_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cleaning_requirements_confirmed_item_id ON cleaning_requirements (confirmed_item_id);
CREATE INDEX IF NOT EXISTS idx_cleaning_requirements_user_id ON cleaning_requirements (user_id);
CREATE INDEX IF NOT EXISTS idx_cleaning_requirements_priority ON cleaning_requirements (priority);

DROP TRIGGER IF EXISTS trg_cleaning_requirements_updated_at ON cleaning_requirements;
CREATE TRIGGER trg_cleaning_requirements_updated_at
    BEFORE UPDATE ON cleaning_requirements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 7. CLEANING PLANS TABLE
-- Weekly or dynamic cleaning plans. Only ONE active plan is permitted per user.
-- =============================================================================

CREATE TABLE IF NOT EXISTS cleaning_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'archived')),
    plan_version INTEGER NOT NULL DEFAULT 1 CHECK (plan_version >= 1),
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cleaning_plans_user_id ON cleaning_plans (user_id);
CREATE INDEX IF NOT EXISTS idx_cleaning_plans_status ON cleaning_plans (status);

-- Partial unique index ensuring at most ONE active plan per user
CREATE UNIQUE INDEX IF NOT EXISTS idx_cleaning_plans_user_active
    ON cleaning_plans (user_id)
    WHERE status = 'active';

DROP TRIGGER IF EXISTS trg_cleaning_plans_updated_at ON cleaning_plans;
CREATE TRIGGER trg_cleaning_plans_updated_at
    BEFORE UPDATE ON cleaning_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 8. PLAN TASKS TABLE
-- Discrete scheduled cleaning tasks tied to specific calendar dates (enables dynamic reshuffling).
-- =============================================================================

CREATE TABLE IF NOT EXISTS plan_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES cleaning_plans(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    confirmed_item_id UUID REFERENCES confirmed_items(id) ON DELETE SET NULL,
    cleaning_requirement_id UUID REFERENCES cleaning_requirements(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    scheduled_date DATE NOT NULL,
    estimated_minutes INTEGER NOT NULL DEFAULT 10 CHECK (estimated_minutes >= 1),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'skipped', 'rescheduled')),
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_plan_tasks_plan_id ON plan_tasks (plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_tasks_user_id ON plan_tasks (user_id);
CREATE INDEX IF NOT EXISTS idx_plan_tasks_scheduled_date ON plan_tasks (scheduled_date);
CREATE INDEX IF NOT EXISTS idx_plan_tasks_status ON plan_tasks (status);
CREATE INDEX IF NOT EXISTS idx_plan_tasks_user_date ON plan_tasks (user_id, scheduled_date);

DROP TRIGGER IF EXISTS trg_plan_tasks_updated_at ON plan_tasks;
CREATE TRIGGER trg_plan_tasks_updated_at
    BEFORE UPDATE ON plan_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 9. TASK COMPLETIONS TABLE
-- Immutable logs recording each completed task session, actual duration, and pacing feedback.
-- =============================================================================

CREATE TABLE IF NOT EXISTS task_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_task_id UUID NOT NULL REFERENCES plan_tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completion_status TEXT NOT NULL DEFAULT 'completed' CHECK (completion_status IN ('completed', 'partial', 'skipped')),
    actual_duration_seconds INTEGER CHECK (actual_duration_seconds IS NULL OR actual_duration_seconds >= 0),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_task_completions_plan_task_id ON task_completions (plan_task_id);
CREATE INDEX IF NOT EXISTS idx_task_completions_user_id ON task_completions (user_id);
CREATE INDEX IF NOT EXISTS idx_task_completions_completed_at ON task_completions (completed_at DESC);

-- =============================================================================
-- 10. USER STREAKS TABLE
-- Tracks daily reset streaks (consecutive calendar days where all scheduled tasks were completed).
-- =============================================================================

CREATE TABLE IF NOT EXISTS user_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    current_streak INTEGER NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
    longest_streak INTEGER NOT NULL DEFAULT 0 CHECK (longest_streak >= 0),
    last_completed_date DATE,
    freeze_count INTEGER NOT NULL DEFAULT 0 CHECK (freeze_count >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_streaks_user_id ON user_streaks (user_id);

DROP TRIGGER IF EXISTS trg_user_streaks_updated_at ON user_streaks;
CREATE TRIGGER trg_user_streaks_updated_at
    BEFORE UPDATE ON user_streaks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) - DEFENSE IN DEPTH
-- Anonymous and direct public access is denied by default.
-- All database access is conducted by the secure server-authenticated FastAPI backend.
-- =============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;

ALTER TABLE scan_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE scan_sessions FORCE ROW LEVEL SECURITY;

ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms FORCE ROW LEVEL SECURITY;

ALTER TABLE captured_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE captured_images FORCE ROW LEVEL SECURITY;

ALTER TABLE confirmed_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE confirmed_items FORCE ROW LEVEL SECURITY;

ALTER TABLE cleaning_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleaning_requirements FORCE ROW LEVEL SECURITY;

ALTER TABLE cleaning_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleaning_plans FORCE ROW LEVEL SECURITY;

ALTER TABLE plan_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_tasks FORCE ROW LEVEL SECURITY;

ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_completions FORCE ROW LEVEL SECURITY;

ALTER TABLE user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_streaks FORCE ROW LEVEL SECURITY;

-- Note: The FastAPI backend connects with PostgreSQL superuser or service_role credentials
-- which bypass RLS for trusted, Firebase-token-verified API operations.
-- Direct anon/public role requests over Supabase PostgREST have 0 policies granted and are safely rejected.
