---
name: dj-task-report
description: Use when reporting a completed or blocked task to the human — after implementation and validation finish, when closing a work session that produced reviewable changes, or when a previous report was too long or vague to act on.
---

# Task Report

## Overview

A task report exists so the human can decide and approve. Its first screen carries what needs the human and what can break; the evidence and the depth sit below it. Signal over ceremony.

The report is for the human only: nothing in it is posted, sent or pasted into a PR by a skill.

## When to use

- A task reaches an end state (`done`, `done-with-drift`, `blocked`, `needs-replan`, ...) — this is the final step of the **dj-task** loop.
- Any implementation work (even outside a formal task packet) that the human will review before committing.

When NOT to use:

- Communication that leaves the machine — PR descriptions, tickets, team updates. Route those through **dj-brief**.
- Mid-task progress updates — a one-line note in conversation is enough.

## The rule

> Don't explain everything. Say what changed, why it matters, how it was validated, and what the human should review.

First what needs you, then what was done.

## Persistence

The same report is delivered twice: shown in the conversation for the human, and saved to `.dj-agents/repos/<repo>/features/<feature>/reports/T-XX.md` (work outside a feature: `.dj-agents/repos/<repo>/reports/<date>-<slug>.md`). The saved copy is what lets a fresh session — or **dj-brief** weeks later — reconstruct what happened without the original conversation. A chat-only report is a lost report.

## What goes in the report

First screen, always present, in this order. The five labels are fixed strings; other skills read them from the saved report.

| Section | Content | Discipline |
|---------|---------|-----------|
| Outcome | Task ID and end state in one line | Name drift and blockers here, never below |
| I need from you | Every pending decision, one line each: what to decide, the options, and what stays unapplied until the answer | Sources: step 8 items sent to the human, `Fix: human` items, Questions and "Couldn't verify" items without a recorded answer, candidates that got no recorded outcome, the packet's open question at the top. Ordered by consequence, no count cap. "nothing" when none |
| Not verified | Claims without pasted output, checks run only by proxy or skipped, exploratory checks not settled, reviewer "Couldn't verify" items | "nothing" only when every hard check has real output in Validation. The one-line summary of Validation, never a replacement for it |
| Business rules changed | What must or must never happen that the diff changed, in the terms of the flow or the glossary, `path:line` each | A changed error code, status, limit, default or condition that callers observe counts. "none" when none |
| Deviations | From the packet: scope, Placement `deviated`, acceptance changed, drift with the drift-log pointer. What did not work: an approach tried and abandoned, and why | So a reopened task does not try it again. Deviations names the fact; Acceptance classifies it. "none" when none |

Below the first screen, in this order:

| Section | Content | Discipline |
|---------|---------|-----------|
| Changes | One line per file: what changed and why | Group mechanical files ("+ 6 snapshot updates"); detail only core files |
| Validation | Each command from the packet + its REAL result | Run it and paste the outcome. "Should pass" is not a result |
| Review filter | The intent comparison line; candidates applied, discarded (each with its reason), sent to the human; follow-ups written; rounds used | One line per candidate; a discard without its reason is not a discard |
| Self-review | Reuse found? Duplication avoided? Edge cases added? Choices a reviewer would question, such as "reused X instead of creating Y because..." | A few bullets from the **dj-repo-patterns** and **dj-simplicity-lens** checks; only choices that had alternatives |
| Skipped steps | Loop steps skipped and why | One line each ("Skipped scout: packet lists all context") |
| Acceptance | Hard / soft check status + drift classification | Levels per **dj-acceptance-review**; if drift exists, point to the drift-log entry (**dj-drift-management**) |
| Out of scope | Discoveries reported, not acted on | Bugs, refactor candidates, missing utilities found along the way |
| Staging | When the changes are not committed: the `staging-table` rows plus a Theme column, one theme per group of hunks the human would commit together | Rows and numbers come from the script, never from reading the diff. The themes let the human run `git add -p` theme by theme. "script missing: part skipped" when it cannot run |
| Review order | Numbered reading order, core file first | This is the human's map to the diff |
| Suggested commit | One line via **dj-commit-message** | Suggest only; the human commits unless commit_policy says otherwise |
| Lengths | `Lengths: report <n> lines, guide section <m> lines`, from `line-count`, as the last line | Information, never a target: nothing is cut or padded to change it. "script missing: part skipped" when it cannot run |
| Walkthrough | Optional deep-dive: goal, data flow, file-by-file functions | Off by default, see "The optional Walkthrough" below |

Names: use the names that exist in the code, the repository and the glossary; never an invented term; never a person's name.

Language: the report itself follows the internal language in `.dj-agents/repos/<repo>/language-policy.md`; the suggested commit message is always English.

Scaling: the first screen is never dropped; its parts say "nothing" or "none", because an absent part reads as "all clear". Below it, drop the sections that would say "nothing to report"; never drop Validation. A trivial task gets the first screen, Changes, Validation, Suggested commit and Lengths.

## The optional Walkthrough

Off by default: the base report stays at its first screen and the evidence below it. Produce it when the user asks ("walk me through T-03"), or when the Report style section of `.dj-agents/repos/<repo>/project.md` sets `Walkthrough: always`. Three parts, in the internal language, ordered so the reader never drowns:

1. **Goal** — the task's objective restated in one line.
2. **Data flow** — a compact `input → transform → output` map of the changed flow (apply **dj-data-flow-review**), one line per path.
3. **File by file, in review order** — for each core file, the functions added or changed, one line each, in plain words. Mechanical files stay grouped — never function by function.

Short lines, no prose paragraphs, no code dumps. The walkthrough explains the change; the diff remains the source of truth.

```md
Walkthrough — T-03

Goal: recover the funding flow when account linking fails after token creation.

Data flow:
- webhook `funding.failed` → `resolveRecovery()` → retry queue or retry queue or abort

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
- **Hiding drift in the middle of the report**: drift changes what the human reviews; it goes in the outcome line, Deviations and Acceptance.
- **A pending decision buried in Changes or Acceptance instead of "I need from you"**: the human approves what the first screen shows; a decision below it gets approved without being seen.
- **"Not verified: nothing" when a check ran only by proxy**: a proxy run, an inline blind review or a skipped command is not verified; name it.
- **Reading the Lengths line as a target to cut to**: it is a measurement for the human; cutting evidence to change it turns results into claims.
- **Pasting the full diff** — the human has `git diff`; the report's job is to guide it, not duplicate it.
- **Skipping the review order** — without it, the human reads files alphabetically and misses the story.

## Output format

```md
T-03 done-with-drift: recovery states handled; the packet's retry limit was wrong (drift-log entry of 2026-09-20).

I need from you:
- Refund on abort: refund at once, or hold the funds for manual review? The abort path logs and stops, with no refund, until you answer (`src/funding/recover.ts:48`).

Not verified:
- `pnpm test:e2e funding`: not run, the sandbox account was not available.
- Blind review ran inline: not blind.

Business rules changed:
- A failed account link after token creation is now retried instead of aborted (`src/funding/recover.ts:22`).
- `funding.failed` with code `LINK_EXPIRED` now ends the funding in `aborted`, which callers see as status 409 instead of 500 (`src/funding/recover.ts:41`).

Deviations:
- Acceptance changed: the packet's retry limit contradicted `src/payments/retry.ts:12`; the code follows `retry.ts`, see the drift-log entry of 2026-09-20.
- Did not work: retrying inside the webhook handler held the webhook past its timeout; the retry moved to the queue.

Changes:
- `src/funding/recover.ts`: handle the two new recovery states.
- `src/funding/types.ts`: add `RecoveryState` union.
- `tests/funding.recover.test.ts`: happy path + timeout edge case.
- (+4 mechanical: snapshot updates from the type change)

Validation:
- `pnpm test funding`: pass (14 tests)
- `pnpm typecheck`: pass
- `pnpm test:e2e funding`: not run (see Not verified)

Review filter:
- intent: match
- applied: timeout edge case test (test audit)
- discarded: "retry has no upper bound": protected by `src/funding/queue.ts:31`
- to the human: refund on abort (see I need from you); follow-ups: none; rounds: 1

Self-review:
- reused the existing `Result` helper instead of adding a new error type: same shape as `src/payments/retry.ts`
- reuse scan found no duplicate helper
- added edge case: timeout during recovery

Acceptance:
- hard checks: pass, except the e2e command (not run)
- soft checks: pass (naming partially matches, see review order #2)
- drift: minor, retry limit (drift-log entry of 2026-09-20)

Out of scope (not acted on):
- `src/funding/client.ts` has an unhandled rejection: candidate for /dj-fix

Staging (uncommitted; `git add -p` theme by theme):

| # | File | Hunk | Added | Removed | First changed line | Theme |
|---|---|---|---|---|---|---|
| 1 | src/funding/recover.ts | 1 of 2 `@@ -18,6 +18,14 @@` | 8 | 0 | `if (isLinkFailure(err)) {` | retry on link failure |
| 2 | src/funding/recover.ts | 2 of 2 `@@ -40,4 +48,9 @@` | 5 | 1 | `case "LINK_EXPIRED":` | abort on expired link |
| 3 | src/funding/types.ts | 1 of 1 `@@ -3,2 +3,5 @@` | 3 | 0 | `export type RecoveryState =` | retry on link failure |
| 4 | tests/funding.recover.test.ts | new file | 64 | 0 | `git add tests/funding.recover.test.ts` | tests |

Review order:
1. `src/funding/recover.ts`: the actual behavior change
2. `src/funding/types.ts`: new union, check naming
3. `tests/funding.recover.test.ts`: edge case coverage

Suggested commit:
`fix(sdk): handle funding recovery states`

Lengths: report 65 lines, guide section 84 lines
```

For a `blocked` or `needs-replan` end state, replace Acceptance with a short "Blocked by / Needs" section stating exactly what decision or fix unblocks it, and still include Validation for whatever was attempted. The decision that unblocks it is also listed in "I need from you", marked as the blocker.
