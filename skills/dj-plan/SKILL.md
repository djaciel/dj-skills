---
name: dj-plan
description: "Use when a feature intent, brief, or brain-dump needs to become a living spec with phases and task packets, or when drift has invalidated part of an existing plan (/dj-plan --replan-from T-XX). Applies after /dj-start on new projects, after /dj-map for features in existing repos, or whenever tasks no longer match current intent."
---

# Plan

## Overview

Turn intent into a living spec hierarchy: Feature Spec → Phase → Task Packet → Acceptance Review → drift/replan when needed. Specs serve construction; they get updated when reality disagrees with them, never worshipped.

**Announce at start:** "I'm using the dj-plan skill to plan <feature>." (or "... to replan <feature> from T-XX.")

## When to use

- After /dj-start produced a brief and focused discovery for a new project.
- After /dj-map produced a codebase map for a feature in an existing repo.
- When the human brings an intent that needs a spec, phases, and tasks before implementation.
- Replan mode: `/dj-plan --replan-from T-XX` when drift invalidated part of the plan.

When NOT to use:

- A trivial change the human can describe as a single task — write one task packet directly, or just do it.
- A bug fix → /dj-fix.
- Real uncertainty between competing approaches → /dj-explore first, then come back here.

## Inputs

Layout and root resolution: `skills/dj-start/templates/dj-agents-layout.md`; resolve `<area>` with the `dj-root` script.

If `dj-root repo` fails or prints a path that does not exist yet, or the area has no `project.md`, stop and tell the human to run `/dj-start --adopt` first (it fills the base files an existing area is missing).

Read before planning, in this order:

1. `.dj-agents/repos/<repo>/current.md` (the index of active features) and, for an existing feature, its `features/<feature>/state.md` (direction and "Do not follow"). Never plan against stale intent.
2. `.dj-agents/repos/<repo>/project.md` — work mode (`human_loop`, `commit_policy`, `pr_policy`), stack, constraints.
3. The knowledge map (`dj-root knowledge` prints its path), in this order: `knowledge/index.md`, `knowledge/architecture/<repo>.md`, `knowledge/patterns/<repo>/` (the capabilities the feature touches), `knowledge/flows/` (the flow the feature touches), `knowledge/glossary.md` (canonical terms for the spec), `knowledge/decisions.md` and `knowledge/questions.md` (never re-ask a question that already has an answer). If the repo has no architecture file, say so in the plan ("no architecture map; run `/dj-map --architecture` or accept the risk") and still plan.
4. `.dj-agents/repos/<repo>/features/<feature>/brief.md` and `discovery.md`, if they exist.
5. `.dj-agents/repos/<repo>/features/<feature>/codebase-map.md`, if it exists. If the area is unfamiliar and there is no map, run /dj-map first.
6. `.dj-agents/repos/<repo>/features/<feature>/follow-ups.md`, if it exists: its open entries are findings earlier tasks left for later packets.

If something essential is missing, ask at most 3–5 **blocking questions** — questions whose answers change planning decisions, not checklist questions.

| Bad question | Good question |
|---|---|
| "Is this an MVP or a POC?" | "Is this first version code you will keep and build on, or disposable if it only validates the idea?" |
| "Who are the users?" | "Will only you use this, or teammates/clients? That changes how much we invest in UX, errors, docs, and tests." |

Everything else becomes an assumption listed in the spec for the human to correct.

## Delegation

Delegate drafting to the **dj-planner** subagent: pass it the inputs above **plus the contents (or absolute paths) of this skill's templates**: `templates/feature-spec.md`, `templates/phase.md`, `templates/task-packet.md`, `templates/pr-strategy.md`, `templates/drift-log.md`, `templates/follow-ups.md`, since the subagent cannot see this skill's folder on its own. Let it produce the spec, delivery plan, task packets, and PR strategy. dj-planner writes only inside `.dj-agents/` and never edits source code.

If the dj-planner subagent is not available, do the planning inline in the main session, following the same rules and templates.

## Outputs

All under `.dj-agents/repos/<repo>/features/<feature>/`:

| File | Template | When |
|---|---|---|
| `spec.md` | `templates/feature-spec.md` | Always |
| `delivery-plan.md` | `templates/phase.md`, one section per phase | Always |
| `tasks/T-01.md`, `tasks/T-02.md`, ... | `templates/task-packet.md`, one file per task | Detailed tasks only |
| `pr-strategy.md` | `templates/pr-strategy.md` | When `pr_policy` is not `none` |
| `drift-log.md` | `templates/drift-log.md` | Initialize empty on first plan |
| `follow-ups.md` | `templates/follow-ups.md` | Created by dj-task on the first out-of-scope finding |

Then create or rewrite `.dj-agents/repos/<repo>/features/<feature>/state.md` (template: `skills/dj-start/templates/feature-state.md`) with the active mode, current phase and next task, and add or rewrite the feature's line in the `.dj-agents/repos/<repo>/current.md` index.

## Plan detailed vs sketch

Do not generate 20 tasks and treat them as sacred. Plan like a good product roadmap:

- **Detailed:** the current phase and its next 3–6 tasks, with full task packets.
- **Sketch:** future phases as a goal plus approximate task bullets inside `delivery-plan.md`. No task packets yet.

Do not detail Phase 3 while Phase 1 might still change the approach. Detail the next phase when the current one closes.

## Phases read like PRs

When `pr_policy` applies, a phase should normally look like a reviewable PR. Every phase gets a **review story**: the ordered list of files or concepts a reviewer reads to understand it. If you cannot write the review story, the phase is probably wrong-sized or mixing concerns.

## Task sizing

A good task packet has:

- 1 conceptual objective;
- ~1–5 core files;
- a vertical slice: it leaves something verifiable end to end, however thin — never one horizontal layer of many ("all the schema, then all the API, then all the UI");
- clear validation commands;
- human review possible in 10–20 minutes;
- no mixing of foundation + UI + docs + cleanup + huge test suites;
- self-sufficiency: read-first paths, the relevant spec excerpt and its Placement, never the full spec pasted. A fresh subagent must be able to execute it reading only the packet and the files it points to.

| Example | Verdict |
|---|---|
| "Add recovery handling to the SDK funding flow when account linking fails after token creation." | Good — one objective, reviewable |
| "Implement the full funding flow." | Too big — split into phases and tasks |
| "Create enum. Export enum. Import enum. Use enum." | Too small — merge into one task |
| "Create all the DB tables for the module." | Horizontal — re-slice so each task proves one flow end to end |

When a packet protects an existing path, say what is protected: observable behavior, or the code itself. "Same responses, same errors" is a behavior promise and permits refactoring the shared parts. "Do not edit this function" is a code promise and needs its own reason, because it forbids the cheapest fix for the duplication the new path may create.

Never enforce a rigid file count: a task may touch more files when most are tests, config, or mechanical changes. The question that decides: **"Does this task leave something reviewable, verifiable, and aligned with current intent?"**

## Acceptance checks — living, 4 levels

Every task packet classifies its checks:

| Level | Meaning | Example |
|---|---|---|
| Hard | Must pass | Typecheck passes; existing success flow still works; do not modify the widget in this task |
| Soft | Desirable, apply judgment | Follow the existing Result pattern; keep error naming consistent |
| Exploratory | May change during execution | UX should feel clear during manual review |
| Deferred | Matters, but belongs to a later task | Public docs will be updated in a later task |

Acceptance checks are living contracts: they can change, but consciously — through a drift-log entry — never by silently ignoring them.

## PR strategy is a hypothesis

**REQUIRED SUB-SKILL:** dj-pr-slicing — apply it when drafting `pr-strategy.md`. If it is not available, plan from the judgment question below. The strategy must:

- answer "does each PR tell a reviewable story?" — never argue from file counts (a 30-file PR can be fine when 5 files are core and there is a clear review map);
- classify files: core / tests / config / mechanical / generated / docs;
- name a **re-evaluation checkpoint** after an early task (usually T-03 or T-04): re-check actual files touched, conceptual vs mechanical change, and whether the PR count still makes sense.

## Replan mode — `/dj-plan --replan-from T-XX`

**REQUIRED SUB-SKILL:** dj-drift-management — the drift should already be captured in the drift-log before replanning.

1. Read the latest `drift-log.md` entry. If there is none, write one first (original / new direction / why / impact / action).
2. Keep everything still valid: completed tasks, future tasks that survive, spec sections that still hold. Never restart from zero.
3. Mark obsolete tasks: set their status to `obsolete` in their packet and in `delivery-plan.md`. Do not delete the files — history stays traceable.
4. Update `spec.md` if intent changed: assumptions, constraints, out-of-scope.
5. Recalculate future tasks from T-XX onward. Give new tasks fresh numbers continuing the sequence.
6. Re-check `pr-strategy.md` — drift often changes the reviewable story.
7. Rewrite `.dj-agents/repos/<repo>/features/<feature>/state.md`, including a "Do not follow" note pointing at superseded docs, so old specs never override the new direction; then rewrite the feature's line in the `current.md` index.

## Human checkpoint

Present the plan before any implementation: spec summary, phase list, the detailed task packets, Architecture fit (tasks that deviate from the map, as open questions), PR strategy, and open assumptions. Scale ceremony to work mode: for `personal-small` a compact summary is enough; for `production-work` walk the human through the review story. The human approves, adjusts, or answers open questions, and confirms or clears each packet's `Learn:` line; each answer to a blocking question is added to `knowledge/questions.md` with the decision it unblocked, following that file's update rule. Then hand off to /dj-task for execution.

## Common mistakes

- Detailing every phase upfront — Phase 3 detail is fiction until Phase 1 survives contact with reality.
- Sizing tasks by file count instead of reviewability.
- Marking every acceptance check Hard — when everything is hard, judgment disappears and drift becomes invisible.
- Replanning by regenerating everything — you lose completed context and the human's earlier corrections.
- Treating the PR strategy as dogma — it is a hypothesis with a checkpoint; revise it when evidence arrives.
- Planning without reading the index and the feature's `state.md` first — plans built on stale state create instant drift.
- Writing the why as a technical restatement of the goal instead of the business reason.
