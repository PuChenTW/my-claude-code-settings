#!/bin/bash

FILE="$HOME/.codex/AGENTS.md"
DATE="- **Current date**: $(date +%Y-%m-%d)"

if [ ! -f "$FILE" ]; then
  exit 0
fi

sed -i.bak "/\*\*Current date\*\*/c\\
$DATE" "$FILE"
