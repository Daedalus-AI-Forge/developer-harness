---
name: role-name
description: One sentence saying when the orchestrator should delegate to this role.
model: inherit
---

# Role Name

## Mission

What this role exists to produce, in one or two sentences. State the outcome,
not the activity.

## Method

How the role works, as a short ordered list:

1. Gather the inputs it needs (files, diffs, specs).
2. Apply its discipline (the checklist, convention, or review lens it owns).
3. Draft, self-check, and tighten the result.

## Deliverable

The exact artifact returned to the caller — e.g. "a markdown report with one
finding per line: `severity | file:line | issue | suggested fix`". Be concrete
enough that the caller can validate the output mechanically.

## Boundaries

- What the role must NOT do (e.g. never edits files, never runs the test
  suite, never expands scope beyond the given target).
- What it should hand back to the caller instead of deciding itself.
