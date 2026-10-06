import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.models.order import OrderStatus


class OrderCreate(BaseModel):
    listing_id: uuid.UUID


class PayRequest(BaseModel):
    phone: str | None = Field(default=None, max_length=20)


class TransferAccessRequest(BaseModel):
    note: str | None = Field(default=None, max_length=1000)


class ConfirmRequest(BaseModel):
    note: str | None = Field(default=None, max_length=1000)


class DisputeRequest(BaseModel):
    reason: str = Field(min_length=10, max_length=2000)


class ResolveRequest(BaseModel):
    action: str = Field(pattern="^(refund|release)$")
    resolution_note: str = Field(min_length=5, max_length=2000)


class OrderEventOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    from_status: str | None
    to_status: str
    actor_id: uuid.UUID | None
    actor_role: str
    note: str | None
    created_at: datetime


class OrderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    listing_id: uuid.UUID
    buyer_id: uuid.UUID
    seller_id: uuid.UUID
    price_xof: int
    commission_rate: Decimal
    commission_xof: int | None
    status: OrderStatus
    payment_provider: str | None
    payment_reference: str | None
    escrow_released_at: datetime | None
    auto_release_at: datetime | None
    dispute_reason: str | None
    resolution_note: str | None
    created_at: datetime
    updated_at: datetime


class OrderDetailOut(OrderOut):
    events: list[OrderEventOut]
