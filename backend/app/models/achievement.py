from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
import uuid

from ..core.database import Base


class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=False)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False)
    memo = Column(String, nullable=True)
    photo_url = Column(String, nullable=True)
    rating = Column(Integer, nullable=True)
    feeling = Column(String, nullable=True)
    achieved_at = Column(DateTime, default=func.now(), nullable=False)

    task = relationship("Task")
