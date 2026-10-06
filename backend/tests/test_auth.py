import hashlib
import hmac
import json
import uuid

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.order import Order
from app.models.user import User, UserRole
from tests.conftest import auth_headers, create_listing, create_user


def _register(client: TestClient, email: str, username: str, role: str = "buyer") -> dict:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "username": username,
            "full_name": "Utilisateur Test",
            "password": "password123",
            "role": role,
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_register_login_and_refresh(client: TestClient) -> None:
    suffix = uuid.uuid4().hex[:8]
    registered = _register(client, f"buyer-{suffix}@test.sn", f"buyer_{suffix}", "buyer")
    assert registered["user"]["role"] == "buyer"
    assert "access_token" in registered
    assert "refresh_token" in registered

    login = client.post(
        "/api/v1/auth/login",
        json={"email": f"buyer-{suffix}@test.sn", "password": "password123"},
    )
    assert login.status_code == 200
    tokens = login.json()

    me = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    assert me.status_code == 200
    assert me.json()["email"] == f"buyer-{suffix}@test.sn"

    refreshed = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert refreshed.status_code == 200
    assert "access_token" in refreshed.json()


def test_login_wrong_password(client: TestClient) -> None:
    suffix = uuid.uuid4().hex[:8]
    _register(client, f"login-{suffix}@test.sn", f"login_{suffix}")
    response = client.post(
        "/api/v1/auth/login",
        json={"email": f"login-{suffix}@test.sn", "password": "wrongpass"},
    )
    assert response.status_code == 401


def test_duplicate_email_rejected(client: TestClient) -> None:
    suffix = uuid.uuid4().hex[:8]
    email = f"dup-{suffix}@test.sn"
    _register(client, email, f"dup_{suffix}")
    again = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "username": f"other_{suffix}",
            "full_name": "Autre",
            "password": "password123",
            "role": "buyer",
        },
    )
    assert again.status_code == 409


def test_register_rate_limit(client: TestClient) -> None:
    for index in range(3):
        _register(
            client,
            f"rl-{index}-{uuid.uuid4().hex[:6]}@test.sn",
            f"rl_{index}_{uuid.uuid4().hex[:6]}",
        )
    blocked = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"rl-blocked-{uuid.uuid4().hex[:6]}@test.sn",
            "username": f"rl_blocked_{uuid.uuid4().hex[:6]}",
            "full_name": "Bloqué",
            "password": "password123",
            "role": "buyer",
        },
    )
    assert blocked.status_code == 429


def test_login_rate_limit(client: TestClient) -> None:
    suffix = uuid.uuid4().hex[:8]
    _register(client, f"limit-{suffix}@test.sn", f"limit_{suffix}")
    for _ in range(5):
        response = client.post(
            "/api/v1/auth/login",
            json={"email": f"limit-{suffix}@test.sn", "password": "bad-password"},
        )
        assert response.status_code == 401
    blocked = client.post(
        "/api/v1/auth/login",
        json={"email": f"limit-{suffix}@test.sn", "password": "bad-password"},
    )
    assert blocked.status_code == 429


def test_admin_role_not_self_serve(client: TestClient, db_session: Session) -> None:
    suffix = uuid.uuid4().hex[:8]
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"admin-{suffix}@test.sn",
            "username": f"admin_{suffix}",
            "full_name": "Fake Admin",
            "password": "password123",
            "role": "admin",
        },
    )
    assert response.status_code == 400


def test_paytech_webhook_idempotent_and_signed(client: TestClient, db_session: Session) -> None:
    buyer = create_user(db_session, role=UserRole.buyer)
    seller = create_user(db_session, role=UserRole.seller)
    listing = create_listing(db_session, seller, price_xof=28000)
    create = client.post(
        "/api/v1/orders",
        json={"listing_id": str(listing.id)},
        headers=auth_headers(buyer),
    )
    assert create.status_code == 201
    order_id = create.json()["id"]

    payment_reference = f"PT-{uuid.uuid4().hex[:16].upper()}"
    db_order = db_session.get(Order, uuid.UUID(order_id))
    assert db_order is not None
    db_order.payment_reference = payment_reference
    db_session.commit()

    payload = json.dumps(
        {
            "payment_reference": payment_reference,
            "status": "success",
            "message": "Wave OK",
        }
    ).encode("utf-8")
    signature = hmac.new(
        settings.paytech_webhook_secret.encode("utf-8"), payload, hashlib.sha256
    ).hexdigest()

    bad_sig = client.post(
        "/api/v1/webhooks/paytech",
        content=payload,
        headers={"x-paytech-signature": "invalid", "Content-Type": "application/json"},
    )
    assert bad_sig.status_code == 401

    first = client.post(
        "/api/v1/webhooks/paytech",
        content=payload,
        headers={"x-paytech-signature": signature, "Content-Type": "application/json"},
    )
    assert first.status_code == 200
    assert first.json()["already_processed"] is False
    assert first.json()["ok"] is True

    second = client.post(
        "/api/v1/webhooks/paytech",
        content=payload,
        headers={"x-paytech-signature": signature, "Content-Type": "application/json"},
    )
    assert second.status_code == 200
    assert second.json()["already_processed"] is True

    db_session.refresh(db_order)
    assert db_order.status.value == "PAID_ESCROW"
    paid_events = [e for e in db_order.events if e.to_status == "PAID_ESCROW"]
    assert len(paid_events) == 1
