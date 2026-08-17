---
name: deep-research
description: Orchestrate a research question too big for one pass — decompose into sub-questions with acceptance criteria, run parallel multi-modal evidence sweeps, adversarially verify every load-bearing claim, and loop a completeness critic until a round yields nothing new. Use when a question carries multiple contested claims, an unknown landscape, needs more than about three independent sources, or a decision hangs on the answer.
license: MIT
---

# Deep Research

An orchestration recipe for research questions a single search pass cannot
settle. It scales the researcher role's single-pass method
(`agents/research-team/researcher.md` — paths here are relative to this
harness's root, the plugin root when installed as a plugin; tools without
custom-agent support adopt the role contract by reading that file) into a staged
pipeline: decompose, sweep in parallel from genuinely different angles,
verify adversarially, critique for completeness, loop until dry,
synthesize. For a single-fact
lookup the single-pass method stands alone — reach for this skill when the
question carries contested claims, an unknown landscape, more than about
three independent sources, or a decision that hangs on the answer.

## Execution modes

- **Tools with subagent support:** run each Stage 2 sweep as its own
  subagent with a fresh context — a sweep must not inherit another sweep's
  findings, or their independence is gone. Verification and critic passes
  likewise benefit from fresh contexts.
- **Tools without:** run the sweeps as sequential passes with separated
  notes — one note file per sweep, each pass written without rereading the
  other sweeps' notes until Stage 4.

If the repo declares the `research-to-decision` team (template:
`rules/agents-md/teams-section.md`), this pipeline runs as that team's
researcher stage: the decision-owner's scope record seeds Stage 1, and
evidence-validator's independent fact-check remains downstream of Stage 6.

## Stage 1 — Decompose

Break the question into sub-questions, each with explicit acceptance
criteria: what evidence would settle it, and what answer would change the
motivating decision. A sub-question without a criterion is not ready to
research. Record the decomposition — it is the checklist every later stage
reports against.

## Stage 2 — Parallel sweeps

For each sub-question, sweep from genuinely different angles — each sweep
blind to the others:

- **Official documentation** — specs, standards, vendor docs.
- **Source artifacts** — manifests, schemas, license files, shipped code;
  install and run the thing when the question is about runtime behavior.
- **Issue trackers and changelogs** — what broke, what changed, what is
  admitted in bug reports but absent from the docs.
- **Practitioner writing** — postmortems, benchmarks, migration reports;
  weighted below primary sources, valuable for failure modes.

Skip a modality only by recording why it cannot bear on the sub-question.

## Stage 3 — Evidence discipline (holds inside every sweep)

- Quote verbatim with section references; never upgrade normative language
  when quoting.
- Every claim carries URL plus access date; no citation means the sentence
  is labeled inference, explicitly.
- Manifest over prose: machine-readable artifacts beat the docs describing
  them; for a load-bearing claim go one level deeper than the README.
- Absence is proved twice: re-sweep with a deliberately looser net
  (synonyms, adjacent phrasings, other languages) and report that the
  second pass's hits were false positives.

## Stage 4 — Adversarial verification

Every load-bearing claim gets an independent refutation attempt at the
primary source: hunt staleness, version and platform drift, translation
gaps, banner-vs-body contradictions (a page's headline claim contradicted
by its own fine print), and quotes not actually present in the cited text.
Record a verdict per claim — confirmed, corrected, or refuted — with the
evidence. Corrections are marked visibly, never silently rewritten.

## Stage 5 — Completeness critic (loop until dry)

A critic pass over the assembled evidence asks:

- Which modality was not searched for which sub-question, and why?
- Which claim rests on a single source?
- What evidence, if found, would change the conclusion — and was it
  actually looked for?

Findings become another round of Stages 2–4 scoped to the gaps. Stop when
a round yields nothing new — that is the exit condition, not a fixed
iteration count.

## Stage 6 — Synthesis

One document per question, containing in order: TL;DR answer → findings
table (claim · sources · per-claim confidence · verification verdict) →
implications for the motivating decision → unknowns that remain → what
would change this conclusion. Inference is labeled as inference,
recommendations as recommendations.

File it in `<research-notes>` (or `<docs-root>`), resolved per the repo's
`## Project bindings` section; if neither is bound, return the document
inline and name the gap. Return to the caller: the doc path, the TL;DR,
the three strongest sources, and an explicit confidence level.

## Rules that hold at every stage

- Verification, not validation: evidence contradicting the caller's lean
  is reported plainly.
- The pipeline grounds the decision, never makes it — implications are
  stated, recommendations are labeled as such.
- A source that could not be verified is flagged, not quietly kept.
- No stage's output is trusted by the next without its artifacts: sweeps
  hand over notes with citations, not summaries of them.
