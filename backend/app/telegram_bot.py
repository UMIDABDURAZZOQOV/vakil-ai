"""Vakil AI Telegram bot: send a photo or PDF, get an instant plain-language
risk summary — no account required first (per the brief's growth strategy:
distribute through Telegram before asking for a signup).

Run as a separate process from the API server, sharing the same database:
    python -m app.telegram_bot

Requires TELEGRAM_BOT_TOKEN in .env (create a bot via @BotFather). Without
it, this exits with a clear message instead of crashing.
"""

import logging
import sys
import uuid

from sqlalchemy import select
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes, MessageHandler, filters

from .core.config import get_settings
from .core.security import hash_password
from .db.base import async_session_maker, init_db
from .db.models import User
from .services.ai_provider import get_ai_provider
from .services.document_service import extract_text_from_bytes, persist_document_analysis

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("vakil_ai.telegram_bot")

settings = get_settings()

WELCOME_TEXT = (
    "Assalomu alaykum! Men Vakil AI botiman. 📄\n\n"
    "Menga shartnoma yoki boshqa yuridik hujjatning rasmini (yoki PDF faylini) yuboring — "
    "bir necha soniyada xavfli bandlarni va sodda tildagi xulosani qaytaraman.\n\n"
    "Bepul: oyiga 2 ta hujjat tahlili."
)

RISK_EMOJI = {"high": "🔴", "medium": "🟡", "low": "🟢"}


async def _get_or_create_guest_user(db, chat_id: int, name: str) -> User:
    identifier = f"telegram:{chat_id}"
    result = await db.execute(select(User).where(User.telegram_id == str(chat_id)))
    user = result.scalar_one_or_none()
    if user is not None:
        return user

    user = User(
        identifier=identifier,
        hashed_password=hash_password(uuid.uuid4().hex),
        name=name or identifier,
        telegram_id=str(chat_id),
        telegram_connected=True,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


def _format_summary(title: str, analysis) -> str:
    emoji = RISK_EMOJI.get(analysis.risk_level, "⚪")
    lines = [
        f"{emoji} *{title}*",
        f"Xavf darajasi: *{analysis.risk_level.upper()}* ({analysis.risk_score:.1f}/10)",
        "",
    ]
    for bullet in analysis.summary_bullets:
        lines.append(f"• {bullet}")
    if analysis.flags:
        lines.append("")
        lines.append("*Xavfli bandlar:*")
        for flag in analysis.flags[:5]:
            flag_emoji = RISK_EMOJI.get(flag.risk_level, "⚪")
            lines.append(f"{flag_emoji} {flag.title}")
    return "\n".join(lines)


async def _handle_document_bytes(update: Update, raw: bytes, content_type: str, filename: str) -> None:
    chat = update.effective_chat
    message = update.effective_message
    async with async_session_maker() as db:
        user = await _get_or_create_guest_user(db, chat.id, update.effective_user.full_name if update.effective_user else "")

        if not user.is_premium and user.documents_used_this_period >= settings.free_tier_document_limit:
            await message.reply_text(
                "Bepul limit tugadi (oyiga 2 ta hujjat). Premium tarif tez orada ilovada mavjud bo'ladi."
            )
            return

        await message.reply_text("Hujjat tahlil qilinmoqda... ⏳")
        text = extract_text_from_bytes(raw, content_type, filename)
        analysis = await get_ai_provider().analyze_document(text, language="uz")
        await persist_document_analysis(db, user=user, title=filename, text=text, analysis=analysis)

    await message.reply_text(_format_summary(filename, analysis), parse_mode="Markdown")


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    async with async_session_maker() as db:
        await _get_or_create_guest_user(
            db, update.effective_chat.id, update.effective_user.full_name if update.effective_user else ""
        )
    await update.effective_message.reply_text(WELCOME_TEXT)


async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    photo = update.effective_message.photo[-1]  # largest size
    file = await context.bot.get_file(photo.file_id)
    raw = bytes(await file.download_as_bytearray())
    await _handle_document_bytes(update, raw, "image/jpeg", f"telegram-photo-{photo.file_unique_id}.jpg")


async def handle_document(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    doc = update.effective_message.document
    file = await context.bot.get_file(doc.file_id)
    raw = bytes(await file.download_as_bytearray())
    await _handle_document_bytes(update, raw, doc.mime_type or "", doc.file_name or "document")


async def _post_init(application: Application) -> None:
    await init_db()
    logger.info("Vakil AI Telegram bot ready")


def main() -> None:
    if not settings.telegram_bot_token:
        print(
            "TELEGRAM_BOT_TOKEN yo'q. backend/.env fayliga Telegram bot tokenini qo'shing "
            "(BotFather orqali oling), keyin qayta ishga tushiring.",
            file=sys.stderr,
        )
        sys.exit(1)

    application = Application.builder().token(settings.telegram_bot_token).post_init(_post_init).build()
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("help", start))
    application.add_handler(MessageHandler(filters.PHOTO, handle_photo))
    application.add_handler(MessageHandler(filters.Document.ALL, handle_document))
    application.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
