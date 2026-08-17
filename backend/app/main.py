"""FastAPI main application entrypoint."""

import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.firebase import initialize_firebase

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown lifespan context."""
    logger.info("Initializing kleenai Backend...")
    try:
        initialize_firebase()
        logger.info(f"Firebase Admin SDK initialized (Project: {settings.FIREBASE_PROJECT_ID}).")
    except Exception as e:
        logger.warning(f"Firebase Admin SDK deferred initialization: {e}")
    yield
    logger.info("kleenai Backend shutting down...")


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Public Health Endpoint
@app.get("/health", tags=["Health"])
async def health_check():
    """Service health and connectivity status."""
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "environment": settings.ENVIRONMENT,
        "supabase_connected": bool(settings.SUPABASE_URL),
        "firebase_project": settings.FIREBASE_PROJECT_ID,
    }


# Root Entrypoint
@app.get("/", tags=["Root"])
async def root():
    """Root entrypoint."""
    return {
        "message": f"Welcome to {settings.PROJECT_NAME}",
        "docs": "/docs",
        "health": "/health",
        "api_v1": f"{settings.API_V1_STR}/me",
    }


# Mount API v1 Router
app.include_router(api_router, prefix=settings.API_V1_STR)
