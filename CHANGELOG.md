# Changelog

Newest first.

## v3.0

**Breaking:** v3 works only on `.dj-agents/`. The v2 working folder is read only by `/dj-migrate`; no other skill opens it, and there is no fallback. Rollback is `git checkout v2.0 && ./install.sh` (see "Rollback" in GUIDE.md).

### Foundations

- One root, `.dj-agents/`, next to the repositories: `knowledge/` for the shared map, `repos/<repo>/` per repository. Found by walking up; the repository name comes from git's main checkout, so worktrees share one area. Nothing is written inside a client repository.
- New script `dj-root` prints the root, the repository name, the area and the knowledge path. The layout reference lives in `skills/dj-start/templates/dj-agents-layout.md`.
- `/dj-start --adopt` gives an existing repository its area, detecting commands and branching from the repository. On an area that lacks base files (a migrated repository) it fills only the missing ones.
- State holds only what is active: `current.md` is an index of active features, each feature has a `state.md`, `handoff.md` is rewritten at every close. What stops being active moves; nothing is deleted.
- `.dj-agents/` is its own git repository. Task and fix closes commit inside it (`dj_agents_commit`, default `auto`); the client repository's commit policy is unchanged.
- `install.sh` also installs the scripts (`~/.claude/scripts/dj/`) and warns that a project-level install writes `.claude/` inside that directory.

### The map

- Knowledge templates: index, glossary, flows, decisions, questions, library, review rules, false positives, inbox, architecture and patterns, each with its update rule and provenance labels.
- `/dj-map --architecture` and `--refresh`, with the new `dj-repo-mapper` agent: the repository's layers, seams, invariants and deviations, each with the command that proves it. The whole-repo codebase map is retired; the feature map stays.
- New command `/dj-ingest`: threads, memos, tickets, hand-made PR packets and "save this explanation" become staged inbox entries with provenance labels; nothing reaches the map before approval; names are removed.
- The planner reads the map and writes Placement, a business why and rejected approaches into each packet; the implementer follows Placement; the scout corrects the map with code evidence; each task close proposes one to three map lines for approval.
- New command `/dj-migrate`: once per machine, copies the v2 working folders into the root, seeds the map through the inbox, strips names and marks each old folder with `MIGRATED.md`; `--merge` adds a second machine's data without overwriting.
- New script `dj-sync`: `pack`, `unpack`, `clone` and `status` move the root between machines as git bundles since a `last-sync` tag.

### Blind review

- `dj-ts-reviewer`, `dj-elixir-reviewer` and `dj-pr-reviewer` are blind reviewers: the range, the touched files, one Goal line and three map files; never the packet, the report or the PR description. Two gates (runtime with a Trigger, structural with a named boundary and a written rule or precedent), two severity scales, no count cap; "Nothing to report" and "Couldn't verify" are valid results.
- `/dj-task` and `/dj-fix`: the blind review replaces the stack review; the orchestrator filters every candidate (discard with a reason, apply when small and clear, or send to the human); one fix list, no re-review, two rounds at most; out-of-scope findings go to `follow-ups.md`.
- `/dj-review`: code before description and a "Description vs code" gap line; one delegated blind pass; a layered dossier; the human's filter feeds false positives, review rules and the library through one approval. Merged PRs and `--base <ref>` are supported; a branch is read where it is, never checked out.
- The reviewers read the code at the reviewed head or the working tree and never change the caller's checkout or index. `dj-implementer` has a narrower tool list; the repo-patterns and simplicity lenses gained rules for renames, guards and duplication.

### What the human reads

- The task report opens with five fixed parts: outcome, "I need from you", "Not verified", "Business rules changed", "Deviations". Depth below, plus a staging table and a `Lengths:` line.
- The guide is layered and newest first: business why, metrics from `diff-metrics`, what can break and yes/no checks to approve; below a marker, flow, removed lines, added lines only file by file, and tests with three answers.
- PR size is estimated and shown, never enforced: per-PR estimates, a split as the default recommendation when large, sequential PRs by default, a hosting check before any stack, a branch plan, a `PR:` field in packets, a meter at task close and a re-slicing procedure. `pr-strategy.md` carries `hypothesis`, `pr-split-needed` or `revised`.
- New scripts `diff-metrics`, `staging-table`, `pr-meter` and `line-count`. They read and print; no skill treats a number as a limit.
- README and GUIDE rewritten for v3, with the migration checklist and rollback. Every comment, description and ticket a skill writes stays a draft that the human rewrites and posts.

## v2.0

The rollback point: the last version that works on the v2 working folder inside each repository.
