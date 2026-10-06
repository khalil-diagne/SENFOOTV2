import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.listing import ListingStatus, Platform
from app.schemas.auth import SellerPublic


class ListingImageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    url: str
    position: int


class ListingCreate(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    description: str = Field(min_length=10, max_length=5000)
    price_xof: int = Field(gt=0)
    platform: Platform
    team_strength: int | None = Field(default=None, ge=0, le=9999)
    account_level: int | None = Field(default=None, ge=0, le=999)
    status: ListingStatus = ListingStatus.active
    image_urls: list[str] = Field(default_factory=list, max_length=10)


class ListingUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=3, max_length=200)
    description: str | None = Field(default=None, min_length=10, max_length=5000)
    price_xof: int | None = Field(default=None, gt=0)
    platform: Platform | None = None
    team_strength: int | None = Field(default=None, ge=0, le=9999)
    account_level: int | None = Field(default=None, ge=0, le=999)
    status: ListingStatus | None = None


class ListingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    seller_id: uuid.UUID
    title: str
    description: str
    price_xof: int
    platform: Platform
    team_strength: int | None
    account_level: int | None
    status: ListingStatus
    images: list[ListingImageOut]
    seller: SellerPublic | None
    created_at: datetime
    updated_at: datetime


class ListingPage(BaseModel):
    items: list[ListingOut]
    total: int
    page: int
    page_size: int
