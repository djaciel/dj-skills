---
name: dj-ingest
description: Use when a Slack thread, memo, ticket, meeting note, a hand-made PR packet, or an explanation the session just gave should enter the knowledge map. Not for code changes or for reviewing a PR.
---

# Ingest: Knowledge from Conversations into the Map

## Overview

Staging first, map second. Every source lands as one entry in `knowledge/inbox/`, with each item typed and labeled with its provenance; nothing reaches the map files until the human approves the routing. The human routes, the skill proposes and applies. Provenance travels with every item into the file it lands in, so a saying never reads as a fact.

**Announce at start:** "I'm using the dj-ingest skill to stage <source kind> in the knowledge inbox."

## When to use

- A Slack thread, memo, ticket or meeting note carries business rules, decisions or open questions worth keeping.
- A hand-made PR packet (`templates/pr-packet.md`) holds the comments of a PR and what the team learned from it.
- The human says "save this explanation" about something the session just explained.
- `/dj-ingest --apply <inbox entry>` runs steps 7 to 9 on an entry whose routing the human already reviewed and edited.

**Do NOT use when:**
- The goal is to plan a feature. The human writes `features/<feature>/init.md` and runs `/dj-plan`.
- The goal is to review a PR. `/dj-review` leaves its own library entry; bring the PR here only as a hand-made packet with the team's real comments.
- The rules come from the code itself (layers, placement, invariants). That is `/dj-map --architecture`, with a command behind every claim.
- The change is to code. This skill writes only under `knowledge/`.

## Inputs

Layout and root resolution: `skills/dj-start/templates/dj-agents-layout.md`; resolve `<area>` with the `dj-root` script.

- The source: pasted text, or a path to a file the human points at.
- The knowledge root: `dj-root knowledge`. If it fails, stop and tell the human to run `/dj-start --adopt` first.
- The templates in the dj-map skill: `templates/knowledge/inbox-entry.md` for the staging entry, `templates/knowledge/library-entry.md` for stories, PRs and explanations, and the template of each destination file when that file does not exist yet.
- `knowledge/index.md` (what lives where) and `knowledge/glossary.md` (to resolve the words of the source against canonical terms and aliases).
- For "verified in code" labels only: the repository the item points at, and `dj-root name` for its name.

## Routing

The destinations are the map files by name. Each file keeps its own update rule from its template header; the skill applies that rule, never its own.

| Item kind | Destination | Update rule | Condition |
|---|---|---|---|
| term (with aliases) | `glossary.md` | `replace-when-changed` | Meaning known. A word with no meaning yet is a question, not a term. |
| fact about a business flow | `flows/<slug>.md` | `replace-when-changed` | The flow exists or the human agrees to open it. |
| rule of the business (what must or must never happen) | `flows/<slug>.md`, or `decisions.md` when no flow file covers it yet | `replace-when-changed` | |
| decision (with rejected alternatives if stated) | `decisions.md` | `replace-when-changed` | |
| question (open or answered) | `questions.md` | `append-dated` | An answered question keeps the answer and the decision it unblocked. |
| story, PR, explanation | `library/<date>-<slug>.md` | `append-dated` | Kept as one entry, not split into rows. |
| rule of the team about code in review | `review/rules.md` | `replace-when-changed` | A single comment is marked "one comment, not yet a rule" and needs its own yes; "apply all" does not cover it. |
| shape a reviewer accepted after discussion | `review/false-positives.md` | `replace-when-changed` | The protection that makes it safe is stated. |
| rule of the repo (layers, placement, invariants) | `architecture/<repo>.md` | `replace-when-changed` | Only `verified in code`. Anything else is marked "needs verification" and goes to `questions.md` or stays in the inbox. |
| opportunity (something wrong, complex or duplicated) | `library/<date>-<slug>.md` | `append-dated` | Kept for a later proposal; never a task by itself. |
| anything that fits nowhere yet | stays in the inbox entry | `staging` | "left: <reason>". |

## The process

### 1. Identify the source kind

One of: `thread | memo | ticket | pr-packet | explanation`, written in the entry's `Source kind:` line with the template's words (Slack thread, memo, ticket, PR packet, session explanation). Note the source date (the date of the conversation, not today, when the source shows it). One source, one inbox entry. For a PR, ask the human to fill `templates/pr-packet.md` by hand if they have not; this skill never reads PRs through `gh` or any API.

### 2. Extract and type the items

Split compound sentences: one item is one of:

- **fact**: how something works today.
- **rule**: of the repo (code structure), of the team (what reviewers check) or of the business (what must or must never happen).
- **decision**: what was chosen, with the rejected alternatives when the source states them.
- **question**: open, or answered with the answer.
- **term**: a word with its meaning and the aliases seen. Resolve it against `glossary.md` first: a known alias maps to its canonical term; when two words might be the same thing and the source is not conclusive, keep two items and say so. Two entries are cheaper to fix than one wrong merge.
- **story**: a narrative worth keeping as one piece (an incident, a PR, an explanation). Stories are not split into rows.
- **opportunity**: something wrong, complex or duplicated, kept for a later proposal.

Paraphrase each item in one line. Keep the source's certainty: "we think" stays a hypothesis.

### 3. Label the provenance

Each item carries exactly one label, verbatim:

- `verified in code <file:line, date, sha>`: only when the file was opened in this run and the line says what the item says. `sha` is `git rev-parse --short HEAD` of that repository. Delegate the check to the **dj-scout** subagent with the list of claims and the repository path ("for each claim, return file:line that confirms or contradicts it, or 'not found'"). If the dj-scout subagent is not available, open the files inline in the main session with Grep/Read; same rule, same anchors. A claim the code contradicts keeps its original label and gets the contradiction noted next to it.
- `said by someone <date>`: anything a person said or wrote, including a PR comment and a ticket.
- `explained by the agent <date>`: anything this session or another agent explained.

Never promote a saying to a fact. A saying that was checked becomes `verified in code` with its anchor; a saying that was not checked stays `said by someone`, even when it sounds certain.

### 4. Anonymize

No names in the map, and this skill does not write any. Remove handles (`@name`), names, and phrases that identify a person by role ("the tech lead", "the PM of payments", "the new hire"). Replace them with "a reviewer", "the team" or "a teammate". Keep the rule, drop the person: "`@<handle>`: reviewers should reject X" becomes "reviewers reject X". Count the names removed for the report. The raw source is not stored in the map because it carries the names; the inbox entry keeps everything the items need.

### 5. Write the inbox entry

Write `knowledge/inbox/<YYYY-MM-DD>-<slug>.md` from `inbox-entry.md`: the source kind and date, `Status: pending`, the Items table and the Routing table. The routing table has one row per item, one line per row: item number, destination file (by name, from the Routing section above), action (`replace` or `append`, from the destination's update rule) and status `pending`. Notes that the human needs to decide go in the status cell next to `pending`: "one comment, not yet a rule", "needs verification" (for any repo rule that is not `verified in code`), "new file" (when the destination does not exist yet). Rows marked "one comment, not yet a rule" are listed again under the table, apart, so the human sees which ones need a yes of their own. A story or explanation takes one row that points to its library entry, not one row per sentence.

This is the only file written in steps 1 to 6.

### 6. Show the table and stop for approval

Show the human the routing table and the count of names removed, then stop. Approval is by batch, not item by item: the human says "apply all", or edits destinations, or drops items with a reason. The default is apply nothing until the human says yes. Nothing is written to the map without that approval. If the human edits the entry file directly, re-read it before applying.

One exception to the batch: a row marked "one comment, not yet a rule" needs its own yes. "Apply all" leaves it in the entry as `left: one comment, not yet a rule`; the entry still moves to `processed/`, and a later ingest that meets the same rule finds it with `grep -r 'one comment' inbox/processed/` and proposes it again with both occurrences. When the human confirms the row, the rule text is written clean and the marker goes to the Evidence column: "one comment (<date>), confirmed at ingest".

### 7. Apply the approved rows

For each approved row, open the destination and follow its header's update rule:

- `replace-when-changed`: add the row or block, or replace the one that says the same thing differently. The replaced text moves to `library/superseded-rules.md` as a dated block (old text verbatim, the date, what replaced it) before the new text is written. Nothing is discarded, it moves.
- `append-dated`: add a new dated block (in `questions.md`, newest first) or a new `library/<date>-<slug>.md` from `library-entry.md`. An answer to an existing question edits that block in place.
- `architecture/<repo>.md`: only rows labeled `verified in code`, and the file's own evidence rule still holds; a claim without its command goes to that file's Open questions with its label.

The provenance label travels with the item into the destination's Provenance column or line. When a destination file does not exist yet, create it from its dj-map template. If the apply created a file or folder that `knowledge/index.md` does not list, rewrite the index line for it and its `Rewritten:` date.

### 8. Close the entry

Set each applied row's status to `applied <YYYY-MM-DD>`. Rows the human dropped stay in the entry with `left: <reason>`; they are never deleted. Set the entry's `Status:` to `applied <YYYY-MM-DD>` and move the file to `knowledge/inbox/processed/`. An entry with rows still `pending` (the human wants to decide later) stays in `inbox/` with `Status: left in inbox: <reason>`.

### 9. Report

Files touched, items applied, items left with their reasons, names removed. See Output.

## PR packet rules

A hand-made PR packet (`templates/pr-packet.md`) is the way the team's review feeds the map.

- A comment that states how code should be written becomes a candidate row for `review/rules.md`, paraphrased, with no name. A single comment is "one comment, not yet a rule" in the table: one reviewer's taste is not a team rule until it repeats or the human confirms that row by itself. The marker never goes into the rule text; a confirmed row carries it in Evidence.
- A pattern the reviewer flagged and then accepted after discussion (the author did not change the code) becomes a candidate row for `review/false-positives.md`, with the protection the discussion named.
- The PR itself becomes one library entry (`Kind: PR reviewed`): what it was, what was learned about the business and about the architecture, each item with its label.
- Business facts, decisions, terms and questions in the description, the ticket or the comments route as in the table above.

## "Save this explanation"

The last explanation the session produced becomes one library entry with `Kind: explanation` and provenance `explained by the agent <date>`. If it cites code, verify those anchors (step 3) before labeling any part `verified in code`; the parts that were not checked keep `explained by the agent`. It still goes through the inbox entry and the approval stop. This skill accepts only an explicit "save this"; it does not propose explanations on its own.

## Common mistakes

- **Writing sayings as facts.** "Said by someone" stays the label until the code is opened and the anchor recorded.
- **Routing to the architecture file without evidence.** A repo rule that nobody verified in code is "needs verification", not architecture.
- **Keeping a name "because it is harmless".** Handles, names and role phrases go, every time. The rule stays.
- **Recording one reviewer's taste as a team rule.** One comment is a candidate, marked as such, and "apply all" does not confirm it. The blind reviewer reads `review/rules.md` as rules, so a marker inside the rule text does not protect anything.
- **Applying before approval.** Steps 1 to 6 write only the inbox entry. `--apply` is for an entry the human already reviewed and runs steps 7 to 9 on it.
- **Deleting a dropped item.** It stays in the entry with "left: <reason>"; the entry moves to `processed/`, it is not deleted.
- **Splitting a story into rows.** A story goes to the library as one entry, with one routing row.
- **Replacing a rule without moving the old text.** The old text goes to `library/superseded-rules.md` first.

## Output

After step 6 (stop):

```text
Inbox entry: .dj-agents/knowledge/inbox/<date>-<slug>.md
Source: <kind>, <source date>
Items: <n> (<n> fact, <n> rule, <n> decision, <n> question, <n> term, <n> story, <n> opportunity)
Names removed: <n>
Routing: see the table in the entry. Reply "apply all", or edit and drop rows with a reason.
```

After step 9:

```text
Applied: .dj-agents/knowledge/inbox/processed/<date>-<slug>.md
Files touched: <file> (<n> rows), <file> (<n> rows), ...
Items applied: <n>; left: <n> (<reason>, ...)
Superseded: <n> moved to library/superseded-rules.md | none
Names removed: <n>
```
