# Makefile for moltaudit test suite
#
# Usage:
#   make test           - Run all tests
#   make test-unit      - Run unit tests only
#   make test-integration - Run integration tests only
#   make test-output    - Run output mode tests only
#   make test-verbose   - Run all tests with verbose output
#   make test-tap       - Run tests with TAP output (for CI)
#   make init-submodules - Initialize git submodules
#   make clean          - Clean test artifacts

.PHONY: test test-unit test-integration test-output test-verbose test-tap init-submodules clean help

# Path to bats executable
BATS := ./test/bats/bin/bats

# Test directories
TEST_DIR := test
UNIT_DIR := $(TEST_DIR)/unit
INTEGRATION_DIR := $(TEST_DIR)/integration
OUTPUT_DIR := $(TEST_DIR)/output

# Default target
.DEFAULT_GOAL := help

# Help target
help:
	@echo "moltaudit Test Suite"
	@echo ""
	@echo "Usage:"
	@echo "  make test              Run all tests"
	@echo "  make test-unit         Run unit tests only"
	@echo "  make test-integration  Run integration tests only"
	@echo "  make test-output       Run output mode tests only"
	@echo "  make test-verbose      Run all tests with verbose output"
	@echo "  make test-tap          Run tests with TAP output (for CI)"
	@echo "  make init-submodules   Initialize git submodules"
	@echo "  make clean             Clean test artifacts"
	@echo ""

# Initialize submodules (required before first run)
init-submodules:
	@echo "Initializing git submodules..."
	git submodule update --init --recursive

# Check if bats is available
check-bats:
	@if [ ! -x $(BATS) ]; then \
		echo "Error: bats not found. Run 'make init-submodules' first."; \
		exit 1; \
	fi

# Run all tests
test: check-bats
	@echo "Running all tests..."
	$(BATS) $(UNIT_DIR)/ $(INTEGRATION_DIR)/ $(OUTPUT_DIR)/

# Run unit tests
test-unit: check-bats
	@echo "Running unit tests..."
	$(BATS) $(UNIT_DIR)/

# Run integration tests
test-integration: check-bats
	@echo "Running integration tests..."
	$(BATS) $(INTEGRATION_DIR)/

# Run output mode tests
test-output: check-bats
	@echo "Running output mode tests..."
	$(BATS) $(OUTPUT_DIR)/

# Run tests with verbose output
test-verbose: check-bats
	@echo "Running all tests (verbose)..."
	$(BATS) --verbose-run $(UNIT_DIR)/ $(INTEGRATION_DIR)/ $(OUTPUT_DIR)/

# Run tests with TAP output (for CI/CD)
test-tap: check-bats
	@echo "Running all tests (TAP format)..."
	$(BATS) --formatter tap $(UNIT_DIR)/ $(INTEGRATION_DIR)/ $(OUTPUT_DIR)/

# Run specific test file
# Usage: make test-file FILE=test/unit/helper-functions.bats
test-file: check-bats
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=path/to/test.bats"; \
		exit 1; \
	fi
	$(BATS) $(FILE)

# Run tests matching a pattern
# Usage: make test-filter FILTER="json"
test-filter: check-bats
	@if [ -z "$(FILTER)" ]; then \
		echo "Usage: make test-filter FILTER=pattern"; \
		exit 1; \
	fi
	$(BATS) --filter "$(FILTER)" $(TEST_DIR)/

# Clean test artifacts
clean:
	@echo "Cleaning test artifacts..."
	rm -rf /tmp/bats-*
	rm -rf test/.bats-*
	@echo "Done."

# Run linter on test files (if shellcheck is available)
lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "Linting shell scripts..."; \
		shellcheck molt-security-audit.sh; \
		shellcheck test/test_helper/common-setup.bash; \
	else \
		echo "shellcheck not installed, skipping lint"; \
	fi

# Show test count
count:
	@echo "Test counts:"
	@echo "  Unit tests:        $$(grep -c '@test' $(UNIT_DIR)/*.bats 2>/dev/null | awk -F: '{sum+=$$2} END {print sum}')"
	@echo "  Integration tests: $$(grep -c '@test' $(INTEGRATION_DIR)/*.bats 2>/dev/null | awk -F: '{sum+=$$2} END {print sum}')"
	@echo "  Output tests:      $$(grep -c '@test' $(OUTPUT_DIR)/*.bats 2>/dev/null | awk -F: '{sum+=$$2} END {print sum}')"
	@echo "  Total:             $$(grep -c '@test' $(UNIT_DIR)/*.bats $(INTEGRATION_DIR)/*.bats $(OUTPUT_DIR)/*.bats 2>/dev/null | awk -F: '{sum+=$$2} END {print sum}')"
