# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-28

### Added

- Initial release of moltaudit security audit tool
- **Security Checks**:
  - SSH security (password auth, root login, fail2ban)
  - Firewall detection (UFW, iptables, firewalld)
  - Gateway exposure (binding address, authentication)
  - User allowlists (Telegram, Discord, Slack)
  - Browser profile security (session isolation)
  - Password manager CLI detection (1Password, Bitwarden, LastPass)
  - Docker security (privileged mode, socket mounts, root user)
  - File permissions (.env, SSH keys, AWS credentials)
  - Token exposure (logs, shell history)
  - Process security (root processes, exposed tokens)
- **Output Modes**:
  - Standard colored terminal output
  - JSON output for CI/CD integration (`--json`)
  - Quiet mode for minimal output (`--quiet`)
- **Fix Mode**: Auto-fix safe issues with `--fix`
- **Risk Scoring**: 0-100 scale with severity ratings
- **Comprehensive Test Suite**: 161 tests using bats-core
  - 53 unit tests
  - 56 integration tests
  - 52 output tests
- Documentation:
  - Detailed vulnerability guide
  - Contributing guidelines
  - Security policy

### Security

- Based on [@mrnacknack](https://x.com/mrnacknack)'s security research
- Defensive tool only - audits YOUR OWN systems

## [Unreleased]

### Planned

- Additional security checks for new attack vectors
- Configuration file support
- HTML report generation
- Slack/Discord notification integration
