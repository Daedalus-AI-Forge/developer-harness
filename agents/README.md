# agents/

Generic, project-agnostic subagent **role contracts**: markdown files with YAML
frontmatter that define a role's mission, method, deliverable, and boundaries.

## Shipped roles

| Role | Delegate when |
| --- | --- |
| [`debugger.md`](debugger.md) | Any bug, regression, flaky test, or unexplained behavior — finds root cause with evidence; proposes fixes, applies them only when explicitly asked. |
| [`qa-reviewer.md`](qa-reviewer.md) | Adversarial review of a diff, PR, or "done" claim — runs the tests, reads the output, hunts silent failures; never implements. |
| [`researcher.md`](researcher.md) | Research grounding a decision — cited primary sources with access dates, adversarial verification, inference labeled as inference. |

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
