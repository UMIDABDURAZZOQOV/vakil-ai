from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    identifier: str = Field(..., description="Phone number or email")
    password: str = Field(..., min_length=6)
    name: str = ""


class LoginRequest(BaseModel):
    identifier: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
