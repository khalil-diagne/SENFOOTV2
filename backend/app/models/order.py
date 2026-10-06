import enum
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.user import utcnow


class OrderStatus(str, enum.Enum):
    CREATED = "CREATED"
    PAID_ESCROW = "PAID_ESCROW"
    ACCESS_TRANSFERRED = "ACCESS_TRANSFERRED"
    CONFIRMED_BY_BUYER = "CONFIRMED_BY_BUYER"
    RELEASED_TO_SELLER = "RELEASED_TO_SELLER"
    DISPUTED = "DISPUTED"
    REFUNDED = "REFUNDED"


TERMINAL_ORDER_STATUSES = frozenset(
    {OrderStatus.RELEASED_TO_SELLER, OrderStatus.REFUNDED}
)

OPEN_ORDER_STATUSES = frozenset(
    {
        OrderStatus.CREATED,
        OrderStatus.PAID_ESCROW,
        OrderStatus.ACCESS_TRANSFERRED,
        OrderStatus.CONFIRMED_BY_BUYER,
        OrderStatus.DISPUTED,
    }
)


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    listing_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("listings.id", ondelete="CASCADE"), nullable=False, index=True
    )
    buyer_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    seller_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    price_xof: Mapped[int] = mapped_column(Integer, nullable=False)
    commission_rate: Mapped[Decimal] = mapped_column(Numeric(6, 4), nullable=False)
    commission_xof: Mapped[int | None] = mapped_column(Integer, nullable=True)
    status: Mapped[OrderStatus] = mapped_column(
        Enum(OrderStatus, name="order_status"), default=OrderStatus.CREATED, nullable=False
    )
    payment_provider: Mapped[str | None] = mapped_column(String(50), nullable=True)
    payment_reference: Mapped[str | None] = mapped_column(String(100), nullable=True)
    escrow_released_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    auto_release_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    dispute_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    resolution_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False
    )

    listing = relationship("Listing", back_populates="orders", lazy="selectin")
    buyer = relationship("User", back_populates="orders_as_buyer", foreign_keys=[buyer_id], lazy="selectin")
    seller = relationship("User", back_populates="orders_as_seller", foreign_keys=[seller_id], lazy="selectin")
    events = relationship(
        "OrderEvent",
        back_populates="order",
        lazy="selectin",
        order_by="OrderEvent.created_at",
        cascade="all, delete-orphan",
    )
    messages = relationship(
        "Message",
        back_populates="order",
        lazy="selectin",
        order_by="Message.created_at",
        cascade="all, delete-orphan",
    )
    reviews = relationship(
        "Review", back_populates="order", lazy="selectin", cascade="all, delete-orphan"
    )


class OrderEvent(Base):
    __tablename__ = "order_events"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    order_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("orders.id", ondelete="CASCADE"), nullable=False, index=True
    )
    from_status: Mapped[str | None] = mapped_column(String(30), nullable=True)
    to_status: Mapped[str] = mapped_column(String(30), nullable=False)
    actor_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    actor_role: Mapped[str] = mapped_column(String(20), nullable=False)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)

    order = relationship("Order", back_populates="events")
