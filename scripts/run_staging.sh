#!/usr/bin/env bash
set -euo pipefail

flutter run \
  --dart-define-from-file=env/staging.json \
  "$@"

