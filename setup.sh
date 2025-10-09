#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CODEX_DIR="$HOME/.codex"

# Check for jq dependency
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed"
  echo "Install with: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

# Helper function to check if MCP server is installed
is_mcp_installed() {
  local client_cli="$1"
  local server_name="$2"

  if ! command -v "$client_cli" &>/dev/null; then
    return 1
  fi

  "$client_cli" mcp list 2>/dev/null | grep -q "^${server_name}:"
}

install_mcp_for_client() {
  local client_cli="$1"
  local server_name="$2"
  shift 2

  if ! command -v "$client_cli" &>/dev/null; then
    echo "⊘ Skipped ${server_name} MCP install for ${client_cli} (command not found)"
    return
  fi

  if is_mcp_installed "$client_cli" "$server_name"; then
    echo "✓ ${server_name} MCP server already installed for ${client_cli}"
    return
  fi

  echo "Installing ${server_name} MCP server for ${client_cli}..."
  if "$client_cli" "$@"; then
    echo "✓ Installed ${server_name} MCP server for ${client_cli}"
  else
    echo "✗ Failed to install ${server_name} MCP server for ${client_cli}"
  fi
}

# Create ~/.claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CODEX_DIR"

# Backup existing CLAUDE.md if it exists
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.backup"
  echo "✓ Backed up existing CLAUDE.md to CLAUDE.md.backup"
fi

# Copy template to ~/.claude/CLAUDE.md
cp "$SCRIPT_DIR/PROMPT_TEMPLATE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "✓ Copied PROMPT_TEMPLATE.md to $CLAUDE_DIR/CLAUDE.md"

# Backup existing AGENTS.md if it exists
if [ -f "$CODEX_DIR/AGENTS.md" ]; then
  cp "$CODEX_DIR/AGENTS.md" "$CODEX_DIR/AGENTS.md.backup"
  echo "✓ Backed up existing AGENTS.md to AGENTS.md.backup"
fi

# Copy template to ~/.codex/AGENTS.md for Codex setup
cp "$SCRIPT_DIR/PROMPT_TEMPLATE.md" "$CODEX_DIR/AGENTS.md"
echo "✓ Copied PROMPT_TEMPLATE.md to $CODEX_DIR/AGENTS.md"

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
  }' --arg command "$HOOK_COMMAND" >"$SETTINGS_FILE"
  echo "✓ Created settings.json with SessionStart hook"
else
  # Backup existing settings.json
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
  echo "✓ Backed up existing settings.json to settings.json.backup"

  # Check if hook already exists and append only if not present
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

echo ""
echo "Playwright MCP:"
install_mcp_for_client "claude" "playwright" mcp add -s user playwright -- npx -y @playwright/mcp@latest
install_mcp_for_client "codex" "playwright" mcp add playwright -- npx -y @playwright/mcp@latest

echo ""
echo "Context7 MCP:"
context7_targets=()
for client_cli in claude codex; do
  if ! command -v "$client_cli" &>/dev/null; then
    echo "⊘ Skipped Context7 MCP install for ${client_cli} (command not found)"
    continue
  fi

  if is_mcp_installed "$client_cli" "context7"; then
    echo "✓ Context7 MCP server already installed for ${client_cli}"
  else
    context7_targets+=("$client_cli")
  fi
done

if [ "${#context7_targets[@]}" -gt 0 ]; then
  echo "Context7 MCP provides up-to-date library documentation."
  echo "Get your API key at: https://context7.com/dashboard"
  read -r -p "Enter Context7 API key (or press Enter to skip): " CONTEXT7_API_KEY

  if [ -n "$CONTEXT7_API_KEY" ]; then
    for client_cli in "${context7_targets[@]}"; do
      case "$client_cli" in
        claude)
          install_mcp_for_client "$client_cli" "context7" mcp add -s user context7 -- npx -y @upstash/context7-mcp --api-key "$CONTEXT7_API_KEY"
          ;;
        codex)
          install_mcp_for_client "$client_cli" "context7" mcp add context7 -- npx -y @upstash/context7-mcp --api-key "$CONTEXT7_API_KEY"
          ;;
        *)
          install_mcp_for_client "$client_cli" "context7" mcp add context7 -- npx -y @upstash/context7-mcp --api-key "$CONTEXT7_API_KEY"
          ;;
      esac
    done
  else
    echo "⊘ Skipped Context7 installation"
    for client_cli in "${context7_targets[@]}"; do
      case "$client_cli" in
        claude)
          echo "  To install later: claude mcp add -s user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY"
          ;;
        codex)
          echo "  To install later: codex mcp add context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY"
          ;;
        *)
          echo "  To install later: ${client_cli} mcp add context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY"
          ;;
      esac
    done
  fi
fi

# List installed MCP servers
echo ""
if command -v claude &>/dev/null; then
  echo "Installed MCP servers (claude):"
  claude mcp list
fi

if command -v codex &>/dev/null; then
  echo ""
  echo "Installed MCP servers (codex):"
  codex mcp list
fi

echo ""
echo "Setup complete!"
