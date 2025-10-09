#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed"
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "⊘ Skipped Claude MCP setup (claude CLI not found)"
  CLAUDE_CLI_AVAILABLE=0
else
  CLAUDE_CLI_AVAILABLE=1
fi

mkdir -p "$CLAUDE_DIR"

if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.backup"
  echo "✓ Backed up existing CLAUDE.md to CLAUDE.md.backup"
fi

cp "$SCRIPT_DIR/PROMPT_TEMPLATE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "✓ Copied PROMPT_TEMPLATE.md to $CLAUDE_DIR/CLAUDE.md"

if [ ! -f "$SCRIPT_DIR/update-claude-date.sh" ]; then
  echo "Error: update-claude-date.sh not found in $SCRIPT_DIR"
  exit 1
fi

chmod +x "$SCRIPT_DIR/update-claude-date.sh"
echo "✓ Made update-claude-date.sh executable"

cp "$SCRIPT_DIR/update-claude-date.sh" "$CLAUDE_DIR/"
chmod +x "$CLAUDE_DIR/update-claude-date.sh"
echo "✓ Copied update-claude-date.sh to $CLAUDE_DIR"

"$SCRIPT_DIR/update-claude-date.sh"
echo "✓ Updated date in CLAUDE.md"

SETTINGS_FILE="$CLAUDE_DIR/settings.json"
HOOK_COMMAND="$CLAUDE_DIR/update-claude-date.sh"

if [ ! -f "$SETTINGS_FILE" ]; then
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
  }' --arg command "$HOOK_COMMAND" >"$SETTINGS_FILE"
  echo "✓ Created settings.json with SessionStart hook"
else
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
  echo "✓ Backed up existing settings.json to settings.json.backup"

  TEMP_FILE=$(mktemp)
  trap 'rm -f "$TEMP_FILE"' EXIT
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
  ' "$SETTINGS_FILE" >"$TEMP_FILE"
  mv "$TEMP_FILE" "$SETTINGS_FILE"

  if jq --arg command "$HOOK_COMMAND" '[.hooks.SessionStart // [] | .[] | .hooks[]? | select(.command == $command)] | length > 0' "$SETTINGS_FILE" | grep -q true; then
    if [ -f "$SETTINGS_FILE.backup" ] && jq --arg command "$HOOK_COMMAND" '[.hooks.SessionStart // [] | .[] | .hooks[]? | select(.command == $command)] | length > 0' "$SETTINGS_FILE.backup" | grep -q true; then
      echo "✓ SessionStart hook already exists, skipped"
    else
      echo "✓ Added SessionStart hook to settings.json"
    fi
  fi
fi

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

if [ "$CLAUDE_CLI_AVAILABLE" -ne 1 ]; then
  exit 0
fi

is_mcp_installed() {
  local server_name="$1"
  claude mcp list 2>/dev/null | grep -q "^${server_name}:"
}

install_mcp() {
  local server_name="$1"
  shift

  if is_mcp_installed "$server_name"; then
    echo "✓ ${server_name} MCP server already installed for claude"
    return 0
  fi

  echo "Installing ${server_name} MCP server for claude..."
  if claude "$@"; then
    echo "✓ Installed ${server_name} MCP server for claude"
  else
    echo "✗ Failed to install ${server_name} MCP server for claude"
  fi
}

echo ""
echo "Playwright MCP (claude):"
install_mcp "playwright" mcp add -s user playwright -- npx -y @playwright/mcp@latest

echo ""
echo "Context7 MCP (claude):"
if ! is_mcp_installed "context7"; then
  echo "Context7 MCP provides up-to-date library documentation."
  echo "Get your API key at: https://context7.com/dashboard"
  read -r -p "Enter Context7 API key for claude (or press Enter to skip): " CONTEXT7_API_KEY
  if [ -n "$CONTEXT7_API_KEY" ]; then
    install_mcp "context7" mcp add -s user context7 -- npx -y @upstash/context7-mcp --api-key "$CONTEXT7_API_KEY"
  else
    echo "⊘ Skipped Context7 installation for claude"
    echo "    To install later: claude mcp add -s user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY"
  fi
else
  echo "✓ Context7 MCP server already installed for claude"
fi

echo ""
echo "Installed MCP servers (claude):"
claude mcp list
