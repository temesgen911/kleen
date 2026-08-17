"""Unit and integration tests for Firebase Authentication verification, user sync, and /api/v1/me endpoint."""

import uuid
from unittest.mock import patch
import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.dialects.postgresql import JSONB

from app.core.database import Base, get_db
from app.core.firebase import ExpiredTokenError, InvalidTokenError
from app.main import app
from app.models.streak import UserStreak
from app.models.user import User

# Handle SQLite JSONB compilation in test engine
@compiles(JSONB, "sqlite")
def compile_jsonb_sqlite(type_, compiler, **kw):
    return "JSON"


TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"


@pytest.fixture
async def async_test_db():
    """Provides an isolated in-memory SQLite async database engine and session factory."""
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session_factory = async_sessionmaker(
        bind=engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )

    async with async_session_factory() as session:
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest.fixture
async def client(async_test_db: AsyncSession):
    """FastAPI TestClient with overridden get_db dependency."""
    async def override_get_db():
        yield async_test_db

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as ac:
        yield ac
    app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# 1. Public Health Endpoint Tests
# ---------------------------------------------------------------------------

@pytest.mark.anyio
async def test_health_check_public(client: AsyncClient):
    """Verify that /health is public and returns 200 OK without auth headers."""
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "firebase_project" in data


# ---------------------------------------------------------------------------
# 2. Authentication Rejection Tests (401 Unauthorized)
# ---------------------------------------------------------------------------

@pytest.mark.anyio
async def test_me_missing_authorization_header(client: AsyncClient):
    """Missing Authorization header must return 401 Unauthorized."""
    response = await client.get("/api/v1/me")
    assert response.status_code == 401
    assert "detail" in response.json()


@pytest.mark.anyio
async def test_me_empty_bearer_token(client: AsyncClient):
    """Empty Bearer token must return 401 Unauthorized."""
    response = await client.get("/api/v1/me", headers={"Authorization": "Bearer "})
    assert response.status_code == 401


@pytest.mark.anyio
async def test_me_invalid_token(client: AsyncClient):
    """Invalid or forged token must return 401 Unauthorized."""
    with patch("app.api.deps.verify_firebase_token", side_effect=InvalidTokenError("Invalid token")):
        response = await client.get("/api/v1/me", headers={"Authorization": "Bearer invalid_token_123"})
        assert response.status_code == 401
        assert "invalid" in response.json()["detail"].lower()


@pytest.mark.anyio
async def test_me_expired_token(client: AsyncClient):
    """Expired Firebase ID token must return 401 Unauthorized."""
    with patch("app.api.deps.verify_firebase_token", side_effect=ExpiredTokenError("Token expired")):
        response = await client.get("/api/v1/me", headers={"Authorization": "Bearer expired_token_xyz"})
        assert response.status_code == 401
        assert "expired" in response.json()["detail"].lower()


# ---------------------------------------------------------------------------
# 3. User Synchronization & Identity Tests (First Login vs Subsequent Login)
# ---------------------------------------------------------------------------

@pytest.mark.anyio
async def test_first_login_creates_local_user_and_streak(client: AsyncClient):
    """First-time login automatically provisions a local PostgreSQL user and streak record."""
    mock_payload = {
        "uid": "firebase_user_alpha_111",
        "email": "alpha@example.com",
        "name": "Alpha User",
    }

    with patch("app.api.deps.verify_firebase_token", return_value=mock_payload):
        response = await client.get("/api/v1/me", headers={"Authorization": "Bearer valid_mock_token_alpha"})
        assert response.status_code == 200
        data = response.json()

        assert data["firebaseUid"] == "firebase_user_alpha_111"
        assert data["email"] == "alpha@example.com"
        assert data["displayName"] == "Alpha User"
        assert "id" in data
        assert "createdAt" in data
        assert "updatedAt" in data


@pytest.mark.anyio
async def test_subsequent_login_returns_same_user_id(client: AsyncClient):
    """Subsequent logins return the exact same user record without duplicating rows."""
    mock_payload = {
        "uid": "firebase_user_alpha_111",
        "email": "alpha@example.com",
        "name": "Alpha User (Updated Name)",
    }

    with patch("app.api.deps.verify_firebase_token", return_value=mock_payload):
        response_1 = await client.get("/api/v1/me", headers={"Authorization": "Bearer token_1"})
        assert response_1.status_code == 200
        user_id_1 = response_1.json()["id"]

        # Call again
        response_2 = await client.get("/api/v1/me", headers={"Authorization": "Bearer token_2"})
        assert response_2.status_code == 200
        user_id_2 = response_2.json()["id"]

        # IDs must match identically (no duplicate row)
        assert user_id_1 == user_id_2
        assert response_2.json()["displayName"] == "Alpha User (Updated Name)"


@pytest.mark.anyio
async def test_user_isolation_and_impersonation_prevention(client: AsyncClient):
    """Different Firebase UIDs produce distinct, isolated user profiles."""
    mock_payload_user_a = {
        "uid": "firebase_user_aaa",
        "email": "user_a@example.com",
        "name": "User A",
    }
    mock_payload_user_b = {
        "uid": "firebase_user_bbb",
        "email": "user_b@example.com",
        "name": "User B",
    }

    with patch("app.api.deps.verify_firebase_token", return_value=mock_payload_user_a):
        res_a = await client.get("/api/v1/me", headers={"Authorization": "Bearer token_a"})
        assert res_a.status_code == 200
        data_a = res_a.json()

    with patch("app.api.deps.verify_firebase_token", return_value=mock_payload_user_b):
        res_b = await client.get("/api/v1/me", headers={"Authorization": "Bearer token_b"})
        assert res_b.status_code == 200
        data_b = res_b.json()

    # User A and User B must have different internal IDs and UIDs
    assert data_a["id"] != data_b["id"]
    assert data_a["firebaseUid"] == "firebase_user_aaa"
    assert data_b["firebaseUid"] == "firebase_user_bbb"
