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
      ↓ (Firebase ID Token in Authorization: Bearer <token>)
[FastAPI Backend] (verifies Firebase token via Firebase Admin SDK)
      ↓ (derives verified firebase_uid -> synchronizes users row)
[Supabase PostgreSQL]
```

---

## 2. Firebase Authentication Configuration

Firebase Authentication is the sole user identity provider. FastAPI verifies ID tokens on incoming requests, derives the authenticated `firebase_uid`, and automatically provisions/synchronizes corresponding profile rows in the PostgreSQL `users` table.

### Environment Variables for Firebase

| Variable | Description | Where to use |
|---|---|---|
| `FIREBASE_PROJECT_ID` | Your Firebase Project ID (`kleenai`). | Local & Render |
| `FIREBASE_CREDENTIALS_PATH` | Path to your downloaded service account JSON key file (e.g. `./firebase-credentials.json`). | Local development only (never commit this file) |
| `FIREBASE_CREDENTIALS_JSON` | Minified raw JSON string of your service account key. | Render / Cloud hosting / CI secret |

#### How to Obtain Firebase Service Account Key:
1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Select project **kleenai**.
3. Go to **Project Settings** (gear icon) → **Service accounts**.
4. Click **Generate new private key** and download the JSON file.
5. **For Local Dev:** Place it at `backend/firebase-credentials.json` (already in `.gitignore`) and set `FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json` in `backend/.env`.
6. **For Render Deployment:** Copy the entire JSON content and paste it into the `FIREBASE_CREDENTIALS_JSON` environment variable in Render's dashboard.

---

## 3. Endpoints

### Public Endpoints
- `GET /health`: Returns service health, environment status, and active Firebase project name.
- `GET /`: API entrypoint and documentation links.
- `GET /docs`: Interactive Swagger UI documentation.
- `GET /redoc`: ReDoc API documentation.

### Authenticated Endpoints (`Authorization: Bearer <firebase_id_token>`)
- `GET /api/v1/me`: Returns the verified user's profile from PostgreSQL:
  ```json
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "firebaseUid": "firebase_user_uid_123",
    "email": "user@example.com",
    "displayName": "Emma Watson",
    "timezone": "UTC",
    "createdAt": "2026-08-17T11:45:00Z",
    "updatedAt": "2026-08-17T11:45:00Z"
  }
  ```

---

## 4. Local Backend Setup

### Prerequisites
- Python 3.9+ / 3.11+
- Virtualenv

### Installation
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Environment Variables (`backend/.env`)
```env
ENVIRONMENT=development
PROJECT_NAME="Cleaning AI Backend"
SUPABASE_URL=https://jccjchbpwgcjscfklfpn.supabase.co

# Supabase Shared Pooler Connection Strings (EU-West-1)
DATABASE_URL=postgresql+asyncpg://postgres.jccjchbpwgcjscfklfpn:[YOUR_PASSWORD]@aws-1-eu-west-1.pooler.supabase.com:6543/postgres
SYNC_DATABASE_URL=postgresql://postgres.jccjchbpwgcjscfklfpn:[YOUR_PASSWORD]@aws-1-eu-west-1.pooler.supabase.com:5432/postgres

# Firebase Authentication
FIREBASE_PROJECT_ID=kleenai
FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json
FIREBASE_CREDENTIALS_JSON=
```

### Running Tests
```bash
.venv/bin/python -m pytest tests/
```

### Running API Server
```bash
.venv/bin/uvicorn app.main:app --reload --port 8000
```
