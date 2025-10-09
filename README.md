# Claude & Codex Settings

English | [繁體中文](README.zh-TW.md)

Global configuration for Claude Code and the Codex CLI that enforces Linus Torvalds-style coding principles: ruthless simplicity, performance-first thinking, and zero abstraction bloat.

## Setup

```bash
./setup.sh
```

Requires `jq`, `claude`, and `codex` on your `PATH`. The wrapper script validates those tools, then hands off to the dedicated installers:

- `setup_claude.sh` updates `~/.claude/`, refreshes the SessionStart hook, and installs Claude MCP servers
- `setup_codex.sh` updates `~/.codex/`, refreshes the cron job, and installs Codex MCP servers

Run `setup_claude.sh` or `setup_codex.sh` directly if you only want to configure one client.

## What It Does

- Copies coding guidelines to `~/.claude/CLAUDE.md`
- Mirrors the same template into `~/.codex/AGENTS.md` for the Codex CLI and installs a daily cron job to refresh its date (backs up existing files before overwriting)
- Configures SessionStart hook to update date on every session
- Installs Playwright MCP server for web automation
- Optionally installs Context7 MCP server for up-to-date library documentation (requires API key)
- Enforces simplicity-first principles across all projects

> Requires the `crontab` command. If it's missing, you'll see a skip message and should refresh `AGENTS.md` manually.

## Customization

You can modify `PROMPT_TEMPLATE.md` to use your own coding guidelines and principles instead of the default Linus Torvalds-style rules.

**IMPORTANT**: The first line must remain `- **Current date**: YYYY-MM-DD` for the SessionStart hook to update the date automatically. Add your custom content starting from line 2.

After modifying `PROMPT_TEMPLATE.md`, run `./setup.sh` again to apply your changes.

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

- **format-shellscript.sh**: Lints and formats shell scripts using shellcheck and shfmt
  - Runs on Write/Edit/MultiEdit operations
  - Lints with shellcheck and formats with shfmt (2-space indent, bash style)
  - Shows errors without blocking (lets Claude see and fix issues)

### Requirements

- jq: `brew install jq` (macOS) or `apt install jq` (Linux)
- uvx (from uv): https://docs.astral.sh/uv/getting-started/installation/
- shellcheck: `brew install shellcheck` (macOS) or `apt install shellcheck` (Linux)
- shfmt: `brew install shfmt` (macOS) or `go install mvdan.cc/sh/v3/cmd/shfmt@latest` (Linux)

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

## Development

### Shell Script Quality

Makefile targets for linting and formatting shell scripts:

```bash
make lint-sh      # Run shellcheck on all .sh files
make format-sh    # Format with shfmt (2-space indent, bash style)
make check-sh     # Run both lint and format
```

### Pre-commit Hooks

Install pre-commit hooks to automatically check shell scripts before commits:

```bash
make install-hooks
```

This runs shellcheck and shfmt on staged .sh files. Commits are blocked if linting fails.

### Requirements

- shellcheck: `brew install shellcheck` (macOS) or `apt install shellcheck` (Linux)
- shfmt: `brew install shfmt` (macOS) or `go install mvdan.cc/sh/v3/cmd/shfmt@latest` (Linux)
- pre-commit: `brew install pre-commit` (macOS) or `pip install pre-commit` (Linux)

## Philosophy

Good code is simple code. Complex solutions indicate poor understanding. Every line is a liability—delete aggressively.
