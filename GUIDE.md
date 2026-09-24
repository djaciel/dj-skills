# dj-skills Usage Guide

Pick the situation, run the recipe. Each recipe says what to type, what comes back and what the human does at each checkpoint. After the recipes come [Migrating from v2](#migrating-from-v2), [Rollback](#rollback) and the [Concepts](#concepts); the recipes do not need the concepts to start.

Scripts are installed in `~/.claude/scripts/dj/`. The recipes write `dj-sync` for `bash ~/.claude/scripts/dj/dj-sync`; add that folder to your `PATH` to type the short form. `<root>` is the `.dj-agents/` folder, `<repo>` a repository's folder name.

| You are... | Go to |
|---|---|
| Starting a brand-new project | [Recipe 1](#recipe-1-new-project) |
| Adding a feature to an existing repository | [Recipe 2](#recipe-2-feature-in-an-existing-repository) |
| Executing planned tasks | [Recipe 3](#recipe-3-day-to-day-tasks) |
| Reviewing someone else's PR | [Recipe 4](#recipe-4-review-a-teammates-pr) |
| Fixing a bug or issue | [Recipe 5](#recipe-5-fix-a-bug) |
| Drafting a PR description, commit, ticket or update | [Recipe 6](#recipe-6-draft-communication) |
| Torn between two approaches | [Recipe 7](#recipe-7-compare-approaches) |
| The plan no longer matches reality | [Recipe 8](#recipe-8-drift-and-replan) |
| Continuing in a fresh session | [Recipe 9](#recipe-9-resume-in-a-fresh-session) |
| Using dj-skills in a repository for the first time | [Recipe 10](#recipe-10-adopt-an-existing-repository) |
| Writing down a repository's rules | [Recipe 11](#recipe-11-map-a-repositorys-architecture) |
| Keeping what a thread, memo, ticket or PR taught | [Recipe 12](#recipe-12-feed-the-map) |
| Reading what the blind reviewer returned | [Recipe 13](#recipe-13-read-a-blind-review) |
| Reading a task's report and guide | [Recipe 14](#recipe-14-read-the-layered-guide-and-report) |
| Working on two machines | [Recipe 15](#recipe-15-sync-between-two-machines) |
| Moving from v2 to v3 | [Recipe 16](#recipe-16-migrate-from-v2) |

---

## Recipe 1: New project

```text
/dj-start expense-tracker     # paste the idea dump: notes, links, an AI conversation
/dj-plan                      # spec, phases, task packets
/dj-task T-01                 # first task
```

**What happens:** run it from inside the new project's git repository. `/dj-start` reads the dump, asks **at most 3 to 5 blocking questions** (everything else becomes an assumption to correct), sets the work mode and the language policy, and writes the base files under `<root>/repos/<repo>/`. `/dj-plan` turns that into a spec, phases and task packets.

**Your job:**
1. Dump everything you have; messy is fine.
2. Answer the questions and correct any wrong assumption in the list.
3. Approve (or edit) the plan.
4. From there, loop Recipe 3.

## Recipe 2: Feature in an existing repository

```text
/dj-start --adopt             # first time in this repository only (Recipe 10)
/dj-map --architecture        # first time only, or when the rules changed (Recipe 11)
# write <root>/repos/<repo>/features/<feature>/init.md: the intent, in your words
/dj-map src/billing           # optional: a reading order for an unfamiliar area
/dj-plan <root>/repos/<repo>/features/<feature>/init.md
/dj-task T-01
```

**What happens:** adopt gives the repository its area, and the architecture file gives planning and review the repository's rules. The human creates the feature folder with its `init.md`; the skills write the rest. `/dj-map <area>` writes a feature map (`features/<feature>/codebase-map.md`): files, patterns, utilities and risks as a reading order. `/dj-plan` reads the map (index, architecture, patterns, flows, glossary, decisions, questions) and writes packets with **Placement** (layer, module, exemplar to imitate), a business why and rejected approaches.

**Your job:** approve the plan, then loop Recipe 3.

**Skip the feature map** when you already know the area.

## Recipe 3: Day-to-day tasks

```text
/dj-task T-03                       # one task
/dj-task T-01..T-04                 # short sequence, full loop per task, one at a time
/dj-task T-01..T-04 --autonomous    # only if you enabled autonomous commits
```

**What happens inside** (rigor follows the work mode): read state, scout (which also corrects the map with code evidence), implement (dj-implementer, following Placement), run validations with real output, test audit, **blind review** (Recipe 13), acceptance review, **filter then fix** (the orchestrator gives each review candidate one outcome: discard with a reason, apply when small and clear, or send to the human; one fix list, no re-review, two rounds at most), then report, guide and close.

**What you get:**
- The **report**, shown in the conversation and saved to `<root>/repos/<repo>/features/<feature>/reports/T-XX.md`. Its first screen: the outcome, "I need from you", "Not verified", "Business rules changed", "Deviations" (Recipe 14).
- When nothing is committed yet, a **Staging** table from `staging-table`: the hunks as `git add -p` will offer them, each with a theme, so each commit holds one theme.
- When the feature has a PR strategy, a **PR meter** line: `PR <n> so far: <meter line> (estimate: ...)`. Past the estimate, one item in "I need from you": keep going, or mark the strategy `pr-split-needed` and re-slice. Nothing else happens without an answer.
- The **guide** section for the task, inserted at the top of `features/<feature>/guide.md` (newest first): why, metrics, what can break, yes/no checks to approve; depth below.
- One to three **map lines** the task taught, as a table with provenance and destination. Nothing reaches the map before approval ("apply all", edit, or drop rows with a reason).
- A suggested commit message and a `Lengths:` line (lines of the report and of the guide section, information only).
- One commit inside `.dj-agents/` (`T-XX <repo>/<feature>: <end state>`). The client repository gets no commit.

Want the deep dive? Say **"walk me through T-03"**: goal, data-flow map and core files function by function.

**Your job:**
1. Answer "I need from you" and read "Not verified".
2. Answer the guide's "To approve" questions from the diff.
3. Approve or edit the map lines.
4. Stage by theme and commit. Nothing is committed in the repository for you by default.

A task can end `done`, but also `done-with-drift`, `blocked`, `needs-replan`, `split-needed`... Anything not `done` says which decision it needs (Recipe 8 for drift).

## Recipe 4: Review a teammate's PR

```text
/dj-review branch feat/order-cancel against main
/dj-review 482 --base 3f2a1c9       # a PR fetched locally, with an explicit base
/dj-review branch feat/order-cancel against main --deep
```

**What happens:**
1. **Code before description.** One blind reviewer (dj-pr-reviewer) reads the PR's own commits, the touched files and the map, never the PR description, the ticket or the commit bodies. It writes what the code does.
2. **The gap line.** Only then the description is read, and one line compares them: `Description vs code: matches | promises <X> that the code does not do | does <Y> that the description does not mention`. The gap is often the best question for the author.
3. **Layered dossier** at `<root>/repos/<repo>/reviews/<branch-or-pr>/reviewer-dossier.md`. First screen: what the PR solves, what behavior changes, where the risk lives, the findings. Below: Components involved and "Files, from the ground up", written for someone who does not know the area.
4. **Your filter feeds the map.** Keep or discard each finding, question and "Couldn't verify" item, with a one-line reason. Comments other reviewers left can be pasted too. The skill turns this into one inbox entry: discards backed by a protection go to false positives, team rules to review rules, one library entry for the PR. **One approval** covers the table; a single comment from one reviewer needs its own yes before it becomes a rule.
5. **Draft comments** for the kept items in `reviews/<branch-or-pr>/comments.md`, in English.

**Range:** the base is the merge base with the target, so the range is the PR's own commits. An already merged PR works too: for a merge commit the skill finds the PR's base and head; for a squash or rebase merge it asks for the base. `--base <ref>` always wins. A branch that is not checked out is read where it is; the skill never checks it out.

**Depth and cost:** the default is one careful pass. `--deep` adds one verifier per Blocking finding, which may read library sources. It costs several times more and is always your call; the skill may offer it, never assume it.

**Your job:** filter the findings, approve the map rows, then rewrite the drafts in your own words and post them yourself. **Nothing is ever posted by a skill.**

## Recipe 5: Fix a bug

```text
/dj-fix ISSUE-123
/dj-brief pr-description      # if the fix ships as a PR
```

**What happens:** reproduce (or write a failing test) **first**, confirm the root cause, minimal fix, validation, blind review and the same filter as Recipe 3, then a fix report in `<root>/repos/<repo>/issues/<id>/fix-report.md` with before and after evidence. The close proposes map lines the bug taught (with approval) and commits inside `.dj-agents/` (`<id> <repo>: <fixed | not reproduced | not a bug>`). It does not wander into refactors.

**Your job:** confirm the reproduction matches the real bug, review the diff, approve the map lines, commit.

## Recipe 6: Draft communication

```text
/dj-brief pr-description
/dj-brief commit
/dj-brief ticket "order cancel follow-ups"
/dj-brief team-update
```

**What happens:** it drafts from the `.dj-agents/` artifacts (reports, fix reports, dossiers); it never re-analyzes code. External text is English, at the level in the language policy (`simple (B1/B2)` means plain words and short sentences).

**Your job:** the result is a draft. Rewrite it in your own words, then post, send or commit it yourself.

**Do the work first, then brief it:** with no analysis yet, run Recipe 3, 4 or 5 first.

## Recipe 7: Compare approaches

```text
/dj-explore T-04 --approaches 2
```

**Only for real uncertainty:** two plausible architectures, a risky integration, a migration with several routes. Compares on paper by default; implements in separate worktrees only when authorized. Ends with a recommendation and the losing approaches discarded on the record.

## Recipe 8: Drift and replan

When reality stops matching the plan (a premise died, scope changed, an assumption broke):

```text
# minor drift: nothing to run; the task ends done-with-drift and is logged
/dj-plan --replan-from T-04     # major drift: replan from the task that diverged
```

**What happens:** the replan keeps what is still valid, marks dead tasks `obsolete`, updates the spec and rewrites future tasks. **It never restarts from zero.** Dead documents are listed under "Do not follow" in the feature's `state.md`, so no session obeys a dead spec.

## Recipe 9: Resume in a fresh session

```text
Continue with <feature>. Read <root>/repos/<repo>/current.md first.
```

`current.md` is the index of active features. Each feature's `state.md` holds its direction, next task and "Do not follow"; `handoff.md` holds the last real state, the next step and what is not verified. All three are rewritten at every task close, so the session can end at any time. When ending a session mid-task, ask for the handoff update first.

## Recipe 10: Adopt an existing repository

```text
/dj-start --adopt             # run from inside the repository
```

**What happens:**
- **New area.** The skill finds the root by walking up. With no root, it asks one question: where should `.dj-agents/` live (default: the parent of the repository). It creates it with `knowledge/` and `repos/`, runs `git init` inside it and commits. Then it reads the manifests and the git history (commands, base branch, naming), asks only what the repository cannot answer (work mode, commit and PR policy, languages), and writes `project.md`, `language-policy.md`, `current.md` and `handoff.md` under `repos/<repo>/`. Commit: "Adopt <repo>".
- **Fill-missing.** An area that exists but lacks base files (a migrated repository has no `project.md` or `language-policy.md`) gets only the missing files. The first line says so: "Area exists: filling <files>; keeping <files>". Existing files, features, reviews, issues and the archive are not touched. Commit: "Fill missing base files for <repo>".
- **Already adopted.** With all four base files present it stops: edit `project.md` by hand.

Nothing is written inside the repository: no files, no branches, no fetch.

**Your job:** correct the "Assumptions (correct me)" list in `project.md`. Next: Recipe 11, then write a feature's `init.md` and run `/dj-plan`.

## Recipe 11: Map a repository's architecture

```text
/dj-map --architecture              # write it
/dj-map --architecture --refresh    # re-run its evidence
```

**What happens:** the dj-repo-mapper subagent writes `<root>/knowledge/architecture/<repo>.md` and one `knowledge/patterns/<repo>/<capability>.md` per capability seen at least twice. Every layer, boundary, seam and invariant carries the command that proves it and its result ("0 of 23 controllers"). Deviations list the concerns handled two ways, with call-site counts and which way is go-forward. What it could not prove goes to "Open questions". The repository's own docs are treated as hypotheses to verify. `--refresh` re-runs each recorded command and marks it `unchanged`, `changed` or `failed`.

**What you get:** a short reply with the counts (invariants verified and failed, deviations, open questions) and the repository's line in `knowledge/index.md`. The planner reads the file for Placement; the blind reviewer reads it as rules.

**Your job:** read the Open questions and the Deviations. A rule that changed on purpose moves to `library/superseded-rules.md` once you confirm.

## Recipe 12: Feed the map

```text
/dj-ingest                          # then paste a thread, a memo, a ticket or meeting notes
/dj-ingest <path to a file>         # a memo or a hand-made PR packet
save this explanation               # after the session explained something worth keeping
/dj-ingest --apply <inbox entry>    # apply an entry whose routing you already edited
```

**What happens:**
1. **Staging.** The source becomes one entry in `knowledge/inbox/<date>-<slug>.md`. Each item is typed (fact, rule, decision, question, term, story, opportunity).
2. **Provenance.** Each item carries one label: `verified in code <file:line, date, sha>`, `said by someone <date>` or `explained by the agent <date>`. A saying never reads as a fact.
3. **Routing.** A table proposes a destination per item: glossary, flows, decisions, questions, library, review rules, false positives, architecture (only `verified in code`), or "stays in the inbox".
4. **Approval.** The skill stops. Reply "apply all", edit destinations, or drop rows with a reason. A single reviewer's comment is marked "one comment, not yet a rule" and needs its own yes.
5. **Apply.** Approved rows land by each file's update rule; the entry moves to `inbox/processed/`.

**PR packets:** a PR reviewed without `/dj-review`, or the comments the team left afterwards, enter as a hand-made packet (template `templates/pr-packet.md` in the dj-ingest skill): id, commits, description, ticket, comments.

**No names:** names, handles and role phrases are removed before anything is written. The rule stays; who said it goes.

**Your job:** read the routing table, approve or edit, and keep sayings apart from facts.

## Recipe 13: Read a blind review

The blind reviewer runs in `/dj-task` step 6, in `/dj-fix`, and as the standard pass of `/dj-review`: `dj-ts-reviewer` for TypeScript and Node, `dj-elixir-reviewer` for Elixir, `dj-pr-reviewer` for any other stack.

**What it sees:** the commit range (or the working tree), every touched file in full and the files they import, one Goal line with the purpose only, and three map files: `architecture/<repo>.md`, `review/rules.md`, `review/false-positives.md`.

**What it never sees:** the task packet, spec, delivery plan, scout result, report, guide, drift log, `state.md`, `current.md`, `handoff.md`, anything under `<root>/repos/`, and for a PR the description, the ticket and the commit bodies. It does not search the rest of the repository. A reviewer that holds the story confirms the story; this one judges the code.

**How to read the output:**
- **Intent (from the code)** comes first. The orchestrator compares it with the packet's Goal: `match`, `partial` or `mismatch`.
- **Two gates.** A runtime finding needs a realistic **Trigger** and `file:line` evidence. A structural finding needs the boundary or duplicate named at `file:line`, what changing it resolves, and a written rule or precedent from the map (or, in three narrow cases, from the touched code).
- **Two scales.** Runtime: `Blocking`, `Should fix`, `Nit`. Structural: `Rule broken` or `Precedent diverged`, never Nit. Each scale has its own section; no count cap.
- **Verdict.** `Findings`, `Nothing to report` or `Couldn't verify`. "Nothing to report" is a valid, good result. A "Couldn't verify" item names the file or fact that would settle it.
- **Fix tags.** `Fix: auto` is a hint; `Fix: human` is never applied without your yes.

**The filter (step 8 of `/dj-task`).** The orchestrator, which holds the packet, the scout result and the architecture, gives each candidate one outcome: discard with a one-line reason, apply when small and clear, or send to you. The report's "Review filter" lists every outcome. Discards backed by a protection in code come back as false-positive rows in the close table, for your approval.

**Your job:** read "I need from you" in the report for what the filter sent you; check a discard reason when it surprises you.

## Recipe 14: Read the layered guide and report

**The report** (`features/<feature>/reports/T-XX.md`). The first screen is never dropped, and its parts say "nothing" or "none" when empty:

1. **Outcome:** task and end state in one line.
2. **I need from you:** every pending decision, one line each: what to decide, the options, what stays unapplied until the answer.
3. **Not verified:** claims without pasted output, proxy checks, reviewer "Couldn't verify" items.
4. **Business rules changed:** what must or must never happen that the diff changed, `path:line` each.
5. **Deviations:** from the packet, and what was tried and abandoned.

Below: Changes, Validation, Review filter, Self-review, Skipped steps, Acceptance, Out of scope, PR meter, Staging, Review order, Suggested commit, Lengths. The report is for you only; nothing in it is posted.

**The guide** (`features/<feature>/guide.md`). Newest task first, with an index at the top. Each task's section:

- **First screen:** Why (business), or an `Open question:` above everything when nobody stated it; Metrics pasted from `diff-metrics` (added and removed lines per file and kind, files outside the packet's scope flagged, one line per file that lost lines); What can break; **To approve:** yes/no questions, one per acceptance check, where "yes" means approve, plus one concrete check to run.
- **The depth marker** `<!-- Depth: read when learning the area -->`. Below it: Flow, Removed lines (each with its verdict), Concepts (only when the packet's `Learn:` line names something), File by file (added lines only), Tests (what, why, what breaks if removed), Not done.

**Lengths as information:** the report ends with `Lengths: report <n> lines, guide section <m> lines`, from `line-count`. It is a measurement, never a target: nothing is cut or padded to change it.

**Your job:** decide from the first screens; go below the marker when learning the area.

## Recipe 15: Sync between two machines

```text
dj-sync status                # root and branch, last-sync, commits to pack, working tree
dj-sync pack                  # on the machine you leave: prints the bundle path
dj-sync unpack <file>         # on the machine you arrive at
dj-sync clone <file>          # first time on a machine: creates ./.dj-agents from a full bundle
```

**What happens:** `.dj-agents/` is a git repository. `pack` bundles the commits since the `last-sync` tag (the whole history with `--full`) into a file next to `.dj-agents/`, never inside it. `unpack` verifies the bundle and pulls it; when both machines had new commits, git makes a merge commit and the next `pack` carries it back. Run `clone` from the folder that holds the repositories.

**Rules:**
- One feature on one machine at a time.
- Uncommitted changes are not packed: close the task or commit inside the root first.
- On a conflict, `unpack` stops with exit 2. Resolve the files, `git add`, `git commit` inside the root, then `dj-sync unpack --finish`.
- The bundle is not encrypted: treat it like the root itself.

**Your job:** `pack` before leaving a machine, `unpack` on arrival.

## Recipe 16: Migrate from v2

```text
/dj-migrate                   # once, on the machine with more v2 data
/dj-migrate --merge           # on the second machine, on top of the copied root
```

**What happens:** every v2 working folder under the root's parent folder is copied into `repos/<repo>/`; state is rewritten into the v3 shape; what it already knew seeds the map through inbox entries; names are removed; each old folder gets a `MIGRATED.md` marker and nothing else changes in it. A migration report lands in `repos/<repo>/archive/`. Merge mode adds without overwriting: a repeated feature gets a `--dup-<date>` suffix, conflicting rules go to the inbox.

**Your job:** follow the install-day checklist in [Migrating from v2](#migrating-from-v2), in its order.

---

## Migrating from v2

The install-day checklist, for one or two machines. v3 reads only `.dj-agents/`. The v2 working folders (`<repo>/.agent/`) are read once, by the migration, and then stay where they are, with a `MIGRATED.md` marker, for [Rollback](#rollback). Do each step fully, and check what it names before the next one. Finish or pause any v2 task in progress first: v2 state is copied as it is on the day.

1. **Install v3 on every machine.** In your copy of the dj-skills repository: `git fetch --tags`, `git checkout v3.0`, then `./install.sh` with no argument (user-level). Check before the next step: it prints 22 skills, 11 agents and 6 scripts, and `ls ~/.claude/scripts/dj` lists the six scripts. Open a new session so the new skills load.
2. **Migrate on the machine with more v2 data.** From the folder that holds the repositories, run `/dj-migrate`. When it asks where `.dj-agents/` should live, answer with this folder, the one that holds the repositories (that is its default from here). It shows a plan first: the root (will be created, or existing), each `.agent/` folder found and where it goes, and the names to remove. Check the root path and the folder count, correct the names list, then reply "go". Check before the next step: the reply lists one line per repository and no unexpected "skipped" line; `repos/<repo>/archive/migration-<date>.md` exists for each repository; `git -C .dj-agents log --oneline` shows "Initialize .dj-agents", one "Migrate <repo> from v2" commit per repository and one "Add migration report from <hostname>" commit; `git -C .dj-agents status` is clean; each `.agent/` folder has a `MIGRATED.md` file. When a client repository tracks its `.agent/` folder in git, the marker shows there as an untracked file; leave it. The inbox entries it left are routed later with `/dj-ingest --apply <entry>`; they do not block the next step.
3. **Bundle the whole root.** From the same folder, `dj-sync pack --full`. Check before the next step: it prints a bundle path next to `.dj-agents/`, and `dj-sync status` says 0 commits to pack. Carry the file to the second machine by any means; it is not encrypted.
4. **Second machine: copy the root, then merge its v2 data.** From the folder that holds the repositories there, `dj-sync clone <file>`. Check: `dj-sync status` says `to pack: 0 commit(s)` and `git -C .dj-agents log --oneline` shows the first machine's commits. Then `/dj-migrate --merge` and read the report. Check before the next step: one "Merge migration from <hostname>" commit; every feature with a `--dup-<date>` suffix (the same feature existed on both machines: compare the two and decide which one continues); every `merge-conflict` entry in `knowledge/inbox/` (rules that differ between machines, both versions kept). When this machine has no v2 data, skip the merge.
5. **Bring the union back.** On the second machine, `dj-sync pack`. On the first machine, `dj-sync unpack <file>`. Check before the next step: `unpack` prints the new HEAD line, and `dj-sync status` on both machines says 0 commits to pack. On a conflict, resolve inside the root, `git add`, `git commit`, then `dj-sync unpack --finish`.
6. **Complete each repository.** On one machine only (the other gets the result through the bundle at the end of this step), inside each repository: `/dj-start --adopt`. Its first line says "Area exists: filling project.md, language-policy.md; keeping ...": a migrated area has no `project.md` and no `language-policy.md`. Correct the assumptions in `project.md`. Then `/dj-map --architecture` and read its Open questions. The map does not commit by itself: commit inside the root (`git -C <root> add -A && git -C <root> commit -m "Map <repo> architecture"`). Check before the next step: `git -C <root> log --oneline` shows "Fill missing base files for <repo>" and "Map <repo> architecture" per repository, and `dj-sync status` says `working tree: clean`. Then `dj-sync pack` on this machine and `dj-sync unpack` on the other.
7. **From then on:** `dj-sync pack` on the machine you leave, `dj-sync unpack <file>` on the machine you arrive at. One feature on one machine at a time.

**Why this order.** The order is the one `/dj-migrate` documents: the machine with more data first, then its root is copied to the second machine (`dj-sync`), then `/dj-migrate --merge` there on top of it, then the result goes back. Migrating on both machines separately and merging afterwards would duplicate every feature that exists on both.

## Rollback

Going back to v2 on a machine, from your copy of the dj-skills repository:

```bash
git checkout v2.0 && ./install.sh
```

The v2 install replaces the skills and agents it knows, but it does not remove the four things only v3 installs. Remove them by hand:

```bash
rm -rf ~/.claude/skills/dj-ingest ~/.claude/skills/dj-migrate ~/.claude/agents/dj-repo-mapper.md ~/.claude/scripts/dj
```

What stays and why it is safe:

- v2 keeps working on the v2 folders (`<repo>/.agent/`) as before. The migration only added `MIGRATED.md` to each; nothing else in them changed. Delete the marker or keep it; v2 does not read it.
- `.dj-agents/` stays where it is, and v2 ignores it. Work done under v3 after the migration lives only in `.dj-agents/`; v2 does not see it.
- Work done under v2 during a rollback stays in the `.agent/` folders: `/dj-migrate` skips a folder that has `MIGRATED.md`, so bring that work over by hand or with `/dj-ingest`.

Going forward again:

```bash
git checkout v3.0 && ./install.sh
```

---

# Concepts

Background only; the recipes already apply it.

## The three roles

- **You are the architect:** intent, plan approval, diff review, trade-offs, commits.
- **The agent is a mid-senior developer:** competent, in scope, reports what it finds instead of acting beyond scope.
- **The system keeps errors small, visible and cheap to correct:** small tasks, real validation output, blind and evidence-based review, external memory.

## The `.dj-agents/` root

One root per client folder, next to the repositories and never inside one. Chat history is disposable; the root is not.

**Finding it.** Every skill walks up from the folder where the session was opened; the first `.dj-agents/` found is the root. `DJ_AGENTS_ROOT` set to an existing directory replaces the walk. The repository name is the folder name of git's main checkout, so every worktree of a repository shares one area. `dj-root` prints these paths.

```text
.dj-agents/
  knowledge/                   the map, shared across repositories
    index.md                   what lives where; the first file any skill reads
    glossary.md                canonical terms and aliases
    flows/<slug>.md            one business flow per file
    decisions.md, questions.md
    library/<date>-<slug>.md   stories, reviewed PRs, explanations, superseded rules
    review/rules.md            team rules the blind reviewer reads
    review/false-positives.md  shapes discarded with the protection that makes them safe
    inbox/<date>-<slug>.md     staging with provenance labels, routed by you
    architecture/<repo>.md     the repository's rules, each with a command
    patterns/<repo>/           the exemplar to imitate per capability
  repos/<repo>/                the work area of one repository
    current.md                 index of active features only
    handoff.md                 last real state, next step, what is not verified
    project.md                 stack, commands, work mode, branching, constraints
    language-policy.md         internal and external language, writing style
    features/<feature>/        init.md (yours), spec, plan, tasks/, reports/, guide.md, state.md, drift-log.md
    reviews/<pr>/              reviewer-dossier.md, comments.md
    issues/<id>/               issue context, reproduction, fix plan, fix report
    reports/<date>-<slug>.md   work outside a feature
    archive/                   migration copies and superseded state files
```

**Rule of place.** State files (`current.md`, each feature's `state.md`, `handoff.md`) hold only what is active and are rewritten at every close, never appended with "Previous" blocks. What stops being active moves to a named place (packet, report, feature folder, library, inbox); it is never deleted. No file has a length limit; the only numbers are measurements shown to you.

**Update rules.** Each map file says its rule in its header:
- `replace-when-changed`: the file always reads as the current truth (glossary, flows, decisions, review rules, false positives, architecture, patterns, and the state files). Rule text that stops applying moves to `library/superseded-rules.md` with its date.
- `append-dated`: a new dated entry; earlier entries stay (questions, library, drift logs, follow-ups).
- `staging`: the inbox. Every item carries a provenance label and waits for your routing.

Packets, reports, dossiers and fix reports are written once; a later correction goes to the drift log or a new dated entry.

**No names.** The map holds team rules, anonymized. No people file, no "who knows what". `/dj-ingest` and `/dj-migrate` strip names before writing.

**Git and sync.** `.dj-agents/` is its own git repository, created by adopt or migrate, with no remote required. Task and fix closes commit inside it, one short commit each; `dj_agents_commit: human-only` in `project.md` turns that off. The client repository's commit policy is untouched. `dj-sync` moves the root between machines as git bundles (Recipe 15). When a remote exists later, `git remote add` is enough.

## Work modes

Set at `/dj-start` (or by hand in `project.md`), adjustable any time:

| Project type | Human reviews | Reviewers per task | Commit policy |
|---|---|---|---|
| `production-work` | every task | test audit + blind review + acceptance | `human-only` |
| `personal-medium` | checkpoints | test audit + acceptance | `human-only` |
| `personal-small` | per phase | acceptance only (or none) | `human-only` unless you loosen it |

Within a mode, no review step is skipped for the size of the task or the zone of the code: a diff with nothing to review comes back as "Nothing to report". Validation never scales down.

Default commit policy everywhere: no auto-commit, no push, no auto-PR, no co-author lines. `--autonomous` only when you say so. This governs the client repository; the commit inside `.dj-agents/` has its own key.

Branching is policy too: `project.md` records the base branch, the naming convention and whether the agent creates branches or only suggests them. `pr_policy` and `pr_size` (the team's PR size preference, in words) steer the PR strategy.

**Language policy** (`<root>/repos/<repo>/language-policy.md`): *internal* is the language you converse in; *external* is always English, with an English level: `simple (B1/B2)` or `natural`. Words get simplified, facts never. The policy also carries a writing style (cautious tone, impersonal register, no dashes as punctuation, depth on demand) that `dj-writer` applies. Every comment, description, ticket or update a skill writes is a draft: you rewrite it in your own words and post it yourself. No skill posts or sends anything.

## Living acceptance and task end states

Task packets classify checks in four levels: **Hard** (must pass), **Soft** (desirable, judged), **Exploratory** (may change), **Deferred** (later task). When reality proves a check wrong, it is updated through the drift log, never silently ignored.

Tasks end in one of: `done`, `done-with-drift`, `blocked`, `needs-replan`, `split-needed`, `merged-into-next`, `obsolete`.

`pr-split-needed` is not a task end state. It is a status of the feature's `pr-strategy.md` (`hypothesis`, `pr-split-needed`, `revised`): set when a task close shows a PR past its estimate and you agree, and it leads to a re-slice at a task boundary. PR estimates are orders of magnitude shown to you, never limits; sequential PRs are the default.

## Sessions and context

The orchestrating session stays light: implementation and reviews run in subagents, and every task close saves state to `.dj-agents/`, so the session can end at any moment. Guidance, not law: up to about 75% of context, keep going; at 75 to 85%, close the slice and start fresh; past 85%, start nothing new. Prefer a fresh session over compacting: `.dj-agents/` restores the same state every time (Recipe 9).

## Multi-repo setups

One root for the client folder, one area per repository under `repos/<repo>/`, one shared `knowledge/` for everything that crosses repositories (flows, glossary, decisions). Nothing of one repository's work area mixes with another. The shared map only makes sense for repositories that belong together. A folder of unrelated personal projects gets no shared root: each project keeps its own `.dj-agents/` inside the project folder (the walk-up takes the nearest root), and its map stays its own. When `/dj-start --adopt` or `/dj-migrate` ask where the root should live, answer with the client folder for related repositories and with the project folder for a standalone one. Register related repositories and shared docs once in `project.md` under "Related repos & context sources". Cross-repo task packets declare the contract explicitly:

```md
## Repos involved
- frontend
- backend

## Cross-repo contract
- backend returns X
- frontend consumes X

## Validation per repo
Backend: ...
Frontend: ...
```

## Scripts, not hooks

Nothing is installed in a client repository: no hooks, no settings, no files. Deterministic work is done by the six scripts in `~/.claude/scripts/dj/`, which need only bash, git and coreutils and work the same under any agent tool that can run a shell:

- `dj-root` and `dj-sync` find and move the root.
- `diff-metrics`, `staging-table`, `pr-meter` and `line-count` measure. They read git and files and print numbers; they never change the repository, and no skill treats a number as a limit.

When a script is missing, the report says "script missing: part skipped"; numbers are never estimated by hand. Hooks remain an option only in your own projects, where writing `.claude/` inside the repository is your choice.

## External skills policy

dj-skills depends on **zero** third-party skills. A missing expert skill lowers specialized expertise; it never breaks a workflow. A trustworthy one can be registered in `<root>/repos/<repo>/expertise-registry.md` after evaluating it like a dependency (source, safety, quality; template in `skills/dj-start/templates/expertise-registry.md`). No external skill goes straight into production work; try it in a sandbox first.
