from datetime import datetime

from pydantic import BaseModel


class ChatMessageIn(BaseModel):
    text: str


class ChatMessageOut(BaseModel):
    id: str
    is_user: bool
    text: str
    created_at: datetime

    model_config = {"from_attributes": True}
