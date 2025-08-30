# Operations Guide

This guide documents environment switching, build/distribution, and backend user scoping so future contributors can operate the project confidently.

## Environments (Frontend)

- Dart defines drive the app’s runtime config.
- Files live under `env/`:
  - `env/prod.json` (default prod API URL)
  - `env/staging.json` (staging API URL; adjust to your endpoint)
- Common keys:
  - `API_BASE_URL`: Base URL of the backend
  - `ENV_NAME`: Human‑readable environment name

### Run/Build Commands

- Run (Prod): `bash scripts/run_prod.sh -d <device>`
- Run (Staging): `bash scripts/run_staging.sh -d <device>`
- iOS IPA (Prod): `bash scripts/build_ios.sh prod`
- iOS IPA (Staging): `bash scripts/build_ios.sh staging`
- Android AAB (Prod): `bash scripts/build_android.sh prod`
- Android AAB (Staging): `bash scripts/build_android.sh staging`

Note: iOS Release no longer hardcodes API URLs. Scripts pass `--dart-define-from-file`.

### Adding a New Environment

1. Create `env/<name>.json` with `API_BASE_URL` and `ENV_NAME`.
2. Run/Build with `--dart-define-from-file=env/<name>.json`, or add a helper script mirroring the existing ones.
3. Optional: Create Xcode Schemes/Configurations and set `DART_DEFINES` to align local builds with CI.

## Backend (FastAPI)

### User Scoping

- All personalized endpoints require the `X-User-Id` header. The front‑end generates and persists a stable user ID on first run and attaches it automatically.
- Endpoints scoped by user:
  - `POST /logs`, `GET /logs`
  - `POST /stock`, `GET /stock`, `DELETE /stock/by-challenge/{challenge_id}`
  - `GET /challenges/search` (computes completion flags per user)
  - `GET /my_tasks`, `POST /my_tasks`, `PUT /my_tasks/{task_id}`, `DELETE /my_tasks/{task_id}`
- Replace this header scheme with a proper auth (e.g., Sign in with Apple) when ready; wire the dependency in `app/api/routes.py`.

### Running the Backend

- Docker: `docker-compose up --build` (API docs at http://localhost:8000/docs)
- Local: `cd backend && pip install -r requirements.txt && uvicorn app.main:app --reload`
- Database: configured via `DATABASE_URL` (see `backend/app/core/config.py`). On startup, tables are created automatically (`Base.metadata.create_all`).
- Seed data: optional helper endpoint `POST /admin/init-data` (uses `backend/scripts/load_data.py`).

## Distribution

### iOS (TestFlight)

1. Bump build number in `pubspec.yaml` (e.g., `1.0.0+3`) if uploading a new build.
2. Build IPA:
   - Prod: `bash scripts/build_ios.sh prod`
   - Staging: `bash scripts/build_ios.sh staging`
3. Upload via Transporter or Xcode Organizer.
4. App Store Connect → TestFlight: assign to Internal/External testers.
5. On device: open TestFlight and install/update.

Notes:
- Use HTTPS API URLs to avoid ATS exceptions. For HTTP during local testing, add exceptions in `ios/Runner/Info.plist` (not recommended for release).
- Ensure you have proper app icons and launch assets.

### Android (Play Console)

1. Build AAB:
   - Prod: `bash scripts/build_android.sh prod`
   - Staging: `bash scripts/build_android.sh staging`
2. Upload to Play Console → Internal testing or production tracks.

## Frontend User Identification

- `lib/services/user_id_service.dart` generates a URL‑safe random ID on first run and stores it in `SharedPreferences`.
- `lib/services/api_headers.dart` injects `X-User-Id` for all requests.

## Troubleshooting

- Verify defines: check generated `ios/Flutter/Generated.xcconfig` (key `DART_DEFINES`) after a build to confirm injected values.
- Network errors on device:
  - Confirm the app points to the correct environment file.
  - Ensure the backend is reachable from the device and uses HTTPS.
- If personalized data is shared across devices, confirm `X-User-Id` header is present server‑side (inspect logs) and tables include the expected `user_id` values.

