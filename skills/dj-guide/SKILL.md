---
name: dj-guide
description: Use when a completed diff needs a human-review guide — closing a task in the /dj-task loop, or invoked directly for changes already made — so a reviewer can understand and verify the change without reconstructing it from a raw diff.
---

# Guide

## Overview

A guide exists so a human can review a change they did not write, file by file and test by test, and actually understand it instead of skimming a diff and trusting it. It teaches by showing: **real code first, short explanation after**. A guide that describes code without quoting it has failed — the reader should never need the repo open in another window to follow it.

## When to use

- At the close of a task in the **dj-task** loop, once code and tests are validated — the step itself is wired in dj-task; this skill only defines what gets written and where.
- Invoked directly to produce a review guide for changes already made (an old branch, a change that shipped without one).

**When NOT to use:**

- Reporting a task's outcome to the human in conversation — use **dj-task-report**.
- Writing a PR description, commit message, or anything that leaves the machine — use **dj-brief**.

## Language

The guide is an internal artifact: write it in the **internal language** from `.agent/language-policy.md` (default: whatever the user converses in). Code, identifiers, and every quoted block stay exactly as written in the repo — never translated.

## Where it lives

APPEND — never overwrite — to `.agent/features/<feature>/guide.md`. One section per task:

```markdown
## T-03 — Add funding recovery retries
```

Sections stay in execution order (T-01, then T-02, ...). The guide is per-feature and grows with every task closed against that feature — by the last task it is the complete human-readable trail of the whole feature.

## Detail level

Two modes, decided once per section. Read `.agent/expertise-registry.md` if it exists — it maps stacks to the user's expertise; no file or no match → known stack.

| Mode | When | What it changes |
|---|---|---|
| **Unknown stack** | The language/framework is new to the user | The Concepts section also teaches the language primitives used in the diff, each with a small runnable snippet |
| **Known stack** | Default | Concepts covers only project-specific ideas; no language tutorial |

## Section structure (per task)

Each `## T-XX — <task title>` section contains, in order:

| # | Section | Content |
|---|---|---|
| 1 | Summary | 3–5 lines: what changed and why, in plain terms |
| 2 | File map | Table: file · what happens to it · which section explains it — plus the `git diff --shortstat` line in a code block. State that explanations follow reading order, not diff order |
| 3 | Diff audit: deletions | The actual removed lines, shown as ```diff blocks, each with a verdict (moved / rewritten / removed on purpose / unclear). Additions cannot break what already existed; deletions can — this is read before approving |
| 4 | Concepts | One sub-heading per concept needed to read this diff, each taught with a verbatim snippet — from the diff, the repo, a dependency's source, or a 3-line REPL example. Never prose alone |
| 5 | File by file | In reading order (dependencies before dependents, tests last). Per file, block by block: paste the code as it landed in a fenced block, before/after as a ```diff when it helps, then explain below each block |
| 6 | Tests, one by one | Paste the test's key block, then its three answers: what it verifies, why it is necessary, what would break without it |
| 7 | Not done | Changes considered and rejected, with the reason |
| 8 | Low-confidence decisions | Calls the implementer made without being sure — points the human at exactly where to look harder |

## Hard rules

- **Show, then tell.** Any code being explained appears verbatim in a fenced block *before* its explanation. Describing code only by `file:line` references is this guide's primary failure mode.
- **Short paragraphs.** 2–4 lines each, with a bold lead-in naming the point (`**Why 30 seconds.** ...`). Walls of prose are unreadable next to a diff.
- **Deletions as diff blocks.** Every removed line appears inside a ```diff block with a verdict. A deletion summarized in a table cell but never shown is not audited.
- **Evidence is shown.** A claim resting on repo evidence ("four of the five caches set no TTL") shows the command used (`grep -rn ...`) or the counterpart code.
- **Reading order, not diff order.** Whatever a file imports or calls comes before it.
- **Every test gets its three answers** — what, why, what-if-missing.
- **Never invent a reason.** If the WHY is not evident from the packet, the report, or the code, say so as an open question.
- **Describe, don't sell.** The guide explains the code as it landed, rough edges included.

## Delegation

Default: the **dj-guide-writer** subagent writes the section. Hand it the task packet path, the commit range (`base..HEAD`), the task report path (if one exists), and the destination `guide.md` path.

**Elegant degradation:** if the subagent is not installed, write the section inline in the main session, following this skill directly.

## Common mistakes

- **Describing code by line numbers instead of pasting it** — produces a guide that must be read with the repo open, which defeats its purpose.
- Long paragraphs that narrate three changes at once — one block, one explanation.
- Writing the guide in English when the internal language is not English.
- Overwriting `guide.md` instead of appending — destroys every prior task's section.
- Following git-diff order instead of reading order.
- Skipping a test because "it's obvious" — every test gets its three answers.
- Guessing at a rationale instead of flagging it as an open question.

## Output format

The shape of one file-by-file entry — code first, short explanation after:

````markdown
### `src/funding/recover.ts`

**The retry decision.** New function; everything else in the file calls into it.

```ts
export function resolveRecovery(error: FundingError): RecoveryAction {
  if (RETRIABLE_CODES.has(error.code)) return { kind: "retry", delayMs: backoff(error.attempt) };
  return { kind: "abort", refund: true };
}
```

**What it does.** Maps an error code to retry-with-backoff or abort-with-refund.
The set lives in `codes.ts` (explained above) so the webhook handler and this
function cannot drift apart.

**What it replaced.**

```diff
-      // inline retry loop, 3 attempts hardcoded
-      for (let i = 0; i < 3; i++) { ... }
+      const action = resolveRecovery(error);
```

Verdict: moved — the loop's logic now lives in `resolveRecovery` with the cap
read from config. Nothing else was deleted in this file.
````
