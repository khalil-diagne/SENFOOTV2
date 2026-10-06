from datetime import datetime, timedelta, timezone
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.listing import Listing, ListingStatus
from app.models.order import OPEN_ORDER_STATUSES, Order, OrderEvent, OrderStatus
from app.models.user import User, UserRole
from app.services.commission import calculate_commission_xof

SYSTEM_ACTOR_ROLE = "system"

ALLOWED_TRANSITIONS: dict[OrderStatus, frozenset[OrderStatus]] = {
    OrderStatus.CREATED: frozenset({OrderStatus.PAID_ESCROW}),
    OrderStatus.PAID_ESCROW: frozenset(
        {OrderStatus.ACCESS_TRANSFERRED, OrderStatus.DISPUTED}
    ),
    OrderStatus.ACCESS_TRANSFERRED: frozenset(
        {OrderStatus.CONFIRMED_BY_BUYER, OrderStatus.DISPUTED}
    ),
    OrderStatus.CONFIRMED_BY_BUYER: frozenset({OrderStatus.RELEASED_TO_SELLER}),
    OrderStatus.DISPUTED: frozenset({OrderStatus.REFUNDED, OrderStatus.RELEASED_TO_SELLER}),
    OrderStatus.RELEASED_TO_SELLER: frozenset(),
    OrderStatus.REFUNDED: frozenset(),
}

DISPUTE_ALLOWED_FROM = frozenset({OrderStatus.PAID_ESCROW, OrderStatus.ACCESS_TRANSFERRED})


def _append_event(
    db: Session,
    order: Order,
    from_status: OrderStatus | None,
    to_status: OrderStatus,
    actor: User | None,
    actor_role: str,
    note: str | None,
) -> None:
    db.add(
        OrderEvent(
            order_id=order.id,
            from_status=from_status.value if from_status else None,
            to_status=to_status.value,
            actor_id=actor.id if actor else None,
            actor_role=actor_role,
            note=note,
        )
    )


def transition_order(
    db: Session,
    order: Order,
    to_status: OrderStatus,
    actor: User | None,
    actor_role: str,
    note: str | None = None,
    auto_release_hours: int | None = None,
) -> Order:
    current = order.status
    if to_status not in ALLOWED_TRANSITIONS[current]:
        raise HTTPException(
            status_code=409,
            detail=(
                f"Transition interdite : {current.value} -> {to_status.value}"
            ),
        )

    if to_status is OrderStatus.PAID_ESCROW:
        if order.listing is not None:
            order.listing.status = ListingStatus.sold

    if to_status is OrderStatus.ACCESS_TRANSFERRED:
        if auto_release_hours is not None:
            order.auto_release_at = datetime.now(timezone.utc) + timedelta(hours=auto_release_hours)

    if to_status is OrderStatus.RELEASED_TO_SELLER:
        order.commission_xof = calculate_commission_xof(order.price_xof, order.commission_rate)
        order.escrow_released_at = datetime.now(timezone.utc)
        order.auto_release_at = None

    if to_status is OrderStatus.REFUNDED:
        if order.listing is not None:
            order.listing.status = ListingStatus.active
        order.commission_xof = None
        order.escrow_released_at = None
        order.auto_release_at = None

    _append_event(db, order, current, to_status, actor, actor_role, note)
    order.status = to_status
    db.add(order)
    db.flush()
    return order


def create_order(
    db: Session,
    listing: Listing,
    buyer: User,
    commission_rate,
    auto_release_hours: int,
) -> Order:
    if listing.seller_id == buyer.id:
        raise HTTPException(status_code=400, detail="Impossible d'acheter sa propre annonce")
    if listing.status is not ListingStatus.active:
        raise HTTPException(status_code=400, detail="Cette annonce n'est pas disponible à la vente")

    existing = (
        db.query(Order)
        .filter(Order.listing_id == listing.id, Order.status.in_(list(OPEN_ORDER_STATUSES)))
        .first()
    )
    if existing is not None:
        raise HTTPException(status_code=409, detail="Une commande active existe déjà pour cette annonce")

    order = Order(
        listing_id=listing.id,
        buyer_id=buyer.id,
        seller_id=listing.seller_id,
        price_xof=listing.price_xof,
        commission_rate=commission_rate,
        status=OrderStatus.CREATED,
        auto_release_at=None,
    )
    db.add(order)
    db.flush()
    _append_event(
        db,
        order,
        None,
        OrderStatus.CREATED,
        actor=buyer,
        actor_role=buyer.role.value,
        note="Commande créée",
    )
    db.flush()
    return order


def require_order_access(order: Order, user: User) -> None:
    if user.role is UserRole.admin:
        return
    if user.id not in {order.buyer_id, order.seller_id}:
        raise HTTPException(status_code=403, detail="Accès refusé à cette commande")


def mark_paid_mock(
    db: Session,
    order: Order,
    buyer: User,
    provider_name: str,
    payment_reference: str,
) -> Order:
    if order.buyer_id != buyer.id:
        raise HTTPException(status_code=403, detail="Seul l'acheteur peut payer")
    order.payment_provider = provider_name
    order.payment_reference = payment_reference
    return transition_order(
        db,
        order,
        OrderStatus.PAID_ESCROW,
        actor=buyer,
        actor_role=buyer.role.value,
        note=f"Paiement séquestre via {provider_name}",
    )


def mark_access_transferred(
    db: Session,
    order: Order,
    seller: User,
    note: str | None,
    auto_release_hours: int,
) -> Order:
    if order.seller_id != seller.id:
        raise HTTPException(status_code=403, detail="Seul le vendeur peut marquer le transfert des accès")
    return transition_order(
        db,
        order,
        OrderStatus.ACCESS_TRANSFERRED,
        actor=seller,
        actor_role=seller.role.value,
        note=note or "Accès du compte remis à l'acheteur",
        auto_release_hours=auto_release_hours,
    )


def confirm_by_buyer(
    db: Session,
    order: Order,
    buyer: User,
    note: str | None,
) -> Order:
    if order.buyer_id != buyer.id:
        raise HTTPException(status_code=403, detail="Seul l'acheteur peut confirmer la réception")
    transition_order(
        db,
        order,
        OrderStatus.CONFIRMED_BY_BUYER,
        actor=buyer,
        actor_role=buyer.role.value,
        note=note or "Réception confirmée par l'acheteur",
    )
    return transition_order(
        db,
        order,
        OrderStatus.RELEASED_TO_SELLER,
        actor=None,
        actor_role=SYSTEM_ACTOR_ROLE,
        note="Libération des fonds au vendeur",
    )


def open_dispute(
    db: Session,
    order: Order,
    user: User,
    reason: str,
) -> Order:
    require_order_access(order, user)
    if user.id not in {order.buyer_id, order.seller_id}:
        raise HTTPException(status_code=403, detail="Seuls acheteur et vendeur peuvent ouvrir un litige")
    if order.status not in DISPUTE_ALLOWED_FROM:
        raise HTTPException(
            status_code=409,
            detail=(
                f"Litige impossible depuis l'état {order.status.value}"
            ),
        )
    order.dispute_reason = reason
    return transition_order(
        db,
        order,
        OrderStatus.DISPUTED,
        actor=user,
        actor_role=user.role.value,
        note=reason,
    )


def resolve_dispute(
    db: Session,
    order: Order,
    admin: User,
    action: str,
    resolution_note: str,
) -> Order:
    if admin.role is not UserRole.admin:
        raise HTTPException(status_code=403, detail="Seul un admin peut trancher un litige")
    if order.status is not OrderStatus.DISPUTED:
        raise HTTPException(status_code=409, detail="Aucun litige actif sur cette commande")
    if not resolution_note or not resolution_note.strip():
        raise HTTPException(status_code=400, detail="La note de résolution est obligatoire")

    order.resolution_note = resolution_note.strip()
    if action == "refund":
        return transition_order(
            db,
            order,
            OrderStatus.REFUNDED,
            actor=admin,
            actor_role=admin.role.value,
            note=order.resolution_note,
        )
    if action == "release":
        return transition_order(
            db,
            order,
            OrderStatus.RELEASED_TO_SELLER,
            actor=admin,
            actor_role=admin.role.value,
            note=order.resolution_note,
        )
    raise HTTPException(status_code=400, detail="Action inconnue (refund|release)")
