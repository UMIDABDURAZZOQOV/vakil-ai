"""Daily job: find upcoming deadlines (payment dates, renewal windows, notice
periods) extracted from analyzed documents and DM the Telegram user who
uploaded them a few days before they're due.

Run as a separate long-lived process, alongside the API server and the bot:
    python -m app.reminder_worker

Requires TELEGRAM_BOT_TOKEN (same as the bot). A deadline is only reminder-
eligible once `Deadline.due_date` has been parsed — see
`document_service.parse_due_date`. Until Gemini is wired in, the mock AI
provider returns no key_dates, so this job simply has nothing to send yet;
the scheduling plumbing is complete and ready.
"""

import asyncio
import logging
import sys
from datetime import date, timedelta

import httpx
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from .core.config import get_settings
from .db.base import async_session_maker
from .db.models import Deadline, Document, User

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("vakil_ai.reminder_worker")

settings = get_settings()
REMINDER_WINDOW_DAYS = 3
CHECK_INTERVAL_SECONDS = 6 * 60 * 60  # every 6 hours


async def _send_telegram_message(chat_id: str, text: str) -> None:
    url = f"https://api.telegram.org/bot{settings.telegram_bot_token}/sendMessage"
    async with httpx.AsyncClient(timeout=10) as client:
        response = await client.post(url, json={"chat_id": chat_id, "text": text})
        response.raise_for_status()


async def check_and_send_reminders() -> int:
    today = date.today()
    horizon = today + timedelta(days=REMINDER_WINDOW_DAYS)
    sent = 0

    async with async_session_maker() as db:
        result = await db.execute(
            select(Deadline)
            .options(selectinload(Deadline.document).selectinload(Document.owner))
            .where(Deadline.notified.is_(False), Deadline.due_date.is_not(None), Deadline.due_date <= horizon)
        )
        due_deadlines = list(result.scalars().all())

        for deadline in due_deadlines:
            owner: User = deadline.document.owner
            if not owner.telegram_id:
                continue
            days_left = (deadline.due_date - today).days
            when = "bugun" if days_left <= 0 else f"{days_left} kundan keyin"
            text = (
                f"⏰ Eslatma: \"{deadline.document.title}\" hujjatida muddat yaqinlashmoqda ({when}).\n"
                f"{deadline.description}"
            )
            try:
                await _send_telegram_message(owner.telegram_id, text)
                deadline.notified = True
                sent += 1
            except httpx.HTTPError:
                logger.exception("Failed to send reminder for deadline %s", deadline.id)

        await db.commit()

    logger.info("Reminder sweep complete: %d sent, %d checked", sent, len(due_deadlines))
    return sent


async def main() -> None:
    if not settings.telegram_bot_token:
        print(
            "TELEGRAM_BOT_TOKEN yo'q. backend/.env fayliga Telegram bot tokenini qo'shing.",
            file=sys.stderr,
        )
        sys.exit(1)

    logger.info("Vakil AI reminder worker started (checking every %ss)", CHECK_INTERVAL_SECONDS)
    while True:
        await check_and_send_reminders()
        await asyncio.sleep(CHECK_INTERVAL_SECONDS)


if __name__ == "__main__":
    asyncio.run(main())
