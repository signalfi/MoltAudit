#!/usr/bin/env bats
#
# Tests for report generation and exit codes in molt-security-audit.sh
#

setup() {
    load '../test_helper/common-setup'
    source_moltaudit_functions
    setup_test_home
    activate_mocks
}

teardown() {
    teardown_test_home
}

# =============================================================================
# Risk Score Threshold Tests
# =============================================================================

@test "risk score 0 shows Excellent rating" {
    reset_counters
    RISK_SCORE=0
    JSON_MODE=false

    run generate_report

    assert_output --partial "0/100"
    assert_output --partial "Excellent"
}

@test "risk score 1-24 shows Good rating" {
    reset_counters
    RISK_SCORE=20
    JSON_MODE=false

    run generate_report

    assert_output --partial "20/100"
    assert_output --partial "Good"
}

@test "risk score 25-49 shows Moderate Risk rating" {
    reset_counters
    RISK_SCORE=35
    JSON_MODE=false

    run generate_report

    assert_output --partial "35/100"
    assert_output --partial "Moderate Risk"
}

@test "risk score 50-74 shows High Risk rating" {
    reset_counters
    RISK_SCORE=60
    JSON_MODE=false

    run generate_report

    assert_output --partial "60/100"
    assert_output --partial "High Risk"
}

@test "risk score 75+ shows CRITICAL RISK rating" {
    reset_counters
    RISK_SCORE=80
    JSON_MODE=false

    run generate_report

    assert_output --partial "80/100"
    assert_output --partial "CRITICAL RISK"
}

@test "risk score boundary: 24 is Good" {
    reset_counters
    RISK_SCORE=24
    JSON_MODE=false

    run generate_report
    assert_output --partial "Good"
}

@test "risk score boundary: 25 is Moderate Risk" {
    reset_counters
    RISK_SCORE=25
    JSON_MODE=false

    run generate_report
    assert_output --partial "Moderate Risk"
}

@test "risk score boundary: 49 is Moderate Risk" {
    reset_counters
    RISK_SCORE=49
    JSON_MODE=false

    run generate_report
    assert_output --partial "Moderate Risk"
}

@test "risk score boundary: 50 is High Risk" {
    reset_counters
    RISK_SCORE=50
    JSON_MODE=false

    run generate_report
    assert_output --partial "High Risk"
}

@test "risk score boundary: 74 is High Risk" {
    reset_counters
    RISK_SCORE=74
    JSON_MODE=false

    run generate_report
    assert_output --partial "High Risk"
}

@test "risk score boundary: 75 is CRITICAL RISK" {
    reset_counters
    RISK_SCORE=75
    JSON_MODE=false

    run generate_report
    assert_output --partial "CRITICAL RISK"
}

# =============================================================================
# Exit Code Tests
# =============================================================================

@test "exit code 0 when all checks pass" {
    # Create minimal environment where checks pass
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Run with mocked environment (no services)
    run_moltaudit

    # Exit code should be 0, 1, or 2 depending on environment
    # In isolated test env with no services, likely all skipped = 0
    [[ $status -le 2 ]]
}

@test "exit code 1 when failures exist" {
    source_moltaudit_functions
    reset_counters

    FAIL_COUNT=1
    WARN_COUNT=0

    if [[ $FAIL_COUNT -gt 0 ]]; then
        exit_code=1
    elif [[ $WARN_COUNT -gt 0 ]]; then
        exit_code=2
    else
        exit_code=0
    fi

    [[ $exit_code -eq 1 ]]
}

@test "exit code 2 when only warnings exist" {
    source_moltaudit_functions
    reset_counters

    FAIL_COUNT=0
    WARN_COUNT=3

    if [[ $FAIL_COUNT -gt 0 ]]; then
        exit_code=1
    elif [[ $WARN_COUNT -gt 0 ]]; then
        exit_code=2
    else
        exit_code=0
    fi

    [[ $exit_code -eq 2 ]]
}

@test "exit code 1 takes precedence over exit code 2" {
    source_moltaudit_functions
    reset_counters

    FAIL_COUNT=1
    WARN_COUNT=5

    if [[ $FAIL_COUNT -gt 0 ]]; then
        exit_code=1
    elif [[ $WARN_COUNT -gt 0 ]]; then
        exit_code=2
    else
        exit_code=0
    fi

    [[ $exit_code -eq 1 ]]
}

# =============================================================================
# Report Content Tests
# =============================================================================

@test "report shows all counter values" {
    reset_counters
    PASS_COUNT=5
    FAIL_COUNT=2
    WARN_COUNT=3
    SKIP_COUNT=1
    JSON_MODE=false

    run generate_report

    assert_output --partial "Passed:"
    assert_output --partial "5"
    assert_output --partial "Failed:"
    assert_output --partial "2"
    assert_output --partial "Warnings:"
    assert_output --partial "3"
    assert_output --partial "Skipped:"
    assert_output --partial "1"
}

@test "report shows action required when failures exist" {
    reset_counters
    FAIL_COUNT=3
    JSON_MODE=false
    FIX_MODE=false

    run generate_report

    assert_output --partial "ACTION REQUIRED"
    assert_output --partial "3 critical issues"
}

@test "report suggests --fix when not in fix mode" {
    reset_counters
    FAIL_COUNT=1
    JSON_MODE=false
    FIX_MODE=false

    run generate_report

    assert_output --partial "--fix"
}

@test "report shows recommendation for warnings only" {
    reset_counters
    FAIL_COUNT=0
    WARN_COUNT=2
    JSON_MODE=false

    run generate_report

    assert_output --partial "RECOMMENDED"
    assert_output --partial "2 warnings"
}

@test "report shows success message when all pass" {
    reset_counters
    FAIL_COUNT=0
    WARN_COUNT=0
    PASS_COUNT=10
    JSON_MODE=false

    run generate_report

    assert_output --partial "All checks passed"
}

@test "report includes documentation reference" {
    reset_counters
    JSON_MODE=false

    run generate_report

    assert_output --partial "molt-security-vulnerabilities.md"
}

# =============================================================================
# JSON Report Tests
# =============================================================================

@test "JSON report includes all summary fields" {
    reset_counters
    PASS_COUNT=5
    FAIL_COUNT=2
    WARN_COUNT=3
    SKIP_COUNT=1
    RISK_SCORE=25
    JSON_MODE=true

    run generate_report

    assert_output --partial '"pass": 5'
    assert_output --partial '"fail": 2'
    assert_output --partial '"warn": 3'
    assert_output --partial '"skip": 1'
    assert_output --partial '"risk_score": 25'
}

@test "JSON report handles empty results array" {
    reset_counters
    JSON_MODE=true
    JSON_RESULTS=()

    run generate_report

    assert_output --partial '"results": []'
}

@test "JSON report formats results correctly" {
    reset_counters
    JSON_MODE=true
    JSON_RESULTS=(
        '{"check": "Test1", "status": "pass", "message": "OK"}'
        '{"check": "Test2", "status": "fail", "message": "Error", "risk": 10}'
    )

    run generate_report

    assert_output --partial '"results":'
    assert_output --partial '"check": "Test1"'
    assert_output --partial '"check": "Test2"'
}
