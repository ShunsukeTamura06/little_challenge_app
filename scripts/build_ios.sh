#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${1:-prod}"
shift || true

ENV_FILE="env/${ENV_NAME}.json"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Environment file not found: $ENV_FILE" >&2
  exit 1
fi

flutter clean
flutter pub get
flutter build ipa --release \
  --dart-define-from-file="$ENV_FILE" \
  "$@"

echo "\nBuilt IPA for $ENV_NAME. See build/ios/ipa" 

