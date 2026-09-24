---
name: dj-map
description: Use when starting work in an existing repository for the first time, when planning a feature that touches an unfamiliar area of the codebase, when returning to a repo after long enough that the mental model has gone stale, or when a repo needs its architecture written or refreshed for planning and review. Run before /dj-plan when the ground is unfamiliar.
---

# Codebase Mapping

## Overview

Build a compact, actionable map of the code you are about to touch — a reading order, not an encyclopedia. The map exists so planning and implementation reuse what the repo already has instead of reinventing it.

**Announce at start:** "I'm using the dj-map skill to map <area/feature, or the architecture of the repo>."

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
| Architecture of the repo | `/dj-map --architecture` | `.dj-agents/knowledge/architecture/<repo>.md` plus `.dj-agents/knowledge/patterns/<repo>/` |
| Architecture refresh | `/dj-map --architecture --refresh` | the same files, each recorded command re-run and marked `unchanged`, `changed` or `failed` |

The feature map is a reading order for one piece of work. There is no whole-repo codebase map: it went stale fast and read like documentation nobody asked for. What holds across the whole repo (layers, placement, invariants, deviations) lives in the architecture file, with evidence that `--refresh` re-runs. See "Architecture mode".

## The process

### Step 1: Frame the scope

Layout and root resolution: `skills/dj-start/templates/dj-agents-layout.md`; resolve `<area>` with the `dj-root` script.

If `dj-root repo` fails or prints a path that does not exist yet, stop and tell the human to run `/dj-start --adopt` first.

1. If `.dj-agents/repos/<repo>/current.md` exists, read it first — it may already say what the upcoming work is.
2. Establish the consumer of the map: what feature or decision must this map serve? If unclear, ask the user one question. A map without a consumer becomes an encyclopedia.
3. Decide: feature map, or architecture mode for rules that hold across the whole repo.

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

## Architecture mode

`/dj-map --architecture` writes the rules of one repo and the code that shows them, for planning and review in that repo. It is not a feature map: no reading order, no file list for one piece of work.

1. **Inputs.** Resolve the repo name with `dj-root name` and the destinations with `dj-root knowledge`: `<knowledge>/architecture/<repo>.md` and `<knowledge>/patterns/<repo>/`. Look for the repo's own docs (ARCHITECTURE, ADRs, CONTRIBUTING, agent instruction files such as CLAUDE.md or AGENTS.md); they are hypotheses to verify, never text to copy. Pass the absolute paths of this skill's `templates/knowledge/architecture.md` and `templates/knowledge/pattern.md` to the agent.
2. **Delegate** to the **dj-repo-mapper** subagent with a concrete brief, for example:

   > "Write the architecture of <repo> at <repo path> into <knowledge>/architecture/<repo>.md from <architecture template>, and one <knowledge>/patterns/<repo>/<capability>.md from <pattern template> for each capability seen at least twice. Read <docs found> as hypotheses to verify, never as text to copy. Record every command behind Derived; give every layer, boundary, seam, shared building block and invariant its command and result, and each invariant its denominator ("0 of 23 controllers"); count the call sites of any concern handled two ways and say which way is go-forward; anything you could not prove goes to Open questions. Do not touch the repository and write nowhere else. Reply with the confirmation only."

3. **Evidence rule.** Every layer, boundary, seam and invariant carries a command and its result, written next to the claim as `` (`command` → result) `` or in the Invariants table. A claim without a command goes to "Open questions" with its provenance label, never into the sections above it.
4. **Derived.** Top-level zones, the import or module graph summary (with the stack's own tool when it runs without writing to the repo, for example `mix xref graph --format stats` over an existing build; otherwise a grep of imports) and git hot spots come from commands the mapper records in the file, so `--refresh` re-runs exactly those lines. `Method:` says what the commands cannot see (macros, behaviours, dynamic imports).
5. **Deviations.** Framework conventions the repo breaks on purpose, and concerns handled by two mechanisms, each with the call-site count of both and which one is documented as go-forward (and where, or "nowhere"). "Multiple ways of doing the same thing" is the clue; the counts say which way the repo is moving.
6. **Patterns by capability.** One `patterns/<repo>/<capability>.md` per capability that appears in more than one place, with the exemplar snippet and its anchors. A capability seen once gets no file; the reply lists it as skipped.
7. **Refresh.** `--refresh` re-runs the Derived and Invariants commands (and the counts under Shared building blocks and Deviations), marks each `unchanged`, `changed` or `failed`, touches the narrative only where an invariant changed, and updates the Verified date and sha. When an invariant changed because the rule itself changed, move the old rule text to `knowledge/library/superseded-rules.md` with the date once the human confirms; the mapper does not write there.
8. **After writing.** Add or update the repo's line in `knowledge/index.md` (`- <repo>: architecture/<repo>.md, patterns/<repo>/`) and its `Rewritten:` date. If a feature is active in `repos/<repo>/current.md`, note the map in that feature's `state.md`.
9. **Degradation.** If the dj-repo-mapper subagent is not available, run the same steps inline in the main session with Glob/Grep/Read/Bash: same brief, same evidence rule, same two destinations, same confirmation to the human.

## Refreshing an existing map

When a map already exists for the area:

1. Read it before exploring — verify its claims instead of rediscovering them.
2. Update in place: remove stale entries, add what changed, keep the reading order current.
3. Note the refresh date at the top of the Scope section.
4. If the old map is mostly wrong (big refactor since), rewrite it and say so to the user.

The architecture file refreshes differently: `/dj-map --architecture --refresh` re-runs its recorded commands (see "Architecture mode", point 7).

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
- **Copying generic architecture theory instead of this repo's verified layout.** "Hexagonal" or "clean architecture" says nothing a command did not confirm in this repo.
- **Writing a boundary without the command that proves it.** No command, no boundary: it goes to Open questions.
- **Turning the architecture file into a file inventory.** That is the feature codebase-map's job; the architecture file holds rules, exemplars and counts.
- **Adding a lessons list.** Rules replace; the rule that stops applying moves to `library/superseded-rules.md`, and stories go to the library.

## Output

The templates for the shared map under `.dj-agents/knowledge/`, including the per-repo `architecture/<repo>.md` and `patterns/<repo>/`, live under `templates/knowledge/`.

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

After architecture mode, report:

```text
Architecture written: .dj-agents/knowledge/architecture/<repo>.md
Patterns: .dj-agents/knowledge/patterns/<repo>/<capability>.md, ... (skipped, seen once: <capability>, ...)
Invariants: <n> verified, <n> failed
Deviations: <n> found | none found
Open questions: <n>
Refresh (only with --refresh): <n> unchanged, <n> changed, <n> failed; Verified <old> to <new>
Next: /dj-plan <feature>
```
