from fastapi import APIRouter, Depends, HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ...core.config import get_settings
from ...db.models import Document, User
from ...db.session import get_db
from ...schemas.document import DocumentDetail, DocumentSummary
from ...services.ai_provider import get_ai_provider
from ...services.document_service import extract_text, persist_document_analysis
from ..deps import get_current_user

router = APIRouter(prefix="/documents", tags=["documents"])
settings = get_settings()


@router.get("", response_model=list[DocumentSummary])
async def list_documents(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[Document]:
    result = await db.execute(
        select(Document).where(Document.user_id == user.id).order_by(Document.created_at.desc())
    )
    return list(result.scalars().all())


@router.get("/{document_id}", response_model=DocumentDetail)
async def get_document(
    document_id: str,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Document:
    result = await db.execute(
        select(Document)
        .options(selectinload(Document.flags))
        .where(Document.id == document_id, Document.user_id == user.id)
    )
    document = result.scalar_one_or_none()
    if document is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")
    return document


@router.post("/upload", response_model=DocumentDetail, status_code=status.HTTP_201_CREATED)
async def upload_document(
    file: UploadFile,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Document:
    if not user.is_premium and user.documents_used_this_period >= settings.free_tier_document_limit:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Bepul limit tugadi. Premium tarifga o'ting.",
        )

    text = await extract_text(file)
    analysis = await get_ai_provider().analyze_document(text, language="uz")
    document = await persist_document_analysis(
        db, user=user, title=file.filename or "Untitled document", text=text, analysis=analysis
    )

    result = await db.execute(
        select(Document).options(selectinload(Document.flags)).where(Document.id == document.id)
    )
    return result.scalar_one()
