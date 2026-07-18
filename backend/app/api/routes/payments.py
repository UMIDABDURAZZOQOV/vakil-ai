from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from ...core.config import get_settings
from ...db.models import Payment, User
from ...db.session import get_db
from ...services import click_service, payme_service
from ..deps import get_current_user

router = APIRouter(prefix="/payments", tags=["payments"])
settings = get_settings()


class CheckoutRequest(BaseModel):
    provider: str  # "payme" | "click"


class CheckoutResponse(BaseModel):
    url: str


@router.post("/checkout-url", response_model=CheckoutResponse)
async def create_checkout_url(
    payload: CheckoutRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> CheckoutResponse:
    if payload.provider == "payme":
        return CheckoutResponse(url=payme_service.build_checkout_url(user.id))

    if payload.provider == "click":
        payment = Payment(
            user_id=user.id,
            provider="click",
            provider_transaction_id="pending",
            amount=settings.premium_price_uzs,
            status="pending",
        )
        db.add(payment)
        await db.commit()
        await db.refresh(payment)
        return CheckoutResponse(url=click_service.build_checkout_url(payment.id))

    raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unknown provider")


@router.post("/payme")
async def payme_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    if not payme_service.is_authorized(request.headers.get("Authorization")):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    payload = await request.json()
    return await payme_service.handle_rpc(db, payload)


@router.post("/click/prepare")
async def click_prepare(request: Request, db: AsyncSession = Depends(get_db)):
    form = dict(await request.form())
    return await click_service.handle_prepare(db, form)


@router.post("/click/complete")
async def click_complete(request: Request, db: AsyncSession = Depends(get_db)):
    form = dict(await request.form())
    return await click_service.handle_complete(db, form)
