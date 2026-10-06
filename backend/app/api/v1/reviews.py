import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.order import Order, OrderStatus
from app.models.review import Review
from app.models.user import User
from app.schemas.review import ReviewCreate, ReviewOut

router = APIRouter(prefix="/orders/{order_id}/reviews", tags=["reviews"])


@router.get("", response_model=list[ReviewOut])
def list_order_reviews(
    order_id: uuid.UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    order = db.get(Order, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Commande introuvable")
    if user.id not in {order.buyer_id, order.seller_id} and user.role.value != "admin":
        raise HTTPException(status_code=403, detail="Accès refusé")
    return [ReviewOut.model_validate(review) for review in order.reviews]


@router.post("", response_model=ReviewOut, status_code=status.HTTP_201_CREATED)
def create_review(
    order_id: uuid.UUID,
    payload: ReviewCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    order = db.get(Order, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Commande introuvable")
    if order.status is not OrderStatus.RELEASED_TO_SELLER:
        raise HTTPException(
            status_code=409,
            detail="Les avis ne sont possibles qu'après libération des fonds",
        )
    if user.id == order.buyer_id:
        reviewee_id = order.seller_id
    elif user.id == order.seller_id:
        reviewee_id = order.buyer_id
    else:
        raise HTTPException(status_code=403, detail="Seuls acheteur et vendeur peuvent laisser un avis")

    existing = (
        db.query(Review)
        .filter(Review.order_id == order.id, Review.reviewer_id == user.id)
        .first()
    )
    if existing is not None:
        raise HTTPException(status_code=409, detail="Vous avez déjà noté cette commande")

    review = Review(
        order_id=order.id,
        reviewer_id=user.id,
        reviewee_id=reviewee_id,
        rating=payload.rating,
        comment=payload.comment,
    )
    db.add(review)
    db.commit()
    db.refresh(review)
    return ReviewOut.model_validate(review)
