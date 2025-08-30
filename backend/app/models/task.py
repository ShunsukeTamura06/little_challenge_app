from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship

from ..core.database import Base


class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    difficulty = Column(Integer, nullable=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    source = Column(String, nullable=False)  # 'catalog' or 'my'
    owner_user_id = Column(String, nullable=True, index=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    category = relationship("Category")

