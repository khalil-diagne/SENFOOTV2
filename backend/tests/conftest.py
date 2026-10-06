import os

os.environ.setdefault("DATABASE_URL", "sqlite://")
os.environ.setdefault("SECRET_KEY", "test-secret-key-efoot-mvp-32bytes-min!!")
os.environ.setdefault("COMMISSION_RATE", "0.08")
os.environ.setdefault("AUTO_RELEASE_HOURS", "72")
os.environ.setdefault("PAYTECH_WEBHOOK_SECRET", "test-webhook-secret")
os.environ.setdefault("UPLOAD_DIR", "uploads_test")

import uuid
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.core.rate_limit import login_limiter, register_limiter
from app.core.security import create_access_token, hash_password
from app.main import app
from app.models.listing import Listing, ListingStatus, Platform
from app.models.user import User, UserRole


@pytest.fixture()
def db_session() -> Generator[Session, None, None]:
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    yield session
    session.close()
    Base.metadata.drop_all(bind=engine)


@pytest.fixture(autouse=True)
def reset_rate_limiters():
    login_limiter._hits.clear()
    register_limiter._hits.clear()
    yield
    login_limiter._hits.clear()
    register_limiter._hits.clear()


@pytest.fixture()
def client(db_session: Session) -> Generator[TestClient, None, None]:
    def override_get_db() -> Generator[Session, None, None]:
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def create_user(
    db: Session,
    role: UserRole = UserRole.buyer,
    email: str | None = None,
    username: str | None = None,
    password: str = "password123",
) -> User:
    suffix = uuid.uuid4().hex[:8]
    user = User(
        email=email or f"{role.value}-{suffix}@test.sn",
        username=username or f"{role.value}_{suffix}",
        full_name=f"Test {role.value}",
        hashed_password=hash_password(password),
        role=role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def auth_headers(user: User) -> dict[str, str]:
    token = create_access_token(user.id)
    return {"Authorization": f"Bearer {token}"}


def create_listing(
    db: Session,
    seller: User,
    price_xof: int = 12345,
    status: ListingStatus = ListingStatus.active,
    title: str = "Compte puissance 3200",
) -> Listing:
    listing = Listing(
        seller_id=seller.id,
        title=title,
        description="Compte eFootball avec Mbappé, Messi épique et forte puissance.",
        price_xof=price_xof,
        platform=Platform.mobile,
        team_strength=3200,
        account_level=45,
        status=status,
    )
    db.add(listing)
    db.commit()
    db.refresh(listing)
    return listing


def create_order_via_api(client: TestClient, buyer: User, listing: Listing) -> dict:
    response = client.post(
        "/api/v1/orders",
        json={"listing_id": str(listing.id)},
        headers=auth_headers(buyer),
    )
    assert response.status_code == 201, response.text
    return response.json()


def advance_order_to_paid(client: TestClient, buyer: User, order_id: str) -> dict:
    response = client.post(
        f"/api/v1/orders/{order_id}/pay",
        json={"phone": "+221770000000"},
        headers=auth_headers(buyer),
    )
    assert response.status_code == 200, response.text
    return response.json()
