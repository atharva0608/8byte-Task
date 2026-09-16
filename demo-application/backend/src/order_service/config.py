from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field
from typing import Optional

class Settings(BaseSettings):
    app_name: str = "Demo Order Management API"
    app_env: str = "development"
    log_level: str = "INFO"
    cors_origins: str = "*"

    # Database configuration (injected via environment in production)
    db_host: str = "localhost"
    db_port: int = 5432
    db_user: str = "postgres"
    db_password: str = "postgres"
    db_name: str = "demoapp"

    @property
    def database_url(self) -> str:
        # Build the connection string for SQLAlchemy
        return f"postgresql://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()
