#!/bin/bash
# setup-hooks.sh
# Install Claude Code hooks into a project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_SOURCE_DIR="$SCRIPT_DIR/hooks"

show_usage() {
  echo "Usage: $0 <project_path>"
  echo ""
  echo "Install Claude Code hooks into the specified project."
  echo ""
  echo "Arguments:"
  echo "  project_path    Path to the project where hooks should be installed"
  echo ""
  echo "Example:"
  echo "  $0 ~/my-python-project"
}

if [[ $# -eq 0 ]]; then
  echo "Error: Missing project path argument" >&2
  echo "" >&2
  show_usage
  exit 1
fi

PROJECT_PATH="$1"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Error: Project path does not exist or is not a directory: $PROJECT_PATH" >&2
  exit 1
fi

if [[ ! -d "$HOOKS_SOURCE_DIR" ]]; then
  echo "Error: Hooks source directory not found: $HOOKS_SOURCE_DIR" >&2
  echo "Make sure you're running this script from the my-claude-code-settings repository." >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is not installed. Please install it first." >&2
  echo "  macOS: brew install jq" >&2
  echo "  Linux: apt install jq or yum install jq" >&2
  exit 1
fi

if ! command -v uvx &>/dev/null; then
  echo "Error: uvx is not installed. Please install uv first." >&2
  echo "  https://docs.astral.sh/uv/getting-started/installation/" >&2
  exit 1
fi

HOOKS_TARGET_DIR="$PROJECT_PATH/.claude/hooks"
CLAUDE_DIR="$PROJECT_PATH/.claude"
SETTINGS_TARGET="$CLAUDE_DIR/settings.json"
SETTINGS_SOURCE="$HOOKS_SOURCE_DIR/settings.json"

if [[ -d "$HOOKS_TARGET_DIR" ]]; then
  echo "Warning: Hooks directory already exists: $HOOKS_TARGET_DIR"
  read -p "Overwrite existing hook scripts? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
  fi
fi

echo "Installing hooks to: $HOOKS_TARGET_DIR"
mkdir -p "$HOOKS_TARGET_DIR"
mkdir -p "$CLAUDE_DIR"

cp -v "$HOOKS_SOURCE_DIR"/*.sh "$HOOKS_TARGET_DIR/"
chmod +x "$HOOKS_TARGET_DIR"/*.sh

if [[ -f "$SETTINGS_TARGET" ]]; then
  echo "Merging with existing settings.json"
  TEMP_MERGED=$(mktemp)
  jq -s '.[0] * .[1]' "$SETTINGS_TARGET" "$SETTINGS_SOURCE" >"$TEMP_MERGED"
  mv "$TEMP_MERGED" "$SETTINGS_TARGET"
  echo "✓ Merged settings.json"
else
  cp -v "$SETTINGS_SOURCE" "$SETTINGS_TARGET"
fi

echo ""
echo "✓ Hooks installed successfully!"
echo ""
echo "Installed files:"
echo "Hook scripts:"
ls -lh "$HOOKS_TARGET_DIR"
echo ""
echo "Settings:"
ls -lh "$SETTINGS_TARGET"
echo ""
echo "Next steps:"
echo "1. Make sure jq is installed: brew install jq (macOS) or apt install jq (Linux)"
echo "2. Make sure uv is installed: https://docs.astral.sh/uv/getting-started/installation/"
echo "3. The hooks will run automatically when Claude Code writes or edits Python files"
