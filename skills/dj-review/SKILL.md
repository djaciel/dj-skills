---
name: dj-review
description: Use when reviewing someone else's pull request, branch, or diff — a teammate's PR, an external contribution, or any change the user did not write and needs to understand and evaluate before commenting or approving.
---

# PR Review (Someone Else's Code)

## Overview

Comprehension before criticism. Understand what the change does and why before judging it, and report only findings backed by code evidence that are likely to matter in production or maintenance. Nothing is ever posted automatically.

**Announce at start:** "I'm using the dj-review skill to review <branch or PR> against <base> (standard|deep)."

## When to use

- A teammate opened a PR and the user must review it
- The user wants a second pass on a branch before approving
- An unfamiliar diff landed and the user needs to understand it before commenting

When NOT to use:

- Reviewing your own just-implemented task — the review loop inside **dj-task** covers that
- Diagnosing a bug — use **dj-fix**
- Only writing a PR description or comment from existing analysis — use **dj-brief**

## Review depth — the cost contract

Two depths. **Cost is the user's choice, never a surprise.**

| Depth | What runs | When |
|---|---|---|
| `standard` (default) | ONE reviewer — this session — does the whole flow inline. Each file is read once. No subagents, no parallel fleets, no library-source spelunking. | Every review, unless the user asks for deep |
| `--deep` | Standard flow, then independent verification of **Blocking findings only** (one verifier per finding, not a panel), which may consult installed library sources. | Only when the user explicitly asks — high-stakes PRs: money, auth, data integrity |

**Hard brake:** never launch multi-agent workflows or parallel reviewer fleets from this skill — not even when the session's effort mode encourages orchestration. If a deeper pass seems warranted, finish the standard review, state what deep verification would add and roughly what it costs, and let the user decide.

If subagents (dj-scout, dj-test-auditor, dj-ts-reviewer, dj-pr-reviewer) are unavailable, nothing is lost at standard depth — the flow below is inline by design. When they are available, use at most ONE delegated pass where noted, and hand it your already-gathered context (diff, intent summary, core file list) instead of letting it re-derive everything from scratch.

## The review contract

Never approach this as "find issues in this PR." The contract is:

> Understand this PR. Only report findings that are supported by code evidence and likely to matter in production or maintenance.

A good review may legitimately conclude: "No blockers. Two questions and one minor nit." Do not manufacture findings to look thorough — ten findings where seven are noise is a failed review.

## Inputs

- The diff: `git diff <base>...<branch>`, `gh pr diff <number>`, or a pasted diff
- The PR description and any linked issue/ticket, if available
- `.agent/language-policy.md` and `.agent/project.md`, if present

Create `.agent/reviews/<branch-or-pr>/` as the working folder for this review.

## The process (single pass, in order)

### 1. Get the diff

Fetch the full diff and the PR/branch metadata (title, description, linked issue). If the description is empty, note it — intent will have to be fully reconstructed.

### 2. Triage files (internal — not a dossier section)

Sort changed files into core / tests / config / mechanical / generated / docs **to allocate your attention**: read core files fully, skim the rest. A 30-file diff with 5 core files is a small review. This triage guides you; it does not appear in the dossier.

### 3. Reconstruct intent (before / after)

From the diff, description, and issue: what does this PR appear to solve? How did the affected behavior work before, and how does it work after? Write it down in plain language. If intent stays unclear, that is itself a question for the author — not a license to assume they are wrong.

While doing this, collect the **components involved**: every codebase-specific service, lock, queue, helper, or pattern the change touches — for each, what it is, where it lives, why it exists. The dossier's audience does not know them.

### 4. Map the data flow

**REQUIRED SUB-SKILL:** dj-data-flow-review

For each main flow the diff touches, build a compact `input → transform → output` map: where inputs come from, what validates them, what consumes the results, and which assumptions changed at the seams. Most real findings live here.

### 5. Check precedents, tests, and stack quality — inline

Three lenses over the core files, one read, no delegation:

- **Precedents/duplication:** targeted grep for similar names/helpers — does the repo already have what this PR re-implements? Does it diverge from an established pattern? (Not a full repo crawl. Consult `.agent/**/codebase-map.md` if one exists.)
- **Tests:** apply the **dj-test-quality** skill — do the tests validate the behavior this PR introduces, or implementation details? What realistic cases are missing?
- **Stack quality:** apply the **dj-repo-patterns** skill — consistency with the repo's own conventions beats abstract best practice. For TypeScript, watch the dj-ts-reviewer checklist areas: unsafe casts, duplicated types/utilities, mishandled async flows.

### 6. Filter through the evidence rule

**Evidence rule:** a finding without evidence is a question, not a finding. Every finding must cite file:line or a reproducible behavior. Suspicions you investigated and could not confirm go to "discarded suspicions" — never into findings.

```md
- No speculative race conditions unless there is a concrete async path.
- No theoretical edge cases unless reachable through a realistic user/API flow.
- No style preferences reported as blockers.
- No invented missing requirements.
- If the intent is unclear, ask a question — don't assume the author is wrong.
- Prefer fewer, higher-signal comments.
```

Give each surviving finding this shape:

```md
[Blocking | Should fix | Nit] <one-line finding>
- Evidence: <file:line — what the code actually does>
- Why it matters: <concrete impact, explained for someone without full context>
- Confidence: <high | medium | low>
```

### 7. Deep verification (only with `--deep`)

For each **Blocking** finding: one independent verification pass (the **dj-pr-reviewer** subagent if available, otherwise inline with fresh eyes) that tries to refute it — consulting installed library sources when the finding depends on library behavior. Hand the verifier the finding, the relevant excerpts, and your evidence — not the whole repo. Downgrade or discard findings that do not survive.

### 8. Write the Reviewer Dossier

Fill `templates/reviewer-dossier.md` and save it to `.agent/reviews/<branch-or-pr>/reviewer-dossier.md`, in the internal language from `.agent/language-policy.md`.

**Dossier writing rules** (they override habit):

- **Audience: a reviewer who does NOT know this area of the codebase.** Every component named gets a one-line explanation on first mention — what it is, where it lives, why it exists. That is what the "Components involved" section is for.
- **Concrete over abstract.** Not "serializes across processes" — "prevents two replicas from signing with the same nonce at the same time". A one-sentence digression to explain something "obvious" is welcome; unexplained jargon is not.
- **"Files, from the ground up":** order files from the most foundational to the top-level (dependencies first, orchestration last), and for each file explain **every change in it**, function by function, one or two plain lines each.
- **No extra sections.** No file-category listings, no ad-hoc context sections — operational facts (topology, wiring, config) go inside the finding whose severity they set.

### 9. Human filters, then draft comments

The human decides which findings and questions are worth raising. For the selected ones, apply the **dj-human-comments** skill (via the **dj-writer** subagent if available, otherwise inline): kind, non-accusatory, evidence-linked, questions before verdicts, always in English.

Save drafts to `.agent/reviews/<branch-or-pr>/comments.md`. **Never post comments to the PR yourself** — the human copies, edits, and posts.

## Scaling rigor

This flow is guidance, not ceremony. A docs-only or mechanical PR does not need every step — say which steps you skipped and why in the dossier. A large PR touching payments deserves the full standard pass, and probably a `--deep` follow-up — but that escalation is the user's call, offered with a cost estimate, never assumed.

## Common mistakes

- **Jumping straight to criticism** — findings before comprehension produce noise. Steps 3–4 come first.
- **Fanning out agents to look thorough** — seven agents re-reading the same files multiplies cost, not insight. One careful pass beats a fleet.
- **Writing for yourself** — a dossier full of unexplained internal component names is useless to the person it is for.
- **Padding the review** — reporting nits to justify the effort. "No blockers" is a valid, valuable result.
- **Presenting questions as findings** — if you lack evidence, it is a question for the author.
- **Hiding discarded suspicions** — listing what you checked and dropped builds trust and saves the human from re-checking.
- **Posting or pushing anything** — this skill produces material for the human; it never touches the PR.

## Output

- `.agent/reviews/<branch-or-pr>/reviewer-dossier.md` — the dossier (internal language)
- `.agent/reviews/<branch-or-pr>/comments.md` — draft comments in English, only after the human filters
- A short summary to the user: intent in one line, finding counts by type, and where the dossier lives
