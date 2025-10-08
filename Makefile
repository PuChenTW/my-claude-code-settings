.PHONY: lint-sh format-sh check-sh install-hooks

SHELL_FILES := $(shell find . -name '*.sh' -type f)

lint-sh:
	@echo "Running shellcheck on shell scripts..."
	@shellcheck $(SHELL_FILES)

format-sh:
	@echo "Formatting shell scripts with shfmt..."
	@shfmt -w -i 2 -bn -ci $(SHELL_FILES)

check-sh: lint-sh format-sh
	@echo "✓ All shell script checks passed"

install-hooks:
	@echo "Installing pre-commit hooks..."
	@pre-commit install
	@echo "✓ Pre-commit hooks installed"
