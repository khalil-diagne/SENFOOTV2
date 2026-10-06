import enum
import uuid
from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, Enum, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.user import utcnow


class Platform(str, enum.Enum):
    ps4 = "ps4"
    ps5 = "ps5"
    xbox = "xbox"
    mobile = "mobile"
    pc = "pc"


class ListingStatus(str, enum.Enum):
    draft = "draft"
    active = "active"
    paused = "paused"
    sold = "sold"
    archived = "archived"


class Listing(Base):
    __tablename__ = "listings"
    __table_args__ = (
        CheckConstraint("price_xof > 0", name="ck_listings_price_positive"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    seller_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    price_xof: Mapped[int] = mapped_column(Integer, nullable=False)
    platform: Mapped[Platform] = mapped_column(Enum(Platform, name="platform"), nullable=False)
    team_strength: Mapped[int | None] = mapped_column(Integer, nullable=True)
    account_level: Mapped[int | None] = mapped_column(Integer, nullable=True)
    status: Mapped[ListingStatus] = mapped_column(
        Enum(ListingStatus, name="listing_status"), default=ListingStatus.active, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False
    )

    seller = relationship("User", back_populates="listings", lazy="selectin")
    images = relationship(
        "ListingImage",
        back_populates="listing",
        lazy="selectin",
        order_by="ListingImage.position",
        cascade="all, delete-orphan",
    )
    orders = relationship("Order", back_populates="listing", lazy="selectin")


class ListingImage(Base):
    __tablename__ = "listing_images"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    listing_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("listings.id", ondelete="CASCADE"), nullable=False, index=True
    )
    url: Mapped[str] = mapped_column(String(500), nullable=False)
    position: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    listing = relationship("Listing", back_populates="images")
