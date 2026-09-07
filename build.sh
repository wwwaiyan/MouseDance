#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SOURCE="$SCRIPT_DIR/MouseDance.c"
OUTPUT="$SCRIPT_DIR/mousedance"
MODULE_CACHE="$SCRIPT_DIR/.build/ModuleCache"

if ! command -v clang >/dev/null 2>&1; then
  print -u2 "Error: Apple Clang compiler not found."
  print -u2 "Install Apple's Command Line Tools with: xcode-select --install"
  exit 1
fi

mkdir -p "$MODULE_CACHE"

clang -O2 \
  -fmodules-cache-path="$MODULE_CACHE" \
  -framework ApplicationServices \
  "$SOURCE" \
  -o "$OUTPUT"

print "Built $OUTPUT"
