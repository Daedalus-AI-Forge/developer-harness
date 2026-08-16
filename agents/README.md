# agents/

Generic, project-agnostic subagent **role contracts**: markdown files with YAML
frontmatter that define a role's bindings, mission, method, deliverable, and
boundaries.

## Shipped roles

### Method roles

| Role | Delegate when |
| --- | --- |
| [`debugger.md`](debugger.md) | Any bug, regression, flaky test, or unexplained behavior — finds root cause with evidence; proposes fixes, applies them only when explicitly asked. |
| [`qa-reviewer.md`](qa-reviewer.md) | Adversarial review of a diff, PR, or "done" claim — runs the tests, reads the output, hunts silent failures; never implements. |
| [`researcher.md`](researcher.md) | Research grounding a decision — cited primary sources with access dates, adversarial verification, inference labeled as inference. |
| [`legal-reviewer.md`](legal-reviewer.md) | Anything public-facing or license-touching, BEFORE the decision — red-flag ledgers, clause-by-clause summaries, attorney question lists; analysis for human review, never final legal advice. |
| [`tech-lead.md`](tech-lead.md) | Design gating, buy-vs-build calls, seam/interface pinning, decomposition into buildable tasks, and design-conformance review of finished work — gates and reviews, never implements. |
| [`project-manager.md`](project-manager.md) | Turning agreed goals into sequenced, owned tasks with schedule, risk (pre-mortem/retro), and progress tracking — consumes product direction, never sets it. |
| [`product-manager.md`](product-manager.md) | Product direction: problem framing, personas, prioritization rationale, success metrics — direction not delivery; legal exposure routes to `legal-reviewer`. |
| [`project-controller.md`](project-controller.md) | Orchestrating multi-role work: routing, one owner per task, handoff completeness, authority rules — coordinates, never does the specialists' work. |

### Developer roles

| Role | Delegate when |
| --- | --- |
| [`developer.md`](developer.md) | Implementing a specified change in any language — the generic base: TDD from a failing test, repo conventions, small reviewable increments; loads the language skills that match the task. |
| [`frontend-developer.md`](frontend-developer.md) | UI work — the base plus UI state management, accessibility, responsive/asset budgets, design fidelity, and browser/device evidence. |
| [`backend-developer.md`](backend-developer.md) | Server-side work — the base plus API contract discipline, data integrity and migrations, failure modes and idempotency, observability hooks. |
| [`devops-engineer.md`](devops-engineer.md) | CI/CD and infrastructure — pipeline custody, reproducible builds, secrets hygiene, release/rollback method; keeps gates honest, never bypasses them. |
| [`mobile-developer.md`](mobile-developer.md) | Mobile app work — the base plus platform lifecycle and background-execution constraints, offline-first data, permissions/privacy UX, app-store review discipline, device evidence, bundle/battery budgets. |
| [`data-engineer.md`](data-engineer.md) | Data platform work — schema/migration custody, idempotent replayable pipelines, data-quality checks as code, PII discipline with lineage, storage/query cost awareness. |
| [`security-engineer.md`](security-engineer.md) | Defensive security — threat modeling on new surfaces, secrets hygiene, supply-chain vetting, least-privilege and trust-boundary review; reviews and hardens, never builds offensive tooling. |

## Standalone vs team use

The roles come in three kinds:

- **Standalone specialists** — `debugger`, `qa-reviewer`, `researcher`,
  `legal-reviewer`. Complete on their own: delegate one task, get one
  deliverable back. They are also the dispatchable specialists a team routes
  work to — and `legal-reviewer` is nobody's exclusive: any role may engage
  it before a public-facing or license-touching decision.
- **Management chain** — `tech-lead`, `project-manager`, `product-manager`,
  `project-controller`. Useful individually (a design gate alone is worth
  having), but built to compose: product-manager sets direction,
  project-manager sequences delivery, tech-lead gates and reviews the
  build, and project-controller routes work between them and the
  specialists.
- **Developer roles** — `developer` is the generic base;
  `frontend-developer`, `backend-developer`, `mobile-developer`,
  `data-engineer`, `devops-engineer`, and `security-engineer` cover one
  layer's concerns each. Language expertise stays in skills: a
  language-specific dev role is composed per repo by pairing a dev role
  with the matching language skills (e.g. `dev-csharp` = `developer` + the
  `csharp-developer` skill) — see the example in
  [`../rules/agents-md/roles-section.md`](../rules/agents-md/roles-section.md).

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

Project-specific agents belong in the consuming repo's own `.claude/agents/`,
not here.

## How consumers install these

| Tool | How |
| --- | --- |
| **Claude Code** | Reads this `agents/` directory automatically when the repo is installed as a plugin ([docs](https://code.claude.com/docs/en/plugins)). Or copy files into your repo's `.claude/agents/` ([subagent format](https://code.claude.com/docs/en/sub-agents)). |
| **Cursor** | Copy files into `.cursor/agents/` — Cursor also reads `.claude/agents/` natively, so a single copy into `.claude/agents/` serves both tools ([docs](https://cursor.com/docs/agent/subagents)). |
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
