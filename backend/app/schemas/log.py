from typing import Optional
from pydantic import BaseModel


class LogCreate(BaseModel):
    task_id: int
    memo: Optional[str] = None
    feeling: Optional[str] = None


class LogResponse(BaseModel):
    log_id: str
    message: str

