---
name: dj-data-flow-review
description: "Use when a diff, PR, or bug must be understood before it is judged, when reviewing changes whose behavior depends on how data moves, especially changes that cross module, service, or layer boundaries."
---

# Data Flow Review

## Overview

Comprehension before criticism: reconstruct how data moves through the changed code (entry points → transforms → outputs and side effects) before producing a single finding. Most real bugs live at the seams, where one side's assumption quietly stops being true.

## When to use

- As the first analytical step of the **dj-review** skill, right after diff retrieval and file classification
- During the **dj-fix** skill, to locate the affected flow before hunting the root cause
- The **dj-pr-reviewer** subagent applies this lens when reconstructing a PR's intent
- The informed pass of the **dj-review** skill (its `templates/informed-pass.md`) applies this lens per main flow, holding the description and the ticket
- Any diff touching an interface between components (API ↔ service, service ↔ DB, SDK ↔ UI, producer ↔ consumer)

**When NOT to use:**

- Purely mechanical diffs (renames, formatting, generated files): nothing flows differently
- Docs- or config-only changes with no runtime behavior

## The method

Trace three things for the changed code, in order.

### 1. Entry points

Where does data enter the changed flow? HTTP handler, queue message, cron job, CLI argument, UI event, a function other modules call. For each input, answer:

- Where does it come from?
- **What validates it, and where?**

If validation moved or disappeared in the diff, that seam goes on the inspection list.

### 2. Transforms

What happens between entry and exit? Renamed fields, type coercions, defaults applied, filtering, aggregation, branching on shape. Note every place the diff changes a transform's assumption: nullable → required, string → enum, sync → async, one item → a batch.

### 3. Outputs and side effects

Where does the result go: return values, DB writes, emitted events, external calls, mutated state, logs? For each output: **who consumes it, and does that consumer still receive what it expects?**

### Before vs. after

Build the map twice: the flow before the diff and the flow after. The differences between the two maps are the review surface: everything else is noise.

### Seams: where assumptions break

Inspect the joints explicitly:

- A producer changed shape or timing: was every consumer updated?
- Validation was removed at one layer assuming another layer covers it. Confirm that layer actually does.
- Error paths: what happens when a transform fails mid-flow? Partial writes? Swallowed errors?
- Ordering or concurrency changes: flag only with evidence; no invented race conditions.

## Common mistakes

- Jumping to findings before the map exists: critiquing code whose purpose was never reconstructed.
- Mapping the whole system instead of the changed flow: the map covers the diff's blast radius, not the architecture.
- Mapping only the happy path: error paths and empty inputs are part of the flow.
- Promoting suspicions to findings: an unverified seam concern is a question, not a finding (evidence rule).

## Output format

A compact map, a dozen lines, not a document:

```md
## Data flow

### After (this diff)
<entry point> → <transform> → <transform> → <output / side effect>

### Before (when behavior changed)
<previous flow, for comparison>

### Inputs & validation
- <input>: comes from <source>, validated by <where> (or: NOT validated, question)

### Consumers
- <output> consumed by <who>, still receives expected shape? yes / no / unverified

### Seams to inspect
- <file:line>: <assumption that may have broken>
```

This map feeds the Reviewer Dossier in **dj-review** and the fix plan in **dj-fix**.
