from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.order import Order, OrderStatus
from app.services.payments import get_payment_provider
from app.services.order_state_machine import SYSTEM_ACTOR_ROLE, transition_order

router = APIRouter(prefix="/webhooks", tags=["webhooks"])


@router.post("/paytech", status_code=status.HTTP_200_OK)
async def paytech_webhook(
    request: Request,
    db: Session = Depends(get_db),
    x_paytech_signature: str | None = Header(default=None),
):
    payload = await request.body()
    provider = get_payment_provider("paytech")
    if not provider.verify_webhook_signature(payload, x_paytech_signature or ""):
        raise HTTPException(status_code=401, detail="Signature PayTech invalide")

    parsed = provider.parse_webhook(payload)
    if not parsed.success or not parsed.payment_reference:
        return {"ok": False, "message": parsed.message}

    order = (
        db.query(Order)
        .filter(Order.payment_reference == parsed.payment_reference)
        .first()
    )
    if order is None:
        return {"ok": False, "message": "Commande inconnue"}

    if order.status is not OrderStatus.CREATED:
        return {"ok": True, "message": "Déjà traité", "already_processed": True}

    order.payment_provider = provider.name
    transition_order(
        db,
        order,
        OrderStatus.PAID_ESCROW,
        actor=None,
        actor_role=SYSTEM_ACTOR_ROLE,
        note=f"Webhook PayTech ({parsed.payment_reference})",
    )
    db.commit()
    return {"ok": True, "message": "Paiement enregistré", "already_processed": False}
