from pydantic import BaseModel


class UserOut(BaseModel):
    id: str
    identifier: str
    name: str
    role: str
    telegram_connected: bool
    is_premium: bool
    documents_used: int
    documents_quota: int

    model_config = {"from_attributes": True}
