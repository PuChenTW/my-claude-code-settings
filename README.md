# Claude Code Settings

English | [繁體中文](README.zh-TW.md)

Global configuration for Claude Code that enforces Linus Torvalds-style coding principles: ruthless simplicity, performance-first thinking, and zero abstraction bloat.

## Setup

```bash
./setup.sh
```

This installs `CLAUDE.md` to `~/.claude/`, sets up a SessionStart hook to keep the date current, and installs MCP servers.

## What It Does

- Copies coding guidelines to `~/.claude/CLAUDE.md`
- Configures SessionStart hook to update date on every session
- Installs Playwright MCP server for web automation
- Optionally installs Context7 MCP server for up-to-date library documentation (requires API key)
- Enforces simplicity-first principles across all projects

## Customization

You can modify `CLAUDE_TEMPLATE.md` to use your own coding guidelines and principles instead of the default Linus Torvalds-style rules.

**IMPORTANT**: The first line must remain `- **Current date**: YYYY-MM-DD` for the SessionStart hook to update the date automatically. Add your custom content starting from line 2.

After modifying `CLAUDE_TEMPLATE.md`, run `./setup.sh` again to apply your changes.

## Hooks

Auto-formatting hooks that run when Claude Code writes or edits files.

### Install Hooks to a Project

```bash
./setup-hooks.sh <project_path>
```

Installs:
- Hook scripts to `<project>/.claude/hooks/`
- Settings to `<project>/.claude/settings.json` (merges if exists)

### Current Hooks

- **format-python.sh**: Auto-formats Python files using ruff via uvx
  - Runs on Write/Edit/MultiEdit operations
  - Formats code and fixes style issues
  - Ignores unused imports (F401) since Claude adds imports before implementation
  - Shows errors without blocking (lets Claude see and fix issues)

### Requirements

- jq: `brew install jq` (macOS) or `apt install jq` (Linux)
- uvx (from uv): https://docs.astral.sh/uv/getting-started/installation/

## MCP Servers

The setup script installs the following MCP servers:

### Playwright MCP
- **Auto-installed** during setup
- Enables browser automation for web development and testing
- No additional configuration required

### Context7 MCP
- **Optional** - prompts for API key during setup
- Provides up-to-date, version-specific library documentation
- Get your API key at: https://context7.com/dashboard
- If skipped during setup, install later with:
  ```bash
  claude mcp add -s user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY
  ```

To list installed MCP servers: `claude mcp list`

## Philosophy

Good code is simple code. Complex solutions indicate poor understanding. Every line is a liability—delete aggressively.
