from datetime import datetime
from pydantic import BaseModel, Field
from typing import Optional


class MyTaskCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)


class MyTaskUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)


class MyTaskResponse(BaseModel):
    id: int
    title: str
    created_at: datetime

    class Config:
        from_attributes = True

