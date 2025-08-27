When finishing tasks:
- Ensure code builds: `docker-compose build` and services start without errors
- Verify `uvicorn` entry points and import paths
- Confirm env usage (DATABASE_URL) and secrets are not hardcoded
- Update docs/README and commands if entrypoints change
- Run quick smoke via http://localhost:8000/docs and try endpoints
- Keep changes minimal and focused; avoid unrelated edits
