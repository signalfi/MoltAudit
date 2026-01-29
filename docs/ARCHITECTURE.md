# MoltAudit Architecture Reference

Complete inner workings reference for `molt-security-audit.sh` v2.0.0.

## 1. Script Structure

| Section | Lines | Description |
|---------|-------|-------------|
| Header & config | 1–58 | Shebang, `set -euo pipefail`, VERSION, colors, counters, option flags, JSON_RESULTS array |
| Helper functions | 60–198 | `print_banner`, `print_help`, `log_pass/fail/warn/skip/info/section`, `command_exists`, `json_escape`, `get_timestamp` |
| Core checks | 200–981 | 11 check functions (always run) |
| STIG checks | 983–1548 | 9 check functions (gated by `$STIG_MODE`) |
| Report generation | 1550–1621 | `generate_report()` — JSON or terminal output |
| Main | 1623–1717 | `main()` — arg parsing, check execution, exit code |

## 2. Execution Flow

```
main($@)
  ├── Parse arguments: --fix, --json, --quiet, --deep, --stig, --help
  ├── print_banner() [unless --json]
  ├── STIG mode indicator [if --stig]
  ├── FIX mode indicator [if --fix]
  │
  ├── Core checks (always):
  │   ├── check_ssh_security()          # lines 204–366
  │   ├── check_firewall()              # lines 368–460
  │   ├── check_gateway_exposure()      # lines 462–522
  │   ├── check_user_allowlist()        # lines 524–568
  │   ├── check_browser_profile()       # lines 570–596
  │   ├── check_password_manager()      # lines 598–654
  │   ├── check_docker_security()       # lines 656–743
  │   ├── check_file_permissions()      # lines 745–824
  │   ├── check_exposed_tokens()        # lines 826–859
  │   ├── check_running_processes()     # lines 861–873
  │   └── check_moltbot_native_audit()  # lines 875–981
  │
  ├── STIG checks (if $STIG_MODE == true):
  │   ├── check_kernel_hardening()      # lines 987–1025
  │   ├── check_audit_logging()         # lines 1027–1105
  │   ├── check_mandatory_access()      # lines 1107–1141
  │   ├── check_account_controls()      # lines 1143–1242
  │   ├── check_service_hardening()     # lines 1244–1302
  │   ├── check_crypto_controls()       # lines 1304–1357
  │   ├── check_file_integrity()        # lines 1359–1396
  │   ├── check_ai_supply_chain()       # lines 1398–1498
  │   └── check_network_zero_trust()    # lines 1500–1548
  │
  ├── generate_report()
  └── exit code (0=pass, 1=fail, 2=warn-only)
```

## 3. Global Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `VERSION` | string | `"2.0.0"` | Script version |
| `SCRIPT_NAME` | string | `"molt-security-audit"` | Used in help text |
| `RED/GREEN/YELLOW/BLUE/CYAN/BOLD/NC` | string | ANSI codes | Terminal colors |
| `PASS_COUNT` | integer | `0` | Passed check counter |
| `FAIL_COUNT` | integer | `0` | Failed check counter |
| `WARN_COUNT` | integer | `0` | Warning counter |
| `SKIP_COUNT` | integer | `0` | Skipped check counter |
| `FIX_MODE` | boolean | `false` | `--fix` flag |
| `JSON_MODE` | boolean | `false` | `--json` flag |
| `QUIET_MODE` | boolean | `false` | `--quiet` flag |
| `DEEP_MODE` | boolean | `false` | `--deep` flag |
| `STIG_MODE` | boolean | `false` | `--stig` flag |
| `RISK_SCORE` | integer | `0` | Accumulated risk (0-100+) |
| `JSON_RESULTS` | array | `()` | JSON result objects for `--json` output |

## 4. Helper Functions

| Function | Line | Purpose |
|----------|------|---------|
| `print_banner()` | 63 | Display ASCII banner with version |
| `print_help()` | 74 | Show usage, options, examples, exit codes |
| `log_pass(check, message)` | 106 | Record passed check; increments PASS_COUNT |
| `log_fail(check, message, risk)` | 120 | Record failure; increments FAIL_COUNT and RISK_SCORE |
| `log_warn(check, message, risk)` | 136 | Record warning; increments WARN_COUNT and RISK_SCORE |
| `log_skip(check, message)` | 152 | Record skipped check; increments SKIP_COUNT |
| `log_info(message)` | 166 | Print informational message (non-JSON, non-quiet) |
| `log_section(title)` | 173 | Print section header |
| `command_exists(cmd)` | 181 | Check if command is in PATH |
| `json_escape(str)` | 186 | Escape backslashes, quotes, newlines, tabs for JSON |
| `get_timestamp()` | 196 | UTC ISO-8601 timestamp |

## 5. Check Function Reference

### Core Checks

| # | Function | Lines | Sub-checks | Platform | Files/Commands Inspected |
|---|----------|-------|------------|----------|-------------------------|
| 1 | `check_ssh_security` | 204–366 | 3 core + 8 STIG | Both | `/etc/ssh/sshd_config`, `/etc/ssh/ssh_host_*_key{,.pub}`, `fail2ban-client`, `systemctl`, `ssh-keygen` |
| 2 | `check_firewall` | 368–460 | 3 core + 4 STIG (macOS) | Both | `ufw`, `iptables`, `firewall-cmd`, `defaults read com.apple.alf`, `spctl`, `csrutil` |
| 3 | `check_gateway_exposure` | 462–522 | 3 | Both | Bot config files, `ss`/`netstat` |
| 4 | `check_user_allowlist` | 524–568 | 3 | Both | Bot config files |
| 5 | `check_browser_profile` | 570–596 | 1 | Both | Bot config files |
| 6 | `check_password_manager` | 598–654 | 3 | Both | `op`, `bw`, `lpass` CLIs |
| 7 | `check_docker_security` | 656–743 | 4 core + 4 STIG (per container) | Both | `docker ps`, `docker inspect` |
| 8 | `check_file_permissions` | 745–824 | 4 | Both | `~/.env`, `~/.ssh/id_*`, `~/.aws/credentials`, `~/.clawdbot`, `~/.moltbot` |
| 9 | `check_exposed_tokens` | 826–859 | 2 | Both | Bot log files, `~/.bash_history`, `~/.zsh_history` |
| 10 | `check_running_processes` | 861–873 | 2 | Both | `pgrep`, `ps aux` |
| 11 | `check_moltbot_native_audit` | 875–981 | variable | Both | `moltbot`/`clawdbot` CLI |

### STIG Checks

| # | Function | Lines | Sub-checks | Platform | STIG IDs | Risk Range |
|---|----------|-------|------------|----------|----------|------------|
| 12 | `check_kernel_hardening` | 987–1025 | 11 | Linux | RHEL-09-213010/20/30, RHEL-09-253010/20/30/40/60 | 10–20 |
| 13 | `check_audit_logging` | 1027–1105 | 6 | Both | RHEL-09-653010/20/40/50, RHEL-09-654010 | 5–20 |
| 14 | `check_mandatory_access` | 1107–1141 | 2 | Linux | RHEL-09-431010, UBTU-24-431010 | 15–20 |
| 15 | `check_account_controls` | 1143–1242 | 6 | Linux | RHEL-09-412035, RHEL-09-411075, RHEL-09-611010/40, RHEL-09-412010 | 5–25 |
| 16 | `check_service_hardening` | 1244–1302 | 4 | Linux | RHEL-09-211010/20, RHEL-09-213040 | 5–15 |
| 17 | `check_crypto_controls` | 1304–1357 | 3 | Linux | RHEL-09-672010/15/20 | 5–15 |
| 18 | `check_file_integrity` | 1359–1396 | 3 | Linux | RHEL-09-651010, RHEL-09-232260/70 | 5–8 |
| 19 | `check_ai_supply_chain` | 1398–1498 | 6 | Both | NIST AI 100-1, FY2026 NDAA | 5–15 |
| 20 | `check_network_zero_trust` | 1500–1548 | 3 | Both | DoD ZT Ref Arch v2.0 | 5–10 |

## 6. JSON Output Schema

When `--json` is used, output follows this schema:

```json
{
  "version": "2.0.0",                    // string: script version
  "timestamp": "2026-01-28T15:00:00Z",   // string: ISO-8601 UTC
  "stig_mode": false,                     // boolean: whether --stig was used
  "summary": {
    "pass": 8,                            // integer: passed check count
    "fail": 0,                            // integer: failed check count
    "warn": 1,                            // integer: warning count
    "skip": 3,                            // integer: skipped check count
    "risk_score": 10                      // integer: accumulated risk (0+)
  },
  "results": [
    {
      "check": "SSH Password Auth",       // string: check name
      "status": "pass",                   // enum: pass|fail|warn|skip
      "message": "Password auth disabled" // string: human-readable detail
    },
    {
      "check": "Docker User",
      "status": "warn",
      "message": "Container running as root",
      "risk": 10                          // integer: only present for fail/warn
    }
  ]
}
```

The `risk` field is present only on `fail` and `warn` results.

## 7. Exit Code Logic

```
if FAIL_COUNT > 0:
    exit 1    # Critical failures found
elif WARN_COUNT > 0:
    exit 2    # Warnings only
else:
    exit 0    # All checks passed
```

## 8. Platform Detection

Checks use `uname` to determine platform:

| Pattern | Used By |
|---------|---------|
| `[[ "$(uname)" == "Darwin" ]]` → skip | `check_kernel_hardening`, `check_service_hardening`, `check_crypto_controls`, `check_mandatory_access` |
| `[[ "$(uname)" == "Darwin" ]]` → macOS path | `check_firewall` (ALF/Gatekeeper/SIP), `check_audit_logging` (launchctl) |
| `[[ "$(uname)" != "Darwin" ]]` → Linux path | `check_file_integrity` (world-writable/SUID) |
| No platform gate | All core checks, `check_account_controls`, `check_ai_supply_chain`, `check_network_zero_trust` |

Cross-platform commands use fallback patterns: `stat -c %a` (Linux) `|| stat -f %Lp` (macOS).

## 9. Risk Score Calculation

Risk is accumulated additively. Each `log_fail(check, msg, risk)` and `log_warn(check, msg, risk)` adds the risk value to `RISK_SCORE`.

| DISA Category | Risk Values | Examples |
|---------------|------------|----------|
| CAT I (Critical) | 20–25 | ASLR off (20), SELinux disabled (20), empty passwords (25), 1Password authenticated (25) |
| CAT II (High) | 10–15 | SSH password auth (15), weak ciphers (15), no firewall (15), no session timeout (10) |
| CAT III (Medium) | 5–8 | Missing SBOM (5), FIPS not enabled (5), debug shell (5), no FIM tool (8) |

Risk score interpretation (displayed in report):
- 0: Excellent
- 1–24: Good
- 25–49: Moderate Risk
- 50–74: High Risk
- 75+: Critical Risk

## 10. Config Files & Paths

Complete list of every file path and command the script reads:

### Files Read

| Path | Check Function |
|------|---------------|
| `/etc/ssh/sshd_config` | `check_ssh_security` |
| `/etc/ssh/ssh_host_*_key{,.pub}` | `check_ssh_security` (STIG: perms + RSA key size) |
| `~/.clawdbot/config.{json,yaml,yml}` | `check_gateway_exposure`, `check_user_allowlist`, `check_browser_profile` |
| `~/.moltbot/config.{json,yaml}` | Same as above |
| `~/.config/{clawdbot,moltbot}/config.json` | `check_gateway_exposure` |
| `~/.env` (3 levels deep via find) | `check_file_permissions` |
| `~/.ssh/id_*`, `~/.ssh/*_key` | `check_file_permissions` |
| `~/.aws/credentials` | `check_file_permissions` |
| `~/.bash_history`, `~/.zsh_history` | `check_exposed_tokens` |
| `/etc/audit/auditd.conf` | `check_audit_logging` |
| `/var/log/audit/audit.log` | `check_audit_logging` |
| `/etc/security/faillock.conf` | `check_account_controls` |
| `/etc/security/pwquality.conf` | `check_account_controls` |
| `/etc/shadow` | `check_account_controls` |
| `/etc/securetty` | `check_account_controls` |
| `/etc/profile`, `/etc/profile.d/*.sh` | `check_account_controls` |
| `/etc/systemd/coredump.conf` | `check_service_hardening` |
| `/etc/crypto-policies/back-ends/opensslcnf.config` | `check_crypto_controls` |
| `/proc/sys/crypto/fips_enabled` | `check_crypto_controls` |
| `/proc/cmdline` | `check_audit_logging` |
| `/etc/resolv.conf` | `check_network_zero_trust` |
| `/etc/systemd/resolved.conf` | `check_network_zero_trust` |
| `/etc/pam.d/*` | `check_account_controls` |
| `sbom.json`, `bom.xml`, `*.spdx` | `check_ai_supply_chain` |
| `~/.moltbot/models/*.{gguf,bin,safetensors}` | `check_ai_supply_chain` |

### Commands Executed

| Command | Check Function |
|---------|---------------|
| `sysctl -n <key>` (11 keys) | `check_kernel_hardening` |
| `ufw status` | `check_firewall` |
| `iptables -L -n` | `check_firewall` |
| `firewall-cmd` | `check_firewall` |
| `defaults read /Library/Preferences/com.apple.alf` | `check_firewall` (macOS) |
| `spctl --status` | `check_firewall` (macOS) |
| `csrutil status` | `check_firewall` (macOS) |
| `ss -tlnp` / `netstat -tlnp` | `check_gateway_exposure`, `check_network_zero_trust` |
| `op account list` | `check_password_manager` |
| `bw status` | `check_password_manager` |
| `lpass status` | `check_password_manager` |
| `docker ps`, `docker inspect` | `check_docker_security` |
| `pgrep`, `ps aux` | `check_running_processes` |
| `moltbot security audit` / `clawdbot security audit` | `check_moltbot_native_audit` |
| `systemctl is-active/is-enabled` | `check_audit_logging`, `check_service_hardening` |
| `auditctl -l` | `check_audit_logging` |
| `getenforce` / `aa-status` | `check_mandatory_access` |
| `getent shadow` | `check_account_controls` |
| `update-crypto-policies --show` | `check_crypto_controls` |
| `launchctl list` | `check_audit_logging` (macOS) |
| `ssh-keygen -l -f` | `check_ssh_security` (STIG: RSA key size) |
| `ip -o link show` / `ifconfig -a` | `check_network_zero_trust` |
| `find` | `check_file_permissions`, `check_file_integrity`, `check_ai_supply_chain` |

## 11. Test Architecture

### Mock System

Tests use helpers defined in `test/test_helper/common-setup.bash`:

| Helper | Purpose |
|--------|---------|
| `source_moltaudit_functions` | Sources the script for function access |
| `reset_counters` | Resets PASS/FAIL/WARN/SKIP counts and RISK_SCORE to 0 |
| `setup_test_home` | Creates temporary HOME with mock config directories |
| `create_mock <cmd> <output>` | Creates a mock command returning fixed output |
| `create_smart_mock <cmd> <script>` | Creates a mock with conditional logic |
| `activate_mocks` | Prepends mock directory to PATH |

### Test Categories

| Category | Directory | Count | Description |
|----------|-----------|-------|-------------|
| Unit | `test/unit/` | 53 | Individual function tests (helpers, json_escape, etc.) |
| Integration | `test/integration/` | 164 | Full check function tests with mocked external commands |
| Output | `test/output/` | 52 | JSON mode, quiet mode, fix mode, exit code verification |

### Fixture Files

| Fixture | Purpose |
|---------|---------|
| `sshd_config-secure` | Secure SSH config (core tests) |
| `sshd_config-insecure` | Insecure SSH config (core tests) |
| `sshd_config-stig-secure` | STIG-compliant SSH config (strong ciphers, MACs, timeouts) |
| `sshd_config-stig-weak` | STIG-weak SSH config (CBC ciphers, SHA-1 MACs) |
| `clawdbot-config-secure.json` | Secure bot config (localhost binding, auth enabled) |
| `clawdbot-config-insecure.json` | Insecure bot config (0.0.0.0 binding, auth disabled) |

### STIG Test Pattern

All STIG integration tests follow the same pattern:

```bash
setup() {
    source_moltaudit_functions
    reset_counters
    setup_test_home
    STIG_MODE=true
}

@test "check passes when hardened" {
    # Create mocks that simulate a secure system
    create_mock "sysctl" "2"
    activate_mocks
    run check_kernel_hardening
    assert_success
    [[ $PASS_COUNT -gt 0 ]]
}

@test "check fails when vulnerable" {
    # Create mocks that simulate an insecure system
    create_mock "sysctl" "0"
    activate_mocks
    run check_kernel_hardening
    assert_success  # function itself doesn't fail
    [[ $FAIL_COUNT -gt 0 ]]
}
```
