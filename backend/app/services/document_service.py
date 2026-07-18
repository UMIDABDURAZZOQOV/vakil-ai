import io
import re
from datetime import date

from fastapi import UploadFile
from pypdf import PdfReader
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.models import ClauseFlag, Deadline, Document, User
from .ai_provider import DocumentAnalysisResult


def extract_text_from_bytes(raw: bytes, content_type: str, filename: str) -> str:
    """Best-effort text extraction. Typed PDFs and .txt work with zero API
    key. Photographed documents (images) need Gemini vision — until
    GEMINI_API_KEY is set, they fall back to a placeholder so the upload
    flow still completes end-to-end.
    """
    content_type = content_type or ""
    name = (filename or "").lower()

    if content_type == "application/pdf" or name.endswith(".pdf"):
        reader = PdfReader(io.BytesIO(raw))
        text = "\n\n".join((page.extract_text() or "") for page in reader.pages)
        return text.strip() or "(PDF matnini o'qib bo'lmadi — skanerlangan rasm bo'lishi mumkin.)"

    if content_type.startswith("text/") or name.endswith(".txt"):
        return raw.decode("utf-8", errors="ignore").strip()

    if content_type.startswith("image/"):
        return (
            "[Rasm hujjati] Matnni o'qish uchun Gemini Vision kerak. "
            "GEMINI_API_KEY sozlanganda, bu yerda hujjatning to'liq matni bo'ladi."
        )

    return raw.decode("utf-8", errors="ignore").strip()


async def extract_text(file: UploadFile) -> str:
    raw = await file.read()
    return extract_text_from_bytes(raw, file.content_type or "", file.filename or "")


_DATE_PATTERN = re.compile(r"(\d{1,2})[./-](\d{1,2})[./-](\d{4})")
_MONTHLY_PATTERN = re.compile(r"har oyning\s+(\d{1,2})-?\s*sana", re.IGNORECASE)


def parse_due_date(text: str, today: date | None = None) -> date | None:
    """Best-effort recurring/absolute date extraction from a free-text
    key-date string (e.g. "To'lov muddati: har oyning 5-sanasi" or
    "15.08.2026"). Returns None when the text isn't a recognizable date —
    those entries are simply excluded from reminder scheduling.
    """
    today = today or date.today()

    absolute = _DATE_PATTERN.search(text)
    if absolute:
        day, month, year = (int(g) for g in absolute.groups())
        try:
            return date(year, month, day)
        except ValueError:
            return None

    monthly = _MONTHLY_PATTERN.search(text)
    if monthly:
        day = int(monthly.group(1))
        year, month = today.year, today.month
        try:
            candidate = date(year, month, day)
        except ValueError:
            return None
        if candidate < today:
            month = month + 1 if month < 12 else 1
            year = year if month != 1 else year + 1
            try:
                candidate = date(year, month, day)
            except ValueError:
                return None
        return candidate

    return None


async def persist_document_analysis(
    db: AsyncSession,
    *,
    user: User,
    title: str,
    text: str,
    analysis: DocumentAnalysisResult,
) -> Document:
    """Shared by the HTTP upload route and the Telegram bot so both entry
    points save documents/flags/deadlines identically and enforce the same
    free-tier quota."""
    document = Document(
        user_id=user.id,
        title=title,
        original_text=text,
        status="completed",
        risk_level=analysis.risk_level,
        risk_score=analysis.risk_score,
        summary_bullets=analysis.summary_bullets,
        key_dates=analysis.key_dates,
        compliance_scores=analysis.compliance_scores,
    )
    db.add(document)
    await db.flush()

    for i, flag in enumerate(analysis.flags):
        db.add(
            ClauseFlag(
                document_id=document.id,
                title=flag.title,
                risk_level=flag.risk_level,
                explanation=flag.explanation,
                order_index=i,
            )
        )

    for key_date_text in analysis.key_dates:
        due = parse_due_date(key_date_text)
        db.add(Deadline(document_id=document.id, description=key_date_text, due_date=due))

    user.documents_used_this_period += 1
    await db.commit()
    return document
