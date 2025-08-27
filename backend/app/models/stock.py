from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
import uuid

from ..core.database import Base


class Stock(Base):
    __tablename__ = "stocks"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=False)
    challenge_id = Column(Integer, ForeignKey("challenges.id"), nullable=False)
    created_at = Column(DateTime, default=func.now(), nullable=False)

    challenge = relationship("Challenge")

