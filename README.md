# dj-skills

A light agentic cockpit for [Claude Code](https://code.claude.com/docs/en/overview). You stay the architect; agents do the specialist work. Ten commands, eleven specialist subagents, twelve small quality lenses and six plain bash scripts turn Claude Code into a structured development partner for real work: new projects, features in existing repositories, bug fixes, review of other people's PRs, and the notes around all of it.

This is v3. What changed since v2 is listed in [CHANGELOG.md](CHANGELOG.md). Coming from v2: read [Migrating from v2](GUIDE.md#migrating-from-v2) before the first run, and keep [Rollback](GUIDE.md#rollback) at hand.

## Why

The goal is not an AI that never makes mistakes. The goal is an AI that works like a mid-senior developer whose errors are small, visible and cheap to correct, while the human keeps the architect's judgment: intent, plan approval, diff review, trade-offs and commits.

v3 adds five things to the v2 base:

- **One root for everything.** All state, plans, reports and knowledge live in one folder, `.dj-agents/`, next to the repositories. Nothing is written inside a client repository.
- **A map that grows with the work.** `knowledge/` holds the architecture of each repository, the business flows, the glossary, decisions, open questions and review rules. Planning and review read it; task closes, reviews and `/dj-ingest` add to it, always after the human approves.
- **Blind review.** The reviewer sees the code, one Goal line and the map, never the plan or the report. It judges the code instead of confirming the story. "Nothing to report" is a valid answer.
- **Layered guide and report.** The first screen says what needs the human, what was not verified and what can break. The depth sits below.
- **Scripts for the numbers.** Diff metrics, the staging table, the PR meter and line counts come from scripts, never from the model's estimate. No number is a limit.

What still holds from v2:

- **Small task packets:** one objective, clear validation commands, reviewable in one sitting.
- **Scout before building:** find the existing pattern before creating a new one.
- **Real validation:** every command in the packet runs, and the report pastes its real output.
- **Drift is logged, never absorbed:** when reality differs from the plan, the drift log says so and a replan follows when needed.

## Core ideas

- **External memory in `.dj-agents/`.** Chat history is disposable; the root is not. Any fresh session continues from the files.
- **Living specs.** Feature spec, phases, task packets, all revisable. Drift leads to a replan, never to a silent restart.
- **Specialist subagents.** Scout, planner, implementer, blind reviewers, writers. Each has one job, restricted tools and a fixed output format.
- **A light orchestrator.** The main session plans, delegates and filters; it does not write code or hold diffs. State is saved at every task close.
- **Evidence-based review.** A finding without evidence is a question, not a finding.
- **Drafts only.** Every comment, PR description, ticket or update a skill writes is a draft. The human rewrites it in his own words and posts it himself. No skill posts, sends or pushes anything.
- **Language policy.** Converse in any language; everything that leaves the machine (code, commits, PR text, comments) is English.
- **Self-contained.** No dependency on third-party skills. Expertise skills are optional and registered per repository.

## How it fits together

The root sits next to the repositories it serves, one level above them:

```text
~/code/<client>/
  .dj-agents/          the root, its own git repository
    knowledge/         the map shared across repositories
    repos/<repo-a>/    the work area of <repo-a>: state, features, reviews, issues
    repos/<repo-b>/
  <repo-a>/            a client repository; nothing of dj-skills inside
  <repo-b>/
```

Every skill finds the root by walking up from the folder where the session was opened. The repository name comes from git's main checkout, so every worktree of a repository shares one area.

A typical interaction:

```text
You
  ↓
Command (/dj-task T-03)
  ↓
Main session: reads .dj-agents/ (index, feature state, packet, map)
  ↓
Delegates each heavy step to one subagent (scout, implementer, blind reviewer, guide writer)
  ↓
Subagents apply the quality lenses (simplicity, repo patterns, test quality)
  ↓
Scripts measure (diff metrics, staging table, PR meter, line counts)
  ↓
Main session filters the review, writes the report, proposes map lines
  ↓
You review, approve and commit
```

## Installation

```bash
git clone <url of this repository> dj-skills
cd dj-skills
git checkout v3.0
./install.sh
```

In an existing copy, run `git fetch --tags` before the checkout.

`./install.sh` with no argument installs user-level into `~/.claude/`: 22 skills, 11 agents and 6 scripts (in `~/.claude/scripts/dj/`). This is the recommended install and the only one for client repositories, because it writes nothing inside any repository. Re-run it after every `git pull` or local edit; it replaces the previous copies.

`./install.sh <dir>` installs project-level into `<dir>/.claude/`. It writes `.claude/` inside that directory, so use it only for a scratch project to try v3. The install prints the same note.

Other installers (a skills CLI, a manual copy) do not copy the agents and the scripts. The scripts are needed by several commands, so use `./install.sh`.

Each skill is invoked by its name (`/dj-start`, `/dj-task`). The ten commands are the entry points; the lenses are applied by the commands and subagents. When a subagent is missing, the same step runs inline in the main session.

## What you get

### Commands (10)

| Command | Purpose |
|---|---|
| `/dj-start` | Start a new project from an idea or notes. `/dj-start --adopt` gives an existing repository its area under `.dj-agents/`, or fills the base files a migrated area lacks |
| `/dj-map` | Map one area for a feature. `/dj-map --architecture` writes the repository's architecture with evidence; `--refresh` re-runs that evidence |
| `/dj-plan` | Turn intent into a living spec, phases, task packets and a PR strategy; replans after drift |
| `/dj-task` | Execute one task packet: implement, validate, test audit, blind review, acceptance review, report, guide, map lines |
| `/dj-review` | Review someone else's PR: code before description, a layered dossier, draft comments. `--deep` verifies blocking findings; `--base <ref>` sets the base by hand |
| `/dj-fix` | Investigate and fix a bug: reproduce first, root cause, minimal fix, fix report |
| `/dj-brief` | Draft human communication from work already done: PR description, commit message, ticket, team update |
| `/dj-explore` | Compare two or three approaches when there is real uncertainty |
| `/dj-ingest` | Stage knowledge from a thread, memo, ticket, hand-made PR packet or an explanation into the map, with provenance labels, after approval |
| `/dj-migrate` | Once per machine: copy the v2 working folders into `.dj-agents/`; `--merge` adds a second machine's data |

### Subagents (11)

| Subagent | Purpose |
|---|---|
| `dj-scout` | Read-only exploration: relevant files, patterns, reusable code, duplication risk, corrections to the map |
| `dj-planner` | Writes spec, delivery plan, task packets (with Placement and a business why) and PR strategy; writes only inside `.dj-agents/` |
| `dj-implementer` | Implements one task packet in scope, follows Placement, runs real validation |
| `dj-ts-reviewer` | Blind reviewer for TypeScript and Node: the diff, the touched files, one Goal line and the map |
| `dj-elixir-reviewer` | Blind reviewer for Elixir, with the same contract |
| `dj-pr-reviewer` | Blind reviewer for other stacks and for other people's PRs; writes the dossier depth sections |
| `dj-test-auditor` | Judges whether tests add value: behavior over implementation, realistic edge cases only |
| `dj-acceptance-reviewer` | Judges whether the diff fulfills the packet's intent |
| `dj-guide-writer` | Inserts one task's section at the top of the feature guide |
| `dj-repo-mapper` | Writes a repository's architecture and pattern files with reproducible evidence; read-only on the repository |
| `dj-writer` | Turns finished analysis into draft human communication, following the language policy |

### Core skills (12)

| Skill | Purpose |
|---|---|
| `dj-simplicity-lens` | The "does this need to exist?" questions before writing new code |
| `dj-repo-patterns` | Find precedent before creating: reuse scan, local conventions, justified new patterns |
| `dj-test-quality` | What makes a test worth having, and when a test is not worth adding |
| `dj-acceptance-review` | The four acceptance levels, the task end states, judging a diff against intent |
| `dj-human-comments` | Review comment drafts a teammate will welcome: kind, evidence-linked, questions before verdicts |
| `dj-commit-message` | Suggest commit messages in the repository's own convention; suggest, never commit |
| `dj-pr-description` | PR description drafts written for the reviewer: what and why, reading order, evidence |
| `dj-pr-slicing` | PR boundaries by reviewable story: estimates per PR, a split as the default when large, sequential PRs, the hosting check, re-slicing |
| `dj-data-flow-review` | Reconstruct input, transform and output before judging a diff |
| `dj-task-report` | The task report: first screen with what needs the human and what was not verified, depth below |
| `dj-guide` | The layered review guide: business why, metrics, what can break, yes/no checks first; added lines only below |
| `dj-drift-management` | Detect drift, log it, decide absorb, replan or split |

### Scripts (6)

Installed in `~/.claude/scripts/dj/`. Plain bash, git and coreutils. They read and print; only `dj-sync` writes: bundles next to the root, and the root itself on `clone`.

| Script | What it does |
|---|---|
| `dj-root` | Prints the root, the repository name, the repository's area or the knowledge path |
| `dj-sync` | Moves `.dj-agents/` between machines as git bundles: `pack`, `unpack`, `clone`, `status` |
| `diff-metrics` | Added and removed lines per file and kind (code, test, docs, config, generated), files outside the packet's scope |
| `staging-table` | The unstaged hunks as `git add -p` will offer them, numbered, so commits can be staged by theme |
| `pr-meter` | One line: commits, files, core files and lines of the current PR so far |
| `line-count` | Lines of a file or of one task's section in the guide |

## Quick start

**Existing repository** (from inside it; `<root>` is the `.dj-agents/` folder):

```text
/dj-start --adopt             # area under .dj-agents/repos/<repo>/, commands detected from the manifests
/dj-map --architecture        # the repository's rules, each with a command behind it
# write <root>/repos/<repo>/features/<feature>/init.md with the intent
/dj-plan <root>/repos/<repo>/features/<feature>/init.md
/dj-task T-01
```

**New project from an idea:**

```text
/dj-start expense-tracker     # paste notes; answer at most 3 to 5 blocking questions
/dj-plan
/dj-task T-01
```

**Someone else's PR:**

```text
/dj-review branch feat/order-cancel against main
# read the dossier's first screen, keep or discard each finding, approve the map rows
# the kept findings come back as draft comments in comments.md
```

The drafts are yours to rewrite and post. The skill never posts.

Full workflows, the migration checklist, rollback and the concepts are in **[GUIDE.md](GUIDE.md)**.

## About `.dj-agents/`

- One root per client folder, next to the repositories, never inside one. No client repository gets a dj-skills file, so there is nothing to ignore there.
- The root is its own git repository. Every task or fix close makes one short commit inside it (`dj_agents_commit: human-only` in `project.md` turns this off). The client repository's commit policy is not affected.
- `dj-sync` moves it between machines as git bundles. One feature is worked on one machine at a time.
- v3 reads only `.dj-agents/`. The v2 working folders are read only by `/dj-migrate`, once. See [Migrating from v2](GUIDE.md#migrating-from-v2) and [Rollback](GUIDE.md#rollback).
