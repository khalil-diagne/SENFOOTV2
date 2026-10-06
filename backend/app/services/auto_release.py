from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.order import Order, OrderStatus
from app.services.order_state_machine import SYSTEM_ACTOR_ROLE, transition_order


def process_due_auto_releases(db: Session) -> int:
    now = datetime.now(timezone.utc)
    due_orders = (
        db.query(Order)
        .filter(
            Order.status == OrderStatus.ACCESS_TRANSFERRED,
            Order.auto_release_at.isnot(None),
            Order.auto_release_at <= now,
        )
        .all()
    )
    processed = 0
    for order in due_orders:
        transition_order(
            db,
            order,
            OrderStatus.CONFIRMED_BY_BUYER,
            actor=None,
            actor_role=SYSTEM_ACTOR_ROLE,
            note="Auto-release : délai de confirmation acheteur écoulé",
        )
        transition_order(
            db,
            order,
            OrderStatus.RELEASED_TO_SELLER,
            actor=None,
            actor_role=SYSTEM_ACTOR_ROLE,
            note="Auto-release : libération des fonds",
        )
        processed += 1
    db.commit()
    return processed


def schedule_auto_release_hours() -> int:
    return settings.auto_release_hours
