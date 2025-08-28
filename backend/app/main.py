from fastapi import FastAPI

from .api.routes import router as api_router
from .core.database import Base, engine
from . import models  # noqa: F401  # ensure models are imported


app = FastAPI()


@app.on_event("startup")
def on_startup() -> None:
    # Create tables if they don't exist (useful for first deploys)
    Base.metadata.create_all(bind=engine)


# Include API routes
app.include_router(api_router)
