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
  `agents/validation-team/qa-reviewer.md` · debugger →
  `agents/develop-team/debugger.md`. Routing is the consuming tool's own
  delegation.
- **Chain:** plan gate (tech-lead) → implement (implementer, TDD) →
  design-conformance review (tech-lead) → verification (qa-reviewer).
  On needs-work: debugger diagnoses the findings (root cause plus
  falsifications — diagnose-only) → the ORIGINAL implementer applies the
  fix, failing test first, for the diagnosed cause → qa-reviewer
  re-verifies against the original findings plus a full rerun. Approve
  ends the chain. Executable step-by-step via the `feature-build` skill.
- **Handoff record:** task record path + design reference + approved plan
  from the gate; files changed + test command + full test output from the
  implementer; pass/fail with reason from the conformance review; verdict +
  ranked findings from verification.
- **Authority rules:** only qa-reviewer declares done; tech-lead's
  conformance fail returns the work with instructions, never patches it;
  the orchestrating harness routes and enforces, and may not overrule
  either verdict; the implementer who built the work fixes it —
  ownership does not transfer on a failed verdict; debugger proposes,
  never patches; a second needs-work on the same finding escalates to
  tech-lead (and the human if contested).
- **Team memory:** one `<team-log>` entry per run — verdicts and what
  remains open.

### Team: design-review

- **Members:** review-coordinator (tech-lead →
  `agents/develop-team/tech-lead.md`) · lens-reviewers ×4 (consistency ·
  feasibility · compliance · completeness — parallel, findings capped at
  ~3 per lens; run as subagents where the tool supports them, else as
  sequential role adoptions) · adversarial-verifier (one per finding,
  default-refute) · doc-owner (remediation) · qa-reviewer →
  `agents/validation-team/qa-reviewer.md`.
- **Chain:** fan the four lenses out over the target doc → refute each
  finding (adversarial verifier; default `refuted=true` — a finding
  survives only on evidence) → coordinator triages CONFIRMED findings
  into a remediation record with a per-finding fix sketch → doc-owner
  applies each fix or rebuts it with reasoning — never ignores one →
  coordinator batch-pass for cross-document seams → qa-reviewer
  independently re-verifies every finding at its claimed location → gate
  closed. This is a PRE-BUILD gate: open findings block build dispatch.
- **Handoff record:** findings table (id · severity · lens · finding ·
  fix sketch); per-finding disposition (`FIXED` / `REBUTTED: <reason>`);
  dated change markers in the doc.
- **Authority rules:** a failed or absent verifier surfaces its finding
  as UNVERIFIED, never as refuted — the gate must not silently pass;
  qa-reviewer may fail the round on a single unmet claim; remediation
  may rebut a finding but must argue its case, never ignore it.
- **Team memory:** the triage record is the round's memory; doc version
  bumps record what each round changed.

### Team: bug-diagnosis

- **Members:** dispatcher (any role) · debugger →
  `agents/develop-team/debugger.md` (diagnose-only by default) ·
  developer → `agents/develop-team/developer.md` (fix) · qa-reviewer →
  `agents/validation-team/qa-reviewer.md` (verify).
- **Chain:** dispatcher pre-triages — reproduces the symptom, falsifies
  the cheap hypotheses itself, and LISTS the falsified ones in the
  handoff so they are not re-raised → debugger proves the root cause
  with evidence (and may correct the dispatch brief — corrections are
  part of the deliverable), describing the smallest fixes as separately
  dispatchable items → dispatcher routes each fix to a developer →
  fixes ship through the normal feature-build gates → qa-reviewer
  verifies against the ORIGINAL symptom.
- **Handoff record:** a diagnosis record carrying the symptom verbatim,
  the evidence already collected, the hypotheses ruled out (with how),
  and an explicit authority line ("diagnose only" unless stated
  otherwise); then the debugger's proven mechanism plus its proposed
  fixes.
- **Authority rules:** the debugger does not fix unless the dispatch
  explicitly authorizes it; any member may dispatch the debugger — it
  is nobody's exclusive; no fix ships outside the build gates.
- **Team memory:** the debugger's durable catalogue of silent-failure
  mechanisms, appended per run.

### Team: research-to-decision

- **Members:** decision-owner (tech-lead →
  `agents/develop-team/tech-lead.md` or product-owner →
  `agents/product-owner.md`, as declared per repo) · researcher →
  `agents/research-team/researcher.md` · evidence-validator →
  `agents/validation-team/evidence-validator.md` (the independent
  re-derivation stage).
- **Chain:** decision-owner authors the scope record with explicit
  acceptance criteria and constraints → researcher delivers a cited
  document: per-finding confirmed/corrected verdicts, a self-refutation
  pass, unknowns and coverage gaps honestly flagged → evidence-validator
  independently re-derives the load-bearing citations at source,
  checking against the acceptance criteria → decision-owner rules.
  Research is evidence, never the decision.
- **Handoff record:** the scope record — its acceptance criteria ARE
  the verification spec (a code-conformance stage is N/A here, and its
  waiver is logged with the reason); the deliverable doc with dated
  citations; the fact-checker's per-criterion verdict.
- **Authority rules:** only evidence-validator (or another validator)
  renders the soundness verdict; the researcher never edits decision
  records; a disclosed source-availability gap with a resolution recipe
  is a coverage gap, not a defect; a stand-in who performs the research
  labels the deliverable reduced-rigor rather than passing it off.
- **Team memory:** per-topic researcher notes in `<research-notes>`; an
  index of delivered documents.

### Team: legal-vetting

- **Members:** legal-reviewer →
  `agents/project-control/legal-reviewer.md` · qa-reviewer →
  `agents/validation-team/qa-reviewer.md` (citation verifier) · the
  human owner plus their attorney (final authority — a named HUMAN
  stage no role may fill).
- **Chain:** archive the governing instruments verbatim with retrieval
  dates BEFORE analysis → clause-level analysis citing the archives,
  never live pages → a green/amber/red verdict PER USAGE POSTURE → a
  mandatory "what only an attorney can decide" section → qa-reviewer
  re-verifies the load-bearing citations at source → the human decides.
- **Handoff record:** the dated verbatim archives plus the memo — a
  NOT-LEGAL-ADVICE banner, per-clause verbatim quotes with section
  numbers, the verdict table, the attorney question list.
- **Authority rules:** hard boundary — analysis FOR human review, never
  final legal advice; anything binding goes to the human; terms are
  re-fetched and diffed before any clause is relied on again.
- **Team memory:** the archive directory itself (append-only, dated)
  plus the reviewer's notes.

### Observed variations (feature-build)

Two recurring variations on the feature-build chain, both legitimate:

1. **Parallel lanes** — N developer lanes with disjoint file claims run
   the implement stage concurrently; one shared integration test
   battery, then a per-lane design-conformance gate and a single
   batched verification that closes all lanes at once.
2. **Waived stages** — any stage a run waives is logged in the handoff
   record with the reason. A stage is never silently skipped.

If no team matches, fall back to the `## Roles` section, or proceed
normally.
