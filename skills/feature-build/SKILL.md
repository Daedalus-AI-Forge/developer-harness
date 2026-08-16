---
name: feature-build
description: Run one scoped feature through a gated team pipeline — tech-lead plan gate, TDD implementation, tech-lead design-conformance review, qa-reviewer verification. Use when asked to build a feature end-to-end with gates, or to run the feature-build chain. Works with subagents (one per stage) or as one agent adopting the roles in sequence.
license: MIT
---

# Feature Build

A pipeline for building one scoped feature end-to-end with the shipped role
contracts: the tech lead gates the plan, an implementer builds test-first,
the tech lead reviews design conformance, and the QA reviewer delivers the
verdict. It exists so that "build feature X" never skips the design gate on
the way in or the adversarial verification on the way out.

## Roles and execution modes

Three role contracts drive the pipeline (see `agents/` in this harness):
`tech-lead.md` (stages 1 and 3), the implementing agent (stage 2 — the
default agent, under the repo's `## Engineering discipline`), and
`qa-reviewer.md` (stage 4).

- **Tools with subagent support:** run each stage as its own subagent with a
  fresh context and the stage's role contract loaded — the reviewer must not
  inherit the implementer's context, or its independence is gone.
- **Tools without:** one agent adopts the roles sequentially — load the
  stage's contract at the start of each stage and honor its Boundaries as if
  the context switch were real: the conformance reviewer does not patch
  code, and the verifier reruns the tests rather than trusting stage 2's
  output.

Placeholders like `<design-docs>` and `<test-command>` resolve from the
repo's `## Project bindings` section (AGENTS.md/CLAUDE.md). If the repo also
declares this chain in a `## Teams` section, that declaration binds.

## Inputs

- The feature, scoped: one component or capability, not a phase of work.
- The design doc or spec it implements (in `<design-docs>`).

## Stage 1 — Plan gate (tech-lead)

1. Verify the design doc exists and covers this feature. Missing or
   insufficient → **stop** and return exactly what is missing. No
   implementation plan for undesigned work.
2. Open a task record: scope, acceptance criteria, design reference, owner.
3. Produce a step-by-step TDD implementation plan — for each step, the test
   to write first and what it proves.

Gate output: `approved` (with the plan) or `rejected` (with the reason).
Rejected ends the run.

## Stage 2 — Implement

1. Follow the approved plan under the repo's engineering discipline: write
   the failing test first, watch it fail, then write the code that makes it
   pass.
2. Keep the task record current as work proceeds.
3. Finish with a test handoff: files changed, the exact `<test-command>`,
   and its full output.

## Stage 3 — Design-conformance review (tech-lead)

1. Diff the implementation against the design doc: module boundaries,
   interface adherence, data model, every constraint the design states.
   This is conformance, not correctness — stage 4 owns correctness.
2. Verdict `pass` or `fail` with the reason, logged in the task record.
3. On `fail`: return the work with concrete change instructions — never
   patch it in review. The implementer gets **one fix round** scoped to the
   fail reasons, then one re-review that first checks those exact reasons.
4. Still failing → **abort**: report the reason and the task record; do not
   proceed to verification.

## Stage 4 — Verification (qa-reviewer)

1. Read the test handoff, then **run the tests yourself** — never accept
   stage 2's output as evidence.
2. Probe adversarially: edge cases, silent failures, untested paths.
3. Verdict `approved` or `needs-work`, with findings ranked by severity,
   each with a concrete failure scenario.
4. On `needs-work`: the implementer gets **one fix round** scoped to the
   findings, then one re-verification that first checks those exact
   findings.
5. Only this stage declares the feature done. A missing or failed verdict
   is `needs-work`, never a silent pass.

## Result

Return: the task record location, the plan-gate verdict, the conformance
verdict (and any fix round), the QA verdict with its findings, and whether
the feature is done. If the repo binds `<team-log>`, append one entry:
stages run, verdicts, and what remains open.

## Rules that hold at every stage

- One fix round per gate — a second failure aborts with the evidence, it
  does not loop.
- Every handoff is complete: the next stage starts from artifacts and the
  task record, not from a summary of them.
- No stage does another's work: the gate does not design, the reviewer does
  not patch, the implementer does not self-approve.
