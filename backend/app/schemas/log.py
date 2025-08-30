from typing import Optional
from pydantic import BaseModel
from datetime import datetime


class LogCreate(BaseModel):
    task_id: Optional[int] = None
    my_task_id: Optional[int] = None
    memo: Optional[str] = None
    feeling: Optional[str] = None
    # Client-local achieved time. If provided,保存はクライアント時間基準で行う。
    achieved_at: Optional[datetime] = None


class LogResponse(BaseModel):
    log_id: str
    message: str
