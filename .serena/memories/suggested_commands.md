Core dev commands (Darwin/macOS):
- Run backend: `docker-compose up --build`
- Seed data (inside api container): `docker-compose exec api python scripts/load_data.py`
- Open FastAPI docs: http://localhost:8000/docs
- Stop services: `docker-compose down`
- Lint/format Flutter: `flutter format .` (if needed)
- Run Flutter app: `flutter run` (from repo root)
- Git basics: `git status`, `git add -p`, `git commit -m`, `git log --oneline`
- File search: `rg "pattern"` (ripgrep)
