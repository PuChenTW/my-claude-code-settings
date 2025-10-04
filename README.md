# Claude Code Settings

English | [繁體中文](README.zh-TW.md)

Global configuration for Claude Code that enforces Linus Torvalds-style coding principles: ruthless simplicity, performance-first thinking, and zero abstraction bloat.

## Setup

```bash
./setup.sh
```

This installs `CLAUDE.md` to `~/.claude/` and sets up a daily cron job to keep the date current.

## What It Does

- Copies coding guidelines to `~/.claude/CLAUDE.md`
- Sets up automatic date updates via cron
- Enforces simplicity-first principles across all projects

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

## Philosophy

Good code is simple code. Complex solutions indicate poor understanding. Every line is a liability—delete aggressively.
