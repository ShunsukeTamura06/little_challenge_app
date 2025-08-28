from pydantic import BaseModel
from .category import CategoryResponse
from typing import List, Optional


class ChallengeResponse(BaseModel):
    id: int
    title: str
    description: str
    difficulty: int
    category: CategoryResponse

    class Config:
        from_attributes = True


class ChallengeSummary(BaseModel):
    id: int
    title: str
    tags: List[str]
    description: Optional[str] = None
    difficulty: Optional[int] = None
    is_completed: Optional[bool] = None

    class Config:
        from_attributes = True
