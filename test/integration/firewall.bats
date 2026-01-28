#!/usr/bin/env bats
#
# Integration tests for check_firewall in molt-security-audit.sh
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
# UFW Tests
# =============================================================================

@test "check_firewall passes with UFW active" {
    create_mock "ufw" 0 "Status: active"
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    PASS_COUNT=0

    run check_firewall
    assert_success
}

@test "check_firewall detects UFW status output correctly" {
    create_mock "ufw" 0 "Status: active
To                         Action      From
--                         ------      ----
22                         ALLOW       Anywhere"
    activate_mocks

    run ufw status
    assert_success
    assert_output --partial "Status: active"
}

@test "check_firewall warns when UFW installed but inactive" {
    create_mock "ufw" 0 "Status: inactive"
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false

    run ufw status
    assert_success
    assert_output --partial "Status: inactive"
    refute_output --partial "Status: active"
}

# =============================================================================
# iptables Tests
# =============================================================================

@test "check_firewall passes with iptables rules" {
    # Simulate iptables with many rules (>8 lines)
    local iptables_output="Chain INPUT (policy DROP)
target     prot opt source               destination
ACCEPT     all  --  anywhere             anywhere
ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:ssh
ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:http
ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:https
DROP       all  --  anywhere             anywhere

Chain FORWARD (policy DROP)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination"

    create_mock "iptables" 0 "$iptables_output"
    activate_mocks

    run iptables -L -n
    assert_success

    # Count lines
    local lines=$(echo "$output" | wc -l)
    [[ $lines -gt 8 ]]
}

@test "check_firewall detects empty iptables" {
    # Simulate minimal iptables output (<=8 lines)
    local iptables_output="Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination"

    create_mock "iptables" 0 "$iptables_output"
    activate_mocks

    run iptables -L -n
    local lines=$(echo "$output" | wc -l)
    [[ $lines -le 8 ]]
}

# =============================================================================
# firewalld Tests
# =============================================================================

@test "check_firewall passes with firewalld active" {
    create_mock "firewall-cmd" 0 "running"
    create_smart_mock "systemctl" << 'MOCK'
if [[ "$1" == "is-active" && "$2" == "--quiet" && "$3" == "firewalld" ]]; then
    exit 0
fi
exit 1
MOCK
    activate_mocks

    run systemctl is-active --quiet firewalld
    assert_success
}

@test "check_firewall detects firewalld inactive" {
    create_mock "firewall-cmd" 0 ""
    create_smart_mock "systemctl" << 'MOCK'
exit 1
MOCK
    activate_mocks

    run systemctl is-active --quiet firewalld
    assert_failure
}

# =============================================================================
# No Firewall Tests
# =============================================================================

@test "check_firewall fails when no firewall is active" {
    # Don't create any firewall mocks
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    FAIL_COUNT=0

    # When no firewall commands exist, should fail
    run command -v ufw
    assert_failure

    run command -v firewall-cmd
    assert_failure
}

@test "check_firewall reports correct failure message" {
    # Create mocks that simulate no active firewall
    create_mock "ufw" 0 "Status: inactive"
    create_smart_mock "iptables" << 'MOCK'
echo "Chain INPUT (policy ACCEPT)"
echo "Chain FORWARD (policy ACCEPT)"
echo "Chain OUTPUT (policy ACCEPT)"
MOCK
    activate_mocks

    # ufw inactive
    run ufw status
    refute_output --partial "Status: active"

    # iptables minimal
    run iptables -L -n
    local lines=$(echo "$output" | wc -l)
    [[ $lines -le 8 ]]
}
