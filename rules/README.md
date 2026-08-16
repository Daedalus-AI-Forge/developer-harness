# rules/

Instruction fragments meant to be pasted into a consuming repo's agent
instruction file — `AGENTS.md` (Codex, OpenCode, and the cross-tool
[AGENTS.md convention](https://agents.md)) or `CLAUDE.md` (Claude Code).

These exist for harness classes some tools cannot consume natively:

- **Roles**: Codex defines custom agents in TOML and OpenCode uses its own
  frontmatter dialect, so markdown role contracts from [`../agents/`](../agents/)
  are routed through an instruction-file section instead of installed as files.
- **Teams**: which roles form a chain, what each stage hands the next, and
  who holds which authority are per-repo declarations, so they live in the
  instruction file rather than in the shipped role contracts.
- **Bindings**: generic role contracts avoid hard-coded layouts by using
  `<placeholder>` names; the instruction file supplies the project's actual
  paths and commands.
- **RACI**: component ownership and communication routing (who is
  Responsible / Accountable / Consulted / Informed) are per-repo facts, so
  the table lives in the instruction file; the `person-of-contact` role
  consumes it.
- **Guards**: every tool wires hooks differently, so the instruction file
  documents which guard scripts exist and when they run.
- **Discipline**: always-on engineering method (TDD, debugging before fixes,
  verification before completion) belongs in the instruction file itself so
  every tool loads it on every turn.

## Templates

| Template | Produces | Use when |
| --- | --- | --- |
| [`agents-md/roles-section.md`](agents-md/roles-section.md) | A `## Roles` routing table: role name → contract file | The consuming tool can't read `.claude/agents/` (Codex, OpenCode) |
| [`agents-md/teams-section.md`](agents-md/teams-section.md) | A `## Teams` declaration per team: members → chain → handoff record → authority rules → optional team memory — plus five predefined teams ready to copy (feature-build, design-review, bug-diagnosis, research-to-decision, legal-vetting) | The repo runs multi-role chains built from [`../agents/`](../agents/) roles (e.g. the feature-build chain); the `define-team` skill scaffolds custom entries |
| [`agents-md/project-bindings-section.md`](agents-md/project-bindings-section.md) | A `## Project bindings` table — role-contract placeholders (`<test-command>`, `<design-docs>`, …) → real paths/commands — plus the Resolution protocol for establishing missing bindings (search → ask → persist; a required binding that can't be established disables the role) | The repo adopts any generic role from [`../agents/`](../agents/) |
| [`agents-md/raci-section.md`](agents-md/raci-section.md) | A `## RACI` table — Component / Responsible / Accountable / Consulted / Informed, with the one-Accountable-per-row rule, the CODEOWNERS/git-shortlog draft protocol for repos that lack one, the Context-handoff format (task reference in `<work-tracker>`, components, R/A/C/I names, spec links, where to report), and the local task-file convention | The repo adopts the `person-of-contact` role from [`../agents/`](../agents/) |
| [`agents-md/guards-section.md`](agents-md/guards-section.md) | A `## Guards` list of hook scripts and when they run | Any repo that vendors scripts from [`../hooks/`](../hooks/) |
| [`agents-md/engineering-discipline-section.md`](agents-md/engineering-discipline-section.md) | A `## Engineering discipline` rule set: TDD, systematic debugging, verification before completion, quality gates, single source of truth, scope/ownership, version-control safety | Any repo where agents write code |

## How to use

1. Copy the template body into the consuming repo's `AGENTS.md` (or
   `CLAUDE.md`).
2. Replace the placeholders with that repo's actual roles, guards, or
   quality-gate commands.
3. Keep paths relative to the consuming repo's root.

Keep fragments generic: no project names, no machine-specific paths.
