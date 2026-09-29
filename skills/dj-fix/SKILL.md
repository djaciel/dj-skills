---
name: dj-fix
description: Use when investigating or fixing a bug, defect, or reported issue: a GitHub/Jira/Linear issue, a regression, unexpected behavior found in QA or production, or "this used to work and now it doesn't."
---

# Issue Fix

## Overview

Reproduce first, confirm the root cause, then apply the smallest fix that removes it, with a failing test as proof. A fix that patches the symptom is a second bug waiting to be filed.

**Announce at start:** "I'm using the dj-fix skill to investigate and fix <issue-id>."

## When to use

- An issue or bug report needs investigation and a fix
- A regression appeared and the cause is unknown
- Unexpected behavior was found and someone said "please fix this"

When NOT to use:

- Building new behavior: use **dj-plan** / **dj-task**
- A bug found inside the task you are currently implementing: fix it within the **dj-task** loop if in scope, otherwise report it
- "While fixing, let's also refactor X": the refactor is a separate plan, not part of the fix

## Two rules that carry this skill

1. **No fix without a confirmed root cause.** Understand the mechanism, not just where the error surfaces.
2. **No fix without a reproduction.** A failing test is the preferred form; if a test is genuinely infeasible, record a scripted or manual reproduction and say why.

Everything else in the flow scales with judgment. These two do not.

## Inputs

Layout and root resolution: `skills/dj-start/templates/dj-agents-layout.md`; resolve `.dj-agents/repos/<repo>/` with `dj-root repo`.

- The issue: a tracker reference (GH-123, JIRA-45), a pasted report, or a verbal description
- `.dj-agents/repos/<repo>/project.md` (work mode, commit_policy, test commands) and `.dj-agents/repos/<repo>/language-policy.md`, if present
- A repo where you can run the tests

## The process

Create `.dj-agents/repos/<repo>/issues/<issue-id>/` as the working folder. Read `.dj-agents/repos/<repo>/current.md` (the index of active features) first if it exists, then, if the issue belongs to a feature, that feature's `features/<feature>/state.md`. Then do the branch check from the Branching section of `.dj-agents/repos/<repo>/project.md`: on the base branch with `branch_creation: agent`, create `fix/<issue-id>` (or the repo's convention) from the up-to-date base; with `suggest-only`, tell the human which branch to create; if no policy is written, ask once and record it in `project.md`.

### 1. Read the issue

Extract: what was reported, expected vs actual behavior, environment, severity, and what is still unknown. Save as `.dj-agents/repos/<repo>/issues/<issue-id>/issue-context.md`. If the report is too vague to act on, ask the user the blocking questions now, before touching code.

### 2. Locate the affected flow

Delegate to the **dj-scout** subagent: which files implement the reported behavior, where does the data enter, what patterns and tests already cover this area? If the dj-scout subagent is not available, do this exploration inline in the main session. For a non-trivial flow, apply the **dj-data-flow-review** skill to map `input → transform → output` before hypothesizing.

### 3. Reproduce: before any fix

Write a failing test that captures the reported behavior. If that is infeasible (needs live third-party state, hardware, prod-only data), record a reproducible script or exact manual steps instead. Save what you did and the real output in `.dj-agents/repos/<repo>/issues/<issue-id>/reproduction.md`.

If you cannot reproduce it at all: report that back with what you tried. Do not guess-fix an unreproduced bug.

### 4. Confirm the root cause

The reproduction tells you *where* it breaks; now establish *why*. Trace from symptom to mechanism until you can state: "the bug exists because X, and changing Y removes it." Example: "the API 500s on empty names" is a symptom; "`normalizeAccountName` assumes a non-empty string and is called before validation runs" is a root cause.

### 5. Write a short fix plan

Save `.dj-agents/repos/<repo>/issues/<issue-id>/fix-plan.md`, a few lines, not a document:

```md
# Fix Plan: <issue-id>
- Root cause: <one sentence, file:line>
- Minimal change: <what will change and why it removes the cause>
- Files: <expected files touched>
- Validation: <commands that will prove it>
- Risk: <what could break; adjacent code with the same assumption>
```

In `production-work` mode (`human_loop: task`), show the plan to the human before implementing. In lighter modes, proceed and let the report carry the visibility.

### 6. Implement the minimal fix

The smallest change that removes the root cause. Stay in scope: no drive-by refactors, no renames "while you're there," no fixing other bugs you spot. Those go into the report's remaining risk / follow-ups. If the minimal fix turns out to require structural change, stop and tell the human; that is a plan, not a fix.

### 7. Run the tests

The failing test from step 3 must now pass. Run the relevant suite plus typecheck/lint per `.dj-agents/repos/<repo>/project.md`. Report real output, never "tests pass" without evidence. If a pre-existing test breaks, the fix changed a contract: investigate, don't edit the test to green.

### 8. Audit edge cases

Delegate to the **dj-test-auditor** subagent: does the fix's test cover the realistic neighbors of this bug (boundary values, the same flaw in sibling code paths)? If the dj-test-auditor subagent is not available, apply the **dj-test-quality** skill inline. Add only tests the auditor deems worth adding.

### 9. Blind review

Delegate with the reviewer choice, the hand-off and the degradation of **dj-task** step 6. The Goal line is the expected behavior from `issue-context.md` in one line (`Goal: Fix: <what should happen>.`), never the root cause or the fix plan: they play the packet's role and are not passed. Compare the reviewer's Intent paragraph with that line as dj-task step 6 does.

### 10. Acceptance against the issue

Delegate to the **dj-acceptance-reviewer** subagent with the issue context, fix plan, and diff: does the change resolve what the reporter actually experienced, not merely make the new test pass? If the dj-acceptance-reviewer subagent is not available, apply the **dj-acceptance-review** skill inline.

**Filter, then fix.** The output of steps 8 to 10 goes through the filter and the fix list of **dj-task** step 8: the same three outcomes, one list, at most two rounds, with `issue-context.md` and `fix-plan.md` in the packet's place. Out-of-scope findings go to the fix report's "Remaining risk" and, when the issue belongs to a feature, to that feature's `follow-ups.md` (source `<issue-id>`).

### 11. Report and hand off

- Fill `templates/issue-fix-report.md` and save as `.dj-agents/repos/<repo>/issues/<issue-id>/fix-report.md`.
- Generate the PR description through the **dj-brief** skill (English, per `.dj-agents/repos/<repo>/language-policy.md`), using the fix report as source material.
- Suggest a commit message following the repo's convention. **Never commit or push** unless `commit_policy` in `.dj-agents/repos/<repo>/project.md` explicitly allows it.
- Rewrite `.dj-agents/repos/<repo>/handoff.md` from its template and, if a feature is involved, its `features/<feature>/state.md` and index line in `current.md`. Rewrite, never append: what stops being active moves to the fix report.
- Propose one to three map lines the bug taught, usually a gotcha or a rule learned, as in the **dj-task** close: one inbox entry, `knowledge/inbox/<YYYY-MM-DD>-<issue-id>.md`, in the routing-table format of `templates/knowledge/inbox-entry.md` in the dj-map skill (`Source kind: fix close`), each line with its provenance label and a destination (`review/rules.md`, `architecture/<repo>.md`, `flows/<slug>.md`, `glossary.md`, `decisions.md`, `library/`). Discards whose reason is a protection in code add their `review/false-positives.md` rows as in dj-task close item 5, outside the one to three lines. Show the table and stop until the human approves; a line for `review/rules.md` from a single occurrence is marked "one comment, not yet a rule" and needs its own yes ("apply all" does not cover it; once confirmed, the rule text is clean and the marker goes in the Evidence column). Apply what was approved by each destination's update rule; the rest stays in the entry as `left: <reason>`. Nothing learned: say "none" and write no entry.
- If `project.md` has `dj_agents_commit: auto` (the default, also when the key is missing) and `.dj-agents/` is a git repository of its own (`<root>/.git` exists), commit inside it, with `<root>` from `dj-root root`: `git -C <root> add -A && git -C <root> commit -m '<issue-id> <repo>: <fixed | not reproduced | not a bug>'`. This never touches the client repo's commit policy.

## Scaling rigor

| Project type | Steps to keep |
|--------------|---------------|
| production-work | All steps, blind review and acceptance review, plan shown before implementing |
| personal-medium | Test audit + acceptance; blind review when the human asks |
| personal-small | Steps 1 to 7 and the report; reviewers optional |

Steps 3 (reproduce) and 4 (root cause) never scale away: they are the fix.

## When the fix doesn't go to plan

- **Cannot reproduce** → report what you tried and what's missing (data, environment, exact steps); ask the reporter. End here.
- **Root cause requires structural change** → stop, present the finding, and propose handling it through **dj-plan**. A "fix" that rewrites a module is a feature.
- **The behavior is actually intended** → report "not a bug" with the evidence (spec, test, or code comment that defines the behavior) and let the human decide.

## Common mistakes

- **Patching the symptom**: adding a null check where the error surfaces instead of fixing why the null arrives. If you can't explain the mechanism, you haven't found the cause.
- **Expanding into a refactor mid-fix**: the diff should read as "this bug, removed." Anything more belongs in a follow-up.
- **Fixing without reproducing**: "I can see the bug in the code" is a hypothesis until a failing test or recorded reproduction confirms it.
- **Editing existing tests to make the fix pass**: a newly-failing old test is information about a broken contract, not an obstacle.
- **Bundling several bugs into one fix**: one issue, one root cause, one reviewable diff. Open separate issues for the rest.

## Output

- `.dj-agents/repos/<repo>/issues/<issue-id>/` containing `issue-context.md`, `reproduction.md`, `fix-plan.md`, `fix-report.md`
- A PR description draft (via **dj-brief**) and a suggested commit message
- A short summary to the user: root cause in one line, files changed, validation evidence, remaining risk
