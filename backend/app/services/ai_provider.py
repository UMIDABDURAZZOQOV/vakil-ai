"""AI abstraction layer.

Every route talks to `get_ai_provider()`, never to Gemini directly. With no
GEMINI_API_KEY set, MockAIProvider returns deterministic, structurally-real
responses so the rest of the product (auth, storage, quotas, Telegram, UI)
can be built and demoed before the API key exists. Set GEMINI_API_KEY in
.env to switch to GeminiAIProvider without touching any route code.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from functools import lru_cache

from ..core.config import get_settings

settings = get_settings()

RISK_KEYWORDS = {
    "high": ["bekor qilish", "javobgarlik", "cheksiz", "indemnif", "termination", "liability", "unlimited"],
    "medium": ["muddat", "notice", "penalty", "jarima", "deadline"],
}

_RISK_LEVEL_ALIASES = {
    "high": "high",
    "yuqori": "high",
    "высокий": "high",
    "medium": "medium",
    "o'rta": "medium",
    "o'rtacha": "medium",
    "ortacha": "medium",
    "средний": "medium",
    "low": "low",
    "past": "low",
    "низкий": "low",
}


def _normalize_risk_level(value: str | None) -> str:
    """Gemini is instructed to always return the English tokens high/medium/low,
    but LLMs don't always follow formatting instructions perfectly — this maps
    common Uzbek/Russian translations back to the canonical token the rest of
    the app (UI colors, badges) expects, defaulting to "low" like the Flutter
    side does for any unrecognized value."""
    if not value:
        return "low"
    return _RISK_LEVEL_ALIASES.get(value.strip().lower(), "low")


@dataclass
class ClauseFlagResult:
    title: str
    risk_level: str
    explanation: str


@dataclass
class DocumentAnalysisResult:
    risk_level: str
    risk_score: float
    summary_bullets: list[str]
    key_dates: list[str]
    compliance_scores: dict[str, int]
    flags: list[ClauseFlagResult] = field(default_factory=list)


class AIProvider:
    async def analyze_document(self, text: str, language: str = "uz") -> DocumentAnalysisResult:
        raise NotImplementedError

    async def chat_reply(self, document_text: str, history: list[tuple[bool, str]], question: str) -> str:
        raise NotImplementedError


class MockAIProvider(AIProvider):
    """Heuristic, keyword-based stand-in. No network calls, no API key."""

    async def analyze_document(self, text: str, language: str = "uz") -> DocumentAnalysisResult:
        lowered = text.lower()
        paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()] or [text.strip() or "(empty)"]

        flags: list[ClauseFlagResult] = []
        for i, para in enumerate(paragraphs[:6]):
            para_lower = para.lower()
            if any(k in para_lower for k in RISK_KEYWORDS["high"]):
                level = "high"
            elif any(k in para_lower for k in RISK_KEYWORDS["medium"]):
                level = "medium"
            else:
                continue
            flags.append(
                ClauseFlagResult(
                    title=(para[:60] + ("…" if len(para) > 60 else "")),
                    risk_level=level,
                    explanation="Mock tahlil: kalit so'zlar asosida aniqlangan. Gemini API kaliti ulanganda, "
                    "bu yerda haqiqiy tushuntirish keladi.",
                )
            )

        high_count = sum(1 for f in flags if f.risk_level == "high")
        medium_count = sum(1 for f in flags if f.risk_level == "medium")
        if high_count > 0:
            overall = "high"
            score = max(2.0, 8.5 - high_count * 0.5)
        elif medium_count > 0:
            overall = "medium"
            score = 6.0
        else:
            overall = "low"
            score = 9.2

        return DocumentAnalysisResult(
            risk_level=overall,
            risk_score=round(score, 1),
            summary_bullets=[
                f"Hujjatda {len(paragraphs)} ta band aniqlandi, shundan {len(flags)} tasi e'tibor talab qiladi.",
                "Bu — mock (namunaviy) tahlil. Haqiqiy AI xulosasi uchun GEMINI_API_KEY sozlang.",
            ],
            key_dates=[],
            compliance_scores={"GDPR": 80, "CCPA": 82, "HIPAA": 75},
            flags=flags,
        )

    async def chat_reply(self, document_text: str, history: list[tuple[bool, str]], question: str) -> str:
        return (
            "Bu — mock javob. Savolingiz: \"" + question + "\". "
            "GEMINI_API_KEY sozlanganda, javob faqat yuklangan hujjatingiz matniga asoslanadi "
            "va aniq band raqami bilan keltiriladi."
        )


class GeminiAIProvider(AIProvider):
    def __init__(self, api_key: str) -> None:
        from google import genai  # imported lazily so the mock path has zero Gemini dependency cost

        self._genai = genai
        self._client = genai.Client(api_key=api_key)
        self._model = "gemini-2.5-flash"

    async def analyze_document(self, text: str, language: str = "uz") -> DocumentAnalysisResult:
        from google.genai import types

        prompt = f"""You are a legal-document risk analyst for everyday, non-lawyer users in Uzbekistan.
Analyze the CONTRACT below and respond ONLY with strict JSON matching this shape:
{{
  "risk_level": "high" | "medium" | "low",
  "risk_score": number (0-10, 10 = safest),
  "summary_bullets": string[] (plain-language, in {language}),
  "key_dates": string[] (in {language}),
  "compliance_scores": {{"GDPR": number, "CCPA": number, "HIPAA": number}} (0-100 estimates),
  "flags": [{{"title": string, "risk_level": "high"|"medium"|"low", "explanation": string}}]
}}

IMPORTANT: every "risk_level" value (both the top-level one and each flag's) MUST be exactly
one of the three literal English words "high", "medium", or "low" — never translate these,
even though every other string field (summary_bullets, key_dates, title, explanation) must be
written in {language}. risk_level is a machine-readable code, not display text.

Be specific to the actual clauses in the document — never generic filler.

CONTRACT:
{text}
"""
        response = await self._client.aio.models.generate_content(
            model=self._model,
            contents=prompt,
            config=types.GenerateContentConfig(response_mime_type="application/json"),
        )
        data = json.loads(response.text)
        return DocumentAnalysisResult(
            risk_level=_normalize_risk_level(data.get("risk_level")),
            risk_score=float(data.get("risk_score", 5.0)),
            summary_bullets=data.get("summary_bullets", []),
            key_dates=data.get("key_dates", []),
            compliance_scores=data.get("compliance_scores", {}),
            flags=[
                ClauseFlagResult(
                    title=f["title"],
                    risk_level=_normalize_risk_level(f.get("risk_level")),
                    explanation=f["explanation"],
                )
                for f in data.get("flags", [])
            ],
        )

    async def chat_reply(self, document_text: str, history: list[tuple[bool, str]], question: str) -> str:
        from google.genai import types

        history_text = "\n".join(f"{'User' if is_user else 'AI'}: {t}" for is_user, t in history)
        prompt = f"""You are Vakil AI's legal companion. Answer ONLY using the document below — if the
question needs general legal knowledge beyond this document, say so explicitly. Cite the
relevant clause/section when possible.

DOCUMENT:
{document_text}

CONVERSATION SO FAR:
{history_text}

QUESTION: {question}
"""
        response = await self._client.aio.models.generate_content(
            model=self._model,
            contents=prompt,
            config=types.GenerateContentConfig(),
        )
        return response.text or ""


@lru_cache
def get_ai_provider() -> AIProvider:
    if settings.gemini_api_key:
        return GeminiAIProvider(settings.gemini_api_key)
    return MockAIProvider()
