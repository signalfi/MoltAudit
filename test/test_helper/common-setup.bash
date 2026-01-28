#!/usr/bin/env bash
#
# common-setup.bash - Shared test utilities for moltaudit bats tests
#

# Get the directory containing this script
_TEST_HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PROJECT_ROOT="$(cd "${_TEST_HELPER_DIR}/../.." && pwd)"

# Load bats libraries
load "${_TEST_HELPER_DIR}/bats-support/load"
load "${_TEST_HELPER_DIR}/bats-assert/load"

# =============================================================================
# Mock Utilities
# =============================================================================

# Creates a mock command that returns specified output and exit code
# Usage: create_mock "command_name" exit_code "output"
create_mock() {
    local cmd_name="$1"
    local exit_code="${2:-0}"
    local output="${3:-}"

    local mock_dir="${BATS_TEST_TMPDIR}/mocks/bin"
    mkdir -p "$mock_dir"

    cat > "${mock_dir}/${cmd_name}" << EOF
#!/usr/bin/env bash
if [[ -n "$output" ]]; then
    echo "$output"
fi
exit $exit_code
EOF
    chmod +x "${mock_dir}/${cmd_name}"
}

# Creates a mock that outputs content from a file
# Usage: create_mock_from_file "command_name" exit_code "/path/to/output/file"
create_mock_from_file() {
    local cmd_name="$1"
    local exit_code="${2:-0}"
    local output_file="$3"

    local mock_dir="${BATS_TEST_TMPDIR}/mocks/bin"
    mkdir -p "$mock_dir"

    cat > "${mock_dir}/${cmd_name}" << EOF
#!/usr/bin/env bash
cat "$output_file"
exit $exit_code
EOF
    chmod +x "${mock_dir}/${cmd_name}"
}

# Creates a mock that behaves differently based on arguments
# Usage: create_smart_mock "command_name" <<'SCRIPT'
#   if [[ "\$1" == "status" ]]; then echo "active"; fi
# SCRIPT
create_smart_mock() {
    local cmd_name="$1"

    local mock_dir="${BATS_TEST_TMPDIR}/mocks/bin"
    mkdir -p "$mock_dir"

    # Read script from stdin
    cat > "${mock_dir}/${cmd_name}" << 'HEADER'
#!/usr/bin/env bash
HEADER
    cat >> "${mock_dir}/${cmd_name}"
    chmod +x "${mock_dir}/${cmd_name}"
}

# Prepends mock directory to PATH - call this after creating mocks
activate_mocks() {
    export PATH="${BATS_TEST_TMPDIR}/mocks/bin:$PATH"
}

# =============================================================================
# Script Source Utilities
# =============================================================================

# Sources the script functions without running main
# Sets up all functions and variables for testing
source_moltaudit_functions() {
    # Create a modified version that doesn't run main
    local tmp_script="${BATS_TEST_TMPDIR}/moltaudit-functions.sh"

    # Copy everything except the last line that calls main
    # Use portable method that works on both Linux and macOS
    local total_lines
    total_lines=$(wc -l < "${_PROJECT_ROOT}/molt-security-audit.sh")
    head -n $((total_lines - 1)) "${_PROJECT_ROOT}/molt-security-audit.sh" > "$tmp_script"

    # Remove 'set -e' so tests can handle errors
    sed -i.bak 's/^set -euo pipefail$/set -uo pipefail/' "$tmp_script" 2>/dev/null || \
    sed -i '' 's/^set -euo pipefail$/set -uo pipefail/' "$tmp_script"

    # Source the functions
    # shellcheck source=/dev/null
    source "$tmp_script"
}

# Runs the full script with given arguments
run_moltaudit() {
    run "${_PROJECT_ROOT}/molt-security-audit.sh" "$@"
}

# =============================================================================
# Fixture Utilities
# =============================================================================

# Returns path to fixtures directory
fixtures_dir() {
    echo "${_TEST_HELPER_DIR}/../fixtures"
}

# Creates a temporary home directory for testing
setup_test_home() {
    export ORIGINAL_HOME="$HOME"
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "$HOME"
}

# Restores original HOME
teardown_test_home() {
    if [[ -n "${ORIGINAL_HOME:-}" ]]; then
        export HOME="$ORIGINAL_HOME"
    fi
}

# =============================================================================
# Assertion Helpers
# =============================================================================

# Assert that output contains valid JSON
assert_valid_json() {
    if command -v jq &>/dev/null; then
        echo "$output" | jq . &>/dev/null || {
            echo "Output is not valid JSON:"
            echo "$output"
            return 1
        }
    else
        # Fallback: basic check for JSON structure
        [[ "$output" =~ ^\{.*\}$ ]] || {
            echo "Output does not appear to be JSON:"
            echo "$output"
            return 1
        }
    fi
}

# Assert JSON field equals value
# Usage: assert_json_field ".summary.pass" "5"
assert_json_field() {
    local field="$1"
    local expected="$2"

    if command -v jq &>/dev/null; then
        local actual
        actual=$(echo "$output" | jq -r "$field")
        [[ "$actual" == "$expected" ]] || {
            echo "Expected $field to be '$expected', got '$actual'"
            return 1
        }
    fi
}

# Assert output contains no ANSI color codes
assert_no_colors() {
    # Check for common ANSI escape sequences
    if [[ "$output" =~ $'\033\[' ]]; then
        echo "Output contains ANSI color codes"
        return 1
    fi
}

# =============================================================================
# Counter Reset
# =============================================================================

# Resets all counters to initial state
reset_counters() {
    PASS_COUNT=0
    FAIL_COUNT=0
    WARN_COUNT=0
    SKIP_COUNT=0
    RISK_SCORE=0
    JSON_RESULTS=()
}
