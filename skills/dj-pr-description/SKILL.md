---
name: dj-pr-description
description: "Use when writing or improving a pull request description — before opening a PR, when dj-brief or dj-fix needs PR text, or when an existing description does not help its reviewer understand or navigate the change."
---

# PR Description — Written for the Reviewer's 15 Minutes

## Overview

A PR description is a review aid, not a changelog. Its job is to let a reviewer reconstruct the intent and know where to look first, within the few minutes they will actually spend on it.

## When to use

- A branch is ready (or nearly ready) and needs a PR description.
- /dj-fix or /dj-brief hands off work that needs PR text.
- An existing PR description is a wall of file names or says only "fixes bug".

**Do NOT use when:** deciding whether this should be one PR or three — that is **dj-pr-slicing**. This skill describes a PR whose boundary is already chosen.

## Source material — read before writing

1. The diff: `git diff <base>...HEAD --stat`, then the core files themselves.
2. The original task, issue, or spec — the "why" comes from intent, not from the code.
3. Validation evidence that was actually executed: task reports, fix reports, CI output.
4. `.dj-agents/repos/<repo>/features/<feature>/pr-strategy.md` if it exists — reuse its review story and file categories instead of rebuilding them.

## Structure

```md
## What & why
<the problem or intent, then what this PR does about it — 2–5 sentences>

## How to review (reading order)
1. `src/core/thing.ts` — the actual behavior change
2. `src/api/routes.ts` — how it is exposed
3. Tests mirror 1–2; everything else is mechanical.

## Changes by category
Core: <files carrying the conceptual change>
Tests: <files>
Config / mechanical / generated / docs: <files, one line total if uninteresting>

## Testing & validation
- `pnpm test src/core`: pass (14 tests)
- `pnpm typecheck`: pass
- Manual: <what was exercised by hand, if anything>

## Risks & follow-ups
- <known risk, deliberate omission, or deferred work — or "none known">
```

## Proportionality

Short PRs get short descriptions. The judgment question: **"What does the reviewer need that the diff does not already show them?"**

| PR shape | Description |
|---|---|
| 1–3 files, one obvious change | 3–6 lines: what & why, validation. Skip the categories. |
| Typical feature slice | Full structure above. |
| Wide diff (renames, generated files, many mechanical edits) | Full structure — the reading order and file categories are the most valuable sections. |

## Rules that always apply

- **Reading order is the highest-value section** of any non-trivial PR. A reviewer who reads the 3 core files first understands the other 27 for free.
- **Validation must be real.** List only commands actually run, with their actual results. Never write "tests pass" without having seen them pass.
- **"Why" before "what".** Reviewers judge fitness to intent; a description that only lists changes forces them to reverse-engineer the intent.
- **Don't restate the diff.** File-by-file prose that repeats what `git diff --stat` shows is noise.
- **English, always** — a PR description is an external artifact under the language policy. Honor its "External English level": at `simple (B1/B2)`, plain words and short sentences — same facts, simpler register.
- **Surface risk honestly.** A known limitation stated up front is a review aid; the same limitation discovered by the reviewer is a trust problem.

## Common mistakes

- Describing every file — that is `--stat`'s job; describe the *story*.
- Claiming validation that was not run.
- Burying or omitting known risks.
- Writing for the author's memory instead of the reviewer's first read.
- Padding a small PR with the full template to look thorough.
