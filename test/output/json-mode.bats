#!/usr/bin/env bats
#
# Tests for JSON output mode in molt-security-audit.sh
#

setup() {
    load '../test_helper/common-setup'
    setup_test_home
    activate_mocks
}

teardown() {
    teardown_test_home
}

# =============================================================================
# JSON Structure Tests
# =============================================================================

@test "JSON output is valid JSON" {
    run_moltaudit --json

    # Use jq to validate if available (script may exit with 1 or 2 but JSON should still be valid)
    if command -v jq &>/dev/null; then
        run bash -c "echo '$output' | jq . &>/dev/null"
        assert_success
    else
        # Fallback: check for basic JSON structure
        [[ "$output" =~ ^\{ ]]
        [[ "$output" =~ \}$ ]]
    fi
}

@test "JSON output contains version field" {
    run_moltaudit --json

    assert_output --partial '"version":'
}

@test "JSON output contains timestamp field" {
    run_moltaudit --json

    assert_output --partial '"timestamp":'
}

@test "JSON output contains summary object" {
    run_moltaudit --json

    assert_output --partial '"summary":'
    assert_output --partial '"pass":'
    assert_output --partial '"fail":'
    assert_output --partial '"warn":'
    assert_output --partial '"skip":'
    assert_output --partial '"risk_score":'
}

@test "JSON output contains results array" {
    run_moltaudit --json

    assert_output --partial '"results":'
}

# =============================================================================
# JSON Values Tests
# =============================================================================

@test "JSON summary values are integers" {
    run_moltaudit --json

    if command -v jq &>/dev/null; then
        local pass=$(echo "$output" | jq '.summary.pass')
        local fail=$(echo "$output" | jq '.summary.fail')
        local warn=$(echo "$output" | jq '.summary.warn')
        local skip=$(echo "$output" | jq '.summary.skip')

        # Should be numeric
        [[ "$pass" =~ ^[0-9]+$ ]]
        [[ "$fail" =~ ^[0-9]+$ ]]
        [[ "$warn" =~ ^[0-9]+$ ]]
        [[ "$skip" =~ ^[0-9]+$ ]]
    fi
}

@test "JSON risk_score is a number" {
    run_moltaudit --json

    if command -v jq &>/dev/null; then
        local risk=$(echo "$output" | jq '.summary.risk_score')
        [[ "$risk" =~ ^[0-9]+$ ]]
    fi
}

@test "JSON version matches script version" {
    run_moltaudit --json

    # Version should be 1.0.0
    assert_output --partial '"version": "1.0.0"'
}

@test "JSON timestamp is ISO 8601 format" {
    run_moltaudit --json

    if command -v jq &>/dev/null; then
        local timestamp=$(echo "$output" | jq -r '.timestamp')
        # Format: YYYY-MM-DDTHH:MM:SSZ
        [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
    fi
}

# =============================================================================
# JSON Result Items Tests
# =============================================================================

@test "JSON result items have required fields" {
    run_moltaudit --json

    if command -v jq &>/dev/null; then
        # Get first result item
        local first_result=$(echo "$output" | jq '.results[0]')

        if [[ "$first_result" != "null" ]]; then
            # Check for required fields
            local has_check=$(echo "$first_result" | jq 'has("check")')
            local has_status=$(echo "$first_result" | jq 'has("status")')
            local has_message=$(echo "$first_result" | jq 'has("message")')

            [[ "$has_check" == "true" ]]
            [[ "$has_status" == "true" ]]
            [[ "$has_message" == "true" ]]
        fi
    fi
}

@test "JSON status values are valid" {
    run_moltaudit --json

    if command -v jq &>/dev/null; then
        # Extract all status values
        local statuses=$(echo "$output" | jq -r '.results[].status' 2>/dev/null | sort -u)

        # Each status should be one of: pass, fail, warn, skip
        while IFS= read -r status; do
            [[ "$status" =~ ^(pass|fail|warn|skip)$ ]]
        done <<< "$statuses"
    fi
}

@test "JSON fail results include risk field" {
    run_moltaudit --json

    if command -v jq &>/dev/null; then
        # Get all fail results
        local fail_results=$(echo "$output" | jq '[.results[] | select(.status == "fail")]')
        local count=$(echo "$fail_results" | jq 'length')

        if [[ "$count" -gt 0 ]]; then
            # Each fail should have a risk field
            local has_risk=$(echo "$fail_results" | jq 'all(has("risk"))')
            [[ "$has_risk" == "true" ]]
        fi
    fi
}

# =============================================================================
# No Color Codes Tests
# =============================================================================

@test "JSON output contains no ANSI color codes" {
    run_moltaudit --json

    # Check for common ANSI escape sequences
    if [[ "$output" =~ $'\033\[' ]]; then
        echo "Found ANSI color codes in JSON output"
        return 1
    fi
}

@test "JSON output contains no control characters" {
    run_moltaudit --json

    # Remove valid JSON whitespace and check for control chars
    # Valid JSON should only have printable ASCII plus \n, \t within strings
    if command -v jq &>/dev/null; then
        # If jq can parse it, it's valid
        echo "$output" | jq . &>/dev/null
    fi
}

# =============================================================================
# JSON with Other Flags Tests
# =============================================================================

@test "JSON mode works with --quiet" {
    run_moltaudit --json --quiet

    # Should still produce valid JSON
    [[ "$output" =~ ^\{ ]]
    [[ "$output" =~ \}$ ]]
}

@test "JSON output is machine-parseable" {
    run_moltaudit --json

    # Create a script that parses the JSON
    if command -v jq &>/dev/null; then
        local pass_count=$(echo "$output" | jq '.summary.pass')
        local fail_count=$(echo "$output" | jq '.summary.fail')

        # Values should be extractable
        [[ -n "$pass_count" ]]
        [[ -n "$fail_count" ]]
    fi
}
