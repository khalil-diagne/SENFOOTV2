from decimal import Decimal

import pytest

from app.services.commission import calculate_commission_xof, to_decimal_rate


@pytest.mark.parametrize(
    ("price_xof", "rate", "expected"),
    [
        (12345, Decimal("0.08"), 988),
        (99999, Decimal("0.08"), 8000),
        (1000, Decimal("0.08"), 80),
        (5000, Decimal("0.08"), 400),
        (1250, Decimal("0.08"), 100),
        (1, Decimal("0.08"), 0),
        (6, Decimal("0.08"), 0),
        (7, Decimal("0.08"), 1),
        (12346, Decimal("0.08"), 988),
        (12344, Decimal("0.08"), 988),
        (11875, Decimal("0.08"), 950),
        (0, Decimal("0.08"), 0),
    ],
)
def test_calculate_commission_xof_edges(price_xof: int, rate, expected: int) -> None:
    result = calculate_commission_xof(price_xof, rate)
    assert isinstance(result, int)
    assert result == expected


def test_calculate_commission_accepts_string_rate() -> None:
    assert calculate_commission_xof(12345, "0.08") == 988


def test_calculate_commission_accepts_float_rate_via_str() -> None:
    assert calculate_commission_xof(99999, 0.08) == 8000


def test_calculate_commission_never_returns_float() -> None:
    result = calculate_commission_xof(12345, Decimal("0.08"))
    assert type(result) is int


def test_calculate_commission_rejects_negative_price() -> None:
    with pytest.raises(ValueError):
        calculate_commission_xof(-1, Decimal("0.08"))


def test_calculate_commission_rejects_negative_rate() -> None:
    with pytest.raises(ValueError):
        calculate_commission_xof(1000, Decimal("-0.01"))


def test_to_decimal_rate_from_float() -> None:
    assert to_decimal_rate(0.08) == Decimal("0.08")


def test_commission_is_half_up_rounding() -> None:
    assert calculate_commission_xof(13, Decimal("0.08")) == 1
    assert calculate_commission_xof(6, Decimal("0.08")) == 0
