---
name: Feature Request
about: Suggest a new security check or feature
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Problem Statement

A clear description of the problem or security gap this feature would address.

## Proposed Solution

Describe the feature or security check you'd like to see added.

## Detection Logic

If proposing a new security check, describe how it should detect the issue:

```bash
# Pseudo-code or example logic
if [[ some_condition ]]; then
    log_fail "Check Name" "Issue detected" risk_score
fi
```

## Prevention/Remediation

What fix should be suggested when the issue is detected?

## References

- Link to relevant security research
- CVE numbers if applicable
- Related issues or PRs

## Additional Context

Any other context, screenshots, or examples.
