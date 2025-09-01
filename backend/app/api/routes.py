from collections import defaultdict
from datetime import datetime
import random
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Response, Header
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func

from ..core.database import get_db
from ..models import Category, Challenge, Task, Achievement, Stock
from ..schemas.category import CategoryResponse
from ..schemas.log import LogCreate, LogResponse
from ..schemas.stock import StockCreate, StockResponse
from ..schemas.challenge import ChallengeSummary
from ..schemas.task_list import TaskListItem
from ..schemas.task import TaskReplaceRequest
from ..schemas.my_task import MyTaskCreate, MyTaskUpdate, MyTaskResponse


router = APIRouter()


def get_current_user_id(x_user_id: str = Header(..., alias="X-User-Id")) -> str:
    if not x_user_id or not x_user_id.strip():
        raise HTTPException(status_code=400, detail="X-User-Id header is required")
    return x_user_id.strip()


@router.get("/healthz")
def healthz():
    return {"status": "ok"}


@router.post("/admin/init-data")
def initialize_data(db: Session = Depends(get_db)):
    """Initialize categories/challenges from seed and mirror them into tasks as catalog items."""
    try:
        from ..core.database import Base, engine
        Base.metadata.create_all(bind=engine)

        try:
            from scripts.load_data import tasks  # type: ignore
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to import seed tasks: {e}")

        category_map = {c.name: c for c in db.query(Category).all()}
        for t in tasks:
            name = t.get("category")
            if name and name not in category_map:
                cat = Category(name=name)
                db.add(cat)
                db.flush()
                category_map[name] = cat

        # Seed challenges
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
                continue
            db.add(
                Challenge(
                    category_id=cat.id,
                    title=t.get("title"),
                    description=t.get("description"),
                    difficulty=int(t.get("difficulty") or 1),
                )
            )
        db.commit()

        # Mirror to tasks as catalog entries if tasks table is empty
        if db.query(Task).count() == 0:
            for ch in db.query(Challenge).all():
                db.add(
                    Task(
                        title=ch.title,
                        description=ch.description,
                        difficulty=ch.difficulty,
                        category_id=ch.category_id,
                        source="catalog",
                    )
                )
            db.commit()

        return {
            "message": "Initialization done",
            "categories_total": db.query(Category).count(),
            "challenges_total": db.query(Challenge).count(),
            "tasks_total": db.query(Task).count(),
        }
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to initialize data: {e}")


@router.get("/tasks/daily")
def get_daily_task(force_refresh: bool = False, db: Session = Depends(get_db)):
    t = (
        db.query(Task)
        .options(joinedload(Task.category))
        .filter(Task.source == "catalog")
        .order_by(func.random())
        .first()
    )
    if t is None:
        raise HTTPException(status_code=404, detail="No tasks found in the database.")
    return {
        "id": str(t.id),
        "title": t.title,
        "description": t.description,
        "difficulty": t.difficulty,
        "tags": [t.category.name] if t.category else [],
        "stats": {"completion_rate": random.uniform(0.1, 0.8)},
        "source": "catalog",
    }


@router.post("/tasks/daily/replace")
def replace_daily_task(
    req: TaskReplaceRequest,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    target_task = None
    if getattr(req, "my_task_id", None) is not None:
        target_task = (
            db.query(Task)
            .filter(Task.id == req.my_task_id, Task.source == "my", Task.owner_user_id == user_id)
            .first()
        )
        if not target_task:
            raise HTTPException(status_code=404, detail="My task not found")
    elif getattr(req, "new_task_id", None):
        try:
            task_id = int(req.new_task_id)
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid new_task_id format.")
        target_task = (
            db.query(Task)
            .options(joinedload(Task.category))
            .filter(Task.id == task_id, Task.source == "catalog")
            .first()
        )
        if not target_task:
            raise HTTPException(status_code=404, detail="Task not found")
    else:
        raise HTTPException(status_code=400, detail="new_task_id or my_task_id required")

    return {
        "id": str(target_task.id),
        "title": target_task.title,
        "description": target_task.description,
        "difficulty": target_task.difficulty,
        "tags": [target_task.category.name] if target_task.category else (["My Task"] if target_task.source == "my" else []),
        "stats": {"completion_rate": random.uniform(0.1, 0.8)},
        "source": target_task.source,
    }


@router.post("/logs", response_model=LogResponse, status_code=201)
def create_log(
    log: LogCreate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    t = db.query(Task).filter(Task.id == log.task_id).first()
    if not t:
        raise HTTPException(status_code=404, detail="Task not found")
    if t.source == "my" and t.owner_user_id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    db_log = Achievement(
        user_id=user_id,
        task_id=log.task_id,
        memo=log.memo,
        feeling=log.feeling,
        achieved_at=log.achieved_at if log.achieved_at is not None else None,
    )
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return {"log_id": db_log.id, "message": "Successfully created."}


@router.get("/logs")
def get_logs(
    month: Optional[str] = None,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    query = db.query(Achievement).filter(Achievement.user_id == user_id)
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

    def to_dict(ach: Achievement):
        t = (
            db.query(Task)
            .options(joinedload(Task.category))
            .filter(Task.id == ach.task_id)
            .first()
        )
        return {
            "id": ach.id,
            "user_id": ach.user_id,
            "memo": ach.memo,
            "feeling": ach.feeling,
            "achieved_at": ach.achieved_at.isoformat(),
            "challenge": {
                "id": t.id,
                "title": t.title,
                "description": t.description,
                "difficulty": t.difficulty,
                "category": {"id": t.category.id, "name": t.category.name} if t.category else {"id": -1, "name": "My Task"},
                "source": t.source,
            },
        }

    grouped = defaultdict(list)
    for l in logs:
        date_str = l.achieved_at.strftime("%Y-%m-%d")
        grouped[date_str].append(to_dict(l))
    return grouped


@router.get("/stock", response_model=List[TaskListItem])
def get_stocked_tasks(db: Session = Depends(get_db), user_id: str = Depends(get_current_user_id)):
    rows = (
        db.query(Stock)
        .options(joinedload(Stock.task).joinedload(Task.category))
        .filter(Stock.user_id == user_id)
        .order_by(Stock.created_at.desc())
        .all()
    )
    results = []
    for s in rows:
        t = s.task
        results.append(
            {
                "id": t.id,
                "title": t.title,
                "tags": [t.category.name] if t.category else ["My Task"],
                "description": t.description,
                "difficulty": t.difficulty,
                "source": t.source,
            }
        )
    return results


@router.post("/stock", status_code=201)
def create_stock(
    stock: StockCreate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    task_id_int = stock.task_id
    t = db.query(Task).filter(Task.id == task_id_int).first()
    if not t:
        raise HTTPException(status_code=404, detail="Task not found")
    if t.source == "my" and t.owner_user_id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    existing = db.query(Stock).filter(Stock.user_id == user_id, Stock.task_id == task_id_int).first()
    if existing:
        return {"status": "exists"}
    item = Stock(user_id=user_id, task_id=task_id_int)
    db.add(item)
    db.commit()
    db.refresh(item)
    return {"status": "created", "id": item.id}


@router.delete("/stock/by-task/{task_id}", status_code=204)
def delete_stock_by_task_id(
    task_id: int, db: Session = Depends(get_db), user_id: str = Depends(get_current_user_id)
):
    stock_item = db.query(Stock).filter(Stock.user_id == user_id, Stock.task_id == task_id).first()
    if stock_item:
        db.delete(stock_item)
        db.commit()
    return Response(status_code=204)


@router.get("/challenges/search", response_model=List[ChallengeSummary])
def search_challenges(
    q: Optional[str] = None,
    category_id: Optional[int] = None,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    query = db.query(Task).options(joinedload(Task.category)).filter(Task.source == "catalog")
    if q:
        query = query.filter(Task.title.ilike(f"%{q}%"))
    if category_id:
        query = query.filter(Task.category_id == category_id)
    tasks = query.all()
    user_ach = db.query(Achievement.task_id).filter(Achievement.user_id == user_id).all()
    completed_ids = {row.task_id for row in user_ach}
    results = []
    for t in tasks:
        results.append(
            {
                "id": t.id,
                "title": t.title,
                "tags": [t.category.name] if t.category else [],
                "description": t.description,
                "difficulty": t.difficulty,
                "is_completed": t.id in completed_ids,
            }
        )
    return results


@router.get("/categories", response_model=List[CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    return db.query(Category).order_by(Category.name).all()


@router.get("/my_tasks", response_model=List[MyTaskResponse])
def list_my_tasks(
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    tasks = (
        db.query(Task)
        .filter(Task.source == "my", Task.owner_user_id == user_id)
        .order_by(Task.created_at.desc())
        .all()
    )
    return [MyTaskResponse(id=t.id, title=t.title, created_at=t.created_at) for t in tasks]


@router.post("/my_tasks", response_model=MyTaskResponse, status_code=201)
def create_my_task(
    payload: MyTaskCreate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    task = Task(title=payload.title, source="my", owner_user_id=user_id)
    db.add(task)
    db.commit()
    db.refresh(task)
    return MyTaskResponse(id=task.id, title=task.title, created_at=task.created_at)


@router.put("/my_tasks/{task_id}", response_model=MyTaskResponse)
def update_my_task(
    task_id: int,
    payload: MyTaskUpdate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    task = (
        db.query(Task)
        .filter(Task.id == task_id, Task.source == "my", Task.owner_user_id == user_id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=404, detail="MyTask not found")
    if payload.title is not None:
        task.title = payload.title
    db.commit()
    db.refresh(task)
    return MyTaskResponse(id=task.id, title=task.title, created_at=task.created_at)


@router.delete("/my_tasks/{task_id}", status_code=204)
def delete_my_task(
    task_id: int,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    task = (
        db.query(Task)
        .filter(Task.id == task_id, Task.source == "my", Task.owner_user_id == user_id)
        .first()
    )
    if task:
        db.delete(task)
        db.commit()
    return Response(status_code=204)
