"""Create database tables using SQLAlchemy metadata.

This script is intended for Render post-deploy or local one-off runs.
"""
from app.core.database import Base, engine

# Import models so they're registered on Base.metadata
from app import models  # noqa: F401


def main() -> None:
    Base.metadata.create_all(bind=engine)


if __name__ == "__main__":
    main()

