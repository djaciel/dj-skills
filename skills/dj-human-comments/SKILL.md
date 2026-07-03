---
name: dj-human-comments
description: "Use when a technical finding must become a review comment a human teammate will read — after /dj-review filters a dossier, when dj-brief routes review comments, or when the user asks how to phrase feedback on a colleague's PR."
---

# Human Review Comments — Questions Before Verdicts

## Overview

The analysis is already done; this lens only translates a confirmed technical finding into a comment a teammate can read without getting defensive. Kind, evidence-linked, and phrased as a question whenever a question is honest.

## When to use

- Turning filtered findings from a reviewer dossier into postable comments.
- Rephrasing a blunt observation before it goes to a colleague.

**Do NOT use when:** producing findings — that is /dj-review and the evidence rule. This skill never analyzes code; it writes from analysis it is given.

## Input contract

Work from a structured finding, not from vibes — the same shape the reviewer dossier uses (**dj-review**):

```text
type: <Blocking | Should fix | Nit>
file: <path>
line: <n>
issue: <what is wrong or risky>
why it matters: <consequence>
evidence: <file:line — what the code actually does>
confidence: <high | medium | low>
suggested change: <optional>
```

If the evidence field is effectively empty — the suspicion was never confirmed — it is a question, not a finding. Either phrase it as a genuine question or do not post it.

## The transformation

Technical finding:

```text
This helper duplicates normalizeAccountName in src/utils/accounts.ts.
```

Human comment:

```text
I might be missing some context, but I noticed we already have
`normalizeAccountName` in `src/utils/accounts.ts`. Do you think we could
reuse or extend that helper here instead of adding a second version?
My concern is that both implementations could drift over time.
```

What changed: it opens with epistemic humility, cites the evidence, proposes as a question, and names the actual risk. Same information, zero accusation.

## Phrasing bank

| Instead of | Use |
|---|---|
| "This is wrong." | "I might be missing some context, but..." |
| "You should use X." | "Would it make sense to use X here?" |
| "This will break Y." | "My concern is that this could break Y when..." |
| "No tests for this." | "Could we add a test for this case?" |
| "Why did you do this?" | "What led to this approach? I'm asking because..." |

## Rules

- **One comment = one concern.** Two problems means two comments.
- **Always link the evidence:** the file, the line, the existing helper, the failing case.
- **Questions before verdicts — but no fake questions.** If something genuinely blocks, say so clearly and kindly, with the reason: "I think this one needs a change before merge, because <consequence>."
- **Mark non-blocking suggestions as non-blocking** so the author can triage.
- **English, always** — teammates read these; the language policy applies.

## When NOT to post

- No evidence — the suspicion could not be confirmed. Ask as an open question or drop it.
- Pure style nit with no consequence.
- Style the repo itself is already inconsistent about — one PR comment will not fix a repo-wide inconsistency; suggest a follow-up task instead.
- Anything a linter or CI already reports.
- A third comment about the same underlying concern — consolidate.

## Common mistakes

- Sounding like an automated reviewer ("Issue detected: ...").
- Softening so much the concern disappears — kindness is not vagueness; the risk must still be named.
- Bundling three concerns into one comment.
- Presenting an unconfirmed suspicion as fact.
- Writing in the internal language instead of English.

## Output

Write comments to `.agent/reviews/<branch-or-pr>/comments.md` (or present them directly if no review folder exists). **A human posts them — never post automatically.**

```md
### `src/utils/accounts.ts:42` — duplicate helper (non-blocking)
I might be missing some context, but I noticed we already have
`normalizeAccountName` in `src/utils/accounts.ts`. Do you think we could
reuse or extend that helper here? My concern is that both implementations
could drift over time.
```
