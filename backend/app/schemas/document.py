from datetime import datetime

from pydantic import BaseModel


class ClauseFlagOut(BaseModel):
    title: str
    risk_level: str
    explanation: str

    model_config = {"from_attributes": True}


class DocumentSummary(BaseModel):
    id: str
    title: str
    status: str
    risk_level: str
    risk_score: float
    created_at: datetime

    model_config = {"from_attributes": True}


class DocumentDetail(DocumentSummary):
    original_text: str
    summary_bullets: list[str]
    key_dates: list[str]
    compliance_scores: dict[str, int]
    flags: list[ClauseFlagOut]
