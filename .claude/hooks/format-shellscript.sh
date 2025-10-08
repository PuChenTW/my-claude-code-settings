#!/bin/bash
# .claude/hooks/format-shellscript.sh
# This claude code hook lints and formats shell scripts using shellcheck and shfmt.

input_json=$(cat)

file_path=$(echo "$input_json" | jq -r '.tool_input.file_path // empty')

# Change this to your project's root directory if needed
project_path="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Exit silently if no file path - hook may be called for non-file operations
if [[ -z "$file_path" ]]; then
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is not installed. Please install it first." >&2
  exit 1
fi

if ! command -v shellcheck &>/dev/null; then
  echo "Error: shellcheck is not installed. Please install it first: brew install shellcheck (macOS) or apt install shellcheck (Linux)" >&2
  exit 1
fi

if ! command -v shfmt &>/dev/null; then
  echo "Error: shfmt is not installed. Please install it first: brew install shfmt (macOS) or go install mvdan.cc/sh/v3/cmd/shfmt@latest (Linux)" >&2
  exit 1
fi

if [[ "$file_path" =~ \.sh$ ]]; then
  echo "Linting and formatting shell script: $file_path"
  # Don't exit on error - let Claude see the error output to fix the code
  if ! (cd "$project_path" && shellcheck "$file_path" && shfmt -w -i 2 -bn -ci "$file_path"); then
    echo "Warning: Linting/formatting had issues for $file_path - check output above" >&2
  fi
fi
