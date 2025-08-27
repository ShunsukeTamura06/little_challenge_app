from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship

from ..core.database import Base


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False, unique=True)

    challenges = relationship("Challenge", back_populates="category")

