"""API v1 router configuration."""

from fastapi import APIRouter

from app.api.v1.endpoints import plans, users, vision

api_router = APIRouter()

# Mount routes
api_router.include_router(users.router, tags=["Users"])
api_router.include_router(plans.router, tags=["Cleaning Plans"])
api_router.include_router(vision.router, prefix="/vision", tags=["Vision AI"])

