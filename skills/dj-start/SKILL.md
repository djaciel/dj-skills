---
name: dj-start
description: "Use when starting a NEW project from scratch — the user arrives with an idea, brain-dump, notes, links, or a pasted conversation with another AI, and no .agent/ directory exists yet. Not for existing codebases (use dj-map) or for planning work in a project that already has .agent/ context (use dj-plan)."
---

# Starting a New Project

## Overview

Turn a raw idea dump into working project memory: extract what the user already knows, ask only what blocks real decisions, set the work mode and language policy, and leave `.agent/` ready for planning.

**Core principle:** Smart intake, not a questionnaire. Read what the user brings, infer everything you can, and ask at most 3–5 questions — only the ones planning would get wrong without.

**Announce at start:** "I'm using the dj-start skill to set up this project."

## When to use

- A new project starts from an idea, notes, restrictions, links, or a pasted brainstorming conversation with another AI.
- There is no `.agent/` directory yet.

When NOT to use:

- First contact with an existing codebase → use the **dj-map** skill.
- New feature or scope change in a project that already has `.agent/` → use the **dj-plan** skill.
- A throwaway one-off script that needs no memory — just write it.

## The process

### 1. Intake

Read everything the user provides: notes, ideas, constraints, links, doubts, pasted conversations. Extract:

- Intent — what they actually want to exist.
- Problem — what hurts today.
- Constraints — platform, stack, budget, timeline, "must not" items.
- Risks and doubts — theirs and yours.
- External context — other repos, docs, or schemas this project depends on. Record them in `project.md` under "Related repos & context sources" so they never need re-explaining.

Reflect a compact intake summary back before asking anything:

```text
I understood this:
- You want to build a browser extension.
- Main user: you.
- Goal: automate X.
- Suggested mode: personal-small.
- PRs: no. Human loop: phase-level review.
- Language: internal Spanish, code/files English.

Blocking questions:
1. Should this run only locally, or sync data somewhere?
2. Is Chrome enough, or do you need Firefox too?
3. Is login/auth needed?
```

### 2. Blocking questions — 3 to 5, maximum

A blocking question is one whose answer changes architecture, scope, stack, cost, or core UX — planning would be wrong without it. Everything else becomes an **assumption**, written down for the user to correct.

Don't ask checklist questions. Ask questions that change a decision:

| Checklist question (don't ask) | Decision-changing question (ask) |
|---|---|
| Is this an MVP or a POC? | Do you expect this to be thrown away after validation, or should the first version be production-quality enough to keep building on? |
| Who are the users? | Is this only for your personal use, or will teammates/customers use it? That changes how strict we get with error handling, docs and tests. |

If the answer is already inferable from the dump, don't ask — infer it and list it as an assumption.

### 3. Set the work mode

Classify the project and recommend a mode; confirm with the user:

| Project type | human_loop | What it means in practice |
|---|---|---|
| personal-small | phase | No PRs, few documents, can work through a whole phase, human review at end of phase. |
| personal-medium | checkpoint | Grouped tasks, checkpoints every 2–4 tasks, reasonable tests, handoff on session close. |
| production-work | task | Human review per task, no automatic commits, mandatory tests/validations, internal review after each task, PR descriptions in English. |

Also set:

- `commit_policy: human-only | allowed-if-explicit | autonomous` — default **human-only**.
- `pr_policy: none | phase-as-pr | explicit-pr-strategy`.
- Branching: base branch, naming convention (`feat/<feature>`, `fix/<issue-id>`), and whether the agent creates branches or only suggests them. For an existing repo, detect the convention from `git branch -a` and recent history instead of inventing one.

These live in `.agent/project.md` and are echoed into every task packet later — the mode is written down, not remembered.

### 4. Set the language policy

Detect (or ask, if genuinely ambiguous) the language the user converses in — that is the **internal language**. The **external language is always English**: code, comments, tests, commits, PRs, tickets, anything that leaves the user's machine. Also set the **external English level**: `simple (B1/B2)` — plain words, short sentences; the right default when teammates read English as a second language — or `natural`. It is a writing register, never a facts filter. Write `.agent/language-policy.md` from `templates/language-policy.md`.

### 5. Generate the `.agent/` base files

Generate the minimal set — planning documents come later, from dj-plan. Default feature name: `main`.

| File | Template | Purpose |
|---|---|---|
| `.agent/project.md` | `templates/project.md` | Stable context: stack, commands, constraints, work mode. |
| `.agent/current.md` | `templates/current.md` | Active work state — always read first. |
| `.agent/handoff.md` | `templates/handoff.md` | Session-to-session handoff (starts nearly empty). |
| `.agent/language-policy.md` | `templates/language-policy.md` | Internal vs external language rules. |
| `.agent/features/main/brief.md` | `templates/brief.md` | What to build, for whom, which problem — plus assumptions. |
| `.agent/expertise-registry.md` | `templates/expertise-registry.md` | Optional — only if the user wants to wire external skills per stack. |

Do not front-load fifteen documents. Spec, delivery plan, task packets and PR strategy belong to dj-plan.

### 6. Focused discovery

**Rule: discovery only investigates decisions that affect real construction.** Not the whole stack, not "evaluate everything", no infinite research.

Write `.agent/features/main/discovery.md` from `templates/focused-discovery.md`. Its core is one table:

| Decision | Options | Recommendation | Evidence | Risk |
|---|---|---|---|---|
| Storage | localStorage vs IndexedDB | IndexedDB | structured data | medium |

Anything that doesn't block planning goes under "Things we are not deciding yet" — deciding late with more information is a feature, not a failure.

### 7. Spikes — only if small and justified

A spike answers one concrete technical question with the least code possible. It does not deliver product functionality, does not implement a whole module, and does not decide architecture by accident.

Every spike gets a spec from `templates/spike.md` with: a concrete question, a hypothesis, a success criterion, a time budget, a file budget, a disposable folder, and a clear conclusion.

If the spike would be large, stop and say exactly this:

```text
This is too large for a spike. Treat it as either:
1. a prototype phase, or
2. the first implementation phase.
```

Keep the vocabulary straight: **spike** = answer a small question · **prototype** = disposable working version · **production slice** = code that ships. Don't let a spike become the project.

### 8. Hand off to planning

**NEXT STEP:** the **dj-plan** skill. It turns `brief.md` + `discovery.md` into the feature spec, delivery plan, task packets and — if `pr_policy` requires it — a PR strategy. dj-start does NOT generate spec, plan or tasks itself.

If the dj-plan skill is not available, tell the user planning is the next step and offer to draft a minimal spec and task list inline — don't silently skip planning.

## Common mistakes

- **Questionnaire mode** — asking blocks of questions the idea dump already answers. Extract first, ask last.
- **Label questions** — "MVP or POC?" is ambiguous and useless; the work mode captures what actually matters (human control, quality bar, PRs, commit rights).
- **Infinite discovery** — researching things that don't change what gets built next.
- **Giant spikes** — a spike that builds 80% of the app is an implementation phase in disguise; a spike that installs a huge project "just to try one thing" is not justified.
- **Skipping the language policy** — it must be a written contract, or later output arrives in the wrong language.
- **Treating the original brain-dump as an active source** — after intake, the pasted conversation is archive material; `current.md` and the brief are the truth.

## Output

Close with a report to the user (in the internal language), covering:

```text
Project set up: <name>

Mode: personal-medium (human_loop: checkpoint, commit_policy: human-only, pr_policy: none)
Language: internal <language> / external English

Generated:
- .agent/project.md
- .agent/current.md
- .agent/handoff.md
- .agent/language-policy.md
- .agent/features/main/brief.md
- .agent/features/main/discovery.md

Assumptions I made (correct me):
1. <assumption>
2. <assumption>

Key discovery decisions: <one line each, from the table>
Proposed spikes: <list with time/file budgets, or "none">

Next: run /dj-plan to generate the spec, delivery plan and task packets.
```

Signal over ceremony: if the project is tiny and a step is obviously unnecessary (e.g. no discovery decisions exist), say so in the report and skip it — don't perform empty sections.
