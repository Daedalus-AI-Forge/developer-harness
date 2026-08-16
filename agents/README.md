# agents/

Generic, project-agnostic subagent **role contracts**: markdown files with YAML
frontmatter that define a role's mission, method, deliverable, and boundaries.

## Shipped roles

| Role | Delegate when |
| --- | --- |
| [`debugger.md`](debugger.md) | Any bug, regression, flaky test, or unexplained behavior — finds root cause with evidence; proposes fixes, applies them only when explicitly asked. |
| [`qa-reviewer.md`](qa-reviewer.md) | Adversarial review of a diff, PR, or "done" claim — runs the tests, reads the output, hunts silent failures; never implements. |
| [`researcher.md`](researcher.md) | Research grounding a decision — cited primary sources with access dates, adversarial verification, inference labeled as inference. |
| [`tech-lead.md`](tech-lead.md) | Design gating, decomposition into buildable tasks, and design-conformance review of finished work — gates and reviews, never implements. |
| [`project-manager.md`](project-manager.md) | Turning agreed goals into sequenced, owned tasks with schedule, risk (pre-mortem/retro), and progress tracking — consumes product direction, never sets it. |
| [`product-manager.md`](product-manager.md) | Product direction: problem framing, personas, prioritization rationale, success metrics — direction not delivery; legal exposure goes to human review. |
| [`project-controller.md`](project-controller.md) | Orchestrating multi-role work: routing, one owner per task, handoff completeness, authority rules — coordinates, never does the specialists' work. |

## Standalone vs team use

The roles come in two kinds:

- **Standalone specialists** — `debugger`, `qa-reviewer`, `researcher`.
  Complete on their own: delegate one task, get one deliverable back. They
  are also the dispatchable specialists a team routes work to.
- **Management chain** — `tech-lead`, `project-manager`, `product-manager`,
  `project-controller`. Useful individually (a design gate alone is worth
  having), but built to compose: product-manager sets direction,
  project-manager sequences delivery, tech-lead gates and reviews the
  build, and project-controller routes work between them and the
  specialists.

Teams — which roles form a chain, what each stage hands the next, and who
holds which authority — are declared per repo in a `## Teams` section
(template:
[`../rules/agents-md/teams-section.md`](../rules/agents-md/teams-section.md)).
The `feature-build` skill ships one such chain as an executable process.

## Project bindings

The shipped roles stay project-agnostic by referring to a small fixed
placeholder vocabulary — `<source-root>`, `<test-command>`, `<design-docs>`,
etc. — instead of hard-coding any layout. A consuming repo resolves them by
pasting a `## Project bindings` table into its `AGENTS.md` (or `CLAUDE.md`);
template in
[`../rules/agents-md/project-bindings-section.md`](../rules/agents-md/project-bindings-section.md).
If a role needs a binding the repo has not defined, it asks rather than
guessing a path.

## What belongs here

- Roles that make sense in *any* codebase (e.g. a reviewer, a test author, a
  refactoring surgeon) — no project names, no repo-specific paths, no
  product knowledge.
- One file per role, following [`_template.md`](_template.md): frontmatter
  (`name`, `description`, optional `model: inherit`) plus the four body
  sections **Mission / Method / Deliverable / Boundaries**.

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
