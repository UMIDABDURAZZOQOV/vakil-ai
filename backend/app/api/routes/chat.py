from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ...db.models import ChatMessage, Document, User
from ...db.session import get_db
from ...schemas.chat import ChatMessageIn, ChatMessageOut
from ...services.ai_provider import get_ai_provider
from ..deps import get_current_user

router = APIRouter(prefix="/documents/{document_id}/chat", tags=["chat"])


async def _get_owned_document(document_id: str, user: User, db: AsyncSession) -> Document:
    result = await db.execute(
        select(Document).where(Document.id == document_id, Document.user_id == user.id)
    )
    document = result.scalar_one_or_none()
    if document is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")
    return document


@router.get("", response_model=list[ChatMessageOut])
async def list_messages(
    document_id: str,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[ChatMessage]:
    await _get_owned_document(document_id, user, db)
    result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.document_id == document_id)
        .order_by(ChatMessage.created_at.asc())
    )
    return list(result.scalars().all())


@router.post("", response_model=list[ChatMessageOut], status_code=status.HTTP_201_CREATED)
async def send_message(
    document_id: str,
    payload: ChatMessageIn,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[ChatMessage]:
    document = await _get_owned_document(document_id, user, db)

    history_result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.document_id == document_id)
        .order_by(ChatMessage.created_at.asc())
    )
    history = [(m.is_user, m.text) for m in history_result.scalars().all()]

    user_message = ChatMessage(document_id=document_id, is_user=True, text=payload.text)
    db.add(user_message)

    reply_text = await get_ai_provider().chat_reply(document.original_text, history, payload.text)
    ai_message = ChatMessage(document_id=document_id, is_user=False, text=reply_text)
    db.add(ai_message)

    await db.commit()
    await db.refresh(user_message)
    await db.refresh(ai_message)
    return [user_message, ai_message]
