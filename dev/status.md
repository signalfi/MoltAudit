# MoltAudit v2.0.0 — Development Status & Audit Guide

> **Purpose:** This file documents all changes made in the v1.1.0 → v2.0.0 upgrade and provides structured validation instructions for an agentic SWE to audit the implementation against source compliance guidance (DISA STIGs, CIS Benchmarks, NIST 800-53).
>
> **Generated:** 2026-01-28
> **Author:** Automated implementation session
> **Status:** Implementation complete, all tests passing, ready for audit

---

## 1. Change Inventory

### 1.1 Files Modified

| File | Change Type | Key Changes |
|------|-------------|-------------|
| `molt-security-audit.sh` | Major extension | Version 1.1.0→2.0.0, `--stig` flag, 8 new check functions, 3 extended functions, 53 new sub-checks |
| `.gitignore` | Minor | Added `dev/` exclusion |
| `README.md` | Updated | STIG checks table, `--stig` usage examples, version refs, STIG-MAPPING link |
| `CHANGELOG.md` | Updated | v2.0.0 entry with full change list |
| `SECURITY.md` | Updated | Added 2.0.x to supported versions |
| `test/output/json-mode.bats` | Updated | Version assertion changed from `1.1.0` to `2.0.0` |

### 1.2 Files Created

| File | Purpose |
|------|---------|
| `docs/STIG-MAPPING.md` | Full DISA STIG ID / CIS ID / NIST 800-53 mapping for every check |
| `test/fixtures/sshd_config-stig-secure` | STIG-compliant SSH config fixture |
| `test/fixtures/sshd_config-stig-weak` | Weak SSH config fixture for negative tests |
| `test/integration/kernel-hardening.bats` | 12 tests for `check_kernel_hardening()` |
| `test/integration/audit-logging.bats` | 10 tests for `check_audit_logging()` |
| `test/integration/mandatory-access.bats` | 6 tests for `check_mandatory_access()` |
| `test/integration/account-controls.bats` | 10 tests for `check_account_controls()` |
| `test/integration/service-hardening.bats` | 8 tests for `check_service_hardening()` |
| `test/integration/crypto-controls.bats` | 8 tests for `check_crypto_controls()` |
| `test/integration/file-integrity.bats` | 8 tests for `check_file_integrity()` |
| `test/integration/ai-supply-chain.bats` | 10 tests for `check_ai_supply_chain()` |
| `test/integration/network-zero-trust.bats` | 6 tests for `check_network_zero_trust()` |

### 1.3 Test Count

| Category | v1.1.0 | v2.0.0 | v2.0.0+gaps | Delta |
|----------|--------|--------|------------|-------|
| Unit | 53 | 53 | 53 | +0 |
| Integration | 68 | 150 | 164 | +14 |
| Output | 52 | 52 | 52 | +0 |
| **Total** | **173** | **255** | **269** | **+14** |

---

## 2. Function-Level Change Map

All functions are in `molt-security-audit.sh`. Line numbers are approximate and should be verified by the auditor.

### 2.1 New Functions (STIG-only, gated by `$STIG_MODE`)

| Function | Lines | Sub-checks | DISA CAT Coverage |
|----------|-------|------------|-------------------|
| `check_kernel_hardening()` | 987–1025 | 11 sysctl checks (incl. conf.default variants) | CAT I (ASLR), CAT II (rest) |
| `check_audit_logging()` | 1027–1105 | 6 auditd checks (incl. critical rules) | CAT I (daemon), CAT II (rules, critical rules, perms, boot), CAT III (retention) |
| `check_mandatory_access()` | 1107–1141 | 2 (SELinux or AppArmor) | CAT I |
| `check_account_controls()` | 1143–1242 | 6 account/auth checks (incl. TMOUT value+readonly) | CAT I (empty passwords), CAT II (rest), CAT III (TMOUT readonly) |
| `check_service_hardening()` | 1244–1302 | 4 systemd checks | CAT II (debug-shell, ctrl-alt-del), CAT III (core dumps, svc count) |
| `check_crypto_controls()` | 1304–1357 | 3 crypto checks (TLS via crypto-policies backend) | CAT II (crypto policy, TLS), CAT III (FIPS) |
| `check_file_integrity()` | 1359–1396 | 3 integrity checks | CAT III |
| `check_ai_supply_chain()` | 1398–1498 | 6 AI-specific checks | CAT II (TLS), CAT III (SBOM, model, plugin, rate limit, foreign origin) |
| `check_network_zero_trust()` | 1500–1548 | 3 network checks | CAT II (exposed services), CAT III (DNS, segmentation) |

### 2.2 Extended Functions

| Function | Lines | New Sub-checks | Gate |
|----------|-------|---------------|------|
| `check_ssh_security()` | 204–366 | +8: idle timeout, alive count, host key perms, PermitUserEnvironment, Protocol 2, ciphers, MACs, RSA key size | `$STIG_MODE` block at ~239–351 |
| `check_firewall()` | 368–460 | +4: macOS ALF state, ALF logging, Gatekeeper, SIP | `$STIG_MODE && Darwin` block at ~407–452 |
| `check_docker_security()` | 656–743 | +4: read-only rootfs, no-new-privileges, memory limit, CPU limit | `$STIG_MODE` block inside container loop at ~699–737 |

### 2.3 Infrastructure Changes

| Change | Location | Detail |
|--------|----------|--------|
| `VERSION` bump | Line 28 | `1.1.0` → `2.0.0` |
| `STIG_MODE` variable | Line 50 | New global, default `false` |
| `--stig` arg parsing | Line ~1590 | New case in argument parser |
| `--stig` in help text | Lines ~78, ~91 | Added to help and header comment |
| STIG mode banner | Lines ~1610–1613 | Prints indicator when `--stig` active |
| STIG checks in `main()` | Lines ~1626–1636 | Conditional block calling all 9 new functions |
| JSON `stig_mode` field | Line ~1491 | Added to JSON report output |

---

## 3. Validation & Audit Instructions

### 3.1 Automated Validation

Run these commands to verify the implementation is functional:

```bash
# 1. All 255 tests pass
make test

# 2. ShellCheck passes (only info/style warnings expected)
shellcheck molt-security-audit.sh

# 3. Basic smoke test — default mode (should behave identically to v1.1.0)
./molt-security-audit.sh --json | jq '.stig_mode'
# Expected: false

# 4. STIG mode smoke test
./molt-security-audit.sh --stig --json | jq '.summary'

# 5. Verify --stig flag is required for new checks
diff <(./molt-security-audit.sh --json 2>/dev/null | jq -r '.results[].check' | sort) \
     <(./molt-security-audit.sh --stig --json 2>/dev/null | jq -r '.results[].check' | sort)
# Expected: STIG mode produces MORE checks than default mode

# 6. Verify version
./molt-security-audit.sh --json | jq -r '.version'
# Expected: 2.0.0

# 7. Verify help includes --stig
./molt-security-audit.sh --help | grep -c "stig"
# Expected: >= 2
```

### 3.2 Manual STIG Compliance Audit

For each check function, the auditor should verify that the implementation accurately reflects the referenced DISA STIG control. The source-of-truth mapping is in `docs/STIG-MAPPING.md`.

#### 3.2.1 Kernel Hardening — Verify Against RHEL-09 STIG

| Check | STIG ID | What to Verify |
|-------|---------|---------------|
| ASLR (`kernel.randomize_va_space`) | RHEL-09-213010 | Must check for value `2` (full randomization). Value `1` is partial and should fail. |
| SYN cookies | RHEL-09-253060 | Must check for value `1`. |
| IP forwarding | RHEL-09-253010 | Must check for value `0` (disabled). STIG says forwarding must be disabled unless system is a router. |
| ICMP redirect send | RHEL-09-253040 | Must check `net.ipv4.conf.all.send_redirects = 0`. |
| ICMP redirect accept | RHEL-09-253030 | Must check `net.ipv4.conf.all.accept_redirects = 0`. Also check: STIG requires `conf.default` as well — **current implementation only checks `conf.all`**. |
| Source routing | RHEL-09-253020 | Must check `net.ipv4.conf.all.accept_source_route = 0`. Same note: STIG also requires `conf.default`. |
| Unprivileged BPF | RHEL-09-213020 | Must check for value `1`. |
| Core dumps | RHEL-09-213030 | Must check `fs.suid_dumpable = 0`. |

**Resolved:** Implementation now checks both `conf.all` and `conf.default` variants for ICMP redirect and source routing settings.

#### 3.2.2 SSH Hardening — Verify Against RHEL-09 STIG + CIS L1

| Check | STIG ID | What to Verify |
|-------|---------|---------------|
| ClientAliveInterval | RHEL-09-255035 | Must be set and ≤ 900. STIG says "must not be greater than 900 seconds." |
| ClientAliveCountMax | RHEL-06-000230 | Must be `0`. This terminates the session after one missed keepalive. |
| Host key permissions | RHEL-08-010480 | Pub keys: 0644. Private keys: 0600. Implementation checks both. |
| PermitUserEnvironment | RHEL-09-255060 | Must be `no`. |
| Ciphers | RHEL-09-255080 | Must NOT contain CBC or arcfour. STIG lists approved ciphers: `aes256-ctr,aes192-ctr,aes128-ctr,aes256-gcm@openssh.com,aes128-gcm@openssh.com`. Current implementation greps for `cbc\|arcfour`. |
| MACs | RHEL-09-255085 | Must NOT contain `hmac-sha1` (without `-etm`) or `hmac-md5`. Current implementation greps for `hmac-sha1[^-]\|hmac-md5`. |

**Verify:** The regex `hmac-sha1[^-]` correctly allows `hmac-sha1-etm@openssh.com` while rejecting `hmac-sha1`. Test with fixture `sshd_config-stig-weak`.

#### 3.2.3 Audit Logging — Verify Against NIST 800-53 AU Family

| Check | STIG ID | What to Verify |
|-------|---------|---------------|
| auditd running | RHEL-09-653010 | `systemctl is-active auditd`. On macOS: `launchctl list \| grep auditd`. |
| Audit rules | RHEL-09-654010 | `auditctl -l` must return > 0 rules. Sub-check verifies critical rules (execve, /etc/passwd, /etc/shadow). |
| Log permissions | RHEL-09-653040 | `/var/log/audit/audit.log` must be 0600 or stricter. |
| Retention | RHEL-09-653050 | `max_log_file_action` in `/etc/audit/auditd.conf`. |
| Boot audit | RHEL-09-653020 | `audit=1` in `/proc/cmdline`. |

**Resolved:** Sub-check now verifies critical audit rules (execve, /etc/passwd, /etc/shadow) in addition to rule count.

#### 3.2.4 Mandatory Access Control — Verify Against STIG

| Check | STIG ID | What to Verify |
|-------|---------|---------------|
| SELinux | RHEL-09-431010 | `getenforce` must return `Enforcing`. `Permissive` is a warning, `Disabled` is a fail. |
| AppArmor | UBTU-24-431010 | `aa-status --profiled` must return > 0. |

**Verify:** Function correctly detects OS type and only runs the appropriate check. Has `return` after SELinux block to avoid checking AppArmor on SELinux systems.

#### 3.2.5 Account Controls — Verify Against DISA STIG + DoDI 8520.03

| Check | STIG ID | What to Verify |
|-------|---------|---------------|
| TMOUT | RHEL-09-412035 | Must be set in `/etc/profile` or `/etc/profile.d/*.sh`. Validates value ≤ 900 and `readonly TMOUT`. |
| Account lockout | RHEL-09-411075 | `pam_faillock` with `deny=` configured. |
| Password complexity | RHEL-09-611040 | `pwquality.conf` with `minlen`, `dcredit`, etc. |
| Empty passwords | RHEL-09-611010 | No accounts in `/etc/shadow` with empty password field. |
| Root console | RHEL-09-412010 | `/etc/securetty` should be empty or absent. |

**Resolved:** TMOUT now validates value ≤ 900 and checks for `readonly TMOUT`.

#### 3.2.6 Service Hardening

| Check | STIG ID | What to Verify |
|-------|---------|---------------|
| debug-shell | RHEL-09-211020 | `systemctl is-enabled debug-shell.service` should be `masked` or `disabled`. |
| ctrl-alt-del | RHEL-09-211010 | `systemctl is-enabled ctrl-alt-del.target` should be `masked`. |
| Core dumps | RHEL-09-213040 | `ProcessSizeMax=0` in `/etc/systemd/coredump.conf`. |
| Service count | CIS 2.2 | Warning if > 50 running services. |

#### 3.2.7 Cryptographic Controls

| Check | STIG ID | What to Verify |
|-------|---------|---------------|
| Crypto policy | RHEL-09-672010 | `update-crypto-policies --show` returns `DEFAULT`, `FUTURE`, or `FIPS`. `LEGACY` is a fail. |
| FIPS mode | RHEL-09-672015 | `/proc/sys/crypto/fips_enabled` = `1`. |
| TLS version | RHEL-09-672020 | Checks `MinProtocol` in `/etc/crypto-policies/back-ends/opensslcnf.config`. |

**Resolved:** TLS check now reads `MinProtocol` from crypto-policies backend file.

#### 3.2.8 File Integrity

| Check | STIG ID | What to Verify |
|-------|---------|---------------|
| FIM tool | RHEL-09-651010 | `aide`, `tripwire`, `ossec-control`, or `samhain` installed. |
| World-writable | RHEL-09-232260 | `find /usr /etc /var -perm -0002`. |
| SUID/SGID | RHEL-09-232270 | Count SUID/SGID in `/usr /bin /sbin`. Warns if > 30. |

#### 3.2.9 AI Supply Chain — Verify Against NIST AI 100-1 / FY2026 NDAA

These checks are novel and not yet standardized. Verify implementation against:
- **SBOM:** NIST SP 800-218A requires SBOM for software supply chain. Looks for `sbom.json`, `bom.xml`, `*.spdx` in bot config directories.
- **Model integrity:** Checks for `.sha256` or `.md5` sidecar files next to model files.
- **Plugin allowlist:** Greps config for `plugin.*allowlist` patterns.
- **Rate limiting:** Greps config for `rate.*limit` patterns.
- **TLS:** Flags `http://` in config, passes `https://`.
- **Foreign model origin:** Warns if `deepseek` or `highflyer` found in config (per FY2026 NDAA foreign model restrictions).

#### 3.2.10 Container Security Extensions — Verify Against DoD Container SRG

| Check | SRG ID | What to Verify |
|-------|--------|---------------|
| Read-only rootfs | V-235815 | `docker inspect --format '{{.HostConfig.ReadonlyRootfs}}'` = `true`. |
| no-new-privileges | V-235830 | `SecurityOpt` contains `no-new-privileges`. |
| Memory limit | V-235820 | `.HostConfig.Memory` ≠ `0`. |
| CPU limit | V-235821 | `.HostConfig.NanoCpus` ≠ `0` OR `.HostConfig.CpuShares` ≠ `0`. |

#### 3.2.11 macOS Controls — Verify Against APPL-15 STIG

| Check | STIG ID | What to Verify |
|-------|---------|---------------|
| ALF globalstate | APPL-15-005010 | `defaults read /Library/Preferences/com.apple.alf globalstate` returns `1` or `2`. |
| ALF logging | APPL-15-005020 | `loggingenabled` = `1`. |
| Gatekeeper | APPL-15-002060 | `spctl --status` contains "assessments enabled". |
| SIP | APPL-15-002070 | `csrutil status` contains "enabled". |

#### 3.2.12 Network Zero Trust — Verify Against DoD ZT Ref Arch v2.0

| Check | Source | What to Verify |
|-------|--------|---------------|
| Exposed services | DoD ZT Ref Arch | `ss -tlnp` output filtered for non-localhost LISTEN. Warns if > 5. |
| Encrypted DNS | DoD ZT Primer | `DNSOverTLS=yes` in `resolved.conf`. |
| Segmentation | DoD ZT Ref Arch | Count non-loopback interfaces via `ip -o link show`. |

---

## 4. Known Gaps & Improvement Opportunities

These items are NOT bugs — they are areas where the implementation takes a simplified approach compared to the full STIG requirement. The auditor should evaluate whether each gap warrants a follow-up fix.

> **Note:** Gaps 1-6 were resolved on 2026-01-28, adding 14 new integration tests (269 total, up from 255).

| # | Gap | STIG Ref | Severity | Recommendation |
|---|-----|----------|----------|----------------|
| 1 | ~~Kernel: only checks `conf.all`, not `conf.default` for ICMP/source-route~~ | RHEL-09-253020/30/40 | Medium | **RESOLVED** — Added `conf.default` variants to sysctl_list |
| 2 | ~~Audit rules: checks count only, not specific required rules~~ | RHEL-09-654010 | Medium | **RESOLVED** — Added sub-check for execve, /etc/passwd, /etc/shadow rules |
| 3 | ~~TMOUT: checks presence only, not value or `readonly`~~ | RHEL-09-412035 | Low | **RESOLVED** — Validates value ≤ 900 and readonly |
| 4 | ~~TLS version check: unreliable localhost probe~~ | RHEL-09-672020 | Low | **RESOLVED** — Checks crypto-policies backend MinProtocol |
| 5 | ~~SSH key size: not implemented~~ | RHEL-09 STIG | Low | **RESOLVED** — Checks RSA host key ≥ 2048-bit |
| 6 | ~~SSH Protocol 2: not explicitly checked~~ | CIS L1 | Low | **RESOLVED** — Warns if Protocol 1 explicitly enabled |
| 7 | Container image signing: not implemented | Container SRG | Medium | Add `docker trust inspect` check |
| 8 | AIDE database freshness: not checked | CIS L2 | Low | Check AIDE database mtime |
| 9 | Password aging: not checked (maxdays, mindays) | RHEL-09 STIG | Low | Add `/etc/login.defs` PASS_MAX_DAYS check |
| 10 | IPv6 sysctl equivalents: not checked | RHEL-09 STIG | Low | Add `net.ipv6.conf.all.*` variants |

---

## 5. Architecture Notes for Auditor

### 5.1 Control Flow

```
main()
  → parse args (--fix, --json, --quiet, --deep, --stig)
  → print_banner() (shows STIG indicator if enabled)
  → 11 core checks (always run)
  → if STIG_MODE:
      → 9 additional check functions
  → generate_report()
  → exit code (0=pass, 1=fail, 2=warn-only)
```

### 5.2 STIG Check Gating

All new STIG checks are gated in two ways:
1. **New functions** (`check_kernel_hardening`, etc.) are only called from `main()` inside `if [[ "$STIG_MODE" == true ]]`
2. **Extensions to existing functions** (`check_ssh_security`, `check_firewall`, `check_docker_security`) use inline `if [[ "$STIG_MODE" == true ]]` blocks

This ensures **full backwards compatibility** — running without `--stig` produces identical behavior to v1.1.0.

### 5.3 Platform Detection

- Linux-only checks: `check_kernel_hardening`, `check_service_hardening`, `check_crypto_controls` — all skip with `log_skip` on Darwin
- macOS-only checks: ALF/Gatekeeper/SIP in `check_firewall` — gated by `[[ "$(uname)" == "Darwin" ]]`
- Cross-platform: `check_audit_logging` has separate Linux (auditd) and macOS (launchctl) paths
- `check_account_controls`, `check_file_integrity` have graceful fallbacks for missing files

### 5.4 Risk Score Mapping

New checks follow DISA severity categories:
- **CAT I (Critical):** risk 20-25 — ASLR off, SELinux disabled, auditd missing, empty passwords
- **CAT II (High):** risk 10-15 — Weak ciphers, no session timeout, no account lockout, exposed services
- **CAT III (Medium):** risk 5-8 — Missing SBOM, no FIM tool, debug shell, core dumps

### 5.5 Test Architecture

All new tests follow the existing pattern in `test/test_helper/common-setup.bash`:
- `setup()` calls `source_moltaudit_functions`, `reset_counters`, `setup_test_home`
- Sets `STIG_MODE=true` for STIG tests
- Uses `create_mock` / `create_smart_mock` / `activate_mocks` for external command mocking
- Tests validate both positive (secure) and negative (insecure) cases

---

## 6. File Quick Reference

For the auditing agent, here are the exact paths to read:

```
# Main implementation
molt-security-audit.sh

# Compliance mapping (verify checks match listed STIG IDs)
docs/STIG-MAPPING.md

# Test files for each new function
test/integration/kernel-hardening.bats
test/integration/audit-logging.bats
test/integration/mandatory-access.bats
test/integration/account-controls.bats
test/integration/service-hardening.bats
test/integration/crypto-controls.bats
test/integration/file-integrity.bats
test/integration/ai-supply-chain.bats
test/integration/network-zero-trust.bats

# Fixtures
test/fixtures/sshd_config-stig-secure
test/fixtures/sshd_config-stig-weak

# Updated docs
README.md
CHANGELOG.md
SECURITY.md
```

---

## 7. Verification Commands

```bash
# Full test suite (expect 269 pass, 0 fail)
make test

# Test count breakdown
make count

# ShellCheck (expect 0 errors, only info/style)
shellcheck molt-security-audit.sh

# Smoke: default mode unchanged
./molt-security-audit.sh --json 2>/dev/null | jq '.stig_mode'

# Smoke: STIG mode runs additional checks
./molt-security-audit.sh --stig --json 2>/dev/null | jq '.summary'

# Verify no stale v1.1.0 references in user-facing files
grep -rn "v1\.1\.0\|1\.1\.0" README.md CHANGELOG.md molt-security-audit.sh | grep -v "^\#\|CHANGELOG.*\[1\.1\.0\]"
```
