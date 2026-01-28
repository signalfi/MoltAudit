<p align="center">
  <img src="assets/banner_v1.png" alt="MoltAudit - Secure Your Shell" width="100%">
</p>

# moltaudit

[![Tests](https://github.com/signalfi/MoltAudit/actions/workflows/test.yml/badge.svg)](https://github.com/signalfi/MoltAudit/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-blue.svg)](https://www.gnu.org/software/bash/)

**Defensive security audit tool for self-hosted AI assistant installations (Moltbot/Clawdbot).**

Based on [@mrnacknack](https://x.com/mrnacknack)'s research: *"10 ways to hack into a vibecoder's clawdbot"* - this tool helps you identify and fix security vulnerabilities before attackers do.

## What It Checks

| Category | Checks |
|----------|--------|
| **SSH Security** | Password auth, root login, fail2ban |
| **Firewall** | UFW, iptables, firewalld status |
| **Gateway Exposure** | Binding address, authentication |
| **User Allowlists** | Telegram, Discord, Slack restrictions |
| **Browser Security** | Profile isolation (session hijacking prevention) |
| **Password Managers** | 1Password, Bitwarden, LastPass CLI auth state |
| **Docker Security** | Privileged mode, socket mounts, root user |
| **File Permissions** | .env files, SSH keys, AWS credentials |
| **Token Exposure** | Tokens in logs, shell history |
| **Process Security** | Root processes, exposed tokens |
| **Moltbot Native Audit** | DM/group policies, tool blast radius, browser control, plugins, model hygiene, sandbox config |

## Quick Start

```bash
# Clone the repository
git clone https://github.com/signalfi/MoltAudit.git
cd moltaudit

# Make executable
chmod +x molt-security-audit.sh

# Run the audit
./molt-security-audit.sh
```

## Usage

```bash
# Basic audit
./molt-security-audit.sh

# Auto-fix safe issues (permissions, provides fix commands)
./molt-security-audit.sh --fix

# JSON output for CI/CD integration
./molt-security-audit.sh --json

# Show only failures and warnings
./molt-security-audit.sh --quiet

# Deep audit (includes native moltbot checks)
./molt-security-audit.sh --deep

# Show help
./molt-security-audit.sh --help
```

## Sample Output

```
╔══════════════════════════════════════════════════════════════════╗
║         Moltbot/Clawdbot Security Audit v1.1.0                   ║
║         Defensive Security Scanner                               ║
╚══════════════════════════════════════════════════════════════════╝

━━━ SSH Security (Hack #1: Brute Force Prevention) ━━━
  [PASS] SSH Password Auth: Password authentication is disabled
  [PASS] SSH Root Login: Root login is disabled
  [PASS] Fail2ban: Fail2ban is installed and running

━━━ Firewall (Hack #1, #2: Network Protection) ━━━
  [PASS] UFW Firewall: UFW is active

━━━ Docker Security (Hack #7: Sandbox Escape Prevention) ━━━
  [WARN] Docker User: Container 'myapp' running as root

══════════════════════════════════════════════════════════════════
                        AUDIT SUMMARY
══════════════════════════════════════════════════════════════════

  Passed:   8
  Failed:   0
  Warnings: 1
  Skipped:  3

  Risk Score: 10/100 - Good

  ℹ RECOMMENDED: Review 1 warnings for best security
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All checks passed |
| `1` | One or more critical failures |
| `2` | Warnings only (no critical failures) |

## JSON Output

For CI/CD integration, use `--json` to get machine-readable output:

```json
{
  "version": "1.1.0",
  "timestamp": "2026-01-28T15:00:00Z",
  "summary": {
    "pass": 8,
    "fail": 0,
    "warn": 1,
    "skip": 3,
    "risk_score": 10
  },
  "results": [
    {"check": "SSH Password Auth", "status": "pass", "message": "Password authentication is disabled"},
    {"check": "Docker User", "status": "warn", "message": "Container 'myapp' running as root", "risk": 10}
  ]
}
```

## Risk Score

The risk score (0-100) indicates overall security posture:

| Score | Rating | Action |
|-------|--------|--------|
| 0 | Excellent | Maintain current security |
| 1-24 | Good | Minor improvements possible |
| 25-49 | Moderate Risk | Address warnings soon |
| 50-74 | High Risk | Immediate attention needed |
| 75+ | Critical Risk | Stop and fix now |

## Requirements

- **Bash** 4.0 or higher
- **Linux** or **macOS**
- Root/sudo access recommended for full checks

### Optional Dependencies

The script works without these, but provides better coverage with:

- `ufw` / `iptables` / `firewall-cmd` - Firewall detection
- `docker` - Container security checks
- `fail2ban-client` - Brute force protection check
- `jq` - JSON validation (testing only)
- `moltbot` / `clawdbot` - Native audit integration (`--deep` mode)

## Running Tests

The project includes a comprehensive test suite using [bats-core](https://github.com/bats-core/bats-core):

```bash
# Initialize test dependencies (first time only)
make init-submodules

# Run all 173 tests
make test

# Run specific test categories
make test-unit         # 53 unit tests
make test-integration  # 68 integration tests
make test-output       # 52 output tests

# TAP format for CI
make test-tap
```

## CI/CD Integration

### GitHub Actions

```yaml
- name: Run Security Audit
  run: |
    ./molt-security-audit.sh --json > audit-results.json
    if [ $? -eq 1 ]; then
      echo "::error::Security audit found critical issues"
      exit 1
    fi
```

### GitLab CI

```yaml
security_audit:
  script:
    - ./molt-security-audit.sh --json
  allow_failure: false
```

## Documentation

- **[Security Vulnerabilities Guide](molt-security-vulnerabilities.md)** - Detailed explanation of each attack vector and prevention measures
- **[Contributing](CONTRIBUTING.md)** - How to contribute to the project
- **[Security Policy](SECURITY.md)** - How to report security issues

## Related Resources

- [Original Research](https://x.com/mrnacknack/status/2016134416897360212) - @mrnacknack's security analysis
- [Clawdhub Supply Chain Analysis](https://x.com/theonejvo) - Skill backdoor research by @theonejvo

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This tool is for **defensive security purposes only**. It audits YOUR OWN installation to help you identify and fix vulnerabilities. It does NOT perform attacks or test external systems.

---

**Stay secure!** If you find this tool useful, please star the repository and share it with others running self-hosted AI assistants.
