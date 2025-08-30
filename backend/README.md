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

Auth / User Scoping:
- Personalized endpoints require the `X-User-Id` header. The app generates and stores a stable user ID on first run and sends it automatically.
- Endpoints scoped by user: `/logs` (GET/POST), `/stock` (GET/POST/DELETE by-challenge), `/challenges/search`, `/my_tasks` (GET/POST/PUT/DELETE).

My Tasks API:
- `GET /my_tasks` → list current user tasks
- `POST /my_tasks` (body: `{ "title": "..." }`) → create
- `PUT /my_tasks/{task_id}` (body: `{ "title": "..." }`) → update
- `DELETE /my_tasks/{task_id}` → delete

Notes:
- Seed script is at `backend/scripts/load_data.py`.
