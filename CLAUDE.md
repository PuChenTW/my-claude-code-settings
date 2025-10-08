# Claude Code Settings Project

## Project Goal

Global configuration management for Claude Code that:
1. Enforces Linus Torvalds-style coding principles (simplicity, performance, zero bloat)
2. Installs and configures MCP servers (Playwright, Context7)
3. Provides auto-formatting hooks for projects
4. Maintains a SessionStart hook for date synchronization

## Architecture

```
.
├── CLAUDE_TEMPLATE.md      # Template for ~/.claude/CLAUDE.md (user's global guidelines)
├── setup.sh                # Main installer: copies template, installs MCP servers, sets up hooks
├── setup-hooks.sh          # Per-project hook installer
├── .claude/hooks/          # Hook scripts (format-python.sh, format-shellscript.sh)
└── scripts/                # Utility scripts (update-date.sh for SessionStart)
```

## Development Guidelines

### Shell Script Quality
- **All shell scripts must pass shellcheck** - no exceptions
- **Format with shfmt** (2-space indent, bash style)
- Use `make check-sh` before committing
- Install pre-commit hooks: `make install-hooks`

### Hook Scripts
- Must be idempotent and handle errors gracefully
- Show errors without blocking (let Claude see and fix issues)
- Use `uvx` for Python tools (no venv pollution)
- Exit 0 on success, non-zero on blocking errors

### Template Modifications
- First line of `CLAUDE_TEMPLATE.md` must be: `- **Current date**: YYYY-MM-DD`
- This enables the SessionStart hook to update dates automatically
- Add custom content from line 2 onward

## Testing

### Manual Testing
```bash
# Test setup script
./setup.sh

# Test hook installation
./setup-hooks.sh /path/to/test-project

# Verify hook behavior
cd /path/to/test-project
echo 'print("test")' > test.py  # Should trigger format-python.sh via Claude Code
```

### Automated Testing
```bash
make lint-sh      # Lint all .sh files
make format-sh    # Format all .sh files
make check-sh     # Both lint and format
```

## MCP Server Management

- **Playwright**: Auto-installed, no config needed
- **Context7**: Optional, requires API key from https://context7.com/dashboard
- List servers: `claude mcp list`
- Add Context7 later: `claude mcp add -s user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_KEY`

## Common Tasks

### Update Global Guidelines
1. Edit `CLAUDE_TEMPLATE.md`
2. Run `./setup.sh` to apply changes
3. Restart Claude Code session to load new guidelines

### Add New Hook
1. Create script in `.claude/hooks/`
2. Make executable: `chmod +x .claude/hooks/your-hook.sh`
3. Update `setup-hooks.sh` to copy it
4. Add corresponding settings to `.claude/settings.json` template in `setup-hooks.sh`

### Debug Hook Issues
- Hooks run in Claude Code's context - check stdout/stderr in Claude's output
- Test hook manually: `.claude/hooks/hook-name.sh /path/to/file`
- Verify jq syntax: `cat .claude/settings.json | jq .`

## Philosophy

This project practices what it preaches:
- **Simple**: Shell scripts, no framework bloat
- **Maintainable**: Each script does one thing well
- **Reliable**: Linting enforced, hooks handle errors gracefully
- **Practical**: Solves real problems (formatting, up-to-date docs, date sync)

Code should be boring, obvious, and correct. Cleverness is a bug, not a feature.
