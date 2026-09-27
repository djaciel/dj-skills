---
name: dj-simplicity-lens
description: Use when about to write new code (especially new helpers, wrappers, abstractions, types, or dependencies) and when reviewing a diff that looks larger or more abstract than the problem it solves.
---

# Simplicity Lens

## Overview

The best code is the code you didn't write. Write only necessary, maintainable code: reuse the repo, the language/runtime, and already-installed dependencies before building anything new.

This is NOT "write minimal code at any cost". Cutting safeguards to save lines is a bug, not simplicity.

## When to use

- Before implementing a task, as a pre-write checkpoint.
- During code review, when judging whether a diff is over-built for its goal.
- Whenever you are about to create a helper, wrapper, abstraction, base class, or propose a new dependency.
- In the **dj-review** skill, the blind reviewer (the **dj-pr-reviewer** subagent, or the session inline) asks questions 1 and 5 to 7 against the diff alone, for its Shape scale; questions 2 to 4 need a repository search and are not asked by a blind reviewer.

**When NOT to use:**

- To justify removing validation, error handling, or tests. That is not simplification. See the do-not-sacrifice list below.
- To ration code that genuinely needs to exist. The lens filters unnecessary code; it does not block necessary code.

## The 7 questions

Ask in order before writing new code:

1. **Does this need to exist?** What breaks or is missing without it?
2. **Does the repo already have this?** A similar util, type, hook, component, fixture. **COMPANION SKILL:** dj-repo-patterns. Run its reuse scan; if it is not available, grep the repo for similar symbols before creating new ones.
3. **Does the language or runtime already provide this?** stdlib, built-in APIs, platform features.
4. **Does an installed dependency already provide this?** Check the manifest/lockfile before re-implementing, and before proposing a new dependency.
5. **Can this be solved with a smaller change?** A new parameter, a two-line edit to an existing function, a config change.
6. **Does the new abstraction actually reduce complexity?** An abstraction with one caller usually adds complexity instead of removing it.
7. **Is the extra code improving maintainability, or only satisfying the urge to build?** "It might be useful later" is the urge to build.

If questions 2 to 5 turn up an existing answer, reuse or extend it. Write new code only when all seven questions survive.

After the change takes shape, ask against the diff you produced whether the new code now repeats an existing path's steps in the same order. That duplication was created by this change, and removing it is part of this change, not a follow-up.

## Do not sacrifice

Simplicity never justifies dropping:

- security
- input validation
- accessibility
- type safety
- error handling
- testability
- clarity

If a "simplification" cuts one of these, keep the safeguard and simplify somewhere else.

## Heuristics beat rules

Absolute rules ("never use ternaries") are sometimes wrong; vague rules ("keep it readable") are always useless. Prefer a heuristic plus one concrete example. The ternary heuristic is the model:

Ternaries are fine when they express one simple choice. Avoid them when nested, when more than one condition is involved, or when an if/else with named variables would state the intent more clearly.

```ts
// Fine: one simple choice
const label = isActive ? "Active" : "Inactive";

// Over-built: the reader must simulate four states
const status = user?.enabled
  ? user.role === "admin" ? "admin-active"
  : hasPendingInvite(user) ? "pending" : "member"
  : "disabled";
```

Apply the same shape to helpers, wrappers, and abstractions: judge the specific case against the 7 questions, not against a blanket rule. When the same over-building mistake repeats across tasks, promote the correction: a rule in `.dj-agents/repos/<repo>/project.md`, an example in a skill, a lint rule or hook if it can be automated.

## Common mistakes

- Treating the lens as code golf: deleting error handling or tests to shrink the diff.
- Creating an abstraction for a single caller "for future flexibility".
- Re-implementing something the stdlib or an installed dependency already provides.
- Adding a dependency for what five lines of stdlib solve.
- Refactoring a function only because it is long. Refactor when it improves readability, removes duplication, or separates real responsibilities.
- Answering question 2 from memory instead of searching the repo.
- Reading "do not change existing behavior" as "do not touch existing code". The first is a promise about what callers observe. The second is a promise about the diff, and honoring it is how a second branch becomes a copy of the first.

## Output format

When the lens changed what you were about to build (or a new abstraction survived it), note it briefly in the task report. One line per decision; skip the section entirely when nothing changed:

```markdown
### Simplicity notes
- Reused <path:symbol> instead of writing a new <thing>.
- Smaller change: <what was done> instead of <what was almost built>.
- New abstraction kept: <what>, <why it reduces complexity; which callers need it>.
```
