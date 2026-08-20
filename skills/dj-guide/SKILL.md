---
name: dj-guide
description: Use when a completed diff needs a human-review guide — closing a task in the /dj-task loop, or invoked directly for changes already made — so a reviewer can understand and verify the change without reconstructing it from a raw diff.
---

# Guide

## Overview

A guide exists so a human can review a change they did not write, file by file and test by test, and actually understand it instead of skimming a diff and trusting it. It explains the code as it landed — what changed, why, what each test protects, and where the implementer was unsure. It never sells the change.

## When to use

- At the close of a task in the **dj-task** loop, once code and tests are validated — this is the final step of that loop; the step itself is wired in dj-task, this skill only defines what gets written and where.
- Invoked directly to produce a review guide for changes already made (an old branch, a change that shipped without one).

**When NOT to use:**

- Reporting a task's outcome to the human in conversation — use **dj-task-report**.
- Writing a PR description, commit message, or anything that leaves the machine — use **dj-brief**.

## Where it lives

APPEND — never overwrite — to `.agent/features/<feature>/guide.md`. One section per task:

```markdown
## T-03 — Add funding recovery retries
...
```

Sections stay in execution order (T-01, then T-02, ...), never alphabetical or diff order. The guide is per-feature and grows with every task closed against that feature — by the last task it is the complete human-readable trail of the whole feature.

## Detail level

Two modes, decided once per section:

| Mode | When | What it adds |
|---|---|---|
| **Unknown stack** | The stack (language/framework) touched by this task is new to the user | Explains the language/framework primitives used in the diff alongside the WHAT/WHY |
| **Known stack** | Default | Only WHAT changed and WHY — no language tutorial |

Read `.agent/expertise-registry.md` if it exists — it maps stacks to the user's expertise level; use its verdict for the stack this task touches. **If the file does not exist, default to known stack.**

## Section structure (per task)

Each `## T-XX — <task title>` section contains, in order:

| # | Section | Content |
|---|---|---|
| 1 | Summary | 3–5 lines: what changed and why, in plain terms |
| 2 | Diff audit | Table of every file added/modified/deleted with line counts; every deleted block gets a verdict (moved / rewritten / removed on purpose / unclear) — deletions are the only lines that can silently break something, so they earn a table even in an otherwise prose-heavy section |
| 3 | The cross-cutting concept | The bug, pattern, or idea behind the change, explained once — referenced afterward, never repeated |
| 4 | File by file | Every changed file, **in logical reading order** (dependencies before dependents, tests last) — not diff order. Each file: what changed, before/now when it helps, explained inline; unknown-stack mode adds language notes here |
| 5 | Tests, one by one | Per test: what it verifies, why it is necessary, what would happen without it (the failure it prevents) |
| 6 | Not done | Changes considered and rejected, with the reason |
| 7 | Low-confidence decisions | Calls the implementer made without being sure — points the human at exactly where to look harder |

## Hard rules

- **Reading order, not diff order.** File-by-file follows dependencies first; whatever a file imports or calls comes before it.
- **Every test gets its three answers** — what, why, what-if-missing. A test with no explanation is not documented.
- **Every deletion is audited** in the diff-audit table. Additions are safe by construction; deletions are not.
- **Never invent a reason.** If the WHY of a change is not evident from the packet, the report, or the code itself, say so as an open question — do not guess to sound complete.
- **Describe, don't sell.** The guide explains the code as it landed, rough edges included. It is not a changelog pitch.

## Delegation

Default: the **dj-guide-writer** subagent writes the section. Hand it the task packet path, the commit range (`base..HEAD`), the task report path (if one exists), and the destination `guide.md` path.

**Elegant degradation:** if the subagent is not installed, write the section inline in the main session, following this skill directly — the guide still gets written, only the writer changes.

## Common mistakes

- Overwriting `guide.md` instead of appending — destroys every prior task's section.
- Following git-diff order for the file-by-file section instead of reading order.
- Skipping a test because "it's obvious" — every test gets its three-line treatment.
- Guessing at a rationale instead of flagging it as an open question.
- Applying unknown-stack detail to a stack the user already knows well, or the reverse, without checking the expertise registry.

## Output format

The appended section, ready to read top to bottom:

```markdown
## T-03 — Add funding recovery retries

[1] In three sentences: retries failed funding webhooks with backoff instead of
dropping them; touches the webhook handler and the retry queue.

[2] Diff audit
| File | Change | Lines |
|---|---|---|
| `src/funding/recover.ts` | added | +64 |
| `src/funding/client.ts` | modified | +8/-3 |

Deletions:
| File:line | What was removed | Verdict |
|---|---|---|
| `client.ts:41` | inline retry loop | moved into `recover.ts` |

[3] The concept: ...

[4] File by file (reading order)
### `src/funding/types.ts`
...
### `src/funding/recover.ts`
...
### `src/funding/client.ts`
...
### `tests/funding.recover.test.ts`
...

[5] Tests
**`retries once on 5xx`** — verifies... — necessary because... — without it...

[6] Not done
- Did not add exponential backoff beyond 3 tries — reason: ...

[7] Low-confidence decisions
- Chose 3 as the retry cap without a stated source — worth confirming with the team.
```
