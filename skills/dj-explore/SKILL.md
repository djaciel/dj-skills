---
name: dj-explore
description: Use when there is real uncertainty about which approach to take — two plausible architectures, a risky integration, a complicated migration, or a refactor with several viable routes. Not for routine tasks where the path is already clear.
---

# Approach Exploration

## Overview

Resolve genuine approach uncertainty deliberately: propose 2–3 candidate approaches, compare them as cheaply as the decision allows, pick one, and discard the rest explicitly so the question is never relitigated by accident.

**Announce at start:** "I'm using the dj-explore skill to compare approaches for <task or question>."

## When to use

- Two or three plausible architectures for the same task.
- A risky integration where the failure mode is unclear.
- A complicated migration with more than one viable route.
- A refactor that could go several ways with different trade-offs.
- Invoked as `/dj-explore T-03 --approaches 2` (scoped to a task) or `/dj-explore "<question>"` (standalone).

When NOT to use:

- Every task. Most tasks have one obvious approach — just implement it.
- When the repo already dictates the pattern — apply the **dj-repo-patterns** skill and follow precedent instead of inventing alternatives.
- When the uncertainty is about product intent, not technical approach — that is a conversation with the user, not an exploration.

Quick test for real uncertainty — run the exploration only if all three are yes:

1. Can you name two approaches a competent reviewer might each defend?
2. Does the choice meaningfully change the diff shape, blast radius, or data model?
3. Would picking wrong be expensive to undo later?

If any answer is no, state the obvious approach and proceed without this skill.

## Modes

| Mode | When | Cost |
|------|------|------|
| On paper (default) | Almost always — the deciding question can be answered by reasoning over the repo | Minutes; no code written |
| Worktree prototypes | ONLY with explicit user authorization, when paper cannot answer the deciding question | Hours; throwaway code in separate git worktrees |

Never start implementing prototypes without the user explicitly authorizing it. If you believe prototypes are needed, say what question they would answer that paper cannot, and ask.

## The process

### Step 1: Frame the decision

1. State what is being decided in one sentence.

```text
Weak:   "Which architecture is better?"
Strong: "Should webhook retries live in the queue worker or in a dedicated retry table,
         given we must survive worker restarts?"
```

2. Pick the deciding criteria up front — what would make an approach win. Common ones:

| Criterion | Question it answers |
|-----------|---------------------|
| Diff size | How much code changes, and how reviewable is it? |
| Blast radius | What breaks if this is wrong? |
| Testability | Can the behavior be validated cheaply and reliably? |
| Pattern fit | Does it follow what the repo already does? |
| Migration safety | Can it ship incrementally? Is there a rollback story? |
| Operational load | What does it add to run and debug in production? |

3. Read the relevant context: if scoped to a task, the task packet `.dj-agents/repos/<repo>/features/<feature>/tasks/T-XX.md` and the feature spec; otherwise whatever framing the user provided.

   Layout and root resolution: `skills/dj-start/templates/dj-agents-layout.md`; resolve `<area>` with the `dj-root` script.

### Step 2: Propose the approaches

- Default to 2. Add a third only if it is genuinely distinct — never a strawman built to make the favorite look good.
- Give each a short name and a one-paragraph description of how it would work in THIS repo — concrete files and seams, not generic architecture talk.

### Step 3: Compare on paper (default)

For each approach, fill in: pros, cons, risk, estimated diff size, testability. Ground every claim in the actual repo — cite the files and patterns that make it easy or hard here, not arguments that would apply to any codebase.

If the paper comparison produces a clear winner, skip Step 4 and go to Step 5.

### Step 4: Prototype in worktrees (only if authorized)

1. Confirm authorization and the timebox with the user first.
2. One git worktree per approach, clearly named (e.g. `explore/T-03-approach-a`).
3. Build the minimum that answers the deciding question — spike-quality, throwaway code. Stop at the timebox even if unfinished; a partial answer is still an answer.
4. Prototype code never merges as-is. The winner gets re-implemented properly through /dj-task with normal review rigor.
5. Clean up when done: `git worktree remove <path>` and delete the exploration branches.

### Step 5: Evaluate

- Delegate to the **dj-acceptance-reviewer** subagent: does each approach satisfy the task/spec intent, and at which acceptance levels? If the dj-acceptance-reviewer subagent is not available, judge acceptance inline against the task packet and spec.
- Delegate technical evaluation to the stack reviewer — the **dj-ts-reviewer** subagent for TypeScript, the **dj-elixir-reviewer** subagent for Elixir; for other stacks, review against repo patterns and stack knowledge. If no reviewer subagent is available, do this evaluation inline in the main session.
- For on-paper comparisons, reviewers judge the described design and sketched interfaces — mark those verdicts as speculative where they are.

Scale rigor by work mode (from `.dj-agents/repos/<repo>/project.md`, guidance not law):

- `production-work`: run both evaluations, even for on-paper comparisons.
- `personal-medium`: acceptance evaluation is enough unless the approaches differ mainly in technical risk.
- `personal-small`: inline judgment is fine — the written comparison itself is the safeguard.

### Step 6: Choose and discard

1. Write the comparison using `templates/approach-comparison.md` to `.dj-agents/repos/<repo>/features/<feature>/approach-comparison.md` (suffix with the task id when scoped, e.g. `approach-comparison-T-03.md`; standalone questions can live at `.dj-agents/repos/<repo>/approach-comparison-<topic>.md`).
2. Recommendation and Why are mandatory. A comparison without a decision just postpones the uncertainty at full price.
3. Discard the losers explicitly: remove their worktrees/branches, and record why each lost so the question is not reopened later by someone (or some session) that never saw the comparison.
4. Feed the choice back into the plan: update the task packet with the chosen approach; if the choice invalidates future tasks, log it in `.dj-agents/repos/<repo>/features/<feature>/drift-log.md` and replan via `/dj-plan --replan-from T-XX`.

## Common mistakes

- **Exploring everything** — running this skill on routine tasks turns a cheap decision into a ceremony. If one approach is obviously right, skip the exploration and say so.
- **Building before deciding** — starting worktree prototypes without authorization, or when a paper comparison would have settled it.
- **Prototypes that grow up** — a spike that quietly becomes the implementation skips review rigor. The winner is rebuilt through the normal task flow.
- **Strawman alternatives** — a third approach added only to be knocked down adds noise, not signal.
- **Comparison without a verdict** — pros/cons tables with no Recommendation and Why leave the user to do the deciding work the skill was meant to do.
- **Zombie worktrees** — discarded prototypes left on disk get accidentally resurrected. Delete them and note the deletion in the comparison.
- **Ungrounded claims** — "Approach B scales better" with no repo evidence is an opinion. Tie claims to files, patterns, or measured prototype behavior.
- **Deciding criteria invented after the fact** — criteria chosen once a favorite exists just rationalize it. Fix them in Step 1, before comparing.

## Output

After writing the comparison, report:

```text
Approach comparison written: .dj-agents/repos/<repo>/features/<feature>/approach-comparison.md
Mode: <on paper | worktree prototypes>
Approaches: A <name> · B <name> [· C <name>]
Recommendation: <A/B/C> — <one-line why>
Discarded: <names> (worktrees removed: <yes/n-a>)
Next: <update T-XX and run /dj-task T-XX | /dj-plan --replan-from T-XX | none>
```
