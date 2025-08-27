Backend (FastAPI) Overview

Structure:
- app/
  - core/ (config, database)
  - models/ (SQLAlchemy ORM models)
  - schemas/ (Pydantic models)
  - api/ (FastAPI routers)
  - main.py (FastAPI app factory)
- sql/ (DDL files)
- requirements.txt, Dockerfile

Run:
- Build and start: `docker-compose up --build`
- API docs: http://localhost:8000/docs

Config:
- Database URL via `DATABASE_URL` (docker-compose sets a default).

Notes:
- Seed script is at `backend/scripts/load_data.py`.
