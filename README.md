# Little Challenge App

This repository contains a Flutter app and a FastAPI backend. See AGENTS.md for high‑level repo structure and commands.

**Frontend (Flutter)**
- Install deps: `flutter pub get`
- Run (Prod): `bash scripts/run_prod.sh -d <device>`
- Run (Staging): `bash scripts/run_staging.sh -d <device>`
- iOS IPA (Prod): `bash scripts/build_ios.sh prod`
- iOS IPA (Staging): `bash scripts/build_ios.sh staging`
- Android AAB (Prod): `bash scripts/build_android.sh prod`
- Android AAB (Staging): `bash scripts/build_android.sh staging`
- Lint: `flutter analyze`
- Format: `dart format .`
- Tests: `flutter test`

**Backend (FastAPI)**
- Docker: `docker-compose up --build` (docs at http://localhost:8000/docs)
- Local: `cd backend && pip install -r requirements.txt && uvicorn app.main:app --reload`

**Environment Configuration (Frontend)**
- API base URL and env name are injected via Dart defines.
- Files live under `env/`:
  - `env/prod.json` (default: https://little-challenge-api.onrender.com)
  - `env/staging.json` (set this to your staging API URL)
- iOS Release no longer hardcodes the API; scripts above pass `--dart-define-from-file`.

**Security**
- Do not commit secrets. Use per‑env config and CI secrets.
