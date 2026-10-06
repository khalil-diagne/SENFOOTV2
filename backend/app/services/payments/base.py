from abc import ABC, abstractmethod
from dataclasses import dataclass
from uuid import UUID


@dataclass(frozen=True)
class PaymentResult:
    success: bool
    provider: str
    payment_reference: str
    message: str


@dataclass(frozen=True)
class WebhookResult:
    success: bool
    payment_reference: str
    message: str
    already_processed: bool = False


class PaymentProvider(ABC):
    name: str

    @abstractmethod
    def create_payment(self, order_id: UUID, amount_xof: int, phone: str | None) -> PaymentResult:
        raise NotImplementedError

    @abstractmethod
    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        raise NotImplementedError

    @abstractmethod
    def parse_webhook(self, payload: bytes) -> WebhookResult:
        raise NotImplementedError
