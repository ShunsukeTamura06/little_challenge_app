from typing import Optional
from pydantic import BaseModel


class TaskListItem(BaseModel):
    id: int
    title: str
    tags: list[str]
    description: Optional[str] = None
    difficulty: Optional[int] = None
    source: str  # 'catalog' or 'my'

    class Config:
        from_attributes = True

