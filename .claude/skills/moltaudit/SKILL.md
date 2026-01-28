---
name: moltaudit
description: |
  Security audit tool for Moltbot/Clawdbot AI assistant installations. Use this skill when the user asks to: (1) Run a security audit on their VPS or server, (2) Check for vulnerabilities in their AI assistant setup, (3) Scan for exposed credentials, tokens, or insecure configurations, (4) Fix common security issues like SSH hardening, firewall setup, or file permissions, (5) Assess risk of their self-hosted AI setup, or mentions "moltaudit", "molt-security-audit", "clawdbot security", or "moltbot security".
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
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks passed |
| 1 | Critical failures detected |
| 2 | Warnings only |

## Security Checks Performed

1. **SSH Security** - Password auth, root login, fail2ban
2. **Firewall** - UFW/iptables/firewalld status
3. **Gateway Exposure** - Clawdbot control gateway binding
4. **User Allowlist** - Discord/Telegram/Slack ID restrictions
5. **Browser Profile** - Isolated vs shared Chrome profile
6. **Password Manager** - 1Password CLI session status
7. **Docker Security** - Privileged mode, root user, host mounts
8. **File Permissions** - .env, SSH keys, AWS credentials
9. **Exposed Tokens** - API keys in configs/logs
10. **Running Processes** - Suspicious or risky processes

## Common Workflows

### Initial Server Hardening

```bash
# Run audit with auto-fix
./molt-security-audit.sh --fix

# Review remaining manual fixes in output
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
