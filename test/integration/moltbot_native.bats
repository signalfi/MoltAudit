#!/usr/bin/env bats
#
# Integration tests for check_moltbot_native_audit in molt-security-audit.sh
#

setup() {
    load '../test_helper/common-setup'
    source_moltaudit_functions
    reset_counters
    setup_test_home
}

teardown() {
    teardown_test_home
}

# =============================================================================
# CLI Detection Tests
# =============================================================================

@test "check_moltbot_native_audit skips when no CLI installed" {
    # Restrict PATH to only mocks dir (which has no moltbot/clawdbot)
    activate_mocks
    local saved_path="$PATH"
    export PATH="${BATS_TEST_TMPDIR}/mocks/bin"

    JSON_MODE=false
    QUIET_MODE=false
    DEEP_MODE=false
    SKIP_COUNT=0

    check_moltbot_native_audit

    export PATH="$saved_path"
    [[ $SKIP_COUNT -gt 0 ]]
}

@test "check_moltbot_native_audit detects moltbot CLI" {
    create_smart_mock "moltbot" << 'MOCK'
if [[ "$1" == "security" && "$2" == "audit" ]]; then
    echo "✓ DM policy is pairing"
    exit 0
fi
exit 1
MOCK
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    DEEP_MODE=false
    PASS_COUNT=0

    check_moltbot_native_audit

    [[ $PASS_COUNT -gt 0 ]]
}

@test "check_moltbot_native_audit falls back to clawdbot CLI" {
    # Only create clawdbot mock, no moltbot
    create_smart_mock "clawdbot" << 'MOCK'
if [[ "$1" == "security" && "$2" == "audit" ]]; then
    echo "✓ Gateway auth enabled"
    exit 0
fi
exit 1
MOCK
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    DEEP_MODE=false
    PASS_COUNT=0

    check_moltbot_native_audit

    [[ $PASS_COUNT -gt 0 ]]
}

# =============================================================================
# Output Parsing Tests
# =============================================================================

@test "check_moltbot_native_audit parses pass findings" {
    create_smart_mock "moltbot" << 'MOCK'
if [[ "$1" == "security" && "$2" == "audit" ]]; then
    echo "✓ DM policy is pairing (default)"
    echo "✓ Gateway auth is enabled"
    echo "✓ Sandbox mode is active"
    exit 0
fi
exit 1
MOCK
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    DEEP_MODE=false
    PASS_COUNT=0

    check_moltbot_native_audit

    [[ $PASS_COUNT -eq 3 ]]
}

@test "check_moltbot_native_audit parses fail findings" {
    create_smart_mock "moltbot" << 'MOCK'
if [[ "$1" == "security" && "$2" == "audit" ]]; then
    echo "✗ Gateway exposed without auth"
    echo "✗ DM policy is open"
    exit 0
fi
exit 1
MOCK
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    DEEP_MODE=false
    FAIL_COUNT=0

    check_moltbot_native_audit

    [[ $FAIL_COUNT -eq 2 ]]
}

@test "check_moltbot_native_audit parses warn findings" {
    create_smart_mock "moltbot" << 'MOCK'
if [[ "$1" == "security" && "$2" == "audit" ]]; then
    echo "⚠ Model may be susceptible to prompt injection"
    echo "⚠ Plugins loaded without explicit allowlist"
    exit 0
fi
exit 1
MOCK
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    DEEP_MODE=false
    WARN_COUNT=0

    check_moltbot_native_audit

    [[ $WARN_COUNT -eq 2 ]]
}

@test "check_moltbot_native_audit parses mixed findings" {
    create_smart_mock "moltbot" << 'MOCK'
if [[ "$1" == "security" && "$2" == "audit" ]]; then
    echo "✓ DM policy is pairing"
    echo "✗ Gateway exposed without auth"
    echo "⚠ Legacy model configured"
    echo "✓ File permissions OK"
    exit 0
fi
exit 1
MOCK
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    DEEP_MODE=false
    PASS_COUNT=0
    FAIL_COUNT=0
    WARN_COUNT=0

    check_moltbot_native_audit

    [[ $PASS_COUNT -eq 2 ]]
    [[ $FAIL_COUNT -eq 1 ]]
    [[ $WARN_COUNT -eq 1 ]]
}

@test "check_moltbot_native_audit parses bracket-style markers" {
    create_smart_mock "moltbot" << 'MOCK'
if [[ "$1" == "security" && "$2" == "audit" ]]; then
    echo "[PASS] Gateway auth enabled"
    echo "[FAIL] Open DM policy detected"
    echo "[WARN] Sandbox not configured"
    exit 0
fi
exit 1
MOCK
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    DEEP_MODE=false
    PASS_COUNT=0
    FAIL_COUNT=0
    WARN_COUNT=0

    check_moltbot_native_audit

    [[ $PASS_COUNT -eq 1 ]]
    [[ $FAIL_COUNT -eq 1 ]]
    [[ $WARN_COUNT -eq 1 ]]
}

# =============================================================================
# Empty / Unrecognized Output Tests
# =============================================================================

@test "check_moltbot_native_audit handles empty output" {
    create_smart_mock "moltbot" << 'MOCK'
if [[ "$1" == "security" && "$2" == "audit" ]]; then
    exit 0
fi
exit 1
MOCK
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    DEEP_MODE=false
    WARN_COUNT=0

    check_moltbot_native_audit

    [[ $WARN_COUNT -gt 0 ]]
}

@test "check_moltbot_native_audit handles unrecognized format" {
    create_smart_mock "moltbot" << 'MOCK'
if [[ "$1" == "security" && "$2" == "audit" ]]; then
    echo "Some unstructured output"
    echo "That has no markers"
    exit 0
fi
exit 1
MOCK
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    DEEP_MODE=false
    WARN_COUNT=0

    check_moltbot_native_audit

    # Should warn about unrecognized format
    [[ $WARN_COUNT -gt 0 ]]
}

# =============================================================================
# Deep Mode Tests
# =============================================================================

@test "check_moltbot_native_audit forwards --deep flag" {
    create_smart_mock "moltbot" << 'MOCK'
if [[ "$1" == "security" && "$2" == "audit" && "$3" == "--deep" ]]; then
    echo "✓ Live Gateway probe passed"
    exit 0
elif [[ "$1" == "security" && "$2" == "audit" ]]; then
    echo "✗ No deep probe (missing --deep)"
    exit 0
fi
exit 1
MOCK
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    DEEP_MODE=true
    PASS_COUNT=0
    FAIL_COUNT=0

    check_moltbot_native_audit

    [[ $PASS_COUNT -eq 1 ]]
    [[ $FAIL_COUNT -eq 0 ]]
}

@test "check_moltbot_native_audit does not send --deep when disabled" {
    create_smart_mock "moltbot" << 'MOCK'
if [[ "$1" == "security" && "$2" == "audit" && "$3" == "--deep" ]]; then
    echo "✗ Should not have received --deep"
    exit 0
elif [[ "$1" == "security" && "$2" == "audit" ]]; then
    echo "✓ Standard audit ran correctly"
    exit 0
fi
exit 1
MOCK
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    DEEP_MODE=false
    PASS_COUNT=0
    FAIL_COUNT=0

    check_moltbot_native_audit

    [[ $PASS_COUNT -eq 1 ]]
    [[ $FAIL_COUNT -eq 0 ]]
}
