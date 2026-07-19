from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api.routes import auth, chat, documents, payments, users
from .core.config import get_settings
from .db.base import init_db

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)

# Origins from ALLOWED_ORIGINS env (comma-separated), or "*" for any. The web
# app authenticates with a Bearer token (not cookies), so credentials aren't
# needed and "*" is safe; when specific origins are set we allow credentials too.
_origins = [o.strip() for o in settings.allowed_origins.split(",") if o.strip()]
_allow_all = _origins == ["*"] or not _origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if _allow_all else _origins,
    allow_credentials=not _allow_all,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(documents.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")
app.include_router(payments.router, prefix="/api/v1")


@app.get("/api/v1/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
