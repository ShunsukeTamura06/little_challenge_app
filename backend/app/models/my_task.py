from sqlalchemy import Column, Integer, String, DateTime, func

from ..core.database import Base


class MyTask(Base):
    __tablename__ = "my_tasks"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, nullable=False, index=True)
    title = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False, server_default=func.now())

