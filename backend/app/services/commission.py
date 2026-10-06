from decimal import ROUND_HALF_UP, Decimal

from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.setting import KEY_DEFAULT_COMMISSION_RATE, AppSetting


def to_decimal_rate(rate: Decimal | float | str) -> Decimal:
    if isinstance(rate, Decimal):
        return rate
    return Decimal(str(rate))


def calculate_commission_xof(price_xof: int, rate: Decimal | float | str) -> int:
    if price_xof < 0:
        raise ValueError("price_xof ne peut pas être négatif")
    rate_dec = to_decimal_rate(rate)
    if rate_dec < 0:
        raise ValueError("Le taux de commission ne peut pas être négatif")
    amount = (Decimal(price_xof) * rate_dec).quantize(Decimal("1"), rounding=ROUND_HALF_UP)
    return int(amount)


def get_commission_rate(db: Session) -> Decimal:
    row = db.get(AppSetting, KEY_DEFAULT_COMMISSION_RATE)
    if row is not None and row.value:
        return to_decimal_rate(row.value)
    return to_decimal_rate(settings.commission_rate)


def ensure_default_settings(db: Session) -> None:
    if db.get(AppSetting, KEY_DEFAULT_COMMISSION_RATE) is None:
        db.add(
            AppSetting(
                key=KEY_DEFAULT_COMMISSION_RATE,
                value=str(to_decimal_rate(settings.commission_rate)),
            )
        )
        db.commit()
