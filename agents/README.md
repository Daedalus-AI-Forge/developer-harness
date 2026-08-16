# agents/

Generic, project-agnostic subagent **role contracts**: markdown files with YAML
frontmatter that define a role's bindings, mission, method, deliverable, and
boundaries. Roles are grouped by team: the coordination pair stays at this
root, and the rest live in `project-control/`, `develop-team/`, and
`design-team/`.

## Shipped roles

### Coordination root

The pair at the root of multi-role work — value and communication; dispatch
itself lives in the consuming tool's orchestration.

| Role | Delegate when |
| --- | --- |
| [`product-owner.md`](product-owner.md) | Value execution against the product blueprint: one Product Goal, a single ordered backlog with acceptance criteria authored before work starts, accept/return calls on delivered increments — judges value, never dispatches work or designs solutions. |
| [`person-of-contact.md`](person-of-contact.md) | Communication routing after work completes or a decision lands: resolves the affected components in the repo's `## RACI` table, hands outcomes to the Responsible/Accountable parties, brokers cross-component collaborations — routes and brokers, never decides value or assigns work. |

### project-control/

The roles that steer and ground work without touching code: direction,
delivery, legal exposure, research.

| Role | Delegate when |
| --- | --- |
| [`product-manager.md`](project-control/product-manager.md) | Product direction: problem framing, personas, prioritization rationale, success metrics — direction not delivery; legal exposure routes to `legal-reviewer`. |
| [`project-manager.md`](project-control/project-manager.md) | Turning agreed goals into sequenced, owned tasks with schedule, risk (pre-mortem/retro), and progress tracking — consumes product direction, never sets it. |
| [`legal-reviewer.md`](project-control/legal-reviewer.md) | Anything public-facing or license-touching, BEFORE the decision — red-flag ledgers, clause-by-clause summaries, attorney question lists; analysis for human review, never final legal advice. |
| [`researcher.md`](project-control/researcher.md) | Research grounding a decision — cited primary sources with access dates, adversarial verification, inference labeled as inference. |

### develop-team/

The roles that build and verify software: the design gate, the implementation
layers, root-causing, and adversarial verification.

| Role | Delegate when |
| --- | --- |
| [`tech-lead.md`](develop-team/tech-lead.md) | Design gating, buy-vs-build calls, seam/interface pinning, decomposition into buildable tasks, and design-conformance review of finished work — gates and reviews, never implements. |
| [`developer.md`](develop-team/developer.md) | Implementing a specified change in any language — the generic base: TDD from a failing test, repo conventions, small reviewable increments; loads the language skills that match the task. |
| [`frontend-developer.md`](develop-team/frontend-developer.md) | UI work — the base plus UI state management, accessibility, responsive/asset budgets, design fidelity, and browser/device evidence. |
| [`backend-developer.md`](develop-team/backend-developer.md) | Server-side work — the base plus API contract discipline, data integrity and migrations, failure modes and idempotency, observability hooks. |
| [`devops-engineer.md`](develop-team/devops-engineer.md) | CI/CD and infrastructure — pipeline custody, reproducible builds, secrets hygiene, release/rollback method; keeps gates honest, never bypasses them. |
| [`mobile-developer.md`](develop-team/mobile-developer.md) | Mobile app work — the base plus platform lifecycle and background-execution constraints, offline-first data, permissions/privacy UX, app-store review discipline, device evidence, bundle/battery budgets. |
| [`data-engineer.md`](develop-team/data-engineer.md) | Data platform work — schema/migration custody, idempotent replayable pipelines, data-quality checks as code, PII discipline with lineage, storage/query cost awareness. |
| [`security-engineer.md`](develop-team/security-engineer.md) | Defensive security — threat modeling on new surfaces, secrets hygiene, supply-chain vetting, least-privilege and trust-boundary review; reviews and hardens, never builds offensive tooling. |
| [`qa-reviewer.md`](develop-team/qa-reviewer.md) | Adversarial review of a diff, PR, or "done" claim — runs the tests, reads the output, hunts silent failures; never implements. |
| [`debugger.md`](develop-team/debugger.md) | Any bug, regression, flaky test, or unexplained behavior — finds root cause with evidence; proposes fixes, applies them only when explicitly asked. |

### design-team/

The roles that specify, steward, and verify the designed experience — specs
in, verdicts and audits out; none of them edits production code.

| Role | Delegate when |
| --- | --- |
| [`ux-designer.md`](design-team/ux-designer.md) | Design-spec authoring — flows, per-screen states (empty/loading/error/first-run included), interaction behavior, and visual intent, precise enough that frontend-developer can implement and design-reviewer can verify without asking back. |
| [`design-reviewer.md`](design-team/design-reviewer.md) | Review of a built UI against its design spec — fidelity state-by-state, accessibility with executed checks plus labeled judgment, design-system conformance; experience verdict only — functional correctness stays with qa-reviewer. |
| [`content-designer.md`](design-team/content-designer.md) | Interface language — labels, errors, empty states, a terminology glossary as source of truth, audits of the strings the code actually ships; legal-sounding copy routes to `legal-reviewer`. |
| [`design-system-steward.md`](design-team/design-system-steward.md) | Design-system custody — tokens/components/conventions in one source of truth, drift audits across the code, additions gated against stated need; reports drift, never patches product code. |
| [`technical-artist.md`](design-team/technical-artist.md) | Opt-in, for real-time/3D/character products — asset budgets as gates, mechanical asset validation, the source-to-runtime pipeline documented, asset-touching code reviewed; validates and specifies, never authors art. |

Researched but deliberately not shipped: a ux-researcher role collides with
`researcher` and real-user research isn't agent-executable, and
visual/brand/motion/3d-craft roles have no honest text-agent deliverable —
their reviewable fragments live in `ux-designer`, `design-reviewer`, and
`technical-artist`.

## Standalone vs team use

The groups map to how the roles compose:

- **Coordination root** — `product-owner` (value: the Product Goal, the
  single ordered backlog, accept/return on delivered increments) ·
  `person-of-contact` (communication: RACI routing, brokered
  cross-component collaborations). The pair at the root of multi-role
  work. Dispatch itself lives in the consuming tool's orchestration, not
  in any role.
- **project-control/** — the standalone specialists `researcher` and
  `legal-reviewer` are complete on their own: delegate one task, get one
  deliverable back — and `legal-reviewer` is nobody's exclusive: any role
  may engage it before a public-facing or license-touching decision. The
  management chain — product-manager (strategy) · product-owner (value
  execution) · project-manager (delivery) · tech-lead (design) — is useful
  individually (a design gate alone is worth having) but built to compose.
- **develop-team/** — `developer` is the generic base;
  `frontend-developer`, `backend-developer`, `mobile-developer`,
  `data-engineer`, `devops-engineer`, and `security-engineer` cover one
  layer's concerns each, while `tech-lead` gates, `debugger` root-causes,
  and `qa-reviewer` verifies. Language expertise stays in skills: a
  language-specific dev role is composed per repo by pairing a dev role
  with the matching language skills (e.g. `dev-csharp` = `developer` + the
  `csharp-developer` skill) — see the example in
  [`../rules/agents-md/roles-section.md`](../rules/agents-md/roles-section.md).
- **design-team/** — `ux-designer` specifies, `content-designer` owns the
  words, `design-system-steward` governs the vocabulary, `design-reviewer`
  verdicts the built experience (independently of `qa-reviewer`'s
  functional verdict — neither substitutes for the other), and
  `technical-artist` is the opt-in bridge to art pipelines. They hand specs
  and findings to develop-team roles rather than editing code.

Teams — which roles form a chain, what each stage hands the next, and who
holds which authority — are declared per repo in a `## Teams` section
(template:
[`../rules/agents-md/teams-section.md`](../rules/agents-md/teams-section.md)).
The `feature-build` skill ships one such chain as an executable process.

## Project bindings

The shipped roles stay project-agnostic by referring to a small fixed
placeholder vocabulary — `<source-root>`, `<test-command>`, `<design-docs>`,
etc. — instead of hard-coding any layout. Each contract opens with a
`## Bindings` block declaring which placeholders it **requires** (it cannot
operate without them) and which are **optional** (it degrades gracefully,
naming the gap). A consuming repo resolves them by pasting a
`## Project bindings` table into its `AGENTS.md` (or `CLAUDE.md`); template in
[`../rules/agents-md/project-bindings-section.md`](../rules/agents-md/project-bindings-section.md).

When a role needs a binding the repo has not defined, that section's
**Resolution protocol** applies: infer candidates from the repo, ask the user
to confirm, persist the confirmed row — and if a *required* binding cannot be
established, the role declares itself unavailable for the repo rather than
proceeding on a guessed path.

## What belongs here

- Roles that make sense in *any* codebase (e.g. a reviewer, a test author, a
  refactoring surgeon) — no project names, no repo-specific paths, no
  product knowledge.
- One file per role, following [`_template.md`](_template.md): frontmatter
  (`name`, `description`, optional `model: inherit`), a `## Bindings` block,
  and the four body sections **Mission / Method / Deliverable / Boundaries**.
  New roles go in the team folder they belong to.

Project-specific agents belong in the consuming repo's own `.claude/agents/`,
not here.

## How consumers install these

| Tool | How |
| --- | --- |
| **Claude Code** | Reads this `agents/` directory automatically when the repo is installed as a plugin ([docs](https://code.claude.com/docs/en/plugins)). Or copy files into your repo's `.claude/agents/` — read recursively, so the grouped folders copy as-is ([subagent format](https://code.claude.com/docs/en/sub-agents)). |
| **Cursor** | Copy files into `.cursor/agents/` — Cursor also reads `.claude/agents/` natively, so a single copy into `.claude/agents/` serves both tools ([docs](https://cursor.com/docs/agent/subagents)). Nested-folder support is unverified — flatten on copy if roles don't appear. |
| **Codex** | No markdown agents: Codex custom agents are TOML files in `.codex/agents/` ([docs](https://learn.chatgpt.com/docs/agent-configuration/subagents)). Instead, route roles through a `## Roles` section in `AGENTS.md` — template in [`../rules/agents-md/roles-section.md`](../rules/agents-md/roles-section.md). |
| **OpenCode** | Native agents use different frontmatter (`description`, `mode: subagent`) in `.opencode/agents/` ([docs](https://opencode.ai/docs/agents/)). Either adapt the frontmatter when copying, or use the same `AGENTS.md` roles-section routing as Codex. |

## Frontmatter (Claude Code / Cursor dialect)

```yaml
---
name: role-name            # lowercase, hyphens
description: When to delegate to this role.
model: inherit             # optional; inherit is the default
---
```

`name` and `description` are the load-bearing fields in both tools; everything
else is optional.
