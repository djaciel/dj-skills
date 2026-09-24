---
name: dj-map
description: Use when starting work in an existing repository for the first time, when planning a feature that touches an unfamiliar area of the codebase, or when returning to a repo after long enough that the mental model has gone stale. Run before /dj-plan when the ground is unfamiliar.
---

# Codebase Mapping

## Overview

Build a compact, actionable map of the code you are about to touch — a reading order, not an encyclopedia. The map exists so planning and implementation reuse what the repo already has instead of reinventing it.

**Announce at start:** "I'm using the dj-map skill to map <area/feature or the whole repo>."

## When to use

- First session in an existing repo, before planning anything.
- Planning a feature in an area of the repo you have not worked in.
- Returning to a repo after a long absence, when your picture of it is stale.

If `dj-root repo` fails or prints a path that does not exist yet, stop and tell the human to run `/dj-start --adopt` first.

When NOT to use:

- Greenfield projects — there is nothing to map yet; use /dj-start.
- Areas you know well and worked in recently — go straight to /dj-plan.
- As a substitute for per-task context gathering — /dj-task handles that with a scoped scout pass.

## Scope and output location

| Scope | Command | Output |
|-------|---------|--------|
| Feature/area map (default) | `/dj-map <area-or-feature>` | `.dj-agents/repos/<repo>/features/<feature>/codebase-map.md` |
| Whole-repo map | `/dj-map --repo` | `.dj-agents/repos/<repo>/codebase-map.md` |

Prefer the feature-scoped map. A whole-repo map is worth writing on first contact with a codebase or for small repos; for anything large it goes stale fast and reads like documentation nobody asked for.

## The process

### Step 1: Frame the scope

Layout and root resolution: `skills/dj-start/templates/dj-agents-layout.md`; resolve `<area>` with the `dj-root` script.

If `dj-root repo` fails or prints a path that does not exist yet, stop and tell the human to run `/dj-start --adopt` first.

1. If `.dj-agents/repos/<repo>/current.md` exists, read it first — it may already say what the upcoming work is.
2. Establish the consumer of the map: what feature or decision must this map serve? If unclear, ask the user one question. A map without a consumer becomes an encyclopedia.
3. Decide: feature map or whole-repo map.

### Step 2: Explore

Delegate exploration to the **dj-scout** subagent with a concrete brief, for example:

> "Map everything relevant to adding <feature> in <area>: entry points, the files that would change, existing patterns to follow, reusable utilities, test fixtures, and anything fragile nearby. Return paths with one-line reasons, plus a suggested reading order."

The scout returns a compact Scout Result (paths with one-line reasons). The map is the durable distillation of that result — do not paste raw exploration output into it.

If the dj-scout subagent is not available, do the exploration inline in the main session with Glob/Grep/Read — same brief, same compact output discipline. A reliable inline order:

1. Entry points and routing/config for the area (how requests/inputs reach it).
2. One or two features similar to the upcoming work — the strongest source of patterns.
3. Shared utilities and types the area imports.
4. The area's tests and fixtures.

The map must identify, for the scoped area:

| Dimension | What to capture |
|-----------|-----------------|
| Stack | Language, framework, tooling — only what affects the work |
| Repo zones | Top-level areas and their roles, with relevance to this work |
| Relevant files | Each with a one-line "why it matters" |
| Commands | Install, run, build, test, lint/typecheck |
| Tests | Framework, location convention, how to run one file |
| Existing patterns | Conventions the new code must follow, with where they live |
| Existing utilities | Code to reuse instead of rewriting |
| Existing fixtures | Test helpers/factories/mocks already available |
| Risks | Fragile areas, implicit coupling, missing tests, generated code |

### Step 3: Verify commands

Confirm commands from real sources (`package.json` scripts, `Makefile`, CI config, README) rather than guessing. When cheap, actually run the low-risk ones (lint, typecheck, listing tests) and mark them verified. A map that lists commands that don't work is worse than no map.

### Step 4: Write the map

Write the map using `templates/codebase-map.md` to the location from the table above.

Compactness rules:

- Every file listed earns its line with a one-line reason. No reason, no entry.
- Suggested reading order: 5–10 items, most-load-bearing first.
- Risks are things that could bite the upcoming plan — not generic warnings.
- If a section has nothing worth saying, write "None found" rather than padding it.

Example of the difference a reason makes:

```text
Weak:   - `src/billing/invoice.service.ts`: invoice service
Strong: - `src/billing/invoice.service.ts`: owns invoice state transitions — the new status lands here
```

Target: the whole map readable in under 5 minutes.

Scale depth by work mode (from `.dj-agents/repos/<repo>/project.md`, guidance not law): for `personal-small`, relevant files + commands + patterns may be enough; for `production-work`, fill every section including risks and fixtures.

### Step 5: Hand off

1. Summarize the map to the user in 5–10 lines: stack, the 2–3 most important findings, the top risk.
2. Point to the next step: `/dj-plan <feature>` consumes this map to produce the spec and tasks.
3. Note that the map was created, and where, in the feature's `features/<feature>/state.md` (Read first); if no feature exists yet, in the `.dj-agents/repos/<repo>/current.md` index line for the upcoming work, if the index exists.

## Refreshing an existing map

When a map already exists for the area:

1. Read it before exploring — verify its claims instead of rediscovering them.
2. Update in place: remove stale entries, add what changed, keep the reading order current.
3. Note the refresh date at the top of the Scope section.
4. If the old map is mostly wrong (big refactor since), rewrite it and say so to the user.

## Knowledge-graph tools (optional)

Tools like knowledge-graph indexers are optional aids, never a default. Consider one only when:

- the repo is large and plain search keeps missing connections;
- exploration keeps getting lost;
- there are many symbols/imports to trace and a graph would genuinely save time.

For small and medium projects, Glob/Grep/Read exploration is the default and is enough.

## Common mistakes

- **Encyclopedia map** — dumping every directory and file. The map serves the next piece of work; cut everything else.
- **Mapping without a consumer** — "map the repo" with no upcoming work in mind produces shelf-ware. Frame the scope first.
- **Guessed commands** — copying commands from memory or convention instead of the repo's own config. Verify.
- **Skipping patterns and fixtures** — the most valuable sections are the ones that prevent reinvention. Stack and zones alone are not a map.
- **Re-mapping known ground** — if the area is fresh in memory and `.dj-agents/` already has a recent map, update it instead of rewriting it.
- **Treating the map as frozen** — if implementation later contradicts the map, fix the map; it is working memory, not a spec.

## Output

After writing the map, report:

```text
Codebase map written: .dj-agents/repos/<repo>/features/<feature>/codebase-map.md
Scope: <area/feature it serves>
Highlights:
- <finding 1>
- <finding 2>
- <top risk>
Next: /dj-plan <feature>
```
