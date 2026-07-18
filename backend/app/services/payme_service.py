"""Payme Merchant API (test mode).

Protocol: Payme's server calls our webhook with JSON-RPC 2.0 requests,
authenticated via `Authorization: Basic base64("Paycom:<PAYME_SECRET_KEY>")`.
Checkout itself happens on Payme's hosted page — we only need to build the
checkout URL (base64-encoded params) and handle the four transaction
lifecycle methods below.

Reference error codes match Payme's documented Merchant API. Going live
needs a real PAYME_MERCHANT_ID/PAYME_SECRET_KEY from Payme's business
cabinet and testing against their sandbox — this implementation is
protocol-complete but unverified against a live Payme sandbox.
"""

import base64
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.config import get_settings
from ..db.models import Payment, User
from .subscription_service import activate_premium

settings = get_settings()

CHECKOUT_BASE_URL = "https://checkout.test.paycom.uz" if settings.payme_test_mode else "https://checkout.paycom.uz"

ERR_INVALID_AMOUNT = -31001
ERR_TRANSACTION_NOT_FOUND = -31003
ERR_CANNOT_CANCEL = -31007
ERR_CANNOT_PERFORM = -31008
ERR_USER_NOT_FOUND = -31050
ERR_INVALID_ACCOUNT = -31099

STATE_CREATED = 1
STATE_PERFORMED = 2
STATE_CANCELLED = -1
STATE_CANCELLED_AFTER_PERFORM = -2


def is_authorized(auth_header: str | None) -> bool:
    if not settings.payme_secret_key or not auth_header or not auth_header.startswith("Basic "):
        return False
    try:
        decoded = base64.b64decode(auth_header.removeprefix("Basic ")).decode()
    except Exception:
        return False
    return decoded == f"Paycom:{settings.payme_secret_key}"


def build_checkout_url(user_id: str) -> str:
    amount_tiyin = int(settings.premium_price_uzs * 100)
    params = f"m={settings.payme_merchant_id};ac.user_id={user_id};a={amount_tiyin}"
    encoded = base64.b64encode(params.encode()).decode()
    return f"{CHECKOUT_BASE_URL}/{encoded}"


def _rpc_error(request_id, code: int, message: str) -> dict:
    return {"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}}


def _rpc_result(request_id, result: dict) -> dict:
    return {"jsonrpc": "2.0", "id": request_id, "result": result}


async def _find_user(db: AsyncSession, params: dict) -> User | None:
    account = params.get("account", {})
    user_id = account.get("user_id")
    if not user_id:
        return None
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


async def handle_rpc(db: AsyncSession, payload: dict) -> dict:
    method = payload.get("method")
    params = payload.get("params", {})
    request_id = payload.get("id")
    amount_tiyin = int(settings.premium_price_uzs * 100)

    if method == "CheckPerformTransaction":
        user = await _find_user(db, params)
        if user is None:
            return _rpc_error(request_id, ERR_USER_NOT_FOUND, "User not found")
        if params.get("amount") != amount_tiyin:
            return _rpc_error(request_id, ERR_INVALID_AMOUNT, "Invalid amount")
        return _rpc_result(request_id, {"allow": True})

    if method == "CreateTransaction":
        user = await _find_user(db, params)
        if user is None:
            return _rpc_error(request_id, ERR_USER_NOT_FOUND, "User not found")
        provider_txn_id = params["id"]
        result = await db.execute(select(Payment).where(Payment.provider_transaction_id == provider_txn_id))
        payment = result.scalar_one_or_none()
        if payment is None:
            payment = Payment(
                user_id=user.id,
                provider="payme",
                provider_transaction_id=provider_txn_id,
                amount=settings.premium_price_uzs,
                status="pending",
            )
            db.add(payment)
            await db.commit()
        create_time = int(payment.created_at.timestamp() * 1000)
        return _rpc_result(request_id, {"create_time": create_time, "transaction": payment.id, "state": STATE_CREATED})

    if method == "PerformTransaction":
        provider_txn_id = params["id"]
        result = await db.execute(select(Payment).where(Payment.provider_transaction_id == provider_txn_id))
        payment = result.scalar_one_or_none()
        if payment is None:
            return _rpc_error(request_id, ERR_TRANSACTION_NOT_FOUND, "Transaction not found")
        if payment.status == "cancelled":
            return _rpc_error(request_id, ERR_CANNOT_PERFORM, "Transaction was cancelled")
        if payment.status != "paid":
            payment.status = "paid"
            user_result = await db.execute(select(User).where(User.id == payment.user_id))
            user = user_result.scalar_one()
            activate_premium(user)
            await db.commit()
        perform_time = int(datetime.now(timezone.utc).timestamp() * 1000)
        return _rpc_result(request_id, {"transaction": payment.id, "perform_time": perform_time, "state": STATE_PERFORMED})

    if method == "CancelTransaction":
        provider_txn_id = params["id"]
        result = await db.execute(select(Payment).where(Payment.provider_transaction_id == provider_txn_id))
        payment = result.scalar_one_or_none()
        if payment is None:
            return _rpc_error(request_id, ERR_TRANSACTION_NOT_FOUND, "Transaction not found")
        was_paid = payment.status == "paid"
        payment.status = "cancelled"
        await db.commit()
        cancel_time = int(datetime.now(timezone.utc).timestamp() * 1000)
        state = STATE_CANCELLED_AFTER_PERFORM if was_paid else STATE_CANCELLED
        return _rpc_result(request_id, {"transaction": payment.id, "cancel_time": cancel_time, "state": state})

    if method == "CheckTransaction":
        provider_txn_id = params["id"]
        result = await db.execute(select(Payment).where(Payment.provider_transaction_id == provider_txn_id))
        payment = result.scalar_one_or_none()
        if payment is None:
            return _rpc_error(request_id, ERR_TRANSACTION_NOT_FOUND, "Transaction not found")
        state = {"pending": STATE_CREATED, "paid": STATE_PERFORMED, "cancelled": STATE_CANCELLED}[payment.status]
        create_time = int(payment.created_at.timestamp() * 1000)
        return _rpc_result(
            request_id,
            {"create_time": create_time, "perform_time": 0, "cancel_time": 0, "transaction": payment.id, "state": state},
        )

    return _rpc_error(request_id, -32601, "Method not found")
