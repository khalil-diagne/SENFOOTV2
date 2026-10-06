import hashlib
import hmac
import json
from uuid import UUID

from app.core.config import settings
from app.services.payments.base import PaymentProvider, PaymentResult, WebhookResult


class PayTechProvider(PaymentProvider):
    name = "paytech"

    def __init__(self) -> None:
        self.api_key = settings.paytech_api_key
        self.api_secret = settings.paytech_api_secret
        self.webhook_secret = settings.paytech_webhook_secret or self.api_secret

    def create_payment(self, order_id: UUID, amount_xof: int, phone: str | None) -> PaymentResult:
        reference = f"PT-{order_id.hex[:16].upper()}"
        return PaymentResult(
            success=bool(self.api_key),
            provider=self.name,
            payment_reference=reference,
            message=(
                "Paiement PayTech initialisé (Wave / Orange Money)"
                if self.api_key
                else "PayTech non configuré : renseigner PAYTECH_API_KEY dans .env"
            ),
        )

    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        if not self.webhook_secret:
            return False
        expected = hmac.new(
            self.webhook_secret.encode("utf-8"), payload, hashlib.sha256
        ).hexdigest()
        return hmac.compare_digest(expected, signature)

    def parse_webhook(self, payload: bytes) -> WebhookResult:
        data = json.loads(payload.decode("utf-8"))
        reference = str(data.get("payment_reference") or data.get("tx_ref") or "")
        if not reference:
            return WebhookResult(success=False, payment_reference="", message="Référence manquante")
        status = str(data.get("status", "")).lower()
        success = status in {"success", "paid", "completed", "confirmed"}
        return WebhookResult(
            success=success,
            payment_reference=reference,
            message=data.get("message", "Webhook PayTech traité"),
        )
