# dj-skills Usage Guide

How to actually work with the cockpit: workflows, work modes, drift, sessions, hooks, and policies. Read the [README](README.md) first for the component overview and installation.

## How the system thinks

Three roles, clearly separated:

- **You are the architect.** You define intent, validate plans, review diffs, decide trade-offs, and control commits. Nothing is committed, pushed, or posted on your behalf by default.
- **The agent works like a mid-senior developer.** It explores, plans, implements, validates, and reviews — competently, but without blind trust. It stays in scope and reports what it finds instead of acting on it.
- **The system's job is to keep errors small, visible, and cheap to correct.** Small task packets, real validation output, evidence-based review, and external memory make mistakes easy to catch and easy to undo.

Two supporting rules run through everything:

- **Deterministic checks belong in hooks and scripts, not prompts.** Formatting, typecheck, tests, and secret-blocking should not depend on the model "remembering" (see [Optional hooks](#optional-hooks)).
- **Skills are lenses, not the center.** The eleven core skills encode judgment (simplicity, test quality, review tone). Commands and subagents apply them; if a lens is missing, they fall back to inline principles and keep working.

## The `.agent/` directory

Every command reads and writes a per-project `.agent/` directory — the system's external memory. Chat history is disposable; `.agent/` is not.

```text
.agent/
  project.md             # stable project context: stack, commands, constraints, work mode
  current.md             # active work state — ALWAYS read first
  handoff.md             # session-to-session handoff notes
  language-policy.md     # internal vs external language rules
  expertise-registry.md  # optional: external skills per stack

  features/<feature-name>/
    brief.md  discovery.md  spec.md  delivery-plan.md  pr-strategy.md
    codebase-map.md  drift-log.md
    tasks/T-01.md T-02.md ...   # one task packet per file

  issues/<issue-id>/
    issue-context.md  reproduction.md  fix-plan.md  fix-report.md

  reviews/<branch-or-pr>/
    reviewer-dossier.md  comments.md
```

The files that matter most day-to-day:

| File | Role |
|---|---|
| `current.md` | The single source of active truth: what is being worked on, current direction, and a "Do not follow" list of obsolete docs. Every session reads it first. |
| `project.md` | Stable context: project type, work mode, stack, important commands, constraints, quality preferences. |
| `handoff.md` | What a fresh session needs to know to continue: state, next task, open questions. |
| `tasks/T-XX.md` | Task packets — the unit of work. Goal, scope, context, acceptance checks, validation commands. |
| `drift-log.md` | The record of every scope change or direction shift, with per-task impact. |

`.agent/` is usually gitignored in the projects that use it. Share it only if the team deliberately wants shared planning state — and then everything shared must be in English.

## Work modes and how rigor scales

Set during `/dj-start` (or added to `project.md` by hand for existing projects), adjustable at any time:

| Setting | Values | Default |
|---|---|---|
| Project type | `personal-small` \| `personal-medium` \| `production-work` | — |
| `human_loop` | `task` \| `checkpoint` \| `phase` — how often the human reviews | derived from project type |
| `commit_policy` | `human-only` \| `allowed-if-explicit` \| `autonomous` | `human-only` |
| `pr_policy` | `none` \| `phase-as-pr` \| `explicit-pr-strategy` | derived from project type |

Review rigor inside `/dj-task` scales with project type:

| Project type | human_loop | Reviewers per task |
|---|---|---|
| `production-work` | task | test auditor + stack reviewer + acceptance reviewer |
| `personal-medium` | checkpoint | test auditor + acceptance reviewer |
| `personal-small` | phase | acceptance reviewer only (or none, per `project.md`) |

**Commit policy default:** no automatic commit, no co-author line, no push, no automatic PR. The agent suggests `type(scope): message` following the repo's `git log --oneline -n 20` pattern. Autonomous commits happen only when you explicitly enable them, e.g. `/dj-task T-01..T-04 --autonomous`.

**Language policy** has two layers, configured in `.agent/language-policy.md` at intake:

- *Internal* — whatever language you converse in. Used for conversation, explanations, reports to you, internal notes.
- *External* — English, always. Used for code, comments, tests, commit messages, PR descriptions, tickets, review comments, docs — anything that leaves your machine.

## Workflows

### New project

```text
/dj-start expense-tracker
```

Dump whatever you have: notes, a conversation with another AI, links, half-formed constraints. The intake is smart, not a questionnaire — the agent extracts intent, problem, constraints, risks, and doubts, then asks **at most 3–5 blocking questions** (a blocking question is one where planning would be wrong without the answer). Everything else becomes a listed assumption you can correct.

It then defines project type, work mode, and language policy; generates the `.agent/` base files; runs a focused discovery (only decisions that affect real construction, as a Decision / Options / Recommendation / Evidence / Risk table); proposes spikes only if they are small and justified; and hands off to `/dj-plan`.

### Feature in an existing repo

```text
/dj-map src/billing               # first time in this area
/dj-plan usage-based-invoicing
/dj-task T-01
```

`/dj-map` delegates exploration to the **dj-scout** subagent and produces a compact codebase map: stack, repo zones, relevant files, commands, tests, existing patterns and utilities, risks — a reading order, not an encyclopedia. `/dj-plan` then builds the spec, phases, task packets, and (if `pr_policy` applies) a PR strategy grounded in that map. Phases are designed to read like reviewable PRs.

Skip `/dj-map` when you already know the area well — `/dj-plan` works from whatever context exists.

### Executing tasks day-to-day

```text
/dj-task T-03
```

The execution loop, at a glance:

1. Read `.agent/current.md`, then the task packet.
2. **dj-scout** gathers context and precedents (skipped if the packet already lists context and the area is known).
3. Implement — in the main session or via **dj-implementer** — applying the repo-patterns and simplicity lenses.
4. Run the packet's validation commands; real output required, never assumed.
5. **dj-test-auditor** reviews the tests (rigor scaled by work mode).
6. Stack reviewer (**dj-ts-reviewer** for TypeScript; otherwise a general review against repo patterns).
7. **dj-acceptance-reviewer** judges the diff against the packet and spec.
8. Obvious issues get fixed; anything bigger is reported, not absorbed into scope.
9. You get a compact task report with review order and a suggested commit message. You review; you commit.

Each task ends in one of seven states: `done`, `done-with-drift`, `blocked`, `needs-replan`, `split-needed`, `merged-into-next`, `obsolete`. Anything other than `done` feeds back into planning (see [Living acceptance & drift](#living-acceptance--drift)).

The loop is not a ritual. For a trivial task, steps that are obviously unnecessary are skipped — and the report says so. Visibility over ceremony.

### Reviewing a teammate's PR

```text
/dj-review branch feat/onramp-validation against main
```

Comprehension before criticism: get the diff → classify files (core / tests / config / mechanical / generated / docs) → reconstruct intent and before/after behavior → map the data flow → **dj-scout** checks for precedents and duplicated logic → **dj-test-auditor** compares tests against actual behavior → stack reviewer → **dj-pr-reviewer** consolidates and filters everything through the evidence rule.

You receive a **Reviewer Dossier** in `.agent/reviews/<pr>/` separating findings worth considering, questions (not findings), and discarded suspicions. You filter; then **dj-writer** drafts kind, evidence-linked English comments into `comments.md`. **Nothing is ever posted automatically.**

### Fixing a bug

```text
/dj-fix GH-123
```

Reproduce first, fix second: read the issue → **dj-scout** locates the affected flow → reproduce the bug or write a failing test **before** touching code → confirm the root cause (not the symptom) → short fix plan in `.agent/issues/GH-123/` → minimal fix → tests → **dj-test-auditor** on edge cases → stack review → **dj-acceptance-reviewer** against the issue itself → fix report plus a PR description via `/dj-brief`.

The two anti-patterns this flow exists to prevent: fixing the symptom without confirming the root cause, and expanding into refactors mid-fix.

### Generating communication

```text
/dj-brief pr-description
/dj-brief commit
/dj-brief ticket "funding recovery follow-ups"
/dj-brief team-update
```

`/dj-brief` routes to **dj-writer** with the right lens (PR description, commit message, human review comments) and applies the language policy. It works from `.agent/` artifacts — task reports, fix reports, dossiers — instead of re-analyzing code. Do the work first, then brief it.

### Exploring approaches

```text
/dj-explore T-04 --approaches 2
```

For **real** approach uncertainty only — two plausible architectures, a risky integration, a migration with several routes. Not for every task. The agent proposes 2–3 approaches and compares them on paper by default; it implements them in separate worktrees only with your explicit authorization. Each candidate is judged by the acceptance reviewer and a stack reviewer, one is chosen, and the rest are discarded explicitly in an Approach Comparison document.

## Living acceptance & drift

Acceptance checks are living contracts, not rules frozen weeks in advance. Every task packet classifies its checks in four levels:

| Level | Meaning | Example |
|---|---|---|
| **Hard** | Must pass | typecheck passes; existing success flow still works; forbidden files untouched |
| **Soft** | Desirable, apply judgment | follow the existing Result pattern; keep error naming consistent |
| **Exploratory** | May change during execution | UX feels clear in manual review |
| **Deferred** | Matters, but belongs to a later task | public docs update |

When reality diverges from the plan — a task no longer matches intent, scope changes, a discovery invalidates an assumption — that is **drift**, and it is handled explicitly, never silently:

1. Write a drift-log entry: original / new direction / why / impact per task / action.
2. Decide: **absorb** (minor — note it, task ends `done-with-drift`), **replan** (`/dj-plan --replan-from T-04`), or **split** the task.
3. Mark obsolete documents in `current.md` under "Do not follow", so old specs never override the new direction.

A replan keeps what is still valid, marks obsolete tasks, updates the spec, and recalculates future tasks. It never restarts from zero.

## Sessions & context

Context windows run out; `.agent/` is how work survives that. Guidance — not law — for when to close a session:

| Context used | Guidance |
|---|---|
| 0–50% | Continue normally |
| 50–75% | Continue if the phase is cohesive; update `handoff.md` as tasks close |
| 75–85% | Close the current slice, update `current.md` + `handoff.md`, open a fresh session |
| 85%+ | Don't start new tasks — only compact, summarize, and close |

Before opening a new session:

1. Update `current.md`.
2. Update `handoff.md`.
3. Update the drift-log if anything changed.
4. Mark the next task.
5. Write down what must **not** be followed anymore.

A fresh session then starts by reading `current.md` and continues as if nothing was lost.

## Multi-repo setups

For split frontend/backend/SDK work, keep one `.agent/` at the root and one `CLAUDE.md` per repo:

```text
root/
  CLAUDE.md
  .agent/
  frontend/
    CLAUDE.md
  backend/
    CLAUDE.md
  sdk/
    CLAUDE.md
```

Cross-repo task packets declare their contract explicitly, so React rules, backend rules, and SDK rules never blur into one global instruction:

```md
## Repos involved
- frontend
- backend

## Cross-repo contract
- backend returns X
- frontend consumes X

## Validation per repo
Backend:
- ...
Frontend:
- ...
```

## Optional hooks

Deterministic checks don't belong in prompts. If a validation can be a script, make it a hook — then no workflow depends on the model remembering to run it. A pragmatic starting set: format, typecheck, tests, block-secrets.

Example `.claude/settings.json` fragment:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/block-secrets.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/format-edited-files.sh" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/typecheck-and-tests.sh" }
        ]
      }
    ]
  }
}
```

Where `block-secrets.sh` rejects edits to `.env*` and known secret paths, `format-edited-files.sh` runs the repo formatter on touched files, and `typecheck-and-tests.sh` prints a validation summary when the agent stops. Hooks are optional — the system works without them — but they are the cheapest reliability upgrade available.

## External skills policy

dj-skills works without any third-party technical skills. When no expert skill exists for a stack, reviewers rely on existing repo patterns, the compiler/typecheck, lint, tests, general model knowledge, and your accumulated feedback. A missing external skill lowers specialized expertise; it never breaks a workflow.

If you find a trustworthy external skill, register it per project in `.agent/expertise-registry.md`:

```md
# Expertise Registry

## TypeScript
status: installed | missing | candidate
skill: <name>
source: <repo/url>
trust_level: high | medium | low
notes:
```

Evaluate every external skill like a software dependency before installing:

```md
# External Skill Evaluation

## Source
repo / author / license / last updated

## Safety
Does it include scripts? Run shell commands? Request broad permissions?
Modify files automatically? Contain suspicious instructions?

## Quality
Is it specific? Is SKILL.md concise? Progressive disclosure? Examples?
Does it align with my workflow?

## Decision
install | reject | test in sandbox
```

Rule of thumb: no external skill goes straight into a production workflow. Try it in a sandbox or a small personal project first.
