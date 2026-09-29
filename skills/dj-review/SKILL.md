---
name: dj-review
description: Use when reviewing someone else's pull request, branch, or diff: a teammate's PR, an external contribution, or any change the user did not write and needs to understand and evaluate before commenting or approving.
---

# PR Review (Someone Else's Code)

## Overview

Comprehension before criticism, and code before the author's account. Read what the change does before reading what its description says it does, then compare the two. Report only findings backed by code evidence that are likely to matter in production or maintenance. Nothing is ever posted automatically, and the human's filter feeds the knowledge map only after approval.

**Announce at start:** "I'm using the dj-review skill to review <branch or PR> against <base> (standard|blind-only|deep)."

## When to use

- A teammate opened a PR and the user must review it
- The user wants a second pass on a branch before approving
- An unfamiliar diff landed and the user needs to understand it before commenting

When NOT to use:

- Reviewing your own just-implemented task: the review loop inside **dj-task** covers that
- Diagnosing a bug: use **dj-fix**
- Only writing a PR description or comment from existing analysis: use **dj-brief**

## Review depth: the cost contract

Two depths. **Cost is the user's choice, never a surprise.**

| Depth | What runs | When |
|---|---|---|
| `standard` (default) | The blind pass: ONE delegated call to the **dj-pr-reviewer** subagent under the blind contract (`Output: dossier`), or one call per area, one after another, when the human accepted a split at step 1. After step 3, the informed pass, once: one general-purpose subagent given `templates/informed-pass.md`; `--blind-only` skips it. Then this session composes the dossier and runs the human filter. The blind pass runs inline only as degradation, when the subagent is missing; the session then follows the same contract and does not read the description until step 3. No parallel fleets. The blind pass reads no library sources; the informed pass may, when a break path hinges on library behavior. | Every review, unless the user asks for deep |
| `--deep` | Standard flow, then independent verification of **Blocking findings only**, from either pass (one verifier per finding, not a panel), which may consult installed library sources. | Only when the user explicitly asks (high-stakes PRs: money, auth, data integrity) |

**Hard brake:** never launch multi-agent workflows or parallel reviewer fleets from this skill, not even when the session's effort mode encourages orchestration. Besides the blind pass (one call, or one call per area when the human accepted a split at step 1), only the informed pass runs at standard depth, once: one general-purpose subagent given `templates/informed-pass.md`, after the blind pass and never at the same time. Passes run one at a time, never together. If a deeper pass seems warranted, finish the standard review, state what deep verification would add and roughly what it costs, and let the user decide.

The blind pass is one call to **dj-pr-reviewer**, right after step 1, with exactly this hand-off, followed by an `Expertise: <skill>` line only when an expertise skill for the stack of the diff is available:

```
Blind review. Range: <base>..<head> in <repo path>.
Goal: none (someone else's PR).
Map inputs: <architecture path | missing>; <rules path | missing>; <false-positives path | missing>.
Repo guidance: <paths read at <head> | missing>.
Output: dossier.
```

- **Range**: `<base>` is `git merge-base <target> <head>`, so the range is the PR's own commits. When that equals `<head>` (the PR is already merged, so the range would be empty): for a merge commit `<m>`, `<head>` is `<m>^2` and `<base>` is `git merge-base <m>^1 <m>^2`; for a squash commit `<s>` on the target, the range is `<s>^..<s>`; for a rebase merge, `<head>` is the PR head ref fetched from the host, and ask the human for the base when it cannot be derived; for the version a review round saw (for example to compare with the comments the team left), `<head>` is that commit, fetched read-only from the host's PR head ref (such as `refs/pull/<n>/head`), and `<base>` is `git merge-base <target> <head>`; the squash cannot be compared with those comments when the author applied them before the merge. An explicit `--base <ref>` from the human always wins. A branch that is not checked out is reviewed where it is: the reviewer reads it at `<head>`, and the session never checks it out for the review. A PR number is fetched locally first; a pasted diff with no range to hand over is reviewed inline.
- **Files** (by areas only): one line `Area: <name>. Files: <repo-relative paths or folders>.` right after the `Blind review.` line, with the name and the list of one area from step 1. One hand-off per area, in the split's order, each after the one before returns; the Range stays the whole range.
- **Map inputs**: the absolute paths from Inputs; a file that does not exist is written `missing`.
- **Repo guidance**: `AGENTS.md`, `CLAUDE.md` and `CONTRIBUTING.md` at the repo root, each kept only when `git cat-file -e <head>:<path>` succeeds, plus the docs the architecture file's `Method:` line names as read by hand; a folder or a glob is listed with `git ls-tree -r --name-only <head> -- <dir>` on its folder, keeping the files it matches. Paths are relative to the repo root; `missing` when none exists. The reviewer decides which of their lines are rules (dj-pr-reviewer, "What you receive").

Never add the PR description, the ticket, the commit bodies, your own intent summary or anything under `.dj-agents/repos/` to that prompt: a reviewer that holds the author's account confirms it instead of judging the code. The reviewer does steps 2 and 4 to 6 and writes the Intent paragraph of step 3; the session does not repeat them. If dj-pr-reviewer is not available, the session does steps 2 to 6 inline under the same contract, and "How this review ran" says so.

The informed pass runs after step 3, unless `--blind-only`. The session fills the header of `templates/informed-pass.md` and sends everything below the template's comment as the prompt of one general-purpose subagent, launched with no model named. The header lives only in the template:

- **Context**: the description as the session read it at step 3, saved verbatim to `.dj-agents/repos/<repo>/reviews/<branch-or-pr>/description.md` when it is not already a file, plus the ticket or RFC paths the human gives; `none` when there is nothing. The Intent line takes the blind pass's Intent paragraph; by areas, it takes each area's Intent paragraph verbatim, each prefixed with its area name, and the Range stays the whole range. The other header lines are filled as the blind hand-off's bullets say.
- **Never add** the blind findings, Questions, Couldn't verify, the Discarded list or the session's own conclusions, the Description vs code line included: the crossing in step 8 only works if the two passes found things apart.

When no subagent can be launched, the session does the informed pass inline after step 3, following `templates/informed-pass.md` as it is written, and "How this review ran" says "inline by the session: not independent of the blind pass". When dj-pr-reviewer is missing but subagents can be launched, the blind pass runs inline as above and the informed pass is still delegated. When no subagent can be launched at all, both passes run inline, in order. By areas, a blind pass that runs inline goes area by area, in the split's order, before the informed pass.

## The review contract

Never approach this as "find issues in this PR." The contract is:

> Understand this PR. Only report findings that are supported by code evidence and likely to matter in production or maintenance.

A good review may legitimately conclude: "No blockers. Two questions and one minor nit." Do not manufacture findings to look thorough. Ten findings where seven are noise is a failed review.

## Inputs

Layout and root resolution: `skills/dj-start/templates/dj-agents-layout.md`; resolve `.dj-agents/repos/<repo>/` with `dj-root repo`.

- The diff: `git diff <base>..<head>` with the Range rule below, `gh pr diff <number>`, or a pasted diff; `--base <ref>` (optional, the human's explicit base); `--blind-only` (optional, skips the informed pass)
- The PR description and any linked issue or ticket, if available: read at step 3, after the Intent paragraph, never before; also handed to the informed pass as a file
- `.dj-agents/repos/<repo>/language-policy.md` and `.dj-agents/repos/<repo>/project.md`, if present
- The three map review inputs, by absolute path, with `<root>` from `dj-root` and `<repo>` from `dj-root name`: `<root>/knowledge/architecture/<repo>.md`, `<root>/knowledge/review/rules.md` and `<root>/knowledge/review/false-positives.md`. Each may be missing; the dossier says which were used.
- The repo's guidance files at `<head>`, as the Repo guidance bullet says; the reviewer reads them, and the dossier lists them.

Create `.dj-agents/repos/<repo>/reviews/<branch-or-pr>/` as the working folder for this review.

## The process (in order)

Standard depth, one after another and never in parallel: step 1 here, the blind pass (steps 2 and 4 to 6, and the Intent paragraph of step 3; by areas, one blind pass per area, in the split's order), step 3, the informed pass (unless `--blind-only`), step 7 with `--deep`, then steps 8 and 9 here. Inline: every step in order, by this session, the informed pass after step 3.

### 1. Get the diff

Fetch the diff (or fix the range for the hand-off) and the PR or branch metadata: title, base and head, linked issue id. Set the description and the ticket aside unread; step 3 reads them. Fix the range as the Range bullet says and resolve the guidance files at `<head>` as the Repo guidance bullet says, then check the range is not empty (`git diff --stat <base>..<head>`) before the hand-off.

**Split by area.** When the diff holds several independent flows or processes, propose a split by area before the hand-off. Judge it from the diff's own shape, for example the entrypoints, the top-level folders or the processes the change adds or touches; no file count decides it. Each area has a short name taken from the code (a folder, an entrypoint, a process, never the description) and a list of repo-relative paths or folders, read at `<head>`. Every changed file sits in exactly one area: run on each area's list, `git diff --name-only <base>..<head> -- <list>` names each changed file once across all the areas. Tests go with the code they test. A file two areas need goes to the area that owns its definition, and the other area reaches it as an import, at `<head>`; code that no single flow owns (shared modules, schema, configuration, lockfiles) forms its own area. Show the areas in order, the shared area first, then from the most foundational to the top-level, each with its file count and its core files, and the cost: one blind pass per area plus one informed pass, one after another. The human says yes, adjusts the lists, or says no. Without a yes, the review runs one blind pass over the whole range.

### 2. Triage files (internal, not a dossier section)

Sort changed files into core / tests / config / mechanical / generated / docs **to allocate your attention**: read core files fully, skim the rest. A 30-file diff with 5 core files is a small review. When the core files fall into several independent flows, that is the split step 1 proposes. This triage guides you; it does not appear in the dossier.

### 3. Reconstruct intent, then compare with the description

First the intent from the code alone: the reviewer's "Intent (from the code)" paragraph, or, inline, one paragraph you write before reading anything else about the PR. What does the change appear to solve, and how did the affected behavior work before and after? By areas, merge the area Intent paragraphs into one "What this PR appears to solve" before reading the description, and write one `Description vs code` line for the whole PR.

Only then read the description and the linked issue, and write one line:

`Description vs code: matches | promises <X> that the code does not do | does <Y> that the description does not mention`

When both gaps exist, write both, separated by `;`. The gap is usually the best question for the author. If the description is empty, the line says so. If intent stays unclear, that is itself a question for the author, not a license to assume they are wrong.

Inline, also collect the **components involved**: every codebase-specific service, lock, queue, helper, or pattern the change touches; for each, what it is, where it lives, why it exists. The dossier's audience does not know them. In the blind pass they come from the reviewer's depth sections.

After the gap line, save the description and run the informed pass, unless `--blind-only`.

### 4. Map the data flow

**REQUIRED SUB-SKILL:** dj-data-flow-review

For each main flow the diff touches, build a compact `input → transform → output` map: where inputs come from, what validates them, what consumes the results, and which assumptions changed at the seams. Most real findings live here.

### 5. Check precedents, tests, and stack quality

Four lenses over the core files, one read. Steps 4 and 5 are done by dj-pr-reviewer in the blind pass; the session does not repeat them.

- **Precedents/duplication:** read the architecture file's "Shared building blocks", "Placement guide", "Layers" and "Deviations and migrations in progress" rows, then the touched files and the files they import. Does the PR re-implement a block the map lists? Does it diverge from a placement, a layer rule or the go-forward side of a migration? The placement check covers where each new module or function of a placed kind lives, not only the calls it makes. No search beyond the touched files and their imports; what the map and those files cannot settle goes to "Couldn't verify".
- **Tests:** apply the **dj-test-quality** skill: do the tests validate the behavior this PR introduces, or implementation details? What realistic cases are missing?
- **Stack quality:** apply the **dj-repo-patterns** skill: consistency with the repo's own conventions beats abstract best practice. For TypeScript, watch the dj-ts-reviewer checklist areas: unsafe casts, duplicated types/utilities, mishandled async flows. For Elixir, watch the dj-elixir-reviewer areas: N+1 queries and missing preloads, get-then-insert races, swallowed error tuples, context boundaries bypassed.
- **Shape:** apply questions 1 and 5 to 7 of the **dj-simplicity-lens** skill against the diff and its imports alone: what the diff itself shows could be smaller or plainer. Questions 2 to 4 need a search of the repository and are not asked here. The signals and the kills are dj-pr-reviewer's Shape rows and its step 7.

### 6. Filter through the evidence rule

**Evidence rule:** a finding without evidence is a question, not a finding. Every finding must cite file:line or a reproducible behavior. Suspicions you investigated and could not confirm go to "Discarded suspicions" in the dossier, never into findings.

```md
- No speculative race conditions unless there is a concrete async path.
- No theoretical edge cases unless reachable through a realistic user/API flow.
- No style preferences reported as blockers.
- No invented missing requirements.
- If the intent is unclear, ask a question. Don't assume the author is wrong.
- Prefer fewer, higher-signal comments.
```

**Kill pass, before writing any finding down.** For each candidate, actively try to kill it: does it match a row in `review/false-positives.md` (a row covers only the shape it names)? Is the case already handled elsewhere (caller validation, middleware, a DB constraint, the type system)? Only a handler you read counts; an assumed one does not. Can its trigger actually happen in this system as deployed, through a realistic user or API flow? Is it a style point the repo is already inconsistent about? A finding earns its place only if the kill attempt fails; killed candidates go to "Discarded suspicions" with the row or what you checked. A candidate is killed on reachability only by a protection you read (a guard, a constraint, a config value in the repository, a map row), named under "Discarded suspicions"; when the only step you cannot check is an operational fact outside the repository (a proxy or path in front of the service, a provider's retry window, a pool size or timeout set at deploy time, a scheduled job that may live elsewhere), it is not killed: it goes through the runtime gate with that fact on an `Assumes:` field. A candidate killed only because its trigger cannot happen as deployed, when it changes previous behavior at a seam (what a caller, a consumer or a failure path saw before), goes to Questions as `path:line: behavior changed (before <X>, now <Y>); was it intended?`, not to "Discarded suspicions".

**Three gates.** Every surviving candidate passes one of them, or it is a Question or a "Couldn't verify" item, never a silent drop (a shape candidate that fails its gate goes to "Discarded suspicions", see the Shape gate):

- **Runtime gate:** a concrete **Trigger** (the realistic sequence that makes it bite) and file:line evidence; a trigger step that depends on an operational fact outside the repository is written on an `Assumes:` field, which names the fact and never asserts it. "Couldn't verify" is a judgment that needs a file or code path you may not read, inside the repository or a library; `Assumes:` is a written trigger whose one open step lives outside the repository (deployment, provider behavior, runtime limits, work owned elsewhere); when you cannot tell which, it is "Couldn't verify".
- **Structural gate:** the boundary or the duplicate named with file:line, what changing it **Resolves**, and a **rule or precedent**: a `review/rules.md` row, an architecture section and row, a pattern file, or a prescriptive line of a repo guidance file (path:line); or touched code at path:line, only when both sides sit in the diff or its imports and the case is one of these three: the existing branch the addition now repeats, the guard its sibling applies, the old meaning of a widened name. Layering and two mechanisms for one concern always need a map row or a prescriptive guidance line; without one they are a Question.
- **Shape gate:** the smaller shape named, and its evidence at path:line inside the diff or its imports. A shape candidate whose evidence needs any other file is not reported; one that fails the gate goes to "Discarded suspicions", never to Questions.

**Three scales**, each with its own section, none trimmed for another:

- **Runtime:** `Blocking | Should fix | Nit`, by consequence in production.
- **Structural:** `Rule broken` (a written rule: a `review/rules.md` row, a Layers "Must not depend on" cell, an Invariants row, or a prescriptive line of a repo guidance file (path:line)) or `Precedent diverged` (a Seams, Placement guide, Shared building blocks or Deviations row, a pattern file, a `review/rules.md` row marked "one comment, not yet a rule", or one of the three touched-code cases). A row marked "one comment, not yet a rule" is a precedent, never a written rule. A structural finding is never Nit.
- **Shape:** one label, `Shape`, a suggestion: never blocking, never a finding of the Runtime or Structural scale, and it never changes the verdict. A duplicate that passes the structural gate stays structural.

The finding shapes are those of dj-pr-reviewer's output, with its field labels as written (Trigger, Evidence, Assumes, Boundary or duplicate, Rule or precedent, Resolves, Fix, Suggestion); `templates/reviewer-dossier.md` shows all three. There is no count cap: order each scale by consequence, the most consequential first. "Nothing to report" and "Couldn't verify" are valid results of a review.

### 7. Deep verification (only with `--deep`)

For each **Blocking** finding: one independent verification pass (the **dj-pr-reviewer** subagent if available, otherwise inline with fresh eyes) that tries to refute it, consulting installed library sources when the finding depends on library behavior. Hand the verifier the finding, the relevant excerpts, and your evidence, not the whole repo. Downgrade or discard findings that do not survive.

### 8. Write the Reviewer Dossier

Fill `templates/reviewer-dossier.md` and save it to `.dj-agents/repos/<repo>/reviews/<branch-or-pr>/reviewer-dossier.md`, in the internal language from `.dj-agents/repos/<repo>/language-policy.md`.

**Cross the two passes** before writing. For each item of either output, decide whether the other pass reports the same problem: the same place (the `path:line` both outputs put first) or the same flow, and the same consequence. An item found by both is written once, in the blind wording, with `Found by: both`, unless the informed item carries a Trigger or an `Assumes:` the blind item lacks (a blind Question against an informed break path), or a higher severity; then the informed wording and severity are kept, still tagged `Found by: both`. Every other item is copied verbatim with one tag appended, `Found by: blind` or `Found by: informed (suspected)`. Informed break paths go under Runtime, "Already exists" items under Shape (they share the blind `[Shape]` label, so their source section sets the tag), informed Questions under Questions, each ordered by consequence with the blind ones. The informed pass's Discarded items are copied under "Discarded suspicions" with `Found by: informed`, and the "Read beyond the diff" line of "How this review ran" lists both passes. With `--blind-only`, every tag is `Found by: blind`. By areas, the blind outputs of all areas are crossed as one blind output; when two areas report the same problem, it is written once, under the area that owns the file. Each copied item then gets `Area: <name>` after its `Found by:` tag: a blind item takes its pass's area, an informed item the area whose list holds its `path:line`, or, when its path is in no list, the area of the changed file its Trigger reaches, or `whole`. Save each pass's output as it came (the subagent's return, or the inline output) next to the dossier, as `blind-output.md` and `informed-output.md`, for the human; by areas, one `blind-output-<area>.md` per area instead of `blind-output.md`.

**Dossier writing rules** (they override habit):

- **First screen for a decision.** The sections above the depth marker open with Worth posting, then say what the PR solves, what behavior changes, where the risk lives and the findings, short enough to read in one screen. Depth comes below. Items are copied from the passes' outputs without rewriting; only the `Found by:` tag is appended, and by areas the `Area:` tag. By areas there is one first screen for the whole PR and one depth block per area (`templates/reviewer-dossier.md`). What is copied from a pass stays verbatim in that pass's language; every other section follows the internal language policy. "What behavior changes" is written from a caller's view (what a client, a user or another module sees), not as a file list.
- **Worth posting.** The first section of the dossier: the items the session would post on the PR, picked from any section (a finding of any scale, a Question, a Couldn't verify item), one line each: `<path:line>: <what to post>. From: <section>, <Found by>. Why: <one line>`. The pick weighs the consequence, the agreement of both passes, a promise the code does not keep, and whether the author can act on it. What a human posts is usually two or three items; that is guidance, not a limit, and "nothing worth posting" is a valid entry. It runs with `--blind-only` too, and by areas it picks across all areas, with `Area: <name>` after `<Found by>`.
- **Audience for the depth sections: a reviewer who does NOT know this area of the codebase.** Every component named gets a one-line explanation on first mention: what it is, where it lives, why it exists. That is what the "Components involved" section is for.
- **Concrete over abstract.** Not "serializes across processes", "prevents two replicas from signing with the same nonce at the same time". A one-sentence digression to explain something "obvious" is welcome; unexplained jargon is not.
- **"Files, from the ground up":** order files from the most foundational to the top-level (dependencies first, orchestration last), and for each file explain **every change in it**, function by function, one or two plain lines each. By areas, the rule applies inside each area block.
- **No extra sections.** No file-category listings, no ad-hoc context sections: operational facts (topology, wiring, config) go inside the finding whose severity they set.

### 9. Human filters, then the map learns

After the human goes through the dossier:

1. **Filter.** Each finding, question and "Couldn't verify" item is kept (to be drafted) or discarded with a one-line reason; a Worth posting line points to one of them and is not a new item.
2. **Other reviewers.** Optionally, the human pastes comments other reviewers already left on this PR.
3. **One inbox entry.** Write `knowledge/inbox/<YYYY-MM-DD>-review-<branch-or-pr>.md` from `templates/knowledge/inbox-entry.md` in the dj-map skill (`Source kind: PR review`), one routing row per item:
   - A discard whose reason is a protection (middleware, caller validation, a DB constraint, the type system): the flagged shape as a pattern and its protection, destination `review/false-positives.md`.
   - A comment from another reviewer that states how code should be written and that no `review/rules.md` row states yet: destination `review/rules.md`, paraphrased. When the architecture file already states it, the status cell says `already in architecture <section, row>` so the human can drop the row instead of keeping one rule in two places. A single comment is marked "one comment, not yet a rule" and needs its own yes: "apply all" does not cover it, and once confirmed the rule text is written clean with the marker in the Evidence column.
   - One row for the library entry, always (`Kind: PR reviewed`): what the PR was, what was learned about the business and about the architecture.
   - Business facts, decisions, terms and questions route as in the dj-ingest Routing table.

   Every row carries one provenance label, verbatim: `verified in code <file:line, date, sha>`, `said by someone <date>` or `explained by the agent <date>`. A reason the human gave and a teammate's comment are `said by someone <date>` unless the session opened the file and the line says it. Names, handles and role phrases are removed as in dj-ingest step 4.

   Show the table and stop. Nothing reaches the map before the human approves ("apply all", edit destinations, or drop rows with a reason). Then apply the approved rows and close the entry exactly as dj-ingest step 6 (the single-comment exception: "apply all" leaves a guarded row as `left: one comment, not yet a rule`), 7 and 8.
4. **Draft comments** for the kept items: apply the **dj-human-comments** skill (via the **dj-writer** subagent if available, otherwise inline): kind, non-accusatory, evidence-linked, questions before verdicts, always in English. Save drafts to `.dj-agents/repos/<repo>/reviews/<branch-or-pr>/comments.md`. **Never post comments to the PR yourself**: the human copies, edits, and posts.

Comments the team leaves after this review, or a PR reviewed without this skill, enter the map later as a hand-made PR packet through `/dj-ingest`.

## Scaling rigor

Both passes run whatever the size of the PR, unless `--blind-only`; a diff with several independent flows is proposed as a split by area at step 1, and the human decides. A docs-only or mechanical diff comes back from the reviewer as "Nothing to report" instead of a skipped step. A PR touching money, auth or data integrity may deserve a `--deep` follow-up, but that escalation is the user's call, offered with a cost estimate, never assumed.

## Common mistakes

- **Jumping straight to criticism**: the Intent paragraph and the data flow come before any judgment; findings come from the comprehension passes, not from a hunt for issues.
- **Fanning out agents to look thorough**: seven agents re-reading the same files multiplies cost, not insight. Two careful passes, one after another, beat a fleet.
- **Writing for yourself**: a dossier full of unexplained internal component names is useless to the person it is for.
- **Padding the review**: reporting nits to justify the effort. "No blockers" is a valid, valuable result.
- **Presenting questions as findings**: if you lack evidence, it is a question for the author.
- **Hiding discarded suspicions**: listing what you checked and dropped builds trust and saves the human from re-checking.
- **Posting or pushing anything**: this skill produces material for the human; it never touches the PR.
- **Reading the description before the code**: the author's account anchors the review and hides the gap between what was promised and what was built. Step 3 reads it after the Intent paragraph.
- **Writing a teammate's single comment as a team rule**: one comment is marked "one comment, not yet a rule" and needs its own yes; the blind reviewer reads `review/rules.md` as rules.

## Output

- `.dj-agents/repos/<repo>/reviews/<branch-or-pr>/reviewer-dossier.md`: the dossier (internal language)
- `.dj-agents/repos/<repo>/reviews/<branch-or-pr>/`, next to the dossier: `description.md` (the PR description as read at step 3), `blind-output.md` and `informed-output.md` (each pass's output as it came; by areas, one `blind-output-<area>.md` per area instead of `blind-output.md`)
- `knowledge/inbox/<YYYY-MM-DD>-review-<branch-or-pr>.md`: the inbox entry with the routing table, shown before anything is applied
- After approval: the rows written to `review/false-positives.md`, `review/rules.md` and the other destinations, and one library entry `library/<YYYY-MM-DD>-<slug>.md` (`Kind: PR reviewed`); the entry moves to `inbox/processed/` once no row is pending
- `.dj-agents/repos/<repo>/reviews/<branch-or-pr>/comments.md`: draft comments in English, only after the human filters
- A short summary to the user: intent in one line, the "Description vs code" line, the Worth posting lines, finding counts by scale, the crossing counts (both, blind only, informed only), and where the dossier lives
