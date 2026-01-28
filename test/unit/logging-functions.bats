#!/usr/bin/env bats
#
# Unit tests for logging functions in molt-security-audit.sh
#

setup() {
    load '../test_helper/common-setup'
    source_moltaudit_functions
    reset_counters
}

# =============================================================================
# log_pass tests
# =============================================================================

@test "log_pass increments PASS_COUNT" {
    PASS_COUNT=0
    log_pass "Test Check" "test message" >/dev/null
    [[ $PASS_COUNT -eq 1 ]]
}

@test "log_pass outputs [PASS] in normal mode" {
    JSON_MODE=false
    QUIET_MODE=false
    run log_pass "SSH Config" "Password auth disabled"
    assert_success
    assert_output --partial "[PASS]"
    assert_output --partial "SSH Config"
    assert_output --partial "Password auth disabled"
}

@test "log_pass is silent in quiet mode" {
    JSON_MODE=false
    QUIET_MODE=true
    run log_pass "Test Check" "test message"
    assert_success
    assert_output ""
}

@test "log_pass adds JSON result in JSON mode" {
    JSON_MODE=true
    QUIET_MODE=false
    JSON_RESULTS=()
    log_pass "Test Check" "test message"
    [[ ${#JSON_RESULTS[@]} -eq 1 ]]
    [[ "${JSON_RESULTS[0]}" == *'"status": "pass"'* ]]
}

# =============================================================================
# log_fail tests
# =============================================================================

@test "log_fail increments FAIL_COUNT" {
    FAIL_COUNT=0
    log_fail "Test Check" "test message" >/dev/null
    [[ $FAIL_COUNT -eq 1 ]]
}

@test "log_fail adds to RISK_SCORE with default risk" {
    FAIL_COUNT=0
    RISK_SCORE=0
    log_fail "Test Check" "test message" >/dev/null
    [[ $RISK_SCORE -eq 10 ]]  # default risk is 10
}

@test "log_fail adds custom risk to RISK_SCORE" {
    FAIL_COUNT=0
    RISK_SCORE=0
    log_fail "Test Check" "test message" 25 >/dev/null
    [[ $RISK_SCORE -eq 25 ]]
}

@test "log_fail outputs [FAIL] in normal mode" {
    JSON_MODE=false
    QUIET_MODE=false
    run log_fail "Firewall" "No firewall active" 15
    assert_success
    assert_output --partial "[FAIL]"
    assert_output --partial "Firewall"
}

@test "log_fail shows in quiet mode (critical)" {
    JSON_MODE=false
    QUIET_MODE=true
    run log_fail "Test Check" "test message"
    assert_success
    assert_output --partial "[FAIL]"
}

@test "log_fail adds JSON result with risk in JSON mode" {
    JSON_MODE=true
    QUIET_MODE=false
    JSON_RESULTS=()
    log_fail "Test Check" "test message" 20
    [[ ${#JSON_RESULTS[@]} -eq 1 ]]
    [[ "${JSON_RESULTS[0]}" == *'"status": "fail"'* ]]
    [[ "${JSON_RESULTS[0]}" == *'"risk": 20'* ]]
}

# =============================================================================
# log_warn tests
# =============================================================================

@test "log_warn increments WARN_COUNT" {
    WARN_COUNT=0
    log_warn "Test Check" "test message" >/dev/null
    [[ $WARN_COUNT -eq 1 ]]
}

@test "log_warn adds to RISK_SCORE with default risk" {
    WARN_COUNT=0
    RISK_SCORE=0
    log_warn "Test Check" "test message" >/dev/null
    [[ $RISK_SCORE -eq 5 ]]  # default risk is 5
}

@test "log_warn outputs [WARN] in normal mode" {
    JSON_MODE=false
    QUIET_MODE=false
    run log_warn "Config" "Ambiguous setting" 5
    assert_success
    assert_output --partial "[WARN]"
    assert_output --partial "Config"
}

@test "log_warn shows in quiet mode (important)" {
    JSON_MODE=false
    QUIET_MODE=true
    run log_warn "Test Check" "test message"
    assert_success
    assert_output --partial "[WARN]"
}

# =============================================================================
# log_skip tests
# =============================================================================

@test "log_skip increments SKIP_COUNT" {
    SKIP_COUNT=0
    log_skip "Test Check" "test message" >/dev/null
    [[ $SKIP_COUNT -eq 1 ]]
}

@test "log_skip does not affect RISK_SCORE" {
    SKIP_COUNT=0
    RISK_SCORE=0
    log_skip "Test Check" "test message" >/dev/null
    [[ $RISK_SCORE -eq 0 ]]
}

@test "log_skip outputs [SKIP] in normal mode" {
    JSON_MODE=false
    QUIET_MODE=false
    run log_skip "Docker" "Docker not installed"
    assert_success
    assert_output --partial "[SKIP]"
    assert_output --partial "Docker"
}

@test "log_skip is silent in quiet mode" {
    JSON_MODE=false
    QUIET_MODE=true
    run log_skip "Test Check" "test message"
    assert_success
    assert_output ""
}

# =============================================================================
# log_info tests
# =============================================================================

@test "log_info outputs message in normal mode" {
    JSON_MODE=false
    QUIET_MODE=false
    run log_info "Information message"
    assert_success
    assert_output --partial "Information message"
}

@test "log_info is silent in JSON mode" {
    JSON_MODE=true
    QUIET_MODE=false
    run log_info "Information message"
    assert_success
    assert_output ""
}

@test "log_info is silent in quiet mode" {
    JSON_MODE=false
    QUIET_MODE=true
    run log_info "Information message"
    assert_success
    assert_output ""
}

# =============================================================================
# log_section tests
# =============================================================================

@test "log_section outputs section title in normal mode" {
    JSON_MODE=false
    run log_section "SSH Security"
    assert_success
    assert_output --partial "SSH Security"
}

@test "log_section is silent in JSON mode" {
    JSON_MODE=true
    run log_section "SSH Security"
    assert_success
    assert_output ""
}
