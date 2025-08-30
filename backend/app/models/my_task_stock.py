from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
import uuid

from ..core.database import Base


class MyTaskStock(Base):
    __tablename__ = "my_task_stocks"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=False, index=True)
    my_task_id = Column(Integer, ForeignKey("my_tasks.id"), nullable=False)
    created_at = Column(DateTime, default=func.now(), nullable=False)

    my_task = relationship("MyTask")

