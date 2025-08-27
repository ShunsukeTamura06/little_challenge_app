from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from .challenge import ChallengeResponse


class AchievementResponse(BaseModel):
    id: str
    user_id: str
    challenge: ChallengeResponse
    memo: Optional[str] = None
    photo_url: Optional[str] = None
    rating: Optional[int] = None
    feeling: Optional[str] = None
    achieved_at: datetime

    class Config:
        from_attributes = True

