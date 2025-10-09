#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_DIR="$HOME/.codex"

mkdir -p "$CODEX_DIR"

if ! command -v codex &>/dev/null; then
  echo "⊘ Skipped Codex MCP setup (codex CLI not found)"
  CODEX_CLI_AVAILABLE=0
else
  CODEX_CLI_AVAILABLE=1
fi

if [ -f "$CODEX_DIR/AGENTS.md" ]; then
  cp "$CODEX_DIR/AGENTS.md" "$CODEX_DIR/AGENTS.md.backup"
  echo "✓ Backed up existing AGENTS.md to AGENTS.md.backup"
fi

cp "$SCRIPT_DIR/PROMPT_TEMPLATE.md" "$CODEX_DIR/AGENTS.md"
echo "✓ Copied PROMPT_TEMPLATE.md to $CODEX_DIR/AGENTS.md"

if [ ! -f "$SCRIPT_DIR/update-codex-date.sh" ]; then
  echo "Error: update-codex-date.sh not found in $SCRIPT_DIR"
  exit 1
fi

chmod +x "$SCRIPT_DIR/update-codex-date.sh"
echo "✓ Made update-codex-date.sh executable"

cp "$SCRIPT_DIR/update-codex-date.sh" "$CODEX_DIR/"
chmod +x "$CODEX_DIR/update-codex-date.sh"
echo "✓ Copied update-codex-date.sh to $CODEX_DIR"

"$SCRIPT_DIR/update-codex-date.sh"
echo "✓ Updated date in AGENTS.md"

if command -v crontab &>/dev/null; then
  CRON_JOB="5 0 * * * $CODEX_DIR/update-codex-date.sh >/dev/null 2>&1"
  EXISTING_CRON="$(crontab -l 2>/dev/null || true)"

  if printf '%s\n' "$EXISTING_CRON" | grep -Fq "$CRON_JOB"; then
    echo "✓ Cron job to update AGENTS.md already configured"
  else
    {
      if [ -n "$EXISTING_CRON" ]; then
        printf '%s\n' "$EXISTING_CRON"
      fi
      echo "$CRON_JOB"
    } | crontab -
    echo "✓ Added cron job to refresh AGENTS.md daily"
  fi
else
  echo "⊘ Skipped cron setup (crontab command not found)"
fi

if [ "$CODEX_CLI_AVAILABLE" -ne 1 ]; then
  exit 0
fi

is_mcp_installed() {
  local server_name="$1"
  codex mcp list 2>/dev/null | grep -q "${server_name}"
}

install_mcp() {
  local server_name="$1"
  shift

  if is_mcp_installed "$server_name"; then
    echo "✓ ${server_name} MCP server already installed for codex"
    return 0
  fi

  echo "Installing ${server_name} MCP server for codex..."
  if codex "$@"; then
    echo "✓ Installed ${server_name} MCP server for codex"
  else
    echo "✗ Failed to install ${server_name} MCP server for codex"
  fi
}

echo ""
echo "Playwright MCP (codex):"
install_mcp "playwright" mcp add playwright -- npx -y @playwright/mcp@latest

echo ""
echo "Context7 MCP (codex):"
if ! is_mcp_installed "context7"; then
  echo "Context7 MCP provides up-to-date library documentation."
  echo "Get your API key at: https://context7.com/dashboard"
  read -r -p "Enter Context7 API key for codex (or press Enter to skip): " CONTEXT7_API_KEY
  if [ -n "$CONTEXT7_API_KEY" ]; then
    install_mcp "context7" mcp add context7 -- npx -y @upstash/context7-mcp --api-key "$CONTEXT7_API_KEY"
  else
    echo "⊘ Skipped Context7 installation for codex"
    echo "    To install later: codex mcp add context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY"
  fi
else
  echo "✓ Context7 MCP server already installed for codex"
fi

echo ""
echo "Installed MCP servers (codex):"
codex mcp list
