#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SOURCE="$SCRIPT_DIR/MouseDance.c"
PROGRAM="$SCRIPT_DIR/mousedance"

if [[ ! -x "$PROGRAM" || "$SOURCE" -nt "$PROGRAM" ]]; then
  "$SCRIPT_DIR/build.sh"
fi

exec "$PROGRAM"
