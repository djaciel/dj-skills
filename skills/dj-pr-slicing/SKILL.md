---
name: dj-pr-slicing
description: "Use when deciding PR boundaries, planning how a feature will land as pull requests, judging whether a grown branch should ship as one PR or several, or when pr_policy requires an explicit PR strategy for a feature."
---

# PR Slicing

## Overview

A PR boundary is judged by one question: **"Does this PR tell a reviewable story?"**, never by file count. A PR strategy is a revisable hypothesis with a re-evaluation checkpoint, not an eternal contract.

Each PR is estimated and the estimate is shown to the human. When a PR is large for the team's `pr_size` preference, a split is the default recommendation, and the human decides. No number is a limit.

## When to use

- During planning, when the **dj-plan** skill (or the **dj-planner** subagent) produces `.dj-agents/repos/<repo>/features/<feature>/pr-strategy.md`
- When a branch has grown and you must decide: ship as-is, split, or stack
- When `pr_policy` in `.dj-agents/repos/<repo>/project.md` is `explicit-pr-strategy`, or `phase-as-pr` needs a sanity check

**When NOT to use:**

- `pr_policy: none`: work lands on a shared branch; there are no PR boundaries to design
- A trivial one-story change (a small fix does not need a slicing analysis)

## Classify files first

File count means nothing until files are classified:

| Category | Examples | Review cost |
|---|---|---|
| Core | new business logic, changed contracts, altered behavior | High, read carefully |
| Tests | new/updated specs, fixtures | Medium, check against behavior |
| Config | CI, env, build settings | Low, scan for surprises |
| Mechanical | renames, import updates, codemod output | Near zero, spot-check |
| Generated | lockfiles, snapshots, codegen | Near zero |
| Docs | READMEs, comments-only changes | Low |

A 30-file PR can be perfectly reviewable if 5 files are core, 10 are tests, 5 are config/docs, 10 are mechanical, **and** the description carries a clear review map (apply the **dj-pr-description** skill). A 5-file PR can be terrible if it mixes architecture, UX, tests, a migration, and cleanup into one diff.

## Estimate each PR

Estimate from the codebase map or the scout result, not from the brief alone. Per PR:

| Field | What to write |
|---|---|
| Core files | the files of the Core category |
| Files | every file, all categories |
| Lines | added plus removed, as an order of magnitude: tens, hundreds, a thousand or more |
| Reading time | a careful review, as an order of magnitude: minutes, tens of minutes, hours |
| Independent value | what stays merged and useful if the next PR never comes |

Compare each estimate with `pr_size` from `project.md` (the team's preference in its own words) and say it in words: "within the team's preference" or "larger than the team's preference", never as a cap. When a PR is larger, recommend a split along a seam (see Slicing techniques) as the default; the human accepts it or keeps one PR at the plan checkpoint. With `pr_size: none`, show the estimates and judge by the story alone.

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
1  | Contracts | API/types/tests   | Medium | none
2  | SDK       | SDK/tests         | High   | PR 1
3  | Widget    | UI/hooks/tests    | Medium | PR 2
```

## Slicing techniques

| Technique | When | What it gives |
|---|---|---|
| Preparatory PR ("make the change easy, then make the easy change") | the change needs existing code moved or extracted first | a mechanical PR that is quick to review, then a small behavior PR |
| Contract first | types, schemas or migrations that only add | PR 1 adds without changing behavior and merges with little risk |
| Behind a flag or unwired | the new module can merge without being used | each PR merges on its own; the last PR connects it |
| Mechanical separate | renames, imports, codemods | the behavior diff is not drowned |

Each technique produces PRs that merge one after another onto the base; none of them needs a stack.

## Choosing the shape

Before recommending a stack, confirm the mechanism exists. A stack needs the first branch to live in the repository where the PRs are reviewed. When the contributor pushes to a different repository than the one reviewed, the base of a PR can only be a branch of the reviewed repository, so no stack is available however fast the team reviews. Two commands settle it (the review remote is the one PRs are opened in; when that is unclear, name your choice as an assumption):

```text
git remote -v
git ls-remote --heads <review remote> "refs/heads/<your branch prefix>/*"
```

If the second prints nothing, there is no stack: plan separate PRs, rebase the dependent branch onto its parent so the two stay in sync, and say why in the strategy's "Hosting check".

| Situation | Lean toward |
|---|---|
| One conceptual change, whatever the file count | 1 PR with a review map |
| A dependency chain: foundation and consumer, each reviewable alone | Sequential PRs (the default): each merges onto the base before the next is reviewed |
| Real dependency chain, the hosting check passed, **and** the team reviews fast | Stacked PRs |
| The team reviews slowly | Fewer, self-contained PRs: stacked chains rot while waiting |
| A mechanical change dwarfs the conceptual change | Separate mechanical from conceptual when possible |

Dependent PRs in real life:

- Branch plan: PR n lives on `<prefix>/<feature>-<n>-<name>`. While PR 1 waits for review, PR 2's branch is cut from PR 1's branch, so work does not wait on review latency; after PR 1 merges, PR 2's branch is rebased onto the base.
- PR 2 is opened against the base. It is opened against PR 1's branch only when the hosting check passed and the strategy chose a stack.
- If PR 2 depends on PR 1, PR 2's description must say so explicitly.
- The strategy names the branches; the human creates, rebases, pushes and opens them. No skill opens, retargets, rebases or pushes a PR.

## The strategy is a hypothesis

Every PR strategy includes a re-evaluation checkpoint after the first real tasks land (e.g. "re-check after T-04"):

- actual files touched vs. expected
- proportion of conceptual vs. mechanical change
- whether the PR count still makes sense
- from then on, at every task close, `pr-meter <target>` shows the PR's size so far next to its estimate (dj-task step 9)

If the strategy changes, update `pr-strategy.md` and note why. Silent divergence between plan and branches is drift (apply the **dj-drift-management** skill if it affects tasks).

`pr-strategy.md` carries `Status: hypothesis | pr-split-needed | revised`. It becomes `pr-split-needed` when a task close shows a PR past its estimate and the human agrees, or when the human asks; that moves the re-evaluation checkpoint to now. After the re-slice it becomes `revised`. A PR past its estimate is a question for the human, never an automatic split.

## Re-slicing existing code

When a branch already holds more than one story:

1. Measure: `pr-meter <target>` (where the scripts live: "Running the scripts" in `skills/dj-start/templates/dj-agents-layout.md`).
2. Name the seams: contracts, mechanical changes, each behavior by its flow. Cut by seam, never by line count.
3. Cut the first increment into its own branch from the base, with the old path still live. With the changes in the working tree, `staging-table` lists the hunks and the human stages the increment with `git add -p`, hunk by hunk. The human runs every command that writes to the client repository, under its commit policy.
4. Each branch builds and its tests pass on its own.
5. Update `pr-strategy.md` (`Status: revised`), the `PR:` field of the affected packets and of the delivery plan, and log the drift (**dj-drift-management**).

## Common mistakes

- Enforcing a file-count ceiling ("max 10 files") as law: file counts are a smell to investigate, not a rule.
- Splitting one coherent story into fragments that cannot be understood alone.
- Building stacked chains for a team that takes days per review.
- Burying a behavioral change inside a giant mechanical rename: the diff drowns the story.
- Treating the initial strategy as frozen and never re-evaluating after real tasks land.
- Recommending stacked PRs without checking that the contributor can push a branch to the repository where PRs are reviewed. Stacking is a hosting capability, not only a workflow choice.
- Turning `pr_size` into a limit or slicing to hit a number instead of a seam.
- Opening PR 2 against PR 1's branch when the hosting check said no.

## Output format

When producing or revising a strategy, write `.dj-agents/repos/<repo>/features/<feature>/pr-strategy.md`. The canonical template ships with **dj-plan** (`templates/pr-strategy.md`); its sections, in order:

```text
Status (hypothesis | pr-split-needed | revised) · Recommended approach (1 PR | sequential PRs | stacked PRs | no PR) ·
Why · Estimates (informational) · Hosting check · Branch plan · Review story ·
File categories (Core / Tests / Config / Mechanical-generated / Docs) · Alternatives considered · Re-evaluation checkpoint
```
