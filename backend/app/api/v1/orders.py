import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user, require_admin
from app.models.listing import Listing
from app.models.order import Order
from app.models.user import User, UserRole
from app.schemas.order import (
    ConfirmRequest,
    DisputeRequest,
    OrderCreate,
    OrderDetailOut,
    OrderOut,
    PayRequest,
    ResolveRequest,
    TransferAccessRequest,
)
from app.services.auto_release import schedule_auto_release_hours
from app.services.commission import ensure_default_settings, get_commission_rate
from app.services.payments import get_payment_provider
from app.services.order_state_machine import (
    confirm_by_buyer,
    create_order,
    mark_access_transferred,
    mark_paid_mock,
    open_dispute,
    require_order_access,
    resolve_dispute,
)

router = APIRouter(prefix="/orders", tags=["orders"])


def _get_order_for_user(db: Session, order_id: uuid.UUID, user: User) -> Order:
    order = db.get(Order, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Commande introuvable")
    require_order_access(order, user)
    return order


@router.post("", response_model=OrderDetailOut, status_code=status.HTTP_201_CREATED)
def create_order_endpoint(
    payload: OrderCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    if user.role is UserRole.admin:
        raise HTTPException(status_code=403, detail="Les admins ne créent pas de commandes")
    ensure_default_settings(db)
    listing = db.get(Listing, payload.listing_id)
    if listing is None:
        raise HTTPException(status_code=404, detail="Annonce introuvable")
    rate = get_commission_rate(db)
    order = create_order(
        db,
        listing=listing,
        buyer=user,
        commission_rate=rate,
        auto_release_hours=schedule_auto_release_hours(),
    )
    db.commit()
    db.refresh(order)
    return OrderDetailOut.model_validate(order)


@router.get("", response_model=list[OrderOut])
def list_my_orders(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    if user.role is UserRole.admin:
        orders = db.query(Order).order_by(Order.created_at.desc()).all()
    else:
        orders = (
            db.query(Order)
            .filter((Order.buyer_id == user.id) | (Order.seller_id == user.id))
            .order_by(Order.created_at.desc())
            .all()
        )
    return [OrderOut.model_validate(item) for item in orders]


@router.get("/{order_id}", response_model=OrderDetailOut)
def get_order(
    order_id: uuid.UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    order = _get_order_for_user(db, order_id, user)
    return OrderDetailOut.model_validate(order)


@router.get("/{order_id}/events", response_model=list[dict])
def list_order_events(
    order_id: uuid.UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    order = _get_order_for_user(db, order_id, user)
    return [
        {
            "id": event.id,
            "from_status": event.from_status,
            "to_status": event.to_status,
            "actor_id": event.actor_id,
            "actor_role": event.actor_role,
            "note": event.note,
            "created_at": event.created_at,
        }
        for event in order.events
    ]


@router.post("/{order_id}/pay", response_model=OrderDetailOut)
def pay_order(
    order_id: uuid.UUID,
    payload: PayRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    order = _get_order_for_user(db, order_id, user)
    provider = get_payment_provider("mock")
    result = provider.create_payment(order.id, order.price_xof, payload.phone)
    if not result.success:
        raise HTTPException(status_code=402, detail=result.message)
    order = mark_paid_mock(
        db,
        order=order,
        buyer=user,
        provider_name=result.provider,
        payment_reference=result.payment_reference,
    )
    db.commit()
    db.refresh(order)
    return OrderDetailOut.model_validate(order)


@router.post("/{order_id}/transfer-access", response_model=OrderDetailOut)
def transfer_access(
    order_id: uuid.UUID,
    payload: TransferAccessRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    order = _get_order_for_user(db, order_id, user)
    order = mark_access_transferred(
        db,
        order=order,
        seller=user,
        note=payload.note,
        auto_release_hours=schedule_auto_release_hours(),
    )
    db.commit()
    db.refresh(order)
    return OrderDetailOut.model_validate(order)


@router.post("/{order_id}/confirm", response_model=OrderDetailOut)
def confirm_order(
    order_id: uuid.UUID,
    payload: ConfirmRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    order = _get_order_for_user(db, order_id, user)
    order = confirm_by_buyer(db, order=order, buyer=user, note=payload.note)
    db.commit()
    db.refresh(order)
    return OrderDetailOut.model_validate(order)


@router.post("/{order_id}/dispute", response_model=OrderDetailOut)
def dispute_order(
    order_id: uuid.UUID,
    payload: DisputeRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    order = _get_order_for_user(db, order_id, user)
    order = open_dispute(db, order=order, user=user, reason=payload.reason)
    db.commit()
    db.refresh(order)
    return OrderDetailOut.model_validate(order)


@router.post("/{order_id}/resolve", response_model=OrderDetailOut)
def resolve_order(
    order_id: uuid.UUID,
    payload: ResolveRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    order = db.get(Order, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Commande introuvable")
    order = resolve_dispute(
        db,
        order=order,
        admin=admin,
        action=payload.action,
        resolution_note=payload.resolution_note,
    )
    db.commit()
    db.refresh(order)
    return OrderDetailOut.model_validate(order)


@router.post("/process-auto-releases", response_model=dict)
def process_auto_releases_now(
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    from app.services.auto_release import process_due_auto_releases

    count = process_due_auto_releases(db)
    return {"processed": count, "at": datetime.now(timezone.utc)}
