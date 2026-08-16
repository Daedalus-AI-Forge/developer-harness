---
name: define-team
description: Interview the user and scaffold a valid custom team entry in their repo's "## Teams" section (AGENTS.md/CLAUDE.md) — members from the harness role library, chain with return paths, handoff record, authority rules, optional team memory. Use when asked to define, create, or scaffold an agent team, or to add a team to AGENTS.md. Invoke explicitly.
license: MIT
---

# Define Team

Scaffolds one custom team — a named chain of roles — as a valid entry in
the consuming repo's `## Teams` section (AGENTS.md or CLAUDE.md). The
interview gathers the five fields, the validation rules run before
anything is written, and the write is append-only, confirmed via a diff.

Five predefined teams already ship in the template
(`rules/agents-md/teams-section.md` in this harness): feature-build,
design-review, bug-diagnosis, research-to-decision, legal-vetting. If one
fits, copy it instead of defining a new team.

## Step 1 — Locate the target

1. Find the repo's instruction file: `AGENTS.md`, else `CLAUDE.md`.
2. Find its `## Teams` section. If absent, create the section from the
   teams-section template (its intro paragraph and closing fallback
   line), then place the new entry inside it.

## Step 2 — Interview

Ask in order, one question at a time; record every answer.

1. **Team name** — short, hyphenated, unique within the section.
2. **Members** — offer the harness role library grouped by its five
   groups: coordination root (product-owner, person-of-contact) ·
   project-control (product-manager, project-manager, legal-reviewer,
   researcher) · develop-team (tech-lead, developer, frontend-developer,
   backend-developer, devops-engineer, mobile-developer, data-engineer,
   security-engineer, debugger) · design-team (ux-designer,
   content-designer, design-system-steward, technical-artist) ·
   validation-team (qa-reviewer, design-reviewer, integration-validator,
   performance-validator, release-validator). External or custom
   contract paths are allowed — confirm each one explicitly.
3. **Chain order** — the stages in order, and for EVERY stage: where the
   work returns on failure, or an explicit "cannot fail here" with why.
4. **Handoff record** — the fields every stage hands the next. Baseline:
   artifact paths, decisions each with a one-line reason, open questions
   each with an owner; add the team's own fields on top.
5. **Authority rules** — exactly ONE role holds the done-verdict; then
   prompt for the escalation rule (what happens when the orchestrator
   and a specialist disagree — default: escalate to the human with both
   positions stated).
6. **Team memory (optional)** — offer one append-only entry per run in
   `<team-log>` (resolved in `## Project bindings`); skip if declined.

## Step 3 — Validate (before writing anything)

Refuse to write until ALL of these hold; on a failure, return to the
interview question that supplies the missing answer:

- every member resolves to an existing contract file (check the path on
  disk) or an explicitly-confirmed custom/external path;
- exactly one role holds the done-verdict — zero or two is invalid;
- every stage has a return path or an explicit "cannot fail here"
  statement;
- the entry follows the five-field shape: Members / Chain / Handoff
  record / Authority rules / Team memory.

## Step 4 — Write and confirm

1. Render the entry in the template's exact shape: `### Team: <name>`
   plus the five bullets.
2. Append it into `## Teams` — never modify an existing entry or any
   other existing line.
3. Show the user the diff and ask for confirmation; on objection, amend
   and re-show before finishing.

## Result

Return: the file edited, the rendered entry, and the validation
checklist with each rule's outcome.
