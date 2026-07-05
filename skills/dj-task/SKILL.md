---
name: dj-task
description: "Use when executing one task packet from a delivery plan (e.g. /dj-task T-03) — a task file exists in .agent/features/<feature>/tasks/ and is ready to be worked on. Also for short sequences (/dj-task T-01..T-04) and for resuming a task after human feedback."
---

# Task Execution

## Overview

Execute ONE task packet end to end: implement, validate, review, report. The human reviews the diff and commits. Review rigor scales with the project's work mode — this is a loop with judgment, not a ritual.

**Announce at start:** "I'm using the dj-task skill to execute task <T-ID>."

## When to use

- Executing a single task packet: `/dj-task T-03`
- Executing a short sequence: `/dj-task T-01..T-04` (each task still goes through the full loop, one at a time)
- Re-running a task after the human requested changes

**Do NOT use when:**
- No task packet exists — run **/dj-plan** first, or just do the work directly if it's a one-off tweak too small to deserve the system
- Investigating or fixing a bug — use **/dj-fix**
- Reviewing someone else's PR — use **/dj-review**

## Subagent availability

The loop delegates to specialist subagents (**dj-scout**, **dj-implementer**, **dj-test-auditor**, **dj-ts-reviewer**, **dj-acceptance-reviewer**). If any of them is not available, do that step inline in the main session with a fresh-eyes mindset — the step still happens, only the executor changes.

**Cost brake:** at most one subagent per step, sequentially — never parallel fleets or multi-agent workflows, even when the session's effort mode encourages orchestration. Hand each subagent the context already gathered (diff, packet, scout result) instead of letting it re-derive everything from scratch.

## The execution loop

### 1. Load state

Read `.agent/current.md` first — it is the source of truth for active mode, current direction, and anything marked "Do not follow". Then read the task packet (`.agent/features/<feature>/tasks/T-XX.md`): objective, context files, acceptance checks (hard/soft/exploratory/deferred), validation commands, commit policy. If `current.md` and the packet disagree, `current.md` wins — flag the mismatch before implementing.

**Branch check.** Read the Branching section of `.agent/project.md`. On the base branch with `branch_creation: agent`? Create the feature branch (per the naming convention) from the up-to-date base before touching files. `suggest-only`? Tell the human which branch to create and wait. Already on a matching feature branch? Continue. No policy written? Ask once, record the answer in `project.md`, and move on.

### 2. Scout context and precedents

Delegate to the **dj-scout** subagent: relevant files, existing patterns, reusable helpers, duplication risk. **Skip this step** if the packet already lists context files and you know the area — say so in the report.

### 3. Implement

Implement in the main session, or delegate to the **dj-implementer** subagent for well-bounded packets.

**REQUIRED SUB-SKILL:** dj-repo-patterns — find precedent before creating anything new.
**REQUIRED SUB-SKILL:** dj-simplicity-lens — before writing new code, ask whether it needs to exist.

Stay in scope: one conceptual objective, the files the packet points at. Out-of-scope discoveries (bugs, refactor opportunities, missing utilities) go in the report — do not act on them.

### 4. Validate

Run the packet's validation commands (format, lint, typecheck, tests — whatever the packet lists). **Real output required**: read the actual results, never assume success. If a command fails, fix the root cause and re-run; if the failure reveals the task is mis-specified, that is drift — see end states below.

### 5. Audit tests

Delegate to the **dj-test-auditor** subagent: do the new/changed tests cover the change's actual contract? Behavior over implementation, realistic edge cases, no duplicate fixtures. Scale by work mode (table below).

### 6. Stack review

For TypeScript/Node work, delegate to the **dj-ts-reviewer** subagent. For other stacks, do a general quality pass inline using the repo's own patterns as the bar (**REQUIRED SUB-SKILL:** dj-repo-patterns). Scale by work mode.

### 7. Acceptance review

Delegate to the **dj-acceptance-reviewer** subagent: does the diff fulfill the packet's intent? Hard checks pass? Soft checks reasonable? Any scope drift or missing behavior? This is the one review that judges intent, not code beauty.

### 8. Fix obvious issues

Fix small, clear findings from steps 5–7 (a missing edge-case test, an unnecessary cast, a naming slip) and re-run the affected validation. Anything bigger — architectural doubts, new scope, findings that change the task's shape — goes in the report instead. Do not expand scope to satisfy a reviewer.

### 9. Report and hand off

**REQUIRED SUB-SKILL:** dj-task-report — produce the compact report (format at the end of this file).
**REQUIRED SUB-SKILL:** dj-commit-message — suggest a commit message matching the repo's convention.

The human reviews the diff and the report, then commits (unless commit policy says otherwise). Declare the task's end state.

## Review rigor by work mode

Read the mode from `.agent/project.md`. Guidance, not law — the human can dial it either way per task.

| Work mode | Steps 5–7 |
|---|---|
| `production-work` | All three: test audit + stack review + acceptance review |
| `personal-medium` | Test audit + acceptance review |
| `personal-small` | Acceptance review only (or none, if project.md says so) |

Validation (step 4) never scales down — commands listed in the packet always run.

## Skipping steps

If a step is obviously unnecessary for this task — scout for a one-line change in a file you just edited, test audit for a docs-only task — skip it **and say so in the report**: "Skipped step 2 (scout): packet lists all context and the area was mapped in T-01." Visibility over ceremony. Silently skipping is the failure mode; skipping with a stated reason is the system working.

## Task end states

Every task ends in exactly one of these:

| End state | Meaning | What happens next |
|---|---|---|
| `done` | Goal met, no surprises | Human reviews, commits, next task |
| `done-with-drift` | Goal met, but reality differed from the packet | Log it — **REQUIRED SUB-SKILL:** dj-drift-management; update affected future tasks |
| `blocked` | Cannot proceed (missing access, broken dependency, unanswered question) | Report the blocker; human unblocks |
| `needs-replan` | Discovery invalidates this task's premise or later tasks | Stop; `/dj-plan --replan-from T-XX` |
| `split-needed` | Task is bigger than one reviewable unit | Report the natural split; replan the packet into two |
| `merged-into-next` | Remaining work is trivial and belongs with the next task | Note it in the next packet; close this one |
| `obsolete` | Direction changed; task no longer makes sense | Mark obsolete in the plan and in `current.md` |

Any drift — even under `done-with-drift` — gets a drift-log entry via **dj-drift-management** so future tasks and the spec stay honest.

## Commit policy

Default (from `.agent/project.md`, `commit_policy: human-only`):

- No automatic commit. No push. No automatic PR. No co-author lines.
- Suggest `type(scope): message` after checking `git log --oneline -n 20` for the repo's actual convention (**REQUIRED SUB-SKILL:** dj-commit-message).
- Autonomous commits only when the user explicitly enables them, e.g. `/dj-task T-01..T-04 --autonomous` — and even then, one commit per task, message per convention.

## Closing the task: state and session

When a task closes (any end state):

1. Update `.agent/current.md`: current task, direction, anything now in "Do not follow".
2. Update `.agent/handoff.md` if the session will end or the context is getting heavy.
3. Update the drift-log if direction changed.
4. Mark the next task.

Context guidance (judgment, not thresholds-as-law):

| Context used | Guidance |
|---|---|
| 0–50% | Continue normally |
| 50–75% | Continue if the work is cohesive; update handoff when closing tasks |
| 75–85% | Close the current slice, update `current.md` + `handoff.md`, open a fresh session |
| 85%+ | Don't start a new task — summarize, close, hand off |

Before opening a fresh session, `handoff.md` must state: what is true now, what changed, discarded ideas, the next task, and **what must NOT be followed anymore** — so the new session never obeys a dead spec.

## Common mistakes

- **Expanding scope because a reviewer suggested it** — reviewers surface findings; the packet defines scope. Bigger findings go in the report.
- **Claiming validation passed without reading output** — "should pass" is not evidence. Paste real results.
- **Silently absorbing drift** — if reality differed from the packet, say so and log it, even when the outcome is fine.
- **Running all reviewers on a personal-small project** — ceremony without payoff. Scale down and say you did.
- **Fixing an out-of-scope bug "while you're here"** — report it; fixing it is a separate task (or a `/dj-fix`).
- **Starting T-05 at 90% context** — close the session properly instead; the handoff costs 5 minutes, a contaminated session costs the task.

## Report format

Per **dj-task-report** (the canonical format and full example live there). Sections, in order:

```text
<T-ID>: <end state>
Changes · Validation · Self-review · Skipped steps · Acceptance ·
Out of scope · Review order · Suggested commit · Walkthrough (on request)
```

Readable in 2 minutes; drop empty sections. The Walkthrough (goal in one line, data-flow map, core files function by function) is produced only when the user asks or when `current.md`'s Report style says `Walkthrough: always`.
