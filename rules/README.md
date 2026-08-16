# rules/

Instruction fragments meant to be pasted into a consuming repo's agent
instruction file — `AGENTS.md` (Codex, OpenCode, and the cross-tool
[AGENTS.md convention](https://agents.md)) or `CLAUDE.md` (Claude Code).

These exist for harness classes some tools cannot consume natively:

- **Roles**: Codex defines custom agents in TOML and OpenCode uses its own
  frontmatter dialect, so markdown role contracts from [`../agents/`](../agents/)
  are routed through an instruction-file section instead of installed as files.
- **Bindings**: generic role contracts avoid hard-coded layouts by using
  `<placeholder>` names; the instruction file supplies the project's actual
  paths and commands.
- **Guards**: every tool wires hooks differently, so the instruction file
  documents which guard scripts exist and when they run.
- **Discipline**: always-on engineering method (TDD, debugging before fixes,
  verification before completion) belongs in the instruction file itself so
  every tool loads it on every turn.

## Templates

| Template | Produces | Use when |
| --- | --- | --- |
| [`agents-md/roles-section.md`](agents-md/roles-section.md) | A `## Roles` routing table: role name → contract file | The consuming tool can't read `.claude/agents/` (Codex, OpenCode) |
| [`agents-md/project-bindings-section.md`](agents-md/project-bindings-section.md) | A `## Project bindings` table: role-contract placeholders (`<test-command>`, `<design-docs>`, …) → real paths/commands | The repo adopts any generic role from [`../agents/`](../agents/) |
| [`agents-md/guards-section.md`](agents-md/guards-section.md) | A `## Guards` list of hook scripts and when they run | Any repo that vendors scripts from [`../hooks/`](../hooks/) |
| [`agents-md/engineering-discipline-section.md`](agents-md/engineering-discipline-section.md) | A `## Engineering discipline` rule set: TDD, systematic debugging, verification before completion, quality gates, single source of truth, scope/ownership, version-control safety | Any repo where agents write code |

## How to use

1. Copy the template body into the consuming repo's `AGENTS.md` (or
   `CLAUDE.md`).
2. Replace the placeholders with that repo's actual roles, guards, or
   quality-gate commands.
3. Keep paths relative to the consuming repo's root.

Keep fragments generic: no project names, no machine-specific paths.
