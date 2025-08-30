from collections import defaultdict
from datetime import datetime
import random
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Response, Header
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func

from ..core.database import get_db
from ..models import Category, Challenge, Achievement, MyTask, MyTaskStock
from ..models.stock import Stock
from ..schemas.category import CategoryResponse
from ..schemas.log import LogCreate, LogResponse
from ..schemas.stock import StockCreate, StockResponse
from ..schemas.challenge import ChallengeSummary
from ..schemas.task_list import TaskListItem
from ..schemas.task import TaskReplaceRequest
from ..schemas.my_task import MyTaskCreate, MyTaskUpdate, MyTaskResponse


router = APIRouter()


# Simple dependency to resolve current user id from header
def get_current_user_id(x_user_id: str = Header(..., alias="X-User-Id")) -> str:
    """
    Resolve the current user from the `X-User-Id` header.
    For production, replace with proper authentication (e.g., Sign in with Apple).
    """
    if not x_user_id or not x_user_id.strip():
        raise HTTPException(status_code=400, detail="X-User-Id header is required")
    return x_user_id.strip()

@router.get("/healthz")
def healthz():
    return {"status": "ok"}


# データ投入用エンドポイント（一時的）: scripts/load_data.py の100件データを利用
@router.post("/admin/init-data")
def initialize_data(db: Session = Depends(get_db)):
    """テーブル作成と初期データ投入。scripts/load_data.py の100件データを使用し、未登録のみ追加。"""
    try:
        # テーブル作成
        from ..core.database import Base, engine
        Base.metadata.create_all(bind=engine)

        # データセットを import（backend/scripts/load_data.py の tasks）
        try:
            from scripts.load_data import tasks  # type: ignore
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to import seed tasks: {e}")

        # カテゴリの用意（存在しないもののみ作成）
        category_map = {c.name: c for c in db.query(Category).all()}
        for t in tasks:
            name = t.get("category")
            if name and name not in category_map:
                cat = Category(name=name)
                db.add(cat)
                db.flush()
                category_map[name] = cat

        inserted, skipped = 0, 0
        # チャレンジを未登録のみ追加（カテゴリ+タイトルで重複回避）
        for t in tasks:
            cat = category_map.get(t.get("category"))
            if not cat:
                continue
            exists = (
                db.query(Challenge)
                .filter(Challenge.category_id == cat.id, Challenge.title == t.get("title"))
                .first()
            )
            if exists:
                skipped += 1
                continue
            ch = Challenge(
                category_id=cat.id,
                title=t.get("title"),
                description=t.get("description"),
                difficulty=int(t.get("difficulty") or 1),
            )
            db.add(ch)
            inserted += 1

        db.commit()

        total_categories = db.query(Category).count()
        total_challenges = db.query(Challenge).count()
        return {
            "message": "Initialization done",
            "inserted": inserted,
            "skipped": skipped,
            "categories_total": total_categories,
            "challenges_total": total_challenges,
        }

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to initialize data: {e}")


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
def replace_daily_task(
    req: TaskReplaceRequest,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    # If my_task_id provided, return MyTask as daily
    if req.my_task_id is not None:
        mt = db.query(MyTask).filter(MyTask.id == req.my_task_id, MyTask.user_id == user_id).first()
        if not mt:
            raise HTTPException(status_code=404, detail="MyTask not found")
        return {
            "id": f"my-{mt.id}",
            "title": mt.title,
            "description": None,
            "difficulty": None,
            "tags": ["My Task"],
            "stats": {"completion_rate": random.uniform(0.1, 0.8)},
        }

    if not req.new_task_id:
        raise HTTPException(status_code=400, detail="new_task_id or my_task_id required")
    try:
        task_id = int(req.new_task_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid new_task_id format.")

    new_task = (
        db.query(Challenge)
        .options(joinedload(Challenge.category))
        .filter(Challenge.id == task_id)
        .first()
    )

    if new_task is None:
        raise HTTPException(status_code=404, detail="New task not found.")

    return {
        "id": str(new_task.id),
        "title": new_task.title,
        "description": new_task.description,
        "difficulty": new_task.difficulty,
        "tags": [new_task.category.name],
        "stats": {"completion_rate": random.uniform(0.1, 0.8)},
    }


@router.post("/logs", response_model=LogResponse, status_code=201)
def create_log(
    log: LogCreate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):

    db_challenge = db.query(Challenge).filter(Challenge.id == log.task_id).first()
    if db_challenge is None:
        raise HTTPException(status_code=404, detail="Challenge not found")

    db_log = Achievement(
        user_id=user_id,
        challenge_id=log.task_id,
        memo=log.memo,
        feeling=log.feeling,
        # Save in client-local time when provided; otherwise use DB default
        achieved_at=log.achieved_at if log.achieved_at is not None else None,
    )
    db.add(db_log)
    db.commit()
    db.refresh(db_log)

    return {"log_id": db_log.id, "message": "Successfully created."}


@router.post("/stock", status_code=201)
def create_stock(
    stock: StockCreate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    # Handle MyTask stocks
    if stock.my_task_id is not None:
        mt = db.query(MyTask).filter(MyTask.id == stock.my_task_id, MyTask.user_id == user_id).first()
        if not mt:
            raise HTTPException(status_code=404, detail="MyTask not found")
        existing = (
            db.query(MyTaskStock)
            .filter(MyTaskStock.user_id == user_id, MyTaskStock.my_task_id == stock.my_task_id)
            .first()
        )
        if existing:
            return {"status": "exists"}
        item = MyTaskStock(user_id=user_id, my_task_id=stock.my_task_id)
        db.add(item)
        db.commit()
        db.refresh(item)
        return {"status": "created", "id": item.id}

    # Challenge stocks (legacy)
    if stock.task_id is None:
        raise HTTPException(status_code=400, detail="Either my_task_id or task_id is required")
    try:
        task_id_int = int(stock.task_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid task_id format. Must be an integer.")

    db_challenge = db.query(Challenge).filter(Challenge.id == task_id_int).first()
    if db_challenge is None:
        raise HTTPException(status_code=404, detail="Challenge not found")

    existing_stock = (
        db.query(Stock)
        .filter(Stock.user_id == user_id, Stock.challenge_id == task_id_int)
        .first()
    )
    if existing_stock:
        return {"status": "exists"}

    db_stock = Stock(user_id=user_id, challenge_id=task_id_int)
    db.add(db_stock)
    db.commit()
    db.refresh(db_stock)
    return {"status": "created", "id": db_stock.id}


@router.delete("/stock/by-challenge/{challenge_id}", status_code=204)
def delete_stock_by_challenge_id(
    challenge_id: int, db: Session = Depends(get_db), user_id: str = Depends(get_current_user_id)
):

    stock_item = (
        db.query(Stock)
        .filter(Stock.user_id == user_id, Stock.challenge_id == challenge_id)
        .first()
    )

    if stock_item:
        db.delete(stock_item)
        db.commit()

    return Response(status_code=204)


@router.delete("/stock/by-my-task/{my_task_id}", status_code=204)
def delete_stock_by_my_task_id(
    my_task_id: int, db: Session = Depends(get_db), user_id: str = Depends(get_current_user_id)
):
    stock_item = (
        db.query(MyTaskStock)
        .filter(MyTaskStock.user_id == user_id, MyTaskStock.my_task_id == my_task_id)
        .first()
    )
    if stock_item:
        db.delete(stock_item)
        db.commit()
    return Response(status_code=204)


@router.get("/logs")
def get_logs(
    month: Optional[str] = None,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
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


@router.get("/stock", response_model=List[TaskListItem])
def get_stocked_tasks(db: Session = Depends(get_db), user_id: str = Depends(get_current_user_id)):

    ch_stocks = (
        db.query(Stock)
        .options(joinedload(Stock.challenge).joinedload(Challenge.category))
        .filter(Stock.user_id == user_id)
        .all()
    )
    my_stocks = (
        db.query(MyTaskStock)
        .options(joinedload(MyTaskStock.my_task))
        .filter(MyTaskStock.user_id == user_id)
        .all()
    )

    unified: list[tuple[dict, "datetime"]] = []  # (payload, created_at)
    for s in ch_stocks:
        ch = s.challenge
        unified.append(
            (
                {
                    "id": ch.id,
                    "title": ch.title,
                    "tags": [ch.category.name],
                    "description": ch.description,
                    "difficulty": ch.difficulty,
                    "source": "catalog",
                },
                s.created_at,
            )
        )
    for s in my_stocks:
        mt = s.my_task
        unified.append(
            (
                {
                    "id": mt.id,
                    "title": mt.title,
                    "tags": ["My Task"],
                    "description": None,
                    "difficulty": None,
                    "source": "my",
                },
                s.created_at,
            )
        )

    unified.sort(key=lambda x: x[1], reverse=True)
    return [u[0] for u in unified]


@router.get("/stock/my")
def get_my_task_stocks(db: Session = Depends(get_db), user_id: str = Depends(get_current_user_id)):
    items = (
        db.query(MyTaskStock)
        .options(joinedload(MyTaskStock.my_task))
        .filter(MyTaskStock.user_id == user_id)
        .order_by(MyTaskStock.created_at.desc())
        .all()
    )
    results = []
    for s in items:
        mt = s.my_task
        results.append(
            {
                "id": f"my-{mt.id}",
                "title": mt.title,
                "tags": ["My Task"],
                "description": None,
                "difficulty": None,
            }
        )
    return results


@router.get("/challenges/search", response_model=List[ChallengeSummary])
def search_challenges(
    q: Optional[str] = None,
    category_id: Optional[int] = None,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
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
                "description": ch.description,
                "difficulty": ch.difficulty,
                "is_completed": ch.id in completed_challenge_ids,
            }
        )

    return results


@router.get("/categories", response_model=List[CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    categories = db.query(Category).order_by(Category.name).all()
    return categories


# My Tasks (per user)
@router.get("/my_tasks", response_model=List[MyTaskResponse])
def list_my_tasks(
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    tasks = (
        db.query(MyTask)
        .filter(MyTask.user_id == user_id)
        .order_by(MyTask.created_at.desc())
        .all()
    )
    return tasks


@router.post("/my_tasks", response_model=MyTaskResponse, status_code=201)
def create_my_task(
    payload: MyTaskCreate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    task = MyTask(user_id=user_id, title=payload.title)
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.put("/my_tasks/{task_id}", response_model=MyTaskResponse)
def update_my_task(
    task_id: int,
    payload: MyTaskUpdate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    task = (
        db.query(MyTask)
        .filter(MyTask.id == task_id, MyTask.user_id == user_id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=404, detail="MyTask not found")

    if payload.title is not None:
        task.title = payload.title

    db.commit()
    db.refresh(task)
    return task


@router.delete("/my_tasks/{task_id}", status_code=204)
def delete_my_task(
    task_id: int,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    task = (
        db.query(MyTask)
        .filter(MyTask.id == task_id, MyTask.user_id == user_id)
        .first()
    )
    if task:
        db.delete(task)
        db.commit()
    return Response(status_code=204)
