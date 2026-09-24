---
name: dj-guide
description: Use when a completed diff needs a human-review guide — closing a task in the /dj-task loop, or invoked directly for changes already made — so a reviewer can understand and verify the change without reconstructing it from a raw diff.
---

# Guide

## Overview

A guide exists so a human can review a change they did not write, file by file and test by test, and actually understand it instead of skimming a diff and trusting it. It teaches by showing: **real code first, short explanation after**. A guide that describes code without quoting it has failed — the reader should never need the repo open in another window to follow it.

Each task's section has two layers. A first screen carries what the human needs to decide: the business why, the metrics of the diff, what can break and the yes/no questions to approve. The depth sits below a marker and is read when learning the area. Only added lines are quoted and explained; a removed line is shown once, with its verdict. The guide is for the human only: nothing in it is posted.

## When to use

- At the close of a task in the **dj-task** loop, once code and tests are validated — the step itself is wired in dj-task; this skill only defines what gets written and where.
- Invoked directly to produce a review guide for changes already made (an old branch, a change that shipped without one).

**When NOT to use:**

- Reporting a task's outcome to the human in conversation — use **dj-task-report**.
- Writing a PR description, commit message, or anything that leaves the machine — use **dj-brief**.

## Language

The guide is an internal artifact: write it in the **internal language** from `.dj-agents/repos/<repo>/language-policy.md` (default: whatever the user converses in). Code, identifiers, and every quoted block stay exactly as written in the repo — never translated.

## Where it lives

`.dj-agents/repos/<repo>/features/<feature>/guide.md`, one file per feature, newest first. The file starts with the feature header and a short index, one line per task, newest on top:

```markdown
# Guide: <feature>

Index:
- T-03: Add funding recovery retries (2026-09-24)
- T-02: Store the funding attempt (2026-09-22)
```

A new task's section is inserted right under the index, above every earlier section, and its line goes on top of the index. Earlier sections are never edited and never reordered: they stay byte-identical. The heading is `## T-XX: <task title>` (a colon, no dash). A guide written before this layout has no index: add one, with the new task's line on top and one line per existing section below it (no date when none is known); the existing sections stay where they are.

## Detail level

Two modes, decided once per section. Read `.dj-agents/repos/<repo>/expertise-registry.md` if it exists — it maps stacks to the user's expertise; no file or no match → known stack.

| Mode | When | What it changes |
|---|---|---|
| **Unknown stack** | The language/framework is new to the user | The Concepts section also teaches the language primitives used in the diff, each with a small runnable snippet |
| **Known stack** | Default | Concepts covers only project-specific ideas; no language tutorial |

The mode only decides the depth of Concepts, and Concepts appears only when the packet's `Learn:` line names something to learn.

## Section structure (per task)

Each `## T-XX: <task title>` section has two parts, in this order.

**First screen**, for the decision:

1. `### Why (business)`: what problem of the business or of the user this task serves, from the packet's why, else the feature spec, else the flow the packet names. When none of them states it, the section opens with `Open question: <why does the business need this?>` right under the heading, above everything else, and this part points to it. Never an invented reason.
2. `### Metrics`: the `diff-metrics` output for the task's range, run with one `--in` per path in the packet's "In scope" list, pasted verbatim: the table and the summary line. Under it, one line per file that lost lines: `<file>: -<n>, <moved | rewritten | removed on purpose | unclear>: <why, in a few words>`. When the script is not found, a `git diff --numstat` table with the note "metrics by hand: kinds and comments not split".
3. `### What can break`: the "Business rules changed" and "Not verified" items of the task report, every removal marked `unclear`, and the decisions made without certainty, each with `path:line`. "nothing found" is allowed.
4. `### To approve`: one yes/no question per acceptance check that a reader can answer from the diff, Hard first, then Soft, phrased so "yes" means approve. Then one concrete check to run (a command, a request, a path to exercise) with its expected result. A check that needs a command instead of reading feeds the concrete check. No fixed count. A question may carry a pointer to where to look (`path:line`), never its answer: the reader answers from the diff.

Then the marker line, exactly:

```markdown
<!-- Depth: read when learning the area -->
```

**Depth**, read when learning the area:

5. `### Flow`: numbered pseudocode with the real names from the code, the happy path only, no guards.
6. `### Removed lines`: every removed line in a ```diff block with its verdict (moved / rewritten / removed on purpose / unclear). Additions cannot break what already existed; deletions can.
7. `### Concepts`: only when the packet's `Learn:` line names something; otherwise the part is left out. One sub-heading per concept, taught with a verbatim snippet (from the diff, the repo, a dependency's source, or a small REPL example), never prose alone. A concept already taught in an earlier section of this guide gets one line pointing to that section instead. "Detail level" decides the depth.
8. `### File by file`: in reading order (dependencies before dependents, tests last). Per file, block by block: quote only the added lines (a ```diff block with the `+` lines, or the code as it landed limited to them), then explain below. Neighboring context gets one line of description at most and is never pasted.
9. `### Tests`: each test's key block, then three answers: what it verifies, why it is needed, what breaks if it is removed. A test whose removal breaks nothing that another test does not already catch is marked "candidate to drop".
10. `### Not done`: the packet's rejected approaches, and what the implementation considered and dropped, with the reason.

A depth part with nothing to show says "none", except Concepts, which is left out.

## Hard rules

- **Show, then tell.** Any code being explained appears verbatim in a fenced block *before* its explanation. Describing code only by `file:line` references is this guide's primary failure mode.
- **Short paragraphs.** 2–4 lines each, with a bold lead-in naming the point (`**Why 30 seconds.** ...`). Walls of prose are unreadable next to a diff.
- **Deletions as diff blocks.** Every removed line appears in a ```diff block with a verdict under Removed lines, and every file that lost lines has its line under Metrics. A deletion summarized but never shown is not audited.
- **Only added lines are quoted and explained.** A line that is unchanged in the diff never appears in a code block under File by file, and neither does code from a file the diff does not touch: it is described in one line, never pasted. Evidence is a command and its output, not a pasted block from elsewhere.
- **The metrics come from `diff-metrics`**, pasted, never retyped or estimated.
- **Evidence is shown.** A claim resting on repo evidence ("four of the five caches set no TTL") shows the command used (`grep -rn ...`) or the counterpart code.
- **Reading order, not diff order.** Whatever a file imports or calls comes before it.
- **Every test gets its three answers** — what, why, what-if-missing.
- **Never invent a reason.** If the WHY is not evident from the packet, the report, or the code, say so as an open question.
- **Names from the code, the repository and the glossary.** Never an invented term; never a person's name.
- **Describe, don't sell.** The guide explains the code as it landed, rough edges included.

## Delegation

Default: the **dj-guide-writer** subagent writes the section. Hand it the task packet path, the range (`<base>..<head>`, or `<base>..working-tree` when nothing is committed, as in dj-task step 6), the task report path (if one exists), and the destination `guide.md` path.

**Elegant degradation:** if the subagent is not installed, write the section inline in the main session, following this skill directly.

## Common mistakes

- **Describing code by line numbers instead of pasting it** — produces a guide that must be read with the repo open, which defeats its purpose.
- Long paragraphs that narrate three changes at once — one block, one explanation.
- Writing the guide in English when the internal language is not English.
- Appending at the bottom or editing an earlier section: new sections go on top, old ones stay byte-identical.
- Explaining neighboring lines to give context for one added line.
- Teaching a concept the packet did not mark, or one already taught in this feature.
- A "To approve" question that cannot be answered by reading the diff.
- Following git-diff order instead of reading order.
- Skipping a test because "it's obvious" — every test gets its three answers.
- Guessing at a rationale instead of flagging it as an open question.

## Output format

The shape of a first screen, then one file-by-file entry that quotes only added lines:

````markdown
## T-03: Add funding recovery retries

### Why (business)

A customer whose card funding fails for a network error today sees a failed order and
pays again by hand; this task retries that funding so the order goes through.

### Metrics

| File | Kind | Added | Removed | Note |
|---|---|---|---|---|
| src/funding/recover.ts | code | 6 | 0 | new |
| src/funding/webhook.ts | code | 1 | 2 |  |

+7 -2 in 2 files. Added by kind: code 7, comments 0, tests 0, docs 0, config and generated 0. Files by kind: code 2, tests 0, docs 0, config and generated 0. Outside scope: 0 files. Comments are counted by line prefix, a heuristic.

- src/funding/webhook.ts: -2, moved: the retry loop now lives in `resolveRecovery`.

### What can break

- A funding error with an unknown code now aborts with a refund instead of retrying (`src/funding/recover.ts:4`).
- Not verified: the retry cap read from config has no test (`src/funding/recover.ts:3`).

### To approve

- Does a network error lead to a retry and a card decline to an abort with refund?
- Is the webhook handler the only caller of `resolveRecovery`?
- Run `pnpm test funding`: every test passes.

<!-- Depth: read when learning the area -->

...

### File by file

#### `src/funding/recover.ts`

**The retry decision.** New function; the webhook handler calls into it.

```diff
+export function resolveRecovery(error: FundingError): RecoveryAction {
+  if (RETRIABLE_CODES.has(error.code)) return { kind: "retry", delayMs: backoff(error.attempt) };
+  return { kind: "abort", refund: true };
+}
```

**What it does.** Maps an error code to retry with backoff, or abort with refund.
`RETRIABLE_CODES` is unchanged and lives in `codes.ts`.
````
