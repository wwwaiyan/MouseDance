#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SOURCE="$SCRIPT_DIR/MouseDance.m"
APP="$SCRIPT_DIR/MouseDance.app"
OUTPUT="$APP/Contents/MacOS/MouseDance"
MODULE_CACHE="$SCRIPT_DIR/.build/ModuleCache"

if ! command -v clang >/dev/null 2>&1; then
  print -u2 "Error: Apple Clang compiler not found."
  print -u2 "Install Apple's Command Line Tools with: xcode-select --install"
  exit 1
fi

mkdir -p "$MODULE_CACHE"
mkdir -p "$APP/Contents/MacOS"

clang -O2 \
  -fobjc-arc \
  -arch arm64 \
  -arch x86_64 \
  -mmacosx-version-min=11.0 \
  -fmodules-cache-path="$MODULE_CACHE" \
  -framework Cocoa \
  -framework ApplicationServices \
  -framework IOKit \
  "$SOURCE" \
  -o "$OUTPUT"

cp "$SCRIPT_DIR/Info.plist" "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP" >/dev/null

print "Built universal app: $APP"
