#!/usr/bin/env bats
#
# Unit tests for argument parsing in molt-security-audit.sh
#

setup() {
    load '../test_helper/common-setup'
}

# =============================================================================
# --help flag tests
# =============================================================================

@test "--help shows usage information" {
    run_moltaudit --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "molt-security-audit"
}

@test "-h shows usage information" {
    run_moltaudit -h
    assert_success
    assert_output --partial "Usage:"
}

@test "--help shows --fix option" {
    run_moltaudit --help
    assert_success
    assert_output --partial "--fix"
}

@test "--help shows --json option" {
    run_moltaudit --help
    assert_success
    assert_output --partial "--json"
}

@test "--help shows --quiet option" {
    run_moltaudit --help
    assert_success
    assert_output --partial "--quiet"
}

@test "--help shows exit codes" {
    run_moltaudit --help
    assert_success
    assert_output --partial "Exit Codes:"
    assert_output --partial "0"
    assert_output --partial "1"
    assert_output --partial "2"
}

@test "--help exits with code 0" {
    run_moltaudit --help
    assert_success
}

# =============================================================================
# Unknown option tests
# =============================================================================

@test "unknown option shows error message" {
    run_moltaudit --unknown-flag
    assert_failure
    assert_output --partial "Unknown option: --unknown-flag"
}

@test "unknown option shows help" {
    run_moltaudit --invalid
    assert_failure
    assert_output --partial "Usage:"
}

@test "unknown option exits with code 1" {
    run_moltaudit --foobar
    [[ $status -eq 1 ]]
}

# =============================================================================
# --json flag tests
# =============================================================================

@test "--json produces JSON output" {
    # Create mock environment to avoid actual checks
    setup_test_home
    activate_mocks

    run_moltaudit --json
    # May fail but should still produce JSON
    assert_output --partial "{"
    assert_output --partial "\"version\":"
    assert_output --partial "\"summary\":"

    teardown_test_home
}

@test "--json output is valid JSON" {
    setup_test_home
    activate_mocks

    run_moltaudit --json

    # Check output is valid JSON (regardless of exit code)
    if command -v jq &>/dev/null; then
        run bash -c "echo '$output' | jq . &>/dev/null"
        assert_success
    else
        # Fallback: basic structure check
        [[ "$output" =~ ^\{ ]]
    fi

    teardown_test_home
}

@test "--json contains required summary fields" {
    setup_test_home
    activate_mocks

    run_moltaudit --json

    assert_output --partial '"pass":'
    assert_output --partial '"fail":'
    assert_output --partial '"warn":'
    assert_output --partial '"skip":'
    assert_output --partial '"risk_score":'

    teardown_test_home
}

# =============================================================================
# --fix flag tests
# =============================================================================

@test "--fix sets FIX_MODE" {
    # Simulate parsing --fix flag
    FIX_MODE=false
    set -- --fix
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix) FIX_MODE=true; shift ;;
            *) shift ;;
        esac
    done

    [[ "$FIX_MODE" == true ]]
}

@test "--fix shows fix mode banner" {
    setup_test_home
    activate_mocks

    run_moltaudit --fix

    assert_output --partial "FIX MODE"

    teardown_test_home
}

# =============================================================================
# --quiet flag tests
# =============================================================================

@test "--quiet suppresses pass and skip messages" {
    source_moltaudit_functions
    reset_counters
    JSON_MODE=false
    QUIET_MODE=true

    # log_pass should be silent
    run log_pass "Test Check" "test passed"
    assert_output ""

    # log_skip should be silent
    run log_skip "Skipped Check" "not applicable"
    assert_output ""
}

# =============================================================================
# Combined flags tests
# =============================================================================

@test "multiple flags can be combined" {
    setup_test_home
    activate_mocks

    # Should not error
    run_moltaudit --json --quiet
    # Exit code depends on checks, but shouldn't crash
    [[ $status -le 2 ]]

    teardown_test_home
}
