import os


# Read database URL from env with a sensible default for docker-compose
DATABASE_URL: str = os.getenv(
    "DATABASE_URL",
    "postgresql://myuser:mypassword@db:5432/mydatabase",
)

