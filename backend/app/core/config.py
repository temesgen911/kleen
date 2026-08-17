"""Application configuration settings."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Cleaning AI Backend"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"

    # Supabase PostgreSQL Database Settings
    # Format: postgresql+asyncpg://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres
    # Direct/Sync Format: postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/cleaning_ai"
    SYNC_DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/cleaning_ai"

    # Supabase Project Settings
    SUPABASE_URL: str = "https://jccjchbpwgcjscfklfpn.supabase.co"
    SUPABASE_SERVICE_ROLE_KEY: str = ""

    # Firebase Authentication
    FIREBASE_PROJECT_ID: str = ""
    FIREBASE_CREDENTIALS_PATH: str = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
