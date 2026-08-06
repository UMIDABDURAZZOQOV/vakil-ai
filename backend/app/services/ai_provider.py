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


@dataclass
class DiffChange:
    kind: str           # "added" | "removed" | "changed"
    title: str
    detail: str
    risk_level: str     # high | medium | low — is this change bad for the user?


@dataclass
class DocumentCompareResult:
    summary: str
    changes: list[DiffChange] = field(default_factory=list)


class AIProvider:
    async def analyze_document(self, text: str, language: str = "uz") -> DocumentAnalysisResult:
        raise NotImplementedError

    async def chat_reply(self, document_text: str, history: list[tuple[bool, str]], question: str) -> str:
        raise NotImplementedError

    async def generate_template(self, template_type: str, fields: dict, language: str = "uz") -> str:
        raise NotImplementedError

    async def answer_legal(self, question: str, language: str = "uz") -> str:
        raise NotImplementedError

    async def compare_documents(self, text_a: str, text_b: str, language: str = "uz") -> DocumentCompareResult:
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

    async def generate_template(self, template_type: str, fields: dict, language: str = "uz") -> str:
        body = "\n".join(f"- {k}: {v}" for k, v in (fields or {}).items())
        return (
            f"[{template_type.upper()} — NAMUNA]\n\n"
            f"Kiritilgan ma'lumotlar:\n{body}\n\n"
            "(Mock: GEMINI_API_KEY sozlanganda bu yerda to'liq, tayyor hujjat matni yaratiladi.)"
        )

    async def answer_legal(self, question: str, language: str = "uz") -> str:
        return (
            "Bu — mock javob. GEMINI_API_KEY sozlanganda haqiqiy yuridik javob keladi.\n\n"
            f"Savolingiz: {question}"
        )

    async def compare_documents(self, text_a: str, text_b: str, language: str = "uz") -> DocumentCompareResult:
        return DocumentCompareResult(
            summary="Mock taqqoslash — GEMINI_API_KEY sozlanganda haqiqiy farqlar chiqadi.",
            changes=[DiffChange(kind="changed", title="Namuna o'zgarish", detail="Mock", risk_level="low")],
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

    async def generate_template(self, template_type: str, fields: dict, language: str = "uz") -> str:
        field_lines = "\n".join(f"- {k}: {v}" for k, v in (fields or {}).items())
        prompt = f"""You are a legal document drafter for Uzbekistan. Draft a complete, ready-to-use
{template_type} in plain, correct {language}. Use the details below; where a detail is missing,
insert a clearly bracketed placeholder like [To'ldiring: ...]. Produce the FULL document with
numbered clauses, parties, obligations, dates and signature lines — professional but readable.
Output ONLY the document text (no commentary, no markdown fences).

DETAILS:
{field_lines}
"""
        response = await self._client.aio.models.generate_content(
            model=self._model,
            contents=prompt,
            config=types.GenerateContentConfig(),
        )
        return response.text or ""

    async def answer_legal(self, question: str, language: str = "uz") -> str:
        prompt = f"""You are Vakil AI, a legal information assistant for everyday people in Uzbekistan.
Answer the question below in clear, plain {language}. Be practical and specific to Uzbek law and
procedures where relevant. Use short paragraphs or bullet points. If the matter is high-stakes or
truly needs a licensed lawyer, say so briefly at the end. Do NOT invent statute numbers you are
unsure of.

QUESTION: {question}
"""
        response = await self._client.aio.models.generate_content(
            model=self._model,
            contents=prompt,
            config=types.GenerateContentConfig(),
        )
        return response.text or ""

    async def compare_documents(self, text_a: str, text_b: str, language: str = "uz") -> DocumentCompareResult:
        from google.genai import types

        prompt = f"""Compare two versions of a contract for a non-lawyer in Uzbekistan. Identify what
changed from VERSION A (old) to VERSION B (new). Respond ONLY with strict JSON:
{{
  "summary": string (one plain-language sentence in {language}),
  "changes": [{{"kind": "added"|"removed"|"changed", "title": string, "detail": string,
               "risk_level": "high"|"medium"|"low"}}]
}}
title/detail/summary must be in {language}. risk_level is how BAD the change is FOR THE USER
(high = worse for them). kind and risk_level MUST be the exact English tokens. Focus on meaningful
changes (money, penalties, dates, obligations, termination) — ignore trivial wording.

VERSION A (old):
{text_a}

VERSION B (new):
{text_b}
"""
        response = await self._client.aio.models.generate_content(
            model=self._model,
            contents=prompt,
            config=types.GenerateContentConfig(response_mime_type="application/json"),
        )
        data = json.loads(response.text)
        return DocumentCompareResult(
            summary=data.get("summary", ""),
            changes=[
                DiffChange(
                    kind=str(c.get("kind", "changed")).lower(),
                    title=c.get("title", ""),
                    detail=c.get("detail", ""),
                    risk_level=_normalize_risk_level(c.get("risk_level")),
                )
                for c in data.get("changes", [])
            ],
        )


class OpenAIAIProvider(AIProvider):
    """OpenAI-backed provider — reuses the OpenAI key/free tokens the owner already
    has. Same prompts/shape as the Gemini provider, via chat.completions."""

    def __init__(self, api_key: str, model: str) -> None:
        from openai import AsyncOpenAI

        self._client = AsyncOpenAI(api_key=api_key)
        self._model = model

    async def _chat(self, prompt: str, json_mode: bool = False) -> str:
        kwargs: dict = {"model": self._model, "messages": [{"role": "user", "content": prompt}]}
        if json_mode:
            kwargs["response_format"] = {"type": "json_object"}
        resp = await self._client.chat.completions.create(**kwargs)
        return resp.choices[0].message.content or ""

    async def analyze_document(self, text: str, language: str = "uz") -> DocumentAnalysisResult:
        prompt = f"""You are a legal-document risk analyst for everyday, non-lawyer users in Uzbekistan.
Analyze the CONTRACT below and respond ONLY with a strict JSON object of this shape:
{{"risk_level":"high|medium|low","risk_score":number(0-10, 10=safest),
"summary_bullets":string[] (plain {language}),"key_dates":string[] ({language}),
"compliance_scores":{{"GDPR":number,"CCPA":number,"HIPAA":number}},
"flags":[{{"title":string,"risk_level":"high|medium|low","explanation":string}}]}}
Every risk_level MUST be exactly "high","medium" or "low" (never translated); all other strings in {language}.
Be specific to the actual clauses — no generic filler.

CONTRACT:
{text}
"""
        data = json.loads(await self._chat(prompt, json_mode=True))
        return DocumentAnalysisResult(
            risk_level=_normalize_risk_level(data.get("risk_level")),
            risk_score=float(data.get("risk_score", 5.0)),
            summary_bullets=data.get("summary_bullets", []),
            key_dates=data.get("key_dates", []),
            compliance_scores=data.get("compliance_scores", {}),
            flags=[
                ClauseFlagResult(title=f["title"], risk_level=_normalize_risk_level(f.get("risk_level")), explanation=f["explanation"])
                for f in data.get("flags", [])
            ],
        )

    async def chat_reply(self, document_text: str, history: list[tuple[bool, str]], question: str) -> str:
        history_text = "\n".join(f"{'User' if is_user else 'AI'}: {t}" for is_user, t in history)
        prompt = f"""You are Vakil AI's legal companion. Answer ONLY using the document below — if the
question needs general legal knowledge beyond it, say so explicitly. Cite the relevant clause when possible.

DOCUMENT:
{document_text}

CONVERSATION SO FAR:
{history_text}

QUESTION: {question}
"""
        return await self._chat(prompt)

    async def generate_template(self, template_type: str, fields: dict, language: str = "uz") -> str:
        field_lines = "\n".join(f"- {k}: {v}" for k, v in (fields or {}).items())
        prompt = f"""You are a legal document drafter for Uzbekistan. Draft a complete, ready-to-use
{template_type} in plain, correct {language}. Use the details below; for missing details insert a
clearly bracketed placeholder like [To'ldiring: ...]. Produce the FULL document with numbered clauses,
parties, obligations, dates and signature lines. Output ONLY the document text.

DETAILS:
{field_lines}
"""
        return await self._chat(prompt)

    async def answer_legal(self, question: str, language: str = "uz") -> str:
        prompt = f"""You are Vakil AI, a legal information assistant for everyday people in Uzbekistan.
Answer the question in clear, plain {language}, practical and specific to Uzbek law where relevant.
Use short paragraphs or bullets. If it truly needs a licensed lawyer, say so briefly at the end.
Do NOT invent statute numbers you are unsure of.

QUESTION: {question}
"""
        return await self._chat(prompt)

    async def compare_documents(self, text_a: str, text_b: str, language: str = "uz") -> DocumentCompareResult:
        prompt = f"""Compare two versions of a contract for a non-lawyer in Uzbekistan. Respond ONLY with a
strict JSON object: {{"summary":string ({language}),"changes":[{{"kind":"added|removed|changed",
"title":string,"detail":string,"risk_level":"high|medium|low"}}]}}. title/detail/summary in {language};
kind and risk_level exactly those English tokens. risk_level = how bad the change is FOR THE USER.
Focus on meaningful changes (money, penalties, dates, obligations, termination).

VERSION A (old):
{text_a}

VERSION B (new):
{text_b}
"""
        data = json.loads(await self._chat(prompt, json_mode=True))
        return DocumentCompareResult(
            summary=data.get("summary", ""),
            changes=[
                DiffChange(kind=str(c.get("kind", "changed")).lower(), title=c.get("title", ""),
                           detail=c.get("detail", ""), risk_level=_normalize_risk_level(c.get("risk_level")))
                for c in data.get("changes", [])
            ],
        )


@lru_cache
def get_ai_provider() -> AIProvider:
    if settings.openai_api_key:
        return OpenAIAIProvider(settings.openai_api_key, settings.openai_model)
    if settings.gemini_api_key:
        return GeminiAIProvider(settings.gemini_api_key)
    return MockAIProvider()
