# Template: "## Teams" section for AGENTS.md

Copy the block below into the consuming repo's `AGENTS.md` (or `CLAUDE.md`),
then replace the placeholder team with real teams. Copy ONLY the teams the
repo actually runs — the five predefined entries are a menu, not a bundle.
A team is a named chain of roles: who is in it, what order work moves
through it, how it executes, what each stage hands the next, who holds which
authority, and where the human re-enters. Role contract files follow
`agents/_template.md` in developer-harness; routing is driven by the
consuming tool's own delegation — orchestration lives in the harness that
runs the team, never in a role.

Add a `## Project bindings` section whenever a listed contract uses
`<placeholder>` bindings (every generic role in developer-harness's `agents/`
does) — template in
[`project-bindings-section.md`](project-bindings-section.md). Team memory
uses that template's `<team-log>` binding.

Apply the shared [`size-budget-note.md`](size-budget-note.md) before
pasting: keep `## Teams` early in the file and inside the 32 KiB budget.
Paste the field tables and invariants once, then only the team entries this
repo runs — all five predefined entries together consume a large share of an
instruction file's budget for teams that will never be dispatched.

---

## Teams

Route multi-role work through the teams below. When a task names a team or
matches its chain, run the stages in order — never skip a stage, and never
advance work on an incomplete handoff.

Declare every team with the fields in the table below. A team missing a
required field is not declared: do not run it.

| Field | Required | Rule |
| --- | --- | --- |
| **Members** | yes | One entry per role: `<role>` → `<relative/path/to/role.md>`. Every member resolves to a file on disk or an explicitly confirmed external path. |
| **Chain** | yes | Stages in order. Every stage names where work returns on failure, or states "cannot fail here" and why. |
| **execution-mode** | yes | One of `agent-team` · `subagents` · `single-session`. Fall back down that chain when the running tool lacks the declared mode, and say so in the handoff. Run `single-session` by adopting each role in sequence with its contract loaded — a first-class mode, not a degraded one. |
| **fix-rounds** | yes | Integer retry budget per gate; default `1`. When the budget is spent, stop and escalate to the named human checkpoint — never open another round. |
| **Handoff record** | yes | Carries the six elements below at every stage boundary, no exceptions. |
| **Artifacts** | optional | Per stage, `creates:` and `requires:` naming concrete artifacts. Do not start a stage until every `requires:` artifact exists; a stage's output is the named artifact, not a claim about it. |
| **Authority rules** | yes | Exactly ONE role declares work done. The orchestrator never overrules a specialist verdict — escalate a dispute to the human with both positions stated. |
| **Human checkpoints** | yes | Name every point where the human re-enters the chain. Make the plan/spec gate the primary checkpoint — plan errors amplify through every later stage, so plan review is the cheapest catch — and name a final acceptance point. |
| **Budget** | optional | A hard cap in rounds or tokens. Stop at the cap and report state; never trade the cap for one more attempt. |
| **Team memory** | optional | A named status file in this repo (declare its path; `<team-log>` by default). Write the plan and the handoff to it BEFORE the stage executes, so context loss never loses chain state. Stage-owned status transitions only advance — never downgrade a status another stage set. |

### Handoff record — six required elements

Write the record as data a stage reads cold. Assume no instruction file, no
prior turn, and no shared memory reaches the delegate.

| Element | Content |
| --- | --- |
| **Objective** | What this stage must achieve, in one statement. |
| **Expected output** | The deliverable SHAPE the next stage receives — format, sections, where it lands. |
| **Tool / source guidance** | Which tools, commands, and sources to use; which to avoid and why. |
| **Task boundaries** | What this stage must NOT do — the scope edge, stated. |
| **Decisions + rationale** | Every decision made at this stage with a one-line reason. Undocumented decisions get re-made differently downstream. |
| **Resolved bindings** | Binding VALUES, not placeholder names (`pytest -q`, not `<test-command>`). Instruction-file inheritance across delegation is unreliable — the record carries the values. |

Add open questions with a named owner whenever any remain.

### Invariants — check before declaring a team and before each run

- Every member resolves to a contract file.
- Exactly one role holds the done-verdict — zero or two is invalid.
- Every stage has a return path or an explicit "cannot fail here".
- Hand a validator or verdict stage ONLY the handoff record plus the
  artifact under review. Never pass it prior session history: a reviewer
  that sees the conversation role-plays as the author and stops reviewing.
- Give parallel stages DISJOINT artifact ownership — one writer per file.
  Where ownership would overlap, serialize the stages instead.
- Log every waived stage in the handoff record with the reason. A stage is
  never silently skipped.

### Economics — when to declare a team at all

Declare a team for high-value work with genuinely parallelizable stages. A
multi-agent run costs an order of magnitude more tokens than one agent doing
the same task. For sequential, dependency-heavy work choose `subagents` or
`single-session` and skip the team overhead.

### Team: `<team-name>`

- **Members:** `<role>` → `<relative/path/to/role.md>` (one entry per role).
- **Chain:** `<stage 1 (role)>` → `<stage 2 (role)>` → `<…>`; on failure
  each stage returns to the stage its contract names.
- **execution-mode:** `<agent-team | subagents | single-session>` (fall back
  agent-team → subagents → single-session).
- **fix-rounds:** `1` per gate.
- **Handoff record:** the six required elements, plus `<team-specific
  fields>`.
- **Artifacts:** `<stage>` creates `<path>`; `<next stage>` requires
  `<path>`.
- **Authority rules:** only `<verifier-role>` declares work done;
  `<any further rules — e.g. "implementation work reaches an implementer
  only through the tech lead's gate">`.
- **Human checkpoints:** `<plan/spec approval — primary>`;
  `<final acceptance>`.
- **Budget (optional):** `<cap>`.
- **Team memory (optional):** `<team-log>` — write the plan and handoff
  before the stage runs; append verdicts and open items after. No entry =
  the run never happened as far as the next one knows.

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
- **execution-mode:** `subagents` (stages are sequentially dependent; fall
  back to `single-session` role adoption). Parallel developer lanes require
  disjoint file ownership — see Observed variations.
- **fix-rounds:** `1` per gate. A second needs-work on the same finding
  stops the round and escalates to tech-lead, then the human.
- **Handoff record:** the six required elements, plus — task record path +
  design reference + approved plan from the gate; files changed + test
  command + full test output + the quality-gate output (or its skip
  notices) for the staged diff from the implementer, so a reviewer starts
  from evidence the fast gates passed and not from a claim; pass/fail with
  reason from the conformance review; verdict + ranked findings from
  verification.
- **Artifacts:** plan gate creates the approved plan record; implement
  requires it and creates the changed files plus the test output;
  conformance review and verification require both. qa-reviewer receives
  the handoff record and the diff only — never the implementation session.
- **Authority rules:** only qa-reviewer declares done; tech-lead's
  conformance fail returns the work with instructions, never patches it;
  the orchestrating harness routes and enforces, and may not overrule
  either verdict; the implementer who built the work fixes it —
  ownership does not transfer on a failed verdict; debugger proposes,
  never patches.
- **Human checkpoints:** plan approval before implementation starts
  (primary); final acceptance after qa-reviewer approves.
- **Team memory:** `<team-log>` — plan and handoff written before each
  stage; verdicts and open items appended after.

### Team: design-review

- **Members:** review-coordinator (tech-lead →
  `agents/develop-team/tech-lead.md`) · lens-reviewers ×4 (consistency ·
  feasibility · compliance · completeness — parallel, findings capped at
  ~3 per lens) · adversarial-verifier (one per finding, default-refute) ·
  doc-owner (remediation) · qa-reviewer →
  `agents/validation-team/qa-reviewer.md`.
- **Chain:** fan the four lenses out over the target doc → refute each
  finding (adversarial verifier; default `refuted=true` — a finding
  survives only on evidence) → coordinator triages CONFIRMED findings
  into a remediation record with a per-finding fix sketch → doc-owner
  applies each fix or rebuts it with reasoning — never ignores one →
  coordinator batch-pass for cross-document seams → qa-reviewer
  independently re-verifies every finding at its claimed location → gate
  closed. This is a PRE-BUILD gate: open findings block build dispatch.
- **execution-mode:** `agent-team` for the parallel lens fan-out; fall back
  to `subagents`, then to `single-session` sequential lens adoption — the
  lenses stay four distinct passes in every mode.
- **fix-rounds:** `1` per finding. A finding re-raised after a rebuttal
  goes to the human checkpoint instead of a second remediation round.
- **Handoff record:** the six required elements, plus the findings table
  (id · severity · lens · finding · fix sketch); per-finding disposition
  (`FIXED` / `REBUTTED: <reason>`); dated change markers in the doc.
- **Artifacts:** each lens writes ONLY its own findings block (disjoint
  ownership — four lenses, four files or four fenced blocks); the
  coordinator alone writes the triage record; the doc-owner alone writes
  the reviewed doc. Verifier and qa-reviewer receive the findings plus the
  doc, never the lens sessions.
- **Authority rules:** a failed or absent verifier surfaces its finding
  as UNVERIFIED, never as refuted — the gate must not silently pass;
  qa-reviewer may fail the round on a single unmet claim; remediation
  may rebut a finding but must argue its case, never ignore it.
- **Human checkpoints:** scope approval — which doc, which lenses —
  before the fan-out (primary); gate-closure sign-off before build
  dispatch.
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
- **execution-mode:** `subagents` (diagnosis and fix are separate agents so
  the fixer inherits no attachment to a hypothesis); fall back to
  `single-session` with the roles adopted in sequence.
- **fix-rounds:** `1`. A failed verification returns once to the debugger
  with the new evidence, then escalates to the human checkpoint.
- **Handoff record:** the six required elements, plus a diagnosis record
  carrying the symptom verbatim, the evidence already collected, the
  hypotheses ruled out (with how), and an explicit authority line
  ("diagnose only" unless stated otherwise); then the debugger's proven
  mechanism plus its proposed fixes.
- **Artifacts:** dispatcher creates the triage brief; debugger requires it
  and creates the diagnosis record; each developer requires the diagnosis
  record and owns only the files its fix item names — parallel fix items
  must not share a file.
- **Authority rules:** the debugger does not fix unless the dispatch
  explicitly authorizes it; any member may dispatch the debugger — it
  is nobody's exclusive; no fix ships outside the build gates.
- **Human checkpoints:** dispatch-brief approval, including the authority
  line diagnose-only vs authorized-to-fix (primary); acceptance of the
  verified fix against the original symptom.
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
- **execution-mode:** `agent-team` when the researcher stage fans parallel
  sweeps out over sub-questions; otherwise `subagents`, else
  `single-session`. Give each parallel sweep its own note file under
  `<research-notes>` — one writer per file.
- **fix-rounds:** `1`. An evidence-validator needs-work returns once to the
  researcher against the same acceptance criteria.
- **Handoff record:** the six required elements, plus the scope record —
  its acceptance criteria ARE the verification spec (a code-conformance
  stage is N/A here, and its waiver is logged with the reason); the
  deliverable doc with dated citations; the validator's per-criterion
  verdict.
- **Artifacts:** decision-owner creates the scope record; researcher
  requires it and creates the cited deliverable; evidence-validator
  requires the deliverable and the scope record — and nothing else, so it
  re-derives rather than re-reads the researcher's reasoning.
- **Authority rules:** only evidence-validator (or another validator)
  renders the soundness verdict; the researcher never edits decision
  records; a disclosed source-availability gap with a resolution recipe
  is a coverage gap, not a defect; a stand-in who performs the research
  labels the deliverable reduced-rigor rather than passing it off.
- **Human checkpoints:** scope-record approval before research starts
  (primary); the ruling itself when the decision-owner is not the human.
- **Budget:** cap the sweep rounds in the scope record; stop at the cap
  and deliver with the remaining gaps flagged.
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
- **execution-mode:** `subagents` or `single-session`; the terminal human
  stage is never substituted by any mode or fallback.
- **fix-rounds:** `1` for citation re-verification; an unresolved citation
  ships as UNVERIFIED in the memo rather than being re-litigated.
- **Handoff record:** the six required elements, plus the dated verbatim
  archives and the memo — a NOT-LEGAL-ADVICE banner, per-clause verbatim
  quotes with section numbers, the verdict table, the attorney question
  list.
- **Artifacts:** the archive directory (created before analysis, dated,
  append-only) and the memo; qa-reviewer requires both and re-fetches at
  source rather than trusting the memo's quotes.
- **Authority rules:** hard boundary — analysis FOR human review, never
  final legal advice; anything binding goes to the human; terms are
  re-fetched and diffed before any clause is relied on again.
- **Human checkpoints:** usage-posture list approval before analysis
  (primary); the human/attorney decision, which is terminal and
  non-delegable.
- **Team memory:** the archive directory itself (append-only, dated)
  plus the reviewer's notes.

### Observed variations (feature-build)

Two recurring variations on the feature-build chain, both legitimate:

1. **Parallel lanes** — N developer lanes with disjoint file claims run
   the implement stage concurrently; one shared integration test
   battery, then a per-lane design-conformance gate and a single
   batched verification that closes all lanes at once. Claim the files
   per lane BEFORE the lanes start; overlapping claims serialize.
2. **Waived stages** — any stage a run waives is logged in the handoff
   record with the reason. A stage is never silently skipped.

If no team matches, fall back to the `## Roles` section, or proceed
normally.
