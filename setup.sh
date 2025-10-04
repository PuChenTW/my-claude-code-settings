#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CRON_CMD="0 0 * * * $SCRIPT_DIR/update-claude-date.sh"

# Create ~/.claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Copy CLAUDE.md to ~/.claude/
cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "✓ Copied CLAUDE.md to $CLAUDE_DIR/CLAUDE.md"

# Make update script executable
chmod +x "$SCRIPT_DIR/update-claude-date.sh"
echo "✓ Made update-claude-date.sh executable"

# Run update script to set current date
"$SCRIPT_DIR/update-claude-date.sh"
echo "✓ Updated date in CLAUDE.md"

# Setup SessionStart hook in ~/.claude/settings.json
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
HOOK_CONFIG=$(cat <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "$SCRIPT_DIR/update-claude-date.sh"
          }
        ]
      }
    ]
  }
}
EOF
)

# Replace $SCRIPT_DIR with actual path in hook config
HOOK_CONFIG=$(echo "$HOOK_CONFIG" | sed "s|\$SCRIPT_DIR|$SCRIPT_DIR|g")

if [ ! -f "$SETTINGS_FILE" ]; then
  # Create new settings.json
  echo "$HOOK_CONFIG" | jq '.' > "$SETTINGS_FILE"
  echo "✓ Created settings.json with SessionStart hook"
else
  # Merge hook into existing settings.json
  TEMP_FILE=$(mktemp)
  jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$HOOK_CONFIG") > "$TEMP_FILE"
  mv "$TEMP_FILE" "$SETTINGS_FILE"
  echo "✓ Updated settings.json with SessionStart hook"
fi

echo ""
echo "Setup complete!"
