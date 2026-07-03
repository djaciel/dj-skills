---
name: dj-pr-slicing
description: "Use when deciding PR boundaries — planning how a feature will land as pull requests, judging whether a grown branch should ship as one PR or several, or when pr_policy requires an explicit PR strategy for a feature."
---

# PR Slicing

## Overview

A PR boundary is judged by one question — **"Does this PR tell a reviewable story?"** — never by file count. A PR strategy is a revisable hypothesis with a re-evaluation checkpoint, not an eternal contract.

## When to use

- During planning, when the **dj-plan** skill (or the **dj-planner** subagent) produces `.agent/features/<feature>/pr-strategy.md`
- When a branch has grown and you must decide: ship as-is, split, or stack
- When `pr_policy` in `.agent/project.md` is `explicit-pr-strategy`, or `phase-as-pr` needs a sanity check

**When NOT to use:**

- `pr_policy: none` — work lands on a shared branch; there are no PR boundaries to design
- A trivial one-story change (a small fix does not need a slicing analysis)

## Classify files first

File count means nothing until files are classified:

| Category | Examples | Review cost |
|---|---|---|
| Core | new business logic, changed contracts, altered behavior | High — read carefully |
| Tests | new/updated specs, fixtures | Medium — check against behavior |
| Config | CI, env, build settings | Low — scan for surprises |
| Mechanical | renames, import updates, codemod output | Near zero — spot-check |
| Generated | lockfiles, snapshots, codegen | Near zero |
| Docs | READMEs, comments-only changes | Low |

A 30-file PR can be perfectly reviewable if 5 files are core, 10 are tests, 5 are config/docs, 10 are mechanical — **and** the description carries a clear review map (apply the **dj-pr-description** skill). A 5-file PR can be terrible if it mixes architecture, UX, tests, a migration, and cleanup into one diff.

## Slicing questions

Answer these before proposing a PR count:

1. What part is foundation (types, contracts, validation)?
2. What part is behavior?
3. What part is integration?
4. What part is UI?
5. What part is tests?
6. What part is cleanup?
7. Which parts can be reviewed on their own?
8. Which parts depend on another part?

The answers become a short table, not a big document:

```text
PR | Purpose   | Expected files    | Risk   | Depends on
1  | Contracts | API/types/tests   | Medium | —
2  | SDK       | SDK/tests         | High   | PR 1
3  | Widget    | UI/hooks/tests    | Medium | PR 2
```

## Choosing the shape

| Situation | Lean toward |
|---|---|
| One conceptual change, whatever the file count | 1 PR with a review map |
| Foundation and consumer are separable, each reviewable alone | 2 PRs |
| Real dependency chain **and** the team reviews fast | Stacked PRs |
| The team reviews slowly | Fewer, self-contained PRs — stacked chains rot while waiting |
| A mechanical change dwarfs the conceptual change | Separate mechanical from conceptual when possible |

Dependent PRs in real life:

- If PR 1 has not been reviewed yet, PR 2 may continue stacked on top of PR 1 — don't block work on review latency.
- If PR 2 depends on PR 1, PR 2's description must say so explicitly.

## The strategy is a hypothesis

Every PR strategy includes a re-evaluation checkpoint after the first real tasks land (e.g. "re-check after T-04"):

- actual files touched vs. expected
- proportion of conceptual vs. mechanical change
- whether the PR count still makes sense

If the strategy changes, update `pr-strategy.md` and note why — silent divergence between plan and branches is drift (apply the **dj-drift-management** skill if it affects tasks).

## Common mistakes

- Enforcing a file-count ceiling ("max 10 files") as law — file counts are a smell to investigate, not a rule.
- Splitting one coherent story into fragments that cannot be understood alone.
- Building stacked chains for a team that takes days per review.
- Burying a behavioral change inside a giant mechanical rename — the diff drowns the story.
- Treating the initial strategy as frozen and never re-evaluating after real tasks land.

## Output format

When producing or revising a strategy, write `.agent/features/<feature>/pr-strategy.md`. The canonical template ships with **dj-plan** (`templates/pr-strategy.md`); its sections, in order:

```text
Recommended approach (1 PR | 2 PRs | stacked PRs | no PR) · Why ·
Review story · File categories (Core / Tests / Config / Mechanical-generated / Docs) ·
Slicing table (multi-PR only) · Alternatives considered · Re-evaluation checkpoint
```
