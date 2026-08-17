---
name: define-team
description: Interview the user and scaffold a valid custom team entry in their repo's "## Teams" section (AGENTS.md/CLAUDE.md) — members from the harness role library, chain with return paths and per-stage expected output, the six-element handoff record, fix-round budget, execution mode, human checkpoints, optional team memory and budget cap — then validate it, check for agent-name collisions, and check the file against the instruction-file size budget. Use when asked to define, create, or scaffold an agent team, or to add a team to AGENTS.md. Invoke explicitly.
license: MIT
---

# Define Team

Scaffolds one custom team — a named chain of roles — as a valid entry in
the consuming repo's `## Teams` section (AGENTS.md or CLAUDE.md). The
interview gathers the schema fields, the validation rules run before
anything is written, and the write is append-only, confirmed via a diff.

Five predefined teams already ship in the template
(`rules/agents-md/teams-section.md` in this harness): feature-build,
design-review, bug-diagnosis, research-to-decision, legal-vetting. If one
fits, copy it instead of defining a new team.

Before starting, say the cost out loud: a declared team is for high-value,
parallelizable work. A multi-agent run costs an order of magnitude more
tokens than a single agent doing the same work, so for sequential,
dependency-heavy work a `subagents` chain or a single session is the
better answer — and that is a legitimate outcome of this interview.

## Step 1 — Locate the target

1. Find the repo's instruction file: `AGENTS.md`, else `CLAUDE.md`.
2. Find its `## Teams` section. If absent, create the section from the
   teams-section template (its intro paragraph and closing fallback
   line), then place the new entry inside it.

## Step 2 — Interview

Ask in order, one question at a time; record every answer.

1. **Team name** — short, hyphenated, unique within the section.
2. **Members** — offer the harness role library grouped by its six
   groups: coordination root (product-owner, person-of-contact) ·
   project-control (product-manager, project-manager, legal-reviewer) ·
   develop-team (tech-lead, developer, frontend-developer,
   backend-developer, devops-engineer, mobile-developer, data-engineer,
   security-engineer, debugger) · design-team (ux-designer,
   content-designer, design-system-steward, technical-artist) ·
   research-team (researcher, analyst — shared specialists) ·
   validation-team (qa-reviewer, design-reviewer, integration-validator,
   performance-validator, release-validator, evidence-validator).
   External or custom contract paths are allowed — confirm each one
   explicitly.
3. **Chain order** — the stages in order, and for EVERY stage: where the
   work returns on failure, or an explicit "cannot fail here" with why.
   Ask whether any stages run in parallel; if so, each parallel stage
   names the artifacts it owns, and those sets must be disjoint. Parallel
   agents with overlapping ownership overwrite each other's work — the
   failure is silent and shows up as lost edits, not as an error.
4. **Expected output per stage** — the deliverable shape the next stage
   receives: a named artifact, a verdict plus ranked findings, a record.
   A stage whose output shape is unstated hands the next stage a guess.
   Optionally pin the edges as `creates:` / `requires:` lists of named
   artifacts — that makes the handoff checkable by something other than
   goodwill: a stage can assert its input exists before it starts.
5. **Handoff record** — what every stage hands the next. Six elements,
   all required:
   - **objective** — what this stage is being asked to achieve;
   - **expected output** — the deliverable shape from question 4;
   - **tool and source guidance** — which tools and sources this stage
     should use, and which to leave alone;
   - **task boundaries** — what is explicitly out of scope here;
   - **decisions made, each with a one-line rationale** — a decision
     taken but never written down gets silently re-litigated at the next
     stage, usually the other way;
   - **resolved binding values** — the actual paths and commands, not
     `<placeholder>` names. Instruction-file inheritance across delegation
     is unreliable, so the record carries the values rather than trusting
     a delegate to re-resolve them.

   Add the team's own fields on top — artifact paths and open questions
   each with an owner are the common two.
6. **Fix rounds** — the retry budget per gate, default `1`. The cap is
   what stops a reviewer and an implementer from trading rounds
   indefinitely; past the budget the chain aborts with the evidence
   rather than looping.
7. **Execution mode** — one of `agent-team` (members run concurrently as
   peers), `subagents` (one fresh subagent per stage), or
   `single-session` (one agent adopts each role in sequence). Record the
   fallback chain with it — `agent-team` → `subagents` → `single-session`
   — so a tool lacking the declared mode degrades instead of failing.
   `single-session` is a first-class mode, not a consolation: sequential
   role adoption honors the same boundaries as long as each stage loads
   its contract and re-runs rather than trusts the previous stage.
8. **Human checkpoints** — where the human re-enters the chain. Default
   the primary checkpoint to the plan gate: an error in the plan is
   inherited by every stage after it, so plan review is the cheapest
   place to catch one. Name any others (final verdict, release) and who
   is asked.
9. **Authority rules** — exactly ONE role holds the done-verdict; then
   the escalation rule (what happens when the orchestrator and a
   specialist disagree — default: escalate to the human with both
   positions stated); then the validator-context rule, which holds for
   every verdict stage: a validator receives the handoff record and the
   artifact under review, never the prior session history. A reviewer
   that can read the conversation re-runs the implementer's reasoning
   instead of judging the output, and approves its own thinking.
10. **Team memory (optional)** — a named status file in the consuming
    repo; ask for the path (`<team-log>`, resolved in `## Project
    bindings`, is the usual binding). Two rules travel with it: the plan
    and each handoff are written to the file BEFORE the stage runs, so a
    context loss costs the work but never the chain state; and status
    transitions only advance — a stage records its own outcome and never
    downgrades an earlier stage's. Skip if declined.
11. **Budget cap (optional)** — a hard stop for the whole run in rounds
    or tokens, above the per-gate fix budget. A chain that cannot finish
    inside its cap stops and reports what it has, rather than spending
    the rest of the budget discovering that it cannot.

## Step 3 — Validate (before writing anything)

Refuse to write until ALL of these hold; on a failure, return to the
interview question that supplies the missing answer:

- every member resolves to an existing contract file (check the path on
  disk) or an explicitly-confirmed custom/external path;
- exactly one role holds the done-verdict — zero or two is invalid;
- every stage has a return path or an explicit "cannot fail here"
  statement;
- every stage declares its expected output;
- the handoff record names all six elements — objective, expected output,
  tool/source guidance, task boundaries, decisions with rationale,
  resolved binding values — and the binding entries carry actual values,
  not `<placeholder>` names;
- `fix-rounds` is present (write `1` where the user had no preference);
- `execution-mode` is present and names the fallback chain
  `agent-team` → `subagents` → `single-session`;
- any parallel stages declare artifact ownership and the owned sets are
  disjoint — overlapping ownership is a rejection, not a warning;
- every validator/verdict stage carries the record-plus-artifact-only
  context rule;
- at least one human checkpoint is named, and it is the plan gate unless
  the user gave a reason for placing it elsewhere;
- team memory and the budget cap are each either declared concretely (a
  file path; a number of rounds or tokens) or explicitly declined —
  never left half-specified;
- the entry follows the template's field shape, in the template's order.

## Step 4 — Name-collision check

Before writing, list the agent names the consuming repo already resolves:
`.claude/agents/**/*.md`, the repo's own `## Roles` section, and
plugin-provided agents wherever the tool can list them. Compare that list
against the team's member names.

Report every collision with both sources and ask which definition the
team means. This is worth a step rather than a footnote because duplicate
agent names do not error — the loser is silently overwritten at load
time, so a team naming `qa-reviewer` can quietly get a different
`qa-reviewer` than the one interviewed. Published role libraries have
shipped dozens of duplicated names, so collisions are the normal case in
a repo with more than one library installed.

A collision is a warning, not a refusal: once the user confirms which one
they mean, write that member as an explicit contract path rather than a
bare name, so the entry says which file it meant.

## Step 5 — Write and confirm

1. Render the entry in the template's exact shape: `### Team: <name>`
   plus the schema bullets.
2. Append it into `## Teams` — never modify an existing entry or any
   other existing line.
3. Show the user the diff and ask for confirmation; on objection, amend
   and re-show before finishing.
4. **Size budget.** After appending, check the instruction file's size
   against the 32 KiB budget — Codex truncates an AGENTS.md at that
   point, and a truncated file fails silently: the team reads as declared
   in the repo while being invisible to the tool. Use the harness's
   `hooks/scripts/agents-md-budget.sh` where the harness is installed,
   otherwise `wc -c` on the file. Over budget: say so, and offer the
   split — routing sections (`## Roles`, `## Teams`, `## Project
   bindings`) stay in the instruction file and stay early in it, long
   prose moves to linked files; the harness's `rules/agents-md/`
   size-budget note carries the full rule. Never silently shorten the
   entry to fit.

## Result

Return: the file edited, the rendered entry, the validation checklist
with each rule's outcome, any name collisions and how they were resolved,
and the post-write file size against the budget.
