from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import create_engine, Column, Integer, String, ForeignKey, text
from sqlalchemy.orm import sessionmaker, Session, declarative_base, relationship
from typing import List

# --- データベース設定 ---
DATABASE_URL = "postgresql://myuser:mypassword@db:5432/mydatabase"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# --- DB依存性: リクエストごとにDBセッションを確立 ---
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- SQLAlchemyモデル（DBテーブルの定義） ---
# これらのモデルは、DBのテーブル構造をPythonコードで表現したものです。
class Category(Base):
    __tablename__ = "categories"
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False, unique=True)
    description = Column(String)
    challenges = relationship("Challenge", back_populates="category")

class Challenge(Base):
    __tablename__ = "challenges"
    id = Column(Integer, primary_key=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    difficulty = Column(Integer, nullable=False)
    category = relationship("Category", back_populates="challenges")


# --- Pydanticモデル（APIレスポンスの型定義） ---
# APIのレスポンスとして、どの情報をどんな型で返すかを定義します。
# これにより、自動でドキュメントが生成され、型チェックも行われます。
from pydantic import BaseModel

class CategoryResponse(BaseModel):
    id: int
    name: str

    class Config:
        orm_mode = True

class ChallengeResponse(BaseModel):
    id: int
    title: str
    description: str
    difficulty: int
    category: CategoryResponse # ネストしたカテゴリ情報

    class Config:
        orm_mode = True

# --- FastAPIアプリケーション本体 ---
app = FastAPI()

# --- APIエンドポイントの定義 ---
@app.get("/challenges", response_model=List[ChallengeResponse])
def get_challenges(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    """
    挑戦のリストを取得します。
    - skip: 開始位置
    - limit: 取得件数
    """
    challenges = db.query(Challenge).offset(skip).limit(limit).all()
    if not challenges:
        raise HTTPException(status_code=404, detail="Challenges not found")
    return challenges

@app.get("/")
def read_root():
    return {"message": "Welcome to the Little Challenge API!"}