from collections import defaultdict
from datetime import datetime
import random
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func

from ..core.database import get_db
from ..models import Category, Challenge, Achievement
from ..models.stock import Stock
from ..schemas.category import CategoryResponse
from ..schemas.log import LogCreate, LogResponse
from ..schemas.stock import StockCreate, StockResponse
from ..schemas.challenge import ChallengeSummary
from ..schemas.task import TaskReplaceRequest


router = APIRouter()


# データ投入用エンドポイント（一時的）
@router.post("/admin/init-data")
def initialize_data(db: Session = Depends(get_db)):
    """データベースにテーブル作成と初期データを投入する（一時的なエンドポイント）"""
    try:
        # テーブル作成
        from ..core.database import Base, engine
        Base.metadata.create_all(bind=engine)
        
        # 既にデータがある場合はスキップ
        existing_categories = db.query(Category).count()
        if existing_categories > 0:
            return {"message": f"Data already exists. Categories: {existing_categories}"}
        
        # カテゴリデータを投入
        categories_data = [
            "食事", "運動", "学習", "創造", "交流", "整理", "癒やし"
        ]
        
        category_objects = {}
        for cat_name in categories_data:
            cat = Category(name=cat_name)
            db.add(cat)
            db.flush()  # IDを取得するため
            category_objects[cat_name] = cat
        
        # チャレンジデータの一部を投入（テスト用に10件）
        challenges_data = [
            {
                "category": "食事",
                "title": "利き手ではない方の手でお箸を使って食事する",
                "description": "普段とは違う手でお箸を使うことで、脳の新しい部分が刺激され、いつもの食事が新鮮な体験に変わります。",
                "difficulty": 2
            },
            {
                "category": "食事",
                "title": "コンビニで見たことのない商品を1つ選んで買う",
                "description": "普段手に取らない新商品や地域限定品を直感で選んでみましょう。予想外の美味しさとの出会いが期待できます。",
                "difficulty": 1
            },
            {
                "category": "運動",
                "title": "エスカレーターを使わずに階段を一つ多く使う",
                "description": "普段エスカレーターを使う場所で階段を選んでみましょう。ほんの少しの運動でも、体が軽やかになります。",
                "difficulty": 1
            },
            {
                "category": "運動",
                "title": "朝起きて5分間ストレッチをする",
                "description": "起床後の5分間を体をほぐす時間にしてみませんか。筋肉の緊張がほぐれ、一日の始まりが気持ちよくスタートできます。",
                "difficulty": 2
            },
            {
                "category": "学習",
                "title": "今日知らなかった新しい単語を1つ覚える",
                "description": "辞書やインターネットで新しい言葉を一つ見つけて覚えてみませんか。語彙が増えることで、表現力も豊かになります。",
                "difficulty": 2
            },
            {
                "category": "創造",
                "title": "スマホで撮った写真に映画のタイトルのような名前をつける",
                "description": "何気なく撮った写真を見返して、まるで映画のワンシーンのようなタイトルを考えてみませんか。",
                "difficulty": 2
            },
            {
                "category": "交流",
                "title": "家族に今日あった良いことを一つ話す",
                "description": "些細なことでも構いません。今日の良い出来事を家族とシェアしてみましょう。",
                "difficulty": 1
            },
            {
                "category": "整理",
                "title": "デスクの上を5分間で整理する",
                "description": "散らかったデスクを短時間で整理してみませんか。すっきりした環境は集中力を高めます。",
                "difficulty": 1
            },
            {
                "category": "癒やし",
                "title": "好きな香りのお茶を丁寧に淹れて味わう",
                "description": "急須やティーポットで丁寧にお茶を淹れ、香りと味をゆっくりと楽しんでみませんか。",
                "difficulty": 1
            },
            {
                "category": "癒やし",
                "title": "温かいお風呂にいつもより長く浸かる",
                "description": "普段はシャワーで済ませがちでも、今日は湯船にゆっくり浸かってみませんか。",
                "difficulty": 1
            }
        ]
        
        for challenge_data in challenges_data:
            category = category_objects[challenge_data["category"]]
            challenge = Challenge(
                category_id=category.id,
                title=challenge_data["title"],
                description=challenge_data["description"],
                difficulty=challenge_data["difficulty"]
            )
            db.add(challenge)
        
        db.commit()
        
        # 投入されたデータをカウント
        total_categories = db.query(Category).count()
        total_challenges = db.query(Challenge).count()
        
        return {
            "message": "Data initialization completed successfully!",
            "categories_created": total_categories,
            "challenges_created": total_challenges
        }
        
    except Exception as e:
        db.rollback()
        return {"error": f"Failed to initialize data: {str(e)}"}


@router.get("/tasks/daily")
def get_daily_task(force_refresh: bool = False, db: Session = Depends(get_db)):
    random_task = (
        db.query(Challenge)
        .options(joinedload(Challenge.category))
        .order_by(func.random())
        .first()
    )

    if random_task is None:
        raise HTTPException(status_code=404, detail="No tasks found in the database.")

    return {
        "id": str(random_task.id),
        "title": random_task.title,
        "description": random_task.description,
        "difficulty": random_task.difficulty,
        "tags": [random_task.category.name],
        "stats": {"completion_rate": random.uniform(0.1, 0.8)},
    }


@router.post("/tasks/daily/replace")
def replace_daily_task(req: TaskReplaceRequest, db: Session = Depends(get_db)):
    try:
        task_id = int(req.new_task_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid new_task_id format.")

    new_task = (
        db.query(Challenge)
        .options(joinedload(Challenge.category))
        .filter(Challenge.id == task_id)
        .first()
    )

    if new_task is None:
        raise HTTPException(status_code=404, detail="New task not found.")

    # The spec says the response should be the same as GET /tasks/daily
    return {
        "id": str(new_task.id),
        "title": new_task.title,
        "description": new_task.description,
        "difficulty": new_task.difficulty,
        "tags": [new_task.category.name],
        "stats": {"completion_rate": random.uniform(0.1, 0.8)}, # Assuming random stats for replaced tasks
    }


@router.post("/logs", response_model=LogResponse, status_code=201)
def create_log(log: LogCreate, db: Session = Depends(get_db)):
    user_id = "user_123"  # TODO: replace with real auth

    db_challenge = db.query(Challenge).filter(Challenge.id == log.task_id).first()
    if db_challenge is None:
        raise HTTPException(status_code=404, detail="Challenge not found")

    db_log = Achievement(
        user_id=user_id,
        challenge_id=log.task_id,
        memo=log.memo,
        feeling=log.feeling,
    )
    db.add(db_log)
    db.commit()
    db.refresh(db_log)

    return {"log_id": db_log.id, "message": "Successfully created."}


@router.post("/stock", response_model=StockResponse, status_code=201)
def create_stock(stock: StockCreate, db: Session = Depends(get_db)):
    user_id = "user_123"  # TODO: replace with real auth

    try:
        task_id_int = int(stock.task_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid task_id format. Must be an integer.")

    db_challenge = db.query(Challenge).filter(Challenge.id == task_id_int).first()
    if db_challenge is None:
        raise HTTPException(status_code=404, detail="Challenge not found")

    # Check if the task is already stocked by the user
    existing_stock = (
        db.query(Stock)
        .filter(Stock.user_id == user_id, Stock.challenge_id == task_id_int)
        .first()
    )
    if existing_stock:
        # Just return the existing stock item
        return existing_stock

    db_stock = Stock(
        user_id=user_id,
        challenge_id=task_id_int,
    )
    db.add(db_stock)
    db.commit()
    db.refresh(db_stock)

    return db_stock


@router.delete("/stock/by-challenge/{challenge_id}", status_code=204)
def delete_stock_by_challenge_id(challenge_id: int, db: Session = Depends(get_db)):
    user_id = "user_123"  # TODO: replace with real auth

    stock_item = (
        db.query(Stock)
        .filter(Stock.user_id == user_id, Stock.challenge_id == challenge_id)
        .first()
    )

    if stock_item:
        db.delete(stock_item)
        db.commit()

    return Response(status_code=204)


@router.get("/logs")
def get_logs(month: Optional[str] = None, db: Session = Depends(get_db)):
    user_id = "user_123"
    query = (
        db.query(Achievement)
        .options(joinedload(Achievement.challenge).joinedload(Challenge.category))
        .filter(Achievement.user_id == user_id)
    )

    if month:
        try:
            year, mon = map(int, month.split("-"))
            start_date = datetime(year, mon, 1)
            end_date = datetime(year, mon + 1, 1) if mon < 12 else datetime(year + 1, 1, 1)
            query = query.filter(
                Achievement.achieved_at >= start_date, Achievement.achieved_at < end_date
            )
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid month format. Use YYYY-MM.")

    logs = query.order_by(Achievement.achieved_at.desc()).all()

    def achievement_to_dict(achievement: Achievement):
        return {
            "id": achievement.id,
            "user_id": achievement.user_id,
            "memo": achievement.memo,
            "feeling": achievement.feeling,
            "achieved_at": achievement.achieved_at.isoformat(),
            "challenge": {
                "id": achievement.challenge.id,
                "title": achievement.challenge.title,
                "description": achievement.challenge.description,
                "difficulty": achievement.challenge.difficulty,
                "category": {
                    "id": achievement.challenge.category.id,
                    "name": achievement.challenge.category.name,
                },
            },
        }

    grouped_logs = defaultdict(list)
    for log in logs:
        date_str = log.achieved_at.strftime("%Y-%m-%d")
        grouped_logs[date_str].append(achievement_to_dict(log))

    return grouped_logs


@router.get("/stock", response_model=List[ChallengeSummary])
def get_stocked_tasks(db: Session = Depends(get_db)):
    user_id = "user_123"  # TODO: replace with real auth

    stocked_items = (
        db.query(Stock)
        .options(joinedload(Stock.challenge).joinedload(Challenge.category))
        .filter(Stock.user_id == user_id)
        .order_by(Stock.created_at.desc())
        .all()
    )

    results = []
    for item in stocked_items:
        ch = item.challenge
        results.append(
            {
                "id": str(ch.id),
                "title": ch.title,
                "tags": [ch.category.name],
                "description": ch.description,
                "difficulty": ch.difficulty,
            }
        )
    return results


@router.get("/challenges/search", response_model=List[ChallengeSummary])
def search_challenges(
    q: Optional[str] = None,
    category_id: Optional[int] = None,
    db: Session = Depends(get_db),
):
    user_id = "user_123"  # TODO: replace with real auth
    query = db.query(Challenge).options(joinedload(Challenge.category))

    if q:
        query = query.filter(Challenge.title.ilike(f"%{q}%"))

    if category_id:
        query = query.filter(Challenge.category_id == category_id)

    challenges = query.all()

    # Get all achievements for the user to check completion status
    user_achievements = (
        db.query(Achievement.challenge_id)
        .filter(Achievement.user_id == user_id)
        .all()
    )
    completed_challenge_ids = {ach.challenge_id for ach in user_achievements}

    results = []
    for ch in challenges:
        results.append(
            {
                "id": ch.id,
                "title": ch.title,
                "tags": [ch.category.name],
                "is_completed": ch.id in completed_challenge_ids,
            }
        )

    return results


@router.get("/categories", response_model=List[CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    categories = db.query(Category).order_by(Category.name).all()
    return categories
