# Cleaning AI — Backend & Supabase Database Foundation

This service is the backend API and persistence layer for the Cleaning AI Flutter mobile app.

---

## 1. Architecture Overview

- **Database**: Supabase PostgreSQL (`https://jccjchbpwgcjscfklfpn.supabase.co`)
- **Backend**: Python FastAPI + SQLAlchemy 2.0 ORM + Alembic
- **Authentication**: **Firebase Authentication** (Single source of truth — Supabase Auth is NOT used)
- **Object Storage**: Supabase Storage / S3 (image paths recorded in `captured_images.storage_path`)

```text
[Flutter Client] 
      ↓ (Firebase ID Token)
[FastAPI Backend] 
      ↓ (Secure Server Connection / Service Role)
[Supabase PostgreSQL]
```

---

## 2. Supabase Setup Checklist (Quick Start)

To apply the database schema to your Supabase project:

### Step 1: Open Supabase SQL Editor
1. Go to your Supabase Dashboard: [https://supabase.com/dashboard/project/jccjchbpwgcjscfklfpn](https://supabase.com/dashboard/project/jccjchbpwgcjscfklfpn)
2. In the left navigation, click on **SQL Editor** (`>_`).
3. Click **+ New Query**.

### Step 2: Run the Initial Migration Script
Copy and paste the complete content of [`migrations/0001_initial_schema.sql`](migrations/0001_initial_schema.sql) into the SQL editor and click **Run** (or `Cmd + Enter`).

### Step 3: Verify the Schema in Supabase Table Editor
After running the script, verify that all **10 tables** appear in the **Table Editor**:
1. `users` — Stores Firebase UID external identity key (`firebase_uid`), timezone, display name.
2. `scan_sessions` — Tracks multi-room scanning workflows and state (`in_progress`, `analyzed`, `confirmed`).
3. `rooms` — User rooms (`Living Room`, `Kitchen`, etc.) linked to scan sessions.
4. `captured_images` — Image metadata, dimensions, orientation, and storage paths (raw bytes are NOT in SQL).
5. `confirmed_items` — Cleanable objects detected by AI or added by users.
6. `cleaning_requirements` — Cleaning actions, recurring intervals (`interval_days`), duration estimates, and priorities.
7. `cleaning_plans` — Cleaning plans with partial unique index enforcing only **1 active plan per user**.
8. `plan_tasks` — Discrete cleaning tasks assigned to specific **calendar dates** (`scheduled_date`).
9. `task_completions` — Immutable completion logs, timer durations, and pacing adjustment metrics.
10. `user_streaks` — Consecutive daily reset streak counters and milestones.

---

## 3. Row Level Security (RLS) & Defense in Depth

- RLS is **enabled and enforced** (`FORCE ROW LEVEL SECURITY`) on all user-owned tables.
- Because authentication is handled via **Firebase Auth**, direct anonymous/public PostgREST access via the Supabase client is denied by default.
- The FastAPI backend connects using server-level PostgreSQL connection credentials (`service_role` or database password), maintaining security while allowing token-verified API operations.

---

## 4. Local Backend Setup

### Prerequisites
- Python 3.11+
- Virtualenv

### Installation
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Environment Variables (`backend/.env`)
Create a `.env` file in the `backend/` directory:
```env
ENVIRONMENT=development
PROJECT_NAME="Cleaning AI Backend"
SUPABASE_URL=https://jccjchbpwgcjscfklfpn.supabase.co

# Supabase PostgreSQL Connection String
# Find this in Supabase Dashboard -> Project Settings -> Database -> Connection string (URI)
DATABASE_URL=postgresql+asyncpg://postgres.[PROJECT_REF]:[YOUR_PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
SYNC_DATABASE_URL=postgresql://postgres.[PROJECT_REF]:[YOUR_PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres

# Firebase Admin SDK Configuration
FIREBASE_PROJECT_ID=cleaning-ai-app
FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json
```

### Running Migrations via Alembic (Optional Alternative to SQL Editor)
```bash
alembic upgrade head
```

### Running the API Server
```bash
uvicorn app.main:app --reload --port 8000
```
- API Docs: `http://localhost:8000/docs`
- Healthcheck: `http://localhost:8000/health`
