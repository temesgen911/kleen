"""Application configuration settings."""

from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "kleenai Backend"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"

    # Supabase PostgreSQL Database Settings
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/cleaning_ai"
    SYNC_DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/cleaning_ai"

    # Supabase Project Settings
    SUPABASE_URL: str = "https://jccjchbpwgcjscfklfpn.supabase.co"
    SUPABASE_SERVICE_ROLE_KEY: str = ""

    # Firebase Authentication
    FIREBASE_PROJECT_ID: str = "kleenai"
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    FIREBASE_CREDENTIALS_JSON: Optional[str] = None

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
