# Repository Guidelines

## Project Structure & Module Organization
- `lib/`: Flutter app source (screens, models, providers). Entry: `lib/main.dart`.
- `test/`: Flutter widget/unit tests (`*_test.dart`).
- `backend/`: FastAPI service (`app/` with `api/`, `models/`, `schemas/`, `core/`).
- Platform folders: `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/`.
- Docker: `docker-compose.yml` (API + Postgres), backend `Dockerfile`.

## Build, Test, and Development Commands
- Frontend
  - Install deps: `flutter pub get`
  - Run app: `flutter run` (e.g., `-d chrome` or emulator)
  - Lint/analyze: `flutter analyze`
  - Format: `dart format .`
  - Tests: `flutter test`
- Backend
  - Start API + DB: `docker-compose up --build` (docs at http://localhost:8000/docs)
  - Local (no Docker):
    - `cd backend && pip install -r requirements.txt`
    - `uvicorn app.main:app --reload`

## Coding Style & Naming Conventions
- Dart (frontend)
  - Lints: `flutter_lints` via `analysis_options.yaml`; fix all analyzer warnings.
  - Naming: Classes `UpperCamelCase`; methods/vars `lowerCamelCase`; files `snake_case.dart`.
  - Prefer small widgets and pure functions; keep API calls out of UI where possible.
- Python (backend)
  - Follow PEP 8, 4‑space indentation; add type hints where practical.
  - Keep routers thin; move DB logic to `models/` and schemas to `schemas/`.

## Testing Guidelines
- Flutter: Place tests under `test/` (e.g., `search_screen_test.dart`); run `flutter test`.
- Write tests for providers/state and parsing (e.g., `Task.fromJson`).
- Backend: No test framework is configured; if adding, prefer `pytest` and keep unit tests close to modules.

## Commit & Pull Request Guidelines
- Use Conventional Commits with optional scope: `feat(search): ...`, `fix(api): ...` (see `git log`).
- Keep subject imperative, ≤72 chars; include a brief body when needed.
- PRs: include description, linked issues, screenshots/GIFs for UI, repro steps, and risks.
- Required: `flutter analyze` and tests pass; update docs and API contracts when applicable.

## Security & Configuration Tips
- Do not commit secrets. Configure DB via `DATABASE_URL` (set in `docker-compose.yml`).
- Use per‑env config; prefer `.env` files locally and CI secrets for pipelines.
