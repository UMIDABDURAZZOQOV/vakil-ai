"""Extra AI tools beyond single-document analysis: draft a document from a short
questionnaire, answer a general legal question, and compare two contract versions.
All three go through get_ai_provider() so they work with the mock or real backend."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from ...db.models import User
from ...services.ai_provider import get_ai_provider
from ..deps import get_current_user

router = APIRouter(prefix="/tools", tags=["tools"])


# ── Templates: generate a document from a questionnaire ──────────────────────
class TemplateRequest(BaseModel):
    template_type: str          # e.g. "NDA", "ijara shartnomasi", "frilans shartnomasi"
    fields: dict = {}
    language: str = "uz"


class TemplateResponse(BaseModel):
    document: str


@router.post("/template", response_model=TemplateResponse)
async def generate_template(req: TemplateRequest, user: User = Depends(get_current_user)) -> TemplateResponse:
    text = await get_ai_provider().generate_template(req.template_type, req.fields, req.language)
    return TemplateResponse(document=text)


# ── Legal Q&A: a general legal question, not tied to a document ───────────────
class LegalRequest(BaseModel):
    question: str
    language: str = "uz"


class LegalResponse(BaseModel):
    answer: str


@router.post("/legal", response_model=LegalResponse)
async def ask_legal(req: LegalRequest, user: User = Depends(get_current_user)) -> LegalResponse:
    answer = await get_ai_provider().answer_legal(req.question, req.language)
    return LegalResponse(answer=answer)


# ── Compare: what changed between two versions of a contract ──────────────────
class CompareRequest(BaseModel):
    text_a: str
    text_b: str
    language: str = "uz"


class DiffChangeOut(BaseModel):
    kind: str
    title: str
    detail: str
    risk_level: str


class CompareResponse(BaseModel):
    summary: str
    changes: list[DiffChangeOut]


@router.post("/compare", response_model=CompareResponse)
async def compare_documents(req: CompareRequest, user: User = Depends(get_current_user)) -> CompareResponse:
    result = await get_ai_provider().compare_documents(req.text_a, req.text_b, req.language)
    return CompareResponse(
        summary=result.summary,
        changes=[
            DiffChangeOut(kind=c.kind, title=c.title, detail=c.detail, risk_level=c.risk_level)
            for c in result.changes
        ],
    )
