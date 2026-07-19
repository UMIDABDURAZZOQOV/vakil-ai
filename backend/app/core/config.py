from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Vakil AI API"
    secret_key: str = "dev-only-insecure-secret-change-me"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 10080  # 7 days

    database_url: str = "sqlite+aiosqlite:///./vakil_ai.db"

    # Comma-separated list of allowed web origins, or "*" for any (dev only).
    allowed_origins: str = "*"

    gemini_api_key: str | None = None
    free_tier_document_limit: int = 2

    upload_dir: str = "uploads"

    telegram_bot_token: str | None = None

    payme_merchant_id: str | None = None
    payme_secret_key: str | None = None
    payme_test_mode: bool = True

    click_service_id: str | None = None
    click_merchant_id: str | None = None
    click_secret_key: str | None = None

    premium_price_uzs: float = 49000.0


@lru_cache
def get_settings() -> Settings:
    return Settings()
