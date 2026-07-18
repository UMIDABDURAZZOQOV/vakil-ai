from datetime import datetime, timedelta, timezone

from ..db.models import User

PREMIUM_PERIOD_DAYS = 30


def activate_premium(user: User) -> None:
    now = datetime.now(timezone.utc)
    current = user.premium_until
    # SQLite drops tzinfo on round-trip even for DateTime(timezone=True)
    # columns; treat naive values as UTC rather than crash on comparison.
    if current is not None and current.tzinfo is None:
        current = current.replace(tzinfo=timezone.utc)
    base = current if (current and current > now) else now
    user.premium_until = base + timedelta(days=PREMIUM_PERIOD_DAYS)
    user.is_premium = True
