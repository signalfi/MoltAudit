---
name: moltaudit
description: |
  Security audit tool for Moltbot/Clawdbot AI assistant installations with DoD STIG/CIS/NIST compliance support. Use this skill when the user asks to: (1) Run a security audit on their VPS or server, (2) Check for vulnerabilities in their AI assistant setup, (3) Scan for exposed credentials, tokens, or insecure configurations, (4) Fix common security issues like SSH hardening, firewall setup, or file permissions, (5) Assess risk of their self-hosted AI setup, (6) Run STIG/CIS/NIST compliance checks, or mentions "moltaudit", "molt-security-audit", "clawdbot security", or "moltbot security".
---

# MoltAudit Security Scanner

Defensive security audit tool for Moltbot/Clawdbot installations based on [@mrnacknack's "10 ways to hack into a vibecoder's clawdbot"](https://x.com/mrnacknack/status/2016134416897360212).

## Quick Reference

```bash
# Full audit
./molt-security-audit.sh

# Auto-fix safe issues
./molt-security-audit.sh --fix

# JSON output for CI/CD
./molt-security-audit.sh --json

# Quiet mode (failures only)
./molt-security-audit.sh --quiet

# Deep mode (includes live Gateway probe via native moltbot audit)
./molt-security-audit.sh --deep

# STIG mode: all DoD STIG/CIS/NIST hardening controls
./molt-security-audit.sh --stig

# STIG compliance report for CI/CD
./molt-security-audit.sh --stig --json

# STIG with auto-fix suggestions
./molt-security-audit.sh --stig --fix
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks passed |
| 1 | Critical failures detected |
| 2 | Warnings only |

## Security Checks Performed

### Core Checks (always run)

1. **SSH Security** - Password auth, root login, fail2ban
2. **Firewall** - UFW/iptables/firewalld status
3. **Gateway Exposure** - Clawdbot control gateway binding
4. **User Allowlist** - Discord/Telegram/Slack ID restrictions
5. **Browser Profile** - Isolated vs shared Chrome profile
6. **Password Manager** - 1Password/Bitwarden/LastPass CLI session status
7. **Docker Security** - Privileged mode, root user, host mounts, socket mounts
8. **File Permissions** - .env, SSH keys, AWS credentials
9. **Exposed Tokens** - API keys in configs/logs/history
10. **Running Processes** - Root processes, exposed tokens in process list
11. **Moltbot Native Audit** - DM/group policies, tool blast radius, browser control, plugins, model hygiene, sandbox config (requires `moltbot` or `clawdbot` CLI)

### STIG Checks (`--stig` flag)

12. **SSH Hardening** - Idle timeout, host key perms, ciphers, MACs, PermitUserEnvironment, Protocol 2, RSA key size
13. **Kernel Hardening** - ASLR, SYN cookies, IP forwarding, ICMP redirects (all+default), source routing (all+default), BPF, core dumps
14. **Audit Logging** - auditd running, rules, critical rules (execve/passwd/shadow), log perms, retention, boot audit
15. **Mandatory Access Control** - SELinux enforcing, AppArmor profiles
16. **Account Controls** - Session timeout (value + readonly), account lockout, password complexity, empty passwords, root login
17. **Service Hardening** - Debug shell, Ctrl-Alt-Del, core dumps, service count
18. **Cryptographic Controls** - Crypto policy, FIPS mode, TLS min version (crypto-policies backend)
19. **File Integrity** - AIDE/Tripwire/OSSEC/Samhain, world-writable files, SUID/SGID binaries
20. **AI Supply Chain** - SBOM, model integrity, plugin allowlist, rate limiting, TLS, foreign model origin
21. **Container Security** (extended) - Read-only rootfs, no-new-privileges, memory/CPU limits
22. **macOS Security** - Application Firewall, FW logging, Gatekeeper, SIP
23. **Network Zero Trust** - Exposed services, encrypted DNS, network segmentation

## Common Workflows

### Initial Server Hardening

```bash
# Run audit with auto-fix
./molt-security-audit.sh --fix

# Review remaining manual fixes in output
```

### STIG Compliance Audit

```bash
# Full DISA STIG / CIS / NIST compliance check
./molt-security-audit.sh --stig

# JSON compliance report for CI/CD
./molt-security-audit.sh --stig --json > stig-report.json

# STIG with auto-fix suggestions
./molt-security-audit.sh --stig --fix
```

### CI/CD Integration

```bash
# Add to pipeline
./molt-security-audit.sh --json > security-report.json
# Fail build on exit code 1
```

### Risk Assessment

Run audit and check the risk score (0-100):
- 0-24: Good
- 25-49: Moderate Risk
- 50-74: High Risk
- 75+: Critical Risk

## Manual Fix Commands

When `--fix` can't auto-remediate, use these:

```bash
# SSH hardening
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Enable firewall
sudo ufw enable
sudo ufw default deny incoming
sudo ufw allow ssh

# Sign out password manager
op signout --all

# Fix file permissions
chmod 600 ~/.env ~/.aws/credentials ~/.ssh/id_*
```

## Installation

```bash
# Clone repository
git clone https://github.com/signalfi/MoltAudit.git
cd MoltAudit

# Make executable
chmod +x molt-security-audit.sh

# Run
./molt-security-audit.sh
```
