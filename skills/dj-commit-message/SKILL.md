---
name: dj-commit-message
description: "Use when a commit message should be suggested for staged or completed changes — at the end of a task, when dj-brief routes a commit request, or whenever the user asks how to commit what was just built."
---

# Commit Message — Suggest, Match the Repo, Never Commit

## Overview

The repo's history is the style guide: suggest a message that fits it, and stop there. Committing is the human's act unless the project's commit policy explicitly says otherwise.

## When to use

- A task or fix is done and the change needs a commit suggestion (called from /dj-task, /dj-fix, or /dj-brief).
- The user asks "what should the commit message be?"

**Do NOT use when:** the change is not finished or not validated — a commit message for unverified work invites committing unverified work.

## Process

1. **Read the repo's convention first:** `git log --oneline -n 20`. Match what is actually there: conventional commits, plain sentences, ticket prefixes (`ABC-123: ...`), emoji or none.
2. **Look at the actual change:** `git diff --stat` (or the task report). The message describes what is in *this* commit, not the whole feature.
3. **Draft in the detected convention.** When history shows no clear pattern, default to `type(scope): message`.
4. **Present as a suggestion** using the output format below.

## Format defaults

- Subject in the imperative mood ("add", not "added" or "adds"); aim under ~72 characters.
- Default types: `feat` `fix` `refactor` `test` `docs` `chore` `perf` `build` `ci`.
- Scope = the module or area touched, matching how the repo already scopes.
- Add a body only when the "why" is not obvious from subject + diff — the body explains why, not what.
- **No co-author lines, no tool attribution, ever.** No emoji unless the repo history uses them.
- English, always — commits are external artifacts under the language policy.

## Commit policy

Honor `commit_policy` from `.agent/project.md`:

| Policy | Behavior |
|---|---|
| `human-only` (default) | Suggest only. Never run `git commit`. |
| `allowed-if-explicit` | Commit only when the user's current instruction explicitly says to. |
| `autonomous` | May commit after the task's validation passes (e.g. `/dj-task T-01..T-04 --autonomous`). Still: no push, no automatic PR, no co-author. |

If `.agent/project.md` does not exist, behave as `human-only`.

## One commit, one change

If the diff mixes unrelated changes, suggest a split with a message per commit rather than one vague umbrella message. Judgment question: **"Could someone revert this commit without collateral damage?"**

## Common mistakes

- Committing because "it's obviously done" — the policy decides, not confidence.
- Imposing conventional commits on a repo whose history writes plain sentences (or vice versa).
- Subject describes the task ("complete T-03") instead of the change.
- Writing the message from the plan instead of the actual diff.
- Adding `Co-Authored-By` or generated-with footers.

## Output format

```text
Suggested commit:
`feat(auth): add session refresh on token expiry`

Convention: matches repo history (conventional commits, scope by module).
Body: not needed — the diff is self-explanatory.
```

If a split is warranted, list the suggested commits in order, one line each, with which files go where.
