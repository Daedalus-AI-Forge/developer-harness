---
name: role-catalog
description: The catalog of this plugin's shipped role contracts — which roles exist, how they group into teams, and when to delegate to each. Use when deciding which role to adopt or delegate to for a piece of work; never for doing the work itself — route the work to the role this catalog names.
model: inherit
disallowedTools: Write, Edit, NotebookEdit
---

# agents/

<!-- WHY THIS README CARRIES AGENT FRONTMATTER: Claude Code loads every
     markdown file in a plugin's agents/ directory as a subagent —
     recursively, with no exemption for READMEs or underscore-prefixed
     files (https://code.claude.com/docs/en/plugins-reference). Without the
     block above, this file would still install, as a broken agent named
     `README`. The frontmatter turns that accident into a deliberate
     read-only role-catalog lookup; the agent's identity comes from `name`,
     not the filename, so the file keeps its README.md name and GitHub
     landing-page role. For the same reason the role-contract scaffold
     lives in ../rules/role-contract-template.md, not here. Do not remove
     the frontmatter, and do not add plain documentation files to this
     directory. -->

Generic, project-agnostic subagent **role contracts**: markdown files with YAML
frontmatter that define a role's bindings, mission, method, deliverable, and
boundaries. Roles are grouped by team: the coordination pair stays at this
root, and the rest live in `project-control/`, `develop-team/`,
`design-team/`, `research-team/`, and `validation-team/`.

## Start small

Adopt four roles first, not twenty-six: **tech-lead**, **developer**,
**qa-reviewer**, **debugger** — the chain the `feature-build` skill already
ships as an executable process (plan gate → TDD implementation →
design-conformance review → functional verdict), with `debugger` on the
failure path. It is the smallest set that still closes the loop, because no
role in it approves its own work.

The reason is empirical rather than aesthetic. The one first-hand account of
a large personal role library that the evidence base turned up is negative —
a hundred roles authored, roughly three used daily — while the accounts of
libraries people keep using cluster at three to five roles. A role
nobody delegates to is not neutral: it is another entry the dispatcher has to
read past, which is exactly what degrades routing for the roles that matter.

Add the other twenty-two when the repo's own work demands them — a
`design-reviewer` when UI fidelity starts drifting, `legal-reviewer` before
the first license-touching decision, `data-engineer` when the first migration
lands. Each addition should be traceable to a job that went badly without it.

## Shipped roles

### Coordination root

The pair at the root of multi-role work — value and communication; dispatch
itself lives in the consuming tool's orchestration. In team operation the
human has two doors into the team: requests to add or change functionality
enter through `product-owner`, and handoff communication flows through
`person-of-contact` — standalone use of a single role is unaffected.

| Role | Delegate when |
| --- | --- |
| [`product-owner.md`](product-owner.md) | Value execution against the product blueprint: one Product Goal, a single ordered backlog with acceptance criteria authored before work starts, accept/return calls on delivered increments — judges value, never dispatches work or designs solutions. |
| [`person-of-contact.md`](person-of-contact.md) | Communication routing after work completes or a decision lands: resolves the affected components in the repo's `## RACI` table, hands outcomes to the Responsible/Accountable parties, brokers cross-component collaborations — routes and brokers, never decides value or assigns work. |

### project-control/

The roles that steer and ground work without touching code: direction,
delivery, legal exposure.

| Role | Delegate when |
| --- | --- |
| [`product-manager.md`](project-control/product-manager.md) | Product direction: problem framing, personas, prioritization rationale, success metrics — direction not delivery; legal exposure routes to `legal-reviewer`. |
| [`project-manager.md`](project-control/project-manager.md) | Turning agreed goals into sequenced, owned tasks with schedule, risk (pre-mortem/retro), and progress tracking — consumes product direction, never sets it. |
| [`legal-reviewer.md`](project-control/legal-reviewer.md) | Anything public-facing or license-touching, BEFORE the decision — red-flag ledgers, clause-by-clause summaries, attorney question lists; analysis for human review, never final legal advice. |

### develop-team/

The roles that build software: the design gate, the implementation layers,
and root-causing. The done-verdict on what they build lives in
`validation-team/`.

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
| [`debugger.md`](develop-team/debugger.md) | Any bug, regression, flaky test, or unexplained behavior — finds root cause with evidence; proposes fixes, applies them only when explicitly asked. |

### design-team/

The roles that specify and steward the designed experience — specs and
audits out; none of them edits production code. The experience verdict on
the built UI lives in `validation-team/`.

| Role | Delegate when |
| --- | --- |
| [`ux-designer.md`](design-team/ux-designer.md) | Design-spec authoring — flows, per-screen states (empty/loading/error/first-run included), interaction behavior, and visual intent, precise enough that frontend-developer can implement and design-reviewer can verify without asking back. |
| [`content-designer.md`](design-team/content-designer.md) | Interface language — labels, errors, empty states, a terminology glossary as source of truth, audits of the strings the code actually ships; legal-sounding copy routes to `legal-reviewer`. |
| [`design-system-steward.md`](design-team/design-system-steward.md) | Design-system custody — tokens/components/conventions in one source of truth, drift audits across the code, additions gated against stated need; reports drift, never patches product code. |
| [`technical-artist.md`](design-team/technical-artist.md) | Opt-in, for real-time/3D/character products — asset budgets as gates, mechanical asset validation, the source-to-runtime pipeline documented, asset-touching code reviewed; validates and specifies, never authors art. |

Researched but deliberately not shipped: a ux-researcher role collides with
`researcher` and real-user research isn't agent-executable, and
visual/brand/motion/3d-craft roles have no honest text-agent deliverable —
their reviewable fragments live in `ux-designer`, `design-reviewer`, and
`technical-artist`.

### research-team/

The shared research specialists serving develop-team and design-team —
research requests originate from those teams' work, and these roles ground
their decisions without making them. The soundness verdict on a research
deliverable lives in `validation-team/`.

| Role | Delegate when |
| --- | --- |
| [`researcher.md`](research-team/researcher.md) | Research grounding a decision — cited primary sources with access dates, adversarial verification, inference labeled as inference. |
| [`analyst.md`](research-team/analyst.md) | Decision-grade numbers — estimates with stated assumptions and shown arithmetic, metric interpretation against product-manager's definitions, sensitivity notes naming the conclusion-flipping inputs; predicts, never measures. |

### validation-team/

The roles that judge finished work — verdicts with executed evidence, never
fixes. Validators live OUTSIDE the teams they judge, and the six verdicts
(functional, experience, integration, performance, readiness, evidence) are
independent — none substitutes for another. Across the group, a check that
could not run yields unverified — never a pass: a missing or broken
verifier is reported with the reason, not silently converted into approval.

| Role | Delegate when |
| --- | --- |
| [`qa-reviewer.md`](validation-team/qa-reviewer.md) | Adversarial review of a diff, PR, or "done" claim — runs the tests, reads the output, hunts silent failures; never implements. |
| [`design-reviewer.md`](validation-team/design-reviewer.md) | Review of a built UI against its design spec — fidelity state-by-state, accessibility with executed checks plus labeled judgment, design-system conformance; experience verdict only — functional correctness stays with qa-reviewer. |
| [`integration-validator.md`](validation-team/integration-validator.md) | A verdict on whether independently built parts work as one system — the contract under test identified, the real seam exercised end-to-end (never mocked), contract-corpus drift and seam failure modes probed; judges the seam, never patches either side. |
| [`performance-validator.md`](validation-team/performance-validator.md) | Performance verdicts against explicit budgets — reproducible measurements (medians and tails) compared to budget and baseline; no budget or no measurement means no verdict; proposes optimization targets, never implementations. |
| [`release-validator.md`](validation-team/release-validator.md) | Ship-readiness of the actual release artifact — built and smoke-tested, checklist walked, every claim traced to a merged change and its passing test, rollback path known before ship; judges readiness, never cuts, deploys, or times the release. |
| [`evidence-validator.md`](validation-team/evidence-validator.md) | A verdict on whether a research deliverable's claims survive independent re-derivation — citations re-fetched, quotes re-verified verbatim, absences re-tested with a looser net, inference labeling checked; judges evidence quality, never the decision. |

## Standalone vs team use

The groups map to how the roles compose:

- **Coordination root** — `product-owner` (value: the Product Goal, the
  single ordered backlog, accept/return on delivered increments) ·
  `person-of-contact` (communication: RACI routing, brokered
  cross-component collaborations). The pair at the root of multi-role
  work. Dispatch itself lives in the consuming tool's orchestration, not
  in any role.
- **project-control/** — the standalone specialist `legal-reviewer` is
  complete on its own: delegate one task, get one deliverable back — and
  it is nobody's exclusive: any role may engage it before a public-facing
  or license-touching decision. The management chain — product-manager
  (strategy) · product-owner (value execution) · project-manager
  (delivery) · tech-lead (design) — is useful individually (a design gate
  alone is worth having) but built to compose.
- **develop-team/** — `developer` is the generic base;
  `frontend-developer`, `backend-developer`, `mobile-developer`,
  `data-engineer`, `devops-engineer`, and `security-engineer` cover one
  layer's concerns each, while `tech-lead` gates and `debugger`
  root-causes; the done-verdict comes from `validation-team/`'s
  `qa-reviewer`. Language expertise stays in skills: a
  language-specific dev role is composed per repo by pairing a dev role
  with the matching language skills (e.g. `dev-csharp` = `developer` + the
  `csharp-developer` skill) — see the example in
  [`../rules/agents-md/roles-section.md`](../rules/agents-md/roles-section.md).
- **design-team/** — `ux-designer` specifies, `content-designer` owns the
  words, `design-system-steward` governs the vocabulary, and
  `technical-artist` is the opt-in bridge to art pipelines; the experience
  verdict on the built UI comes from `validation-team/`'s
  `design-reviewer`. They hand specs and findings to develop-team roles
  rather than editing code.
- **research-team/** — the shared specialists serving develop-team and
  design-team: `researcher` (sourced claims) and `analyst` (decision-grade
  numbers), each complete standalone; the soundness verdict on a research
  deliverable comes from `validation-team/`'s `evidence-validator`.
- **validation-team/** — the six independent verdicts: `qa-reviewer`
  (functional), `design-reviewer` (experience), `integration-validator`
  (integration), `performance-validator` (performance),
  `release-validator` (readiness), and `evidence-validator` (evidence).
  Each is complete standalone — delegate one artifact, get one verdict
  back — and all six sit outside the teams they judge, so no builder
  approves its own work and no verdict substitutes for another.

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
- One file per role, following the template in
  [`../rules/role-contract-template.md`](../rules/role-contract-template.md):
  frontmatter (`name`, a trigger-clause `description`, `model: inherit`, and a
  `disallowedTools` denylist where the role's Boundaries forbid touching
  code), a `## Bindings` block, and the four body sections **Mission /
  Method / Deliverable / Boundaries**. New roles go in the team folder they
  belong to.
- Nothing else. Every markdown file in this directory installs as a live
  subagent when the repo is consumed as a Claude Code plugin — which is why
  the role-contract template lives in `rules/`, and why this README carries
  frontmatter making it a deliberate `role-catalog` lookup rather than an
  accidental broken agent.

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
name: role-name                             # lowercase, hyphens; equals the filename stem
description: Lane. Use when <situations>.   # router rule, under 500 characters
model: inherit                              # every shipped role; never a pinned tier
disallowedTools: Edit, NotebookEdit         # optional denylist; omit for implementation roles
---
```

`name` and `description` are load-bearing in both tools; the other two encode
this library's enforcement policy. The full rationale lives in the comment
block of
[`../rules/role-contract-template.md`](../rules/role-contract-template.md) —
the short version:

- **`description` is a router rule, not a summary.** It is the only text a
  dispatching agent reads when choosing among twenty-six roles, so every one
  of them names situations (`Use when …`) rather than qualities. Three roles
  that must be engaged *before* a decision rather than after — `tech-lead`'s
  gate, `legal-reviewer`, `debugger`'s pre-fix diagnosis — say
  `Use PROACTIVELY when …`.
- **`model: inherit` everywhere; never a pinned tier.** A pinned model
  outlives the tier names it was written against and silently overrides the
  consumer's own choice — a known failure mode in published role libraries.

### Mechanical boundary enforcement

Every role whose Boundaries forbid touching code carries a `disallowedTools`
**denylist** derived from its own Boundaries and Deliverable text:

| Group | Line | Why |
| --- | --- | --- |
| The six validation-team roles | `Write, Edit, NotebookEdit` | Their deliverable is a verdict returned to the caller; where a contract binds an optional `<team-log>`, the denied Write degrades to its documented inline fallback. |
| `debugger` | *(none — deliberate)* | Its contract permits an explicitly-authorized fix once the root cause is proven, and the bug-diagnosis team makes diagnose-vs-fix a per-run decision — so the prose governs; a repo wanting hard read-only adds `Write, Edit, NotebookEdit` locally. |
| `tech-lead` | `Edit, NotebookEdit` | Same gate discipline, but the Deliverable files buy-vs-build calls and the decomposition into `<design-docs>`, so Write stays. |
| The authoring roles — `product-owner`, `person-of-contact`, `product-manager`, `project-manager`, `legal-reviewer`, `ux-designer`, `content-designer`, `design-system-steward`, `technical-artist`, `researcher`, `analyst` | `Edit, NotebookEdit` | Each files its own document (spec, ledger, plan, research note); none may patch code. |
| The seven implementation roles — `developer`, `frontend-`, `backend-`, `mobile-`, `data-`, `devops-`, `security-engineer` | *(none)* | Writing code is the job. |

Two rules hold across the table. **Bash is never denied** — a verdict without
executed evidence is worthless, and it is the Boundaries prose, not the tool
list, that governs what Bash is used for. And **there is never a `tools:`
allowlist**: an allowlist must enumerate every tool the role will ever need,
including the team-communication tools a multi-agent harness injects, and
omitting one silently breaks the role inside a team — a bug both major
published role libraries shipped.

**Overriding per repo.** The deny lists are defaults, not verdicts on your
workflow. Copy the contract into your own `.claude/agents/` (or the tool's
equivalent) and adjust the line — a repo-local file wins over the plugin's.
`debugger` is the shipped example of the judgment call in the other
direction: its authorized-fix path is exactly the restriction users of
another library pushed back on, so it ships with no denylist and its
contract names the hard read-only line a repo can add. Each restricted
contract carries a Boundaries bullet naming its own override.

**Fields that are ignored.** When these contracts ship through a plugin, the
consuming tool honors `tools`, `disallowedTools`, and `model`, but **ignores**
`permissionMode`, `hooks`, and `mcpServers` in agent frontmatter. Never encode
a guarantee in a field that will not be read — wire hooks at the harness level
([`../hooks/`](../hooks/)) instead.

### Cross-tool equivalents

`disallowedTools` is the Claude Code / Cursor dialect. Elsewhere the same
boundary is expressed differently: **OpenCode** agents take a `permission`
block (`edit: deny` is the closest analogue, alongside `bash` and `webfetch`
rules); **Codex** has no per-agent tool denylist but does have a session-level
`sandbox_mode` (`read-only` being the restrictive end); **Cursor**'s subagent
controls are coarse — a read-only mode, not a per-tool list — so for
fine-grained boundaries there, the Boundaries prose remains the enforcement.
Per-tool wiring and its verification status live in
[`../docs/`](../docs/) — `consume-claude-code.md`, `consume-codex.md`,
`consume-cursor.md`, `consume-opencode.md`.

### Candidate, not shipped: `skills:` preload

Claude Code's agent frontmatter has a `skills:` field that preloads named
skills into the subagent's context — the obvious use here being
`systematic-debugging` into `debugger`, `deep-research` into `researcher`, or
the language conventions into `developer`. **No shipped contract sets it**,
and none should until one thing is verified: how a skill name resolves when
the skill arrives through a plugin namespace rather than sitting in the
project's own skills directory. Until a consumer confirms that resolution in
their own install, the roles that want a companion skill say so in prose
(`load the X skill where installed … where absent, this Method stands alone`),
which degrades correctly everywhere instead of failing silently in one place.
