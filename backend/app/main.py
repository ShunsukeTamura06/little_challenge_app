from fastapi import FastAPI

from .api.routes import router as api_router
from .core.database import Base, engine
from . import models  # noqa: F401  # ensure models are imported
from .models import Challenge, Task
from sqlalchemy.orm import Session


app = FastAPI()


@app.on_event("startup")
def on_startup() -> None:
    # Create tables if they don't exist (useful for first deploys)
    Base.metadata.create_all(bind=engine)
    # Ensure catalog tasks are mirrored from challenges if tasks are empty
    with Session(bind=engine) as db:
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


# Include API routes
app.include_router(api_router)
