---
name: dj-test-quality
description: Use when writing tests for a change, auditing whether existing tests add value, or deciding whether a test is worth adding at all, typically during task execution, PR review, or bug fixing.
---

# Test Quality

## Overview

Tests exist to validate behavior, bugs, real edge cases, and important contracts, not to satisfy a methodology. A test that locks in implementation details or duplicates existing coverage is a cost, not an asset.

## When to use

- Writing tests for a task, fix, or new feature.
- Auditing the tests in a diff (yours or someone else's).
- Deciding whether a change needs tests at all.

**When NOT to use:** don't run a full audit on a docs-only or config-only change. State "no test needed" and move on.

## Core rules

| Rule | Meaning |
|------|---------|
| Behavior over implementation | Assert what the code promises its callers, not how it works internally. Renaming a private helper should not break tests. |
| Edge cases from the actual contract | Derive edge cases from what the change really handles (empty input, expired token, API error response), not speculative races or impossible states. |
| Happy path + failure modes | Every meaningful behavior needs its success case and its realistic failure cases. |
| Reuse fixtures | Search for existing fixtures, factories, and test helpers before writing new ones. Duplicated fixtures rot fast. |
| Small and focused | One test = one behavior. A test whose name needs a paragraph is probably several tests. |
| Never bend tests to a bad implementation | If the implementation makes a correct test fail, fix the implementation. Rewriting the assertion to match wrong behavior hides a bug. |

## When a test is NOT worth adding

- Config-only or mechanical changes with no behavior of their own.
- Restating something the type system already enforces.
- Re-testing a framework or library (trust the router to route).
- A duplicate of an existing test through a slightly different path.
- Coverage-driven tests that assert nothing a caller depends on.

Say so explicitly: "No additional test needed for config-only change" is a valid, useful audit result.

## What to look for when auditing

- Is the happy path covered?
- Are realistic edge cases covered?
- Do tests validate behavior, or internal implementation details?
- Are there repeated fixtures that should be shared?
- Are any tests oversized, doing too much in one case?
- Are tests missing for the change's actual contract or for a bug it fixes?

Edge-case review is cumulative: when auditing task T-N, judge coverage against the contract built up from T-01 through T-N, not only the newest diff. Earlier tasks may have left gaps the latest change now exposes.

Within /dj-task and /dj-review, delegate the audit to the **dj-test-auditor** subagent. If the dj-test-auditor subagent is not available, run the audit inline in the main session using this skill.

## Common mistakes

- Adding tests to "comply with TDD" rather than to validate real behavior, a bug, a real edge case, or an important contract.
- Inventing edge cases the code cannot reach in order to look thorough.
- Mocking so heavily that the test validates the mocks, not the code.
- Deleting or weakening a failing test instead of investigating why it fails.

## Output format

Keep audit output short: a three-line audit beats a page of ceremony:

```text
Test audit:
- Existing tests cover happy path.
- Missing edge case: recovery API returns expired token.
- No additional test needed for config-only change.
```

For a full audit (e.g. closing a task in production-work mode), use this shape:

```markdown
# Test Audit

## Coverage judgment
good | partial | weak | not needed

## Existing useful tests
- ...

## Missing realistic edge cases
- ...

## Tests not worth adding
- ...

## Recommendation
add | update | keep | no test needed
```
