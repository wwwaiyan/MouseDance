#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
DIST_DIR="$SCRIPT_DIR/dist"
ARCHIVE="$DIST_DIR/MouseDance-macOS-portable.zip"
DISK_IMAGE="$DIST_DIR/MouseDance-macOS.dmg"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mousedance-package.XXXXXX")"
PACKAGE_DIR="$TEMP_DIR/MouseDance"
DMG_DIR="$TEMP_DIR/MouseDance DMG"

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

"$SCRIPT_DIR/build.sh"
mkdir -p "$DIST_DIR" "$PACKAGE_DIR" "$DMG_DIR"
ditto "$SCRIPT_DIR/MouseDance.app" "$PACKAGE_DIR/MouseDance.app"
cp "$SCRIPT_DIR/Install MouseDance.command" "$PACKAGE_DIR/Install MouseDance.command"
cp "$SCRIPT_DIR/QUICK-START.txt" "$PACKAGE_DIR/QUICK-START.txt"
chmod +x "$PACKAGE_DIR/Install MouseDance.command"

rm -f "$ARCHIVE"
ditto -c -k --sequesterRsrc --keepParent "$PACKAGE_DIR" "$ARCHIVE"

ditto "$SCRIPT_DIR/MouseDance.app" "$DMG_DIR/MouseDance.app"
cp "$SCRIPT_DIR/QUICK-START.txt" "$DMG_DIR/QUICK-START.txt"
ln -s /Applications "$DMG_DIR/Applications"

rm -f "$DISK_IMAGE"
hdiutil create \
  -quiet \
  -volname "MouseDance" \
  -srcfolder "$DMG_DIR" \
  -format UDZO \
  -ov \
  "$DISK_IMAGE"

print "Created $ARCHIVE"
print "Created $DISK_IMAGE"
