from app.services.payments.base import PaymentProvider, PaymentResult, WebhookResult
from app.services.payments.mock_provider import MockPaymentProvider
from app.services.payments.paytech_provider import PayTechProvider

__all__ = [
    "MockPaymentProvider",
    "PaymentProvider",
    "PaymentResult",
    "PayTechProvider",
    "WebhookResult",
]


def get_payment_provider(name: str = "mock") -> PaymentProvider:
    if name == "paytech":
        return PayTechProvider()
    return MockPaymentProvider()
