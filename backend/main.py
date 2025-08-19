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
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=False) # 簡単のため、一旦文字列として扱う
    challenge_id = Column(Integer, ForeignKey("challenges.id"), nullable=False)
    memo = Column(String, nullable=True)
    feeling = Column(String, nullable=True)
    challenge = relationship("Challenge")

# --- Pydanticモデル ---
from pydantic import BaseModel
from typing import Optional

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
class LogCreate(BaseModel):
    task_id: int
    memo: Optional[str] = None
    feeling: Optional[str] = None

class LogResponse(BaseModel):
    log_id: str
    message: str

class AchievementResponse(BaseModel):
    id: str
    user_id: str
    challenge: ChallengeResponse
    memo: Optional[str] = None
    feeling: Optional[str] = None
    class Config: from_attributes = True


# --- FastAPIアプリケーション ---
app = FastAPI()

# --- APIエンドポイント ---

@app.get("/tasks/daily")
def get_daily_task(force_refresh: bool = False, db: Session = Depends(get_db)):
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

@app.post("/logs", response_model=LogResponse, status_code=201)
def create_log(log: LogCreate, db: Session = Depends(get_db)):
    user_id = "user_123"  # Fixed user_id for now

    db_challenge = db.query(Challenge).filter(Challenge.id == log.task_id).first()
    if db_challenge is None:
        raise HTTPException(status_code=404, detail="Challenge not found")

    db_log = Achievement(
        user_id=user_id,
        challenge_id=log.task_id,
        memo=log.memo,
        feeling=log.feeling
    )
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    
    return {"log_id": db_log.id, "message": "Successfully created."}

@app.get("/logs", response_model=List[AchievementResponse])
def get_logs(db: Session = Depends(get_db)):
    user_id = "user_123"
    logs = db.query(Achievement).filter(Achievement.user_id == user_id).order_by(Achievement.id.desc()).all()
    return logs

@app.get("/challenges", response_model=List[ChallengeResponse])
def get_challenges(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    challenges = db.query(Challenge).offset(skip).limit(limit).all()
    if not challenges:
        raise HTTPException(status_code=404, detail="Challenges not found")
    return challenges

class StockCreate(BaseModel):
    task_id: int

class StockResponse(BaseModel):
    stock_id: str
    message: str

@app.post("/stock", response_model=StockResponse, status_code=201)
def create_stock(stock: StockCreate, db: Session = Depends(get_db)):
    """
    Adds a task to the user's stock.
    (Currently a dummy implementation)
    """
    # TODO: Implement actual database logic to store the stocked task
    # For now, just log it and return a success response.
    print(f"Task ID {stock.task_id} received to be stocked.")

    # Dummy response
    return {
        "stock_id": f"stock_{uuid.uuid4()}",
        "message": f"Task {stock.task_id} has been successfully stocked."
    }

@app.get("/stock", response_model=List[ChallengeResponse])
def get_stock(db: Session = Depends(get_db)):
    """
    Retrieves the list of stocked tasks.
    (Currently returns a dummy list of challenges)
    """
    # TODO: Implement actual logic to retrieve stocked tasks for the user.
    # For now, return a few random challenges as dummy data.
    dummy_stocked_tasks = db.query(Challenge).options(joinedload(Challenge.category)).order_by(func.random()).limit(3).all()
    if not dummy_stocked_tasks:
        # If the database is empty, return an empty list.
        return []
    return dummy_stocked_tasks

class TaskReplaceRequest(BaseModel):
    new_task_id: int
    source: str # e.g., "stock", "my_task"

@app.post("/tasks/daily/replace", response_model=ChallengeResponse)
def replace_daily_task(request: TaskReplaceRequest, db: Session = Depends(get_db)):
    """
    Replaces the daily task with a new one from stock or my_tasks.
    (Currently a dummy implementation)
    """
    # TODO: Implement the actual logic of replacing the daily task.
    # For now, just fetch the requested challenge and return it.
    new_task = db.query(Challenge).options(joinedload(Challenge.category)).filter(Challenge.id == request.new_task_id).first()
    if not new_task:
        raise HTTPException(status_code=404, detail=f"Challenge with id {request.new_task_id} not found.")
    
    # The response format for a single challenge needs to be adapted.
    # Let's re-use the ChallengeResponse model which should be compatible.
    return new_task

@app.get("/")
def read_root():
    return {"message": "Welcome to the Little Challenge API!"}
