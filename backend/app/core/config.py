from functools import lru_cache
from decimal import Decimal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "EFoot Market SN API"
    secret_key: str = Field(default="dev-secret-change-me")
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7
    commission_rate: Decimal = Decimal("0.08")
    auto_release_hours: int = 72
    database_url: str = "postgresql+psycopg://efoot:efoot@localhost:5432/efoot_market"
    allowed_origins: str = "http://localhost:3000,http://localhost:8080,http://localhost:5273"
    paytech_api_key: str = ""
    paytech_api_secret: str = ""
    paytech_webhook_secret: str = ""
    upload_dir: str = "uploads"

    @property
    def allowed_origins_list(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
