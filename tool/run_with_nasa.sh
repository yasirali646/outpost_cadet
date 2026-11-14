#!/usr/bin/env bash
# Load NASA_API_KEY from .env and forward to Flutter as --dart-define.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
if [[ -x /media/yasir/Projects/flutter/bin/flutter ]]; then
  FLUTTER_BIN=/media/yasir/Projects/flutter/bin/flutter
fi

KEY=""
if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  set -a
  source .env
  set +a
  KEY="${NASA_API_KEY:-}"
fi

if [[ -z "$KEY" ]]; then
  echo "Warning: NASA_API_KEY empty — using CCMC DONKI / snapshot fallback."
fi

exec "$FLUTTER_BIN" "$@" --dart-define="NASA_API_KEY=$KEY"
