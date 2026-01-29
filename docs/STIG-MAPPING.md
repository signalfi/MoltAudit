# STIG / CIS / NIST Control Mapping

This document maps each MoltAudit v2.0 check to its source compliance control.

## Legend

- **DISA CAT I** = Critical (risk 20-25)
- **DISA CAT II** = High (risk 10-15)
- **DISA CAT III** = Medium (risk 5-8)

## SSH Security (Extended)

| MoltAudit Check | DISA STIG ID | CIS ID | NIST 800-53 | CAT |
|----------------|-------------|--------|-------------|-----|
| SSH Password Auth | RHEL-09-255040 | CIS 5.2.6 | IA-5(1) | II |
| SSH Root Login | RHEL-09-255045 | CIS 5.2.10 | AC-6(2) | I |
| SSH Idle Timeout | RHEL-09-255035 | CIS 5.2.16 | AC-12 | II |
| SSH Alive Count | RHEL-06-000230 | CIS 5.2.16 | AC-12 | II |
| SSH Host Key Perms | RHEL-08-010480 | CIS 5.2.2 | AC-3 | II |
| SSH PermitUserEnv | RHEL-09-255060 | CIS 5.2.12 | CM-6 | II |
| SSH Ciphers | RHEL-09-255080 | CIS 5.2.13 | SC-13 | I |
| SSH MACs | RHEL-09-255085 | CIS 5.2.14 | SC-13 | I |
| SSH Protocol 2 | N/A (legacy) | CIS 5.2.4 | CM-6 | III |
| SSH RSA Key Size | RHEL-08-010480 | CIS 5.2.3 | SC-12 | II |

## Kernel Hardening

| MoltAudit Check | DISA STIG ID | CIS ID | NIST 800-53 | CAT |
|----------------|-------------|--------|-------------|-----|
| ASLR | RHEL-09-213010 | CIS 1.5.2 | SI-16 | I |
| TCP SYN Cookies | RHEL-09-253060 | CIS 3.2.8 | SC-5 | II |
| IP Forwarding | RHEL-09-253010 | CIS 3.1.1 | SC-7 | II |
| ICMP Redirect Send | RHEL-09-253040 | CIS 3.2.1 | SC-7 | II |
| ICMP Redirect Accept | RHEL-09-253030 | CIS 3.2.2 | SC-7 | II |
| Source Routing | RHEL-09-253020 | CIS 3.2.5 | SC-7 | II |
| ICMP Redirect Send (default) | RHEL-09-253040 | CIS 3.2.1 | SC-7 | II |
| ICMP Redirect Accept (default) | RHEL-09-253030 | CIS 3.2.2 | SC-7 | II |
| Source Routing (default) | RHEL-09-253020 | CIS 3.2.5 | SC-7 | II |
| Unprivileged BPF | RHEL-09-213020 | CIS 1.5.3 | CM-6 | II |
| Core Dumps (SUID) | RHEL-09-213030 | CIS 1.5.1 | CM-6 | II |

## Audit Logging

| MoltAudit Check | DISA STIG ID | CIS ID | NIST 800-53 | CAT |
|----------------|-------------|--------|-------------|-----|
| auditd Running | RHEL-09-653010 | CIS 4.1.1.1 | AU-3 | I |
| Audit Rules | RHEL-09-654010 | CIS 4.1.3 | AU-12 | II |
| Audit Critical Rules | RHEL-09-654010 | CIS 4.1.3 | AU-12 | II |
| Audit Log Perms | RHEL-09-653040 | CIS 4.1.4.1 | AU-9 | II |
| Audit Retention | RHEL-09-653050 | CIS 4.1.2.2 | AU-11 | III |
| Boot Audit | RHEL-09-653020 | CIS 4.1.1.3 | AU-14 | II |

## Mandatory Access Control

| MoltAudit Check | DISA STIG ID | CIS ID | NIST 800-53 | CAT |
|----------------|-------------|--------|-------------|-----|
| SELinux Enforcing | RHEL-09-431010 | CIS 1.6.1.1 | AC-3(3) | I |
| AppArmor Active | UBTU-24-431010 | CIS 1.6.1.1 | AC-3(3) | I |

## Account & Authentication Controls

| MoltAudit Check | DISA STIG ID | CIS ID | NIST 800-53 | CAT |
|----------------|-------------|--------|-------------|-----|
| Session Timeout | RHEL-09-412035 | CIS 5.5.3 | AC-12 | II |
| Session Timeout Readonly | RHEL-09-412035 | CIS 5.5.3 | AC-12 | III |
| Account Lockout | RHEL-09-411075 | CIS 5.3.2 | AC-7 | II |
| Password Complexity | RHEL-09-611040 | CIS 5.4.1 | IA-5(1) | II |
| Empty Passwords | RHEL-09-611010 | CIS 5.4.2 | IA-5(1) | I |
| Root Direct Login | RHEL-09-412010 | CIS 5.5.5 | AC-6(2) | II |

## Service Hardening

| MoltAudit Check | DISA STIG ID | CIS ID | NIST 800-53 | CAT |
|----------------|-------------|--------|-------------|-----|
| Debug Shell | RHEL-09-211020 | CIS 1.4.1 | CM-6 | III |
| Ctrl-Alt-Del | RHEL-09-211010 | CIS 1.4.2 | CM-6 | II |
| Core Dumps (systemd) | RHEL-09-213040 | CIS 1.5.1 | CM-6 | III |
| Service Count | N/A | CIS 2.2 | CM-7 | III |

## Cryptographic Controls

| MoltAudit Check | DISA STIG ID | CIS ID | NIST 800-53 | CAT |
|----------------|-------------|--------|-------------|-----|
| Crypto Policy | RHEL-09-672010 | CIS 1.10 | SC-13 | II |
| FIPS Mode | RHEL-09-672015 | N/A | SC-13 | III |
| TLS Version | RHEL-09-672020 | CIS 1.10 | SC-8 | II |

## File Integrity

| MoltAudit Check | DISA STIG ID | CIS ID | NIST 800-53 | CAT |
|----------------|-------------|--------|-------------|-----|
| FIM Tool | RHEL-09-651010 | CIS 1.3.1 | SI-7 | III |
| World-Writable | RHEL-09-232260 | CIS 6.1.10 | CM-6 | III |
| SUID/SGID | RHEL-09-232270 | CIS 6.1.11 | CM-6 | III |

## Container Security (Extended)

| MoltAudit Check | DISA STIG ID | CIS ID | NIST 800-53 | CAT |
|----------------|-------------|--------|-------------|-----|
| Read-Only Root FS | Container SRG V-235815 | Docker CIS 5.12 | CM-7 | II |
| no-new-privileges | Container SRG V-235830 | Docker CIS 5.25 | AC-6 | II |
| Memory Limit | Container SRG V-235820 | Docker CIS 5.10 | SC-6 | III |
| CPU Limit | Container SRG V-235821 | Docker CIS 5.11 | SC-6 | III |

## AI Supply Chain

| MoltAudit Check | Source | NIST 800-53 | CAT |
|----------------|--------|-------------|-----|
| SBOM | NIST SP 800-218A | SA-17 | III |
| Model Integrity | NIST AI 100-1 | SI-7 | III |
| Plugin Allowlist | DoD AI Tailoring Guide | CM-7 | III |
| API Rate Limit | NIST SP 800-53 COSAiS | SC-5 | III |
| AI Gateway TLS | NIST SP 800-53 SC-8 | SC-8 | II |
| Foreign Model Origin | FY2026 NDAA | SA-12 | III |

## macOS Controls

| MoltAudit Check | DISA STIG ID | CIS ID | NIST 800-53 | CAT |
|----------------|-------------|--------|-------------|-----|
| Application Firewall | APPL-15-005010 | CIS 2.2.1 | SC-7 | II |
| FW Logging | APPL-15-005020 | CIS 2.2.2 | AU-12 | III |
| Gatekeeper | APPL-15-002060 | CIS 2.6.1 | CM-14 | I |
| SIP | APPL-15-002070 | CIS 5.1.2 | SI-7 | I |

## Network Zero Trust

| MoltAudit Check | Source | NIST 800-53 | CAT |
|----------------|--------|-------------|-----|
| Exposed Services | DoD ZT Ref Arch v2.0 | SC-7 | II |
| Encrypted DNS | DoD ZT Implementation Primer | SC-8 | III |
| Network Segmentation | DoD ZT Ref Arch v2.0 | SC-7(5) | III |
