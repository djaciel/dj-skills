---
name: dj-task
description: "Use when executing one task packet from a delivery plan (e.g. /dj-task T-03) — a task file exists in .dj-agents/repos/<repo>/features/<feature>/tasks/ and is ready to be worked on. Also for short sequences (/dj-task T-01..T-04) and for resuming a task after human feedback."
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

The loop delegates to specialist subagents (**dj-scout**, **dj-implementer**, **dj-test-auditor**, **dj-ts-reviewer**, **dj-elixir-reviewer**, **dj-pr-reviewer**, **dj-acceptance-reviewer**, **dj-guide-writer**). If any of them is not available, do that step inline in the main session with a fresh-eyes mindset: the step still happens, only the executor changes.

**Cost brake:** at most one subagent per step, sequentially — never parallel fleets or multi-agent workflows, even when the session's effort mode encourages orchestration. Hand each subagent deterministic pointers to context already gathered — the packet path, the scout result file, the diff as a commit range — instead of letting it re-derive everything from scratch, and instead of pasting file contents into the orchestrating session.

## The execution loop

### 1. Load state

Layout and root resolution: `skills/dj-start/templates/dj-agents-layout.md`; resolve `<area>` with the `dj-root` script.

If `dj-root repo` fails or prints a path that does not exist yet, or the area has no `project.md`, stop and tell the human to run `/dj-start --adopt` first (it fills the base files an existing area is missing).

Read in this order:

1. `.dj-agents/repos/<repo>/current.md`: the index of active features. Find this feature's line.
2. `.dj-agents/repos/<repo>/features/<feature>/state.md`: the source of truth for active mode, current direction, and anything marked "Do not follow".
3. The task packet (`.dj-agents/repos/<repo>/features/<feature>/tasks/T-XX.md`): objective, context files, acceptance checks (hard/soft/exploratory/deferred), validation commands, commit policy.
4. `.dj-agents/repos/<repo>/features/<feature>/follow-ups.md`, if it exists. Open entries on files in the packet's scope go to the implementer as a pointer together with the packet (step 3); at close their status becomes `taken in T-XX` only when the diff resolves them, otherwise they stay open.

If `state.md` and the packet disagree, `state.md` wins: flag the mismatch before implementing.

**Branch check.** Read the Branching section of `.dj-agents/repos/<repo>/project.md`. On the base branch with `branch_creation: agent`? Create the feature branch (per the naming convention) from the up-to-date base before touching files. `suggest-only`? Tell the human which branch to create and wait. Already on a matching feature branch? Continue. No policy written? Ask once, record the answer in `project.md`, and move on.

### 2. Scout context and precedents

Delegate to the **dj-scout** subagent: relevant files, existing patterns, reusable helpers, duplication risk. Save the returned Scout Result verbatim to `.dj-agents/repos/<repo>/features/<feature>/scout/T-XX.md` — the implementer and reviewers read the file, and a future session resuming this task does not re-scout. **Skip this step** if the packet already lists context files and you know the area — say so in the report.

**Apply the Map corrections before implementing.** The scout is read-only, so the orchestrator writes its `Map corrections` into the knowledge files (under `dj-root knowledge`) right after saving the Scout Result. Each correction replaces the wrong line with what is true now and its evidence, following the file's update rule; when the wrong line was a rule, its old text first moves to `library/superseded-rules.md` as a dated block. A correction without evidence is not applied: it goes to the report as a question. Note "map corrected: <n>" in the report.

### 3. Implement

**Delegate to the dj-implementer subagent — always.** The orchestrating session writes no code; all implementation happens in the implementer's own context, and only its Implementation Report comes back. Hand it pointers, not content: the packet path, the scout result file (step 2), and the feature's `state.md`. The implementer applies dj-repo-patterns and dj-simplicity-lens internally.

Implement inline only as degradation — when dj-implementer is not installed — and then:

**REQUIRED SUB-SKILL:** dj-repo-patterns — find precedent before creating anything new.
**REQUIRED SUB-SKILL:** dj-simplicity-lens — before writing new code, ask whether it needs to exist.

Stay in scope: one conceptual objective, the files the packet points at. Out-of-scope discoveries (bugs, refactor opportunities, missing utilities) go in the report — do not act on them.

### 4. Validate

Run the packet's validation commands (format, lint, typecheck, tests — whatever the packet lists). **Real output required**: read the actual results, never assume success. If a command fails, fix the root cause and re-run; if the failure reveals the task is mis-specified, that is drift — see end states below.

**Reviewers pull, the orchestrator points (steps 5 to 7).** Give the test auditor (step 5) and the acceptance reviewer (step 7) the packet path, the scout result file, and the diff as a commit range (state the refs: `git diff <base>..HEAD`, or `git diff <base>` plus the untracked files when nothing is committed yet); the reviewer runs the diff in its own context. The blind reviewer (step 6) gets only the hand-off written in step 6. Never load the full diff into the orchestrating session just to paste it into reviewer prompts: the range is deterministic and costs the orchestrator nothing.

### 5. Audit tests

Delegate to the **dj-test-auditor** subagent: do the new/changed tests cover the change's actual contract? Behavior over implementation, realistic edge cases, no duplicate fixtures. Scale by work mode (table below).

### 6. Blind review

Delegate to the blind reviewer of the diff's stack: **dj-ts-reviewer** for TypeScript or Node, **dj-elixir-reviewer** for Elixir, **dj-pr-reviewer** for any other stack. A mixed diff goes to the reviewer of the stack with the most core files (one subagent for the step). The prompt has exactly this shape, followed by an `Expertise: <skill>` line only when an expertise skill for that stack is available:

```
Blind review. Range: <base>..<head> in <repo path>.
Goal: <one line>.
Map inputs: <architecture path | missing>; <rules path | missing>; <false-positives path | missing>.
Output: compact.
```

- **Range**: `<base>` is the commit the task started from; `<head>` is `working-tree` while the task's changes are not committed (the usual case under `commit_policy: human-only`), otherwise the task's last commit. Example: `Blind review. Range: 3f2a1c9..working-tree in /path/to/repo.`
- **Goal**: the packet's Goal reduced to one sentence of purpose, with no file names, scope lists or acceptance checks. "Goal: let a customer cancel an order that has not shipped yet." is right; "Goal: T-04, add cancelOrder to src/orders/service.ts." is not.
- **Map inputs**: `<knowledge>/architecture/<name>.md`, `<knowledge>/review/rules.md` and `<knowledge>/review/false-positives.md`, with `<knowledge>` from `dj-root knowledge` and `<name>` from `dj-root name`; a file that does not exist is written `missing`.
- **Output**: always written, always `compact`.

Never add the packet, the scout result, the report, `state.md`, `current.md`, `handoff.md` or the feature path to that prompt: a reviewer that holds the story of the task confirms the story instead of judging the code. If no reviewer subagent is available, the main session does the pass inline with the reviewer's checklist and gates, and the report says "blind review ran inline: not blind".

**Intent comparison.** Put the reviewer's "Intent (from the code)" paragraph next to the packet Goal and write one line for the report: `match | partial (<what the code does more or less than the Goal>) | mismatch (<what the code does not communicate>)`. A partial or a mismatch enters step 8 as a candidate.

### 7. Acceptance review

Delegate to the **dj-acceptance-reviewer** subagent: does the diff fulfill the packet's intent? Hard checks pass? Soft checks reasonable? Any scope drift or missing behavior? This is the one review that judges intent, not code beauty.

### 8. Filter, then fix

Nothing a reviewer returns is applied before the orchestrator filters it. **Stage 1** is the reviewers' output: the findings, Questions and "Couldn't verify" items of steps 5 to 7, plus a partial or a mismatch from the intent comparison. The same problem reported twice (a runtime finding and its structural twin, or a finding and a "Couldn't verify" item on the same path:line) is one candidate; a structural finding that cites touched code at path:line stands even when the map is missing. **Stage 2** is the orchestrator: it reads each candidate against the packet, the scout result and the architecture file, and gives it exactly one outcome:

- **Discard**, with the reason in one line: "the packet decides this in <section>", "protected by <path:line>", "out of this task's purpose". Every discard is listed in the report.
- **Apply**, when it is small and clear. A `Fix: auto` tag is a hint, not an order; a `Fix: human` item is never applied without the human's yes. A Question or a "Couldn't verify" item reaches the fix list only after the orchestrator answers it from the packet, the scout result or a file it opened, and the report line shows that answer; without an answer it goes to the human.
- **To the human**, in the report, when it changes logic, needs a decision or is a redesign. When it is real but outside this task's scope, the report line points to a new entry in `features/<feature>/follow-ups.md` (created from `templates/follow-ups.md` of the dj-plan skill on first use).

**One fix list** goes to **dj-implementer** with the applied items only: no new decisions, no refactor beyond them; it re-runs the affected validation (inline only as degradation). The reviewers do not run again on the fixes: re-reviewing is how a fix step turns into a second run. A second round happens only for what the first round broke or left undone, and it is shorter than the first; after the second round, whatever remains goes to the human in the report and the loop stops. Do not expand scope to satisfy a reviewer.

### 9. Report, guide, and hand off

**REQUIRED SUB-SKILL:** dj-task-report — produce the compact report (format at the end of this file) and save the same content to `.dj-agents/repos/<repo>/features/<feature>/reports/T-XX.md`.
**Guide step:** delegate to the **dj-guide-writer** subagent (contract in the **dj-guide** skill) to append this task's section to `.dj-agents/repos/<repo>/features/<feature>/guide.md` — pass it the packet path, the commit range, and the report path. Inline as degradation. Scale detail by work mode: full on `production-work`, minimal on `personal-small`.
**REQUIRED SUB-SKILL:** dj-commit-message — suggest a commit message matching the repo's convention.

The human reviews the diff, the report, and the guide, then commits (unless commit policy says otherwise). Declare the task's end state.

## Review rigor by work mode

Read the mode from `.dj-agents/repos/<repo>/project.md`. Guidance, not law — the human can dial it either way per task.

| Work mode | Steps 5–7 |
|---|---|
| `production-work` | All three: test audit + blind review + acceptance review |
| `personal-medium` | Test audit + acceptance review |
| `personal-small` | Acceptance review only (or none, if project.md says so) |

Within a mode, no step of 5 to 7 is skipped for the size of the task or the zone of the code; a diff with nothing to review comes back as "Nothing to report".

Validation (step 4) never scales down — commands listed in the packet always run.

## Skipping steps

If a step is obviously unnecessary for this task — scout for a one-line change in a file you just edited, test audit for a docs-only task — skip it **and say so in the report**: "Skipped step 2 (scout): packet lists all context and the area was mapped in T-01." Visibility over ceremony. Silently skipping is the failure mode; skipping with a stated reason is the system working.

Step 6 is never skipped in a mode that runs it: a docs-only or one-line diff still goes to the blind reviewer.

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
| `obsolete` | Direction changed; task no longer makes sense | Mark obsolete in the plan, the packet and the feature's `state.md` |

Any drift — even under `done-with-drift` — gets a drift-log entry via **dj-drift-management** so future tasks and the spec stay honest.

## Commit policy

Default (from `.dj-agents/repos/<repo>/project.md`, `commit_policy: human-only`):

- No automatic commit. No push. No automatic PR. No co-author lines.
- Suggest `type(scope): message` after checking `git log --oneline -n 20` for the repo's actual convention (**REQUIRED SUB-SKILL:** dj-commit-message).
- Autonomous commits only when the user explicitly enables them, e.g. `/dj-task T-01..T-04 --autonomous` — and even then, one commit per task, message per convention.

This policy governs the client repository only; `.dj-agents/` is the user's own folder, and the close commits there under its own key, `dj_agents_commit` (last item of the close checklist).

## Closing the task: state and session

When a task closes (any end state), follow this checklist in order. State files are rewritten, never appended: each one holds only what is active after this close. Templates: `skills/dj-start/templates/feature-state.md`, `current.md`, `handoff.md`.

1. **Packet.** In `T-XX.md`, set `Status:` to the end state and fill the one-line `Outcome:`. A fresh session reading the packet must see the truth without this conversation.
2. **Feature state.** Rewrite `.dj-agents/repos/<repo>/features/<feature>/state.md` from its template: active mode, current phase, current task and the next one, current direction, "Do not follow", recent changes that are still active, read first.
3. **Index.** Rewrite this feature's line in `.dj-agents/repos/<repo>/current.md` (phase, current task, next action) and its `Rewritten:` line. Add the line when the feature starts; remove it when the feature closes. The index holds nothing else.
4. **Handoff.** Rewrite `.dj-agents/repos/<repo>/handoff.md` from its template: last real state (and what was verified), next step, not verified, do not rely on. Do it at every task close, not only when the session is ending: the orchestrating session must stay disposable at all times. Never append the previous handoff below.
5. **Map lines.** Propose one to three map lines this task taught: a rule learned, a gotcha, a flow traced, a term. Sources: the human's corrections, the reviewers' findings, the scout's flow and opportunity candidates. Write them as one inbox entry, `knowledge/inbox/<YYYY-MM-DD>-T-XX-<feature>.md`, in the routing-table format of `templates/knowledge/inbox-entry.md` in the dj-map skill (`Source kind: task close`): each line with its provenance (`verified in code <file:line, date, sha>`, `said by someone <date>` or `explained by the agent <date>`) and a destination (`review/rules.md`, `architecture/<repo>.md`, `flows/<slug>.md`, `glossary.md`, `decisions.md`, `library/`). The entry also carries one row per step 8 discard whose reason is a protection in code: the flagged shape as a pattern and its protection, destination `review/false-positives.md`, provenance `verified in code <file:line, date, sha>` when the orchestrator opened the protection, otherwise `explained by the agent <date>`. These rows do not count toward the one to three map lines, and they go through the same approval stop. A discard whose reason is the packet or the spec stays in the report only: it is a decision of this task, not a shape of false positive. Show the table and stop: the human approves in the same close ("apply all", edit destinations, or drop rows with a reason), and nothing reaches the map before that. A line for `review/rules.md` that comes from a single occurrence is marked "one comment, not yet a rule" and needs its own yes: "apply all" does not cover it, and once confirmed the rule text is written clean with the marker in the Evidence column. Apply what was approved by each destination's update rule, with its provenance; what was not approved stays in the entry as `left: <reason>`, and the entry moves to `inbox/processed/` once no row is pending. When the task taught nothing, say "none" and write no entry: proposing lines to look thorough fills the map with noise.
6. **Drift log.** If direction changed, add an entry to `features/<feature>/drift-log.md` (**dj-drift-management**).
7. **Next task.** Mark it in the delivery plan and in `state.md`.
8. **Nothing is discarded, it moves.** Anything that leaves a state file in steps 2 to 4 goes to a named destination before it is removed: task detail to the packet (`Outcome:`) or the report (`features/<feature>/reports/T-XX.md`); decisions, dead ideas and feature history to `features/<feature>/` (drift log, spec, follow-ups); anything not yet classified to the knowledge inbox once it exists. It is never deleted and never appended as a "Previous" block.
9. If the same human correction has now appeared more than once across tasks, propose making it structural instead of trusting memory, in one of three destinations: a rule in `knowledge/architecture/<repo>.md` (where code goes, which layer may call which), a constraint in `project.md`, or a lint rule or test when a machine can check it.
10. **Commit inside `.dj-agents/`.** If `project.md` has `dj_agents_commit: auto` (the default, also when the key is missing) and `.dj-agents/` is a git repository of its own (`<root>/.git` exists; a parent repository does not count), commit inside it, with `<root>` from `dj-root root`: `git -C <root> add -A && git -C <root> commit -m 'T-XX <repo>/<feature>: <end state>'`. This never touches the client repo's commit policy. With `human-only`, leave the changes uncommitted and say so in the report.

Context guidance (judgment, not thresholds-as-law):

| Context used | Guidance |
|---|---|
| 0–50% | Continue normally |
| 50–75% | Continue if the work is cohesive; run the close checklist when closing tasks |
| 75–85% | Close the current slice, run the close checklist, open a fresh session |
| 85%+ | Don't start a new task — summarize, close, hand off |

Before opening a fresh session, `handoff.md` must state the last real state, the next step, what is not verified, and **what must NOT be relied on anymore**, so the new session never obeys a dead spec.

## Common mistakes

- **Implementing in the orchestrating session with dj-implementer installed** — the orchestrator plans, delegates, reviews, and reports; it does not write code. Inline implementation is a degradation path, not a choice.
- **Expanding scope because a reviewer suggested it** — reviewers surface findings; the packet defines scope. Bigger findings go in the report.
- **Claiming validation passed without reading output** — "should pass" is not evidence. Paste real results.
- **Silently absorbing drift** — if reality differed from the packet, say so and log it, even when the outcome is fine.
- **Running all reviewers on a personal-small project** — ceremony without payoff. Scale down and say you did.
- **Fixing an out-of-scope bug "while you're here"** — report it; fixing it is a separate task (or a `/dj-fix`).
- **Appending a "Previous" block to `current.md` or `handoff.md` instead of rewriting them**: history moves to the packet, the report or the feature folder; the state files hold only what is active.
- **Handing the blind reviewer the packet or the scout "for context"**: the hand-off of step 6 is the whole prompt; the orchestrator holds the story and filters in step 8.
- **Re-running the reviewers on the fixes or starting a third round**: one fix list, at most two rounds, then the rest goes to the human.
- **Starting T-05 at 90% context** — close the session properly instead; the handoff costs 5 minutes, a contaminated session costs the task.

## Report format

Per **dj-task-report** (the canonical format and full example live there). Sections, in order:

```text
<T-ID>: <end state>
Changes · Validation · Self-review · Review filter · Skipped steps · Acceptance ·
Out of scope · Review order · Suggested commit · Walkthrough (on request)
```

Readable in 2 minutes; drop empty sections. The Walkthrough (goal in one line, data-flow map, core files function by function) is produced only when the user asks or when the Report style section of `.dj-agents/repos/<repo>/project.md` says `Walkthrough: always`.
