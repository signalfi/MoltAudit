<p align="center">
  <img src="assets/banner_v1.png" alt="MoltAudit - Secure Your Shell" width="100%">
</p>

# moltaudit

[![Tests](https://github.com/signalfi/MoltAudit/actions/workflows/test.yml/badge.svg)](https://github.com/signalfi/MoltAudit/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-blue.svg)](https://www.gnu.org/software/bash/)
[![Tests: 269](https://img.shields.io/badge/tests-269%20passed-brightgreen.svg)]()

**Lock down your second brain.** MoltAudit is a comprehensive security auditing and hardening platform for self-hosted AI assistant installations — Moltbot, Clawdbot, and any similar agent running on your infrastructure.

Your AI assistant has access to your shell, your browser sessions, your credentials, and your cloud keys. MoltAudit treats that attack surface with the seriousness it deserves: 20 check functions, 80+ sub-checks, DoD STIG/CIS/NIST compliance mapping, auto-fix remediation, CI/CD-ready JSON output, and cross-platform support for both Linux and macOS.

> **Origin story:** This project started from [@mrnacknack](https://x.com/mrnacknack)'s research *"10 ways to hack into a vibecoder's clawdbot"* — a sharp look at the real vulnerabilities in self-hosted AI setups. MoltAudit began as a script to check for those 10 issues and has since grown into a full security platform with DISA STIG, CIS Benchmark, and NIST 800-53 compliance controls, AI supply chain verification, and zero-trust network validation.

## Why MoltAudit

Self-hosted AI assistants are uniquely dangerous when misconfigured:

- They run with **your user permissions** — one prompt injection away from `rm -rf` or credential exfiltration
- They hold **live browser sessions** — session cookies, OAuth tokens, password manager vaults
- They expose **control gateways** — HTTP endpoints that, if bound to 0.0.0.0, let anyone on the network issue commands
- They pull **models and plugins** from the internet — unsigned code running in your shell
- They generate **logs full of API keys** — tokens in plaintext that outlive the session

MoltAudit audits all of this. One command, zero dependencies beyond Bash 4.

## Quick Start

```bash
git clone https://github.com/signalfi/MoltAudit.git
cd moltaudit
chmod +x molt-security-audit.sh

# Basic security audit
./molt-security-audit.sh

# Full DoD STIG/CIS/NIST compliance audit
./molt-security-audit.sh --stig

# Auto-fix what's safe to fix
./molt-security-audit.sh --stig --fix

# CI/CD compliance report
./molt-security-audit.sh --stig --json > audit-report.json
```

## What It Checks

### Core Checks (always run)

| Category | What It Looks For |
|----------|-------------------|
| **SSH Security** | Password auth enabled, root login permitted, fail2ban missing |
| **Firewall** | No active firewall (UFW, iptables, firewalld) |
| **Gateway Exposure** | Control gateway bound to 0.0.0.0, authentication disabled |
| **User Allowlists** | Missing Telegram/Discord/Slack user restrictions |
| **Browser Security** | Default browser profile (session hijacking vector) |
| **Password Managers** | 1Password/Bitwarden/LastPass CLI left authenticated |
| **Docker Security** | Privileged containers, docker socket mounts, root user, host filesystem mounts |
| **File Permissions** | World-readable .env files, SSH keys, AWS credentials |
| **Token Exposure** | API tokens in log files, shell history |
| **Process Security** | Bot running as root, tokens visible in process list |
| **Native Bot Audit** | DM/group policies, tool blast radius, browser control, plugin hygiene, sandbox config |

### STIG/CIS/NIST Compliance Checks (`--stig`)

| Category | Sub-checks | Compliance Source |
|----------|-----------|-------------------|
| **SSH Hardening** | Idle timeout, host key perms, ciphers, MACs, PermitUserEnvironment, Protocol 2, RSA key size | RHEL-09 STIG, CIS L1 |
| **Kernel Hardening** | ASLR, SYN cookies, IP forwarding, ICMP redirects (all+default), source routing (all+default), BPF, core dumps | RHEL-09 STIG, CIS L1/L2 |
| **Audit Logging** | auditd running, rules configured, critical rules (execve/passwd/shadow), log perms, retention, boot audit | NIST 800-53 AU |
| **Mandatory Access Control** | SELinux enforcing or AppArmor profiles loaded | DISA STIG, CIS L1 |
| **Account Controls** | Session timeout (value + readonly), account lockout, password complexity, empty passwords, root console login | DoDI 8520.03 |
| **Service Hardening** | Debug shell masked, Ctrl-Alt-Del disabled, core dumps disabled, service count review | RHEL-09 STIG |
| **Cryptographic Controls** | System crypto policy, FIPS mode, TLS minimum version (crypto-policies backend) | NIST 800-53 SC |
| **File Integrity** | AIDE/Tripwire installed, world-writable files in system dirs, SUID/SGID binary count | CIS L2, NIST SI-7 |
| **AI Supply Chain** | SBOM present, model checksums, plugin allowlist, rate limiting, TLS enforcement, foreign model origin (FY2026 NDAA) | NIST AI 100-1 |
| **Container Security** | Read-only rootfs, no-new-privileges, memory/CPU limits | DoD Container SRG |
| **macOS Security** | Application Firewall, FW logging, Gatekeeper, SIP | APPL-15 STIG |
| **Network Zero Trust** | Non-localhost listeners, encrypted DNS, network segmentation | DoD ZT Ref Arch v2.0 |

Full control mapping: [docs/STIG-MAPPING.md](docs/STIG-MAPPING.md)

## Usage

```bash
./molt-security-audit.sh              # Core security audit
./molt-security-audit.sh --stig       # + DoD STIG/CIS/NIST controls
./molt-security-audit.sh --fix        # Auto-remediate safe issues
./molt-security-audit.sh --json       # Machine-readable output
./molt-security-audit.sh --quiet      # Failures and warnings only
./molt-security-audit.sh --deep       # Include native moltbot/clawdbot audit
./molt-security-audit.sh --stig --json --fix  # Everything at once
./molt-security-audit.sh --help       # Full usage reference
```

## Sample Output

```
╔══════════════════════════════════════════════════════════════════╗
║         Moltbot/Clawdbot Security Audit v2.0.0                   ║
║         Defensive Security Scanner                               ║
╚══════════════════════════════════════════════════════════════════╝

STIG MODE: DISA STIG / CIS Benchmark / NIST 800-53 controls enabled

━━━ SSH Security (Hack #1: Brute Force Prevention) ━━━
  [PASS] SSH Password Auth: Password authentication is disabled
  [PASS] SSH Root Login: Root login is disabled
  [PASS] Fail2ban: Fail2ban is installed and running
  [PASS] SSH Idle Timeout: ClientAliveInterval set to 600s
  [PASS] SSH Ciphers: No weak ciphers in Ciphers directive

━━━ Kernel Hardening (DISA STIG / CIS L1) ━━━
  [PASS] Kernel: ASLR: kernel.randomize_va_space = 2
  [PASS] Kernel: TCP SYN Cookies: net.ipv4.tcp_syncookies = 1

━━━ AI Supply Chain Security (NIST AI 100-1 / FY2026 NDAA) ━━━
  [PASS] SBOM: Software Bill of Materials found
  [PASS] AI Gateway TLS: TLS appears configured for AI gateway

══════════════════════════════════════════════════════════════════
                        AUDIT SUMMARY
══════════════════════════════════════════════════════════════════

  Passed:   42
  Failed:   0
  Warnings: 3
  Skipped:  5

  Risk Score: 15/100 - Good

  ℹ RECOMMENDED: Review 3 warnings for best security
```

## JSON Output

```json
{
  "version": "2.0.0",
  "timestamp": "2026-01-28T15:00:00Z",
  "stig_mode": true,
  "summary": {
    "pass": 42,
    "fail": 0,
    "warn": 3,
    "skip": 5,
    "risk_score": 15
  },
  "results": [
    {"check": "SSH Password Auth", "status": "pass", "message": "Password authentication is disabled"},
    {"check": "Kernel: ASLR", "status": "pass", "message": "kernel.randomize_va_space = 2"},
    {"check": "Docker User", "status": "warn", "message": "Container 'myapp' running as root", "risk": 10}
  ]
}
```

## Risk Score

| Score | Rating | Action |
|-------|--------|--------|
| 0 | Excellent | Maintain current security |
| 1-24 | Good | Minor improvements possible |
| 25-49 | Moderate Risk | Address warnings soon |
| 50-74 | High Risk | Immediate attention needed |
| 75+ | Critical Risk | Stop and fix now |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All checks passed |
| `1` | One or more critical failures |
| `2` | Warnings only (no critical failures) |

## Architecture Overview

20 check functions execute in fixed order: 11 core (always) then 9 STIG (with `--stig`).

```
main() → parse args → banner
  → 11 core checks (SSH, firewall, gateway, allowlists, browser,
     password managers, Docker, file perms, tokens, processes, native audit)
  → [--stig] 9 compliance checks (kernel, audit logging, MAC, accounts,
     services, crypto, file integrity, AI supply chain, network zero trust)
  → generate_report() → exit code
```

**Platform detection:** Linux-only checks skip on macOS. macOS-specific checks (ALF, Gatekeeper, SIP) run only on Darwin. Several checks have separate Linux/macOS code paths.

**Risk scoring** follows DISA severity: CAT I = 20-25 points, CAT II = 10-15, CAT III = 5-8.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full inner workings reference.

## Requirements

- **Bash** 4.0 or higher
- **Linux** or **macOS**
- Root/sudo access recommended for full checks
- Zero external dependencies — works with coreutils alone

### Optional (better coverage)

- `fail2ban-client` — Brute force protection check
- `docker` — Container security checks
- `ufw` / `iptables` / `firewall-cmd` — Firewall detection
- `moltbot` / `clawdbot` — Native audit integration (`--deep` mode)

## Running Tests

269 tests (53 unit, 164 integration, 52 output) using [bats-core](https://github.com/bats-core/bats-core):

```bash
make init-submodules   # First time only
make test              # All 269 tests
make test-unit         # Unit tests
make test-integration  # Integration tests (core + STIG)
make test-output       # Output mode tests
make test-tap          # TAP format for CI
```

## CI/CD Integration

### GitHub Actions

```yaml
- name: Security Audit
  run: |
    ./molt-security-audit.sh --stig --json > audit-results.json
    if [ $? -eq 1 ]; then
      echo "::error::Security audit found critical issues"
      exit 1
    fi
```

### GitLab CI

```yaml
security_audit:
  script:
    - ./molt-security-audit.sh --stig --json
  allow_failure: false
```

## Documentation

- **[Architecture Reference](docs/ARCHITECTURE.md)** — Execution flow, function map, JSON schema, test architecture
- **[STIG/CIS/NIST Mapping](docs/STIG-MAPPING.md)** — Full compliance control mapping
- **[Security Vulnerabilities Guide](molt-security-vulnerabilities.md)** — Attack vectors and prevention measures
- **[Contributing](CONTRIBUTING.md)** — How to contribute (including STIG check contribution guide)
- **[Security Policy](SECURITY.md)** — How to report security issues

## Acknowledgments

- [@mrnacknack](https://x.com/mrnacknack) — Original research: *"10 ways to hack into a vibecoder's clawdbot"* that inspired this project
- [@theonejvo](https://x.com/theonejvo) — Clawdhub supply chain analysis and skill backdoor research

## License

MIT License — see [LICENSE](LICENSE).

## Disclaimer

This tool is for **defensive security purposes only**. It audits YOUR OWN installation to help you identify and fix vulnerabilities. It does NOT perform attacks or test external systems.

---

**Your AI assistant is the most privileged process on your machine. Audit it.**
