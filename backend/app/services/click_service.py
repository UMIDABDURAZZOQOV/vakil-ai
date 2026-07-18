"""Click Merchant API (test mode).

Protocol: our checkout link sends the user to Click's hosted payment page.
Click then calls our webhook twice per payment — action=0 (Prepare) then
action=1 (Complete) — as form-encoded POST params, each signed with an MD5
hex digest over a fixed field concatenation. See CLICK_SECRET_KEY in
backend/.env; going live needs real CLICK_SERVICE_ID/CLICK_MERCHANT_ID from
Click's merchant cabinet.
"""

import hashlib

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.config import get_settings
from ..db.models import Payment, User
from .subscription_service import activate_premium

settings = get_settings()

ERR_SIGN_FAILED = -1
ERR_AMOUNT = -2
ERR_ACTION_NOT_FOUND = -3
ERR_ALREADY_PAID = -4
ERR_USER_NOT_FOUND = -5
ERR_TRANSACTION_NOT_FOUND = -6
ERR_CANCELLED = -9


def build_checkout_url(payment_id: str) -> str:
    amount = f"{settings.premium_price_uzs:.2f}"
    return (
        "https://my.click.uz/services/pay"
        f"?service_id={settings.click_service_id}"
        f"&merchant_id={settings.click_merchant_id}"
        f"&amount={amount}"
        f"&transaction_param={payment_id}"
    )


def _verify_prepare_signature(p: dict) -> bool:
    raw = (
        f"{p['click_trans_id']}{p['service_id']}{settings.click_secret_key}"
        f"{p['merchant_trans_id']}{p['amount']}{p['action']}{p['sign_time']}"
    )
    return hashlib.md5(raw.encode()).hexdigest() == p.get("sign_string")


def _verify_complete_signature(p: dict) -> bool:
    raw = (
        f"{p['click_trans_id']}{p['service_id']}{settings.click_secret_key}"
        f"{p['merchant_trans_id']}{p.get('merchant_prepare_id', '')}"
        f"{p['amount']}{p['action']}{p['sign_time']}"
    )
    return hashlib.md5(raw.encode()).hexdigest() == p.get("sign_string")


async def handle_prepare(db: AsyncSession, params: dict) -> dict:
    base = {"click_trans_id": params.get("click_trans_id"), "merchant_trans_id": params.get("merchant_trans_id")}

    if not settings.click_secret_key or not _verify_prepare_signature(params):
        return {**base, "error": ERR_SIGN_FAILED, "error_note": "SIGN CHECK FAILED"}

    result = await db.execute(select(Payment).where(Payment.id == params["merchant_trans_id"]))
    payment = result.scalar_one_or_none()
    if payment is None:
        return {**base, "error": ERR_TRANSACTION_NOT_FOUND, "error_note": "Transaction not found"}

    if float(params["amount"]) != payment.amount:
        return {**base, "error": ERR_AMOUNT, "error_note": "Incorrect amount"}

    payment.provider_transaction_id = str(params["click_trans_id"])
    await db.commit()

    return {**base, "merchant_prepare_id": payment.id, "error": 0, "error_note": "Success"}


async def handle_complete(db: AsyncSession, params: dict) -> dict:
    base = {"click_trans_id": params.get("click_trans_id"), "merchant_trans_id": params.get("merchant_trans_id")}

    if not settings.click_secret_key or not _verify_complete_signature(params):
        return {**base, "error": ERR_SIGN_FAILED, "error_note": "SIGN CHECK FAILED"}

    result = await db.execute(select(Payment).where(Payment.id == params["merchant_trans_id"]))
    payment = result.scalar_one_or_none()
    if payment is None:
        return {**base, "error": ERR_TRANSACTION_NOT_FOUND, "error_note": "Transaction not found"}

    if payment.status == "paid":
        return {**base, "merchant_confirm_id": payment.id, "error": ERR_ALREADY_PAID, "error_note": "Already paid"}

    if int(params.get("error", 0)) < 0:
        payment.status = "cancelled"
        await db.commit()
        return {**base, "error": ERR_CANCELLED, "error_note": "Transaction cancelled by Click"}

    payment.status = "paid"
    user_result = await db.execute(select(User).where(User.id == payment.user_id))
    user = user_result.scalar_one()
    activate_premium(user)
    await db.commit()

    return {**base, "merchant_confirm_id": payment.id, "error": 0, "error_note": "Success"}
