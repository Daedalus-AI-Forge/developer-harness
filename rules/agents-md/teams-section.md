# Template: "## Teams" section for AGENTS.md

Copy the block below into the consuming repo's `AGENTS.md` (or `CLAUDE.md`),
then replace the placeholder team with real teams. A team is a named chain of
roles: who is in it, what order work moves through it, what each stage must
hand the next, and who holds which authority. Role contract files follow
`agents/_template.md` in developer-harness; the routing itself is driven by
the consuming tool's own delegation — orchestration lives in the harness
that runs the team, not in any role.

If any listed contract uses `<placeholder>` bindings (the generic roles in
developer-harness's `agents/` do), also add a `## Project bindings` section —
template in [`project-bindings-section.md`](project-bindings-section.md).
The optional team-memory convention uses the `<team-log>` binding from that
template.

---

## Teams

Multi-role work runs through the teams below. When a task names a team or
matches its chain, route it through the stages in order — never skip a
stage, and never move work forward on an incomplete handoff.

### Team: `<team-name>`

- **Members:** `<role>` → `<relative/path/to/role.md>` (one entry per role).
- **Chain:** `<stage 1 (role)>` → `<stage 2 (role)>` → `<…>`. A stage that
  fails returns the work to the stage its contract names — it never
  silently passes.
- **Handoff record** — what every stage hands the next, no exceptions:
  - artifact paths (files created or changed, task record location),
  - decisions made at this stage, each with a one-line reason,
  - open questions, each with an owner.
- **Authority rules:**
  - only `<verifier-role>` declares work done;
  - the orchestrator may not overrule a specialist's verdict — a dispute is
    escalated to the human with both positions stated;
  - `<any further rules — e.g. "implementation work reaches an implementer
    only through the tech lead's gate">`.
- **Team memory (optional):** append one entry per run to `<team-log>` —
  stages run, verdicts, open items. Append-only; the next run reads it
  before starting. No entry = the run never happened as far as the next
  one knows.

### Team: feature-build

- **Members:** tech-lead → `agents/develop-team/tech-lead.md` · implementer
  → the default agent under `## Engineering discipline` · qa-reviewer →
  `agents/develop-team/qa-reviewer.md`. Routing is the consuming tool's own
  delegation.
- **Chain:** plan gate (tech-lead) → implement (implementer, TDD) →
  design-conformance review (tech-lead) → verification (qa-reviewer).
  Executable step-by-step via the `feature-build` skill.
- **Handoff record:** task record path + design reference + approved plan
  from the gate; files changed + test command + full test output from the
  implementer; pass/fail with reason from the conformance review; verdict +
  ranked findings from verification.
- **Authority rules:** only qa-reviewer declares done; tech-lead's
  conformance fail returns the work with instructions, never patches it;
  the orchestrating harness routes and enforces, and may not overrule
  either verdict.
- **Team memory:** one `<team-log>` entry per run — verdicts and what
  remains open.

If no team matches, fall back to the `## Roles` section, or proceed
normally.
