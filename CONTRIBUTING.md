# Contributing to moltaudit

Thank you for your interest in contributing to moltaudit! This document provides guidelines for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/signalfi/moltaudit/issues)
2. If not, create a new issue with:
   - A clear, descriptive title
   - Steps to reproduce the bug
   - Expected vs actual behavior
   - Your environment (OS, Bash version)
   - Relevant log output

### Suggesting Features

1. Check existing issues and discussions for similar suggestions
2. Create a new issue with the "enhancement" label
3. Describe:
   - The problem you're trying to solve
   - Your proposed solution
   - Alternative approaches you've considered

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Run tests: `make test`
5. Commit with a descriptive message
6. Push to your fork
7. Open a Pull Request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/signalfi/moltaudit.git
cd moltaudit

# Initialize test dependencies
make init-submodules

# Run tests to verify setup
make test
```

## Testing Guidelines

### Running Tests

```bash
# All tests
make test

# Specific categories
make test-unit
make test-integration
make test-output

# Single test file
make test-file FILE=test/unit/helper-functions.bats
```

### Writing Tests

Tests use [bats-core](https://github.com/bats-core/bats-core). Place new tests in the appropriate directory:

- `test/unit/` - Unit tests for individual functions
- `test/integration/` - Integration tests for security checks
- `test/output/` - Tests for output modes (JSON, quiet, etc.)

Example test:

```bash
@test "my_function handles edge case" {
    source_moltaudit_functions

    run my_function "edge_case_input"

    assert_success
    assert_output --partial "expected output"
}
```

### Test Requirements

- All new features must include tests
- All bug fixes should include a regression test
- Tests must pass on both Linux and macOS
- Use mocks for external commands (see `test/test_helper/common-setup.bash`)

## Code Style

### Shell Script Guidelines

- Use `#!/usr/bin/env bash` shebang
- Enable strict mode: `set -euo pipefail`
- Quote all variables: `"$variable"`
- Use `[[ ]]` for conditionals (not `[ ]`)
- Use `$(command)` for command substitution (not backticks)
- Add comments for complex logic
- Follow existing naming conventions

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new security check for X
fix: correct false positive in firewall detection
docs: update README with new usage examples
test: add tests for edge case in json_escape
refactor: simplify permission checking logic
```

## Project Structure

```
moltaudit/
├── molt-security-audit.sh           # Main script (20 check functions)
├── molt-security-vulnerabilities.md # Vulnerability documentation
├── Makefile                         # Build/test commands
├── docs/
│   ├── STIG-MAPPING.md              # DISA STIG / CIS / NIST control mapping
│   └── ARCHITECTURE.md              # Full inner workings reference
├── dev/
│   └── status.md                    # Development status & audit guide
├── test/
│   ├── bats/                        # bats-core (submodule)
│   ├── test_helper/
│   │   ├── bats-support/            # bats-support (submodule)
│   │   ├── bats-assert/             # bats-assert (submodule)
│   │   └── common-setup.bash        # Shared test utilities
│   ├── fixtures/                    # Test data files
│   │   ├── clawdbot-config-*.json   # Bot config fixtures
│   │   ├── sshd_config-secure       # Core SSH fixture
│   │   ├── sshd_config-insecure     # Core SSH fixture (negative)
│   │   ├── sshd_config-stig-secure  # STIG SSH fixture
│   │   └── sshd_config-stig-weak   # STIG SSH fixture (negative)
│   ├── unit/                        # 53 unit tests
│   ├── integration/                 # 164 integration tests
│   └── output/                      # 52 output tests
└── .github/
    └── workflows/                   # CI workflows
```

## Adding a New Security Check

1. Add the check function in `molt-security-audit.sh`:

```bash
check_new_feature() {
    log_section "New Feature Check"

    if [[ some_condition ]]; then
        log_pass "New Feature" "Everything is secure"
    else
        log_fail "New Feature" "Security issue detected" 15
        if [[ "$FIX_MODE" == true ]]; then
            echo -e "    ${YELLOW}→ Fix: command to fix${NC}"
        fi
    fi
}
```

2. Call it from `main()`:

```bash
check_new_feature
```

3. Add tests in `test/integration/new-feature.bats`

4. Document the vulnerability in `molt-security-vulnerabilities.md`

## Adding a STIG Check

STIG checks are gated behind the `--stig` flag and follow stricter contribution requirements:

1. **Gate behind `$STIG_MODE`** — All STIG checks must only execute when `$STIG_MODE == true`:

```bash
check_my_stig_feature() {
    log_section "My STIG Feature (DISA STIG / CIS L1)"

    # Skip on unsupported platforms
    if [[ "$(uname)" == "Darwin" ]]; then
        log_skip "My Feature" "Linux-only checks (skipped on macOS)"
        return
    fi

    if [[ some_condition ]]; then
        log_pass "My Feature" "Hardened correctly"
    else
        log_fail "My Feature" "Not hardened (RHEL-09-XXXXXX)" 15
    fi
}
```

2. **Add to `main()`** inside the STIG block:

```bash
if [[ "$STIG_MODE" == true ]]; then
    # ... existing STIG checks ...
    check_my_stig_feature
fi
```

3. **Map to compliance controls** — Add an entry to `docs/STIG-MAPPING.md` with:
   - DISA STIG ID (e.g., `RHEL-09-XXXXXX`)
   - CIS Benchmark ID (e.g., `CIS 5.2.X`)
   - NIST 800-53 control (e.g., `AC-6`)

4. **Use appropriate risk scores per DISA CAT level:**
   - CAT I (Critical): risk 20-25
   - CAT II (High): risk 10-15
   - CAT III (Medium): risk 5-8

5. **Platform detection** — Use `[[ "$(uname)" == "Darwin" ]]` to skip Linux-only checks on macOS.

6. **Add tests** — Create or extend `test/integration/<feature>.bats` with both secure and insecure cases. Use `STIG_MODE=true` in setup.

7. **Add STIG fixtures** if testing config file parsing (see `test/fixtures/sshd_config-stig-secure` and `sshd_config-stig-weak` for examples).

## Questions?

- Open an issue for questions about contributing
- Tag maintainers for urgent issues

Thank you for helping make moltaudit better!
