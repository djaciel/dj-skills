# dj-skills

A lightweight agentic cockpit for [Claude Code](https://code.claude.com/docs/en/overview) — you stay the architect, agents do specialist work. Eight visible commands, eight specialist subagents, and eleven small quality lenses turn Claude Code into a structured but flexible development partner for real work: new projects, features in existing repos, bug fixes, peer PR review, and the human communication around all of it.

## Why

dj-skills is the successor of the author's previous system, Phased Build Skills (PBS). PBS proved that external memory, small tasks, and human review checkpoints work — and also that twenty visible skills, rigid gates, giant reports, and questionnaire-style discovery create more friction than quality.

This system keeps what worked and drops the ceremony:

- A handful of visible commands instead of a skill per micro-step.
- Specialist subagents instead of one monolithic prompt doing everything.
- Living specs and acceptance checks instead of contracts frozen weeks in advance.
- Judgment questions instead of rigid numeric rules.

The goal is not an AI that never makes mistakes. The goal is an AI that works like a mid-senior developer whose errors are small, visible, and cheap to correct — while you keep the architect's judgment: you define intent, validate plans, review diffs, decide trade-offs, and control commits.

## Core ideas

- **External memory in `.agent/`** — project state, specs, task packets, drift logs, and handoff notes live in files, not in chat history. Any fresh session can pick up exactly where the last one stopped.
- **Living specs** — Feature Spec → Phase → Task Packet, all revisable. When reality diverges from the plan, drift is logged and triggers a replan — never a silent restart from zero.
- **Small task packets** — one conceptual objective, clear validation commands, human-reviewable in 10–20 minutes.
- **Specialist subagents** — scout, planner, implementer, reviewers, writer. Each has one job, restricted tools, and a defined output format.
- **Evidence-based review** — a finding without evidence is a question, not a finding. No invented race conditions, no impossible edge cases, no zero-value nits.
- **Clear language policy** — converse in whatever language you prefer; everything that leaves your machine (code, commits, PR descriptions, review comments) is always English.
- **Self-contained** — the system has zero dependencies on third-party skills. External expertise skills are optional plugins registered per project, never requirements.

## How it fits together

Five pieces: visible commands, the `.agent/` directory as external memory, specialist subagents, small optional skills, and deterministic hooks/scripts. A typical interaction:

```text
You
  ↓
Visible command (/dj-task T-03)
  ↓
Main Claude session
  ↓
Reads .agent/ (current state, task packet, spec)
  ↓
Invokes subagents where useful (scout, implementer, reviewers)
  ↓
Subagents apply quality lenses (simplicity, repo patterns, test quality)
  ↓
Hooks/scripts validate deterministic things (format, typecheck, tests)
  ↓
Main session reports back with evidence
  ↓
You review and decide
```

Deterministic checks (formatting, typecheck, tests, secret-blocking) belong in hooks and scripts, not in prompts — the model should never have to "remember" to run them. See GUIDE.md for an example hook setup.

## Installation

### Option A: `npx skills` (recommended)

```bash
# from GitHub
npx skills add djaciel/dj-skills --all -g

# or from a local clone
npx skills add /path/to/dj-skills --all -g
```

Drop `-g` to install into the current project (`.claude/`) instead of user-level (`~/.claude/`). The CLI symlinks by default, so `git pull` on the clone updates your installed skills; add `--copy` if you want plain copies. Use `-l` to list what would be installed, or omit `--all` to pick skills interactively.

**The subagents are not covered by the skills CLI** — copy them manually:

```bash
cp /path/to/dj-skills/agents/*.md ~/.claude/agents/    # or .claude/agents/ inside a project
```

### Option B: manual copy/symlink

**User-level (available in every project):**

```bash
git clone https://github.com/djaciel/dj-skills.git
cd dj-skills
mkdir -p ~/.claude/skills ~/.claude/agents
cp -R skills/* ~/.claude/skills/
cp agents/*.md ~/.claude/agents/
```

**Project-level (one project only):**

```bash
mkdir -p .claude/skills .claude/agents
cp -R /path/to/dj-skills/skills/* .claude/skills/
cp /path/to/dj-skills/agents/*.md .claude/agents/
```

Prefer symlinks if you want `git pull` updates to propagate automatically.

Each installed skill is invocable by its name (e.g. `/dj-start`, `/dj-task`). The eight command skills below are the intended entry points; the lens skills are mostly applied automatically by the commands and subagents. Commands degrade gracefully: if a subagent is not installed, the same work happens inline in the main session.

## What you get

### Commands (8)

| Command | Purpose |
|---|---|
| `/dj-start` | Start a new project from an idea or brain-dump: smart intake, work mode, base `.agent/` files, focused discovery |
| `/dj-map` | Understand an existing repo or repo area before planning — produces a compact codebase map |
| `/dj-plan` | Turn intent into a living spec, phases, task packets, and PR strategy; also replans after drift |
| `/dj-task` | Execute one task packet end-to-end: implement, validate, audit tests, review, report |
| `/dj-review` | Review someone else's PR, branch, or diff — produces a reviewer dossier and draft comments |
| `/dj-fix` | Investigate and fix a bug: reproduce first, confirm root cause, minimal fix, fix report |
| `/dj-brief` | Generate human communication from work already done: PR description, commit message, ticket, team update |
| `/dj-explore` | Compare 2–3 approaches when there is real architectural uncertainty |

### Subagents (8)

| Subagent | Purpose |
|---|---|
| `dj-scout` | Read-only repo exploration: relevant files, existing patterns, reusable code, duplication risk |
| `dj-planner` | Turns intent into feature spec, delivery plan, task packets, and PR strategy — writes only inside `.agent/` |
| `dj-implementer` | Implements one task packet: stays in scope, reuses existing patterns, runs real validation |
| `dj-ts-reviewer` | TypeScript/Node review lens: types, duplication, modularity, error handling, async flows |
| `dj-test-auditor` | Judges whether tests add value: behavior over implementation, realistic edge cases only |
| `dj-acceptance-reviewer` | Judges whether the diff fulfills the task/spec intent — not whether the code is pretty |
| `dj-pr-reviewer` | Reviews external PRs under the evidence rule: findings, questions, and discarded suspicions |
| `dj-writer` | Turns technical analysis into human communication, honoring the project's language policy |

### Core skills (11)

| Skill | Purpose |
|---|---|
| `dj-simplicity-lens` | The seven "does this need to exist?" questions before writing new code |
| `dj-repo-patterns` | Find precedent before creating: reuse scan, follow local conventions, justify new patterns |
| `dj-test-quality` | What makes a test worth having — and when a test is not worth adding |
| `dj-acceptance-review` | The four acceptance levels, seven task end states, and how to judge a diff against intent |
| `dj-human-comments` | Review comments a teammate will actually welcome: kind, evidence-linked, questions before verdicts |
| `dj-commit-message` | Suggest commit messages that match the repo's existing convention; suggest, never commit |
| `dj-pr-description` | PR descriptions written for the reviewer's 15 minutes: what/why, reading order, evidence |
| `dj-pr-slicing` | Decide PR boundaries by reviewable story, not by file counts |
| `dj-data-flow-review` | Reconstruct input → transform → output before judging any diff |
| `dj-task-report` | The compact task completion report: changes, real validation output, review order |
| `dj-drift-management` | Detect drift, log it, decide absorb vs replan vs split — and mark obsolete docs |

## Quick start

**1. New project from an idea:**

```text
/dj-start expense-tracker
# paste your notes or a conversation with another AI;
# answer at most 3–5 blocking questions
/dj-plan            # spec, phases, task packets
/dj-task T-01       # execute the first task
```

**2. Feature in an existing repo:**

```text
/dj-map packages/sdk          # compact codebase map of the area
/dj-plan funding-recovery     # spec + tasks grounded in that map
/dj-task T-01
```

**3. Review a teammate's PR:**

```text
/dj-review branch feat/onramp-validation against main
# read the reviewer dossier, keep the findings you agree with
/dj-brief review-comments     # draft English comments for the keepers
```

For full workflows, work modes, drift handling, session management, hooks, and the external skills policy, read **[GUIDE.md](GUIDE.md)**.

## A note on `.agent/`

The commands generate a `.agent/` directory in each project you use them on. It is working memory — project context, current state, specs, task packets, reports — not part of this repo. You will usually want to add `.agent/` to that project's `.gitignore`; keep it tracked only if your team deliberately wants to share planning state.
