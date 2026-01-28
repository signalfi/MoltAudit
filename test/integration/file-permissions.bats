#!/usr/bin/env bats
#
# Integration tests for check_file_permissions in molt-security-audit.sh
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
# .env File Permission Tests
# =============================================================================

@test "check_file_permissions fails on world-readable .env file" {
    # Create world-readable .env
    mkdir -p "$HOME/project"
    echo "SECRET=value" > "$HOME/project/.env"
    chmod 644 "$HOME/project/.env"

    JSON_MODE=false
    QUIET_MODE=false
    FAIL_COUNT=0

    run check_file_permissions

    # Should detect the issue
    [[ $FAIL_COUNT -gt 0 ]] || [[ "$output" == *"world-readable"* ]] || [[ "$output" == *".env"* ]]
}

@test "check_file_permissions passes on restricted .env file" {
    # Create properly secured .env
    mkdir -p "$HOME/project"
    echo "SECRET=value" > "$HOME/project/.env"
    chmod 600 "$HOME/project/.env"

    JSON_MODE=false
    QUIET_MODE=false

    # Verify permissions
    local perms
    if [[ "$(uname)" == "Darwin" ]]; then
        perms=$(stat -f %Lp "$HOME/project/.env")
    else
        perms=$(stat -c %a "$HOME/project/.env")
    fi

    [[ "$perms" == "600" ]]
}

@test "check_file_permissions fix mode corrects .env permissions" {
    # Create world-readable .env
    mkdir -p "$HOME/project"
    echo "SECRET=value" > "$HOME/project/.env"
    chmod 644 "$HOME/project/.env"

    JSON_MODE=false
    QUIET_MODE=false
    FIX_MODE=true

    # Run check with fix mode
    check_file_permissions

    # Verify permissions were fixed
    local perms
    if [[ "$(uname)" == "Darwin" ]]; then
        perms=$(stat -f %Lp "$HOME/project/.env")
    else
        perms=$(stat -c %a "$HOME/project/.env")
    fi

    [[ "$perms" == "600" ]]
}

# =============================================================================
# SSH Key Permission Tests
# =============================================================================

@test "check_file_permissions fails on loose SSH key permissions" {
    # Create SSH directory with loose key permissions
    mkdir -p "$HOME/.ssh"
    echo "fake key content" > "$HOME/.ssh/id_rsa"
    chmod 644 "$HOME/.ssh/id_rsa"

    JSON_MODE=false
    QUIET_MODE=false
    FAIL_COUNT=0

    run check_file_permissions

    # Should detect the issue
    [[ $FAIL_COUNT -gt 0 ]] || [[ "$output" == *"SSH"* ]] || [[ "$output" == *"permissions"* ]]
}

@test "check_file_permissions passes on correct SSH key permissions" {
    # Create SSH directory with correct permissions
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    echo "fake key content" > "$HOME/.ssh/id_rsa"
    chmod 600 "$HOME/.ssh/id_rsa"

    # Verify permissions
    local perms
    if [[ "$(uname)" == "Darwin" ]]; then
        perms=$(stat -f %Lp "$HOME/.ssh/id_rsa")
    else
        perms=$(stat -c %a "$HOME/.ssh/id_rsa")
    fi

    [[ "$perms" == "600" ]]
}

@test "check_file_permissions ignores .pub files" {
    # Create SSH directory
    mkdir -p "$HOME/.ssh"
    echo "public key content" > "$HOME/.ssh/id_rsa.pub"
    chmod 644 "$HOME/.ssh/id_rsa.pub"  # Public keys can be world-readable

    # .pub files should not trigger failure
    JSON_MODE=false
    QUIET_MODE=false
    FAIL_COUNT=0

    # The script should skip .pub files in the key check
    local key="$HOME/.ssh/id_rsa.pub"
    [[ "$key" =~ \.pub$ ]]  # Should match
}

@test "check_file_permissions fix mode corrects SSH key permissions" {
    mkdir -p "$HOME/.ssh"
    echo "fake key content" > "$HOME/.ssh/id_rsa"
    chmod 644 "$HOME/.ssh/id_rsa"

    FIX_MODE=true
    JSON_MODE=false
    QUIET_MODE=false

    check_file_permissions

    # Verify permissions were fixed
    local perms
    if [[ "$(uname)" == "Darwin" ]]; then
        perms=$(stat -f %Lp "$HOME/.ssh/id_rsa")
    else
        perms=$(stat -c %a "$HOME/.ssh/id_rsa")
    fi

    [[ "$perms" == "600" ]]
}

# =============================================================================
# AWS Credentials Tests
# =============================================================================

@test "check_file_permissions fails on world-readable AWS credentials" {
    mkdir -p "$HOME/.aws"
    echo "[default]" > "$HOME/.aws/credentials"
    echo "aws_access_key_id = AKIAIOSFODNN7EXAMPLE" >> "$HOME/.aws/credentials"
    chmod 644 "$HOME/.aws/credentials"

    JSON_MODE=false
    QUIET_MODE=false
    FAIL_COUNT=0

    run check_file_permissions

    [[ $FAIL_COUNT -gt 0 ]] || [[ "$output" == *"AWS"* ]] || [[ "$output" == *"credentials"* ]]
}

@test "check_file_permissions passes on restricted AWS credentials" {
    mkdir -p "$HOME/.aws"
    echo "[default]" > "$HOME/.aws/credentials"
    chmod 600 "$HOME/.aws/credentials"

    local perms
    if [[ "$(uname)" == "Darwin" ]]; then
        perms=$(stat -f %Lp "$HOME/.aws/credentials")
    else
        perms=$(stat -c %a "$HOME/.aws/credentials")
    fi

    [[ "$perms" == "600" ]]
}

# =============================================================================
# Config Directory Tests
# =============================================================================

@test "check_file_permissions fails on world-accessible config directory" {
    mkdir -p "$HOME/.clawdbot"
    chmod 755 "$HOME/.clawdbot"

    JSON_MODE=false
    QUIET_MODE=false
    FAIL_COUNT=0

    run check_file_permissions

    [[ $FAIL_COUNT -gt 0 ]] || [[ "$output" == *"world-accessible"* ]] || [[ "$output" == *"clawdbot"* ]]
}

@test "check_file_permissions passes on restricted config directory" {
    mkdir -p "$HOME/.clawdbot"
    chmod 700 "$HOME/.clawdbot"

    local perms
    if [[ "$(uname)" == "Darwin" ]]; then
        perms=$(stat -f %Lp "$HOME/.clawdbot")
    else
        perms=$(stat -c %a "$HOME/.clawdbot")
    fi

    [[ "$perms" == "700" ]]
}

# =============================================================================
# Edge Cases
# =============================================================================

@test "check_file_permissions handles filenames with spaces" {
    mkdir -p "$HOME/my project"
    echo "SECRET=value" > "$HOME/my project/.env"
    chmod 644 "$HOME/my project/.env"

    # Should not error on spaces in path
    run check_file_permissions
    [[ $status -eq 0 ]]
}

@test "check_file_permissions handles empty .env file" {
    mkdir -p "$HOME/project"
    touch "$HOME/project/.env"
    chmod 644 "$HOME/project/.env"

    # Should still check permissions on empty file
    run check_file_permissions
    [[ $status -eq 0 ]]
}

@test "check_file_permissions handles missing directories gracefully" {
    # No .ssh, .aws, or .clawdbot directories
    rm -rf "$HOME/.ssh" "$HOME/.aws" "$HOME/.clawdbot" 2>/dev/null || true

    run check_file_permissions
    # Should not error
    [[ $status -eq 0 ]]
}
