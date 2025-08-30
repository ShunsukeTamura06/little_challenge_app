#!/usr/bin/env bash
set -euo pipefail

# Build iOS IPA for TestFlight with production API endpoint
# Usage: bash scripts/build_ios_release.sh [extra flutter build args]

flutter clean
flutter pub get
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://little-challenge-api.onrender.com \
  "$@"

echo "\nDone. IPA should be in build/ios/ipa" 

