#!/usr/bin/env bats
#
# Tests for quiet mode in molt-security-audit.sh
#
# Note: Quiet mode suppresses PASS and SKIP log messages, but does NOT
# suppress the banner or section headers. Only JSON mode suppresses the banner.
#

setup() {
    load '../test_helper/common-setup'
    source_moltaudit_functions
    reset_counters
}

# =============================================================================
# PASS/SKIP Suppression Tests
# =============================================================================

@test "quiet mode suppresses PASS messages" {
    JSON_MODE=false
    QUIET_MODE=true

    run log_pass "Test Check" "test passed"
    assert_output ""
}

@test "quiet mode suppresses SKIP messages" {
    JSON_MODE=false
    QUIET_MODE=true

    run log_skip "Test Check" "skipped check"
    assert_output ""
}

@test "quiet mode suppresses info messages" {
    JSON_MODE=false
    QUIET_MODE=true

    run log_info "Information message"
    assert_output ""
}

# =============================================================================
# FAIL/WARN Display Tests
# =============================================================================

@test "quiet mode shows FAIL messages" {
    JSON_MODE=false
    QUIET_MODE=true

    run log_fail "Critical Issue" "something failed"
    assert_output --partial "[FAIL]"
    assert_output --partial "Critical Issue"
}

@test "quiet mode shows WARN messages" {
    JSON_MODE=false
    QUIET_MODE=true

    run log_warn "Warning Issue" "something needs attention"
    assert_output --partial "[WARN]"
    assert_output --partial "Warning Issue"
}

# =============================================================================
# Counter Behavior Tests
# =============================================================================

@test "quiet mode still increments counters" {
    JSON_MODE=false
    QUIET_MODE=true

    log_pass "Test1" "passed" >/dev/null
    log_pass "Test2" "passed" >/dev/null
    log_fail "Test3" "failed" >/dev/null

    [[ $PASS_COUNT -eq 2 ]]
    [[ $FAIL_COUNT -eq 1 ]]
}

@test "quiet mode still calculates risk score" {
    JSON_MODE=false
    QUIET_MODE=true

    log_fail "Test1" "failed" 15 >/dev/null
    log_warn "Test2" "warning" 5 >/dev/null

    [[ $RISK_SCORE -eq 20 ]]
}

# =============================================================================
# Normal Mode Comparison Tests
# =============================================================================

@test "normal mode shows PASS messages" {
    JSON_MODE=false
    QUIET_MODE=false

    run log_pass "Test Check" "test passed"
    assert_output --partial "[PASS]"
    assert_output --partial "Test Check"
}

@test "normal mode shows SKIP messages" {
    JSON_MODE=false
    QUIET_MODE=false

    run log_skip "Skipped Check" "not applicable"
    assert_output --partial "[SKIP]"
    assert_output --partial "Skipped Check"
}

@test "normal mode shows info messages" {
    JSON_MODE=false
    QUIET_MODE=false

    run log_info "Information message"
    assert_output --partial "Information message"
}

# =============================================================================
# Quiet Mode Behavior Verification
# =============================================================================

@test "quiet mode does not affect section headers" {
    JSON_MODE=false
    QUIET_MODE=true

    run log_section "Test Section"
    # Section headers are NOT suppressed in quiet mode
    assert_output --partial "Test Section"
}

@test "quiet mode combined with JSON mode produces JSON" {
    JSON_MODE=true
    QUIET_MODE=true
    JSON_RESULTS=()

    # In JSON mode, output should be JSON regardless of quiet
    run log_pass "Test" "message"
    # JSON mode produces no console output (results stored in array)
    assert_output ""
}
