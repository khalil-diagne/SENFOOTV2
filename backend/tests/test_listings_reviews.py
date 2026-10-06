from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.listing import ListingStatus, Platform
from app.models.user import UserRole
from tests.conftest import (
    advance_order_to_paid,
    auth_headers,
    create_listing,
    create_order_via_api,
    create_user,
)


def test_listing_search_and_crud(client: TestClient, db_session: Session) -> None:
    seller = create_user(db_session, role=UserRole.seller)
    buyer = create_user(db_session, role=UserRole.buyer)

    created = client.post(
        "/api/v1/listings",
        json={
            "title": "Compte puissance 3160 PS4",
            "description": "Compte avec Messi 2015 et Lautaro épique, puissance 3160.",
            "price_xof": 15000,
            "platform": "ps4",
            "team_strength": 3160,
            "image_urls": ["https://cdn.example.com/1.jpg"],
        },
        headers=auth_headers(seller),
    )
    assert created.status_code == 201, created.text
    listing_id = created.json()["id"]
    assert created.json()["images"][0]["url"] == "https://cdn.example.com/1.jpg"
    assert created.json()["seller"]["username"] == seller.username
    assert created.json()["seller"]["avg_rating"] is None

    page = client.get("/api/v1/listings", params={"q": "3160", "platform": "ps4"})
    assert page.status_code == 200
    body = page.json()
    assert body["total"] == 1
    assert body["items"][0]["id"] == listing_id

    filtered = client.get(
        "/api/v1/listings",
        params={"min_price": 20000, "max_price": 40000},
    )
    assert filtered.status_code == 200
    assert filtered.json()["total"] == 0

    updated = client.patch(
        f"/api/v1/listings/{listing_id}",
        json={"price_xof": 17500, "status": "paused"},
        headers=auth_headers(seller),
    )
    assert updated.status_code == 200
    assert updated.json()["price_xof"] == 17500
    assert updated.json()["status"] == "paused"

    forbidden = client.patch(
        f"/api/v1/listings/{listing_id}",
        json={"price_xof": 1},
        headers=auth_headers(buyer),
    )
    assert forbidden.status_code == 403

    archived = client.delete(
        f"/api/v1/listings/{listing_id}",
        headers=auth_headers(seller),
    )
    assert archived.status_code == 200
    assert archived.json()["status"] == "archived"

    public = client.get(f"/api/v1/listings/{listing_id}")
    assert public.status_code == 200
    assert public.json()["status"] == "archived"


def test_reviews_reciprocal_after_release(client: TestClient, db_session: Session) -> None:
    buyer = create_user(db_session, role=UserRole.buyer)
    seller = create_user(db_session, role=UserRole.seller)
    listing = create_listing(db_session, seller, price_xof=12345)
    order = create_order_via_api(client, buyer, listing)
    order_id = order["id"]

    early_review = client.post(
        f"/api/v1/orders/{order_id}/reviews",
        json={"rating": 5, "comment": "trop tot"},
        headers=auth_headers(buyer),
    )
    assert early_review.status_code == 409

    advance_order_to_paid(client, buyer, order_id)
    client.post(
        f"/api/v1/orders/{order_id}/transfer-access",
        json={"note": "ok"},
        headers=auth_headers(seller),
    )
    released = client.post(
        f"/api/v1/orders/{order_id}/confirm",
        json={},
        headers=auth_headers(buyer),
    )
    assert released.json()["status"] == "RELEASED_TO_SELLER"

    buyer_review = client.post(
        f"/api/v1/orders/{order_id}/reviews",
        json={"rating": 5, "comment": "Compte conforme, merci !"},
        headers=auth_headers(buyer),
    )
    assert buyer_review.status_code == 201, buyer_review.text

    duplicate = client.post(
        f"/api/v1/orders/{order_id}/reviews",
        json={"rating": 4, "comment": "encore"},
        headers=auth_headers(buyer),
    )
    assert duplicate.status_code == 409

    seller_review = client.post(
        f"/api/v1/orders/{order_id}/reviews",
        json={"rating": 4, "comment": "Acheteur sérieux"},
        headers=auth_headers(seller),
    )
    assert seller_review.status_code == 201

    detail = client.get(f"/api/v1/listings/{listing.id}")
    assert detail.status_code == 200
    seller_public = detail.json()["seller"]
    assert seller_public["reviews_count"] == 1
    assert seller_public["avg_rating"] == 5.0


def test_inactive_listing_cannot_be_ordered(client: TestClient, db_session: Session) -> None:
    buyer = create_user(db_session, role=UserRole.buyer)
    seller = create_user(db_session, role=UserRole.seller)
    listing = create_listing(db_session, seller, status=ListingStatus.paused)

    response = client.post(
        "/api/v1/orders",
        json={"listing_id": str(listing.id)},
        headers=auth_headers(buyer),
    )
    assert response.status_code == 400
    assert "pas disponible" in response.json()["detail"]
