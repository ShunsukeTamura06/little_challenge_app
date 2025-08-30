from pydantic import BaseModel, Field
from typing import Optional


class StockCreate(BaseModel):
    task_id: Optional[str] = Field(default=None, description="Challenge ID (int, as string)")
    my_task_id: Optional[int] = Field(default=None, description="MyTask ID")

class StockResponse(BaseModel):
    id: str
    user_id: str
    challenge_id: int

    class Config:
        orm_mode = True
