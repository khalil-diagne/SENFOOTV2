import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.message import Message
from app.models.order import Order
from app.models.user import User, UserRole
from app.schemas.message import MessageCreate, MessageOut

router = APIRouter(prefix="/orders/{order_id}/messages", tags=["messages"])


def _get_order_for_chat(db: Session, order_id: uuid.UUID, user: User) -> Order:
    order = db.get(Order, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Commande introuvable")
    if user.role is UserRole.admin:
        return order
    if user.id not in {order.buyer_id, order.seller_id}:
        raise HTTPException(status_code=403, detail="Accès refusé à la discussion de cette commande")
    return order


@router.get("", response_model=list[MessageOut])
def list_messages(
    order_id: uuid.UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    order = _get_order_for_chat(db, order_id, user)
    return [MessageOut.model_validate(message) for message in order.messages]


@router.post("", response_model=MessageOut, status_code=status.HTTP_201_CREATED)
def create_message(
    order_id: uuid.UUID,
    payload: MessageCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    order = _get_order_for_chat(db, order_id, user)
    message = Message(order_id=order.id, sender_id=user.id, body=payload.body)
    db.add(message)
    db.commit()
    db.refresh(message)
    return MessageOut.model_validate(message)
