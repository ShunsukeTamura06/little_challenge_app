# backend/main.py

from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import create_engine, Column, Integer, String, ForeignKey, func
from sqlalchemy.orm import sessionmaker, Session, declarative_base, relationship, joinedload
from typing import List
import uuid
import random

# --- データベースとモデルのセットアップ（モデルを追加） ---
DATABASE_URL = "postgresql://myuser:mypassword@db:5432/mydatabase"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class Category(Base):
    __tablename__ = "categories"
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False, unique=True)
    challenges = relationship("Challenge", back_populates="category")

class Challenge(Base):
    __tablename__ = "challenges"
    id = Column(Integer, primary_key=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    difficulty = Column(Integer, nullable=False)
    category = relationship("Category", back_populates="challenges")

# achievementsテーブル用の新しいモデル
class Achievement(Base):
    __tablename__ = "achievements"
    # UUIDを文字列として保存。デフォルトで新しいUUIDを生成
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=False) # 簡単のため、一旦文字列として扱う
    challenge_id = Column(Integer, ForeignKey("challenges.id"), nullable=False)
    challenge = relationship("Challenge")

# --- Pydanticモデル ---
from pydantic import BaseModel

class CategoryResponse(BaseModel):
    id: int
    name: str
    class Config: from_attributes = True

class ChallengeResponse(BaseModel):
    id: int
    title: str
    description: str
    difficulty: int
    category: CategoryResponse
    class Config: from_attributes = True

# 達成報告用の新しいPydanticモデル
class AchievementCreate(BaseModel):
    challenge_id: int

class AchievementResponse(BaseModel):
    id: str
    user_id: str
    challenge: ChallengeResponse
    class Config: from_attributes = True


# --- FastAPIアプリケーション ---
app = FastAPI()

# --- APIエンドポイント ---

@app.get("/tasks/daily")
def get_daily_task(db: Session = Depends(get_db)):
    """
    Provides a single daily task based on the format specified in gemini.md.
    Uses SQLAlchemy ORM.
    """
    random_task = db.query(Challenge).options(joinedload(Challenge.category)).order_by(func.random()).first()

    if random_task is None:
        raise HTTPException(status_code=404, detail="No tasks found in the database.")

    # Format the response according to the spec
    response_data = {
        "id": str(random_task.id),
        "title": random_task.title,
        "tags": [random_task.category.name],
        "stats": {
            "completion_rate": random.uniform(0.1, 0.8)
        }
    }
    return response_data

@app.post("/achievements", response_model=AchievementResponse, status_code=201)
def create_achievement(achievement: AchievementCreate, db: Session = Depends(get_db)):
    # 一旦、user_idは固定値を使います。後で本当の認証機能を追加します。
    user_id = "user_123"
    
    # 挑戦が存在するか確認
    db_challenge = db.query(Challenge).filter(Challenge.id == achievement.challenge_id).first()
    if db_challenge is None:
        raise HTTPException(status_code=404, detail="Challenge not found")
        
    db_achievement = Achievement(
        user_id=user_id,
        challenge_id=achievement.challenge_id
    )
    db.add(db_achievement)
    db.commit()
    db.refresh(db_achievement)
    return db_achievement

@app.get("/achievements", response_model=List[AchievementResponse])
def get_achievements(db: Session = Depends(get_db)):
    # 固定ユーザーの達成記録を取得
    user_id = "user_123"
    achievements = db.query(Achievement).filter(Achievement.user_id == user_id).order_by(Achievement.id.desc()).all()
    return achievements

@app.get("/challenges", response_model=List[ChallengeResponse])
def get_challenges(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    challenges = db.query(Challenge).offset(skip).limit(limit).all()
    if not challenges:
        raise HTTPException(status_code=404, detail="Challenges not found")
    return challenges

@app.get("/")
def read_root():
    return {"message": "Welcome to the Little Challenge API!"}
