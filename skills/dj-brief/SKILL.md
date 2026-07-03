---
name: dj-brief
description: "Use when finished or planned work needs to be communicated to humans — a PR description, commit message, review comments, a ticket (Jira/Linear), a team update, or a technical summary — including when another dj- skill hands off its results and asks for shareable text."
---

# Brief — Turn Work into Human Communication

## Overview

Analysis and communication are separate acts: the technical truth already lives in `.agent/` artifacts and diffs, and this skill only translates it for a human audience. Never re-analyze code in order to write about it — read what was already produced, then write.

**Announce at start:** "I'm using the dj-brief skill to produce a [output type] from [source material]."

## When to use

- A PR description is needed for a branch that is ready or nearly ready.
- A commit message should be suggested for staged or completed changes.
- Review findings need to become comments a teammate will actually read.
- A ticket, team update, or technical summary must describe work done or planned.
- Another skill hands off here: /dj-fix wants a PR description for its fix, /dj-task wants a commit suggestion, /dj-review wants human comments from a filtered dossier.

**Do NOT use when:**
- The analysis does not exist yet. dj-brief writes *from* findings; it never produces findings. Run /dj-review, /dj-task, or /dj-fix first.
- The user wants planning documents (specs, task packets, PR strategy) — that is /dj-plan.
- The user wants to *decide* PR boundaries rather than describe a PR — apply **dj-pr-slicing** via /dj-plan instead.

## Language policy

Read `.agent/language-policy.md` before writing anything. Two layers:

- **Conversation with the user:** internal language — whatever the user converses in.
- **The artifact itself** (PR description, commit message, review comment, ticket, update): external language — **English, always**. It leaves the user's machine.

If `.agent/language-policy.md` does not exist, default to exactly that split: converse in the user's language, write artifacts in English.

## Routing

Pick the lens for the requested output:

| Output requested | Lens to apply | Typical destination |
|---|---|---|
| PR description | **REQUIRED SUB-SKILL:** dj-pr-description | PR body — user posts it |
| Commit message | **REQUIRED SUB-SKILL:** dj-commit-message | Suggestion — user commits |
| Review comments | **REQUIRED SUB-SKILL:** dj-human-comments | `.agent/reviews/<branch-or-pr>/comments.md` — user posts |
| Ticket (Jira/Linear) | format below | User's tracker |
| Team update | format below | Slack / email — user sends |
| Technical summary | format below | Doc or message — user sends |

## Process

### 1. Identify output type and audience

Infer from the request, ask one question if ambiguous. Audience determines depth: a reviewer needs a reading order; a manager needs outcomes and risks, not file lists; a future teammate reading a ticket needs context that outlives today's session.

### 2. Gather source material — read, don't re-analyze

Prefer existing artifacts, in this order:

1. `.agent/` artifacts: task reports, `issues/<id>/fix-report.md`, `reviews/<branch-or-pr>/reviewer-dossier.md`, `features/<feature>/spec.md`, `pr-strategy.md`, `drift-log.md`.
2. The actual diff (`git diff <base>...HEAD --stat`) and `git log` — to confirm file lists and scope, not to re-judge quality.
3. The original issue/task text, when the output must reference intent.

If no artifact exists (the work happened outside dj- workflows), read the diff and ask the user for the intent in one question rather than inventing a "why".

### 3. Draft with the right lens

Delegate drafting to the **dj-writer** subagent. Give it: the output type, the gathered source material, the audience, and the language policy. If the dj-writer subagent is not available, draft inline in the main session, applying the routed lens skill directly.

Either way, the lens skill's structure and tone rules govern the draft — dj-writer does not analyze code, and neither do you at this step.

### 4. Present and hand over

- Show the draft to the user: explanations in the internal language, the artifact itself in English.
- **Nothing is posted, committed, or submitted automatically.** The user sends the update, posts the comment, runs the commit.
- Persist artifacts that belong in `.agent/` (review comments, a suggested PR description next to a fix report). One-off updates and tickets are only saved if the user asks.
- If the user edits the draft, incorporate the edits — their voice wins over the template.

## Hand-offs and system coherence

- Commit suggestions produced here still obey `commit_policy` in `.agent/project.md` — dj-brief never makes committing more autonomous than the policy allows.
- Review comments produced here inherit the evidence rule from /dj-review: a finding the human discarded from the dossier does not come back as a comment.
- PR descriptions for a fix should cite the fix report's validation ("failing test before fix / passing after") — that evidence already exists; reuse it.
- If /dj-fix or /dj-task called dj-brief, return the artifact to that flow's report rather than presenting it as a separate deliverable.

## Formats for outputs without a dedicated lens skill

### Ticket (Jira/Linear)

```md
# <concise title, imperative>

## Context
<why this exists — the problem or trigger, 2–4 sentences>

## What to do
<expected outcome, not step-by-step implementation orders>

## Scope
In: <what belongs here>
Out: <what explicitly does not>

## Acceptance
- <observable check>
- <observable check>

## References
- <links, related PRs, relevant .agent/ artifacts>
```

### Team update

Aim for something readable in under a minute:

```md
**What moved:** <shipped / progressed / decided>
**Why it matters:** <impact in one or two lines>
**Risks / blockers:** <or "none">
**Next:** <what happens next and who is waiting on what>
```

### Technical summary

Scale to the audience. Cover, in order: what changed, why, current state, open risks/follow-ups. A good summary is readable in about 2 minutes; link to `.agent/` artifacts or the PR for depth instead of inlining it.

## Common mistakes

- **Re-analyzing code instead of reading the report/dossier.** Slow, and it can contradict findings the human already filtered. The artifacts are the source of truth.
- **Writing the artifact in the internal language.** Everything that leaves the machine is English, per the language policy.
- **Padding.** A 40-line PR description for a 3-file PR buries the signal. Short work gets short communication.
- **Inventing motivation.** If the "why" is not in the source material, ask — a wrong "why" in a ticket or PR misleads every future reader.
- **Posting or committing on the user's behalf.** dj-brief produces drafts; humans send them.
- **Adding co-author lines or tool attribution.** Never, in any artifact.
