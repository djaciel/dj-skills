---
name: dj-repo-patterns
description: Use when implementing anything in an existing codebase (new functions, types, components, tests, or fixtures), especially in an unfamiliar area of the repo, or when a known "best practice" conflicts with how the repo already does things.
---

# Repo Patterns

## Overview

An existing codebase has already voted on how things are done. Find the precedent before creating anything: reuse beats extending, extending beats creating, and a new pattern requires justification in the report.

## When to use

- Before writing any new function, type, hook, component, util, fixture, or test helper in an existing repo.
- When deciding where new code lives and what it is called.
- When what you would normally write conflicts with what the repo actually does.

**When NOT to use:**

- Greenfield code with no precedent: there is nothing to imitate yet; apply the **dj-simplicity-lens** skill alone.

## The reuse scan

Before adding new code, spend a few minutes confirming the repo does not already have it. Check for:

- [ ] similar utility functions
- [ ] similar hooks or components
- [ ] similar types / interfaces
- [ ] similar fixtures and test helpers
- [ ] similar API clients or data-access code
- [ ] similar validation logic

Cheap ways to search:

1. Grep for the domain nouns and verbs involved (`invoice`, `retry`, `formatDate`).
2. Glob the folder of the nearest similar feature and read its structure.
3. Read ONE exemplar file end to end: the closest existing feature to what you are building.

For unfamiliar areas, delegate this exploration to the **dj-scout** subagent; if it is not available, run the searches inline in the main session.

Then decide, in order of preference: **reuse** (call the existing code as-is) → **extend** (small addition to the existing code) → **create new** (last resort, justify it).

The scan is cheap. Skip it only for code so trivial that duplication is impossible, and say so in the report.

## Follow local conventions

Match the neighbors, not your habits:

| Dimension | Imitate |
|---|---|
| Naming | casing, prefixes/suffixes, pluralization used by sibling files |
| Error handling | Result types vs exceptions vs error codes: whatever the module already uses |
| Module layout | where this kind of file lives, how it is split and exported |
| Tests | framework, fixture style, naming, and location of the nearest similar test |
| Data access / IO | existing clients, repositories, wrappers, never a parallel hand-rolled path |

## When the repo conflicts with "best practice"

Prefer the repo. Consistency across the codebase is usually worth more than a marginally better pattern applied in one file. Deviate only with a strong reason (a real bug or security risk, or a pattern the repo is explicitly migrating away from), and when you deviate, flag it in your report. Never deviate silently.

If the repo itself is inconsistent (two competing styles), follow the dominant or most recent one and note the inconsistency instead of adding a third.

## New pattern requires justification

Creating a new helper, type, layout, or convention is sometimes right. When it is, the task report must say what was checked and why the existing code did not fit. An unjustified new pattern is a review finding, not a preference.

## Common mistakes

- Writing the helper first and "checking for duplicates" after: the scan comes before the code.
- Trusting memory of the repo instead of searching it.
- Locally "improving" naming or error handling, leaving one more style for the next reader to decode.
- Blind-copying an exemplar together with its bugs: read what you imitate.
- Refactoring surrounding code to match your new pattern mid-task: that is scope creep; report it instead.
- Checking only whether the code already exists, never whether it belongs where you are putting it. A new function in the wrong layer passes the reuse scan cleanly.
- Copying a neighbor's happy path and never reading its unhappy one.
- Widening what a function does and leaving its name, its documentation comment, and its log messages describing only the old half.

## Output format

Record the scan compactly in the task report, one entry per non-trivial new symbol:

```markdown
### Reuse scan
- Checked: <path>, <symbol>: <how similar / why it does or does not fit>
- Decision: reuse | extend | create new
- Why: <one or two lines; for "create new", why nothing existing fit>
```
