"""Create database tables using SQLAlchemy metadata.

This script is intended for Render post-deploy or local one-off runs.
"""
from app.core.database import Base, engine

# Import models so they're registered on Base.metadata
from app import models  # noqa: F401


def main() -> None:
    print("Dropping all tables...")
    Base.metadata.drop_all(bind=engine)
    print("Tables dropped.")
    print("Creating all tables...")
    Base.metadata.create_all(bind=engine)
    print("Tables created.")


if __name__ == "__main__":
    main()

