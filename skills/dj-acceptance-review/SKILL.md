---
name: dj-acceptance-review
description: Use when judging whether a diff fulfills the intent of its task packet, spec, or issue — after implementing a task, before closing a bug fix, or when comparing explored approaches against requirements.
---

# Acceptance Review

## Overview

Acceptance review answers one question: was the right thing built? It judges the diff against intent — not whether the code is pretty (that is the stack reviewer's job).

## When to use

- After implementing a task packet, before reporting it done.
- Before closing a bug fix, judged against the original issue.
- When evaluating candidate approaches in /dj-explore.

**When NOT to use:** as a style or code-quality review. Findings about naming, structure, or patterns belong to the stack reviewer (e.g. the **dj-ts-reviewer** subagent).

## Inputs

Read, in this order:

1. The task packet (`.dj-agents/repos/<repo>/features/<feature>/tasks/T-XX.md`) or issue context.
2. The relevant spec section.
3. The diff.
4. The tests.
5. The implementation report, if one exists.

## The four acceptance levels

Not every check carries the same weight. Classify each check before judging it:

| Level | Meaning | Examples |
|-------|---------|----------|
| **Hard** | Must pass. Failing means the task is not done. | Typecheck passes. Existing success flow still works. Widget not modified in this task. |
| **Soft** | Desirable — apply judgment. | Follows the existing Result pattern. Error naming stays consistent. |
| **Exploratory** | May legitimately change during execution. | UX feels clear in manual review. Flow doesn't feel too long. |
| **Deferred** | Matters, but belongs to a later task. | Public docs updated in a later task. Old error naming unified. |

## Acceptance checks are living contracts

Checks have status, and status can change — consciously, never silently:

| Check | Status | Notes |
|---|---|---|
| SDK returns recovery result | active | hard |
| Widget consumes recovery state | future | handled in T-06 |
| Error copy is final | provisional | may change after UI review |

Typical transitions: `active → obsolete`, `provisional → active`, `future → moved`, `active → deferred`. When a check changes status because the scope really shifted, record why in a drift-log entry — **see the dj-drift-management skill**. Ignoring a check without recording it is how specs die. Keep it a simple table, not a state machine.

## How to run the review

1. **Judge goal satisfaction** — does the diff achieve the packet's conceptual objective? `yes | partial | no`.
2. **Walk hard checks** — pass/fail each one, with evidence (command output, file:line, observed behavior). No evidence, no pass.
3. **Walk soft checks** — pass/partial/fail with a one-line judgment.
4. **Classify scope drift** — `none | minor | major`. Minor: same intent, small deviation worth noting. Major: the work no longer matches the planned intent.
5. **List missing behavior** — anything the packet promised that the diff does not deliver.
6. **Decide whether future tasks need replanning** — a discovery here can invalidate downstream assumptions.
7. **Recommend** — `approve | fix now | replan future tasks | split task`.

Within /dj-task, /dj-fix, and /dj-explore, delegate this review to the **dj-acceptance-reviewer** subagent. If the dj-acceptance-reviewer subagent is not available, run the review inline in the main session using these steps.

## Task end states

An acceptance-reviewed task lands in exactly one of:

`done | done-with-drift | blocked | needs-replan | split-needed | merged-into-next | obsolete`

`done-with-drift`, `needs-replan`, and `split-needed` all require a drift-log entry — hand off to the **dj-drift-management** skill.

## Common mistakes

- Reviewing code quality instead of intent — wrong lens, wrong reviewer.
- Treating every check as hard, turning judgment calls into blockers.
- Passing a task whose hard checks fail "because the code looks fine".
- Silently dropping an acceptance check instead of marking it obsolete or deferred with a reason.
- Declaring the goal satisfied without evidence for the hard checks.

## Output format

```markdown
# Acceptance Review

## Goal satisfied
yes | partial | no

## Hard acceptance checks
- <check> — pass/fail (<evidence>)

## Soft acceptance checks
- <check> — pass/partial/fail (<one-line judgment>)

## Scope drift
none | minor | major — <one line on what drifted>

## Missing behavior
- ...

## Needs replan
yes | no

## Recommendation
approve | fix now | replan future tasks | split task
```
