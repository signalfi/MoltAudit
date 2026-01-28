# Security Policy

## Purpose

moltaudit is a **defensive security tool** designed to help users identify vulnerabilities in their own installations. This document describes our security policy and how to report security issues.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

### In moltaudit Itself

If you discover a security vulnerability in the moltaudit tool itself:

1. **Do NOT** open a public issue
2. Email the maintainers directly (see repository for contact info)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will respond within 48 hours and work with you to understand and address the issue.

### In Systems moltaudit Checks

If you discover new attack vectors against Moltbot/Clawdbot installations that moltaudit should detect:

1. Open an issue with the "security-check" label
2. Describe the attack vector
3. Suggest detection logic
4. Reference any public research if available

## Security Best Practices

When using moltaudit:

1. **Run on your own systems only** - This tool is for auditing installations you own or have permission to test

2. **Review output carefully** - The tool may reveal sensitive information about your configuration

3. **Secure the output** - JSON output and logs may contain security-relevant information

4. **Keep updated** - Pull the latest version to get new security checks

## Responsible Disclosure

We believe in responsible disclosure. If we discover issues in related projects (bats-core, etc.), we will:

1. Report to the upstream project first
2. Allow reasonable time for a fix
3. Credit the original researchers

## Acknowledgments

This project is based on security research by:
- [@mrnacknack](https://x.com/mrnacknack) - Original "10 ways to hack" research
- [@theonejvo](https://x.com/theonejvo) - Clawdhub supply chain analysis

## Scope

### In Scope

- Vulnerabilities in the moltaudit script itself
- False negatives (security issues not detected)
- False positives (incorrect security warnings)
- New attack vectors to detect

### Out of Scope

- Vulnerabilities in third-party dependencies (report upstream)
- Social engineering attacks
- Physical security
- Issues in systems moltaudit checks (report to those projects)

## Contact

For security issues, contact the maintainers through:
- GitHub Security Advisories (preferred)
- Direct email to repository maintainers

Thank you for helping keep the community secure!
