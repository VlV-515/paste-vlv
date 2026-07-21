#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Paste-vlv"
APP_BUNDLE_NAME="Paste vlv"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
VERSION="${1:-1.3.0}"
BUILD="${BUILD_NUMBER:-1}"
ARCHIVE_NAME="$APP_NAME-$VERSION-macos-unsigned.zip"
CHECKSUM_NAME="$ARCHIVE_NAME.sha256"
ARCHIVE_PATH="$DIST_DIR/$ARCHIVE_NAME"
CHECKSUM_PATH="$ARCHIVE_PATH.sha256"

APP_VERSION="$VERSION" APP_BUILD="$BUILD" "$ROOT_DIR/scripts/package-app.sh"

rm -f "$ARCHIVE_PATH" "$CHECKSUM_PATH"

(
  cd "$DIST_DIR"
  ditto -c -k --keepParent "$APP_BUNDLE_NAME.app" "$ARCHIVE_NAME"
)

(
  cd "$DIST_DIR"
  shasum -a 256 "$ARCHIVE_NAME" > "$CHECKSUM_NAME"
)

echo "Created $ARCHIVE_PATH"
echo "Created $CHECKSUM_PATH"
