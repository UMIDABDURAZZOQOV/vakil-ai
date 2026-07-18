from fastapi import APIRouter, Depends

from ...core.config import get_settings
from ...db.models import User
from ...schemas.user import UserOut
from ..deps import get_current_user

router = APIRouter(prefix="/users", tags=["users"])
settings = get_settings()


@router.get("/me", response_model=UserOut)
async def get_me(user: User = Depends(get_current_user)) -> UserOut:
    return UserOut(
        id=user.id,
        identifier=user.identifier,
        name=user.name,
        role=user.role,
        telegram_connected=user.telegram_connected,
        is_premium=user.is_premium,
        documents_used=user.documents_used_this_period,
        documents_quota=settings.free_tier_document_limit,
    )
