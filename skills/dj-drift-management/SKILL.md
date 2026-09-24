---
name: dj-drift-management
description: Use when reality diverges from the plan — a task no longer matches current intent, the user requests a scope change mid-feature, a discovery during implementation invalidates spec assumptions, or .dj-agents/ documents contradict each other about the current direction.
---

# Drift Management

## Overview

Plans are hypotheses, so drift is normal — silent drift is not. When reality and plan diverge, record it, size it, and route it (absorb, split, or replan) so old documents can never override the new direction.

## When to use

- Mid-implementation, a task packet's assumptions turn out to be wrong.
- The user changes direction: "actually, let's do X instead."
- An acceptance review (see **dj-acceptance-review**) ends in `done-with-drift`, `needs-replan`, or `split-needed`.
- Two `.dj-agents/` documents disagree and you must decide which one to trust.

When NOT to use:

- Ordinary implementation choices within scope — those belong in the task report's key decisions (**dj-task-report**).
- Bugs in existing behavior — that is **/dj-fix** territory, not drift.

## Step 1 — Record it

Write an entry in `.dj-agents/repos/<repo>/features/<feature>/drift-log.md` (created by **dj-plan**; if the file doesn't exist, create it with a `# Drift Log` heading and append entries). Format at the end of this skill. Do this BEFORE acting on the drift — the entry is what keeps the next session sane.

## Step 2 — Size it and route it

| Size | Signs | Action |
|------|-------|--------|
| Minor | Intent intact; only this task's details shift | Absorb: finish the task, end state `done-with-drift`, log entry + note in the task report |
| Moderate | This task is wrong as written, but the plan around it holds | Split (`split-needed`) or rewrite the packet; log entry; future tasks untouched |
| Major | Future tasks, the phase, or the spec are invalidated | Stop and replan: `/dj-plan --replan-from T-XX` |

The judgment question: **"Knowing this, would the human plan the remaining tasks differently?"** If yes, it's major — don't absorb it quietly.

Acceptance checks are living contracts: if a check no longer applies, update it consciously through a drift-log entry. Never silently ignore a check to reach `done`.

## Step 3 — Invalidate the old direction

This is the step most often skipped, and the one that matters most:

- Rewrite `.dj-agents/repos/<repo>/features/<feature>/state.md` with a **"Do not follow"** list naming the outdated docs or sections (e.g. "Do not follow spec.md §3 — old API shape"). A stale spec that isn't flagged WILL be obeyed by a future session.
- In the entry's Impact section, classify affected artifacts: still valid / obsolete / needs migration.
- Mark dead tasks with their end state (`obsolete`, `merged-into-next`) in the delivery plan.

## Context hierarchy (when documents contradict)

Most recent intent wins. `current.md` is the index above all: it says which features are active and where their state lives. Within a feature, read and trust in this order:

1. `state.md` (including its "Do not follow" list)
2. The active task packet
3. `drift-log.md`
4. Phase spec
5. Feature spec
6. Historical discovery / brainstorming

The original brainstorming never outranks the current task.

## Replan rules

When routing to `/dj-plan --replan-from T-XX`, the replan must:

- Keep everything still valid — completed tasks, sound decisions, unaffected future tasks.
- Mark obsolete tasks explicitly instead of deleting history.
- Update the feature spec if the intent itself changed.
- Recalculate only the future tasks.
- **Never restart from zero.**

If replanning can't happen now (context nearly exhausted, or the **dj-planner** subagent unavailable), write the drift-log entry and the "Do not follow" note first — those two artifacts protect the next session — then replan fresh, inline in the main session if dj-planner is not available.

## Common mistakes

- **Absorbing major drift to "keep momentum"** — you'll implement three more tasks against a dead spec.
- **Replanning without invalidating old docs** — the next session reads the old spec and undoes the pivot.
- **Treating every wobble as a replan** — most drift is minor; absorb it and move on.
- **Recording drift only in conversation** — if it isn't in drift-log + the feature's `state.md`, it doesn't exist next session.
- **Restarting the plan from zero** — throws away valid work and human-approved decisions.

## Output format — drift-log entry

```md
## <date> — <short title>

Original:
- <what the plan/spec assumed>

New direction:
- <what is true now>

Why:
- <discovery, user request, or invalidated assumption — one or two lines>

Impact:
- T-04: obsolete.
- T-05: still valid.
- T-06: needs rewrite (API shape changed).
- spec.md §3: outdated — update during replan.

Action:
- Replan from T-04 (`/dj-plan --replan-from T-04`).
- state.md rewritten: "Do not follow spec.md §3 (old API shape)."
```
