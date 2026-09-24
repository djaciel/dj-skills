---
name: dj-migrate
description: Use once per machine to move existing v2 working folders into the .dj-agents/ root, or with --merge to add a second machine's v2 data to a root that already has content. Not for daily use.
---

# Migrate: v2 Working Folders into `.dj-agents/`

## Overview

Copy, classify, seed, mark, report. Every old v2 folder (`<repo>/.agent/`) under the root is copied into `repos/<repo>/`, its state is rewritten into the v3 shape, what it already knows seeds the map through inbox entries, names are stripped, and the old folder gets a marker file. This is the only skill that reads the v2 folder; every other v3 skill ignores it.

Never delete the old folder and never move it: copy with `cp -R`, never `mv`, never `rm`. The marker `MIGRATED.md` is the only file written outside `.dj-agents/`; nothing else in the old folder changes, and nothing else in the client repository is touched. Nothing is discarded, it moves: what has no place in v3 goes to `repos/<repo>/archive/` and is listed in the report.

**Announce at start:** "I'm using the dj-migrate skill to migrate the v2 folders under <base> into <root>."

## When to use

- First run on a machine: v2 folders exist and v3 is installed. Order across machines: the machine with more data first, then its root is copied to the second machine (`dj-sync`), then `/dj-migrate --merge` there on top of it, then the result goes back.
- `/dj-migrate --merge`: the root already has content from another machine and this machine's v2 folders must be added without overwriting anything.

**Do NOT use when:**
- The root already holds migrated data from this machine. A second run without `--merge` stops at step 1.
- A repository has no v2 folder. That is `/dj-start --adopt`.
- New knowledge arrives from a thread, a memo or a PR. That is `/dj-ingest`.

## Inputs

Layout and root resolution: `skills/dj-start/templates/dj-agents-layout.md`; resolve `<area>` with the `dj-root` script.

- **The root.** Run `dj-root`. If it exits 1, ask one question with a default: "Where should `.dj-agents/` live? Default: the parent of the current repository". Then create it exactly as `/dj-start --adopt` step 1 does: `knowledge/` with `index.md` seeded from the dj-map template, `repos/` with a `.gitkeep`, `git init`, first commit "Initialize .dj-agents". A root without its own `.git` gets the same `git init` and first commit.
- **The base**: the directory that holds `.dj-agents/`. The old folders are searched there, four levels deep, without entering `node_modules`, `.git` or any `.dj-agents/`, and without entering a v2 folder once found:
  `find <base> -maxdepth 4 \( -name node_modules -o -name .dj-agents -o -name .git \) -prune -o -type d -name .agent -print -prune`
- **The repo name** of each old folder: run `dj-root name` from the folder that contains it. Exit 2 means it is not inside a git repository: skip the folder and report it. Two old folders that resolve to the same name (a main checkout and a worktree) go to the same `repos/<repo>/`; the second one follows the merge rules.
- **Skip** an old folder that already has `MIGRATED.md` and report it as "already migrated on <date> to <root>".
- `--also <path>` (optional): a folder outside the old folders, for example guides kept in an external notes folder. It is never discovered on its own; the human passes it and names its repo. It is copied to `repos/<repo>/archive/also/<basename>/` and listed.
- **Templates**: in the dj-start skill `templates/current.md`, `feature-state.md`, `handoff.md`; in the dj-map skill `templates/knowledge/inbox-entry.md`, `library-entry.md` and the template of each map file created for the first time; `templates/migration-report.md` here.
- **Dates**: `<date>` is today (`date +%F`). A source's date is the date it states, else its modification date (`date -r <file> +%F`).

## The process

Step 1 covers all old folders at once. Steps 2 to 7 run per old folder. Step 8 closes the run.

### 1. Plan and confirm once

Count, per old folder, what will be copied and where: features (folders and files), reviews, issues, base files, the two state files, other entries at the old root, the sources step 4 will seed from, and the kinds that will be applied without a further question (below). Stop if a found repo already has `repos/<repo>/` with content and `--merge` was not given: "already migrated here; run `/dj-migrate --merge` for data from another machine". Stop too when `git -C <root> status --porcelain` prints anything: the run's commits must hold only what the migration wrote, so the human commits or stashes the root first. Show the plan with the names question of step 5 and wait for one reply that covers every folder:

```text
Root: <root> (created now | existing)
Base: <base>, depth 4. Old folders found: <n>

- <repo> (<path>) -> repos/<repo>/
  features <n> (<n> files) | reviews <n> | issues <n> | base files <n> | state files 2 -> archive
  other entries at the old root -> archive: <names>
  sources to seed: codebase maps <n>, understanding and facts <n>, decisions <n>, questions <n>, reports and guides <n>, reviews <n>
- skipped: <path>: <not inside a git repository | already migrated on <date>>

Applied without a further question: codebase-map risks with a date and sha, answered questions, library entries.
Everything else stays in the inbox for /dj-ingest --apply.

Names and handles to redact. Found: <@handle (n files), filenames with a name>.
Add names or role phrases, remove false hits (code annotations, emails).

Reply "go" with the final names list, or correct the root.
```

A wrong root or a folder count that looks off is caught here, before anything is written.

### 2. Copy

Copy, never move. For each old folder:

| From the old folder | To `repos/<repo>/` |
|---|---|
| `features/<f>/` | `features/<f>/` |
| `reviews/<pr>/` | `reviews/<pr>/` |
| `issues/<id>/` | `issues/<id>/` |
| `project.md`, `language-policy.md`, `expertise-registry.md` | same name at `repos/<repo>/` |
| `current.md`, `handoff.md` | step 3 |
| every other file or folder at the old root (hand notes, a root `codebase-map.md`, `reports/`, `approach-comparison-*.md`) | `archive/<same relative path>` |

Use `cp -R <old>/<entry> <dest>` per entry. Nothing in `archive/` is ever overwritten: a path that exists gets `-2` (then `-3`) before its extension. Inside each copied feature, note the files and folders that are not part of the v3 feature layout (`T-13-implementation.md`, `guide-copy.md`, `proposals/`, `reference/`): they stay where they are and the report lists them.

### 3. Rewrite the state

1. Copy the old `current.md` and `handoff.md` verbatim to `archive/current-<date>.md` and `archive/handoff-<date>.md`. Never edit, trim or rewrite the old text; the names step is the only change ever made to these copies.
2. Read every section of the old `current.md` whose heading starts with "Active" and names a feature (the v2 template's "Active feature / issue / review", or free-form "Active: <feature>" blocks). For each named feature that was copied, write `features/<f>/state.md` from `feature-state.md`: phase, current task, current direction, "Do not follow" and recent changes from that section; active mode from it or from `project.md`, else "not recorded in v2". An active issue or review gets no index line; its folder is already copied.
3. Write a fresh `current.md` from its template: one line per feature from item 2, next action from the old task line, `Rewritten: <date> by dj-migrate`. No "Previous" block of any kind.
4. Write a fresh `handoff.md` from its template using only the newest state of the old handoff (the part above any "Previous handoff"): last real state, next step, what was not verified, what not to rely on, and a line saying the old handoff is at `archive/handoff-<date>.md`.
5. The blocks of the old `current.md` that are knowledge, not state, become items for step 4: "Standing rules" (rule: `architecture/<repo>.md`, `review/rules.md` or a constraint in `project.md`), "Environment notes" (`project.md`), "Key precedents" (`patterns/<repo>/`). "Previous header", "Previous features", "Pointers" and similar history stay in the archived copy only.

### 4. Seed the map through the inbox

One inbox entry per repo and source kind, `knowledge/inbox/<date>-migration-<repo>-<kind>.md`, from `inbox-entry.md` with `Source kind: migration`. Items, kinds, provenance labels, the Routing table, update rules and "one comment, not yet a rule" follow the `dj-ingest` skill (Routing, steps 2, 3 and 5, PR packet rules); this step only says where each source goes. Write only the kinds that have content. An entry name that exists gets `-2`.

| Kind | Sources in the copy | Items and candidate destinations |
|---|---|---|
| `state` | the blocks of step 3.5 | rules, environment notes and precedents, as listed there |
| `codebase-maps` | `codebase-map.md` of each feature | Repo zones, Existing patterns, Risks: `architecture/<repo>.md`; Reusable utilities: `patterns/<repo>/` |
| `understanding` | `understanding.md`, `hechos.md`, facts, `investigacion.md`, `formats.md`, `db-call-sites.md`, second-opinion files | terms: `glossary.md`; "what not to investigate again" and flow facts: `decisions.md` or `flows/<slug>.md` |
| `decisions` | per-feature `decisions.md` | `decisions.md`, status current unless the feature superseded it |
| `questions` | question files (`preguntas-*`, `questions-*`) | `questions.md` with the answer and the decision it unblocked, no names |
| `reports` | `reports/`, `guide.md`, guides | one `library/` entry per feature: what it was, what was learned, a pointer to the copied reports |
| `reviews` | `reviews/<pr>/` dossiers and comments | comments that state a rule: `review/rules.md`, each "one comment, not yet a rule"; discarded findings with their recorded reason: `review/false-positives.md`; one `library/` entry per review |

Provenance follows who produced the statement. A person's words (review comments, answers, rules the human set) are `said by someone <date>`. An agent's analysis (reports, dossiers, understanding files, guides, environment notes) is `explained by the agent <date>`: a report's claim is never promoted to verified. `verified in code <file:line, date, sha>` only when the source carries its own verification header with a date and a sha and the item names a path; the date and sha are the source's, never today's.

Then apply the rows whose destination is unambiguous, the kinds the human accepted in step 1:

- a codebase-map risk labeled `verified in code`: a row under "Sharp edges" of `architecture/<repo>.md` (created from its template when missing, with the header and empty tables and no placeholder rows, until `/dj-map --architecture` fills it; its `Verified:` line says only seeded rows are verified, each with its own date and sha);
- a question with its answer: a block in `questions.md`; an identical block already there is skipped;
- a library entry: `library/<date>-<slug>.md` from `library-entry.md`, `-2` when the name is taken.

Create the shared map files the entries route to, when missing, from their templates with the header and an empty table (no placeholder rows): `glossary.md`, `decisions.md`, `questions.md`, `review/rules.md`, `review/false-positives.md`. They give `/dj-ingest --apply` a file to land in and give merge mode a file to compare against.

Everything else stays `pending` with "needs human routing" in its status cell. Review-rule candidates, false-positive candidates, glossary terms, decisions, standing rules and every zone or pattern are judgment items: they are never applied here. Close each entry as `dj-ingest` step 8 does: fully applied entries move to `inbox/processed/`, the rest stay in `inbox/` with `Status: left in inbox: needs human routing`. Add the repo to the "Repos" list of `knowledge/index.md` and update its `Rewritten:` date.

### 5. Strip names

Ask the human once for the list of names, handles and role phrases to redact. The question travels with the plan in step 1, so one reply answers both. Defaults to propose: every `@handle` found by `grep -rhoE '@[A-Za-z][A-Za-z0-9_-]+'` over the copied files (drop code annotations and emails), and every filename that carries a name. Never write the list anywhere under the root.

1. Filenames first. A question file named after a person (`preguntas-<name>.md`, `preguntas-para-<name>.md`, `questions-for-<name>.md`) becomes `questions-<feature>.md`; any other filename loses the name for the slug of its folder. Rewrite the references to the old filename in the copied files.
2. Then contents, in every file written under `repos/<repo>/` and `knowledge/` by this run, archive included. Replace each name or handle, whole word and case-insensitive, with one of three roles: "a reviewer" in review files, "the team" when the sentence speaks for a group, "a teammate" otherwise. Never a role that points at one person ("the tech lead"). Keep the rule, drop the person.
3. Count occurrences per file for the report (file path and count, never the name). Check with `grep -rniw --exclude-dir=.git -e <name> <root>` and `find <root> -path '*/.git' -prune -o -iname '*<name>*' -print`: both must return nothing.

### 6. Mark the old folder

Write `<old folder>/MIGRATED.md` and nothing else in the old folder:

```md
# Migrated

- Date: <date>
- Destination: <root>/repos/<repo>/
- By: dj-migrate (dj-skills v3), <first run | merge>

v3 never reads this folder; keep it for rollback to v2.0.
```

If the client repository tracks its v2 folder in git, the marker shows as an untracked file there; say so in the report and leave it for the human.

### 7. Commit inside `.dj-agents/`

`git -C <root> add repos/<repo> knowledge && git -C <root> commit -m "Migrate <repo> from v2"`. Run steps 2 to 7 for one repo before starting the next, so each commit holds one repo's files; `knowledge/` is shared, and an entry written for another repo before this commit would land here. This never touches the client repository or its commit policy.

### 8. Report

Fill `templates/migration-report.md` per repo at `repos/<repo>/archive/migration-<date>.md`, and write one root-level summary at `knowledge/library/<date>-migration-<hostname>.md` from `library-entry.md` (`Kind: story`, one line per repo pointing to its report). Commit both, staging only what this step wrote: `git -C <root> add repos/*/archive/migration-<date>.md knowledge/library/<date>-migration-<hostname>.md && git -C <root> commit -m "Add migration report from <hostname>"`. Never `add -A` at the root: it would sweep in anything the human left uncommitted. Show the Output block.

## Merge mode

`/dj-migrate --merge` runs the same discovery and steps on top of a root that already has content, usually after that root was copied from the other machine. It adds what is missing and overwrites nothing:

- **Add missing.** Nothing identical is added twice: an incoming item that its destination already holds word for word, or that an existing inbox entry already stages, is skipped and counted in the report. A feature, review or issue folder that is new is copied plainly. A `library/` entry is added when its filename is new, with `-2` when the name is taken. A `questions.md` block is added unless an identical one is there. Index lines are added to `current.md`, never replaced. Files that already exist at `repos/<repo>/` (`project.md`, `language-policy.md`, `expertise-registry.md`, `handoff.md`) are kept; the incoming ones go to `archive/` by the archive rule of step 2.
- **Suffix duplicates with a warning.** When `repos/<repo>/features/<f>` exists, the incoming one is copied as `features/<f>--dup-<date>` and the plan, the output and the report warn about it. Its state and index line use the suffixed name. A review or issue folder that exists gets the same suffix (`reviews/<pr>--dup-<date>`, `issues/<id>--dup-<date>`). The human compares the two and decides which one continues.
- **Conflicts go to the inbox.** `review/rules.md`, `review/false-positives.md`, `glossary.md`, `decisions.md` and `architecture/<repo>.md` are never overwritten in merge mode. Every incoming item routed to one of them that the file does not already hold word for word goes into one entry per file, `knowledge/inbox/<date>-merge-conflict-<file-slug>.md`, titled "merge conflict: <file>", holding both versions: the file's current text and the incoming items with their labels and source entries. In the source entry, the same row says "left: see merge conflict entry". A protected file that does not exist yet follows the first-run rules.
- **One commit** for the whole run, after the report: `git -C <root> add repos knowledge && git -C <root> commit -m "Merge migration from <hostname>"`, replacing the commits of steps 7 and 8. The step 1 stop on a dirty root applies here too.

One feature is worked on one machine at a time. A feature that shows up as `--dup-` means that rule was broken; the report says so.

## Common mistakes

- **Deleting or moving the old folder.** Copy with `cp -R`; the old folder keeps every file and gains only `MIGRATED.md`. It is the rollback to v2.0.
- **Running twice on the same machine without `--merge`.** Step 1 stops; folders with `MIGRATED.md` are skipped in both modes.
- **Treating a report's claim as verified.** Reports, guides and dossiers are `explained by the agent`. Only a source's own date and sha make `verified in code`.
- **Keeping a name in a question.** The answer and the decision it unblocked stay; who was asked goes. A name in a filename counts too.
- **Rewriting the old `current.md` instead of archiving it verbatim.** The archive keeps the old text as it was; the new `current.md` is a fresh index.
- **Applying a judgment item.** Only the three kinds listed in step 4 are applied. A review rule from one comment stays in the inbox as "one comment, not yet a rule".
- **Letting `find` wander.** Prune `node_modules`, `.git` and `.dj-agents`, keep the depth, and never read a path the human did not pass with `--also`.

## Output

```text
Migration: <first run | merge> on <hostname>, <date>
Root: <root> (created now | existing)

- <repo>: <n> files copied (features <n>, reviews <n>, issues <n>, base <n>, archived <n>)
  state: <n> features indexed | inbox: <n> entries, <n> items applied, <n> left | names: <n> in <n> files
  warnings: <f>--dup-<date> | merge conflict: <file> | none
- skipped: <path>: <reason>

Marked: <n> old folders with MIGRATED.md; nothing else in them changed.
Committed in .dj-agents/: <commit subjects>
Reports: repos/<repo>/archive/migration-<date>.md, knowledge/library/<date>-migration-<hostname>.md

Next: /dj-start --adopt in each repository first (it writes the missing project.md and language-policy.md), then /dj-map --architecture, then /dj-ingest --apply on each entry left in knowledge/inbox/.
```
