#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

missing=()
for cmd in jq claude codex; do
  if ! command -v "$cmd" &>/dev/null; then
    missing+=("$cmd")
  fi
done

if [ "${#missing[@]}" -gt 0 ]; then
  echo "Error: missing required command(s): ${missing[*]}"
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/setup_claude.sh" ]; then
  echo "Error: setup_claude.sh not found in $SCRIPT_DIR"
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/setup_codex.sh" ]; then
  echo "Error: setup_codex.sh not found in $SCRIPT_DIR"
  exit 1
fi

"$SCRIPT_DIR/setup_claude.sh"
echo ""
"$SCRIPT_DIR/setup_codex.sh"

echo ""
echo "Setup complete!"
