# rules/

Instruction fragments meant to be pasted into a consuming repo's agent
instruction file — `AGENTS.md` (Codex, OpenCode, and the cross-tool
[AGENTS.md convention](https://agents.md)) or `CLAUDE.md` (Claude Code).

**Why a single `agents-md/` directory:** this directory is named for its
delivery mechanism — pasted instruction-file sections, the one rules channel
every tool reads. Tool-specific rule formats (Cursor `.mdc` files, Claude
path-scoped `.claude/rules/`) are deliberately not shipped: they reach one
tool each, and the portable section reaches all four. A second directory
appears here when a second portable delivery mechanism actually exists —
never as an empty placeholder. The templates below are grouped into three
catalogs by theme; the grouping is documentation, the directory stays flat.

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
- **Coding rules**: always-on one-line-per-rule conventions live in the
  instruction file; reference-sized rule sets ship as skills (e.g.
  `python-conventions`, `rustdoc-conventions`), so the section is the router
  that says which convention skills to load per language before writing.
- **Design docs**: doc-shape rules — headers, decision IDs, index, dated
  amendments — are per-repo working agreements every tool must load, so they
  live in the instruction file beside the discipline rules.

## Templates — three catalogs

### Organization — who does what, and how work moves

| Template | Produces | Use when |
| --- | --- | --- |
| [`agents-md/roles-section.md`](agents-md/roles-section.md) | A `## Roles` routing table: role name → contract file | The consuming tool can't read `.claude/agents/` (Codex, OpenCode) |
| [`agents-md/teams-section.md`](agents-md/teams-section.md) | A `## Teams` declaration per team: members → chain → execution-mode → fix-rounds → handoff record (six required elements) → optional artifact edges → authority rules → human checkpoints → optional budget → optional team memory; plus the invariants (one done-authority, a return path per stage, validators see only the handoff and the artifact, parallel stages own disjoint artifacts) and the economics note — and five predefined teams ready to copy (feature-build, design-review, bug-diagnosis, research-to-decision, legal-vetting) | The repo runs multi-role chains built from [`../agents/`](../agents/) roles (e.g. the feature-build chain); the `define-team` skill scaffolds and validates custom entries |
| [`agents-md/raci-section.md`](agents-md/raci-section.md) | A `## RACI` table — Component / Responsible / Accountable / Consulted / Informed, with the one-Accountable-per-row rule, the CODEOWNERS/git-shortlog draft protocol for repos that lack one, the Context-handoff format (task reference in `<work-tracker>`, components, R/A/C/I names, spec links, where to report), and the local task-file convention | The repo adopts the `person-of-contact` role from [`../agents/`](../agents/) |

### Configuration — injecting the project's facts

| Template | Produces | Use when |
| --- | --- | --- |
| [`agents-md/project-bindings-section.md`](agents-md/project-bindings-section.md) | A `## Project bindings` table — role-contract placeholders (`<test-command>`, `<design-docs>`, …) → real paths/commands — plus the Resolution protocol for establishing missing bindings (search → ask → persist; a required binding that can't be established disables the role) | The repo adopts any generic role from [`../agents/`](../agents/) |

### Method — how work is done, always on

| Template | Produces | Use when |
| --- | --- | --- |
| [`agents-md/engineering-discipline-section.md`](agents-md/engineering-discipline-section.md) | A `## Engineering discipline` rule set: TDD, systematic debugging, verification before completion, quality gates, single source of truth, scope/ownership, version-control safety | Any repo where agents write code |
| [`agents-md/coding-section.md`](agents-md/coding-section.md) | A `## Coding rules` section: conventions-win-over-instinct rule, a language → convention-skill routing table (load BEFORE writing), quality gates via the `<lint-command>`/`<test-command>` bindings | Any repo where agents write code and the conventions ship as skills (e.g. this harness's `python-conventions`, `rustdoc-conventions`) |
| [`agents-md/design-docs-section.md`](agents-md/design-docs-section.md) | A `## Design docs` doc-shape rule set: status/owner/date headers, stable decision IDs owned by one doc, a root index with reading order, docs updated in the same change as the code they govern, dated in-place amendments | Any repo that keeps design docs under a `<design-docs>` binding |
| [`agents-md/guards-section.md`](agents-md/guards-section.md) | A `## Guards` list of hook scripts and when they run | Any repo that vendors scripts from [`../hooks/`](../hooks/) |

### Shared notes

| Note | Content | Referenced by |
| --- | --- | --- |
| [`agents-md/size-budget-note.md`](agents-md/size-budget-note.md) | The instruction-file size budget: stay well inside 32 KiB (Codex concatenates and truncates silently from the END), under ~200 lines per file for adherence, `## Roles` and `## Teams` early, copy only the rows a repo runs, move reference-sized material into skills — and run `hooks/scripts/agents-md-budget.sh` before committing | roles · teams · project-bindings · RACI templates |

## How to use

1. Copy the template body into the consuming repo's `AGENTS.md` (or
   `CLAUDE.md`).
2. Replace the placeholders with that repo's actual roles, guards, or
   quality-gate commands.
3. Keep paths relative to the consuming repo's root.
4. Check the result against
   [`agents-md/size-budget-note.md`](agents-md/size-budget-note.md) — copy
   only the rows and teams the repo runs, and keep the routing sections at
   the top of the file.

Keep fragments generic: no project names, no machine-specific paths.
