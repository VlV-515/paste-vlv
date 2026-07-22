#!/usr/bin/env bash
set -euo pipefail

APP_DISPLAY_NAME="Paste vlv"
EXECUTABLE_NAME="Paste-vlv"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/$APP_DISPLAY_NAME.app"
LEGACY_APP_DIR="$ROOT_DIR/dist/Paste-vlv.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_FILE="$ROOT_DIR/Assets/AppIcon.icns"
APP_VERSION="${APP_VERSION:-1.3.1}"
APP_BUILD="${APP_BUILD:-1}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR" "$LEGACY_APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp ".build/release/$EXECUTABLE_NAME" "$MACOS_DIR/$EXECUTABLE_NAME"
cp "$ICON_FILE" "$RESOURCES_DIR/AppIcon.icns"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>dev.vlv.pastevlv</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_DISPLAY_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_DISPLAY_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Private app for personal use.</string>
</dict>
</plist>
PLIST

chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"
if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  codesign --force --deep --sign - "$APP_DIR"
  echo "Ad-hoc signed $APP_DIR"
else
  codesign --force --deep --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP_DIR"
  echo "Developer ID signed $APP_DIR"
fi
echo "Created $APP_DIR"
