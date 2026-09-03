#!/usr/bin/env bash
# Builds the Lambda deployment zip from app/src. Used by CI before
# `terraform apply`; safe to run locally too for a quick sanity check.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../app"
BUILD_DIR="$APP_DIR/build"
OUTPUT_ZIP="${1:-$APP_DIR/build/app.zip}"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$(dirname "$OUTPUT_ZIP")"

pip install \
  --requirement "$APP_DIR/src/requirements.txt" \
  --target "$BUILD_DIR" \
  --no-cache-dir \
  --quiet

cp "$APP_DIR/src/handler.py" "$BUILD_DIR/"

# Zip to a path outside BUILD_DIR so we never mv a file onto itself.
TMP_DIR="$(mktemp -d)"
TMP_ZIP="$TMP_DIR/app.zip"
(cd "$BUILD_DIR" && zip -r -q "$TMP_ZIP" .)
mv -f "$TMP_ZIP" "$OUTPUT_ZIP"
rmdir "$TMP_DIR"

echo "Built $OUTPUT_ZIP"
