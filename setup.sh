#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Check for jq dependency
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed"
  echo "Install with: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

# Create ~/.claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Backup existing CLAUDE.md if it exists
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.backup"
  echo "✓ Backed up existing CLAUDE.md to CLAUDE.md.backup"
fi

# Copy CLAUDE.md to ~/.claude/
cp "$SCRIPT_DIR/CLAUDE_TEMPLATE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "✓ Copied CLAUDE_TEMPLATE.md to $CLAUDE_DIR/CLAUDE.md"

# Check if update script exists
if [ ! -f "$SCRIPT_DIR/update-claude-date.sh" ]; then
  echo "Error: update-claude-date.sh not found in $SCRIPT_DIR"
  exit 1
fi

# Make update script executable
chmod +x "$SCRIPT_DIR/update-claude-date.sh"
echo "✓ Made update-claude-date.sh executable"

# Copy script to permanent location
cp "$SCRIPT_DIR/update-claude-date.sh" "$CLAUDE_DIR/"
chmod +x "$CLAUDE_DIR/update-claude-date.sh"
echo "✓ Copied update-claude-date.sh to $CLAUDE_DIR"

# Run update script to set current date
"$SCRIPT_DIR/update-claude-date.sh"
echo "✓ Updated date in CLAUDE.md"

# Setup SessionStart hook in ~/.claude/settings.json
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
HOOK_COMMAND="$CLAUDE_DIR/update-claude-date.sh"

if [ ! -f "$SETTINGS_FILE" ]; then
  # Create new settings.json with SessionStart hook
  jq -n '{
    "hooks": {
      "SessionStart": [
        {
          "matcher": "startup|resume",
          "hooks": [
            {
              "type": "command",
              "command": $command
            }
          ]
        }
      ]
    }
  }' --arg command "$HOOK_COMMAND" > "$SETTINGS_FILE"
  echo "✓ Created settings.json with SessionStart hook"
else
  # Backup existing settings.json
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
  echo "✓ Backed up existing settings.json to settings.json.backup"

  # Check if hook already exists and append only if not present
  TEMP_FILE=$(mktemp)
  trap "rm -f $TEMP_FILE" EXIT
  jq --arg command "$HOOK_COMMAND" '
    .hooks.SessionStart = (.hooks.SessionStart // []) +
    if ([.hooks.SessionStart // [] | .[] | .hooks[]? | select(.command == $command)] | length > 0)
    then []
    else [{
      "matcher": "startup|resume",
      "hooks": [{
        "type": "command",
        "command": $command
      }]
    }]
    end
  ' "$SETTINGS_FILE" > "$TEMP_FILE"
  mv "$TEMP_FILE" "$SETTINGS_FILE"

  # Check if hook was added or already existed
  if jq --arg command "$HOOK_COMMAND" '[.hooks.SessionStart // [] | .[] | .hooks[]? | select(.command == $command)] | length > 0' "$SETTINGS_FILE" | grep -q true; then
    if [ -f "$SETTINGS_FILE.backup" ] && jq --arg command "$HOOK_COMMAND" '[.hooks.SessionStart // [] | .[] | .hooks[]? | select(.command == $command)] | length > 0' "$SETTINGS_FILE.backup" | grep -q true; then
      echo "✓ SessionStart hook already exists, skipped"
    else
      echo "✓ Added SessionStart hook to settings.json"
    fi
  fi
fi

# Validate settings.json is valid JSON
if ! jq empty "$SETTINGS_FILE" 2>/dev/null; then
  echo "Error: Generated invalid JSON in $SETTINGS_FILE"
  if [ -f "$SETTINGS_FILE.backup" ]; then
    mv "$SETTINGS_FILE.backup" "$SETTINGS_FILE"
    echo "✓ Restored settings.json from backup"
  else
    rm -f "$SETTINGS_FILE"
  fi
  exit 1
fi

# Setup MCP servers
echo ""
echo "Setting up MCP servers..."

# Install Playwright MCP
echo "Installing Playwright MCP server..."
if claude mcp add -s user playwright -- npx -y @playwright/mcp@latest; then
  echo "✓ Installed Playwright MCP server"
else
  echo "✗ Failed to install Playwright MCP server"
fi

# Install Context7 MCP (with API key prompt)
echo ""
echo "Context7 MCP provides up-to-date library documentation."
echo "Get your API key at: https://context7.com/dashboard"
read -p "Enter Context7 API key (or press Enter to skip): " CONTEXT7_API_KEY

if [ -n "$CONTEXT7_API_KEY" ]; then
  echo "Installing Context7 MCP server..."
  if claude mcp add -s user context7 -- npx -y @upstash/context7-mcp --api-key "$CONTEXT7_API_KEY"; then
    echo "✓ Installed Context7 MCP server"
  else
    echo "✗ Failed to install Context7 MCP server"
  fi
else
  echo "⊘ Skipped Context7 installation"
  echo "  To install later: claude mcp add -s user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY"
fi

# List installed MCP servers
echo ""
echo "Installed MCP servers:"
claude mcp list

echo ""
echo "Setup complete!"
