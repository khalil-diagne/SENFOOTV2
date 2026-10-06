import json
import uuid
from uuid import UUID

from app.services.payments.base import PaymentProvider, PaymentResult, WebhookResult


class MockPaymentProvider(PaymentProvider):
    name = "mock"

    def create_payment(self, order_id: UUID, amount_xof: int, phone: str | None) -> PaymentResult:
        reference = f"MOCK-{uuid.uuid4().hex[:12].upper()}"
        return PaymentResult(
            success=True,
            provider=self.name,
            payment_reference=reference,
            message="Paiement simulé accepté (séquestre fictif)",
        )

    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        return True

    def parse_webhook(self, payload: bytes) -> WebhookResult:
        data = json.loads(payload.decode("utf-8"))
        reference = str(data.get("payment_reference", ""))
        if not reference:
            return WebhookResult(success=False, payment_reference="", message="Référence manquante")
        return WebhookResult(
            success=True,
            payment_reference=reference,
            message="Webhook mock accepté",
        )
