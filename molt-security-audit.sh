#!/usr/bin/env bash
#
# molt-security-audit.sh - Defensive Security Audit for Moltbot/Clawdbot Installations
#
# Based on: "10 ways to hack into a vibecoder's clawdbot" by @mrnacknack
# Source: https://x.com/mrnacknack/status/2016134416897360212
#
# This script performs DEFENSIVE security checks on YOUR OWN installation.
# It does NOT perform any attacks or test external systems.
#
# Usage: ./molt-security-audit.sh [OPTIONS]
#
# Options:
#   --fix       Attempt to auto-fix safe issues
#   --json      Output results as JSON
#   --quiet     Only show failures
#   --help      Show this help message
#

set -euo pipefail
shopt -s nullglob  # Handle glob patterns that match nothing

# =============================================================================
# Configuration
# =============================================================================

VERSION="1.0.0"
SCRIPT_NAME="molt-security-audit"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
SKIP_COUNT=0

# Options
FIX_MODE=false
JSON_MODE=false
QUIET_MODE=false

# Risk score (0-100)
RISK_SCORE=0

# JSON results array
declare -a JSON_RESULTS=()

# =============================================================================
# Helper Functions
# =============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║         Moltbot/Clawdbot Security Audit v${VERSION}                 ║"
    echo "║         Defensive Security Scanner                               ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${BLUE}Based on: ${NC}@mrnacknack's '10 ways to hack into a vibecoder's clawdbot'"
    echo ""
}

print_help() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Defensive security audit for Moltbot/Clawdbot installations.
Checks YOUR OWN installation for common vulnerabilities.

Options:
  --fix       Attempt to auto-fix safe issues (SSH config, permissions)
  --json      Output results as JSON (for CI/CD integration)
  --quiet     Only show failures and warnings
  --help      Show this help message

Examples:
  ${SCRIPT_NAME}              # Run full audit
  ${SCRIPT_NAME} --fix        # Run audit and fix issues
  ${SCRIPT_NAME} --json       # Output JSON for automation

Exit Codes:
  0  - All checks passed
  1  - One or more critical failures
  2  - Warnings only (no critical failures)

Documentation: See molt-security-vulnerabilities.md for details on each check.
EOF
}

log_pass() {
    local check="$1"
    local message="$2"
    PASS_COUNT=$((PASS_COUNT + 1))
    if [[ "$JSON_MODE" == true ]]; then
        local esc_check esc_msg
        esc_check=$(json_escape "$check")
        esc_msg=$(json_escape "$message")
        JSON_RESULTS+=("{\"check\": \"$esc_check\", \"status\": \"pass\", \"message\": \"$esc_msg\"}")
    elif [[ "$QUIET_MODE" == false ]]; then
        echo -e "  ${GREEN}[PASS]${NC} $check: $message"
    fi
}

log_fail() {
    local check="$1"
    local message="$2"
    local risk="${3:-10}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    RISK_SCORE=$((RISK_SCORE + risk))
    if [[ "$JSON_MODE" == true ]]; then
        local esc_check esc_msg
        esc_check=$(json_escape "$check")
        esc_msg=$(json_escape "$message")
        JSON_RESULTS+=("{\"check\": \"$esc_check\", \"status\": \"fail\", \"message\": \"$esc_msg\", \"risk\": $risk}")
    else
        echo -e "  ${RED}[FAIL]${NC} $check: $message"
    fi
}

log_warn() {
    local check="$1"
    local message="$2"
    local risk="${3:-5}"
    WARN_COUNT=$((WARN_COUNT + 1))
    RISK_SCORE=$((RISK_SCORE + risk))
    if [[ "$JSON_MODE" == true ]]; then
        local esc_check esc_msg
        esc_check=$(json_escape "$check")
        esc_msg=$(json_escape "$message")
        JSON_RESULTS+=("{\"check\": \"$esc_check\", \"status\": \"warn\", \"message\": \"$esc_msg\", \"risk\": $risk}")
    else
        echo -e "  ${YELLOW}[WARN]${NC} $check: $message"
    fi
}

log_skip() {
    local check="$1"
    local message="$2"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    if [[ "$JSON_MODE" == true ]]; then
        local esc_check esc_msg
        esc_check=$(json_escape "$check")
        esc_msg=$(json_escape "$message")
        JSON_RESULTS+=("{\"check\": \"$esc_check\", \"status\": \"skip\", \"message\": \"$esc_msg\"}")
    elif [[ "$QUIET_MODE" == false ]]; then
        echo -e "  ${BLUE}[SKIP]${NC} $check: $message"
    fi
}

log_info() {
    local message="$1"
    if [[ "$JSON_MODE" == false && "$QUIET_MODE" == false ]]; then
        echo -e "${CYAN}$message${NC}"
    fi
}

log_section() {
    local title="$1"
    if [[ "$JSON_MODE" == false ]]; then
        echo ""
        echo -e "${BOLD}━━━ $title ━━━${NC}"
    fi
}

command_exists() {
    command -v "$1" &> /dev/null
}

# Escape string for JSON output
json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"  # Escape backslashes
    str="${str//\"/\\\"}"  # Escape quotes
    str="${str//$'\n'/\\n}" # Escape newlines
    str="${str//$'\t'/\\t}" # Escape tabs
    echo "$str"
}

# Cross-platform timestamp (works on both Linux and macOS)
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# =============================================================================
# Security Checks
# =============================================================================

check_ssh_security() {
    log_section "SSH Security (Hack #1: Brute Force Prevention)"

    local sshd_config="/etc/ssh/sshd_config"

    if [[ ! -f "$sshd_config" ]]; then
        log_skip "SSH Config" "SSHD config not found (may not be a server)"
        return
    fi

    # Check password authentication
    if grep -E "^PasswordAuthentication\s+no" "$sshd_config" &>/dev/null; then
        log_pass "SSH Password Auth" "Password authentication is disabled"
    elif grep -E "^PasswordAuthentication\s+yes" "$sshd_config" &>/dev/null; then
        log_fail "SSH Password Auth" "Password authentication is ENABLED - vulnerable to brute force" 15
        if [[ "$FIX_MODE" == true ]]; then
            echo -e "    ${YELLOW}→ Fix: sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' $sshd_config${NC}"
        fi
    else
        log_warn "SSH Password Auth" "Password authentication not explicitly disabled (defaults may vary)" 10
    fi

    # Check root login
    if grep -E "^PermitRootLogin\s+no" "$sshd_config" &>/dev/null; then
        log_pass "SSH Root Login" "Root login is disabled"
    elif grep -E "^PermitRootLogin\s+(yes|without-password|prohibit-password)" "$sshd_config" &>/dev/null; then
        log_fail "SSH Root Login" "Root login is ENABLED" 15
        if [[ "$FIX_MODE" == true ]]; then
            echo -e "    ${YELLOW}→ Fix: sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' $sshd_config${NC}"
        fi
    else
        log_warn "SSH Root Login" "Root login not explicitly disabled" 10
    fi

    # Check for fail2ban
    if command_exists fail2ban-client; then
        if systemctl is-active --quiet fail2ban 2>/dev/null; then
            log_pass "Fail2ban" "Fail2ban is installed and running"
        else
            log_warn "Fail2ban" "Fail2ban is installed but not running" 8
        fi
    else
        log_fail "Fail2ban" "Fail2ban is NOT installed - no brute force protection" 12
        if [[ "$FIX_MODE" == true ]]; then
            echo -e "    ${YELLOW}→ Fix: sudo apt install fail2ban -y && sudo systemctl enable fail2ban${NC}"
        fi
    fi
}

check_firewall() {
    log_section "Firewall (Hack #1, #2: Network Protection)"

    local firewall_active=false

    # Check UFW
    if command_exists ufw; then
        if ufw status 2>/dev/null | grep -q "Status: active"; then
            log_pass "UFW Firewall" "UFW is active"
            firewall_active=true
        else
            log_warn "UFW Firewall" "UFW is installed but inactive" 10
        fi
    fi

    # Check iptables (if UFW not active)
    if [[ "$firewall_active" == false ]] && command_exists iptables; then
        local rules=0
        local iptables_output=""
        # Handle iptables failure gracefully (|| true prevents set -e exit)
        iptables_output=$(iptables -L -n 2>/dev/null) || true
        if [[ -n "$iptables_output" ]]; then
            rules=$(echo "$iptables_output" | wc -l)
            if [[ $rules -gt 8 ]]; then
                log_pass "iptables" "iptables has rules configured"
                firewall_active=true
            fi
        fi
    fi

    # Check firewalld
    if [[ "$firewall_active" == false ]] && command_exists firewall-cmd; then
        if systemctl is-active --quiet firewalld 2>/dev/null; then
            log_pass "firewalld" "firewalld is active"
            firewall_active=true
        fi
    fi

    if [[ "$firewall_active" == false ]]; then
        log_fail "Firewall" "No active firewall detected" 15
        if [[ "$FIX_MODE" == true ]]; then
            echo -e "    ${YELLOW}→ Fix: sudo apt install ufw && sudo ufw enable${NC}"
        fi
    fi
}

check_gateway_exposure() {
    log_section "Gateway Exposure (Hack #2: Control Gateway Security)"

    # Check for common clawdbot/moltbot config locations
    local config_paths=(
        "$HOME/.clawdbot/config.json"
        "$HOME/.clawdbot/config.yaml"
        "$HOME/.clawdbot/config.yml"
        "$HOME/.moltbot/config.json"
        "$HOME/.moltbot/config.yaml"
        "$HOME/.config/clawdbot/config.json"
        "$HOME/.config/moltbot/config.json"
    )

    local config_found=false

    for config in "${config_paths[@]}"; do
        if [[ -f "$config" ]]; then
            config_found=true
            log_info "  Found config: $config"

            # Check if bound to 0.0.0.0
            if grep -E "(0\.0\.0\.0|bind.*:.*0\.0\.0\.0)" "$config" &>/dev/null; then
                log_fail "Gateway Binding" "Gateway bound to 0.0.0.0 - exposed to internet!" 20
                if [[ "$FIX_MODE" == true ]]; then
                    echo -e "    ${YELLOW}→ Fix: Change bind address to 127.0.0.1 in $config${NC}"
                fi
            elif grep -E "(127\.0\.0\.1|localhost)" "$config" &>/dev/null; then
                log_pass "Gateway Binding" "Gateway bound to localhost"
            else
                log_warn "Gateway Binding" "Could not determine gateway binding" 5
            fi

            # Check authentication
            if grep -Ei "authentication.*:.*false|auth.*:.*false" "$config" &>/dev/null; then
                log_fail "Gateway Auth" "Gateway authentication is DISABLED" 20
            elif grep -Ei "authentication.*:.*true|auth.*:.*true" "$config" &>/dev/null; then
                log_pass "Gateway Auth" "Gateway authentication is enabled"
            else
                log_warn "Gateway Auth" "Could not determine authentication status" 10
            fi

            break
        fi
    done

    if [[ "$config_found" == false ]]; then
        log_skip "Gateway Config" "No clawdbot/moltbot config found"
    fi

    # Check for exposed ports
    if command_exists ss; then
        if ss -tlnp 2>/dev/null | grep -E ":18789|:8080" | grep -q "0.0.0.0"; then
            log_fail "Port Exposure" "Bot gateway port exposed on all interfaces" 15
        fi
    elif command_exists netstat; then
        if netstat -tlnp 2>/dev/null | grep -E ":18789|:8080" | grep -q "0.0.0.0"; then
            log_fail "Port Exposure" "Bot gateway port exposed on all interfaces" 15
        fi
    fi
}

check_user_allowlist() {
    log_section "User Allowlist (Hack #3: Unauthorized Access Prevention)"

    local config_paths=(
        "$HOME/.clawdbot/config.json"
        "$HOME/.clawdbot/config.yaml"
        "$HOME/.moltbot/config.json"
        "$HOME/.moltbot/config.yaml"
    )

    for config in "${config_paths[@]}"; do
        if [[ -f "$config" ]]; then
            # Check for Telegram allowlist
            if grep -Ei "telegram" "$config" &>/dev/null; then
                if grep -Ei "allowedUserIds|allowed_user_ids|user_id.*:" "$config" &>/dev/null; then
                    log_pass "Telegram Allowlist" "Telegram user allowlist appears configured"
                else
                    log_fail "Telegram Allowlist" "No Telegram user allowlist found - anyone can message bot" 15
                fi
            fi

            # Check for Discord allowlist
            if grep -Ei "discord" "$config" &>/dev/null; then
                if grep -Ei "allowedUserIds|allowed_user_ids" "$config" &>/dev/null; then
                    log_pass "Discord Allowlist" "Discord user allowlist appears configured"
                else
                    log_fail "Discord Allowlist" "No Discord user allowlist found" 15
                fi
            fi

            # Check for Slack allowlist
            if grep -Ei "slack" "$config" &>/dev/null; then
                if grep -Ei "allowedUserIds|allowed_user_ids" "$config" &>/dev/null; then
                    log_pass "Slack Allowlist" "Slack user allowlist appears configured"
                else
                    log_warn "Slack Allowlist" "No Slack user allowlist found" 10
                fi
            fi

            return
        fi
    done

    log_skip "User Allowlist" "No bot config found to check"
}

check_browser_profile() {
    log_section "Browser Security (Hack #4: Session Hijacking Prevention)"

    local config_paths=(
        "$HOME/.clawdbot/config.json"
        "$HOME/.clawdbot/config.yaml"
        "$HOME/.moltbot/config.json"
        "$HOME/.moltbot/config.yaml"
    )

    for config in "${config_paths[@]}"; do
        if [[ -f "$config" ]]; then
            # Check for browser profile configuration
            if grep -Ei "browser.*profile.*default|chrome.*profile.*default" "$config" &>/dev/null; then
                log_fail "Browser Profile" "Using DEFAULT browser profile - session hijacking risk!" 20
                echo -e "    ${YELLOW}→ Recommendation: Create isolated profile for bot${NC}"
            elif grep -Ei "browser.*profile|chrome.*profile|user.*data.*dir" "$config" &>/dev/null; then
                log_pass "Browser Profile" "Custom browser profile appears configured"
            else
                log_warn "Browser Profile" "Browser profile configuration not found" 10
            fi
            return
        fi
    done

    log_skip "Browser Profile" "No bot config found"
}

check_password_manager() {
    log_section "Password Manager (Hack #5: Credential Extraction Prevention)"

    # Check 1Password CLI (with timeout to prevent hanging)
    if command_exists op; then
        if command_exists timeout; then
            if timeout 5 op account list &>/dev/null; then
                log_fail "1Password CLI" "1Password CLI is AUTHENTICATED on this system!" 25
                echo -e "    ${RED}→ CRITICAL: Run 'op signout --all' to sign out${NC}"
            else
                log_pass "1Password CLI" "1Password CLI installed but not authenticated"
            fi
        else
            # Fallback without timeout (macOS may not have timeout)
            if op account list &>/dev/null 2>&1; then
                log_fail "1Password CLI" "1Password CLI is AUTHENTICATED on this system!" 25
                echo -e "    ${RED}→ CRITICAL: Run 'op signout --all' to sign out${NC}"
            else
                log_pass "1Password CLI" "1Password CLI installed but not authenticated"
            fi
        fi
    else
        log_pass "1Password CLI" "1Password CLI not installed on this system"
    fi

    # Check Bitwarden CLI (with timeout)
    if command_exists bw; then
        local bw_status
        if command_exists timeout; then
            bw_status=$(timeout 5 bw status 2>/dev/null || echo '{}')
        else
            bw_status=$(bw status 2>/dev/null || echo '{}')
        fi
        if echo "$bw_status" | grep -q '"status":"unlocked"'; then
            log_fail "Bitwarden CLI" "Bitwarden CLI is UNLOCKED on this system!" 25
            echo -e "    ${RED}→ CRITICAL: Run 'bw lock' to lock the vault${NC}"
        else
            log_pass "Bitwarden CLI" "Bitwarden CLI is locked or not logged in"
        fi
    fi

    # Check LastPass CLI (with timeout)
    if command_exists lpass; then
        local lpass_status
        if command_exists timeout; then
            lpass_status=$(timeout 5 lpass status 2>/dev/null || echo "Not logged in")
        else
            lpass_status=$(lpass status 2>/dev/null || echo "Not logged in")
        fi
        if echo "$lpass_status" | grep -q "Logged in"; then
            log_fail "LastPass CLI" "LastPass CLI is LOGGED IN on this system!" 25
            echo -e "    ${RED}→ CRITICAL: Run 'lpass logout' to sign out${NC}"
        else
            log_pass "LastPass CLI" "LastPass CLI not logged in"
        fi
    fi
}

check_docker_security() {
    log_section "Docker Security (Hack #7: Sandbox Escape Prevention)"

    if ! command_exists docker; then
        log_skip "Docker" "Docker not installed"
        return
    fi

    # Check if current user can run docker (is in docker group)
    if groups 2>/dev/null | grep -q docker; then
        log_warn "Docker Group" "Current user is in docker group - container escape possible" 5
    fi

    # Check running containers for privileged mode
    local containers
    containers=$(docker ps --format '{{.Names}}' 2>/dev/null) || true

    if [[ -n "$containers" && ! "$containers" =~ ^(Cannot|Error|permission) ]]; then
        while IFS= read -r container; do
            [[ -z "$container" ]] && continue
            # Check privileged
            if docker inspect "$container" 2>/dev/null | grep -q '"Privileged": true'; then
                log_fail "Docker Privileged" "Container '$container' running in PRIVILEGED mode!" 25
            fi

            # Check for host mounts
            if docker inspect "$container" 2>/dev/null | grep -qE '"Source": "/"[,}]|"Source": "/host"'; then
                log_fail "Docker Host Mount" "Container '$container' has HOST FILESYSTEM mounted!" 25
            fi

            # Check if running as root
            local user
            user=$(docker inspect "$container" --format '{{.Config.User}}' 2>/dev/null)
            if [[ -z "$user" || "$user" == "root" || "$user" == "0" ]]; then
                log_warn "Docker User" "Container '$container' running as root" 10
            fi

            # Check for docker socket mount
            if docker inspect "$container" 2>/dev/null | grep -q "/var/run/docker.sock"; then
                log_fail "Docker Socket" "Container '$container' has DOCKER SOCKET mounted!" 25
            fi

        done <<< "$containers"
    else
        log_skip "Docker Containers" "No running containers found"
    fi
}

check_file_permissions() {
    log_section "File Permissions (Credential Protection)"

    # Helper to check if permissions are world-readable (last digit is 4-7)
    is_world_readable() {
        local perms="$1"
        # Strip leading zeros and check last digit
        local last_digit="${perms: -1}"
        [[ "$last_digit" =~ [4-7] ]]
    }

    # Helper to check if directory is world-accessible (last digit is 5-7)
    is_world_accessible() {
        local perms="$1"
        local last_digit="${perms: -1}"
        [[ "$last_digit" =~ [5-7] ]]
    }

    # Check .env files (using -print0 for safe handling of filenames with spaces)
    while IFS= read -r -d '' env_file; do
        local perms
        perms=$(stat -c %a "$env_file" 2>/dev/null || stat -f %Lp "$env_file" 2>/dev/null)
        if is_world_readable "$perms"; then
            log_fail "File Permissions" "$env_file is world-readable (mode: $perms)" 10
            if [[ "$FIX_MODE" == true ]]; then
                chmod 600 "$env_file"
                echo -e "    ${GREEN}→ Fixed: chmod 600 $env_file${NC}"
            fi
        else
            log_pass "File Permissions" "$env_file has restricted permissions"
        fi
    done < <(find "$HOME" -maxdepth 3 -name ".env" -type f -print0 2>/dev/null)

    # Check SSH private keys (nullglob handles case where no files match)
    if [[ -d "$HOME/.ssh" ]]; then
        for key in "$HOME/.ssh/id_"* "$HOME/.ssh/"*_key; do
            if [[ -f "$key" && ! "$key" =~ \.pub$ ]]; then
                local perms
                perms=$(stat -c %a "$key" 2>/dev/null || stat -f %Lp "$key" 2>/dev/null)
                if [[ "$perms" != "600" && "$perms" != "400" ]]; then
                    log_fail "SSH Key Permissions" "$key has loose permissions (mode: $perms)" 15
                    if [[ "$FIX_MODE" == true ]]; then
                        chmod 600 "$key"
                        echo -e "    ${GREEN}→ Fixed: chmod 600 $key${NC}"
                    fi
                fi
            fi
        done
    fi

    # Check AWS credentials
    if [[ -f "$HOME/.aws/credentials" ]]; then
        local perms
        perms=$(stat -c %a "$HOME/.aws/credentials" 2>/dev/null || stat -f %Lp "$HOME/.aws/credentials" 2>/dev/null)
        if is_world_readable "$perms"; then
            log_fail "AWS Credentials" "\$HOME/.aws/credentials is world-readable" 15
            if [[ "$FIX_MODE" == true ]]; then
                chmod 600 "$HOME/.aws/credentials"
                echo -e "    ${GREEN}→ Fixed: chmod 600 \$HOME/.aws/credentials${NC}"
            fi
        else
            log_pass "AWS Credentials" "\$HOME/.aws/credentials has restricted permissions"
        fi
    fi

    # Check clawdbot/moltbot config directories
    for config_dir in "$HOME/.clawdbot" "$HOME/.moltbot"; do
        if [[ -d "$config_dir" ]]; then
            local dir_perms
            dir_perms=$(stat -c %a "$config_dir" 2>/dev/null || stat -f %Lp "$config_dir" 2>/dev/null)
            if is_world_accessible "$dir_perms"; then
                log_fail "Config Directory" "$config_dir is world-accessible" 15
                if [[ "$FIX_MODE" == true ]]; then
                    chmod 700 "$config_dir"
                    echo -e "    ${GREEN}→ Fixed: chmod 700 $config_dir${NC}"
                fi
            fi
        fi
    done
}

check_exposed_tokens() {
    log_section "Token Exposure (Credential Leak Detection)"

    # Search for exposed tokens in common locations
    local search_paths=(
        "$HOME/.clawdbot"
        "$HOME/.moltbot"
        "$HOME/.config/clawdbot"
        "$HOME/.config/moltbot"
    )

    for search_path in "${search_paths[@]}"; do
        if [[ -d "$search_path" ]]; then
            # Check for tokens in logs (using xargs for safety with filenames)
            local token_files
            token_files=$(find "$search_path" -name "*.log" -print0 2>/dev/null | \
                xargs -0 grep -l -E "(sk-ant-|ghp_|xoxb-|xoxp-|sk_live_)" 2>/dev/null | \
                head -1) || true
            if [[ -n "$token_files" ]]; then
                log_fail "Token in Logs" "API tokens found in log files in $search_path" 20
            fi
        fi
    done

    # Check shell history for tokens
    for hist_file in "$HOME/.bash_history" "$HOME/.zsh_history"; do
        if [[ -f "$hist_file" ]]; then
            if grep -E "(sk-ant-|ghp_|xoxb-|xoxp-|sk_live_|AKIA)" "$hist_file" &>/dev/null; then
                log_warn "Token in History" "Possible API tokens found in $hist_file" 10
                echo -e "    ${YELLOW}→ Consider clearing sensitive entries from shell history${NC}"
            fi
        fi
    done
}

check_running_processes() {
    log_section "Process Security"

    # Check if bot is running as root
    if pgrep -u root -f "clawdbot|moltbot" &>/dev/null; then
        log_fail "Bot User" "Bot process running as ROOT user!" 20
    fi

    # Check for processes with exposed tokens in command line
    if ps aux 2>/dev/null | grep -E "(sk-ant-|ghp_|xoxb-)" | grep -v grep &>/dev/null; then
        log_fail "Token in Process" "API tokens visible in process list!" 20
    fi
}

# =============================================================================
# Report Generation
# =============================================================================

generate_report() {
    if [[ "$JSON_MODE" == true ]]; then
        echo "{"
        echo "  \"version\": \"$VERSION\","
        echo "  \"timestamp\": \"$(get_timestamp)\","
        echo "  \"summary\": {"
        echo "    \"pass\": $PASS_COUNT,"
        echo "    \"fail\": $FAIL_COUNT,"
        echo "    \"warn\": $WARN_COUNT,"
        echo "    \"skip\": $SKIP_COUNT,"
        echo "    \"risk_score\": $RISK_SCORE"
        echo "  },"
        echo -n "  \"results\": ["
        if [[ ${#JSON_RESULTS[@]} -gt 0 ]]; then
            echo ""
            echo -n "    "
            printf '%s\n' "${JSON_RESULTS[@]}" | paste -sd ',' - | sed 's/,/,\n    /g'
            echo ""
            echo "  ]"
        else
            echo "]"
        fi
        echo "}"
    else
        echo ""
        echo -e "${BOLD}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}                        AUDIT SUMMARY                              ${NC}"
        echo -e "${BOLD}══════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "  ${GREEN}Passed:${NC}   $PASS_COUNT"
        echo -e "  ${RED}Failed:${NC}   $FAIL_COUNT"
        echo -e "  ${YELLOW}Warnings:${NC} $WARN_COUNT"
        echo -e "  ${BLUE}Skipped:${NC}  $SKIP_COUNT"
        echo ""

        # Risk score interpretation
        echo -ne "  ${BOLD}Risk Score:${NC} "
        if [[ $RISK_SCORE -eq 0 ]]; then
            echo -e "${GREEN}$RISK_SCORE/100 - Excellent${NC}"
        elif [[ $RISK_SCORE -lt 25 ]]; then
            echo -e "${GREEN}$RISK_SCORE/100 - Good${NC}"
        elif [[ $RISK_SCORE -lt 50 ]]; then
            echo -e "${YELLOW}$RISK_SCORE/100 - Moderate Risk${NC}"
        elif [[ $RISK_SCORE -lt 75 ]]; then
            echo -e "${RED}$RISK_SCORE/100 - High Risk${NC}"
        else
            echo -e "${RED}$RISK_SCORE/100 - CRITICAL RISK${NC}"
        fi

        echo ""

        if [[ $FAIL_COUNT -gt 0 ]]; then
            echo -e "  ${RED}⚠ ${BOLD}ACTION REQUIRED:${NC} $FAIL_COUNT critical issues need immediate attention"
            if [[ "$FIX_MODE" == false ]]; then
                echo -e "  ${YELLOW}→ Run with --fix to auto-remediate safe issues${NC}"
            fi
        elif [[ $WARN_COUNT -gt 0 ]]; then
            echo -e "  ${YELLOW}ℹ ${BOLD}RECOMMENDED:${NC} Review $WARN_COUNT warnings for best security"
        else
            echo -e "  ${GREEN}✓ ${BOLD}All checks passed!${NC} Your installation appears secure."
        fi

        echo ""
        echo -e "${CYAN}Documentation: See molt-security-vulnerabilities.md for remediation details${NC}"
        echo ""
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix)
                FIX_MODE=true
                shift
                ;;
            --json)
                JSON_MODE=true
                shift
                ;;
            --quiet)
                QUIET_MODE=true
                shift
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done

    if [[ "$JSON_MODE" == false ]]; then
        print_banner

        if [[ "$FIX_MODE" == true ]]; then
            echo -e "${YELLOW}Running in FIX MODE - will attempt to remediate issues${NC}"
            echo ""
        fi
    fi

    # Run all checks
    check_ssh_security
    check_firewall
    check_gateway_exposure
    check_user_allowlist
    check_browser_profile
    check_password_manager
    check_docker_security
    check_file_permissions
    check_exposed_tokens
    check_running_processes

    # Generate report
    generate_report

    # Exit with appropriate code
    if [[ $FAIL_COUNT -gt 0 ]]; then
        exit 1
    elif [[ $WARN_COUNT -gt 0 ]]; then
        exit 2
    else
        exit 0
    fi
}

main "$@"
