---
name: dj-review
description: Use when reviewing someone else's pull request, branch, or diff — a teammate's PR, an external contribution, or any change the user did not write and needs to understand and evaluate before commenting or approving.
---

# PR Review (Someone Else's Code)

## Overview

Comprehension before criticism. Understand what the change does and why before judging it, and report only findings backed by code evidence that are likely to matter in production or maintenance. Nothing is ever posted automatically.

**Announce at start:** "I'm using the dj-review skill to review <branch or PR> against <base>."

## When to use

- A teammate opened a PR and the user must review it
- The user wants a second pass on a branch before approving
- An unfamiliar diff landed and the user needs to understand it before commenting

When NOT to use:

- Reviewing your own just-implemented task — the review loop inside **dj-task** covers that
- Diagnosing a bug — use **dj-fix**
- Only writing a PR description or comment from existing analysis — use **dj-brief**

## The review contract

Never approach this as "find issues in this PR." The contract is:

> Understand this PR. Only report findings that are supported by code evidence and likely to matter in production or maintenance.

A good review may legitimately conclude: "No blockers. Two questions and one minor nit." Do not manufacture findings to look thorough — ten findings where seven are noise is a failed review.

## Inputs

- The diff: `git diff <base>...<branch>`, `gh pr diff <number>`, or a pasted diff
- The PR description and any linked issue/ticket, if available
- `.agent/language-policy.md` and `.agent/project.md`, if present

Create `.agent/reviews/<branch-or-pr>/` as the working folder for this review.

## The process

### 1. Get the diff

Fetch the full diff and the PR/branch metadata (title, description, linked issue). If the description is empty, note it — intent will have to be fully reconstructed.

### 2. Classify files

| Category | What it is | Review effort |
|----------|-----------|---------------|
| Core | Files carrying the actual behavior change | Most of your attention |
| Tests | Test files | Audit in step 6 |
| Config | Config, infra, CI, env | Check for surprises only |
| Mechanical | Renames, moves, formatting-only, lockfiles | Skim |
| Generated | Build output, codegen artifacts | Verify they match the generator; don't hand-review |
| Docs | Documentation | Skim for accuracy |

A 30-file diff with 5 core files is a small review. Anchor effort on core.

### 3. Reconstruct intent (before / after)

From the diff, description, and issue: what does this PR appear to solve? How did the affected behavior work before, and how does it work after? Write it down in your own words. If intent stays unclear, that is itself a question for the author — not a license to assume they are wrong.

### 4. Map the data flow

**REQUIRED SUB-SKILL:** dj-data-flow-review

For each main flow the diff touches, build a compact `input → transform → output` map: where inputs come from, what validates them, what consumes the results, and which assumptions changed at the seams. Most real findings live here.

### 5. Scan for precedents and duplication

Delegate to the **dj-scout** subagent: does the repo already have utilities, types, or logic this PR re-implements? Are there existing patterns the PR diverges from? If the dj-scout subagent is not available, do this exploration inline in the main session (targeted grep for similar names/helpers — not a full repo crawl).

### 6. Audit the tests

Delegate to the **dj-test-auditor** subagent: do the tests validate the behavior this PR introduces, or just its implementation details? What realistic cases are missing? If the dj-test-auditor subagent is not available, apply the **dj-test-quality** skill inline.

### 7. Stack review

For TypeScript/Node code, delegate to the **dj-ts-reviewer** subagent. For other stacks, or if the subagent is not available, do a general quality pass inline anchored on the repo's own patterns (apply the **dj-repo-patterns** skill): consistency with existing conventions beats abstract best practice.

### 8. Consolidate and filter

Delegate consolidation to the **dj-pr-reviewer** subagent, which merges the material from steps 3–7 and filters it through the evidence rule. If the dj-pr-reviewer subagent is not available, do the filtering yourself using the rule below.

**Evidence rule:** a finding without evidence is a question, not a finding. Every finding must cite file:line or a reproducible behavior. Suspicions you investigated and could not confirm go to "discarded suspicions" — never into findings.

Filter every candidate finding through:

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
- Why it matters: <concrete production or maintenance impact>
- Confidence: <high | medium | low>
```

### 9. Write the Reviewer Dossier

Fill `templates/reviewer-dossier.md` and save it to `.agent/reviews/<branch-or-pr>/reviewer-dossier.md`. The dossier is for the human: it absorbs the comprehension work (intent, before/after, data flow, reading order) so they can review the PR in minutes, then presents findings, questions, and discarded suspicions separately.

Write the dossier in the internal language from `.agent/language-policy.md` (default: the language the user converses in).

### 10. Human filters, then draft comments

The human decides which findings and questions are worth raising. For the selected ones, delegate drafting to the **dj-writer** subagent applying the **dj-human-comments** skill: kind, non-accusatory, evidence-linked, questions before verdicts, always in English. If the dj-writer subagent is not available, draft the comments inline applying the dj-human-comments skill directly.

Save drafts to `.agent/reviews/<branch-or-pr>/comments.md`. **Never post comments to the PR yourself** — the human copies, edits, and posts.

## Scaling rigor

This flow is guidance, not ceremony. A docs-only or mechanical PR does not need six review passes — say which steps you skipped and why in the dossier. A large PR touching payments in a production-work project deserves every step. The question is always: "what does the human need to review this confidently?"

## Common mistakes

- **Jumping straight to criticism** — findings before comprehension produce noise. Steps 3–4 come first.
- **Padding the review** — reporting nits to justify the effort. "No blockers" is a valid, valuable result.
- **Presenting questions as findings** — if you lack evidence, it is a question for the author.
- **Hiding discarded suspicions** — listing what you checked and dropped builds trust and saves the human from re-checking.
- **Posting or pushing anything** — this skill produces material for the human; it never touches the PR.
- **Reviewing generated/mechanical files line by line** — classify first, spend attention on core.

## Output

- `.agent/reviews/<branch-or-pr>/reviewer-dossier.md` — the dossier (internal language)
- `.agent/reviews/<branch-or-pr>/comments.md` — draft comments in English, only after the human filters
- A short summary to the user: intent in one line, finding counts by type, and where the dossier lives
