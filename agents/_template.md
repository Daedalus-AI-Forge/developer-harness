---
name: role-name
description: One sentence saying when the orchestrator should delegate to this role.
model: inherit
---

# Role Name

## Bindings

<!-- Choosing Requires vs Optional: a binding is REQUIRED only when the role
     cannot produce an honest deliverable without it (a missing required
     binding triggers step 4 of the Resolution protocol — the role declares
     itself unavailable and stops). It is OPTIONAL when the role can still
     deliver without it, at reduced depth — the role names the gap and
     continues. Ask: "could this role still return something truthful and
     useful without this binding?" Yes → Optional. Delete whichever line the
     role does not use. -->

- Requires: `<a>`, `<b>` — cannot operate without these (protocol step 4
  applies).
- Optional: `<c>` — enriches the role; degrade gracefully if absent.
- Resolution: per the "Resolution protocol" in the repo's
  `## Project bindings` section (AGENTS.md/CLAUDE.md).

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
