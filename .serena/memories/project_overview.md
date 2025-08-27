Project: little_challenge_app
Purpose: Flutter app with a FastAPI backend serving daily challenges, categories, and user logs; data stored in PostgreSQL.
Tech Stack: Flutter (Dart), Python 3.11, FastAPI, SQLAlchemy, Pydantic v2, Uvicorn, PostgreSQL, Docker Compose.
Structure (pre-refactor): backend/ (main.py monolith: app+models+schemas+routes), load_data.py (psycopg2 seed), create_table.sql & CREATE_TABLE.pgsql (DDL), Dockerfile, requirements.txt; plus Flutter standard dirs at root.
Env: docker-compose sets `DATABASE_URL=postgresql://myuser:mypassword@db:5432/mydatabase`.
Notes: No tests; no Python linter/formatter configured. Backend currently hardcodes DB URL in main.py (should use env).