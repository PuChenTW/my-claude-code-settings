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

# Add cron job if it doesn't already exist
(crontab -l 2>/dev/null | grep -v "update-claude-date.sh"; echo "$CRON_CMD") | crontab -
echo "✓ Added cron job to run daily at 0:00"

echo ""
echo "Setup complete!"
