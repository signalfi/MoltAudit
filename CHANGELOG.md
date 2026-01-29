# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- **Gap 1:** Kernel hardening now checks `conf.default` variants for ICMP redirect and source routing (RHEL-09-253020/30/40)
- **Gap 2:** Audit rules sub-check verifies critical rules (execve, /etc/passwd, /etc/shadow) not just rule count (RHEL-09-654010)
- **Gap 3:** TMOUT validation checks value ≤ 900 and `readonly TMOUT`, not just presence (RHEL-09-412035)
- **Gap 4:** TLS version check uses crypto-policies backend file instead of unreliable localhost probe (RHEL-09-672020)
- **Gap 5:** SSH RSA host key size check warns if < 2048-bit (RHEL-08-010480)
- **Gap 6:** SSH Protocol 2 check warns if Protocol 1 is explicitly enabled (CIS 5.2.4)

### Tests

- 14 new integration tests for gap fixes (269 total, up from 255)

### Planned

- Configuration file support
- HTML report generation
- Slack/Discord notification integration

## [2.0.0] - 2026-01-28

### Added

- **`--stig` flag** for DoD-grade DISA STIG / CIS Benchmark / NIST 800-53 controls
- **8 new check functions** (53 new sub-checks total):
  - `check_kernel_hardening()` — 8 sysctl checks (ASLR, SYN cookies, IP forwarding, etc.)
  - `check_audit_logging()` — 5 auditd checks (daemon, rules, permissions, retention, boot)
  - `check_mandatory_access()` — SELinux/AppArmor enforcement
  - `check_account_controls()` — 5 account/auth checks (TMOUT, faillock, pwquality, empty passwords, root console)
  - `check_service_hardening()` — 4 systemd checks (debug-shell, ctrl-alt-del, core dumps, service count)
  - `check_crypto_controls()` — 3 crypto checks (crypto policy, FIPS, TLS)
  - `check_file_integrity()` — 3 integrity checks (AIDE/Tripwire, world-writable, SUID/SGID)
  - `check_ai_supply_chain()` — 6 AI-specific checks (SBOM, model integrity, plugin allowlist, rate limiting, TLS, foreign model origin)
  - `check_network_zero_trust()` — 3 network checks (exposed services, encrypted DNS, segmentation)
- **4 extended existing checks**:
  - SSH: 6 new STIG sub-checks (idle timeout, host key perms, PermitUserEnvironment, ciphers, MACs)
  - Firewall: macOS ALF, Gatekeeper, SIP checks (APPL-15 STIG)
  - Docker: 4 new sub-checks (read-only rootfs, no-new-privileges, memory/CPU limits)
- **STIG compliance mapping**: `docs/STIG-MAPPING.md` with full DISA STIG ID → CIS ID → NIST 800-53 mapping
- ~102 new integration tests (9 new test files + extended existing tests)
- New test fixtures: `sshd_config-stig-secure`, `sshd_config-stig-weak`

### Changed

- Version bump to 2.0.0
- JSON output now includes `stig_mode` field
- Banner displays STIG mode indicator when enabled
- Default behavior unchanged (backwards compatible — new checks require `--stig`)

### References

- DISA RHEL 9 STIG v2 (2025-05-14)
- DISA macOS 15 Sequoia STIG v1 (2025-05-05)
- NIST AI 100-1, NIST SP 800-53 COSAiS
- FY2026 NDAA AI/ML Security Framework
- DoD Zero Trust Reference Architecture v2.0

## [1.1.0] - 2026-01-28

### Added

- Native `moltbot security audit` integration (check #11)
- `--deep` flag for extended audit including native moltbot checks
- Portable timeout handling for cross-platform compatibility
- 12 new integration tests for native audit checks
- Claude Code CLI skill for running audits

### Changed

- Version bump to 1.1.0
- Test count increased from 161 to 173 (integration: 56 → 68)

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
