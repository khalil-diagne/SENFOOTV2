from datetime import datetime, timedelta, timezone
from decimal import Decimal
from uuid import UUID

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.listing import ListingStatus
from app.models.order import Order, OrderEvent, OrderStatus
from app.models.user import User, UserRole
from app.services.auto_release import process_due_auto_releases
from tests.conftest import (
    advance_order_to_paid,
    auth_headers,
    create_listing,
    create_order_via_api,
    create_user,
)


def _order_events(db: Session, order_id: UUID) -> list[OrderEvent]:
    order = db.get(Order, order_id)
    assert order is not None
    db.refresh(order)
    return list(order.events)


def test_create_order_success_and_forbidden_own_listing(
    client: TestClient, db_session: Session
) -> None:
    buyer = create_user(db_session, role=UserRole.buyer)
    seller = create_user(db_session, role=UserRole.seller)
    listing = create_listing(db_session, seller, price_xof=12345)

    order = create_order_via_api(client, buyer, listing)
    assert order["status"] == "CREATED"
    assert order["price_xof"] == 12345
    assert Decimal(str(order["commission_rate"])) == Decimal("0.08")
    assert order["commission_xof"] is None
    assert order["buyer_id"] == str(buyer.id)
    assert order["seller_id"] == str(seller.id)

    events = order["events"]
    assert events[0]["from_status"] is None
    assert events[0]["to_status"] == "CREATED"
    assert events[0]["actor_role"] == "buyer"

    own = client.post(
        "/api/v1/orders",
        json={"listing_id": str(listing.id)},
        headers=auth_headers(seller),
    )
    assert own.status_code == 400
    assert "propre annonce" in own.json()["detail"]


def test_cannot_open_second_active_order(client: TestClient, db_session: Session) -> None:
    buyer = create_user(db_session, role=UserRole.buyer)
    other = create_user(db_session, role=UserRole.buyer)
    seller = create_user(db_session, role=UserRole.seller)
    listing = create_listing(db_session, seller)

    first = client.post(
        "/api/v1/orders",
        json={"listing_id": str(listing.id)},
        headers=auth_headers(buyer),
    )
    assert first.status_code == 201

    second = client.post(
        "/api/v1/orders",
        json={"listing_id": str(listing.id)},
        headers=auth_headers(other),
    )
    assert second.status_code == 409


def test_invalid_transitions_are_rejected(client: TestClient, db_session: Session) -> None:
    buyer = create_user(db_session, role=UserRole.buyer)
    seller = create_user(db_session, role=UserRole.seller)
    listing = create_listing(db_session, seller)
    order = create_order_via_api(client, buyer, listing)
    order_id = order["id"]

    transfer_early = client.post(
        f"/api/v1/orders/{order_id}/transfer-access",
        json={"note": "trop tot"},
        headers=auth_headers(seller),
    )
    assert transfer_early.status_code == 409

    confirm_early = client.post(
        f"/api/v1/orders/{order_id}/confirm",
        json={},
        headers=auth_headers(buyer),
    )
    assert confirm_early.status_code == 409

    dispute_from_created = client.post(
        f"/api/v1/orders/{order_id}/dispute",
        json={"reason": "je veux annuler avant paiement"},
        headers=auth_headers(buyer),
    )
    assert dispute_from_created.status_code == 409

    paid = advance_order_to_paid(client, buyer, order_id)
    assert paid["status"] == "PAID_ESCROW"

    pay_again = client.post(
        f"/api/v1/orders/{order_id}/pay",
        json={},
        headers=auth_headers(buyer),
    )
    assert pay_again.status_code == 409

    confirm_after_pay = client.post(
        f"/api/v1/orders/{order_id}/confirm",
        json={},
        headers=auth_headers(buyer),
    )
    assert confirm_after_pay.status_code == 409

    wrong_actor = client.post(
        f"/api/v1/orders/{order_id}/transfer-access",
        json={"note": "je ne suis pas vendeur"},
        headers=auth_headers(buyer),
    )
    assert wrong_actor.status_code == 403


def test_happy_path_release_and_commission(client: TestClient, db_session: Session) -> None:
    buyer = create_user(db_session, role=UserRole.buyer)
    seller = create_user(db_session, role=UserRole.seller)
    listing = create_listing(db_session, seller, price_xof=99999)
    order = create_order_via_api(client, buyer, listing)
    order_id = order["id"]

    paid = advance_order_to_paid(client, buyer, order_id)
    assert paid["status"] == "PAID_ESCROW"
    db_listing = db_session.get(type(listing), listing.id)
    assert db_listing.status is ListingStatus.sold
    assert paid["auto_release_at"] is None

    transferred = client.post(
        f"/api/v1/orders/{order_id}/transfer-access",
        json={"note": "identifiants envoyés en chat"},
        headers=auth_headers(seller),
    )
    assert transferred.status_code == 200
    assert transferred.json()["status"] == "ACCESS_TRANSFERRED"
    assert transferred.json()["auto_release_at"] is not None

    confirmed = client.post(
        f"/api/v1/orders/{order_id}/confirm",
        json={"note": "compte ok"},
        headers=auth_headers(buyer),
    )
    assert confirmed.status_code == 200
    body = confirmed.json()
    assert body["status"] == "RELEASED_TO_SELLER"
    assert body["commission_xof"] == 8000
    assert body["escrow_released_at"] is not None

    statuses = [event["to_status"] for event in body["events"]]
    assert statuses == [
        "CREATED",
        "PAID_ESCROW",
        "ACCESS_TRANSFERRED",
        "CONFIRMED_BY_BUYER",
        "RELEASED_TO_SELLER",
    ]


def test_dispute_flow_and_admin_resolution(client: TestClient, db_session: Session) -> None:
    admin = create_user(db_session, role=UserRole.admin)
    buyer = create_user(db_session, role=UserRole.buyer)
    seller = create_user(db_session, role=UserRole.seller)
    outsider = create_user(db_session, role=UserRole.buyer)
    listing = create_listing(db_session, seller, price_xof=5000)
    order = create_order_via_api(client, buyer, listing)
    order_id = order["id"]

    paid = advance_order_to_paid(client, buyer, order_id)
    assert paid["status"] == "PAID_ESCROW"

    outsider_dispute = client.post(
        f"/api/v1/orders/{order_id}/dispute",
        json={"reason": "je ne suis pas partie a cette commande"},
        headers=auth_headers(outsider),
    )
    assert outsider_dispute.status_code == 403

    disputed = client.post(
        f"/api/v1/orders/{order_id}/dispute",
        json={"reason": "les identifiants ne marchent pas"},
        headers=auth_headers(buyer),
    )
    assert disputed.status_code == 200
    assert disputed.json()["status"] == "DISPUTED"
    assert disputed.json()["dispute_reason"] == "les identifiants ne marchent pas"

    buyer_again = client.post(
        f"/api/v1/orders/{order_id}/dispute",
        json={"reason": "nouveau litige"},
        headers=auth_headers(buyer),
    )
    assert buyer_again.status_code == 409

    seller_dispute = client.post(
        f"/api/v1/orders/{order_id}/dispute",
        json={"reason": "nouveau litige vendeur"},
        headers=auth_headers(seller),
    )
    assert seller_dispute.status_code == 409

    non_admin_resolve = client.post(
        f"/api/v1/orders/{order_id}/resolve",
        json={"action": "refund", "resolution_note": "je veux rembourser"},
        headers=auth_headers(buyer),
    )
    assert non_admin_resolve.status_code == 403

    missing_note = client.post(
        f"/api/v1/orders/{order_id}/resolve",
        json={"action": "refund", "resolution_note": "ab"},
        headers=auth_headers(admin),
    )
    assert missing_note.status_code == 422

    resolved = client.post(
        f"/api/v1/orders/{order_id}/resolve",
        json={"action": "refund", "resolution_note": "Accès invalides, remboursement accordé"},
        headers=auth_headers(admin),
    )
    assert resolved.status_code == 200
    body = resolved.json()
    assert body["status"] == "REFUNDED"
    assert body["resolution_note"] == "Accès invalides, remboursement accordé"
    assert body["commission_xof"] is None

    db_listing = db_session.get(type(listing), listing.id)
    assert db_listing.status is ListingStatus.active

    late_dispute = client.post(
        f"/api/v1/orders/{order_id}/dispute",
        json={"reason": "trop tard apres resolution"},
        headers=auth_headers(buyer),
    )
    assert late_dispute.status_code == 409


def test_auto_release_job(client: TestClient, db_session: Session) -> None:
    buyer = create_user(db_session, role=UserRole.buyer)
    seller = create_user(db_session, role=UserRole.seller)
    listing = create_listing(db_session, seller, price_xof=12345)
    order = create_order_via_api(client, buyer, listing)
    order_id = order["id"]
    advance_order_to_paid(client, buyer, order_id)

    client.post(
        f"/api/v1/orders/{order_id}/transfer-access",
        json={"note": "transfere"},
        headers=auth_headers(seller),
    )

    order_row = db_session.get(Order, UUID(order_id))
    assert order_row is not None
    order_row.auto_release_at = datetime.now(timezone.utc) - timedelta(hours=1)
    db_session.commit()

    processed = process_due_auto_releases(db_session)
    assert processed == 1

    db_session.refresh(order_row)
    assert order_row.status is OrderStatus.RELEASED_TO_SELLER
    assert order_row.commission_xof == 988
    assert order_row.auto_release_at is None

    events = _order_events(db_session, UUID(order_id))
    to_statuses = [event.to_status for event in events]
    assert to_statuses[-2:] == ["CONFIRMED_BY_BUYER", "RELEASED_TO_SELLER"]
    assert events[-1].actor_role == "system"


def test_dispute_blocks_auto_release(client: TestClient, db_session: Session) -> None:
    admin = create_user(db_session, role=UserRole.admin)
    buyer = create_user(db_session, role=UserRole.buyer)
    seller = create_user(db_session, role=UserRole.seller)
    listing = create_listing(db_session, seller, price_xof=5000)
    order = create_order_via_api(client, buyer, listing)
    order_id = order["id"]
    advance_order_to_paid(client, buyer, order_id)
    client.post(
        f"/api/v1/orders/{order_id}/transfer-access",
        json={"note": "transfere"},
        headers=auth_headers(seller),
    )

    order_row = db_session.get(Order, UUID(order_id))
    assert order_row is not None
    order_row.auto_release_at = datetime.now(timezone.utc) - timedelta(hours=1)
    db_session.commit()

    client.post(
        f"/api/v1/orders/{order_id}/dispute",
        json={"reason": "je veux bloquer la liberation auto"},
        headers=auth_headers(buyer),
    )

    processed = process_due_auto_releases(db_session)
    assert processed == 0
    db_session.refresh(order_row)
    assert order_row.status is OrderStatus.DISPUTED

    released = client.post(
        f"/api/v1/orders/{order_id}/resolve",
        json={"action": "release", "resolution_note": "Le vendeur a bien livré"},
        headers=auth_headers(admin),
    )
    assert released.status_code == 200
    assert released.json()["status"] == "RELEASED_TO_SELLER"
    assert released.json()["commission_xof"] == 400


def test_order_visibility_and_chat_access(client: TestClient, db_session: Session) -> None:
    buyer = create_user(db_session, role=UserRole.buyer)
    seller = create_user(db_session, role=UserRole.seller)
    outsider = create_user(db_session, role=UserRole.buyer)
    admin = create_user(db_session, role=UserRole.admin)
    listing = create_listing(db_session, seller)
    order = create_order_via_api(client, buyer, listing)
    order_id = order["id"]

    outsider_order = client.get(
        f"/api/v1/orders/{order_id}", headers=auth_headers(outsider)
    )
    assert outsider_order.status_code == 403

    outsider_messages = client.get(
        f"/api/v1/orders/{order_id}/messages", headers=auth_headers(outsider)
    )
    assert outsider_messages.status_code == 403

    buyer_order = client.get(
        f"/api/v1/orders/{order_id}", headers=auth_headers(buyer)
    )
    admin_order = client.get(
        f"/api/v1/orders/{order_id}", headers=auth_headers(admin)
    )
    assert buyer_order.status_code == 200
    assert admin_order.status_code == 200

    sent = client.post(
        f"/api/v1/orders/{order_id}/messages",
        json={"body": "Bonjour, est-ce que le compte est dispo ?"},
        headers=auth_headers(buyer),
    )
    assert sent.status_code == 201

    read_by_seller = client.get(
        f"/api/v1/orders/{order_id}/messages", headers=auth_headers(seller)
    )
    assert read_by_seller.status_code == 200
    assert len(read_by_seller.json()) == 1

    reply = client.post(
        f"/api/v1/orders/{order_id}/messages",
        json={"body": "Oui, dispo des maintenant"},
        headers=auth_headers(seller),
    )
    assert reply.status_code == 201

    admin_read = client.get(
        f"/api/v1/orders/{order_id}/messages", headers=auth_headers(admin)
    )
    assert admin_read.status_code == 200
    assert len(admin_read.json()) == 2
