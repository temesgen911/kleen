"""API v1 router configuration."""

from fastapi import APIRouter

from app.api.v1.endpoints import users

api_router = APIRouter()

# Mount user identity routes
api_router.include_router(users.router, tags=["Users"])
