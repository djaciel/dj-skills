---
name: dj-task-report
description: Use when reporting a completed or blocked task to the human — after implementation and validation finish, when closing a work session that produced reviewable changes, or when a previous report was too long or vague to act on.
---

# Task Report

## Overview

A task report exists so the human can review the work in ~2 minutes: what changed, why it matters, how it was validated, and where to look first. Signal over ceremony — an 800-line narration is worse than no report.

## When to use

- A task reaches an end state (`done`, `done-with-drift`, `blocked`, `needs-replan`, ...) — this is the final step of the **dj-task** loop.
- Any implementation work (even outside a formal task packet) that the human will review before committing.

When NOT to use:

- Communication that leaves the machine — PR descriptions, tickets, team updates. Route those through **dj-brief**.
- Mid-task progress updates — a one-line note in conversation is enough.

## The rule

> Don't explain everything. Say what changed, why it matters, how it was validated, and what the human should review.

## What goes in the report

| Section | Content | Discipline |
|---------|---------|-----------|
| Outcome | Task ID + end state in one line | Name drift or blockers up front, never bury them |
| Changes | One line per file: what changed and why | Group mechanical files ("+ 6 snapshot updates"); detail only core files |
| Key decisions | Choices a reviewer would question — especially "reused X instead of creating Y because..." | Only decisions with alternatives; skip the obvious |
| Validation | Each command from the packet + its REAL result | Run it and paste the outcome. "Should pass" is not a result |
| Self-review | Reuse found? Duplication avoided? Edge cases added? | 2–4 bullets from the **dj-repo-patterns** and **dj-simplicity-lens** checks |
| Skipped steps | Loop steps skipped and why | One line each ("Skipped scout: packet lists all context"); drop when empty |
| Acceptance | Hard / soft check status + drift classification | Levels per **dj-acceptance-review**; if drift exists, point to the drift-log entry (**dj-drift-management**) |
| Out of scope | Discoveries reported, not acted on | Bugs, refactor candidates, missing utilities found along the way; drop when empty |
| Walkthrough | Optional deep-dive: goal, data flow, file-by-file functions | Off by default — see "The optional Walkthrough" below |
| Review order | Numbered reading order, core file first | This is the human's map — earn their 10–20 minutes |
| Suggested commit | One line via **dj-commit-message** | Suggest only; the human commits unless commit_policy says otherwise |

Language: the report itself follows the internal language in `.agent/language-policy.md`; the suggested commit message is always English.

Scaling: a trivial task gets a trivial report — outcome, changes, validation, commit. Drop sections that would say "nothing to report"; never drop Validation.

## The optional Walkthrough

Off by default — the base report stays readable in 2 minutes. Produce it when the user asks ("walk me through T-03"), or when `.agent/current.md` sets `Walkthrough: always` under Report style. Three parts, in the internal language, ordered so the reader never drowns:

1. **Goal** — the task's objective restated in one line.
2. **Data flow** — a compact `input → transform → output` map of the changed flow (apply **dj-data-flow-review**), one line per path.
3. **File by file, in review order** — for each core file, the functions added or changed, one line each, in plain words. Mechanical files stay grouped — never function by function.

Short lines, no prose paragraphs, no code dumps. The walkthrough explains the change; the diff remains the source of truth.

```md
Walkthrough — T-03

Goal: recover the funding flow when account linking fails after token creation.

Data flow:
- webhook `funding.failed` → `resolveRecovery()` → retry queue or abort + refund

File by file:
1. `src/funding/recover.ts`
   - `resolveRecovery()` — decides retry vs abort from the error code
   - `scheduleRetry()` — enqueues the retry with backoff (reuses `queue.push`)
2. `src/funding/types.ts`
   - `RecoveryState` — new union: `retrying | aborted | recovered`
```

## Common mistakes

- **Narrating the process chronologically** ("first I read, then I tried...") — report results, not the journey.
- **"All tests pass" with no command output** — validation without evidence is a claim, not a result.
- **Listing 20 mechanical files individually** — drowns the 3 files that matter. Group them.
- **Hiding drift in the middle of the report** — drift changes what the human reviews; it goes in the outcome line and Acceptance.
- **Pasting the full diff** — the human has `git diff`; the report's job is to guide it, not duplicate it.
- **Skipping the review order** — without it, the human reads files alphabetically and misses the story.

## Output format

```md
T-03 done.

Changes:
- `src/funding/recover.ts`: handle the two new recovery states.
- `src/funding/types.ts`: add `RecoveryState` union.
- `tests/funding.recover.test.ts`: happy path + timeout edge case.
- (+4 mechanical: snapshot updates from the type change)

Key decisions:
- Reused the existing `Result` helper instead of adding a new error type —
  same shape as `src/payments/retry.ts`.

Validation:
- `pnpm test funding`: pass (14 tests)
- `pnpm typecheck`: pass

Self-review:
- reused retry pattern from `src/payments/retry.ts`
- reuse scan found no duplicate helper
- added edge case: timeout during recovery

Skipped steps:
- Step 6 (stack review): personal-medium mode — per project.md

Acceptance:
- hard checks: pass
- soft checks: pass (naming partially matches — see review order #2)
- drift: none

Out of scope (not acted on):
- `src/funding/client.ts` has an unhandled rejection — candidate for /dj-fix

Review order:
1. `src/funding/recover.ts` — the actual behavior change
2. `src/funding/types.ts` — new union, check naming
3. `tests/funding.recover.test.ts` — edge case coverage

Suggested commit:
`fix(sdk): handle funding recovery states`
```

For a `blocked` or `needs-replan` end state, replace Acceptance with a short "Blocked by / Needs" section stating exactly what decision or fix unblocks it, and still include Validation for whatever was attempted.
