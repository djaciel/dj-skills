# dj-skills Usage Guide

Pick your situation, run the recipe. Every recipe tells you: what to type, what you get back, and what your job is at each checkpoint. Concepts live [at the end](#concepts) — you don't need them to start.

| You are... | Go to |
|---|---|
| Starting a brand-new project | [Recipe 1](#recipe-1--new-project) |
| Adding a feature to an existing repo | [Recipe 2](#recipe-2--feature-in-an-existing-repo) |
| Executing planned tasks | [Recipe 3](#recipe-3--day-to-day-tasks) |
| Reviewing someone else's PR | [Recipe 4](#recipe-4--review-a-teammates-pr) |
| Fixing a bug or issue | [Recipe 5](#recipe-5--fix-a-bug) |
| Writing a PR description, commit, ticket, or update | [Recipe 6](#recipe-6--generate-communication) |
| Torn between two approaches | [Recipe 7](#recipe-7--compare-approaches) |
| Plan no longer matches reality | [Recipe 8](#recipe-8--drift--replan) |
| Continuing work in a fresh session | [Recipe 9](#recipe-9--resume-in-a-fresh-session) |

---

## Recipe 1 — New project

```text
/dj-start expense-tracker     # paste your idea dump: notes, links, an AI conversation
/dj-plan                      # spec + phases + task packets
/dj-task T-01                 # first task
```

**What happens:** `/dj-start` reads your dump, asks **at most 3–5 blocking questions** (everything else becomes an assumption you can correct), sets the work mode and language, and creates the `.dj-agents/` base files. `/dj-plan` turns that into a spec, phases, and task packets.

**Your job:**
1. Dump everything you have — messy is fine.
2. Answer the questions; correct any wrong assumption in the list it shows you.
3. Approve (or edit) the plan.
4. From there, loop Recipe 3.

## Recipe 2 — Feature in an existing repo

```text
/dj-map src/billing           # only if the area is new to you — skip it otherwise
/dj-plan usage-based-invoicing
/dj-task T-01
```

**What happens:** `/dj-map` produces a compact codebase map (files, patterns, utilities, risks — a reading order, not an encyclopedia). `/dj-plan` builds spec + tasks grounded in it; once a map exists, every later exploration reuses it instead of re-crawling the repo.

**Your job:** approve the plan, then loop Recipe 3.

**Skip `/dj-map`** when you already know the area — go straight to `/dj-plan`.

## Recipe 3 — Day-to-day tasks

```text
/dj-task T-03                       # one task
/dj-task T-01..T-04                 # short sequence — full loop per task, one at a time
/dj-task T-01..T-04 --autonomous    # only if you enabled autonomous commits
```

**What happens inside** (automatic; rigor scales with your work mode): read state → scout context → implement (delegated to dj-implementer) → run validations with real output → test audit → stack review → acceptance review → report, guide, and hand off.

**What you get:** a 2-minute report — changes per file, validation evidence, review order, suggested commit — saved to `.dj-agents/repos/<repo>/features/<feature>/reports/T-XX.md`, plus a review guide appended to `.dj-agents/repos/<repo>/features/<feature>/guide.md` (file-by-file, test-by-test, every deletion audited). Want the deep dive? Say **"walk me through T-03"** → goal, data-flow map, and file-by-file functions in plain words.

**Your job:**
1. Read the report (start with the review order).
2. Review the diff.
3. Commit — nothing is committed for you by default.

A task can end `done`, but also `blocked`, `needs-replan`, `split-needed`... — anything not `done` tells you exactly what decision it needs (see Recipe 8 for drift).

## Recipe 4 — Review a teammate's PR

```text
/dj-review branch feat/onramp-validation against main
# → read the Reviewer Dossier, tell it which findings to keep
/dj-brief review-comments
# → copy the drafted English comments into the PR yourself
```

**What you get:** a **Reviewer Dossier** (`.dj-agents/repos/<repo>/reviews/<pr>/reviewer-dossier.md`) written for someone who does *not* know that area of the codebase: every component explained on first mention, the files walked from the most foundational up with every change explained function by function, then *findings worth considering* (with evidence), *questions*, and *discarded suspicions* (things it checked and ruled out, so you don't re-check them). Then `comments.md` with kind, ready-to-paste English comments for the findings you kept.

**Depth & cost:** the default is a single careful pass — one reviewer, each file read once, no agent fleets. Add `--deep` only for high-stakes PRs (money, auth, data integrity): it independently verifies Blocking findings, consulting library sources. Deep costs several times more, and it is always your call — the skill will offer it, never assume it.

**Your job:** filter the findings — you decide what gets said. **Nothing is ever posted automatically.**

## Recipe 5 — Fix a bug

```text
/dj-fix GH-123
# → review the diff and the fix report
/dj-brief pr-description      # if the fix ships as a PR
```

**What happens:** reproduce (or write a failing test) **first** → confirm the root cause, not the symptom → minimal fix → validation → fix report with before/after test evidence. It will not wander into refactors mid-fix.

**Your job:** confirm the reproduction matches the real bug, review the diff, commit.

## Recipe 6 — Generate communication

```text
/dj-brief pr-description
/dj-brief commit
/dj-brief ticket "funding recovery follow-ups"
/dj-brief team-update
```

**What happens:** it writes from the `.dj-agents/` artifacts (task reports, fix reports, dossiers) — it never re-analyzes code. External text is always English, honoring the English level in your language policy (`simple (B1/B2)` = plain words, short sentences).

**Your job:** read the draft, edit if you want, and post/send/commit it yourself.

**Do the work first, then brief it** — if no analysis exists yet, run Recipe 3/4/5 first.

## Recipe 7 — Compare approaches

```text
/dj-explore T-04 --approaches 2
```

**Only for real uncertainty** — two plausible architectures, a risky integration, a migration with several routes. Not for every task. Compares on paper by default; implements in separate worktrees only if you authorize it. Ends with a recommendation and the losing approaches explicitly discarded, so the question is never relitigated by accident.

## Recipe 8 — Drift / replan

When reality stops matching the plan (a task's premise died, scope changed, an assumption broke):

```text
# minor drift → nothing to run: the task ends `done-with-drift` and gets logged
/dj-plan --replan-from T-04     # major drift → replan from the divergent task
```

**What happens:** the replan keeps everything still valid, marks dead tasks `obsolete`, updates the spec, and rewrites future tasks. **It never restarts from zero.** Obsolete docs get listed under "Do not follow" in `current.md` so no session ever obeys a dead spec.

## Recipe 9 — Resume in a fresh session

```text
# new session, same project — just say:
Continue with <feature>. Read .dj-agents/repos/<repo>/current.md first.
```

That's it: `current.md` holds the active task, the current direction, and what NOT to follow; `handoff.md` holds the context. Both are updated automatically when tasks close — if you're ending a session mid-task, ask for the handoff update before closing.

---

# Concepts

Everything below is background — the recipes above already apply it for you.

## The three roles

- **You are the architect:** intent, plan approval, diff review, trade-offs, commits.
- **The agent is a mid-senior developer:** competent, in scope, no blind trust — it reports what it finds instead of acting beyond scope.
- **The system keeps errors small, visible, and cheap to correct:** small tasks, real validation output, evidence-based review, external memory.

## The `.dj-agents/` root

Per-project external memory — chat history is disposable, `.dj-agents/` is not. Usually gitignored.

| File | Role |
|---|---|
| `current.md` | Active state. **Always read first.** Includes "Do not follow" (obsolete docs) |
| `project.md` | Stable context: stack, commands, work mode, constraints |
| `handoff.md` | What a fresh session needs to continue |
| `features/<f>/tasks/T-XX.md` | Task packets — the unit of work |
| `features/<f>/drift-log.md` | Every scope/direction change, with per-task impact |
| `features/<f>/guide.md` | Human-review guide, one section per task, appended on every task close |
| `features/<f>/reports/T-XX.md`, `features/<f>/scout/T-XX.md` | Saved task report and scout result per task |
| `features/<f>/` also holds | brief, discovery, spec, delivery-plan, pr-strategy, codebase-map |
| `issues/<id>/`, `reviews/<pr>/` | Fix and review artifacts |

## Work modes

Set at `/dj-start` (or by hand in `project.md`), adjustable any time:

| Project type | Human reviews | Reviewers per task | Commit policy |
|---|---|---|---|
| `production-work` | every task | test audit + stack review + acceptance | `human-only` |
| `personal-medium` | checkpoints | test audit + acceptance | `human-only` |
| `personal-small` | per phase | acceptance only (or none) | `human-only` unless you loosen it |

Default commit policy everywhere: no auto-commit, no push, no auto-PR, no co-author lines. `--autonomous` only when you say so.

Branching is policy too: `project.md` records the base branch, the naming convention (`feat/…`, `fix/…`), and whether the agent creates branches or only suggests them. `/dj-task` and `/dj-fix` check it before touching files — and if no policy is written, they ask once and record the answer.

**Language policy** (in `.dj-agents/repos/<repo>/language-policy.md`): *internal* = whatever you converse in; *external* = always English, with an **English level** — `simple (B1/B2)` (plain words, short sentences) or `natural`. Words get simplified, facts never. The policy also carries a **writing style** for everything you share (cautious tone, impersonal register for reports, no dashes as punctuation, depth on demand) — `dj-writer` applies it to every artifact, and its defaults kick in even when the file doesn't exist.

## Living acceptance & task end states

Task packets classify checks in four levels: **Hard** (must pass) · **Soft** (desirable, judged) · **Exploratory** (may change) · **Deferred** (later task). Checks are living contracts — when reality proves one wrong, it's updated through the drift log, never silently ignored.

Tasks end in one of: `done · done-with-drift · blocked · needs-replan · split-needed · merged-into-next · obsolete`.

## Sessions & context

The orchestrating session is designed to stay light: implementation and reviews run in subagents (only compact results return), and every task close saves state to `.dj-agents/` — so the session is disposable at any moment. Guidance, not law: up to ~75% of context, keep going; at 75–85%, close the slice and start fresh; past 85%, don't start anything new. When you do cut, prefer a fresh session over compacting — compaction produces a variable summary, while `.dj-agents/` always restores the same state. Recipe 9 makes fresh sessions cheap.

## Multi-repo setups

One `.dj-agents/` at the root, one `CLAUDE.md` per repo. Register sibling repos and shared docs **once** in `project.md` under "Related repos & context sources" — scout and planner consult them automatically, so you never re-explain the paths. Cross-repo task packets declare the contract explicitly:

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

## Optional hooks

Deterministic checks (format, typecheck, tests, secret-blocking) belong in hooks, not prompts. Example `.claude/settings.json` fragment:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": ".claude/hooks/block-secrets.sh" }] }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": ".claude/hooks/format-edited-files.sh" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": ".claude/hooks/typecheck-and-tests.sh" }] }
    ]
  }
}
```

Hooks are optional — the system works without them — but they are the cheapest reliability upgrade available.

## External skills policy

dj-skills depends on **zero** third-party skills. A missing expert skill lowers specialized expertise; it never breaks a workflow. If you find a trustworthy one, register it in `.dj-agents/repos/<repo>/expertise-registry.md` and evaluate it like a dependency first (source, safety, quality — see the template in `skills/dj-start/templates/expertise-registry.md`). No external skill goes straight into production work; sandbox it first.
