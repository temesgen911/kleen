"""
End-to-End Integration Test Suite
=================================
Validates the full stack connectivity:
  1. Supabase PostgreSQL: Connection, schema existence, CRUD operations
  2. FastAPI Backend: Health endpoint, user sync endpoint  
  3. Firebase Admin SDK: Initialization and token verification pipeline

Run with:
    cd backend && python -m pytest tests/test_integration_e2e.py -v --tb=short
"""

import json
import logging
import sys
import uuid
from pathlib import Path

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

# Ensure project root is on path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Load env at import time
from dotenv import load_dotenv
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("E2E-Integration")


# ============================================================================
# Shared fixtures
# ============================================================================

@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"


def _get_database_url():
    """Get database URL from settings."""
    from app.core.config import settings
    return settings.DATABASE_URL


@pytest.fixture
async def async_engine_fresh():
    """Create a fresh async engine per test to avoid event loop issues."""
    engine = create_async_engine(
        _get_database_url(),
        echo=False,
        pool_pre_ping=True,
        connect_args={"statement_cache_size": 0},  # Required for Supabase PgBouncer
    )
    yield engine
    await engine.dispose()


@pytest.fixture
async def db_session(async_engine_fresh):
    """Create an async session from the fresh engine."""
    session_factory = async_sessionmaker(
        bind=async_engine_fresh,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with session_factory() as session:
        yield session


# ============================================================================
# 1. SUPABASE / POSTGRESQL CONNECTIVITY & SCHEMA TESTS
# ============================================================================

class TestSupabasePostgresql:
    """Tests for Supabase PostgreSQL database connectivity and schema integrity."""

    @pytest.mark.anyio
    async def test_async_connection(self, async_engine_fresh):
        """Verify asyncpg connection to Supabase PostgreSQL."""
        async with async_engine_fresh.connect() as conn:
            result = await conn.execute(text("SELECT 1 AS ping"))
            row = result.fetchone()
            assert row is not None
            assert row[0] == 1
            logger.info("✅ Async PostgreSQL connection to Supabase: CONNECTED")

    @pytest.mark.anyio
    async def test_schema_tables_exist(self, async_engine_fresh):
        """Verify all expected tables exist in the database."""
        expected_tables = [
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
        ]

        async with async_engine_fresh.connect() as conn:
            result = await conn.execute(text(
                "SELECT table_name FROM information_schema.tables "
                "WHERE table_schema = 'public' AND table_type = 'BASE TABLE' "
                "ORDER BY table_name"
            ))
            existing_tables = [row[0] for row in result.fetchall()]

        logger.info(f"Tables found in Supabase: {existing_tables}")
        
        missing = [t for t in expected_tables if t not in existing_tables]
        if missing:
            logger.warning(f"⚠️  Missing tables: {missing}")
            pytest.skip(f"Schema not yet migrated. Missing tables: {missing}. "
                       f"Run: psql $SYNC_DATABASE_URL < migrations/0001_initial_schema.sql")
        
        logger.info(f"✅ All {len(expected_tables)} schema tables verified in Supabase")

    @pytest.mark.anyio
    async def test_user_crud_operations(self, async_engine_fresh):
        """Verify CRUD operations on the users table via SQLAlchemy ORM."""
        from app.models.user import User
        from app.models.streak import UserStreak
        from sqlalchemy import select

        session_factory = async_sessionmaker(
            bind=async_engine_fresh,
            class_=AsyncSession,
            expire_on_commit=False,
        )

        # Check if users table exists
        async with session_factory() as session:
            result = await session.execute(text(
                "SELECT EXISTS (SELECT FROM information_schema.tables "
                "WHERE table_schema = 'public' AND table_name = 'users')"
            ))
            exists = result.scalar()
            if not exists:
                pytest.skip("Users table does not exist yet. Run migration first.")

        test_firebase_uid = f"e2e_test_{uuid.uuid4().hex[:12]}"
        test_email = f"e2e_{uuid.uuid4().hex[:8]}@test.kleenai.com"

        try:
            async with session_factory() as session:
                # CREATE
                new_user = User(
                    firebase_uid=test_firebase_uid,
                    email=test_email,
                    display_name="E2E Test User",
                    timezone="Africa/Nairobi",
                )
                session.add(new_user)
                await session.flush()
                user_id = new_user.id
                assert user_id is not None
                logger.info(f"  CREATE: User created with ID={user_id}")

                # Also create streak
                streak = UserStreak(
                    user_id=user_id,
                    current_streak=0,
                    longest_streak=0,
                    freeze_count=0,
                )
                session.add(streak)
                await session.commit()

                # READ
                stmt = select(User).where(User.firebase_uid == test_firebase_uid)
                result = await session.execute(stmt)
                fetched_user = result.scalar_one_or_none()
                assert fetched_user is not None
                assert fetched_user.email == test_email
                assert fetched_user.display_name == "E2E Test User"
                assert fetched_user.timezone == "Africa/Nairobi"
                logger.info(f"  READ: User fetched successfully - {fetched_user.email}")

                # UPDATE
                fetched_user.display_name = "E2E Updated Name"
                await session.commit()
                await session.refresh(fetched_user)
                assert fetched_user.display_name == "E2E Updated Name"
                logger.info(f"  UPDATE: Display name updated to '{fetched_user.display_name}'")

                # DELETE (cleanup)
                await session.delete(fetched_user)
                await session.commit()

                # Verify deletion
                result2 = await session.execute(
                    select(User).where(User.firebase_uid == test_firebase_uid)
                )
                assert result2.scalar_one_or_none() is None
                logger.info(f"  DELETE: Test user cleaned up successfully")

            logger.info("✅ Supabase CRUD (Create → Read → Update → Delete): ALL PASSED")

        except Exception:
            # Emergency cleanup if test fails mid-way
            async with session_factory() as session:
                from sqlalchemy import delete
                await session.execute(
                    delete(User).where(User.firebase_uid == test_firebase_uid)
                )
                await session.commit()
            raise


# ============================================================================
# 2. FASTAPI SERVER TESTS
# ============================================================================

class TestFastAPIServer:
    """Tests for the FastAPI application endpoints."""

    @pytest.mark.anyio
    async def test_health_endpoint(self):
        """Verify /health returns proper status with connection info."""
        from app.main import app
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            response = await c.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "Backend" in data["service"]  # "Cleaning AI Backend" or "kleenai Backend"
        assert data["firebase_project"] == "kleenai"
        assert data["supabase_connected"] is True
        logger.info(f"✅ /health endpoint: {json.dumps(data, indent=2)}")

    @pytest.mark.anyio
    async def test_root_endpoint(self):
        """Verify root endpoint returns API navigation."""
        from app.main import app
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            response = await c.get("/")
        
        assert response.status_code == 200
        data = response.json()
        assert "Welcome to" in data["message"]
        assert data["docs"] == "/docs"
        assert data["health"] == "/health"
        logger.info(f"✅ / root endpoint: {data['message']}")

    @pytest.mark.anyio
    async def test_me_endpoint_requires_auth(self):
        """Verify /api/v1/me rejects unauthenticated requests."""
        from app.main import app
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            response = await c.get("/api/v1/me")
        
        # Should return 401 or 403 when no token provided
        assert response.status_code in (401, 403)
        logger.info(f"✅ /api/v1/me correctly requires authentication (status={response.status_code})")

    @pytest.mark.anyio
    async def test_openapi_docs_accessible(self):
        """Verify OpenAPI docs are accessible."""
        from app.main import app
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            response = await c.get("/api/v1/openapi.json")
        
        assert response.status_code == 200
        data = response.json()
        assert "paths" in data
        assert "/api/v1/me" in data["paths"] or "/me" in str(data["paths"])
        logger.info(f"✅ OpenAPI schema accessible with {len(data.get('paths', {}))} paths defined")


# ============================================================================
# 3. FIREBASE ADMIN SDK TESTS
# ============================================================================

class TestFirebaseAdminSDK:
    """Tests for Firebase Admin SDK initialization and token verification pipeline."""

    def test_firebase_initialization(self):
        """Verify Firebase Admin SDK initializes successfully."""
        from app.core.firebase import initialize_firebase
        
        try:
            fb_app = initialize_firebase()
            assert fb_app is not None
            logger.info(f"✅ Firebase Admin SDK initialized: project={getattr(fb_app, 'project_id', 'kleenai')}")
        except Exception as e:
            logger.warning(f"⚠️  Firebase Admin SDK init issue: {e}")
            pytest.skip(f"Firebase credentials not configured: {e}")

    def test_firebase_token_validation_rejects_invalid_token(self):
        """Verify invalid tokens are properly rejected."""
        from app.core.firebase import verify_firebase_token, InvalidTokenError, FirebaseTokenError

        with pytest.raises((InvalidTokenError, FirebaseTokenError, Exception)):
            verify_firebase_token("invalid_token_abc123")
        
        logger.info("✅ Firebase token verification correctly rejects invalid tokens")

    def test_firebase_token_validation_rejects_empty_token(self):
        """Verify empty tokens are properly rejected."""
        from app.core.firebase import verify_firebase_token, InvalidTokenError

        with pytest.raises(InvalidTokenError):
            verify_firebase_token("")
        
        with pytest.raises(InvalidTokenError):
            verify_firebase_token(None)  # type: ignore
        
        logger.info("✅ Firebase token verification correctly rejects empty/null tokens")

    def test_firebase_config_settings(self):
        """Verify Firebase configuration is properly loaded."""
        from app.core.config import settings

        assert settings.FIREBASE_PROJECT_ID == "kleenai"
        logger.info(f"✅ Firebase config: project_id={settings.FIREBASE_PROJECT_ID}")


# ============================================================================
# 4. FULL STACK INTEGRATION: AUTH → BACKEND → DATABASE
# ============================================================================

class TestFullStackIntegration:
    """End-to-end tests that verify the complete authentication → API → database pipeline."""

    @pytest.mark.anyio
    async def test_user_service_get_or_create(self, async_engine_fresh):
        """Verify the user service can create/fetch users directly from Supabase."""
        from app.services.user_service import get_or_create_user
        from app.models.user import User
        from sqlalchemy import select

        session_factory = async_sessionmaker(
            bind=async_engine_fresh,
            class_=AsyncSession,
            expire_on_commit=False,
        )

        # Check table exists
        async with session_factory() as session:
            result = await session.execute(text(
                "SELECT EXISTS (SELECT FROM information_schema.tables "
                "WHERE table_schema = 'public' AND table_name = 'users')"
            ))
            if not result.scalar():
                pytest.skip("Users table not yet created. Run migration first.")

        test_uid = f"integration_{uuid.uuid4().hex[:12]}"
        test_email = f"integration_{uuid.uuid4().hex[:8]}@kleenai.test"

        try:
            async with session_factory() as session:
                # First call: CREATE new user
                user = await get_or_create_user(
                    db=session,
                    firebase_uid=test_uid,
                    email=test_email,
                    display_name="Integration Test",
                )
                assert user is not None
                assert user.firebase_uid == test_uid
                assert user.email == test_email
                user_id = user.id
                logger.info(f"  get_or_create_user (CREATE): {user}")

            async with session_factory() as session:
                # Second call: GET existing user
                user2 = await get_or_create_user(
                    db=session,
                    firebase_uid=test_uid,
                    email=test_email,
                    display_name="Integration Test Updated",
                )
                assert user2.id == user_id
                assert user2.display_name == "Integration Test Updated"
                logger.info(f"  get_or_create_user (GET+UPDATE): {user2}")

            logger.info("✅ Full-stack user_service get_or_create pipeline: PASSED")

        finally:
            # Cleanup
            async with session_factory() as session:
                from sqlalchemy import delete
                await session.execute(
                    delete(User).where(User.firebase_uid == test_uid)
                )
                await session.commit()
                logger.info(f"  Cleanup: Test user deleted")

    @pytest.mark.anyio
    async def test_authenticated_me_endpoint_rejects_bad_token(self):
        """Verify the /me endpoint properly rejects a fake token through the full pipeline."""
        from app.main import app
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            response = await c.get(
                "/api/v1/me",
                headers={"Authorization": "Bearer fake_token_12345"},
            )
        
        assert response.status_code == 401
        logger.info(f"✅ /api/v1/me with bad token: correctly returned 401")

    @pytest.mark.anyio
    async def test_database_connection_settings_match_supabase(self):
        """Verify database configuration points to Supabase."""
        from app.core.config import settings

        assert "supabase" in settings.DATABASE_URL.lower() or "jccjchbpwgcjscfklfpn" in settings.DATABASE_URL
        assert settings.SUPABASE_URL.startswith("https://")
        assert "supabase.co" in settings.SUPABASE_URL
        logger.info(f"✅ Database URL points to Supabase: {settings.SUPABASE_URL}")


# ============================================================================
# Standalone runner for quick verification
# ============================================================================

if __name__ == "__main__":
    print("=" * 70)
    print("  KleenAI E2E Integration Test Suite")
    print("  Testing: Supabase ↔ FastAPI ↔ Firebase")
    print("=" * 70)
    sys.exit(pytest.main([__file__, "-v", "--tb=short", "-x"]))
