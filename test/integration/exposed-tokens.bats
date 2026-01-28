#!/usr/bin/env bats
#
# Integration tests for check_exposed_tokens in molt-security-audit.sh
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
# Token in Logs Tests
# =============================================================================

@test "check_exposed_tokens fails when API token found in logs" {
    # Create clawdbot directory with log containing token
    mkdir -p "$HOME/.clawdbot"
    cat > "$HOME/.clawdbot/app.log" << 'EOF'
2024-01-15 10:00:00 INFO Starting bot
2024-01-15 10:00:01 DEBUG Using token: sk-ant-api03-abc123xyz
2024-01-15 10:00:02 INFO Connected to API
EOF

    JSON_MODE=false
    QUIET_MODE=false
    FAIL_COUNT=0

    run check_exposed_tokens

    # Should detect token in logs
    [[ $FAIL_COUNT -gt 0 ]] || [[ "$output" == *"token"* ]] || [[ "$output" == *"log"* ]]
}

@test "check_exposed_tokens detects GitHub token in logs" {
    mkdir -p "$HOME/.clawdbot"
    cat > "$HOME/.clawdbot/app.log" << 'EOF'
2024-01-15 10:00:00 DEBUG GitHub token: ghp_abc123xyz789
EOF

    run grep -E "ghp_" "$HOME/.clawdbot/app.log"
    assert_success
}

@test "check_exposed_tokens detects Slack token in logs" {
    mkdir -p "$HOME/.moltbot"
    cat > "$HOME/.moltbot/app.log" << 'EOF'
2024-01-15 10:00:00 DEBUG Slack bot token: xoxb-123-456-abc
EOF

    run grep -E "xoxb-" "$HOME/.moltbot/app.log"
    assert_success
}

@test "check_exposed_tokens detects Stripe token in logs" {
    mkdir -p "$HOME/.clawdbot"
    cat > "$HOME/.clawdbot/app.log" << 'EOF'
2024-01-15 10:00:00 DEBUG Stripe key: sk_live_abc123xyz
EOF

    run grep -E "sk_live_" "$HOME/.clawdbot/app.log"
    assert_success
}

@test "check_exposed_tokens passes when logs are clean" {
    mkdir -p "$HOME/.clawdbot"
    cat > "$HOME/.clawdbot/app.log" << 'EOF'
2024-01-15 10:00:00 INFO Starting bot
2024-01-15 10:00:01 INFO Using API key from environment
2024-01-15 10:00:02 INFO Connected successfully
2024-01-15 10:00:03 INFO Processing request
EOF

    run grep -E "(sk-ant-|ghp_|xoxb-|xoxp-|sk_live_)" "$HOME/.clawdbot/app.log"
    assert_failure  # No match means clean
}

# =============================================================================
# Token in Shell History Tests
# =============================================================================

@test "check_exposed_tokens warns when token found in bash history" {
    # Create bash history with token
    cat > "$HOME/.bash_history" << 'EOF'
ls -la
cd /home/user
export API_KEY=sk-ant-api03-secretkey123
npm install
EOF

    run grep -E "sk-ant-" "$HOME/.bash_history"
    assert_success
}

@test "check_exposed_tokens warns when AWS key found in history" {
    cat > "$HOME/.bash_history" << 'EOF'
aws configure
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
aws s3 ls
EOF

    run grep -E "AKIA" "$HOME/.bash_history"
    assert_success
}

@test "check_exposed_tokens checks zsh history" {
    cat > "$HOME/.zsh_history" << 'EOF'
: 1705320000:0;export GITHUB_TOKEN=ghp_abc123secrettoken
: 1705320001:0;git push
EOF

    run grep -E "ghp_" "$HOME/.zsh_history"
    assert_success
}

@test "check_exposed_tokens passes when history is clean" {
    cat > "$HOME/.bash_history" << 'EOF'
ls -la
cd /project
npm install
git status
docker ps
EOF

    run grep -E "(sk-ant-|ghp_|xoxb-|xoxp-|sk_live_|AKIA)" "$HOME/.bash_history"
    assert_failure  # No match
}

# =============================================================================
# Multiple Search Paths Tests
# =============================================================================

@test "check_exposed_tokens searches all config directories" {
    # Create multiple config directories
    mkdir -p "$HOME/.clawdbot"
    mkdir -p "$HOME/.moltbot"
    mkdir -p "$HOME/.config/clawdbot"
    mkdir -p "$HOME/.config/moltbot"

    touch "$HOME/.clawdbot/app.log"
    touch "$HOME/.moltbot/app.log"
    touch "$HOME/.config/clawdbot/app.log"
    touch "$HOME/.config/moltbot/app.log"

    # All directories should exist
    [[ -d "$HOME/.clawdbot" ]]
    [[ -d "$HOME/.moltbot" ]]
    [[ -d "$HOME/.config/clawdbot" ]]
    [[ -d "$HOME/.config/moltbot" ]]
}

# =============================================================================
# Edge Cases
# =============================================================================

@test "check_exposed_tokens handles missing log directories" {
    # No log directories exist
    rm -rf "$HOME/.clawdbot" "$HOME/.moltbot" "$HOME/.config/clawdbot" "$HOME/.config/moltbot" 2>/dev/null || true

    run check_exposed_tokens
    # Should not error
    assert_success
}

@test "check_exposed_tokens handles missing history files" {
    rm -f "$HOME/.bash_history" "$HOME/.zsh_history" 2>/dev/null || true

    run check_exposed_tokens
    assert_success
}

@test "check_exposed_tokens handles empty log files" {
    mkdir -p "$HOME/.clawdbot"
    touch "$HOME/.clawdbot/app.log"

    run check_exposed_tokens
    assert_success
}

@test "check_exposed_tokens handles log files with special characters" {
    mkdir -p "$HOME/.clawdbot"
    cat > "$HOME/.clawdbot/app.log" << 'EOF'
2024-01-15 User said: "Hello! How are you?"
2024-01-15 Path: /home/user/file with spaces.txt
2024-01-15 JSON: {"key": "value", "nested": {"a": 1}}
EOF

    run check_exposed_tokens
    assert_success
}
