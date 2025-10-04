# Claude Code Settings

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

## Philosophy

Good code is simple code. Complex solutions indicate poor understanding. Every line is a liability—delete aggressively.
