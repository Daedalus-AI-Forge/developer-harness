# Template: "## Design docs" section for AGENTS.md

Copy the block below into the consuming repo's `AGENTS.md` (or `CLAUDE.md`).
It is ready to paste as-is: the only placeholder is `<design-docs>`,
resolved in the repo's `## Project bindings` section (template:
[`project-bindings-section.md`](project-bindings-section.md)). These are
doc-SHAPE rules — what the docs say belongs to the roles that own them.

---

## Design docs

Shape rules for everything under `<design-docs>`. They keep a growing doc
set navigable and its decisions traceable.

- **Every design doc opens with a header:** status (e.g. DRAFT / ACTIVE /
  SUPERSEDED, plus a version), owner (the role or person answerable for
  it), and creation date — plus links to the parent docs that give it
  context. A doc whose standing cannot be read in five seconds is a trap
  for its next reader.
- **Decisions carry stable IDs, each owned by exactly ONE doc.** Other
  docs reference the ID and never restate or re-decide it — this is the
  "One source of truth" rule from `## Engineering discipline` (template
  beside this one) applied to design docs. An index of decisions may
  point at IDs; it never re-decides them.
- **An index doc lives at the root of `<design-docs>`,** naming what each
  doc owns and the reading order for newcomers. A new doc is added to the
  index in the same change that creates it.
- **Docs are updated in the same change as the code they govern.** A
  design doc that lags its implementation is misinformation with
  authority; when a change makes a doc wrong, fixing the doc is part of
  that change.
- **Amendments are dated in place, never silently rewritten.** Supersede
  visibly: mark the amended text with the date and what replaced it, or
  flip the doc's status to SUPERSEDED and point forward — history stays
  auditable either way.
- **Estimates are labeled estimates.** Planning numbers in design docs —
  dates, sizes, capacity — are marked as planning values; facts of record
  live in their one canonical home and are referenced, never restated.
