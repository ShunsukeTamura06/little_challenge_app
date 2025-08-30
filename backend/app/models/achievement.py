from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
import uuid

from ..core.database import Base


class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=False)
    challenge_id = Column(Integer, ForeignKey("challenges.id"), nullable=True)
    my_task_id = Column(Integer, ForeignKey("my_tasks.id"), nullable=True)
    memo = Column(String, nullable=True)
    photo_url = Column(String, nullable=True)
    rating = Column(Integer, nullable=True)
    feeling = Column(String, nullable=True)
    achieved_at = Column(DateTime, default=func.now(), nullable=False)

    challenge = relationship("Challenge")
    # my_task relationship is not strictly needed for now; resolve ad-hoc when required
