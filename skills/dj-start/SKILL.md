---
name: dj-start
description: "Use when starting a NEW project from scratch: the user arrives with an idea, brain-dump, notes, links, or a pasted conversation with another AI, and no work area exists for it under .dj-agents/ yet. Use with --adopt when an existing repository has no repos/<repo>/ area under .dj-agents/ yet. Not for a repository that already has its area (use dj-map to understand the code, dj-plan to plan work)."
---

# Starting a New Project

## Overview

Turn a raw idea dump into working project memory: extract what the user already knows, ask only what blocks real decisions, set the work mode and language policy, and leave `.dj-agents/` ready for planning.

**Core principle:** Smart intake, not a questionnaire. Read what the user brings, infer everything you can, and ask at most 3–5 questions — only the ones planning would get wrong without.

**Announce at start:** "I'm using the dj-start skill to set up this project."

## When to use

Layout and root resolution: `skills/dj-start/templates/dj-agents-layout.md`; resolve `<area>` with the `dj-root` script.

- A new project starts from an idea, notes, restrictions, links, or a pasted brainstorming conversation with another AI.
- The project has no `repos/<repo>/` area under `.dj-agents/` yet (the root itself may already exist next to other repositories).
- An existing repository with no `repos/<repo>/` area under `.dj-agents/`: `/dj-start --adopt`.

When NOT to use:

- First contact with an existing codebase → map it with the **dj-map** skill after adopting it.
- New feature or scope change in a project that already has `.dj-agents/` → use the **dj-plan** skill.
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

These live in `.dj-agents/repos/<repo>/project.md` and are echoed into every task packet later — the mode is written down, not remembered.

### 4. Set the language policy

Detect (or ask, if genuinely ambiguous) the language the user converses in — that is the **internal language**. The **external language is always English**: code, comments, tests, commits, PRs, tickets, anything that leaves the user's machine. Also set the **external English level**: `simple (B1/B2)` — plain words, short sentences; the right default when teammates read English as a second language — or `natural`. It is a writing register, never a facts filter. Write `.dj-agents/repos/<repo>/language-policy.md` from `templates/language-policy.md`.

### 5. Generate the base files (new project and adopt)

Generate the minimal set — planning documents come later, from dj-plan. Default feature name for a new project: `main`. Adopt mode creates no feature.

| File | Template | New project | Adopt | Purpose |
|---|---|---|---|---|
| `.dj-agents/repos/<repo>/project.md` | `templates/project.md` | yes | yes | Stable context: stack, commands, constraints, work mode. |
| `.dj-agents/repos/<repo>/current.md` | `templates/current.md` | yes, one index line for `main` | yes, with no active feature | Index of active features, always read first. |
| `.dj-agents/repos/<repo>/features/main/state.md` | `templates/feature-state.md` | yes | no | The feature's active state: direction, "Do not follow", next task. |
| `.dj-agents/repos/<repo>/handoff.md` | `templates/handoff.md` | yes | yes, empty state | Session-to-session handoff (starts nearly empty). |
| `.dj-agents/repos/<repo>/language-policy.md` | `templates/language-policy.md` | yes | yes | Internal vs external language rules. |
| `.dj-agents/repos/<repo>/features/main/brief.md` | `templates/brief.md` | yes | no | What to build, for whom, which problem — plus assumptions. |
| `.dj-agents/repos/<repo>/expertise-registry.md` | `templates/expertise-registry.md` | optional | optional | Optional — only if the user wants to wire external skills per stack. |

Do not front-load fifteen documents. Spec, delivery plan, task packets and PR strategy belong to dj-plan.

### 6. Focused discovery

**Rule: discovery only investigates decisions that affect real construction.** Not the whole stack, not "evaluate everything", no infinite research.

Write `.dj-agents/repos/<repo>/features/main/discovery.md` from `templates/focused-discovery.md`. Its core is one table:

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

## Adopt mode (`--adopt`)

`/dj-start --adopt` gives an existing repository its `repos/<repo>/` area. Run it from inside the repository. It reads the repository and writes only under `.dj-agents/`; nothing is written inside the client repository (no files, no branches, no `git fetch`).

1. **Resolve the root.** Run `dj-root`. If it prints a root, use it. If it exits 1, ask one question with a default: "Where should `.dj-agents/` live? Default: `<parent of the repository>`" (the parent of the main checkout, the directory that owns `git rev-parse --git-common-dir`, so a worktree or a subdirectory does not move it). Then create `.dj-agents/knowledge/` and `.dj-agents/repos/` there, each with a `.gitkeep`, run `git init` inside `.dj-agents/`, and make a first commit with those two directories ("Initialize .dj-agents"). A root that exists without its own `.git` gets the same `git init` and first commit.
2. **Resolve the repo name.** Run `dj-root name`. Exit 2 means the session is not inside a git repository: stop and say so. If `.dj-agents/repos/<repo>/` already exists, stop: "already adopted; edit `project.md` by hand".
3. **Detect from the repository, not from memory.** Stack and commands from the manifests that exist (`package.json` scripts, `mix.exs` aliases, `pyproject.toml`, `Makefile` targets, CI config under `.github/workflows/` or similar). Quote each command as the manifest defines it and keep its source file. Branching from `git branch -a` and `git log --oneline -n 30` (naming convention, merge style). The base branch from the remote HEAD (`git symbolic-ref --short refs/remotes/origin/HEAD`); with no remote, the current branch, listed as an assumption.
4. **Ask only what the repository cannot answer**, at most 3 to 5 blocking questions, in one message: project type and work mode (`human_loop`), `commit_policy`, `pr_policy`, internal language and external English level. Skip any the conversation already answers. Everything else becomes an assumption.
5. **Write the base files** under `.dj-agents/repos/<repo>/` from the templates (table in step 5 above): `project.md` (detected values, each command with its source file, and every unconfirmed value under "Assumptions (correct me)"), `language-policy.md`, `current.md` (from the index template, with no feature line) and `handoff.md` (from its template; last real state: adopted, nothing implemented yet).
6. **Do not create a feature.** The human creates `.dj-agents/repos/<repo>/features/<feature>/init.md` and runs `/dj-plan` with that path.
7. **Commit inside `.dj-agents/`**: `git -C <root> add repos/<repo>` and `git -C <root> commit -m "Adopt <repo>"`. The client repository's commit policy does not apply here, and no commit is made in it.
8. **Report** with the adopt variant of the Output block: paths written, detected values with their source, assumptions to correct, next step (`/dj-map <area>` for unfamiliar ground, or `/dj-plan` once a feature's `init.md` exists).

## Common mistakes

- **Questionnaire mode** — asking blocks of questions the idea dump already answers. Extract first, ask last.
- **Label questions** — "MVP or POC?" is ambiguous and useless; the work mode captures what actually matters (human control, quality bar, PRs, commit rights).
- **Infinite discovery** — researching things that don't change what gets built next.
- **Giant spikes** — a spike that builds 80% of the app is an implementation phase in disguise; a spike that installs a huge project "just to try one thing" is not justified.
- **Skipping the language policy** — it must be a written contract, or later output arrives in the wrong language.
- **Treating the original brain-dump as an active source** — after intake, the pasted conversation is archive material; the feature's `state.md` and the brief are the truth.
- **Adopting by copying rules from memory instead of reading the manifests and the git history**: every command and branching value in an adopted `project.md` has a source in the repository, or it is listed as an assumption.
- **Writing anything inside the client repository**: adopt mode reads the repository and writes only under `.dj-agents/`.

## Output

Close with a report to the user (in the internal language), covering:

```text
Project set up: <name>

Mode: personal-medium (human_loop: checkpoint, commit_policy: human-only, pr_policy: none)
Language: internal <language> / external English

Generated:
- .dj-agents/repos/<repo>/project.md
- .dj-agents/repos/<repo>/current.md
- .dj-agents/repos/<repo>/handoff.md
- .dj-agents/repos/<repo>/language-policy.md
- .dj-agents/repos/<repo>/features/main/state.md
- .dj-agents/repos/<repo>/features/main/brief.md
- .dj-agents/repos/<repo>/features/main/discovery.md

Assumptions I made (correct me):
1. <assumption>
2. <assumption>

Key discovery decisions: <one line each, from the table>
Proposed spikes: <list with time/file budgets, or "none">

Next: run /dj-plan to generate the spec, delivery plan and task packets.
```

Adopt variant (`--adopt`):

```text
Repository adopted: <repo>

Root: <path>/.dj-agents (created now | existing)
Mode: <project type> (human_loop: <task | checkpoint | phase>, commit_policy: <policy>, pr_policy: <policy>)
Language: internal <language> / external English (<simple (B1/B2) | natural>)

Generated:
- .dj-agents/repos/<repo>/project.md
- .dj-agents/repos/<repo>/language-policy.md
- .dj-agents/repos/<repo>/current.md
- .dj-agents/repos/<repo>/handoff.md

Detected (source):
- test: <command> (package.json)
- base_branch: <branch> (origin/HEAD)

Assumptions I made (correct me in project.md):
1. <assumption>

Committed in .dj-agents/: "Adopt <repo>". Nothing written inside the repository.

Next: create .dj-agents/repos/<repo>/features/<feature>/init.md and run /dj-plan with it; run /dj-map <area> first if the ground is unfamiliar.
```

Signal over ceremony: if the project is tiny and a step is obviously unnecessary (e.g. no discovery decisions exist), say so in the report and skip it — don't perform empty sections.
